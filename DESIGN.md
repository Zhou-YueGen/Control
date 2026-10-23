# Control — DESIGN.md

> **Design System & Screen Specification / SwiftUI 视觉与交互规范**  
> **版本：** 0.2.0 · Gradient UI (12 Screens)  
> **日期：** 2026-10-23  
> **目标平台：** iPhone · iOS 17+ · SwiftUI  
> **UI 语言：** English；规范说明：中文  
> **关联：** `PRD.md` / `USER_FLOW.md` / `References/control-ui-12screens.png`

---

## 0. 设计总则

**设计方向：** `Calm Premium Wellness × Layered Gradients × Soft Glass`。

本版相较旧版白底青绿 Control，重点升级：

1. **按使用场景安排渐变情绪**：引导页深海蓝/紫、首页蓝天薄荷、训练页清透青绿、完成页暖光、Progress 深海蓝、设置页紫蓝。
2. **渐变是背景，不是可读性负担**：正文要落在足够不透明的卡片上，颜色遵循对比度要求。
3. **克制的玻璃质感**：使用系统 `Material`、少量半透明层和柔和阴影，避免高饱和霓虹和过度模糊。
4. **品牌统一**：圆角、间距、字重、强调色、导航风格跨 12 屏一致，不让每个页面成为互不相关的海报。
5. **真实交互优先**：代码组件是真正的 SwiftUI 控件；**不可将整张设计参考图裁剪当 UI 背景**。
6. **健康类内容审慎**：圆环和波纹是时间/指导动画，不伪装生理传感器；解剖图需审核；文案不夸大效果。

**规范冲突优先级：** 临床/隐私审核 > `PRD.md` 功能 > `USER_FLOW.md` 交互 > 本文档视觉 > 图片参考。

---

## 1. UI 风格关键词

- Brand: **Control**；Tagline：`Train Control. Learn to Relax.`
- Tone: Calm / Confident / Private / Scientific / Premium / Encouraging。
- 视觉元素：流动渐变背景、圆形训练计时器、柔和磨砂卡片、薄荷绿 CTA、轻玻璃 Tab Bar、清晰的数据可视化。
- 避免：硬阴影、厚重的黑描边、发光文字、花哨动效、过量 emoji、低对比的小字、把训练表现渲染成医学测量。
- 字体：Apple SF 系统字体，不依赖第三方商业字体。

---

## 2. Design Tokens

### 2.1 语义色板（基础原色）

| Token | HEX | 用途 |
|---|---|---|
| `inkPrimary` | `#0C1F35` | 浅背景上的标题/正文 |
| `inkSecondary` | `#40556B` | 浅背景上的次要说明 |
| `inkOnDark` | `#FFFFFF` | 深色背景标题/正文 |
| `inkOnDarkMuted` | `#DCEAF3` | 深色背景次要说明 |
| `brandDeep` | `#006D67` | 主按钮、浅色背景强调元素 |
| `brandMid` | `#0D9182` | 品牌图标、图形与进度 |
| `brandMint` | `#5BE0BF` | 深色背景高亮、选中标签 |
| `tealTint` | `#D8F6EF` | 选中卡片浅青绿底 |
| `ocean` | `#153E76` | 深蓝主题基础 |
| `sky` | `#69ADD0` | 首页/教学背景过渡 |
| `lavender` | `#9C8DD8` | 设置/完成背景过渡 |
| `peach` | `#F9E4D4` | 温暖结束页/训练下半背景 |
| `surfaceLight` | `#FFFFFF` | 浅主题卡片基底 |
| `surfaceDark` | `#122C4C` | 深主题非透明备用卡片 |
| `separatorLight` | `#D8E5EB` | 浅背景分隔线 |
| `danger` | `#A52848` | 错误、风险与停止提示（附文字） |
| `warningSurface` | `#FFF2E9` | 风险通知信息承载底 |
| `success` | `#087A6B` | 已完成状态（配符号/文字） |
| `disabled` | `#A5B8C1` | 禁用且附原因说明 |

