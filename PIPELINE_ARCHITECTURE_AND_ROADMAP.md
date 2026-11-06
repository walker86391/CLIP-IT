# ClipIt — Complete Video Processing Pipeline, Hinglish Transcription & 6-Screen Customization Architecture

## 1. Executive Pipeline Architecture

The ClipIt processing pipeline transforms long-form raw video into high-retention, virally-optimized short clips (9:16, 1:1, 16:9). The ChatGPT local browser bridge acts as the intelligent semantic reasoning engine, while local processing binaries (FFmpeg, FFprobe, and whisper.cpp / specialized Hinglish ASR) handle audio-visual extraction and rendering.

```
 ┌────────────────┐
 │ Raw Video File │ (.mp4, .mov, .mkv)
 └───────┬────────┘
         │
         ▼ [Stage 1: Metadata Extraction]
 ┌─────────────────────────────────────────────────────────┐
 │ FFprobe: Resolution, FPS, Duration, Audio Codec, Tracks │
 └───────┬─────────────────────────────────────────────────┘
         │
         ▼ [Stage 2: Audio Extraction & Preprocessing]
 ┌─────────────────────────────────────────────────────────┐
 │ FFmpeg: Extract 16kHz 16-bit Mono PCM WAV               │
 │ Cache to: .clipit/projects/{id}/audio_16k.wav          │
 └───────┬─────────────────────────────────────────────────┘
         │
         ▼ [Stage 3: VAD Chunking & Speech-to-Text]
 ┌─────────────────────────────────────────────────────────┐
 │ • Voice Activity Detection (VAD) split into 30-60s chunks│
 │ • Hinglish/Roman Hindi Model (Oriserve / Whisper GGUF)  │
 │ • Real-time Timestamp Alignment [00:14.200 -> 00:18.500]│
 │ • Save formatted transcript to transcript.txt           │
 └───────┬─────────────────────────────────────────────────┘
         │
         ▼ [Stage 4: ChatGPT Local Bridge Analysis]
 ┌─────────────────────────────────────────────────────────┐
 │ • Prepend Selected Genre AI Prompt (1 of 10 presets)    │
 │ • Stream Timestamped Transcript through WebSocket Bridge│
 │ • Output: Structured JSON Viral Moment Cut List         │
 └───────┬─────────────────────────────────────────────────┘
         │
         ▼ [Stage 5: 6-Screen Customization Workflow]
 ┌─────────────────────────────────────────────────────────┐
 │ [1] Project Settings (Device, Ratio, Head Tracking)    │
 │ [2] Auto-Framing & Layouts (Single, Split, Multi-Cam)  │
 │ [3] Subtitle & Caption Styler (Karaoke, Fonts, Emojis) │
 │ [4] Visual Effects & Filters (LUTs, Punch Zooms, Blur) │
 │ [5] Audio Enhancements (Noise gate, Ducking, SFX)      │
 │ [6] Viral Score Review & Final Multi-Clip Render Queue │
 └───────┬─────────────────────────────────────────────────┘
         │
         ▼ [Stage 6: FFmpeg Render & Export]
 ┌─────────────────────────────────────────────────────────┐
 │ FFmpeg Filtergraph: Trim timestamps, Crop/Reframe,     │
 │ Burn ASS subtitles, apply audio ducking -> Export MP4  │
 └─────────────────────────────────────────────────────────┘
```

---

## 2. In-Depth Research: Speech-to-Text for Hinglish (Roman Hindi)

### The Problem with Standard OpenAI Whisper
Vanilla Whisper has two significant flaws when processing Indian content:
1. **Script Mismatch:** Spoken conversational Hindi is transcribed into **Devanagari script** (`भाई आज तो मज़ा आ गया`) instead of modern Roman Hindi (`bhai aaj toh maza aa gya`).
2. **Translation Bias:** If set to English translation (`--task translate`), Whisper translates colloquial slang into formal English (`"Brother, today was so much fun"`), which completely destroys conversational authenticity, comedic timing, and viral punchlines.
3. **Code-Switching Failures:** Real conversational Hindi contains 15% to 30% English vocabulary ("stream", "subscribe", "crazy", "gameplay", "bro"). Vanilla Whisper often drops tokens or hallucinates when speakers rapidly switch languages mid-sentence.
4. **Noise Sensitivity:** Studio clapping, table slams, laughter, or background music confuse standard models into hallucinating phantom phrases.

---

### Best Evaluated Open-Source Models for Roman Hindi / Hinglish

