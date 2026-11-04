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
- 元素构成（从左到右依次排列，保持一行；清空与设置固定在右侧）：
  1. “声音来源”二选一按钮：只显示文字“麦克风”/“喇叭”，不显示图标（见 4.8）。
  2. 主语言按钮：显示第一个已勾选的主语言，勾选多种时附上其余数量（如“普通话 +2”），右侧有下拉箭头。点击弹出“识别语言”窗口：
     - 显示当前模型名称（按勾选语言与设置页模型偏好选出，见 4.5.3、4.6）；
     - 普通话、粤语、英语三个勾选项，用于选择主语言；试图取消最后一项时在窗口内提示“至少保留一种识别语言”；
     - 当前模型还支持的其他语言或方言（如 SenseVoice 的日语、韩语，TeleSpeech 的河南话）列在“还可自动识别”下，并说明勾选多种语言（自动识别）时可识别。
  3. 清空记录图标按钮（垃圾桶）。
  4. 设置图标按钮。
- 交互规则：
  - 默认状态：按配置中的 defaultEnabled 勾选。默认配置下普通话、粤语、英语勾选，河南话不勾选。
  - 联动逻辑：以下为使用 SenseVoice 模型（普通话、粤语、英语）时的规则，是 4.5.3 通用匹配规则的具体表现。勾选河南话等需要其他模型的语言时，按 4.5.3 处理。
    - 三者均勾选时：传参 language="auto"，启用全自动混识。
    - 单独勾选某一项（如仅勾选“英语”）：传参 language="en"，避免外部白噪音被误解码为汉字。
    - 仅勾选两项（如普通话 + 英语）：先以 language="auto" 解码，读取 SenseVoice 输出的语种标签（zh / yue / en，sherpa-onnx 结果中的 lang 字段）。若检测到的语种已勾选，直接采用；若检测到的是未勾选语种（如粤语），则用已勾选的主语种（按 普通话 > 粤语 > 英语 的优先级选取）强制重解码一次。重解码只在定稿时执行，临时结果不做此校验。
      - 说明：sherpa-onnx 不提供逐字置信度，无法实现“对粤语虚词做置信度惩罚”，故改为语种标签校验方案。
    - **防空保护**：禁止取消全部语言；若用户试图取消最后一个激活项，在识别语言窗口内提示“至少保留一种识别语言”。
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
- **远程配置**：App 根据 4.5.6 的地区判断结果选择下载地址，不依赖配置中的 `remoteConfigUrl` 字段：
  - 海外环境：`https://raw.githubusercontent.com/godvmxi/VisioIridisConfig/refs/heads/master/model_config.json`
  - 大陆环境：`https://raw.giteeusercontent.com/godvmxi/VisioIridisConfig/raw/master/model_config.json`
  - 地区未知（首次启动且探测尚未完成）：依次尝试两个地址，取首个成功的结果。
  - 时机：App 启动后在后台检查，不阻塞界面；距上次成功检查不足 24 小时则跳过；请求超时 5s。
  - 接受条件：必须是 HTTPS；JSON 能正常解析；`schemaVersion` 是当前 App 支持的版本；`configVersion` 大于正在使用的配置。任一条件不满足即丢弃，继续使用当前配置，不提示用户。
  - 生效：校验通过后保存到应用私有目录，作为“最近可用配置”。识别进行中不切换，下次点击“开始识别”时生效。
  - 优先级：最近可用的远程配置 > 内置默认配置。
- **安全**：配置决定了 App 从哪里下载什么文件，因此只接受 HTTPS，且每个模型文件都必须通过配置中的 sha256 校验才会被使用。Phase 2 增加配置签名（如 Ed25519），防止配置服务器被篡改后下发恶意地址。
- **权限**：本功能需要 `INTERNET` 权限，不需要存储权限（见 4.5.5）。

