# Project Plan

Create an offline ASR/STT (Speech-to-Text) Android application named SeeSound using sherpa-onnx. The app supports recording audio from the microphone, saving/getting WAV recordings, and performing offline speech recognition using sherpa-onnx offline recognizer models (e.g., zipformer or transducer models), displaying real-time or post-recording transcription results locally without internet dependency.

## Project Brief

# Project Brief: SeeSound (Offline ASR/STT Android App)

## Features (MVP)

1. **Audio Recording & WAV Management**: Record audio from the device microphone, save recordings locally as standard WAV files in app-specific storage, and list/retrieve saved WAV recordings.
2. **Offline Speech Recognition (ASR)**: Perform offline speech-to-text processing using sherpa-onnx offline recognizer models (such as zipformer or transducer models) entirely on-device without internet dependency.
3. **Transcription Viewer & Management**: Display transcription results locally in real-time or post-recording, with options to view, copy, or manage transcription history.
4. **Adaptive Navigation & UI**: State-driven navigation powered by **Jetpack Navigation 3** and responsive multi-pane layouts utilizing the **Compose Material Adaptive** library.

## High-Level Tech Stack

- **Language**: Kotlin
- **UI Toolkit**: Jetpack Compose, Material 3
- **Adaptive Layouts & Navigation**:
  - **Compose Material Adaptive**: For responsive layouts across phones, foldables, and tablets.
  - **Jetpack Navigation 3**: For state-driven navigation flows.
- **Concurrency & State Management**: Kotlin Coroutines & `StateFlow`
- **Speech Recognition Engine**: `sherpa-onnx` (Offline ASR engine supporting zipformer/transducer models)
- **Audio Capture**: Android `AudioRecord` / `MediaRecorder` APIs for microphone capture and WAV file encoding
- **Storage**: Local app-specific internal storage for WAV audio files and model assets (no external databases or cloud persistence layers required)

## Implementation Steps