**可读性：** 普通正文/按钮文本对比度目标 ≥4.5:1，大号字 ≥3:1；渐变底上的细字必须测量最差色停位置。`brandMid` 不一定适合所有白底小字，关键文字优先使用更深的 `brandDeep`。

### 2.2 12 屏专用渐变主题

每个主题由 `top → middle → bottom` 表示，方向默认 `topLeading → bottomTrailing`；须根据真实内容和按钮位置微调。

| Screen | Theme ID | 色停建议 | 文字/卡片策略 |
|---|---|---|---|
| 01 Welcome | `welcomeMist` | `#A9CFE4 → #E7ECE8 → #FCE6D2` | 深色文字；自然摄影背景要有对比遮罩 |
| 02 Goal | `goalOcean` | `#045D68 → #153C70 → #42345D` | 白字；半透深蓝卡片，选中项青绿 |
| 03 Safety | `safetyOcean` | `#047F77 → #20538A → #615AA0` | 标题白字，问卷放在浅色实底卡片 |
| 04 Home | `homeSky` | `#5E8BC5 → #96D4D9 → #FAE8D5` | 顶部白字；中下部深色文字与白卡 |
| 05 Training | `trainingFlow` | `#165F7F → #9EDBD9 → #F9E9D7` | 主计时器白底、深色字，视觉聚焦 |
| 06 Complete | `completeGlow` | `#7A8DCB → #F4D4CB → #FAF0E4` | 深色文字、暖白卡、完成绿色图标 |
| 07 Progress | `progressNight` | `#102950 → #18446D → #6E627F` | 顶部白字，深玻璃卡 + 明亮图表 |
| 08 Learn | `learnAir` | `#2B8CAD → #B4DED3 → #EDE9E5` | 白/深文字分区，知识卡必须清晰 |
| 09 My Routine | `routineBlue` | `#3153AA → #B9D8E2 → #FBEDDF` | 蓝白层级，当前训练绿色强调 |
| 10 Choose Session | `sessionChoice` | `#80B4CF → #E0E7D9 → #F8E0C6` | 深标题，白色 Session 卡 |
| 11 Settings | `settingsLilac` | `#326DAA → #9589CA → #E9E3F0` | 标题白字，功能分组浅色实底 |
| 12 Journey | `journeyLandscape` | 山景资源 + 深蓝半透遮罩 → 柔和浅青绿页脚 | 白色覆盖标题；数据区浅色卡 |

**渐变实施准则：**
- 渐变以统一容器覆盖安全区域，不随卡片高度重复铺贴。
- 一屏通常 2–3 个主色停；品牌薄荷绿 CTA 保持一致，不因背景变化随机换色。
- 深色页中，浅玻璃面板可用近乎不透明的蓝白色；长文本和医学提示优先不透明白卡。
- 极端屏宽或大字模式下颜色分区不能影响对比度；有必要时添加深/浅局部蒙层。
- 原型展示的多彩渐变不是系统 Dark Mode 自动适配的替代。V0.2 可先固定经测试的外观，完整 Dark Mode 另行设计测试。

### 2.3 字体层级

使用 `.system(...)` 或 SwiftUI Dynamic Type Text Styles；语义优先于固定绝对字号。

| Typography | 建议字号 | Weight | 使用场景 |
|---|---:|---|---|
| `brandTitle` | 34–38 pt | bold/semibold | Welcome 品牌名称 |
| `screenTitle` | 28–32 pt | bold | 一级标题 |
| `sectionTitle` | 20–22 pt | semibold | 页面分区标题 |
| `cardTitle` | 16–18 pt | semibold | 训练卡/课程名 |
| `body` | 15–17 pt | regular | 正文、操作解释 |
| `secondary` | 13–14 pt | regular | 次要文字 |
| `caption` | 11–12 pt | medium | 图表辅助标注，不放关键医疗提示 |
| `timerNumber` | 56–72 pt | bold, rounded | 训练秒数；使用 `.monospacedDigit()` |
| `metricNumber` | 24–30 pt | bold/semibold | 训练累计与指标 |

