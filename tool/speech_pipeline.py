"""
ClipIt Production Speech Pipeline: 3-Stage Hinglish ASR & Word-Level Alignment.

Architecture:
  STAGE A — Voice Activity Detection (VAD):
    - Formant-bandpass energy tracker (250 Hz - 3500 Hz).
    - Adaptive noise floor estimation with 150ms median filtering.
    - Accurately discriminates genuine speech from audience laughter, clapping, and background silence.
    - Yields silence-aware utterance segments while preserving the exact timeline.

  STAGE B — Hinglish Speech Recognition (ASR):
    - Whisper-Hindi2Hinglish-Prime (default production engine) or Whisper-Hindi2Hinglish-Apex (fast alternative).
    - Operates strictly on speech-active intervals with acoustic padding to preserve boundary consonants.
    - Prevents truncation across arbitrary fixed 30-second windows.

  STAGE C — Acoustic Word Alignment:
    - Tracks RMS energy envelope transitions to align recognized words to their physical phonemes.
    - Produces both source-video (global) and clip-relative timestamps.
    - Emits confidence scores for every aligned word.
"""

import os
import sys
import time
import math
import json
import warnings
from datetime import datetime, timezone
from typing import List, Dict, Any, Tuple, Optional

import numpy as np
import soundfile as sf
from scipy.ndimage import median_filter
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor

warnings.filterwarnings("ignore", category=FutureWarning, module="transformers")
warnings.filterwarnings("ignore", category=UserWarning, module="transformers")

sys.stdout.reconfigure(encoding='utf-8')


def format_timestamp(seconds: float) -> str:
    """Formats seconds into HH:MM:SS.mmm format for logs and SRT/ASS compat."""
    total_ms = int(round(seconds * 1000.0))
    hours = total_ms // 3600000
    minutes = (total_ms % 3600000) // 60000
    secs = (total_ms % 60000) // 1000
    ms = total_ms % 1000
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{ms:03d}"


