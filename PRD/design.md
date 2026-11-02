伊利斯之视 (Visio Iridis) —— 听障离线实时字幕助手

# 1. 文档概述
## 1.1 背景与痛点
现有移动端语音转文字（ASR）工具多面向会议纪要或通用听写，在听障人士面对面交流场景中存在核心痛点：
- 网络强依赖与高延迟：无网、弱网（如电梯、地下室、商场角落）直接瘫痪；云端往返延迟常超过 1 秒，破坏即时对话流。
- 多语言/方言识别割裂：日常交流中普通话、粤语、英语高频混讲，市面多数软件需手动进设置切换语言包，无法自适应。
- 视觉设计不符合无障碍需求：文字字号偏小、对比度不足、缺乏视觉锚点；流式输出时整屏文字疯狂跳动，造成强烈的视觉眩晕。


## 1.2 产品定位
一款基于 Android (Flutter 跨平台技术栈) 开发的纯离线、低延迟、高对比度无障碍实时字幕工具。既可作为独立 App 安装在个人手机上，也可通过单任务展厅模式（Kiosk Mode）部署在专用的便携式硬件盒子上。


## 1.3 核心目标
- 离线可用：模型就绪后，识别全程不依赖网络。联网只用于两件事：下载模型配置与模型文件（首次使用或模型更新时，见 4.5），以及默认关闭、需用户主动开启的“在线 AI 纠错”。
- 低延迟响应：从 VAD 判定句尾（静音满 400ms）到定稿字幕完整上屏，延迟控制在 300ms 以内；说话人闭口到上屏的总时延因此约为 400ms + 300ms ≤ 700ms。推理吞吐要求 RTF < 0.1。
- 自适应多语言：原生混合自动识别普通话、粤语、英语。
- 无障碍防眩晕：采用“历史滚动 + 底部最新结果绝对置顶”分层布局与大字高对比配色。

# 2. 用户画像与核心使用场景
| 维度 | 描述 |
| ---  | ---  |
| 主要目标用户 | 具备文字阅读能力的听力受损人士（轻度到重度听障、老年性耳背）。|
| 次要使用人群 | 听障人士的家属、同事、柜台服务人员、医护人员等日常沟通对象。 | 
| 场景 A：双人面对面沟通 | 用户将手机/设备立在桌面或手持，麦克风正对健听人。健听人正常交谈，听障用户通过屏幕下方的固定高亮区实时获取信息。|
| 场景 B：弱网/无网移动场景 | 乘车、地铁、野外、商场地下停车场等无法连接 Wi-Fi 或蜂窝网络的环境下，保证助听功能 100% 正常运转。
| 场景 C：多语种/方言混讲 | 在粤港澳地区、跨国企业或海外华人日常交际中，交流中频繁出现中英夹杂（Code-Switching）或普粤交替 |

# 3. 功能架构与系统数据流
```bash
┌─────────────────────────────────────────────────────────────┐
│                       Flutter UI 层                          │
│   顶部语言选择栏 ──► 历史流式列表 ──► 最新高亮卡片 ──► 底部主按键   │
└──────────────────────────────▲──────────────────────────────┘
                               │ Stream<SubtitleItem>
┌──────────────────────────────┴──────────────────────────────┐
│                    Dart 业务逻辑调度层                       │
│  - 状态管理 (Riverpod / Bloc)                                │
│  - 模型配置加载、模型下载/校验/缓存 (见 4.5)                  │
│  - 语言模式参数映射 (zh / yue / en / auto)                    │
│  - 语种标签校验与重解码 (见 4.1)                              │
│  - 事件/情绪标签过滤与格式化 (<|Laughter|> -> 😄)             │
│  - 屏幕常亮与触觉震动反馈管理                                 │
└──────────────────────────────▲──────────────────────────────┘
                               │ SendPort/ReceivePort (Isolate 消息)
┌──────────────────────────────┴──────────────────────────────┐
│        推理 Isolate (Dart FFI → sherpa-onnx C++ 动态库)      │
│                                                             │
│   [record 插件] 16kHz, 16bit, Mono PCM 流 (主 Isolate 采集)   │
│         │  转 Float32 后发送给推理 Isolate                   │
│         ▼                                                   │
│   [Silero-VAD] 语音端点检测 (静音 400ms 触发句子切片)         │
│         │                                                   │
│         ├──► 说话中：每 ~300ms 对当前未结束片段重解码，       │
│         │    输出“临时结果”(partial)                         │
│         ▼                                                   │
│   [SenseVoice-Small INT8] 非自回归解码 (numThreads = 2)      │
│         │  句尾：整段解码一次，输出“定稿结果”(final)          │
│         ▼                                                   │
│   [OpenCC] (可选) 简繁统一规则引擎                            │
│         │                                                   │
│         ▼                                                   │
│   [Online AI] (可选, 默认关闭) 在线 AI 纠错，仅作用于定稿结果  │
└─────────────────────────────────────────────────────────────┘

[Android 原生层] 前台服务 (foregroundServiceType=microphone)
保活拾音进程；AudioDeviceCallback 监听麦克风热插拔。
```

