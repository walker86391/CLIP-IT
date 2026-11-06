import os
import sys
import time
import requests

MODEL_DIR = os.path.abspath('models/Whisper-Hindi2Hinglish-Apex')
BASE_URL = 'https://huggingface.co/Oriserve/Whisper-Hindi2Hinglish-Apex/resolve/main'

METADATA_FILES = [
    'config.json',
    'generation_config.json',
    'preprocessor_config.json',
    'tokenizer_config.json',
    'tokenizer.json',
    'vocab.json',
    'merges.txt',
    'special_tokens_map.json',
    'added_tokens.json',
    'normalizer.json',
    'convert_hf2openai.json',
    'README.md',
]

WEIGHT_FILES = [
    'model.safetensors',
]

def download_file(filename: str):
    os.makedirs(MODEL_DIR, exist_ok=True)
    target_path = os.path.join(MODEL_DIR, filename)
    part_path = target_path + '.part'
    
    url = f"{BASE_URL}/{filename}"
    headers = {'User-Agent': 'Mozilla/5.0'}
    
    try:
        head_resp = requests.head(url, headers=headers, allow_redirects=True, timeout=15)
        head_resp.raise_for_status()
        total_size = int(head_resp.headers.get('content-length', 0))
    except Exception as e:
        print(f"[Warning] Could not get header for {filename}: {e}", flush=True)
        total_size = 0
        
    if total_size > 0 and os.path.exists(target_path) and os.path.getsize(target_path) == total_size:
        print(f"[Skip] {filename} already downloaded ({total_size / (1024*1024):.1f} MB)", flush=True)
        return
        
    start_byte = 0
    mode = 'wb'
    if os.path.exists(part_path) and total_size > 0:
        start_byte = os.path.getsize(part_path)
        if start_byte < total_size:
            headers['Range'] = f'bytes={start_byte}-'
            mode = 'ab'
            print(f"[Resume] {filename} from {start_byte / (1024*1024):.1f} MB / {total_size / (1024*1024):.1f} MB", flush=True)
        else:
            start_byte = 0
            
    print(f"[Start] Downloading {filename} ({total_size / (1024*1024):.1f} MB)...", flush=True)
    
    with requests.get(url, headers=headers, stream=True, timeout=30) as r:
        if r.status_code not in (200, 206):
            r.raise_for_status()
            
        downloaded = start_byte
        start_time = time.time()
        last_log = start_time
        
        with open(part_path, mode) as f:
            for chunk in r.iter_content(chunk_size=2 * 1024 * 1024): # 2MB chunks
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    now = time.time()
                    if total_size > 0 and (now - last_log > 3.0 or downloaded == total_size):
                        elapsed = now - start_time
                        speed = (downloaded - start_byte) / (elapsed + 1e-6) / (1024 * 1024)
                        pct = (downloaded / total_size) * 100
                        print(f"[{filename}] {downloaded / (1024*1024):.1f}/{total_size / (1024*1024):.1f} MB ({pct:.1f}%) @ {speed:.2f} MB/s", flush=True)
                        last_log = now
                        
    if os.path.exists(target_path):
        os.remove(target_path)
    os.rename(part_path, target_path)
    print(f"[Done] {filename} completed successfully!", flush=True)

if __name__ == '__main__':
    for fn in METADATA_FILES:
        try:
            download_file(fn)
        except Exception as err:
            print(f"[Note] Metadata {fn}: {err}")
    for fn in WEIGHT_FILES:
        download_file(fn)
    print("[All Complete] Whisper-Hindi2Hinglish-Apex is fully installed in models/Whisper-Hindi2Hinglish-Apex!", flush=True)