规则：
- 英文标题使用 Sentence case，避免混乱的 Title Case / 全大写。
- 数字与单位分层，但完整含义能被 VoiceOver 读出（例如 `4 seconds remaining`）。
- Dynamic Type 下布局自动纵向延展，关键内容不被固定高度卡片裁切。
- 图文多的 Learn 内容优先采用系统动态字体，减少依赖固定行数。

### 2.4 间距、圆角、尺寸

| Token | 值 | 场景 |
|---|---:|---|
| `space2` | 8 pt | 图标和文字、密集元素 |
| `space3` | 12 pt | 小卡内容与行间距 |
| `space4` | 16 pt | 常规组件内边距 |
| `space5` | 20 pt | 屏幕左右 padding |
| `space6` | 24 pt | 页面模块间距 |
| `space8` | 32 pt | 关键区域分隔 |
| `radiusSmall` | 12 pt | 单行设置项/标签 |
| `radiusCard` | 18–22 pt | 大多数内容卡 |
| `radiusHero` | 28 pt | 主要训练/欢迎组件 |
| `radiusPill` | 999 pt | 主 CTA、日期胶囊、Segment |
| `buttonMinHeight` | 52–56 pt | 底部主按钮 |
| `hitTargetMin` | 44×44 pt | 所有交互元素 |
| `tabBarHeight` | 系统自适应 | `TabView` 主导航 |

**不建议**将完整屏幕做成固定 390×844 的绝对坐标布局；用 `GeometryReader` 只处理确需比例适配的图形，内容使用 `ScrollView`、`VStack`、安全区边距。

### 2.5 Shadow / Stroke / Material

- Light card：白色 `0.90–0.96` 不透明度；阴影 `black 0.06`，半径 16，Y=6；边框白色/蓝灰低对比。
- Dark glass：深蓝底 `0.55–0.8` 不透明度（视文字对比决定），或系统 `thinMaterial` + 独立深蒙层；白色描边 ≤0.14。
- 不让 Material 背景直接承载必须阅读的 Safety 细字；此类内容采用白色高不透明卡。
- 使用 `clipShape(RoundedRectangle(...))`，避免阴影被外层裁切。

---

## 3. 通用组件库（SwiftUI 建议命名）

| 组件 | SwiftUI 命名 | 规格 / 行为 |
|---|---|---|
| 渐变页面容器 | `ControlGradientBackground` | 根据 `GradientTheme` 生成统一背景；覆盖安全区域 |
| 页面基础布局 | `ControlScreen` | SafeArea / ScrollView / 左右边距 / 渐变切换 |
| 白/暗玻璃卡 | `GlassCard` | 统一 corner、material、stroke、shadow |
| 主按钮 | `PrimaryPillButton` | 绿色深浅渐变、完整 pressed/disabled/loading |
| 次按钮 | `SecondaryButton` | 低强调，保持 44pt 点击区 |
| 目标选择卡 | `GoalOptionCard` | Icon/Title/Subtext/Check；完整单选行为 |
| 风险问答卡 | `SafetyQuestionRow` | 题目与 No/Yes/Prefer not to say 按钮，不暗示默认答案 |
| 周日历 | `WeeklyCalendarStrip` | 当地日期、今日、实际完成状态、可访问标签 |
| 今日训练卡 | `TodaySessionCard` | 标题、可用状态、时长、开始按钮 |
| 进度圈 | `TrainingCountdownRing` | 仅显示倒计时进度，状态有辅助文字 |
| 呼吸/放松引导 | `GuidanceWaveView` | 轻微波纹/呼吸视觉；非生物反馈 |
| 训练底栏 | `SessionControlBar` | 已完成次数、Pause/Resume、剩余时间 |
| 完成指标 | `MetricCard` | 动态数字、单位、真实记录 |
| 难度选择 | `DifficultySelector` | 4 选 1，可不选；VoiceOver 清楚 |
| 风险提示 | `SafetyNoticeCard` | 清晰正文与建议，不能只靠颜色 |
| 训练趋势图 | `TrainingBarChart` | Swift Charts，空数据不造图 |
| 导航标题 | `ControlNavigationHeader` | 返回按钮、标题、可选帮助，不遮挡状态栏 |
| 空状态 | `EmptyStateView` | 无历史/无计划/受限信息，附真实 CTA |
| 底部导航 | `ControlTabBar` | 首选原生 `TabView`，如要自定义须保留系统可访问性 |