### 4.5.2 配置字段
| 字段 | 说明 |
| --- | --- |
| `schemaVersion` | 配置格式版本。App 只接受自己支持的版本，格式不兼容时整份丢弃。当前为 2（语言支持由 0–100 的 weight 改为 0–10 的 score）。 |
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
| `languages[]` | 支持的语言。`lang`：对应 `languages[].id`；`score`：识别质量打分（10 分制，0–10，越高越优先）；`decodeParam`：仅识别该语言时传给模型的语言参数，为空表示该模型不支持指定语言。 |
| `autoDecodeParam` | 勾选多种语言时传给模型的语言参数，如 SenseVoice 的 `auto`；为空表示不传参。 |

### 4.5.3 语言与模型的匹配规则
- **同一时间只加载一个识别模型**，以满足 5.1 的内存上限（450MB）。
- **选择模型**：在支持全部已勾选语言的模型中，选打分之和最高的；打分相同时选文件总大小更小的。
- **勾选冲突**：用户勾选语言 L 后，如果没有任何模型能同时支持全部已勾选语言，则以对 L 打分最高的模型为准：保留该模型支持的已勾选语言，自动取消其余语言，并 Toast 提示，例如“河南话需要切换到 TeleSpeech 模型，已取消：粤语、英语”。这样任何时候的勾选组合都能对应到唯一模型。
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
文件大小与 sha256 均为 2026-11-02 从 Hugging Face / GitHub 实际获取的真实值。模型文件 `urls[]` 顺序为海外默认（huggingface.co 优先），大陆环境下 App 在下载时自动将 hf-mirror.com 调整至首位，详见 4.5.6。VAD 文件目前只有 GitHub 一个下载地址，国内镜像待补充。
```json
{
  "schemaVersion": 2,
  "configVersion": 2,
  "remoteConfigUrl": "https://raw.githubusercontent.com/godvmxi/VisioIridisConfig/refs/heads/master/model_config.json",
  "languages": [
    { "id": "zh",    "name": "普通话", "defaultEnabled": true,  "order": 1 },
    { "id": "yue",   "name": "粤语",   "defaultEnabled": true,  "order": 2 },
    { "id": "en",    "name": "英语",   "defaultEnabled": true,  "order": 3 },
    { "id": "henan", "name": "河南话", "defaultEnabled": false, "order": 4 },
    { "id": "ja",    "name": "日语",   "defaultEnabled": false, "order": 5 },
    { "id": "ko",    "name": "韩语",   "defaultEnabled": false, "order": 6 }
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
        { "lang": "zh",  "score": 10, "decodeParam": "zh" },
        { "lang": "yue", "score": 10, "decodeParam": "yue" },
        { "lang": "en",  "score": 9,  "decodeParam": "en" },
        { "lang": "ja",  "score": 8,  "decodeParam": "ja" },
        { "lang": "ko",  "score": 8,  "decodeParam": "ko" }
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
        { "lang": "zh",    "score": 7, "decodeParam": "" },
        { "lang": "henan", "score": 9, "decodeParam": "" }
      ],
      "autoDecodeParam": ""
    }
  ]
}
```
> **示例数据说明**：
> - 打分为示例值，可按实际使用效果调整。
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


### 4.5.6 大陆地区网络适配
中国大陆对 Google、X（Twitter）、Hugging Face 等境外服务有网络访问限制。App 在启动后通过连通性探测判断用户所在网络环境，并自动选择最优的配置与模型下载地址，无需用户手动配置。

#### 探测机制
- **时机**：App 启动后立即在后台 Isolate 中并发执行，不阻塞界面；探测结果异步更新，期间保持使用上次缓存结果。
- **探测目标**（仅建立 TCP 连接，不发送 HTTP 请求，无隐私问题）：
  | 组别 | 探测目标 | 说明 |
  | --- | --- | --- |
  | 境外站点（大陆受限） | `google.com:443`、`x.com:443`、`huggingface.co:443` | 任一可通则判定为境外/VPN 环境 |
  | 大陆站点 | `baidu.com:443`、`taobao.com:443` | 至少一个可通则确认有网络但在大陆 |
- **超时**：每次 TCP 连接超时 5s；所有连接并发发出，总等待不超过 5s。
- **判断逻辑**：
  - 境外站点**任一可通** → `overseas`（境外/VPN）
  - 境外站点**全部不通** + 大陆站点**至少一个可通** → `mainland`（大陆）
  - 全部不通 → `unknown`（无网络），按上次缓存结果处理；若无缓存则按 `overseas` 处理
