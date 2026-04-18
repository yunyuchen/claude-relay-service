# /api-stats + /insights Claude.ai 风格改版

- **Status**: design approved, plan pending
- **Date**: 2026-04-18
- **Scope**: `/api-stats` (web/admin-spa/src/views/ApiStatsView.vue, 1248 行) + `/insights` (InsightsView.vue, 681 行)
- **Out of scope**: 管理后台 (`/dashboard`, `/user-login`, admin/ 下所有路由), 后端 API, 数据模型

## 1. 目标与动机

当前两页使用玻璃拟态 + 渐变底 (glass-strong / gradient-bg) 风格，视觉与 Claude.ai 官网割裂，用户侧（API Key 使用者）打开两页能清楚看出"产品不成体系"。

改版目标：把两页统一到 Claude.ai 官网的视觉语言，提升可读性并建立与 Anthropic 生态的视觉归属。

非目标：功能变更、数据模型变更、管理后台改版、性能优化。

## 2. 回退约束（硬性）

用户明确要求"保留原风格，方便回退"。实现必须满足：

- **保留**现有 `ApiStatsView.vue` 和 `InsightsView.vue` 的全部业务代码（template + script）。做法：
  1. 把现有 `ApiStatsView.vue` 的全部内容**原样搬移**到新文件 `ApiStatsLegacyView.vue`（纯文件移动，不改一行业务逻辑）
  2. `ApiStatsView.vue` 改写为一个薄 Shell，根据 OEM flag 分发到 Legacy 或 Claude 视图
  3. `InsightsView.vue` 同样处理
- 新视图放独立文件 `ApiStatsClaudeView.vue`、`InsightsClaudeView.vue`
- 现有子组件（`StatsOverview`, `TokenDistribution`, `LimitConfig`, `ModelUsageStats`, `ServiceCostCards`, `AggregatedStatsCard`, `ApiKeyInput`, `UnifiedTestModal`, `LogoTitle` 等）**零改动**
- 通过 **OEM 设置 `useClaudeStyleStats`**（布尔，默认 `false`）切换：true → Shell 加载 Claude 视图，false → Shell 加载 Legacy 视图
- 新视图共享 store (`apistats.js`)、API client、数据 fetch 逻辑，只重写 template + 样式 + 结构性逻辑（如 period 全局化）
- 关闭开关后立即无损回退，无数据迁移、无 Redis 脏数据
- Legacy 视图保留时间：最少保留到改版后第 2 个 minor 版本；用户反馈稳定后再评估清理

## 3. 设计令牌

新增 `web/admin-spa/src/styles/claude-tokens.css`（仅在新视图引入，不污染全局）。

### 3.1 色板（Light）

| Token | 值 | 用途 |
|---|---|---|
| `--cr-bg` | `#FAF9F5` | 页面底（奶油米） |
| `--cr-surface` | `#FFFFFF` | 卡片底 |
| `--cr-surface-soft` | `#F5F3EC` | 次级块 / input 底 / pill 底 |
| `--cr-border` | `#E8E4D9` | 默认边框（1px） |
| `--cr-border-strong` | `#D6D1C2` | hover / focus 边框 |
| `--cr-text` | `#2B2420` | 主文本（暖黑） |
| `--cr-text-sec` | `#645D53` | 次级文本 |
| `--cr-text-ter` | `#9C9488` | 三级 / 辅助 |
| `--cr-coral` | `#C96442` | 主强调（链接、进度条、serif accent） |
| `--cr-coral-hover` | `#B0553A` | hover |
| `--cr-coral-soft` | `#FAEEE5` | 强调背景（avatar、pill） |
| `--cr-ok` | `#65866E` | 成功 / 绿 |
| `--cr-ok-soft` | `#EBF2EC` | 成功软底 |
| `--cr-warn` | `#C47E1A` | 警告 / 琥珀 |
| `--cr-warn-soft` | `#FBF1DC` | 警告软底 |
| `--cr-danger` | `#B14D3C` | 危险 / 红 |
| `--cr-danger-soft` | `#F7E5DF` | 危险软底 |