| Model Name | Type / Architecture | Hinglish / Roman Output Quality | Background Noise & Clapping Tolerance | Recommended Local Deployment |
| :--- | :--- | :--- | :--- | :--- |
| **`Oriserve/Whisper-Hindi2Hinglish`** *(Top Choice)* | Fine-tuned `whisper-large-v3` on 550+ hrs of noisy Indian call-center & conversation audio | **Exceptional:** Directly outputs natural Romanized Hindi with English mixed in. | **High:** Trained specifically on loud, real-world Indian acoustic environments. | Available in GGUF format (`curiophile/whisper-hindi2hinglish-ggml`) running via C++ `whisper-cli.exe` (no Python needed). |
| **`Trelis/whisper-hinglish-preview`** | Whisper Medium fine-tune with `<\|mixedcode\|>` tokens | **Very Good:** Mimics WhatsApp/chat style romanized Hinglish. | **Moderate:** Best in clean to medium studio environments. | Hugging Face Transformers or ONNX Runtime. |
| **`Shunya Labs Zero-STT Hinglish`** | Whisper Medium optimized for Indian code-switching | **High:** Captures mid-sentence Hindi-English transitions without latency. | **Good:** Robust against casual crosstalk. | PyTorch / vLLM / C++ GGUF. |
| **AI4Bharat IndicWhisper / IndicConformer** | Conformer-CTC & Whisper fine-tuned across 22 Indian languages | **High:** Highly accurate phonetic representation. | **High:** Trained on diverse Indian accents and dialects. | ONNX / Python / C++ runtime. |

### Dual-Layer Fallback Strategy (Guaranteed Roman Output)
To ensure 100% reliability even if a user downloads a standard Whisper model (Base, Small, Large-v3):
1. **Primary Pass:** If an optimized Hinglish model (`whisper-hindi2hinglish`) is selected, transcription outputs Roman Hindi directly.
2. **Deterministic Transliteration Engine:** If a standard Whisper model is used and outputs Devanagari text, ClipIt automatically pipes the text through an internal phonetic transliteration engine (`indic-transliteration` / ISO-15919 phonetic mapping in Dart) to instantly transform:
   - `भाई आज तो क्रेज़ी हो गया यार` ➔ `Bhai aaj toh crazy ho gaya yaar`
   - Preserves all English terms and punctuation intact.

---

## 3. Audio Chunking & Exact Timestamp Architecture

To prevent memory crashes on 30-minute to 2-hour long videos, audio is processed in discrete chunks while retaining global video timestamps.

### Chunking Logic
1. **FFmpeg Audio Extraction:**
   ```bash
   ffmpeg -y -i input_video.mp4 -vn -ar 16000 -ac 1 -c:a pcm_s16le .clipit/projects/{id}/audio_16k.wav
   ```
2. **Silence-Aware Boundary Splitting (VAD):**
   - Audio is divided into **45-second chunks** with a 2-second overlap at natural silence boundaries (using Voice Activity Detection / Silero VAD or FFmpeg `silencedetect`).
   - Prevents words from being split in half at arbitrary chunk boundaries.
3. **Global Timestamp Offset Calculation:**
   Each transcribed segment's timestamps are offset by the chunk's start time:
   $$\text{Global Timestamp} = \text{Chunk Start Time} + \text{Segment Time}$$
4. **Structured Output File (`transcript.txt`):**
   ```text
   [00:00:14.250 -> 00:00:18.800] Bhai aaj toh crazy ho gya, unbelievable stream!
   [00:00:19.100 -> 00:00:23.400] [cheering/applause] Sab log chat mein W spam kardo!
   [00:00:24.000 -> 00:00:29.850] Aaj humne record break kar diya poora.
   ```

---

## 4. Settings: Model Manager Design

Located under **Settings ➔ AI & Models** in ClipIt:

### Section A: Standard Whisper Models (Multilingual & English)
| Model | Size | RAM Required | Recommended For | Actions |
| :--- | :--- | :--- | :--- | :--- |
| **Whisper Tiny** | 75 MB | ~300 MB | Fast test runs, low-spec PCs | [Download] / [Verify] / [Delete] |
| **Whisper Base** | 142 MB | ~450 MB | Quick processing, basic English | [Download] / [Verify] / [Delete] |
| **Whisper Small** | 466 MB | ~1.1 GB | Balanced speed and accuracy | [Download] / [Verify] / [Delete] |
| **Whisper Medium** | 1.5 GB | ~2.6 GB | High-accuracy English/general | [Download] / [Verify] / [Delete] |
| **Whisper Large-v3-Turbo** | 1.6 GB | ~3.0 GB | **Recommended:** Fast, high accuracy | [Download] / [Verify] / [Delete] |
| **Whisper Large-v3** | 2.9 GB | ~4.8 GB | Maximum precision multilingual | [Download] / [Verify] / [Delete] |

### Section B: Hinglish & Roman Hindi Models
| Model | Size | RAM Required | Recommended For | Actions |
| :--- | :--- | :--- | :--- | :--- |
| **Oriserve Hindi2Hinglish GGML** | 1.6 GB | ~3.0 GB | **Best for Hinglish (Roman Hindi)** | [Download] / [Verify] / [Delete] |
| **Trelis Hinglish Medium** | 1.5 GB | ~2.6 GB | WhatsApp-style conversational code-mix | [Download] / [Verify] / [Delete] |
| **IndicConformer Romanized** | 850 MB | ~1.8 GB | Lightweight Indian English/Hindi | [Download] / [Verify] / [Delete] |