> **关于“实时更新”的说明**：SenseVoice 是非流式模型，必须拿到一段完整音频才能解码，没有原生的逐字流式输出。本方案用“片段内周期性重解码”生成临时结果：每次重解码的音频是从句首到当前时刻，长度随说话时间增长，因此 VAD 需设置最长片段上限（建议 15s，超长强制切句），以控制重解码开销。若实测 CPU 超出 5.1 指标，可将重解码间隔放宽到 500ms，或在低端机上关闭临时结果、只显示定稿结果。

# 4. 详细功能规格说明
## 4.1 顶部控制栏 (Top Bar)
- 元素构成：
  - 若干带状态勾选框的语言胶囊按钮，由模型配置中的语言列表生成（见 4.5.3）。默认配置为普通话、粤语、英语、河南话四个。
  - 1 个清屏动作图标按钮（垃圾桶图标）。
- 交互规则：
  - 默认状态：按配置中的 defaultEnabled 勾选。默认配置下普通话、粤语、英语勾选，河南话不勾选。
  - 联动逻辑：以下为使用 SenseVoice 模型（普通话、粤语、英语）时的规则，是 4.5.3 通用匹配规则的具体表现。勾选河南话等需要其他模型的语言时，按 4.5.3 处理。
    - 三者均勾选时：传参 language="auto"，启用全自动混识。
    - 单独勾选某一项（如仅勾选“英语”）：传参 language="en"，避免外部白噪音被误解码为汉字。
    - 仅勾选两项（如普通话 + 英语）：先以 language="auto" 解码，读取 SenseVoice 输出的语种标签（zh / yue / en，sherpa-onnx 结果中的 lang 字段）。若检测到的语种已勾选，直接采用；若检测到的是未勾选语种（如粤语），则用已勾选的主语种（按 普通话 > 粤语 > 英语 的优先级选取）强制重解码一次。重解码只在定稿时执行，临时结果不做此校验。
      - 说明：sherpa-onnx 不提供逐字置信度，无法实现“对粤语虚词做置信度惩罚”，故改为语种标签校验方案。
    - **防空保护**：禁止取消全部语言；若用户试图取消最后一个激活项，界面抖动并 Toast 提示“至少保留一种识别语言”。
  - 清屏操作：点击清屏图标，弹出底部轻量 ActionSheet 二次确认：“确认清空所有历史字幕记录？”，点击确认后清空历史列表，最新卡片内容重置。

## 4.2 历史记录展示区 (History Area)
- 布局：占据屏幕中间约 55% ~ 60% 高度，使用弹性列表渲染。
- 样式规则：
  - 背景底色：纯黑 #000000。
  - 字体与颜色：次级浅灰 #B0B0B0，行高 1.5，字号 18sp ~ 20sp。
  - 时间线标识：每段文字前缀显示 [HH:mm] 浅灰时间戳（#666666）。
- 滚动与交互：
  - 排列顺序：按时间正序排列，最旧在上、最新在下；新句子追加到列表末尾（`history.add`）。
  - 自动跟随：每当一条新句子从“最新展示区”沉淀进入历史区时，列表自动平滑滚动到底部（Duration: 250ms, Curve: easeOut）。
  - 人工介入锁定：当检测到用户手势向上拖拽浏览历史时，立刻解绑“自动到底部”状态，防止新文字强行拉动屏幕破坏阅读体验。用户手动滚回底部（距底部 < 24dp）时自动恢复跟随。
  - 回到底部悬浮键：只要处于“自动跟随已解绑”状态，右下角即淡入浮现“回到最新”悬浮按钮，按钮上的 Badge 显示解绑后新增的条数；点击后回滚到底部并恢复自动跟随。
  
