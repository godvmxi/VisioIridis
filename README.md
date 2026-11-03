# 伊利斯之视 · Visio Iridis

**专为听障人士设计的离线实时语音字幕应用**

[![Release](https://img.shields.io/github/v/release/godvmxi/VisioIridis)](https://github.com/godvmxi/VisioIridis/releases)
[![Platform](https://img.shields.io/badge/platform-Android-green)](https://github.com/godvmxi/VisioIridis/releases)

[English README →](README_EN.md)

---

## 简介

Visio Iridis 是一款面向听障人士的实时语音转字幕工具。核心设计原则是**完全离线运行**——语音识别在本地设备完成，无需联网，无需将任何语音数据上传至服务器，保护用户隐私。

### 主要特性

- **完全离线**：识别引擎运行于设备本地，无网络亦可正常使用
- **实时转写**：低延迟语音识别，字幕即说即显
- **多语言支持**：普通话、粤语、英语同时识别
- **双音源**：支持麦克风（周围声音）和系统播放声音（媒体字幕）
- **后台浮窗**：切到其他应用时保持字幕悬浮显示
- **无障碍优先**：字号、字重可调，高对比度配色

---

## 下载

前往 [Releases](https://github.com/godvmxi/VisioIridis/releases) 页面下载最新 APK。

---

## 构建

需要 Flutter 3.47+：

```bash
flutter pub get
flutter build apk --release
```

---

## 技术栈

- Flutter（Android）
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) — 本地语音识别引擎
- Riverpod — 状态管理