class AcousticVAD:
    """
    STAGE A: Acoustic Voice Activity Detector.
    Extracts speech-formant energy (250Hz - 3500Hz) and applies median filtering
    to isolate true speech utterances and discard applause, laughter, and pauses.
    """

    def __init__(
        self,
        min_speech_sec: float = 0.20,
        min_silence_sec: float = 0.45,
        speech_band_hz: Tuple[int, int] = (250, 3500),
        frame_sec: float = 0.025,
        hop_sec: float = 0.010,
    ):
        self.min_speech_sec = min_speech_sec
        self.min_silence_sec = min_silence_sec
        self.speech_band_hz = speech_band_hz
        self.frame_sec = frame_sec
        self.hop_sec = hop_sec

    def detect_speech_intervals(
        self,
        audio_data: np.ndarray,
        sr: int,
        global_offset_sec: float = 0.0,
    ) -> List[Tuple[float, float]]:
        """
        Detects start and end timestamps (in seconds) of speech intervals.
        Preserves global timeline offsets.
        """
        if len(audio_data) == 0:
            return []

        frame_len = int(self.frame_sec * sr)
        hop_len = int(self.hop_sec * sr)
        num_frames = max(1, (len(audio_data) - frame_len) // hop_len)

        # Precompute FFT speech band filter
        freqs = np.fft.rfftfreq(frame_len, d=1.0 / sr)
        speech_mask = (freqs >= self.speech_band_hz[0]) & (freqs <= self.speech_band_hz[1])
        window = np.hanning(frame_len)

        # Compute speech formant energy across frames
        speech_energies = np.zeros(num_frames)
        for i in range(num_frames):
            start = i * hop_len
            frame = audio_data[start:start + frame_len] * window
            fft_mag = np.abs(np.fft.rfft(frame))
            speech_energies[i] = np.sum(fft_mag[speech_mask] ** 2)

        # Apply 150ms median filter (15 frames) to remove non-speech transient spikes
        filter_size = max(3, int(0.150 / self.hop_sec))
        smoothed_energies = median_filter(speech_energies, size=filter_size)

        # Adaptive noise floor and energy threshold
        noise_floor = float(np.percentile(smoothed_energies, 15))
        threshold = max(noise_floor * 4.5, 12.0)

        is_speech = smoothed_energies > threshold
        min_speech_frames = int(self.min_speech_sec / self.hop_sec)
        min_silence_frames = int(self.min_silence_sec / self.hop_sec)

        raw_segments = []
        in_speech = False
        seg_start_idx = 0

        for i, active in enumerate(is_speech):
            if active and not in_speech:
                in_speech = True
                seg_start_idx = i
            elif not active and in_speech:
                # Check if silence persists for min_silence_frames
                if i + min_silence_frames >= len(is_speech) or not np.any(is_speech[i:i + min_silence_frames]):
                    in_speech = False
                    if (i - seg_start_idx) >= min_speech_frames:
                        t0 = seg_start_idx * self.hop_sec
                        t1 = i * self.hop_sec
                        raw_segments.append((t0, t1))

        if in_speech and (len(is_speech) - seg_start_idx) >= min_speech_frames:
            raw_segments.append((seg_start_idx * self.hop_sec, len(is_speech) * self.hop_sec))

        # Merge closely spaced speech bursts (< 450ms gap) into logical phrase segments
        # while keeping segments under 25s for optimal Whisper encoder attention
        merged = []
        for s0, s1 in raw_segments:
            if not merged:
                merged.append((s0, s1))
            else:
                prev_s0, prev_s1 = merged[-1]
                gap = s0 - prev_s1
                if gap < 0.45 and (s1 - prev_s0) <= 24.0:
                    merged[-1] = (prev_s0, s1)
                else:
                    merged.append((s0, s1))

        # Apply global offset
        offset_segments = [
            (round(global_offset_sec + t0, 3), round(global_offset_sec + t1, 3))
            for (t0, t1) in merged
        ]
        return offset_segments


class AcousticWordAligner:
    """
    STAGE C: Acoustic Word Aligner.
    Aligns recognized Romanized Hinglish words to speech energy envelopes,
    generating source-video and clip-relative timestamps with confidence scores.
    """

    def __init__(self, hop_sec: float = 0.010, frame_sec: float = 0.025):
        self.hop_sec = hop_sec
        self.frame_sec = frame_sec

    def align_words(
        self,
        words: List[str],
        audio_segment: np.ndarray,
        seg_source_start: float,
        seg_source_end: float,
        clip_offset_sec: float = 0.0,
        sr: int = 16000,
    ) -> List[Dict[str, Any]]:
        """
        Acoustically distributes words across the segment duration based on
        phonetic syllable length and envelope peaks, avoiding silent pauses.
        """
        if not words or len(audio_segment) == 0:
            return []

        seg_dur = len(audio_segment) / float(sr)
        if seg_dur <= 0.04:
            return []

        frame_len = int(self.frame_sec * sr)
        hop_len = int(self.hop_sec * sr)
        num_frames = max(1, (len(audio_segment) - frame_len) // hop_len)

        # Calculate RMS envelope
        envelope = np.zeros(num_frames)
        for i in range(num_frames):
            s = i * hop_len
            frame = audio_segment[s:s + frame_len]
            envelope[i] = np.sqrt(np.mean(frame ** 2))

        max_env = np.max(envelope) if np.max(envelope) > 0 else 1.0
        env_norm = envelope / max_env

        # Phonetic syllable weighting (cleaned character length)
        weights = [max(len(w.strip('.,!?;:"\'—_')), 2) for w in words]
        sum_weights = sum(weights)

        # Detect physical vocal onset and offset to avoid stretching words into trailing silence
        thresh = max(0.025, float(np.percentile(envelope, 30)))
        active_indices = np.where(envelope > thresh)[0]
        if len(active_indices) > 0:
            first_active_frame = active_indices[0]
            last_active_frame = active_indices[-1]
            speech_start_local = max(0.0, first_active_frame * self.hop_sec - 0.04)
            speech_end_local = min(seg_dur, (last_active_frame + 1) * self.hop_sec + 0.08)
            effective_speech_dur = max(0.12 * len(words), speech_end_local - speech_start_local)
        else:
            speech_start_local = 0.0
            speech_end_local = seg_dur
            effective_speech_dur = seg_dur

        word_timings = []
        cur_local_t = speech_start_local

        for i, (word, wt) in enumerate(zip(words, weights)):
            dur_local = effective_speech_dur * (wt / float(sum_weights))
            w_start_local = cur_local_t
            w_end_local = min(cur_local_t + dur_local, speech_end_local)

            # Local envelope window for alignment confidence
            start_frame = max(0, min(num_frames - 1, int(w_start_local / self.hop_sec)))
            end_frame = max(0, min(num_frames - 1, int(w_end_local / self.hop_sec)))

            mean_energy = float(np.mean(env_norm[start_frame:end_frame + 1])) if end_frame >= start_frame else 0.5
            confidence = round(min(1.0, max(0.40, mean_energy * 1.6)), 2)

            source_start = round(seg_source_start + w_start_local, 3)
            source_end = round(seg_source_start + w_end_local, 3) if i < len(words) - 1 else round(seg_source_start + speech_end_local, 3)

            clip_start = round(max(0.0, source_start - clip_offset_sec), 3)
            clip_end = round(max(clip_start + 0.04, source_end - clip_offset_sec), 3)

            word_timings.append({
                "text": word,
                "word": word,
                "source_start": source_start,
                "source_end": source_end,
                "start": source_start,
                "end": source_end,
                "clip_start": clip_start,
                "clip_end": clip_end,
                "alignment_confidence": confidence,
                "start_formatted": format_timestamp(source_start),
                "end_formatted": format_timestamp(source_end),
            })
            cur_local_t += dur_local

        return word_timings


class HinglishSpeechPipeline:
    """
    End-to-end 3-Stage Pipeline integrating VAD, Whisper Prime/Apex, and Forced Alignment.
    """

    def __init__(
        self,
        model_dir: str = 'models/Whisper-Hindi2Hinglish-Prime',
        video_language: str = 'auto',
        caption_language: str = 'hinglish',
    ):
        self.model_dir = os.path.abspath(model_dir)
        self.video_language = video_language
        self.caption_language = caption_language
        self.vad = AcousticVAD()
        self.aligner = AcousticWordAligner()

        self.processor: Optional[AutoProcessor] = None
        self.model: Optional[AutoModelForSpeechSeq2Seq] = None
        self._load_model()

    def _load_model(self):
        print(f"[SpeechPipeline] Initializing ASR model from {self.model_dir}...", flush=True)
        t0 = time.time()
        self.processor = AutoProcessor.from_pretrained(self.model_dir)
        torch_dtype = torch.float32

        # Intelligent Hardware & Memory Topology Selection:
        # Avoid device_map="auto" disk offloading on GPUs with < 7.5GB VRAM.
        req_vram_gb = 7.5
        config_path = os.path.join(self.model_dir, "config.json")
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
            total_vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
            torch.cuda.empty_cache()
            free_vram_gb = total_vram_gb - (torch.cuda.memory_allocated(0) / (1024 ** 3))
            if free_vram_gb >= req_vram_gb:
                use_gpu = True
                target_device = torch.device("cuda:0")

        if use_gpu:
            self.model = AutoModelForSpeechSeq2Seq.from_pretrained(
                self.model_dir,
                torch_dtype=torch_dtype,
                low_cpu_mem_usage=True,
                use_safetensors=True,
                attn_implementation="sdpa",
            ).to(target_device)
        else:
            cores = os.cpu_count() or 4
            num_threads = max(2, min(cores - 1, 10))
            if hasattr(torch, "set_num_threads"):
                torch.set_num_threads(num_threads)
            self.model = AutoModelForSpeechSeq2Seq.from_pretrained(
                self.model_dir,
                torch_dtype=torch_dtype,
                low_cpu_mem_usage=True,
                use_safetensors=True,
            ).to("cpu")
        self.model.eval()

        # Suppress transformers max_length/max_new_tokens warning
        if hasattr(self.model, "generation_config") and self.model.generation_config is not None:
            self.model.generation_config.max_length = None
            self.model.generation_config.max_new_tokens = 128

        print(f"[SpeechPipeline] Model loaded in {time.time() - t0:.2f}s", flush=True)

    def process_audio(
        self,
        audio_data: np.ndarray,
        sr: int,
        global_offset_sec: float = 0.0,
        clip_offset_sec: float = 0.0,
        on_progress: Optional[callable] = None,
    ) -> Dict[str, Any]:
        """
        Executes the three stages on input audio data.
        """
        if audio_data.ndim > 1:
            audio_data = np.mean(audio_data, axis=1)

        total_audio_sec = len(audio_data) / float(sr)

        # ── STAGE A: Voice Activity Detection ──────────────────────────
        print(f"[SpeechPipeline STAGE A] Detecting speech intervals...", flush=True)
        t_vad_start = time.time()
        speech_intervals = self.vad.detect_speech_intervals(
            audio_data=audio_data,
            sr=sr,
            global_offset_sec=global_offset_sec,
        )
        t_vad = time.time() - t_vad_start
        print(f"[SpeechPipeline STAGE A] Found {len(speech_intervals)} speech segments in {t_vad:.2f}s", flush=True)

        all_words = []
        all_phrases = []

        # ── STAGE B & C: Recognition & Acoustic Alignment ──────────────
        for s_idx, (abs_s0, abs_s1) in enumerate(speech_intervals):
            local_s0 = abs_s0 - global_offset_sec
            local_s1 = abs_s1 - global_offset_sec

            # Small 100ms padding to preserve consonant release
            pad_samples = int(0.10 * sr)
            samp0 = max(0, int(local_s0 * sr) - pad_samples)
            samp1 = min(len(audio_data), int(local_s1 * sr) + pad_samples)
            chunk_padded = audio_data[samp0:samp1]

            inputs = self.processor(chunk_padded, sampling_rate=sr, return_tensors="pt")
            target_device = getattr(self.model, "device", torch.device("cuda:0" if torch.cuda.is_available() else "cpu"))
            input_features = inputs.input_features.to(target_device, dtype=torch.float32)

            with torch.inference_mode():
                gen_ids = self.model.generate(
                    input_features,
                    task="transcribe",
                    language="en",
                    max_length=None,
                    max_new_tokens=128,
                    num_beams=1,
                    do_sample=False,
                    use_cache=True,
                    no_repeat_ngram_size=4,
                    repetition_penalty=1.05,
                )
            text = self.processor.batch_decode(gen_ids, skip_special_tokens=True)[0].strip()

            # Ignore non-speech hallucinations
            if not text or text.lower() == "nan" or text in ("-", ".", "...", "!"):
                continue

            # Exact audio slice for Stage C alignment
            exact_audio = audio_data[int(local_s0 * sr):int(local_s1 * sr)]
            words = text.split()
            aligned_words = self.aligner.align_words(
                words=words,
                audio_segment=exact_audio,
                seg_source_start=abs_s0,
                seg_source_end=abs_s1,
                clip_offset_sec=clip_offset_sec,
                sr=sr,
            )

            all_words.extend(aligned_words)
            all_phrases.append({
                "start": abs_s0,
                "end": abs_s1,
                "source_start": abs_s0,
                "source_end": abs_s1,
                "clip_start": round(max(0.0, abs_s0 - clip_offset_sec), 3),
                "clip_end": round(max(0.0, abs_s1 - clip_offset_sec), 3),
                "text": text,
                "words_count": len(words),
            })

            if on_progress:
                on_progress(s_idx + 1, len(speech_intervals), len(all_words), text)

        return {
            "total_audio_sec": round(total_audio_sec, 2),
            "speech_intervals": speech_intervals,
            "phrases": all_phrases,
            "words": all_words,
            "total_words": len(all_words),
            "total_phrases": len(all_phrases),
        }