## 4.3 固定的最新转换卡片 (Current Focus Card)
- 布局：固定在历史列表与底部大按钮之间，高度自适应（约 120dp ~ 150dp），不随历史滚动。
- 样式规则：
  - 卡片背景：深灰表面色 #1E1E1E，边框描边 1dp (#333333)，圆角 16dp。
  - 状态指示灯：卡片左上角显示 8dp 圆形指示点。拾音中呈浅绿微呼吸动效（#10B981），暂停呈静态浅灰（#666666）。
  - 文字规格：加粗明黄（#FFE600），字号 28sp ~ 32sp，行高 1.35。临时结果使用同色 70% 不透明度，定稿后变为 100%，让用户区分“可能还会变”和“已确定”。
- 状态机与内容更新机制：
  - 空闲态：文本显示浅灰占位符 “等待语音输入...”。
  - 收音中 (VAD 激活)：显示当前片段的临时结果，约每 300ms 刷新一次（见第 3 章说明）。为减轻跳动，新结果与旧结果的公共前缀保持不动，只替换变化的尾部。
  - 断句与沉淀 (VAD 静音触发)：
    - 当说话人停顿超过 400ms，当前句子判定完成，整段解码得到定稿结果并替换临时结果。
    - 微动画：当前句子向上平移淡出，同时追加到历史记录列表末尾，卡片在 100ms 内淡入准备接收下一句。
  - 事件/情绪标签映射（SenseVoice 原始标签大小写不统一，匹配时忽略大小写）：
    - <|Laughter|> $\to$ 😄 [笑声]
    - <|Applause|> $\to$ 👏 [掌声]
    - <|Cry|> $\to$ 😢 [哭泣声]
    - <|Speech|>、<|BGM|>、<|NEUTRAL|>、<|zh|> 等其余标签：从显示文本中剔除，不上屏。
    
## 4.4 底部控制主按键 (Bottom Action Button)
- 布局：占据底部绝对安全区域，外边距左右 16dp，按键高 60dp，圆角 30dp。
- 状态切换：
  - 未拾音态：翡翠绿底色（#10B981），图标 Icons.mic_rounded，文字 “开始识别”（20sp 加粗白字）。
  - 拾音中态：高饱和警示红（#DC2626），图标 Icons.stop_rounded，文字 “停止识别”。
- 物理反馈：点击时必须触发系统级短震（HapticFeedback.heavyImpact()），给予听障人士明确的触觉操作确认。
- 权限：首次点击“开始识别”时申请麦克风权限（Android 13+ 同时申请通知权限，用于前台服务常驻通知）。用户拒绝时，在卡片区显示说明文字与“去设置”按钮，不反复弹窗。

## 4.5 模型配置与下载 (Model Config & Download)
安装包不内置模型。App 通过一份“模型配置”得知有哪些模型可用、从哪里下载、如何校验，以及每个模型支持哪些语言；需要模型时再下载。

### 4.5.1 配置来源与更新
- **内置默认配置**：随 App 打包在 `assets/config/model_config.json`，内容即 4.5.4 的示例配置。保证从未联网时也有一份完整配置。
- **远程配置**：从配置中的 `remoteConfigUrl` 下载（正式地址待定）。
  - 时机：App 启动后在后台检查，不阻塞界面；距上次成功检查不足 24 小时则跳过；请求超时 5s。
  - 接受条件：必须是 HTTPS；JSON 能正常解析；`schemaVersion` 是当前 App 支持的版本；`configVersion` 大于正在使用的配置。任一条件不满足即丢弃，继续使用当前配置，不提示用户。
  - 生效：校验通过后保存到应用私有目录，作为“最近可用配置”。识别进行中不切换，下次点击“开始识别”时生效。
  - 优先级：最近可用的远程配置 > 内置默认配置。
