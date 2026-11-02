听障离线实时字幕助手 (HearClear / 听见盒子)

# 1. 文档概述
## 1.1 背景与痛点
现有移动端语音转文字（ASR）工具多面向会议纪要或通用听写，在听障人士面对面交流场景中存在核心痛点：
- 网络强依赖与高延迟：无网、弱网（如电梯、地下室、商场角落）直接瘫痪；云端往返延迟常超过 1 秒，破坏即时对话流。
- 多语言/方言识别割裂：日常交流中普通话、粤语、英语高频混讲，市面多数软件需手动进设置切换语言包，无法自适应。
- 视觉设计不符合无障碍需求：文字字号偏小、对比度不足、缺乏视觉锚点；流式输出时整屏文字疯狂跳动，造成强烈的视觉眩晕。


## 1.2 产品定位
一款基于 Android (Flutter 跨平台技术栈) 开发的纯离线、低延迟、高对比度无障碍实时字幕工具。既可作为独立 App 安装在个人手机上，也可通过单任务展厅模式（Kiosk Mode）部署在专用的便携式硬件盒子上。


## 1.3 核心目标
- 离线可用：核心识别链路 0 外部网络依赖，模型与推理库完全内嵌；唯一联网功能“在线 AI 纠错”默认关闭、需用户主动开启。
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
  - 3 个带状态勾选框的胶囊按钮：普通话、粤语、英语。
  - 1 个清屏动作图标按钮（垃圾桶图标）。
- 交互规则：
  - 默认状态：全选（普通话、粤语、英语均激活）。
  - 联动逻辑：
    - 三者均勾选时：传参 language="auto"，启用全自动混识。
    - 单独勾选某一项（如仅勾选“英语”）：传参 language="en"，避免外部白噪音被误解码为汉字。
    - 仅勾选两项（如普通话 + 英语）：先以 language="auto" 解码，读取 SenseVoice 输出的语种标签（zh / yue / en，sherpa-onnx 结果中的 lang 字段）。若检测到的语种已勾选，直接采用；若检测到的是未勾选语种（如粤语），则用已勾选的主语种（按 普通话 > 粤语 > 英语 的优先级选取）强制重解码一次。重解码只在定稿时执行，临时结果不做此校验。
      - 说明：sherpa-onnx 不提供逐字置信度，无法实现“对粤语虚词做置信度惩罚”，故改为语种标签校验方案。
    - **防空保护**：禁止三者同时取消勾选；若用户试图取消最后一个激活项，界面抖动并 Toast 提示“至少保留一种识别语言”。
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


# 5. 非功能性需求 (NFR)
## 5.1 性能指标
- 推理延迟 (Latency)：在搭载骁龙 680 / 联发科 G99 及以上级别硬件上，SenseVoice-Small INT8 单句推理耗时需 $\le 120\text{ ms}$。
- 整句上屏时延：从 VAD 判定句尾（静音满 400ms）到最新卡片渲染定稿结果，延迟 $\le 300\text{ ms}$。说话人闭口到上屏的总时延 = 400ms 静音判定 + 本项，约 $\le 700\text{ ms}$。
- 临时结果刷新：说话期间临时结果刷新间隔约 300ms。
- 内存占用：App 完整加载模型并启动拾音流水线后，整体 PSS 运行内存 $\le 450\text{ MB}$。
- CPU 占用：双线程推理模式下，非工作静音态 CPU 占用 $\le 3\%$；持续说话（含临时结果重解码）时综合 CPU 占用 $\le 35\%$。超标时按第 3 章说明降级。
- UI 流畅度：字幕滚屏与状态动画必须稳定在 60 FPS。VAD 与 SenseVoice 推理必须在常驻的后台 Isolate 中执行；模型在该 Isolate 启动时加载一次，之后常驻，禁止每句重新加载。

## 5.2 模型分发
- SenseVoice-Small INT8 约 230MB，加上 Silero-VAD 后安装包将超过 Google Play 基础 APK 的 200MB 上限。
  - 硬件盒子 / 侧载版本：模型直接打包进 assets，首次启动时解压到应用私有目录（sherpa-onnx 需要文件路径）。
  - Google Play 版本：通过 Play Asset Delivery（install-time 资源包）分发模型，保证安装后即可离线使用。

## 5.3 功耗与续航
- 常亮管理：开启识别时调用 WakelockPlus.enable() 保持屏幕长亮；停止识别后 3 分钟无操作，恢复系统级自动休眠。 
- 连续工作发热：室温（25℃）下连续工作 2 小时，设备表面温度上升不得超过 10℃，不得因过热引发降频卡顿。

## 5.4 稳定性与容错
- 无网络环境：完全断开 Wi-Fi 和蜂窝移动网络下，除“在线 AI 纠错”外功能 100% 完整，无任何网络报错弹窗；在线 AI 请求失败时静默回退到离线结果。
- 麦克风占用/热插拔：当插入或拔出 Type-C 领夹无线麦时，音频引擎需在 500ms 内自动停止并重建录音流，不得闪退。实现上由 Android 原生层的 AudioDeviceCallback 通知 Dart 层重启 record 流。
- 前台服务保活：声明 FOREGROUND_SERVICE 与 FOREGROUND_SERVICE_MICROPHONE 权限，Service 设置 foregroundServiceType="microphone"，附带常驻通知栏提示，防止被系统低内存策略意外杀死。注意 Android 14+ 要求该前台服务必须在 App 处于前台时启动（即用户点击“开始识别”时）。


# 6. 技术实现路径与工程架构 (Flutter)
## 6.1 核心依赖库清单
| 依赖项 | 版本/来源 | 用途说明 |
| ---   | ---  | --- |
| sherpa_onnx | 官方 flutter package | 通过 Dart FFI 调用 C++ 动态库，运行 SenseVoice 及 Silero-VAD | 
| record | pub.dev 最新稳定版 | 16kHz, 16bit 单声道 Raw PCM 流式采集（`startStream`） |
| permission_handler | pub.dev 最新稳定版 | 麦克风、通知权限申请 |
| flutter_foreground_task | pub.dev 最新稳定版 | 麦克风类型前台服务与常驻通知 |
| wakelock_plus | pub.dev 最新稳定版 | 保持屏幕常亮 | 
| flutter_riverpod | pub.dev 最新稳定版 | 状态管理 |
| path_provider | pub.dev 最新稳定版 | 模型解压目标目录 |
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

# 7. 版本迭代规划
## Phase 1: MVP 基础验证版 (当前阶段)
- [ ] 搭建 Flutter 主页面骨架与三段式 UI。
- [ ] 集成 sherpa-onnx 与 SenseVoice-Small INT8 + Silero-VAD。
- [ ] 实现普/粤/英自动切换与本地离线推理。
- [ ] 实现屏幕常亮与触觉反馈。


## Phase 2: 无障碍体验深化版
- [ ] 增加字号自由调节滑块（提供 Standard 24sp、Large 32sp、Huge 40sp 三档）。
- [ ] 情绪标签（SenseVoice 自带的喜怒哀乐、掌声、笑声）全量图形化渲染。
- [ ] 支持外部 Type-C / 蓝牙麦克风电量与连接状态实时监控指示。
- [ ] 历史记录导出（支持一键导出为 TXT 文件分享至系统其他 App）。


## Phase 3: 硬件与定制版 (盒子方案)
- [ ] 适配 Android Kiosk 模式（开机自启动、屏蔽系统导航条、禁止用户退出）。
- [ ] 增加双向分屏模式（屏幕上半部分反转 180 度面向对方，屏幕下半部分正向面向听障者）。