### 3.2 色板（Dark，Claude.ai 暖黑）

| Token | 值 |
|---|---|
| `--cr-bg` | `#1F1B17` |
| `--cr-surface` | `#2A2520` |
| `--cr-surface-soft` | `#34302A` |
| `--cr-border` | `#3F3932` |
| `--cr-border-strong` | `#524B42` |
| `--cr-text` | `#ECE6DA` |
| `--cr-text-sec` | `#A89F92` |
| `--cr-text-ter` | `#6E665B` |
| `--cr-coral` | `#E6896B`（亮度上调保对比度） |
| `--cr-coral-soft` | `rgba(230,137,107,.12)` |
| `--cr-ok` / `warn` / `danger` | 调亮版（同构映射） |

### 3.3 字体

```css
--cr-sans:  'Inter', system-ui, sans-serif;
--cr-serif: 'Fraunces', 'Source Serif 4', Georgia, serif;
--cr-mono:  'JetBrains Mono', ui-monospace, monospace;
```

使用规则：
- **Fraunces (serif)**：H1 页面标题、hero 大数字、KPI 数字、section h3、rank 序号
- **Inter (sans)**：所有 UI 文本、labels、说明段
- **JetBrains Mono**：数据细项（百分比、version、tabular-nums 数字列）

字体通过 Google Fonts 引入，放 `index.html` 的 `<link preconnect>` 后面（仅在新视图启用时）。

### 3.4 间距 / 圆角 / 阴影

- 卡片圆角：`16px`
- pill / 按钮圆角：`999px`（period）/ `8px`（普通）
- 边框：`1px solid var(--cr-border)`
- 内边距：卡片 `18-24px`，行 `12-14px 18-22px`
- 阴影：极少用，仅 period 激活胶囊 `0 1px 2px rgba(0,0,0,.06)`
- 图标库：**保留 Font Awesome**（项目已用，全站一致），但用作辅助；不强制切 Lucide

## 4. 信息架构重组

### 4.1 /api-stats 统计 tab

**移除**：
- 3 段 `<ModelUsageStats period="daily|monthly|alltime" />`（合并为 1 段 + 全局 period 切换）
- `ServiceCostCards` 独立 3 张渐变卡（改为 Services block 行式排列）
- 顶栏 `ThemeToggle` 位置不变但样式更换
- "时间切换按钮旁的测试下拉"整个菜单 + `UnifiedTestModal` 的入口（UnifiedTestModal 组件保留但不从此视图调用）
- 底部 actions 行（Test/Tutorial/Logout 在顶栏和身份条已有入口，不再重复）
- **额度卡 tab（quota）** — 整个 tab 从顶级导航隐藏；`handleRedeem` / `loadRedemptionHistory` 等逻辑不再从新视图调用（旧视图保留即可）

**保留（功能不变）**：
- `ApiKeyInput` — 登录态组件，重写样式为 Claude 风（单卡片居中 + Fraunces 标题）
- `StatsOverview` 字段 — 但折叠进 header strip 和 hero row，不再独立组件
- 限额字段 — 由 LimitConfig 字段抽出，新 QuotaStatus block
- Token 分布 — 由 TokenDistribution 字段抽出，合并进 hero 的 Tokens KPI pill 展开
- 模型 top — 由 ModelUsageStats 合并，新 TopModels block
- 服务费用 — 由 ServiceCostCards 抽出，新 Services block
- **使用教程 tab** — 保留为顶级 tab（`TutorialView`），教程内容渲染在 Claude 风容器里
- 通知弹窗 `apiStatsNotice` — 样式改为 Claude 风模态