- **安全**：配置决定了 App 从哪里下载什么文件，因此只接受 HTTPS，且每个模型文件都必须通过配置中的 sha256 校验才会被使用。Phase 2 增加配置签名（如 Ed25519），防止配置服务器被篡改后下发恶意地址。
- **权限**：本功能需要 `INTERNET` 权限，不需要存储权限（见 4.5.5）。

### 4.5.2 配置字段
| 字段 | 说明 |
| --- | --- |
| `schemaVersion` | 配置格式版本。App 只接受自己支持的版本，格式不兼容时整份丢弃。 |
| `configVersion` | 配置内容版本，单调递增，用于判断远程配置是否比当前的新。 |
| `remoteConfigUrl` | 下次检查更新时使用的地址，允许配置自身迁移地址。 |
| `languages[]` | 语言列表。`id`：语言标识；`name`：胶囊上显示的名称；`defaultEnabled`：是否默认勾选；`order`：显示顺序。 |
| `vad` | VAD 模型，所有识别模型共用。字段同下方模型的 `id` / `version` / `files`。 |
| `asrModels[]` | 识别模型列表，字段见下表。 |

识别模型（`asrModels[]` 的每一项）：
| 字段 | 说明 |
| --- | --- |
| `id` / `name` | 模型标识与显示名称。 |
| `type` | sherpa-onnx 模型类型，决定加载方式。当前支持 `sense_voice`、`telespeech_ctc`。 |
| `version` | 模型版本，用作存储目录名；版本变化即视为新模型，需重新获取。 |
| `license` | 模型许可说明，供关于页展示。 |
| `files[]` | 模型包含的文件。`name`：文件名；`size`：字节数；`sha256`：校验值；`urls[]`：下载地址，按顺序尝试，前一个失败自动换下一个（用于国内镜像）。 |
| `languages[]` | 支持的语言。`lang`：对应 `languages[].id`；`weight`：优先权重（0–100，表示该模型对此语言的识别质量，越高越优先）；`decodeParam`：仅识别该语言时传给模型的语言参数，为空表示该模型不支持指定语言。 |
| `autoDecodeParam` | 勾选多种语言时传给模型的语言参数，如 SenseVoice 的 `auto`；为空表示不传参。 |

### 4.5.3 语言与模型的匹配规则
- **同一时间只加载一个识别模型**，以满足 5.1 的内存上限（450MB）。
- **选择模型**：在支持全部已勾选语言的模型中，选权重之和最高的；权重相同时选文件总大小更小的。
- **勾选冲突**：用户勾选语言 L 后，如果没有任何模型能同时支持全部已勾选语言，则以对 L 权重最高的模型为准：保留该模型支持的已勾选语言，自动取消其余语言，并 Toast 提示，例如“河南话需要切换到 TeleSpeech 模型，已取消：粤语、英语”。这样任何时候的勾选组合都能对应到唯一模型。
- **解码参数**：只勾选一种语言时，使用该语言的 `decodeParam`；勾选多种时使用模型的 `autoDecodeParam`；参数为空则不传。4.1 中的 zh / yue / en / auto 规则就是 SenseVoice 在这套机制下的结果。4.1 的“语种校验与重解码”只对会输出语种标签的模型（SenseVoice）生效。
- **切换模型**：识别中因语言勾选变化需要换模型时，暂停拾音，卡片显示“正在切换识别模型...”，推理 Isolate 释放旧模型、加载新模型（目标 ≤ 3s），完成后自动恢复拾音。新模型尚未下载时，按 4.5.5 的流程获取。
- **默认配置下的结果**：
  | 勾选的语言 | 使用的模型 | 语言参数 |
  | --- | --- | --- |
  | 普通话 + 粤语 + 英语（默认） | SenseVoice | auto |
  | 仅英语 | SenseVoice | en |
  | 仅河南话 | TeleSpeech | 不传 |
  | 普通话 + 河南话 | TeleSpeech（只有它同时支持两者） | 不传 |
  | 在默认三项基础上再勾选河南话 | TeleSpeech，自动取消粤语、英语 | 不传 |