- **持久化**：探测结果保存到 `shared_preferences`（键 `region.result`），下次启动直接读取缓存结果；每次启动仍在后台重新探测并刷新缓存。

#### 对下载行为的影响
| 行为 | 大陆环境 | 境外/未知环境 |
| --- | --- | --- |
| 远程模型配置地址 | Gitee Raw URL | GitHub Raw URL |
| 模型文件 `urls[]` 下载顺序 | hf-mirror.com 优先（调至首位） | 按配置原顺序（huggingface.co 优先） |

URL 重排在模型下载时由 App 注入，不修改配置文件本身；配置 JSON 中的 `urls[]` 始终以 huggingface.co 为首（海外默认）。

## 4.6 设置页 (Settings)
- 入口：顶部控制栏清屏按钮右侧的齿轮图标，进入独立的设置页面。所有设置立即生效并持久保存（shared_preferences），重启后保留。
- **界面语言**：设置页最上方的下拉框，选项为“跟随系统”（默认）、“简体中文”、“繁體中文”、“English”；后三项始终用各自的文字显示，便于看不懂当前界面语言的用户找到。切换后立即生效：
  - 范围：App 内全部界面文字，包括顶部栏、按钮、设置页、对话框与提示、模型下载提示、语言与模型名称旁的说明、音频事件标签（如 😄 [笑声] / 😄 [laughter]）、浮动窗口按钮（麦克风/喇叭/返回/退出及退出确认）、前台服务通知文字（下次开始识别时更新），以及最近任务列表中的 App 名称。
  - 不在范围内：识别出的字幕文字本身；配置中的模型名称（如“SenseVoice Small”）；桌面启动器上的 App 名称（由系统语言决定）；下载、校验等底层错误的技术细节（附在已翻译的提示后原样显示）。
  - 跟随系统：系统语言为中文时，脚本为 Hant 或地区为港澳台用繁体，其余中文用简体；系统为其他语言时用英语。
  - 实现：Flutter gen-l10n（`lib/l10n/app_zh.arb` 为模板，另有 `app_zh_Hant.arb`、`app_en.arb`）。原生浮动窗口与系统声音录制通知的文字由 Dart 端随调用传入。
- **字体大小**：五档分段按钮。每档只有一个字号，最新卡片（含识别中的动画文字与占位提示）、历史记录、浮动字幕窗口统一使用；卡片高度随字号缩放（约容纳 3 行）。页面内提供按当前字号与配色渲染的预览。
  | 档位 | 字号 |
  | --- | --- |
  | 标准 | 24sp |
  | 大（默认） | 30sp |
  | 特大 | 36sp |
  | 超大 | 44sp |
  | 巨大 | 52sp |
- **粗体**：开关，默认关闭。开启后历史记录、时间戳、占位提示和浮动字幕的历史行都使用粗体；最新卡片的识别文字始终为粗体。
- **配色模式**：四选一，每项旁显示色块预览。同一模式下所有文字统一使用该模式的颜色（历史记录、最新卡片、语言胶囊、设置页、对话框、浮动字幕），时间戳用同色 60% 不透明度、占位提示用 50% 不透明度区分层级。开始/停止按键的绿色与红色不随配色变化。
  | 模式 | 背景 | 文字颜色 | 卡片底色 |
  | --- | --- | --- | --- |
  | 黄字黑底（默认） | #000000 | #FFE600 | #1E1E1E |
  | 白字黑底 | #000000 | #FFFFFF | #1E1E1E |
  | 黑字白底 | #FFFFFF | #000000 | #F2F2F2 |
  | 自定义 | 用户选择 | 用户选择 | 背景色向文字色混合 8% |
  - **自定义**：选中后展开“背景色”“文字颜色”两组色块（各 12 种，深浅色均有），点选即生效并持久保存；默认深蓝底 #0D1B2A、青色字 #00E5FF。卡片边框为背景色向文字色混合 22%，界面明暗按背景亮度自动判断。两色对比度低于 4.5:1（WCAG AA）时显示提示“对比度较低（x:1），字幕可能不易看清”，但不阻止选择。
  - 说明：此处取代 4.2 中历史区浅灰 #B0B0B0、时间戳 #666666 的规定。