**所有状态组件**至少考虑：`normal / selected / pressed / disabled / loading / error`；常规展示页考虑 `empty / content / loading / unavailable`。

---

## 4. 页面设计规格（严格对应参考图 1–12）

### S01 · Welcome — `WelcomeView`（P0）

- **主题：** `welcomeMist`，蓝灰晨雾到米色夕阳；下半部可使用经授权的男性户外场景照。
- **层级：** 品牌 Logo → `Control` → 两行 tagline → 三条简短价值点 → 底部 `Get Started`。
- **CTA：** 绿色玻璃感圆角按钮，保持对比度；安全区以上 16–24pt。
- **真实行为：** Get Started 进入成年确认；`I already have an account` 因 V0.1 不做账号**应隐藏或改为 `Continue`（仅有本地未完成流程时）**。
- **注意：** 摄影素材不允许遮挡导航、正文或品牌文字。

### S02 · Goal Selection — `GoalSelectionView`（P0）

- **主题：** `goalOcean`，深蓝/孔雀绿/紫渐变，白字。
- **模块：** 顶部步骤 `2/4`（最终步骤数由流程配置驱动）、标题 `What's your main goal?`、选项卡、底部 Continue。
- **选择态：** 青绿高亮 + 确认标识；未选项暗玻璃。
- **业务：** 原型的 Post-surgery support 仅作为 `Recovery information (education only)`，选择后明确教育/专业建议分支。
- **禁用：** 没有选中任何目标，Continue 不可点。

### S03 · Health & Safety Check — `SafetyCheckView`（P0）

- **主题：** `safetyOcean`；深色页眉 + 不透明浅色题目卡。
- **布局：** 步骤进度、标题、安全说明、每行 `No / Yes / Prefer not to say`、底部信息说明与 Continue。
- **可读性：** 长题目必须换行；按钮可随动态字体换到下一行。
- **状态：** 任一回答未知/风险触发安全分支；没有任何默认选中的“健康”答案。
- **限制：** App 不凭问卷给出诊断或术后训练许可。

### S04 · Home — `HomeView`（P0）

- **主题：** `homeSky`；上方天空蓝/薰衣草光感，下方薄荷/杏色。
- **顺序：** Header（今日日期+问候）→ WeeklyCalendarStrip → TodaySessionCard → Weekly Progress → 真实数据卡 → 简短鼓励文案。
- **卡片：** 主要内容白卡；顶区文字颜色根据梯度深浅调节。当前日期用绿色胶囊。
- **CTA：** Today's Training 一键开始**已审核且可用**的模板；受限时显示查看安全信息。
- **底栏：** Home / Learn / Train / Progress / Settings，当前 Home 高亮。
- **空状态：** 新安装用户展示 0 Sessions 与鼓励开始，绝不套用参考图 `12 Sessions`。

### S05 · Training — `TrainingView`（P0）