### 4.5.4 示例配置（即内置默认配置）
文件大小与 sha256 均为 2026-11-02 从 Hugging Face / GitHub 实际获取的真实值；`remoteConfigUrl` 为占位地址，正式地址待定。VAD 文件目前只有 GitHub 一个下载地址，国内镜像待补充。
```json
{
  "schemaVersion": 1,
  "configVersion": 1,
  "remoteConfigUrl": "https://example.com/visio-iridis/model_config.json",
  "languages": [
    { "id": "zh",    "name": "普通话", "defaultEnabled": true,  "order": 1 },
    { "id": "yue",   "name": "粤语",   "defaultEnabled": true,  "order": 2 },
    { "id": "en",    "name": "英语",   "defaultEnabled": true,  "order": 3 },
    { "id": "henan", "name": "河南话", "defaultEnabled": false, "order": 4 }
  ],
  "vad": {
    "id": "silero-vad",
    "version": "1",
    "files": [
      {
        "name": "silero_vad.onnx",
        "size": 643854,
        "sha256": "9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6",
        "urls": [
          "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"
        ]
      }
    ]
  },
  "asrModels": [
    {
      "id": "sense-voice-small-int8",
      "name": "SenseVoice Small",
      "type": "sense_voice",
      "version": "2024-07-17",
      "license": "FunASR Model License",
      "files": [
        {
          "name": "model.int8.onnx",
          "size": 239233841,
          "sha256": "c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51",
          "urls": [
            "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx",
            "https://hf-mirror.com/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/model.int8.onnx"
          ]
        },
        {
          "name": "tokens.txt",
          "size": 315894,
          "sha256": "f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc",
          "urls": [
            "https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt",
            "https://hf-mirror.com/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/tokens.txt"
          ]
        }
      ],
      "languages": [
        { "lang": "zh",  "weight": 100, "decodeParam": "zh" },
        { "lang": "yue", "weight": 100, "decodeParam": "yue" },
        { "lang": "en",  "weight": 90,  "decodeParam": "en" }
      ],
      "autoDecodeParam": "auto"
    },
    {
      "id": "telespeech-ctc-int8",
      "name": "TeleSpeech",
      "type": "telespeech_ctc",
      "version": "2024-06-04",
      "license": "TeleSpeech 模型社区许可协议",
      "files": [
        {
          "name": "model.int8.onnx",
          "size": 340990949,
          "sha256": "2bf52b42c971696dc02a2db94c52c8fc75fab321ac4cf10b5a2d6863a73a33b3",
          "urls": [
            "https://huggingface.co/csukuangfj/sherpa-onnx-telespeech-ctc-int8-zh-2024-06-04/resolve/main/model.int8.onnx",
            "https://hf-mirror.com/csukuangfj/sherpa-onnx-telespeech-ctc-int8-zh-2024-06-04/resolve/main/model.int8.onnx"
          ]
        },
        {
          "name": "tokens.txt",
          "size": 66642,
          "sha256": "f1dea25fe751bc3eebd27b2ff3b86298f9598686a090701990dabddde0eba508",
          "urls": [
            "https://huggingface.co/csukuangfj/sherpa-onnx-telespeech-ctc-int8-zh-2024-06-04/resolve/main/tokens.txt",
            "https://hf-mirror.com/csukuangfj/sherpa-onnx-telespeech-ctc-int8-zh-2024-06-04/resolve/main/tokens.txt"
          ]
        }
      ],
      "languages": [
        { "lang": "zh",    "weight": 70, "decodeParam": "" },
        { "lang": "henan", "weight": 90, "decodeParam": "" }
      ],
      "autoDecodeParam": ""
    }
  ]
}
```
> **示例数据说明**：
> - 权重为示例值，可按实际使用效果调整。
> - TeleSpeech 使用自有的社区许可协议，商用前需确认授权条款。

### 4.5.5 模型获取与存储
- **存储位置**：不访问外部公共存储，不申请任何存储权限。
  | 位置 | 路径 | 作用 |
  | --- | --- | --- |
  | 外置存储（应用专属目录） | `Android/data/com.seevoice.seevoice/files/models/<模型id>/<version>/`（`getExternalStorageDirectory`） | 长期保存下载好的模型，卸载 App 时一并删除。盒子出厂时可通过 adb 预置模型。 |
  | cache 目录 | `<应用私有 cache>/models/<模型id>/<version>/` | 推理时实际加载的位置。 |
  - 外置存储中的文件可能被改动，因此复制到 cache 后必须做 sha256 校验（见下方第 2 步）。
