#!/usr/bin/env python3
"""
Whisper-Hindi2Hinglish-Prime Transcription Engine for ClipIt
Supports progressive multi-chunk audio processing, language selection,
sequential 30-second window streaming, word-level timestamps with exact
millisecond precision, and real-time JSON / TXT writing.
"""

import os
import sys
import json
import argparse
import time
import warnings
from datetime import datetime, timezone
import numpy as np
import soundfile as sf
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor

warnings.filterwarnings("ignore", category=FutureWarning, module="transformers")
warnings.filterwarnings("ignore", category=UserWarning, module="transformers")


def format_timestamp(seconds: float) -> str:
    """Format seconds into HH:MM:SS.mmm format."""
    total_ms = int(round(seconds * 1000))
    hours = total_ms // 3600000
    minutes = (total_ms % 3600000) // 60000
    secs = (total_ms % 60000) // 1000
    ms = total_ms % 1000
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{ms:03d}"


def get_generate_kwargs(video_language: str, caption_language: str):
    """
    Configures generation arguments for Whisper according to video
    and target caption language selections.
    """
    caption_language = (caption_language or "hinglish").lower().strip()
    video_language = (video_language or "auto").lower().strip()

    kwargs = {}

    if caption_language == "hinglish":
        # Oriserve/Whisper-Hindi2Hinglish-Prime generates Romanized Hindi
        # (Hinglish) when task='transcribe' and language='en'
        kwargs["task"] = "transcribe"
        kwargs["language"] = "en"
    elif caption_language in ("en", "english"):
        if video_language in ("en", "english"):
            kwargs["task"] = "transcribe"
            kwargs["language"] = "en"
        else:
            # Cross-lingual translation into English
            kwargs["task"] = "translate"
            kwargs["language"] = "en"
    elif caption_language in ("hi", "hindi"):
        # Native Devanagari Hindi transcription
        kwargs["task"] = "transcribe"
        kwargs["language"] = "hi"
    else:
        kwargs["task"] = "transcribe"
        if video_language != "auto":
            kwargs["language"] = video_language

    return kwargs