- **主题：** `trainingFlow`，中心为清爽白底大圆；其余视觉降噪。
- **上区：** 返回、训练名称、当前阶段 `1/3`（如存在分段）、可选声音按钮。
- **中心：** `TrainingCountdownRing` 直径适配屏宽约 70–78%，不能压住两侧安全边距；`Contract / Relax` 与巨大秒数。
- **环形进度：** 底环薄荷色、前景从 teal 到 sea green；通过动画反映**时间流逝**。
- **下区：** `GuidanceWaveView` 引导视觉、每阶段一句指导、重复数/暂停按钮/剩余时间。
- **状态：** Paused 时圆环静止且明确显示 `Paused`；退出需确认；后台回来不自动 Resume。
- **指导文案：** Contract/Relax 内容由审核过的模板配置，避免误导或不安全命令。

### S06 · Session Complete — `SessionCompleteView`（P0）

- **主题：** `completeGlow`；柔紫、珊瑚杏与暖白。
- **主视觉：** 青绿完成标识、少量庆祝粒子（Reduce Motion 下静态）。
- **层级：** Great job → 真实数据（Reps/Minutes）→ DifficultySelector → **独立 discomfort 问题** → Save & Continue。
- **不要：** 固定显示 `8 reps/8 minutes` 或把 `Moderate` 当成自动识别的训练表现。
- **数据保证：** 保存完成训练不能依赖是否填写难度；重复保存不重复计算。

### S07 · Your Progress — `ProgressView`（P0）

- **主题：** `progressNight`；深蓝/海绿图表。
- **布局：** 时间筛选 → 三张真实指标 → 7 日柱图 → 训练日历 → 可选长线趋势。
- **指标：** Total Sessions / Minutes / Day Streak；同 PRD 数据规则。
- **图表：** 柱颜色是实际活动强度/训练完成程度的视觉表征，轴标签清晰；VoiceOver 有数据摘要。
- **范围：** P0 可只显示 7D / 30D，隐藏无逻辑支持的 3M / 1Y。
- **空态：** `No sessions yet` + `Start a session`（只有 gate 允许时）。

### S08 · Learn — `LearnView`（P0）

- **主题：** `learnAir`；蓝绿柔和渐变，教学内容以白卡承载。
- **顶部 Tab：** Basics / How to / Common Mistakes（实际是 Learn 内部 Segmented Control）。
- **内容：** 教学插画/动画卡 + 问题说明 + 可进入的课程单元。
- **审核：** 生理解剖示意需专业核对和使用权审查；“盆底肌在哪里”等内容通俗准确。
- **入门守卫：** 首次训练前需确认 `Learn Basics` 内容已阅读；完成状态必须持久化。

### S09 · Your Plan / My Routine — `MyRoutineView`（P1）

- **主题：** `routineBlue`，白色清爽课程表。
- **模块：** 标题 + 训练启用开关 → 周目标进度 → 每日计划卡 → 自定义计划入口。
- **规则：** 计划相关总量、完成比例必须由真实安排和训练记录计算；没有课程不渲染假计划。
- **发布：** P0 不在 Home 放置未实现的可点击 Routine，也不添加空壳 Tab。

### S10 · Choose a Session — `ChooseSessionView`（P1）

- **主题：** `sessionChoice`，柔和晨曦蓝到杏色。
- **模块：** 简短说明 → Quick / Standard / Extended 三张卡（时长、内容、难度标签和可用条件）。
- **选中：** 青绿色描边和浅色玻璃背景；不可用课程显示明确状态，不伪装成可启动。
- **规则：** 首发若只有一种已审核模板，则展示单卡或直接进入该模板；不要强行凑三个不可用 Session。

### S11 · Settings — `SettingsView`（P0/P1）

- **主题：** `settingsLilac`；紫蓝顶部，内容在分组浅色卡片中。
- **P0：** Sound Guidance、Haptic Feedback、Safety Information、Privacy Policy、Delete All Data。
- **P1：** Voice、Training Reminders、Reminder Times、Motivational Messages、Export Data。
- **控件：** 首选原生 Toggle；危险性删除显示清晰二次确认。
- **注意：** 未获得通知权限不预先显示“已启用”；不能制作无效的开关。

### S12 · Your Journey — `JourneyView`（P2）