- **获取流程**：需要某个模型时（点击“开始识别”或切换模型），对模型的每个文件分别执行：
  1. **检查 cache**：文件存在且大小与配置一致，直接使用。启动时只比较大小、不算 sha256，避免每次启动耗时数秒。
  2. **检查外置存储**：找到大小一致的文件后复制到 cache 的临时文件并校验 sha256，通过则重命名为正式文件后使用；不通过则删除临时文件，进入第 3 步。
  3. **下载**：按 `urls` 顺序下载到 cache 的 `.part` 临时文件，支持断点续传（HTTP Range）；前一个地址失败自动换下一个，所有地址都失败则报错。下载完成后校验 sha256，不通过则删除并报错；通过则先复制一份到外置存储（覆盖其中已损坏的旧文件），再重命名为 cache 中的正式文件。
  - 因此每次下载前都会先检查外置存储，已有且校验通过的文件不会重复下载。
  - 系统在存储紧张时可能清空 cache 目录，下次需要时会自动从外置存储重新复制，无需重新下载。
- **空间检查**：下载前检查外置存储剩余空间 ≥ 待下载大小；复制前检查 cache 所在分区剩余空间 ≥ 模型大小。同一模型在外置存储和 cache 各存一份，SenseVoice 约占 2 × 229MB。
- **用户提示**：
  - 下载前弹窗告知模型名称和大小；使用移动数据时额外提示流量消耗，由用户确认后才开始。
  - 下载过程中在最新卡片位置显示进度（已下载 / 总大小，可取消），底部主按键禁用。
  - 无网络且本地没有可用模型时，卡片显示“需要先下载识别模型，请连接网络”，不弹出网络错误。
- **旧版本清理**：配置更新导致模型 `version` 变化时，新版本就绪并成功加载一次后，删除外置存储和 cache 中的旧版本目录。


## 4.6 设置页 (Settings)
- 入口：顶部控制栏清屏按钮右侧的齿轮图标，进入独立的设置页面。所有设置立即生效并持久保存（shared_preferences），重启后保留。
- **字体大小**：五档分段按钮，同时调整最新卡片与历史区字号；卡片高度随字号缩放（约容纳 3 行）。页面内提供按当前字号与配色渲染的预览。
  | 档位 | 最新卡片 | 历史区 |
  | --- | --- | --- |
  | 标准 | 28sp | 18sp |
  | 大（默认） | 36sp | 22sp |
  | 特大 | 44sp | 26sp |
  | 超大 | 52sp | 30sp |
  | 巨大 | 60sp | 34sp |
- **配色模式**：三选一，每项旁显示色块预览。开始/停止按键的绿色与红色不随配色变化。
  | 模式 | 背景 | 最新卡片文字 | 历史文字 | 卡片底色 |
  | --- | --- | --- | --- | --- |
  | 黄字黑底（默认，即 4.2/4.3 规定的配色） | #000000 | #FFE600 | #B0B0B0 | #1E1E1E |
  | 白字黑底 | #000000 | #FFFFFF | #B0B0B0 | #1E1E1E |
  | 黑字白底 | #FFFFFF | #000000 | #424242 | #F2F2F2 |
- **识别模型（按语言）**：列出顶部栏可勾选的每种语言，下拉选择“自动（当前按权重会选中的模型名）”或任一支持该语言的模型。
  - 选择模型时（4.5.3 的扩展）：在支持全部已勾选语言的模型中，被越多已勾选语言指定的模型越优先；指定次数相同时按权重之和、再按文件总大小选择。被指定的模型若不支持全部已勾选语言，则不会被选中。
  - 配置更新后，已不存在或不再支持该语言的指定视为“自动”。
  - 修改在下次点击“开始识别”时生效；识别进行中不切换模型。