- **识别模型（按语言）**：顶部为“语言”下拉框（顶部栏可选的每种主语言，默认选中第一个），选中某种语言后，下方直接列出“为‘普通话’选择模型”的候选列表（单选）：
  - 第一项为“自动”，副标题显示当前会选中的模型及打分（如“选打分最高的模型：SenseVoice Small  10 分”）；
  - 其后按该语言打分从高到低列出所有支持该语言的模型，标题为“模型名  语言名 X 分”，副标题列出该模型支持的全部语言及打分（如“支持：普通话 7 · 河南话 9”）；
  - 点击模型即选中并保存。
  - 选择模型时（4.5.3 的扩展）：在支持全部已勾选语言的模型中，被越多已勾选语言指定的模型越优先；指定次数相同时按打分之和、再按文件总大小选择。被指定的模型若不支持全部已勾选语言，则不会被选中。
  - 配置更新后，已不存在或不再支持该语言的指定视为“自动”。
  - 修改在下次点击“开始识别”时生效；识别进行中不切换模型。
  - **启动前检查模型变化**：App 记录上次成功启动识别时使用的模型。点击“开始识别”时按当前语言与偏好选出模型，与上次比较：
    - 模型未变且已就绪：直接开始；
    - 模型已变且已就绪：直接开始，并提示“识别模型已切换为「X」”；
    - 需要下载：弹窗说明（模型变化时标题为“识别模型已变更”，内容为“识别模型由「A」变更为「B」”及下载大小），按钮为“取消”“下载”；若上次的模型支持当前勾选的语言且仍在 cache 中，另提供“先用「A」”，本次继续用旧模型启动，下次开始时再次询问。

## 4.7 后台浮动字幕 (Floating Caption)
- **开关**：设置页“浮动窗”中的“显示浮动窗”，默认关闭。开启时若没有“显示在其他应用上层”权限，弹窗说明并跳转系统设置页，返回后再次检查，仍未授权则提示“未获得悬浮窗权限，浮动窗未开启”，开关保持关闭。不再提供电池优化 / 后台运行设置引导。
- **显示时机**：开关开启、识别进行中、且 App 切到后台时显示；回到 App 时隐藏；后台识别停止（如出错）时也隐藏。
- **窗口样式**：
  - 宽度为屏幕宽度减去两侧 12dp，高度为屏幕高度的 1/3，默认位于屏幕下方（留出导航栏位置），圆角 16dp。
  - 背景为当前配色的背景色、75% 不透明度；文字颜色与字号跟随设置页（当前识别与历史使用同一字号）。
  - 顶部为拖动条（≡）、“麦克风 | 喇叭”声音来源选择（见 4.8）、“返回”与“退出”按钮；下方为字幕区：历史记录在上、当前识别在最底部（临时结果 70% 不透明度），内容贴底排列。窗口能容纳几条历史就显示几条（随窗口高度与字号自适应），每条历史可换行完整显示。
- **交互**：
  - 拖动顶部拖动条上下移动窗口；点“返回”回到 App；点“退出”后顶部改为确认栏“确定退出？ [退出] [取消 (5)]”，避免误触：点“退出”才停止识别、关闭浮动窗口并关闭 App（从最近任务中移除）；点“取消”或 5 秒内无操作（倒计时显示在“取消”上）则恢复原来的顶部按钮，确认期间识别和字幕不中断。窗口不获取焦点，不影响其他应用的输入。
  - 在字幕区上下滑动查看更早的历史（最多保留最近 100 条）。停在底部时新内容自动滚动到底；向上滑动查看时暂停自动跟随，滑回底部后恢复。
- **后台录音**：开始识别时启动麦克风类型的前台服务（常驻通知“实时字幕识别中”），停止识别或 App 被关闭时结束，见 5.4。Android 只允许持有麦克风前台服务的应用在后台录音，否则系统会把录音静音；因此前台服务在 App 切到后台时必须继续运行，不能随界面一起停止。