- **主题：** 有授权的群山小径图片 + 顶部深色文字遮罩 + 底部薄荷白卡。
- **内容：** `Consistency builds a stronger you` 等非疗效性鼓励文案、进度节点、真实累计 Sessions/Weeks/Time。
- **路径规则：** 所有节点只对应练习习惯里程碑，不得解释为身体结构改善或医疗恢复阶段。
- **空态：** 初次使用为第 0 节点；无图则用渐变和路径矢量实现。

---

## 5. 底部 Tab Bar 和导航规范

### 5.1 唯一的五个 Tab

顺序固定：`Home` / `Learn` / `Train` / `Progress` / `Settings`。

建议 SF Symbols：`house.fill`、`book.closed`、`play.circle`、`chart.bar`、`gearshape`（可依据清晰度微调）。

- 选中：深青绿图标 + 文字；非选中：灰蓝色；当前状态不能只靠颜色。
- 原生 `TabView` 优先，保持 iOS 系统触摸/VoiceOver/安全区行为。
- `TrainingView`（全屏沉浸式）和 `SessionCompleteView` 不显示 Tab。
- 在 Train 的二级页点击系统 Back 返回 Train；不必用自定义返回按钮模拟所有导航。
- 深页底部栏使用较高不透明度的磨砂浅色底，绝不让渐变导致标签不可读。

### 5.2 页面滚动原则

- 首页和 Learn / Progress / Settings 必须允许垂直滚动。
- 底部大 CTA 可使用 `.safeAreaInset(edge: .bottom)` 固定，但不能覆盖最后一个输入或表单行。
- 小屏手机或 Dynamic Type 模式下 CTA 不应被 Home Indicator 遮挡。
- 键盘弹出时备注/输入区域可进入视野；若 Notes 未开发则不显示输入框。

---

## 6. 动效与反馈

| 交互 | 默认动效 | 替代/约束 |
|---|---|---|
| 页面进场 | 淡入 + 轻微上移，0.2–0.3s | Reduce Motion 时直接切换 |
| 卡片选中 | 边框/背景平滑切换 0.15–0.25s | 同步显示勾选标记 |
| 主 CTA | pressed scale 0.98 | 保持触摸响应，禁用/加载态清楚 |
| Timer ring | 时间驱动平滑进度 | 不在暂停时继续动画，不代表肌肉收缩质量 |
| Guidance wave | 微弱、缓慢起伏 | Reduce Motion 改为静态渐变图 |
| Complete | 轻微弹性完成图标，少量粒子 | Reduce Motion 时纯静态确认 |
| 图表 | 可选入场过渡 | 初版可以静态，优先读数准确 |

语音和振动由设置控制；任何引导都必须可以在没有声音或振动的环境下理解。发生收缩/放松阶段切换时，应同时有可见文字变化和合适的辅助技术提示。

---

## 7. SwiftUI 实现建议（设计示例）

### 7.1 主题枚举 + 背景示意