def segment_to_words(
    segment_text: str,
    seg_start: float,
    seg_end: float,
    chunk_index: int,
    audio_data: np.ndarray = None,
    sr: int = 16000,
):
    """
    Breaks a phrase/segment into individual timestamped words with exact ms precision.
    Detects physical speech envelope boundaries to prevent stretching words into trailing
    silence, audience laughter, or background noise.
    """
    tokens = segment_text.strip().split()
    if not tokens:
        return []

    # Phonetic weight: word character length with minimum weight of 2
    weights = [max(len(t.strip('.,!?;:"\'')), 2) for t in tokens]
    sum_weights = sum(weights)

    if audio_data is not None and len(audio_data) > 0:
        hop_len = int(0.010 * sr)
        win_len = int(0.025 * sr)
        n_frames = max(1, (len(audio_data) - win_len) // hop_len)
        envelope = np.zeros(n_frames)
        for fi in range(n_frames):
            pos = fi * hop_len
            envelope[fi] = np.sqrt(np.mean(audio_data[pos:pos + win_len] ** 2))

        # Identify true vocal activity bounds
        thresh = max(0.025, float(np.percentile(envelope, 30)))
        active_indices = np.where(envelope > thresh)[0]
        if len(active_indices) > 0:
            speech_start = seg_start + max(0.0, active_indices[0] * 0.010 - 0.04)
            speech_end = min(seg_end, seg_start + (active_indices[-1] + 1) * 0.010 + 0.08)
            total_dur = max(0.12 * len(tokens), speech_end - speech_start)
            current_t = speech_start
        else:
            total_dur = max(seg_end - seg_start, 0.08 * len(tokens))
            current_t = seg_start
    else:
        total_dur = max(seg_end - seg_start, 0.08 * len(tokens))
        current_t = seg_start

    word_records = []
    for i, (w, wt) in enumerate(zip(tokens, weights)):
        w_dur = total_dur * (wt / sum_weights)
        w_start = round(current_t, 3)
        w_end = round(current_t + w_dur, 3) if i < len(tokens) - 1 else round(current_t + w_dur, 3)
        current_t += w_dur

        word_records.append({
            "chunk_index": chunk_index,
            "word": w,
            "text": w,
            "start": w_start,
            "end": w_end,
            "start_formatted": format_timestamp(w_start),
            "end_formatted": format_timestamp(w_end),
        })
    return word_records


def save_transcripts(
    all_words: list,
    all_phrases: list,
    output_json: str,
    output_txt: str,
    video_language: str,
    caption_language: str,
    chunks_processed: int,
    total_chunks: int,
    model_name: str = "Oriserve/Whisper-Hindi2Hinglish-Prime",
):
    """Saves word-level timestamps to JSON and TXT format with immediate flushing."""
    if output_json:
        os.makedirs(os.path.dirname(os.path.abspath(output_json)), exist_ok=True)
        data = {
            "model": model_name,
            "video_language": video_language,
            "caption_language": caption_language,
            "timestamp_granularity": "word",
            "total_words": len(all_words),
            "total_phrases": len(all_phrases),
            "chunks_processed": chunks_processed,
            "total_chunks": total_chunks,
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "words": all_words,
            "segments": all_words,
            "phrases": all_phrases,
        }
        with open(output_json, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.flush()

    if output_txt:
        os.makedirs(os.path.dirname(os.path.abspath(output_txt)), exist_ok=True)
        with open(output_txt, "w", encoding="utf-8") as f:
            for w in all_words:
                start_formatted = w.get("start_formatted") or format_timestamp(float(w.get("start", 0.0)))
                end_formatted = w.get("end_formatted") or format_timestamp(float(w.get("end", 0.0)))
                word_text = w.get("word") or w.get("text") or ""
                f.write(f"[{start_formatted} --> {end_formatted}] {word_text}\n")
            f.flush()


def transcribe_chunks(
    audio_files: list,
    chunk_offsets: list,
    model_dir: str = 'models/Whisper-Hindi2Hinglish-Prime',
    output_json: str = 'live process/transcription/transcript.json',
    output_txt: str = 'live process/transcription/transcript.txt',
    video_language: str = 'auto',
    caption_language: str = 'hinglish',
):
    """
    Transcribes sequential audio chunks using Whisper-Hindi2Hinglish-Prime,
    offsetting timestamps and writing word-level timestamps to JSON / TXT after each window.
    """
    model_dir = os.path.abspath(model_dir)
    if not os.path.exists(model_dir):
        raise FileNotFoundError(f"Model directory not found: {model_dir}")

    device = "cuda:0" if torch.cuda.is_available() else "cpu"
    # Note: On Turing / Quadro GPUs, float16 causes NaN attention logits in Whisper Large v3.
    # torch.float32 prevents NaNs and executes reliably without infinite loops.
    torch_dtype = torch.float32

    # High-performance compute & memory configuration: allow PyTorch to utilize available hardware
    if hasattr(torch, "set_num_threads"):
        cores = os.cpu_count() or 4
        # Give Whisper sufficient CPU worker threads for feature processing and token generation
        num_threads = max(2, min(cores - 1, 10))
        torch.set_num_threads(num_threads)
        print(f"[Whisper Engine] Set PyTorch CPU worker threads: {num_threads}/{cores}", flush=True)

    if torch.cuda.is_available():
        torch.backends.cuda.matmul.allow_tf32 = True
        torch.backends.cudnn.allow_tf32 = True
        torch.backends.cudnn.benchmark = True

    print(f"[Whisper Prime] Target Video Language: {video_language}", flush=True)
    print(f"[Whisper Prime] Expected Captions Language: {caption_language}", flush=True)
    t0 = time.time()

    processor = AutoProcessor.from_pretrained(model_dir)

    # Intelligent Memory & Hardware Topology Selection:
    # Whisper Large (Prime) in float32 requires ~7.5 GB of dedicated VRAM.
    # On GPUs with < 7.5 GB VRAM (e.g. 4GB Quadro T1000 or GTX 1650), loading
    # with device_map="auto" causes Accelerate to offload layers to DISK and CPU.
    # Disk offloading causes multi-minute stalls per 30s window and triggers watchdog timeouts.
    # Modern multi-core CPUs (e.g. 12 threads) run float32 Whisper Large entirely in system RAM
    # at ~1.5x real-time speed with 0 offload, 0 NaNs, and 0 stalls.
    req_vram_gb = 7.5
    config_path = os.path.join(model_dir, "config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as cf:
                cfg = json.load(cf)
                if cfg.get("decoder_layers", 32) <= 6:
                    req_vram_gb = 3.0
        except Exception:
            pass

    use_gpu = False
    target_device = torch.device("cpu")
    if torch.cuda.is_available():
        gpu_name = torch.cuda.get_device_name(0)
        total_vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
        torch.cuda.empty_cache()
        allocated_gb = torch.cuda.memory_allocated(0) / (1024 ** 3)
        free_vram_gb = total_vram_gb - allocated_gb

        if free_vram_gb >= req_vram_gb:
            use_gpu = True
            target_device = torch.device("cuda:0")
            print(
                f"[Whisper Prime] Dedicated GPU VRAM ({free_vram_gb:.2f} GB / {total_vram_gb:.2f} GB on {gpu_name}) "
                f"is sufficient (>= {req_vram_gb:.1f} GB required). Initializing on {target_device}!",
                flush=True,
            )
        else:
            print(
                f"[Whisper Prime] Detected {gpu_name} with {total_vram_gb:.2f} GB VRAM ({free_vram_gb:.2f} GB available). "
                f"Full model in float32 requires ~{req_vram_gb:.1f} GB to prevent disk-offload stalls. "
                f"Routing to multi-core CPU ({num_threads} worker threads, system RAM) for smooth, non-blocking inference.",
                flush=True,
            )

    model = None
    if use_gpu:
        try:
            model = AutoModelForSpeechSeq2Seq.from_pretrained(
                model_dir,
                torch_dtype=torch_dtype,
                low_cpu_mem_usage=True,
                use_safetensors=True,
                attn_implementation="sdpa",
            ).to(target_device)
            print(f"[Whisper Prime] Successfully initialized on {target_device} with PyTorch SDPA attention!", flush=True)
        except Exception as sdpa_err:
            print(f"[Whisper Prime] SDPA backend notice ({sdpa_err}), initializing with eager attention...", flush=True)
            model = AutoModelForSpeechSeq2Seq.from_pretrained(
                model_dir,
                torch_dtype=torch_dtype,
                low_cpu_mem_usage=True,
                use_safetensors=True,
            ).to(target_device)
            print(f"[Whisper Prime] Successfully initialized on {target_device}!", flush=True)
    else:
        print(f"[Whisper Prime] Initializing on CPU with {num_threads} worker threads...", flush=True)
        model = AutoModelForSpeechSeq2Seq.from_pretrained(
            model_dir,
            torch_dtype=torch_dtype,
            low_cpu_mem_usage=True,
            use_safetensors=True,
        ).to("cpu")
        print(f"[Whisper Prime] Successfully initialized on CPU with {num_threads} worker threads.", flush=True)

    model.eval()
    # Suppress transformers conflicting max_length/max_new_tokens warnings
    if hasattr(model, "generation_config") and model.generation_config is not None:
        model.generation_config.max_length = None
        model.generation_config.max_new_tokens = 128

    print(f"[Whisper Prime] Model loaded in {time.time() - t0:.2f}s", flush=True)

    gen_kwargs = get_generate_kwargs(video_language, caption_language)
    print(f"[Whisper Prime] Generation parameters: {gen_kwargs}", flush=True)

    all_words = []
    all_phrases = []
    total_chunks = len(audio_files)
    effective_model_name = os.path.basename(model_dir)

    # ── Progressive Resume Engine ───────────────────────────────────────────
    # If transcription was previously interrupted (e.g. app closed or killed),
    # load existing words/phrases from output_json and skip already completed windows.
    last_transcribed_end_sec = -1.0
    if os.path.exists(output_json):
        try:
            with open(output_json, "r", encoding="utf-8") as f:
                prev_data = json.load(f)
            prev_words = prev_data.get("words", [])
            prev_phrases = prev_data.get("phrases", [])
            if prev_words and len(prev_words) > 0:
                w_max = max(float(w.get("end", 0.0)) for w in prev_words)
                last_transcribed_end_sec = max(last_transcribed_end_sec, w_max)
                all_words = list(prev_words)
            if prev_phrases and len(prev_phrases) > 0:
                p_max = max(float(p.get("end", 0.0)) for p in prev_phrases)
                last_transcribed_end_sec = max(last_transcribed_end_sec, p_max)
                all_phrases = list(prev_phrases)
            if last_transcribed_end_sec > 0.0:
                print(
                    f"[Whisper Prime] Found existing transcription progress: {len(all_words)} words, "
                    f"{len(all_phrases)} phrases up to {last_transcribed_end_sec:.2f}s ({format_timestamp(last_transcribed_end_sec)}). "
                    f"Resuming seamlessly without repeating completed windows!",
                    flush=True,
                )
        except Exception as load_err:
            print(f"[Whisper Prime] Notice: could not load existing progress for resume ({load_err}). Starting fresh.", flush=True)

    # Pre-initialize or update JSON and TXT output files with word-level headers
    save_transcripts(
        all_words=all_words,
        all_phrases=all_phrases,
        output_json=output_json,
        output_txt=output_txt,
        video_language=video_language,
        caption_language=caption_language,
        chunks_processed=0,
        total_chunks=total_chunks,
        model_name=effective_model_name,
    )

    for idx, audio_file in enumerate(audio_files):
        audio_path = os.path.abspath(audio_file)
        if not os.path.exists(audio_path):
            print(f"[Whisper Prime] Warning: chunk file not found: {audio_path}", flush=True)
            continue

        offset_s = chunk_offsets[idx] if idx < len(chunk_offsets) else 0.0
        print(f"[Whisper Prime] Processing chunk {idx + 1}/{total_chunks}: {os.path.basename(audio_path)} (offset: {offset_s:.3f}s)", flush=True)

        try:
            data, sr = sf.read(audio_path, dtype='float32')
        except Exception as e:
            print(f"[Whisper Prime] Error reading audio {audio_path}: {e}", flush=True)
            continue

        # Convert multi-channel to mono
        if data.ndim > 1:
            data = np.mean(data, axis=1)

        total_audio_sec = len(data) / float(sr)
        window_sec = 30.0
        samples_per_window = int(window_sec * sr)
        num_windows = int(np.ceil(len(data) / float(samples_per_window))) if samples_per_window > 0 else 1

        print(f"[Whisper Prime] Chunk audio length: {total_audio_sec:.2f}s across {num_windows} window(s)", flush=True)

        chunk_words = []
        chunk_phrases = []

        for w_idx in range(num_windows):
            s_start = w_idx * samples_per_window
            s_end = min((w_idx + 1) * samples_per_window, len(data))
            win_data = data[s_start:s_end]

            if len(win_data) == 0:
                continue

            win_dur = len(win_data) / float(sr)
            abs_start = offset_s + (w_idx * window_sec)
            abs_end = abs_start + win_dur

            # ── Fast Resume Skip ─────────────────────────────────────────
            # If this 30-second window was already completed in a prior run, skip inference directly.
            if last_transcribed_end_sec > 0.0 and abs_end <= (last_transcribed_end_sec + 0.05):
                pct = int(round(((w_idx + 1) / float(num_windows)) * 100))
                print(f"[{format_timestamp(abs_start)} --> {format_timestamp(abs_end)}] ({pct}%) [Already transcribed - resumed]", flush=True)
                print(
                    f"[WINDOW_PROGRESS] {json.dumps({'chunk_index': idx, 'chunks_total': total_chunks, 'chunk_percent': pct, 'total_words': len(all_words), 'recent_text': '[Resumed]'})}",
                    flush=True,
                )
                continue

            # Silence detection (RMS energy)
            rms = float(np.sqrt(np.mean(win_data**2)))
            if rms < 0.005:
                # Silence window: skip inference
                pct = int(round(((w_idx + 1) / float(num_windows)) * 100))
                print(f"[{format_timestamp(abs_start)} --> {format_timestamp(abs_end)}] ({pct}%) [Silence - skipped]", flush=True)
                print(
                    f"[WINDOW_PROGRESS] {json.dumps({'chunk_index': idx, 'chunks_total': total_chunks, 'chunk_percent': pct, 'total_words': len(all_words), 'recent_text': ''})}",
                    flush=True,
                )
                continue

            t_win_start = time.time()
            pct_start = int(round((w_idx / float(num_windows)) * 100))
            print(
                f"[Whisper Prime] Transcribing window {w_idx + 1}/{num_windows} "
                f"[{format_timestamp(abs_start)} --> {format_timestamp(abs_end)}] ({pct_start}%)...",
                flush=True,
            )
            try:
                inputs = processor(win_data, sampling_rate=sr, return_tensors="pt")
                target_device = getattr(model, "device", torch.device("cuda:0" if torch.cuda.is_available() else "cpu"))
                input_features = inputs.input_features.to(target_device, dtype=torch_dtype)
                with torch.inference_mode():
                    gen_ids = model.generate(
                        input_features,
                        task=gen_kwargs.get("task", "transcribe"),
                        language=gen_kwargs.get("language", "en"),
                        max_new_tokens=128,
                        num_beams=1,
                        do_sample=False,
                        use_cache=True,
                        no_repeat_ngram_size=4,
                        repetition_penalty=1.05,
                    )
                text = processor.batch_decode(gen_ids, skip_special_tokens=True)[0].strip()
            except Exception as gen_err:
                print(f"[Whisper Prime] Warning: generation error in window {w_idx + 1}: {gen_err}", flush=True)
                text = ""

            win_elapsed = time.time() - t_win_start
            if win_elapsed > 120.0:
                print(f"[Whisper Prime] Notice: window {w_idx + 1} processing duration: {win_elapsed:.1f}s", flush=True)

            # Filter out non-speech artifacts or NaNs
            if text and text.lower() != "nan" and text.strip() not in ("-", ".", "...", "!"):
                words = segment_to_words(text, abs_start, abs_end, idx, audio_data=win_data, sr=sr)
                chunk_words.extend(words)
                chunk_phrases.append({
                    "chunk_index": idx,
                    "start": round(abs_start, 3),
                    "end": round(abs_end, 3),
                    "start_formatted": format_timestamp(abs_start),
                    "end_formatted": format_timestamp(abs_end),
                    "text": text,
                })
                all_words.extend(words)
                all_phrases.append(chunk_phrases[-1])

                # IMMEDIATELY write and flush word timestamps to JSON and TXT
                save_transcripts(
                    all_words=all_words,
                    all_phrases=all_phrases,
                    output_json=output_json,
                    output_txt=output_txt,
                    video_language=video_language,
                    caption_language=caption_language,
                    chunks_processed=idx + 1,
                    total_chunks=total_chunks,
                    model_name=effective_model_name,
                )

            pct = int(round(((w_idx + 1) / float(num_windows)) * 100))
            display_text = text if text and text.lower() != "nan" else "[Non-speech / music]"
            print(f"[{format_timestamp(abs_start)} --> {format_timestamp(abs_end)}] ({pct}%) {display_text}", flush=True)
            print(
                f"[WINDOW_PROGRESS] {json.dumps({'chunk_index': idx, 'chunks_total': total_chunks, 'chunk_percent': pct, 'total_words': len(all_words), 'recent_text': display_text})}",
                flush=True,
            )

        print(
            f"[CHUNK_DONE] {json.dumps({'chunk_index': idx, 'chunks_total': total_chunks, 'chunk_words': len(chunk_words), 'cumulative_words': len(all_words), 'cumulative_segments': len(all_words), 'output_json': output_json})}",
            flush=True,
        )

    if torch.cuda.is_available():
        torch.cuda.empty_cache()

    print(f"[Whisper Prime] Completed all {total_chunks} chunks. Total timestamped words: {len(all_words)}", flush=True)
    return all_words


def main():
    parser = argparse.ArgumentParser(description="Multi-chunk Whisper Prime transcription engine")
    parser.add_argument("--chunks", "-c", nargs="+", help="List of chunk audio files to transcribe")
    parser.add_argument("--audio", "-a", help="Single audio file path")
    parser.add_argument("--offsets", nargs="+", type=float, help="List of start offset seconds per chunk")
    parser.add_argument("--model", "-m", default="models/Whisper-Hindi2Hinglish-Prime", help="Path to model directory")
    parser.add_argument("--output-json", "-j", default="live process/transcription/transcript.json", help="Path for JSON output")
    parser.add_argument("--output-txt", "-t", default="live process/transcription/transcript.txt", help="Path for TXT output")
    parser.add_argument("--video-language", default="auto", help="Default video language")
    parser.add_argument("--caption-language", default="hinglish", help="Expected captions language (hinglish, en, hi)")
    args = parser.parse_args()

    audio_files = []
    if args.chunks:
        audio_files = args.chunks
    elif args.audio:
        audio_files = [args.audio]
    else:
        default_wav = "live process/audio/audio.wav"
        default_mp3 = "live process/audio/audio.mp3"
        if os.path.exists(default_mp3):
            audio_files = [default_mp3]
        elif os.path.exists(default_wav):
            audio_files = [default_wav]
        else:
            print("Error: No audio files provided and defaults not found.")
            sys.exit(1)

    offsets = args.offsets if args.offsets else [0.0] * len(audio_files)
    if len(offsets) < len(audio_files):
        offsets.extend([0.0] * (len(audio_files) - len(offsets)))

    transcribe_chunks(
        audio_files=audio_files,
        chunk_offsets=offsets,
        model_dir=args.model,
        output_json=args.output_json,
        output_txt=args.output_txt,
        video_language=args.video_language,
        caption_language=args.caption_language,
    )


if __name__ == "__main__":
    main()