# 5. 非功能性需求 (NFR)
## 5.1 性能指标
- 推理延迟 (Latency)：在搭载骁龙 680 / 联发科 G99 及以上级别硬件上，SenseVoice-Small INT8 单句推理耗时需 $\le 120\text{ ms}$。
- 整句上屏时延：从 VAD 判定句尾（静音满 400ms）到最新卡片渲染定稿结果，延迟 $\le 300\text{ ms}$。说话人闭口到上屏的总时延 = 400ms 静音判定 + 本项，约 $\le 700\text{ ms}$。
- 临时结果刷新：说话期间临时结果刷新间隔约 300ms。
- 内存占用：App 完整加载模型并启动拾音流水线后，整体 PSS 运行内存 $\le 450\text{ MB}$。
- CPU 占用：双线程推理模式下，非工作静音态 CPU 占用 $\le 3\%$；持续说话（含临时结果重解码）时综合 CPU 占用 $\le 35\%$。超标时按第 3 章说明降级。
- UI 流畅度：字幕滚屏与状态动画必须稳定在 60 FPS。VAD 与 SenseVoice 推理必须在常驻的后台 Isolate 中执行；模型在该 Isolate 启动时加载一次，之后常驻，禁止每句重新加载。

## 5.2 模型分发
- 安装包不内置模型，按 4.5 的流程在首次使用时下载。SenseVoice-Small INT8 约 229MB，若打包进 APK 会超过 Google Play 基础 APK 的 200MB 上限；改为下载后不再有此问题，也无需 Play Asset Delivery。
- 硬件盒子版本：出厂前通过 adb 把模型推送到 4.5.5 所述的应用专属目录 `Android/data/com.seevoice.seevoice/files/models/`（需先安装 App 以创建该目录）。首次启动时直接从该目录复制到 cache，全程无需联网。

## 5.3 功耗与续航
- 常亮管理：开启识别时调用 WakelockPlus.enable() 保持屏幕长亮；停止识别后 3 分钟无操作，恢复系统级自动休眠。 
- 连续工作发热：室温（25℃）下连续工作 2 小时，设备表面温度上升不得超过 10℃，不得因过热引发降频卡顿。

## 5.4 稳定性与容错
- 无网络环境：模型已就绪时，完全断开 Wi-Fi 和蜂窝移动网络下，除“在线 AI 纠错”外功能 100% 完整，无任何网络报错弹窗；在线 AI 请求失败时静默回退到离线结果；远程配置检查失败时静默使用当前配置。模型未就绪且无网络时，按 4.5.5 在卡片中提示，不弹窗。
- 麦克风占用/热插拔：当插入或拔出 Type-C 领夹无线麦时，音频引擎需在 500ms 内自动停止并重建录音流，不得闪退。实现上由 Android 原生层的 AudioDeviceCallback 通知 Dart 层重启 record 流。
- 前台服务保活：声明 FOREGROUND_SERVICE 与 FOREGROUND_SERVICE_MICROPHONE 权限，Service 设置 foregroundServiceType="microphone"，附带常驻通知栏提示，防止被系统低内存策略意外杀死。注意 Android 14+ 要求该前台服务必须在 App 处于前台时启动（即用户点击“开始识别”时）。


# 6. 技术实现路径与工程架构 (Flutter)
## 6.1 核心依赖库清单
| 依赖项 | 版本/来源 | 用途说明 |
| ---   | ---  | --- |
| sherpa_onnx | 官方 flutter package | 通过 Dart FFI 调用 C++ 动态库，运行 SenseVoice、TeleSpeech 等识别模型及 Silero-VAD | 
| http | pub.dev 最新稳定版 | 下载模型配置与模型文件（支持 Range 断点续传） |
| crypto | pub.dev 最新稳定版 | 模型文件 sha256 校验 |
| record | pub.dev 最新稳定版 | 16kHz, 16bit 单声道 Raw PCM 流式采集（`startStream`） |
| permission_handler | pub.dev 最新稳定版 | 麦克风、通知权限申请 |
| flutter_foreground_task | pub.dev 最新稳定版 | 麦克风类型前台服务与常驻通知 |
| wakelock_plus | pub.dev 最新稳定版 | 保持屏幕常亮 | 
| flutter_riverpod | pub.dev 最新稳定版 | 状态管理 |
| path_provider | pub.dev 最新稳定版 | 获取 cache 目录与应用专属外置目录 |
| shared_preferences | pub.dev 最新稳定版 | 保存设置页中的字号、配色与模型选择（4.6） |
| OpenCC（待选型） | — | 粤语与普通话输出文本的繁简规范化。pub.dev 上 OpenCC 封装成熟度不一，Phase 1 不做，Phase 2 再评估（备选：自带词表的纯 Dart 实现） |
| 在线 AI（可选） | OpenAI 兼容接口 | 纠正识别错别字、辅助语义理解；默认关闭，开启前需向用户说明“文字将发送至第三方服务” |


