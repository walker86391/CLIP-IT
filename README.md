# ClipIt — AI Video Clipping & Subtitle Studio

**ClipIt** is a premium Windows desktop application built with Flutter, designed for high-performance AI video clipping, Hinglish/Romanized transcription, acoustic word-by-word forced alignment, and animated viral subtitle generation.

---

## ⚡ Key Features

* **Acoustic Word-by-Word Subtitle Engine**:
  * Real-time vocal envelope detection ensuring subtitles strictly align with spoken words.
  * Active word scale pop (`\fscx120\fscy120`) in electric neon yellow (`#00FFFF`).
  * Dynamic semantic color highlights (e.g., lime green for monetary terms, fiery crimson for climax words, fiery gold for hooks).
  * Smart multi-line flow with intra-line pause handling and automatic laughter clearance.
* **Whisper-Hindi2Hinglish Integration**:
  * Multilingual speech recognition utilizing `Oriserve/Whisper-Hindi2Hinglish-Prime` and `Apex`.
  * Speech-aware VAD chunking and acoustic alignment avoiding arbitrary 30-second drifts.
* **Automated 9:16 Video Re-Framing**:
  * FFmpeg-powered vertical cropping, high-quality audio mixing, and multi-track overlay effects.
* **ChatGPT Bridge Extension**:
  * Integrated browser bridge for script segmentation, hook identification, and automated prompt dispatch.
* **Modern Desktop Architecture**:
  * Windows-first design featuring smooth navigation, custom design tokens, job queue management, and Subtitle Studio.

---

## 🛠️ Tech Stack

* **Frontend**: Flutter (Dart) — Windows Desktop Runner
* **Speech & Alignment Engine**: Python 3.10+, PyTorch, Transformers, Librosa, Scipy, SoundFile
* **Video/Audio Compositor**: FFmpeg & FFprobe
* **Database & Auth**: Supabase Flutter SDK
* **Browser Bridge**: Chrome Manifest V3 Extension (`clipit-chatgpt-bridge/`)

---

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK**: 3.24+ with Windows Desktop support enabled (`flutter config --enable-windows-desktop`).
2. **Visual Studio 2022**: With "Desktop development with C++" workload installed.
3. **Python 3.10+**: With required audio packages:
   ```bash
   pip install torch torchaudio transformers librosa scipy soundfile numpy
   ```
4. **FFmpeg**: Placed in `windows/ffmpeg/` or accessible via system `PATH`.

### Setup

1. **Clone the repository**:
   ```bash
   git clone git@github.com:walker86391/CLIP-IT.git
   cd CLIP-IT
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Environment Setup**:
   Copy `.env.example` to `.env` and configure your Supabase credentials:
   ```bash
   cp .env.example .env
   ```

4. **Models**:
   Download the Whisper models using the provided download scripts:
   ```bash
   python tool/download_whisper_prime.py
   ```

5. **Run in Development**:
   ```bash
   flutter run -d windows
   ```

6. **Build for Release**:
   ```bash
   flutter build windows --release
   ```

---

## 📁 Repository Structure

```
CLIP-IT/
├── lib/                             # Flutter application source code
│   ├── app/                         # Routing, theme, app entry points
│   ├── core/                        # Central services (FFmpeg, Whisper, Auth, AppPathResolver)
│   ├── features/                    # Feature modules (pipeline, subtitles, effects, sound_effects)
│   └── shared/                      # Reusable widgets and UI components
├── tool/                            # Speech pipeline & Whisper runner scripts
│   ├── speech_pipeline.py           # Acoustic alignment & VAD chunking
│   ├── transcribe_hinglish.py       # Audio transcription runner
│   └── download_whisper_prime.py    # Model setup helper
├── clipit-chatgpt-bridge/           # Browser extension bridge
├── assets/                          # Sound effects, fonts, 3D assets, prompt templates
├── windows/                         # Windows C++ runner and native configurations
└── test/                            # Unit and widget test suite
```

---

## 📄 License

Proprietary / All rights reserved.