```swift
import SwiftUI

enum ControlTheme {
    case home, goal, safety, training, complete, progress, learn, routine, sessionChoice, settings

    var colors: [Color] {
        switch self {
        case .home:          return [Color(red: 0.37, green: 0.55, blue: 0.77), Color(red: 0.59, green: 0.83, blue: 0.85), Color(red: 0.98, green: 0.91, blue: 0.84)]
        case .goal:          return [Color(red: 0.02, green: 0.36, blue: 0.41), Color(red: 0.08, green: 0.24, blue: 0.44), Color(red: 0.26, green: 0.20, blue: 0.36)]
        case .safety:        return [Color(red: 0.02, green: 0.50, blue: 0.47), Color(red: 0.13, green: 0.33, blue: 0.54), Color(red: 0.38, green: 0.35, blue: 0.63)]
        case .training:      return [Color(red: 0.08, green: 0.37, blue: 0.50), Color(red: 0.62, green: 0.86, blue: 0.85), Color(red: 0.98, green: 0.91, blue: 0.84)]
        case .complete:      return [Color(red: 0.48, green: 0.55, blue: 0.80), Color(red: 0.96, green: 0.83, blue: 0.80), Color(red: 0.98, green: 0.94, blue: 0.89)]
        case .progress:      return [Color(red: 0.06, green: 0.16, blue: 0.31), Color(red: 0.09, green: 0.27, blue: 0.43), Color(red: 0.43, green: 0.38, blue: 0.50)]
        case .learn:         return [Color(red: 0.17, green: 0.55, blue: 0.68), Color(red: 0.71, green: 0.87, blue: 0.83), Color(red: 0.93, green: 0.91, blue: 0.90)]
        case .routine:       return [Color(red: 0.19, green: 0.33, blue: 0.67), Color(red: 0.73, green: 0.85, blue: 0.89), Color(red: 0.98, green: 0.93, blue: 0.87)]
        case .sessionChoice: return [Color(red: 0.50, green: 0.71, blue: 0.81), Color(red: 0.88, green: 0.91, blue: 0.85), Color(red: 0.97, green: 0.88, blue: 0.78)]
        case .settings:      return [Color(red: 0.20, green: 0.43, blue: 0.67), Color(red: 0.58, green: 0.54, blue: 0.79), Color(red: 0.91, green: 0.89, blue: 0.94)]
        }
    }
}

struct ControlGradientBackground: View {
    let theme: ControlTheme
    var body: some View {
        LinearGradient(colors: theme.colors,
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
```

**说明：** 此代码为设计起步，不是完整 App。实际颜色、深/浅文字 Token、Material 透明度及屏幕区域需逐页真机检查。Welcome 和 Journey 的图片层需额外资源与对比遮罩。

### 7.2 组件结构建议

```text
Control/
├── App/
│   ├── ControlApp.swift
│   └── AppRouter.swift
├── DesignSystem/
│   ├── ControlTheme.swift
│   ├── ControlGradientBackground.swift
│   ├── GlassCard.swift
│   ├── PrimaryPillButton.swift
│   ├── MetricCard.swift
│   └── ControlTabBar.swift
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Learn/
│   ├── Training/
│   ├── Progress/
│   └── Settings/
├── Models/
├── Services/
└── Resources/
    └── Assets.xcassets/
```

`TrainingEngine` 和数据模型应与 UI 分层；View 不要直接实现持久化或在 `onAppear` 中无条件启动计时器。

---

## 8. 设计验收清单

### 全局

- [ ] 5 个 Tab 的内容与路由明确，没有第六个 Tab。
- [ ] 12 屏渐变主题具有一致品牌感，正文不会和背景混色。
- [ ] 深浅文字在真实最差背景处均满足可读性要求。
- [ ] iPhone SE 类窄屏、小屏与 Pro Max 不错位；屏幕安全区正确。
- [ ] Dynamic Type、VoiceOver、Reduce Motion 可用；按钮触摸区 ≥44pt。
- [ ] 无无效订阅/登录/计划/提醒按钮；未实现功能隐藏。
- [ ] 计时器动画是时间指导而非生理数据可视化。
- [ ] 所有训练和 Progress 数字绑定真实模型/测试预览，正式版无伪数据。
- [ ] 风险文案、人体插画、训练参数走专业审核。

### 优先视觉验收 3 屏

1. **HomeView**：蓝天渐变 + 日期条 + 高辨识度今日训练卡 + 原生底栏。
2. **TrainingView**：聚焦圆环 + Contract/Relax 明确切换 + 暂停/恢复可靠 + 波纹平和不喧宾夺主。
3. **SessionCompleteView**：暖光渐变 + 成功提示 + 真实数据 + 不适反馈独立问题 + 幂等保存。

> 给 Cursor 的原则：先实现设计系统和这三屏的真实布局，再逐步扩展剩余页面；视觉图只用作参照，不硬编码截图中的年份、训练指标和未经审核的医疗内容。