## 4.8 声音来源：麦克风 / 喇叭 (Sound Source)
- **入口**：主界面顶部栏与浮动窗口顶部各有一个“声音来源”二选一按钮，分别显示“麦克风”和“喇叭”，两处状态同步。“喇叭”表示识别手机正在播放的声音（视频、直播、音乐、网页、游戏等）。
  - 未在识别时选择：只记录选择，点击“开始识别”后立即生效。
  - 识别中切换：立即切换。
  - 停止识别后保留选择；授权被拒绝或录制被结束时自动回到“麦克风”。
- **切换到喇叭时的提示**：每次切换到“喇叭”都提示“因系统限制，喇叭模式只能识别播放器等应用播放的声音，无法识别电话和语音/视频通话的声音”。App 在前台时以 SnackBar 显示；在后台（浮动窗口操作）时以系统 Toast 显示。浮动窗口显示期间的其他提示同样改用 Toast。
- **授权**：每次开启时系统弹出“开始录制/投屏”确认框（MediaProjection，Android 10+ 才支持）。确认框由一个透明页面弹出，不会把主界面拉到前台。用户拒绝时保持麦克风识别并提示“未获得录制喇叭声音的授权，已切回麦克风”。
- **实现**：授权后立即启动 mediaProjection 类型的前台服务（常驻通知“正在识别系统播放的声音”），通过 AudioPlaybackCapture 以 16kHz / 16bit / 单声道录制，与麦克风数据走同一条识别流水线。切换来源时，正在说的句子按句尾定稿。
- **结束**：切回麦克风、停止识别或 App 被关闭时停止捕获。用户在通知栏或系统界面结束投屏时，自动切回麦克风并提示。
- **系统限制**（Android 平台规定，无法绕过）：
  - 只能捕获用途为媒体、游戏或未知的声音；对方 App 可以声明禁止被捕获（部分视频、音乐 App 会这样做），此时录到的是静音。
  - **电话和网络通话（微信语音/视频、会议软件等，用途为 VOICE_COMMUNICATION）的声音无法捕获**；通话期间系统通常也会静音非通话 App 的麦克风。

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
| flutter_localizations / intl | Flutter SDK / pub.dev | 界面多语言：简体中文、繁體中文、English（4.6） |
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
  final int score;          // 0–10 分，越高越优先
  final String decodeParam; // 空串表示不支持指定语言
}
```

# 7. 版本迭代规划
## Phase 1: MVP 基础验证版 (当前阶段)
- [ ] 搭建 Flutter 主页面骨架与三段式 UI。
- [ ] 集成 sherpa-onnx 与 SenseVoice-Small INT8 + Silero-VAD。
- [ ] 实现普/粤/英自动切换与本地离线推理。
- [ ] 实现地区检测（4.5.6）：App 启动后后台连通性探测，根据结果自动选择远程配置 URL 与模型下载 URL 顺序。
- [ ] 实现模型配置（内置默认 + 远程更新）与模型下载、校验、外置存储到 cache 的缓存流程（4.5）。
- [ ] 按配置生成语言胶囊，实现语言与模型的匹配和模型切换（4.5.3）。
- [ ] 设置页：字体大小、配色模式、按语言选择识别模型（4.6）。
- [ ] 后台浮动字幕与后台运行设置引导（4.7）。
- [ ] 声音来源切换：麦克风 / 喇叭（4.8）。
- [ ] 实现屏幕常亮与触觉反馈。


## Phase 2: 无障碍体验深化版
- [ ] 情绪标签（SenseVoice 自带的喜怒哀乐、掌声、笑声）全量图形化渲染。
- [ ] 支持外部 Type-C / 蓝牙麦克风电量与连接状态实时监控指示。
- [ ] 历史记录导出（支持一键导出为 TXT 文件分享至系统其他 App）。
- [ ] 模型配置签名校验（如 Ed25519），防止配置被篡改。

## Phase 3: 硬件与定制版 (盒子方案)
- [ ] 适配 Android Kiosk 模式（开机自启动、屏蔽系统导航条、禁止用户退出）。
- [ ] 增加双向分屏模式（屏幕上半部分反转 180 度面向对方，屏幕下半部分正向面向听障者）。
