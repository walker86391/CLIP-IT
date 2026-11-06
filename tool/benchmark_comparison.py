import os
import sys
import time
import json
import psutil
import torch
import soundfile as sf
import numpy as np
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor

sys.stdout.reconfigure(encoding='utf-8')

# Ground truth spoken transcription for 30s-90s of the video (scratch/ref_30_90.wav):
# 00.0s - 03.0s: [Silence / audience laughter]
# 03.0s - 04.7s: "Aa gae tum log? Bade khush ho rahe ho"
# 04.7s - 08.5s: [Audience laughter & cheers]
# 08.5s - 12.0s: "wahan se main hi hounga aur kaun ho?"
# 12.0s - 14.0s: [Audience laughs]
# 12.5s - 16.5s: "Welcome friends, fans"
# 16.5s - 21.5s: "aur mere do rishtedaar jo aaj free mein aae hain"
# 21.8s - 23.5s: "You are not welcome."
# 23.5s - 25.0s: [Audience laughs]
# 25.0s - 26.5s: "You are cheap."
# 26.5s - 29.2s: [Audience laughs]
# 29.2s - 32.5s: "For the rest of you who paid to be here"
# 32.5s - 37.0s: "tum logon ka swaagat hai aur respect bhi"
# 37.0s - 42.0s: "Show shuru karne se pehle main kuch rules batana chahta hoon"
# 42.0s - 48.0s: "Show ke beech mein photo kheenchna, video banana aur mere honth choona sakht mana hai"
# 48.0s - 52.0s: "Show ke baad main teeno ka mauka doonga"

def benchmark_model(model_dir: str, audio_path: str, model_label: str):
    print(f"\n=======================================================", flush=True)
    print(f"BENCHMARK: {model_label}", flush=True)
    print(f"Model Path: {model_dir}", flush=True)
    print(f"Audio Path: {audio_path}", flush=True)
    print(f"=======================================================", flush=True)

    if not os.path.exists(model_dir):
        print(f"[Error] Model directory does not exist: {model_dir}", flush=True)
        return None

    weights_exist = any(
        os.path.exists(os.path.join(model_dir, f))
        for f in ['model.safetensors', 'model-00001-of-00002.safetensors', 'pytorch_model.bin']
    )
    if not weights_exist:
        print(f"[Error] Weights not yet found in: {model_dir}", flush=True)
        return None

    process = psutil.Process(os.getpid())
    ram_before = process.memory_info().rss / (1024 * 1024)

    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.reset_peak_memory_stats()
        vram_before = torch.cuda.memory_allocated() / (1024 * 1024)
    else:
        vram_before = 0.0

    t_load_start = time.time()
    processor = AutoProcessor.from_pretrained(model_dir)
    torch_dtype = torch.float32

    model = AutoModelForSpeechSeq2Seq.from_pretrained(
        model_dir,
        torch_dtype=torch_dtype,
        low_cpu_mem_usage=True,
        use_safetensors=True,
        device_map="auto" if torch.cuda.is_available() else None,
    )
    model.eval()
    load_time = time.time() - t_load_start
    print(f"Model loaded in: {load_time:.2f}s (device_map='auto', dtype={torch_dtype})", flush=True)

    data, sr = sf.read(audio_path, dtype='float32')
    if data.ndim > 1:
        data = np.mean(data, axis=1)
    dur = len(data) / float(sr)

    window_sec = 30.0
    samples_per_window = int(window_sec * sr)
    num_windows = int(np.ceil(len(data) / float(samples_per_window)))

    t_inf_start = time.time()
    all_segments = []

    for w_idx in range(num_windows):
        s_start = w_idx * samples_per_window
        s_end = min((w_idx + 1) * samples_per_window, len(data))
        win_data = data[s_start:s_end]
        win_dur = len(win_data) / float(sr)
        abs_start = w_idx * window_sec
        abs_end = abs_start + win_dur

        inputs = processor(win_data, sampling_rate=sr, return_tensors="pt")
        target_device = getattr(model, "device", torch.device("cuda:0" if torch.cuda.is_available() else "cpu"))
        input_features = inputs.input_features.to(target_device, dtype=torch_dtype)

        t_w_start = time.time()
        with torch.inference_mode():
            gen_ids = model.generate(
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
        text = processor.batch_decode(gen_ids, skip_special_tokens=True)[0].strip()
        w_latency = time.time() - t_w_start

        all_segments.append({
            "window": w_idx,
            "start": round(abs_start, 3),
            "end": round(abs_end, 3),
            "latency_s": round(w_latency, 2),
            "text": text,
        })
        print(f"  Window {w_idx + 1} [{abs_start:.1f}s -> {abs_end:.1f}s] ({w_latency:.2f}s): {text}", flush=True)

    total_inf_time = time.time() - t_inf_start
    ram_after = process.memory_info().rss / (1024 * 1024)
    peak_vram = (torch.cuda.max_memory_allocated() / (1024 * 1024)) if torch.cuda.is_available() else 0.0

    print(f"\n--- {model_label} METRICS ---", flush=True)
    print(f"Load Time: {load_time:.2f}s", flush=True)
    print(f"Total Inference Time: {total_inf_time:.2f}s (Real-Time Factor: {dur / total_inf_time:.2f}x)", flush=True)
    print(f"Peak VRAM: {peak_vram:.1f} MB", flush=True)
    print(f"System RAM: {ram_after:.1f} MB (delta: {ram_after - ram_before:.1f} MB)", flush=True)

    return {
        "model_label": model_label,
        "model_dir": model_dir,
        "audio_path": audio_path,
        "audio_duration_s": round(dur, 2),
        "load_time_s": round(load_time, 2),
        "inference_time_s": round(total_inf_time, 2),
        "rtf": round(dur / total_inf_time, 2),
        "peak_vram_mb": round(peak_vram, 1),
        "ram_mb": round(ram_after, 1),
        "segments": all_segments,
    }

if __name__ == '__main__':
    prime_path = os.path.abspath('build/windows/x64/runner/Release/models/Whisper-Hindi2Hinglish-Prime')
    apex_path = os.path.abspath('models/Whisper-Hindi2Hinglish-Apex')
    audio_file = os.path.abspath('scratch/ref_30_90.wav')

    results = {}
    if os.path.exists(prime_path):
        results['prime'] = benchmark_model(prime_path, audio_file, "Whisper-Hindi2Hinglish-Prime")

    if os.path.exists(apex_path):
        results['apex'] = benchmark_model(apex_path, audio_file, "Whisper-Hindi2Hinglish-Apex")

    with open('scratch/model_comparison_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("\nSaved full results to scratch/model_comparison_results.json", flush=True)