**新增 / 重排**：
- **全局 period 切换**：单一 segmented 控件放 toolbar 右侧，切换影响所有 block（而不是各自内部切）
- **Hero row**：1 大（Total spend）+ 3 小（Tokens / Requests / Latency）
- **Per-key breakdown**（仅多 key 模式）：Services block 下方新增表格
- **Footer**：`All systems operational` · `Last sync` · `version`

### 4.2 /api-stats 骨架（从上到下）

```
┌─ Top nav ─────────────────────────────────────────┐
│ [Logo] Claude Relay · Stats    Insights Tutorial │
│                                 [ThemeToggle]Admin│
└───────────────────────────────────────────────────┘

H1: Your API usage
    Track spend, limits, and model breakdown across
    all connected services.

┌─ Toolbar ─────────────────────────────────────────┐
│ [Avatar] yunyu.crs.key         [Today Month All]  │
│  ● Active · Expires 90d · Gold     [Sign out]     │
└───────────────────────────────────────────────────┘

┌─ Hero row (1 hero + 3 KPI, responsive) ───────────┐
│ ┌─Total spend──┐ ┌─Tokens─┐ ┌─Requests─┐ ┌─Latency┐│
│ │  $128.43     │ │ 4.21M  │ │   142    │ │ 840ms │ │
│ │  ↑12% ...    │ │ [pills]│ │ [success]│ │ [p95] │ │
│ └──────────────┘ └────────┘ └──────────┘ └───────┘ │
└───────────────────────────────────────────────────┘

┌─ Dual (≥1280px) ──────────────────────────────────┐
│ ┌─ Quota status ────┐   ┌─ Services ───────────┐  │
│ │ Cost  ▓▓▓░ 62%    │   │ Claude    $82.10 ▓▓  │  │
│ │ RPM   ▓░░░ 12%    │   │ OpenAI    $46.33 ▓   │  │
│ │ Daily ▓░░░ 30%    │   │ Gemini    —          │  │
│ └───────────────────┘   │ Droid     —          │  │
│                         └──────────────────────┘  │
└───────────────────────────────────────────────────┘

┌─ Top models ──────────────────────────────────────┐
│ 01  claude-sonnet-4-5   $74.20   2.1M tok         │
│ 02  gpt-5               $46.33   0.8M tok         │
│ ...                                                │
│              Expand all →                          │
└───────────────────────────────────────────────────┘

┌─ Per-key breakdown (仅多 key) ────────────────────┐
│ 01  key-prod      $82.10   ...    WARN            │
│ 02  key-dev       $46.33   ...    OK              │
└───────────────────────────────────────────────────┘

─── ● All systems operational · sync 4s · v1.1.303 ─
```

### 4.3 /api-stats 教程 tab

顶级 Tab 切换器 UI 取消。访问规则：
- 默认状态 `currentTab = 'stats'`，渲染第 4.2 节骨架
- 顶栏的 `Tutorial` 链接点击设置 `currentTab = 'tutorial'`
- 此时页面保留顶栏 + H1（标题改为"Usage tutorial" + 简介段），隐藏 toolbar / hero / blocks，主体换 `<TutorialView />` 渲染
- 容器改为 Claude 风卡片：`bg-surface` + `border-border` + `rounded-16`，移除 `glass-strong`
- 提供一个"← Back to stats"链接返回 stats

### 4.4 /insights 骨架

```
┌─ Top nav（同 /api-stats） ────────────────────────┐

H1: 排行榜 & 洞察
    See top users, cache masters, and aggregate spend.

┌─ Fun stats row (4 cards) ─────────────────────────┐
│ ┌─卷王─┐ ┌─效率之星─┐ ┌─Token 大户─┐ ┌─总花费─┐ │
│ │ 👤   │ │ ⚡        │ │ 🪙          │ │ $XX   │ │
│ │ name │ │ name      │ │ name        │ │ reqs  │ │
│ └──────┘ └──────────┘ └────────────┘ └───────┘ │
└───────────────────────────────────────────────────┘
     （保留概念，但去掉渐变色块圆形图标；
      emoji 轻量化，卡片样式套 Claude tokens）

┌─ Main rank list ──────────────────────────────────┐
│ 🥇  name       ▓▓▓▓░░  $xx   tokens   ...        │
│ 🥈  name       ▓▓▓░░░  $xx   ...                  │
│ 🥉  name       ▓▓░░░░  $xx   ...                  │
│ 04  name       ...                                │
│ [time range: 今日 本月 全部]                      │
└───────────────────────────────────────────────────┘
```