## 6.2 状态管理与数据结构设计
```dart
// 字幕项实体
class SubtitleItem {
  final String id;
  final DateTime timestamp;
  final String text;
  final String? lang;       // SenseVoice 检测语种: "zh" / "yue" / "en"
  final String? emotionTag; // 情绪: "HAPPY" / "SAD" 等
  final String? eventTag;   // 音频事件: "Laughter" / "Applause" / "Cry" 等

  SubtitleItem({
    required this.id,
    required this.timestamp,
    required this.text,
    this.lang,
    this.emotionTag,
    this.eventTag,
  });

  String get formattedTime => 
      "[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}]";
}

// 引擎配置状态
class AsrEngineState {
  final bool isListening;
  final bool isMandarinEnabled;
  final bool isCantoneseEnabled;
  final bool isEnglishEnabled;
  final String currentPendingText;
  final List<SubtitleItem> history;

  AsrEngineState({
    this.isListening = false,
    this.isMandarinEnabled = true,
    this.isCantoneseEnabled = true,
    this.isEnglishEnabled = true,
    this.currentPendingText = "",
    this.history = const [],
  });

  // 传给 SenseVoice 的 language 参数，规则见 4.1
  String get languageParam {
    final enabled = [
      if (isMandarinEnabled) "zh",
      if (isCantoneseEnabled) "yue",
      if (isEnglishEnabled) "en",
    ];
    return enabled.length == 1 ? enabled.first : "auto";
  }
}
```

模型配置（对应 4.5.2 的 JSON 结构）：
```dart
class ModelConfig {
  final int schemaVersion;
  final int configVersion;
  final String remoteConfigUrl;
  final List<LanguageDef> languages;
  final ModelDef vad;
  final List<AsrModelDef> asrModels;
}

class LanguageDef {
  final String id;          // "zh" / "yue" / "en" / "henan"
  final String name;        // 胶囊显示名称
  final bool defaultEnabled;
  final int order;
}

class ModelDef {
  final String id;
  final String version;     // 存储目录名，变化即视为新模型
  final List<ModelFile> files;
}

class AsrModelDef extends ModelDef {
  final String name;
  final String type;        // "sense_voice" / "telespeech_ctc"
  final String license;
  final List<LanguageSupport> languages;
  final String autoDecodeParam;
}

class ModelFile {
  final String name;
  final int size;
  final String sha256;
  final List<String> urls;  // 按顺序尝试
}

class LanguageSupport {
  final String lang;        // 对应 LanguageDef.id
  final int weight;         // 0–100，越高越优先
  final String decodeParam; // 空串表示不支持指定语言
}
```

# 7. 版本迭代规划
## Phase 1: MVP 基础验证版 (当前阶段)
- [ ] 搭建 Flutter 主页面骨架与三段式 UI。
- [ ] 集成 sherpa-onnx 与 SenseVoice-Small INT8 + Silero-VAD。
- [ ] 实现普/粤/英自动切换与本地离线推理。
- [ ] 实现模型配置（内置默认 + 远程更新）与模型下载、校验、外置存储到 cache 的缓存流程（4.5）。
- [ ] 按配置生成语言胶囊，实现语言与模型的匹配和模型切换（4.5.3）。
- [ ] 设置页：字体大小、配色模式、按语言选择识别模型（4.6）。
- [ ] 实现屏幕常亮与触觉反馈。


## Phase 2: 无障碍体验深化版
- [ ] 情绪标签（SenseVoice 自带的喜怒哀乐、掌声、笑声）全量图形化渲染。
- [ ] 支持外部 Type-C / 蓝牙麦克风电量与连接状态实时监控指示。
- [ ] 历史记录导出（支持一键导出为 TXT 文件分享至系统其他 App）。
- [ ] 模型配置签名校验（如 Ed25519），防止配置被篡改。

## Phase 3: 硬件与定制版 (盒子方案)
- [ ] 适配 Android Kiosk 模式（开机自启动、屏蔽系统导航条、禁止用户退出）。
- [ ] 增加双向分屏模式（屏幕上半部分反转 180 度面向对方，屏幕下半部分正向面向听障者）。
