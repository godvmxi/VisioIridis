# Project Plan

Build an offline, low-latency, high-contrast live-caption Android app for hard-of-hearing users, using **Flutter** and **sherpa-onnx** (SenseVoice-Small INT8 + Silero-VAD). The source of truth for requirements is `design.md` in the separate [VisioIridisPRD](https://github.com/godvmxi/VisioIridisPRD) repo.

## Project Brief

### Features (Phase 1 MVP)

1. **Live captions**: Capture mic audio (16kHz mono PCM), segment speech with Silero-VAD (400ms silence ends a sentence), decode with SenseVoice. Show ~300ms partial results while speaking and a final result at sentence end.
2. **Language selection**: Mandarin / Cantonese / English toggles. All three or two selected → `auto` plus a language-tag check that re-decodes when the detected language is not selected. One selected → force that language. At least one must stay selected.
3. **Three-zone accessible UI**: History list (black background, oldest first, auto-follow with manual-scroll lock and a "back to latest" button), fixed focus card (#FFE600 bold, 28–32sp), bottom start/stop button (60dp, with haptic feedback).
4. **Event tags**: Laughter / Applause / Cry → emoji labels; all other SenseVoice tags are stripped.
5. **Keep-alive**: Wakelock while listening; a microphone-type foreground service; mic hot-plug recovery.

### Tech Stack

- **Framework**: Flutter (Dart), Android first
- **State management**: flutter_riverpod
- **ASR**: sherpa_onnx (Dart FFI), with inference in a long-lived background Isolate that loads the model once
- **Audio**: record (`startStream`, PCM16 16kHz mono)
- **Platform**: permission_handler, flutter_foreground_task, wakelock_plus, path_provider
- **Models**: bundled in assets and extracted to app storage on first launch (Play builds: Play Asset Delivery)
- **Network**: none in the core path; optional online AI correction is off by default

## Implementation Steps

1. Replace the Kotlin/Compose template with a Flutter project (`flutter create --platforms android`).
2. Add dependencies and Android manifest permissions (RECORD_AUDIO, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MICROPHONE, POST_NOTIFICATIONS, WAKE_LOCK).
3. Build the three-zone UI skeleton with mock subtitle data.
4. Add model asset extraction and the inference Isolate (VAD + SenseVoice).
5. Wire record stream → Isolate → Riverpod state → UI; add partial/final handling.
6. Add language-param mapping, tag parsing, wakelock, haptics, and the foreground service.
7. Test on a Snapdragon 680 / Helio G99-class device against the PRD section 5 metrics.