排行榜前 3 保留 🥇🥈🥉 emoji（在 Claude.ai 风中适度使用表情符号是 OK 的）。

## 5. 关键组件改动清单

| 组件 | 动作 | 说明 |
|---|---|---|
| `ApiStatsView.vue` | **改为 Shell**（15 行左右） | 根据 `oemSettings.useClaudeStyleStats` 分发 |
| `InsightsView.vue` | **改为 Shell** | 同上 |
| `ApiStatsLegacyView.vue` | **新建**（现 `ApiStatsView.vue` 内容原样迁入） | Legacy 路径，完整保留旧 UI |
| `InsightsLegacyView.vue` | **新建**（同上） | Legacy 路径 |
| `ApiStatsClaudeView.vue` | **新建** | Claude 风主视图 |
| `InsightsClaudeView.vue` | **新建** | Claude 风洞察视图 |
| 子组件 (`StatsOverview`, `TokenDistribution`, `LimitConfig`, `ModelUsageStats`, `ServiceCostCards`, `AggregatedStatsCard`) | 保留，0 改动 | 新视图不复用这些组件，内联重写 block |
| `ApiKeyInput.vue` | 保留；新建 `ApiKeyInputClaude.vue` | 仅样式不同，逻辑共享 store |
| `UnifiedTestModal.vue` | 保留，0 改动 | Legacy 视图使用，新视图不调用 |
| `TutorialView.vue` | 保留，0 改动 | 内容复用，外层容器由父视图决定 |
| `LogoTitle.vue` | 保留；新视图**不使用**，内联新 brand component | 旧 LogoTitle 绑 glass 风，与 Claude 风冲突 |
| `ThemeToggle.vue` | 保留并复用 | 新视图内仍显示 |
| Store (`apistats.js`) | 保留并复用 | 所有 state / actions 完全一致 |
| 后端 OEM 服务 | 新增字段 `useClaudeStyleStats` | 默认 `false`，对公开 OEM endpoint 可见 |
| 管理后台 OEM 设置页 | 新增开关 | Label: `Use Claude.ai style (stats/insights pages)` |

## 6. Feature flag 机制

### 6.1 OEM 设置扩展

后端在 `src/services/oemSettingsService.js`（或等价路径）的 OEM 设置结构中新增：

```js
{
  // ... 现有字段
  useClaudeStyleStats: false  // 默认关闭，不影响现有部署
}
```

对外通过 `/api/oem-settings`（公开端点）返回，新老前端都会拿到此字段。

### 6.2 视图分发机制

采用 **Shell 分发** 方案。不改 router：

1. 新建两个"实体"视图组件：
   - `ApiStatsClaudeView.vue`（Claude 风新视图）
   - `InsightsClaudeView.vue`（Claude 风洞察视图）
2. 新建两个"遗留"视图组件（把现有 `ApiStatsView.vue` 和 `InsightsView.vue` 的内容原样迁移进去）：
   - `ApiStatsLegacyView.vue`
   - `InsightsLegacyView.vue`
3. 现有 `ApiStatsView.vue` 和 `InsightsView.vue` 变成 Shell，只做分发：

```vue
<!-- ApiStatsView.vue -->
<script setup>
import { computed, shallowRef, defineAsyncComponent } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

const useClaude = computed(() => oemSettings.value?.useClaudeStyleStats === true)

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))
</script>

<template>
  <component :is="useClaude ? ClaudeView : LegacyView" />
</template>
```