### Model Card Capabilities
- **Download:** Downloads directly from Hugging Face / GitHub releases with live percentage, download speed (MB/s), and ETA.
- **Verify:** Computes SHA-256 hash to ensure the downloaded `.bin` or `.gguf` file is intact and not corrupted.
- **Delete:** Frees disk space with a single click.
- **Active Selection Badge:** User selects one model as the active speech engine.

---

## 5. ChatGPT Bridge Prompting & Viral Moment JSON Format

When `transcript.txt` is ready, ClipIt packages it with the selected genre prompt (from the 10 presets) and transmits it to the open ChatGPT tab via the WebSocket bridge.

### The Bridge Prompt Structure
```text
SYSTEM INSTRUCTION:
You are an expert viral video editor and retention strategist for TikTok, YouTube Shorts, and Instagram Reels.
You will analyze the following timestamped transcript of a video.

CONTENT GENRE: {SelectedGenreTitle}
DIRECTIVE: {SelectedGenrePrompt}

TASK:
1. Identify the top 3 to 5 highest-retention viral moments.
2. Ensure each clip has a strong opening hook (first 3 seconds).
3. Ensure each clip has a satisfying punchline, climax, or takeaway.
4. Output ONLY valid JSON matching the exact schema below.

OUTPUT JSON SCHEMA:
{
  "clips": [
    {
      "id": 1,
      "start_time": "00:01:14.250",
      "end_time": "00:01:58.400",
      "hook_title": "Bhai Aaj Toh Crazy Ho Gya!",
      "viral_score": 94,
      "virality_reason": "High emotional spike, strong opening hook, laughter and punchline delivery.",
      "suggested_caption": "Wait till the end 😂 #viral #trending"
    }
  ]
}

TRANSCRIPT:
{TimestampedTranscript}
```

---

## 6. The 6-Step Customization Workflow

The ClipIt project workflow stepper (`(1) 2 3 4 5 6`) guides the creator through visual personalization before rendering:

### Step 1: Project Settings *(Implemented)*
- Device preview selection (iPhone 18 Pro Max, Samsung S26, UltraBook Laptop).
- Aspect ratio selection (`16:9`, `1:1`, `9:16`, `4:5`, `21:9`, `3:2`, `Original`).
- Head tracking & speaker reframing toggle.
- Inbuilt AI prompt & video title review.

### Step 2: Auto-Framing & Layout Engine
- **Layout Modes:**
  1. *Single Speaker Auto-Tracking:* Real-time face detection keeps active speaker centered in 9:16.
  2. *Split-Screen (Top/Bottom):* Ideal for podcasts and interviews (Host on top, Guest on bottom).
  3. *Picture-in-Picture (PiP):* Ideal for gameplay and reaction videos.
  4. *Blur Padding:* Original 16:9 placed in center with blurred video backdrop.
- Manual framing offset slider (X/Y pan adjustment).

### Step 3: Subtitles & Caption Styler
- **Presets:** MrBeast bold yellow/black stroke, Hormozi modern minimalist, Neon glow, Aesthetic serif.
- **Karaoke Word-by-Word Highlight:** Active word pops or changes color as spoken.
- Font family, size, line spacing, text capitalization (`ALL CAPS`, `Title Case`).
- Automatic emoji insertion based on emotion/keywords (e.g. "crazy" ➔ 🤪, "fire" ➔ 🔥).
- Safe-zone indicators for TikTok / Reels UI overlays.

### Step 4: Visual Effects & Dynamic Cuts
- **Punch-In Zooms:** Automatic 1.15x zoom cut on key punchlines and emotional shifts.
- **Cinematic LUT Color Grading:** Vibrant, Moody, Warm Film, Clean Tech, High Contrast.
- **B-Roll & Overlay Triggers:** Sound wave visualizers, retro VHS tape effect, subtle grain.

### Step 5: Audio Mastering & Background Music
- **Noise Suppression:** Background hum, fan, and hiss removal.
- **Auto-Ducking:** Background music automatically drops by -18 dB when speech is detected.
- **Loudness Normalization:** EBU R128 (-14 LUFS standard for Shorts and Reels).
- Sound effect triggers (whoosh, pop, vinyl scratch, rimshot).

### Step 6: Review, Virality Scoring & Multi-Clip Render
- Visual card deck showing all candidate viral clips generated by ChatGPT.
- **Viral Score Breakdown (0–100):** Hook Score, Retention Potential, Pacing Rating.
- Side-by-side comparison & quick timeline trimming adjustment.
- **Batch Render:** Export all selected clips in parallel with hardware acceleration (NVENC / QuickSync / AMF).

---

## 7. Immediate Next Steps

As requested:
1. **First, design and build all 6 customization screens** in the UI so the full creator journey is visually and functionally realized.
2. **Next, build the Settings AI & Models manager** to handle downloading, verifying, and deleting Whisper & Hinglish GGUF model files.
3. **Finally, wire the real FFmpeg/ASR backend pipeline** to the ChatGPT bridge to run the end-to-end processing.