OEM 设置从 store 拿（store 已在 `loadOemSettings()` 里 populate）。Shell 在 OEM 加载完毕前可以默认走 Legacy 避免闪烁。

**路由配置完全不动**。

### 6.3 管理界面开关

管理后台 `OEM 设置`页面新增一个 switch："Use Claude.ai style (stats/insights pages)"；默认 off。

## 7. 响应式断点

| 断点 | padding | 布局变化 |
|---|---|---|
| `< 800px` (mobile) | 24px | hero row 单列；dual 单列；toolbar 上下叠 |
| `800-1200px` | 32px | hero row 3 列（去 latency）；dual 单列 |
| `1200-1280px` | 40px | hero row 4 列；dual 单列 |
| `≥ 1280px` | 48px | hero row 4 列；dual 双列 |
| `≥ 1440px` | 80px | 同上，padding 更宽 |
| `≥ 1920px` | 120px | 同上 |

所有卡片 `max-width: 100%`，跟随 padding 自然全铺。

## 8. 边界情况

| 场景 | 行为 |
|---|---|
| **未输入 API Key**（`!apiId`） | 单卡片居中：Fraunces H1 "Enter your API key" + input + coral 按钮；不渲染骨架 |
| **加载中** (`loading`) | Block 占位：1px border 骨架 + 灰色 shimmer bar（不要 spinner icon） |
| **单 Key 模式** | `Per-key breakdown` block 不渲染 |
| **多 Key 模式** | 身份条显示 `3 keys` 徽章；hero 数字为聚合；新增 `Per-key breakdown` |
| **错误** (`error`) | 顶部 inline alert：`--cr-danger-soft` 底 + `--cr-danger` 边 + 文字 |
| **空数据**（某服务 `$0`） | 行保留但 `text-ter` 灰化显示 `—` |
| **Limit 未配置** | 不渲染该行 |
| **权限不足不能看某服务** | 行保留 `—`（与空数据同） |
| **通知弹窗** | 保留逻辑，样式改 Claude 风卡 |

## 9. Dark mode 规则

- ThemeToggle 保留；切换 `<html class="dark">` 后整套 tokens 切到 dark 变量表
- 不强制任一模式；auto 跟随系统
- Hero 右上软光晕 dark 模式下用 `rgba(230,137,107,.08)`
- 所有渐变、阴影在 dark 下降透明度避免刺眼

## 10. 图标与 emoji

- 保留 Font Awesome 为主图标库（`fas fa-*`），但在新视图仅用简洁几何：`chart-line` / `shield-alt` / `user` / `sign-out-alt` 等
- 弃用新视图里所有渐变圆形背景图标（`bg-gradient-to-br from-* to-*`）
- 排行榜 🥇🥈🥉 保留
- 其他 emoji（📊📈🚀 等营销感 emoji）不用

## 11. 迁移 / 上线策略

1. 新增后端 OEM 字段，默认 `false` — 老用户无感
2. 前端新建文件，完成视觉 + 功能
3. 管理后台开关默认 `false`，用户自行打开试用
4. 收集反馈；满意则在下个版本把默认值改 `true`
5. 如果数周内仍有人用旧视图，保留双文件到下下版本；没有反馈再清理旧文件

## 12. 验收标准

- 开关 **false** 时 `/api-stats` 和 `/insights` 视觉行为 100% 与改版前一致
- 开关 **true** 时：
  - 两页视觉符合 Claude.ai 风（色板、字体、布局匹配本 spec）
  - 所有现有数据功能保留（登录、查询、切换时间、多 key、限额显示、教程）
  - 额度卡 tab 不可见
  - Light / Dark 模式均完整覆盖
  - 响应式从 375px 到 1920px+ 无破版
  - Lighthouse accessibility ≥ 90（色对比度满足 WCAG AA）
- 代码改动不触及管理后台、后端业务逻辑、数据模型
- 移除开关后代码零残留
