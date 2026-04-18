# /api-stats + /insights Claude.ai 风改版 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在保留旧 UI 可回退的前提下，为 `/api-stats` 和 `/insights` 两页实现 Claude.ai 风（暖米 + 珊瑚橙 + Fraunces/Inter/JetBrains Mono）改版，通过 OEM feature flag 切换。

**Architecture:** Shell 模式——`ApiStatsView.vue` 和 `InsightsView.vue` 改为薄分发层；原内容搬移到 `*LegacyView.vue`；新版在 `*ClaudeView.vue`。后端 OEM 新增 `useClaudeStyleStats` 布尔字段，默认 false。新视图内联 block 不复用老子组件，共享 Pinia store 与 API client。

**Tech Stack:** Vue 3 (Composition API) + Pinia + Tailwind CSS + Font Awesome（保留）+ Google Fonts（Inter / Fraunces / JetBrains Mono）+ Jest（后端测试）

**Reference spec:** `docs/superpowers/specs/2026-04-18-api-stats-redesign-design.md`

**Reference mockup:** `.superpowers/brainstorm/1085-1776470293/content/claude-style.html`（所有 CSS 视觉源码参考这里）

---

### Task 1: Backend — OEM 设置新增 `useClaudeStyleStats` 字段

**Files:**
- Modify: `src/routes/admin/system.js`（两个 handler：GET `/oem-settings` L94-, PUT `/oem-settings` L137-）
- Test: `tests/oemSettingsUseClaudeStyle.test.js`（新建）

- [ ] **Step 1: 写失败测试**

```js
// tests/oemSettingsUseClaudeStyle.test.js
const request = require('supertest')

jest.mock('../src/models/redis', () => {
  const store = new Map()
  const client = {
    get: jest.fn((k) => Promise.resolve(store.get(k) || null)),
    set: jest.fn((k, v) => { store.set(k, v); return Promise.resolve('OK') })
  }
  return { getClient: () => client, client, __store: store }
})

jest.mock('../src/middleware/auth', () => ({
  authenticateAdmin: (req, res, next) => next(),
  authenticateApiKey: (req, res, next) => next()
}))

const express = require('express')

describe('OEM settings useClaudeStyleStats', () => {
  let app

  beforeEach(() => {
    jest.resetModules()
    const router = require('../src/routes/admin/system')
    app = express()
    app.use(express.json())
    app.use('/admin', router)
  })

  test('GET /admin/oem-settings 默认返回 useClaudeStyleStats=false', async () => {
    const res = await request(app).get('/admin/oem-settings')
    expect(res.status).toBe(200)
    expect(res.body.success).toBe(true)
    expect(res.body.data.useClaudeStyleStats).toBe(false)
  })

  test('PUT /admin/oem-settings 接受 useClaudeStyleStats=true 并回显', async () => {
    const put = await request(app)
      .put('/admin/oem-settings')
      .send({ siteName: 'Test', useClaudeStyleStats: true })
    expect(put.status).toBe(200)
    expect(put.body.data.useClaudeStyleStats).toBe(true)

    const get = await request(app).get('/admin/oem-settings')
    expect(get.body.data.useClaudeStyleStats).toBe(true)
  })

  test('PUT /admin/oem-settings 未提供 useClaudeStyleStats 时默认 false', async () => {
    const put = await request(app)
      .put('/admin/oem-settings')
      .send({ siteName: 'Test' })
    expect(put.body.data.useClaudeStyleStats).toBe(false)
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run: `npm test -- oemSettingsUseClaudeStyle`
Expected: FAIL — `expect(res.body.data.useClaudeStyleStats).toBe(false)` 会因为字段未定义而失败。

- [ ] **Step 3: 修改 GET handler 增加 default**

在 `src/routes/admin/system.js` 的 GET `/oem-settings` 的 `defaultSettings` 对象末尾添加：

```js
    const defaultSettings = {
      siteName: 'Claude Relay Service',
      siteIcon: '',
      siteIconData: '',
      showAdminButton: true,
      apiStatsNotice: {
        enabled: false,
        title: '',
        content: ''
      },
      useClaudeStyleStats: false, // 新增：是否使用 Claude.ai 风 /api-stats + /insights 视图
      updatedAt: new Date().toISOString()
    }
```

- [ ] **Step 4: 修改 PUT handler 接受新字段**

在 `src/routes/admin/system.js` 的 PUT `/oem-settings` 的 body 解构 + settings 构造中补齐：

```js
    const {
      siteName,
      siteIcon,
      siteIconData,
      showAdminButton,
      apiStatsNotice,
      useClaudeStyleStats  // 新增
    } = req.body

    // ... 现有校验保持不变 ...

    const settings = {
      siteName: siteName.trim(),
      siteIcon: (siteIcon || '').trim(),
      siteIconData: (siteIconData || '').trim(),
      showAdminButton: showAdminButton !== false,
      apiStatsNotice: {
        enabled: apiStatsNotice?.enabled === true,
        title: (apiStatsNotice?.title || '').trim().slice(0, 100),
        content: (apiStatsNotice?.content || '').trim().slice(0, 2000)
      },
      useClaudeStyleStats: useClaudeStyleStats === true, // 新增：显式 true 才启用，其他一律 false
      updatedAt: new Date().toISOString()
    }
```

- [ ] **Step 5: 运行测试确认通过**

Run: `npm test -- oemSettingsUseClaudeStyle`
Expected: PASS（3 个 test case 全绿）

- [ ] **Step 6: 运行全量后端 lint 确保无回归**

Run: `npm run lint`
Expected: 0 errors / 0 warnings

- [ ] **Step 7: Commit**

```bash
git add src/routes/admin/system.js tests/oemSettingsUseClaudeStyle.test.js
git commit -m "feat(oem): 新增 useClaudeStyleStats 开关字段，默认关闭"
```

---

### Task 2: 管理后台 OEM 设置页加入开关 UI

**Files:**
- Modify: `web/admin-spa/src/views/SettingsView.vue`（OEM 设置区域 + `saveOemSettings` 函数）
- Modify: `web/admin-spa/src/stores/settings.js`（如果 saveOemSettings 这里也做字段白名单）

- [ ] **Step 1: 定位 OEM 设置 UI 中现有的 "apiStatsNotice" 开关区块**

Run: `grep -n "apiStatsNotice.enabled" web/admin-spa/src/views/SettingsView.vue`
参考行号（两个位置各一个开关）。我们在"apiStatsNotice"开关同一 section 下追加一个同款 toggle。

- [ ] **Step 2: 在 SettingsView.vue 的 OEM 区域增加开关**

在 `apiStatsNotice` 整块结束后（约 L290-300，在 save/reset 按钮行之前）新增：

```vue
<!-- 使用 Claude.ai 风统计页开关 -->
<div class="flex flex-col gap-2 rounded-lg bg-gray-50 p-4 dark:bg-gray-700/50">
  <div class="flex items-center justify-between">
    <div>
      <label class="text-sm font-medium text-gray-900 dark:text-gray-200">
        Claude.ai 风统计页
      </label>
      <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
        启用后 /api-stats 和 /insights 切换为 Claude.ai 风格（暖米 + 珊瑚橙）。关闭立刻回到原样式。
      </p>
    </div>
    <label class="relative inline-flex cursor-pointer items-center">
      <input
        v-model="oemSettings.useClaudeStyleStats"
        class="peer sr-only"
        type="checkbox"
      />
      <div
        class="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-blue-500 peer-checked:after:translate-x-full peer-checked:after:border-white dark:bg-gray-600 dark:peer-checked:bg-blue-500"
      ></div>
      <span class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300">
        {{ oemSettings.useClaudeStyleStats ? '已启用' : '已禁用' }}
      </span>
    </label>
  </div>
</div>
```

- [ ] **Step 3: 修改 `saveOemSettings` 函数带上新字段**

定位 `const saveOemSettings = async () => {` 函数（约 L3123），修改 `settings` 对象：

```js
const saveOemSettings = async () => {
  try {
    const settings = {
      siteName: oemSettings.value.siteName,
      siteIcon: oemSettings.value.siteIcon,
      siteIconData: oemSettings.value.siteIconData,
      showAdminButton: oemSettings.value.showAdminButton,
      apiStatsNotice: oemSettings.value.apiStatsNotice,
      useClaudeStyleStats: oemSettings.value.useClaudeStyleStats === true // 新增
    }
    // ... 后续保持不变
```

- [ ] **Step 4: 确保 oemSettings 初始化包含新字段**

搜索 SettingsView.vue 中 `oemSettings = ref({...})` 或同等初始化位置：

Run: `grep -n "oemSettings.*ref\|oemSettings = " web/admin-spa/src/views/SettingsView.vue`

在初始对象里增加 `useClaudeStyleStats: false,`，保证 v-model 有初值不报 `undefined`。

- [ ] **Step 5: 启动前端 dev server 手动验证**

Run: `cd web/admin-spa && npm run dev`
Browser: 打开 admin 后台 → 系统设置 → OEM 设置
- 确认新开关渲染位置正确
- 切换 on / off → 点"保存设置" → 成功 toast
- 刷新页面 → 开关状态持久化（证明后端成功写入并读回）
- 确认已保存后的 `GET /admin/oem-settings` 响应中 `useClaudeStyleStats` 为预期值

- [ ] **Step 6: Commit**

```bash
git add web/admin-spa/src/views/SettingsView.vue
git commit -m "feat(admin-ui): OEM 设置新增 Claude.ai 风统计页开关"
```

---

### Task 3: Shell 重构 — `ApiStatsView.vue` 拆为 Shell + Legacy

**Files:**
- Move: `web/admin-spa/src/views/ApiStatsView.vue` → `web/admin-spa/src/views/ApiStatsLegacyView.vue`（git mv，内容不改）
- Create: 新的 `web/admin-spa/src/views/ApiStatsView.vue`（Shell）
- Create: `web/admin-spa/src/views/ApiStatsClaudeView.vue`（占位，后续任务填充）

- [ ] **Step 1: 用 git mv 保留文件历史**

```bash
cd D:/Github/claude-relay-service
git mv web/admin-spa/src/views/ApiStatsView.vue web/admin-spa/src/views/ApiStatsLegacyView.vue
```

- [ ] **Step 2: 新建占位 Claude 视图**

创建 `web/admin-spa/src/views/ApiStatsClaudeView.vue`：

```vue
<template>
  <div class="min-h-screen p-6" style="background:#FAF9F5">
    <p>ApiStatsClaudeView — placeholder, will be built in later tasks.</p>
  </div>
</template>

<script setup>
// TODO(Task 7+): implement Claude.ai style view
</script>
```

- [ ] **Step 3: 新建 Shell `ApiStatsView.vue`**

创建 `web/admin-spa/src/views/ApiStatsView.vue`：

```vue
<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

// Shell 在 OEM 加载完成前默认走 Legacy 以避免闪烁
const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  // 如果 store 之前没加载过 OEM，这里兜底加载一次
  if (typeof apiStatsStore.loadOemSettings === 'function' && !oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
```

- [ ] **Step 4: 启动 dev server，OEM 关关闭态下手动回归**

Run: `cd web/admin-spa && npm run dev`
Browser: 访问 `/api-stats`（无 API Key 状态和已输入 key 状态各一遍）
- 视觉 / 功能应该与改版前 **完全一致**（因为 flag 默认 false，走的是 Legacy 视图）
- 登录、period 切换、多 key、测试弹窗、额度卡、教程 tab 全部按原样工作
- 浏览器 DevTools → 在 `/admin/oem-settings` 响应中确认 `useClaudeStyleStats: false`

- [ ] **Step 5: 手动验证 flag 打开效果**

在管理后台打开"Claude.ai 风统计页"开关并保存，访问 `/api-stats`：
- 此时应该看到占位文本 "ApiStatsClaudeView — placeholder..."
- 关闭开关再保存，再访问 `/api-stats` → 回到 Legacy

- [ ] **Step 6: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsView.vue web/admin-spa/src/views/ApiStatsLegacyView.vue web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "refactor(api-stats): 拆分为 Shell + Legacy + ClaudeView 骨架"
```

---

### Task 4: Shell 重构 — `InsightsView.vue` 拆为 Shell + Legacy

**Files:**
- Move: `web/admin-spa/src/views/InsightsView.vue` → `web/admin-spa/src/views/InsightsLegacyView.vue`
- Create: 新的 `web/admin-spa/src/views/InsightsView.vue`（Shell）
- Create: `web/admin-spa/src/views/InsightsClaudeView.vue`（占位）

- [ ] **Step 1: Git mv**

```bash
git mv web/admin-spa/src/views/InsightsView.vue web/admin-spa/src/views/InsightsLegacyView.vue
```

- [ ] **Step 2: 占位 Claude 视图**

创建 `web/admin-spa/src/views/InsightsClaudeView.vue`：

```vue
<template>
  <div class="min-h-screen p-6" style="background:#FAF9F5">
    <p>InsightsClaudeView — placeholder, will be built in later tasks.</p>
  </div>
</template>

<script setup>
// TODO(Task 14): implement Claude.ai style insights
</script>
```

- [ ] **Step 3: Shell `InsightsView.vue`**

创建 `web/admin-spa/src/views/InsightsView.vue`：

```vue
<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./InsightsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./InsightsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  if (typeof apiStatsStore.loadOemSettings === 'function' && !oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
```

- [ ] **Step 4: 手动验证**

Browser 访问 `/insights`：
- flag off → Legacy 原样渲染
- flag on → 占位文本

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/InsightsView.vue web/admin-spa/src/views/InsightsLegacyView.vue web/admin-spa/src/views/InsightsClaudeView.vue
git commit -m "refactor(insights): 拆分为 Shell + Legacy + ClaudeView 骨架"
```

---

### Task 5: 设计令牌与字体

**Files:**
- Create: `web/admin-spa/src/styles/claude-tokens.css`

- [ ] **Step 1: 新建 tokens CSS**

创建 `web/admin-spa/src/styles/claude-tokens.css`：

```css
/* 仅由 ApiStatsClaudeView / InsightsClaudeView / 其子 Claude 组件引入。
   不放到全局入口，避免污染 admin 后台样式。 */

@import url('https://fonts.googleapis.com/css2?family=Fraunces:wght@400;500;600&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');

.cr-theme {
  --cr-bg: #FAF9F5;
  --cr-surface: #FFFFFF;
  --cr-surface-soft: #F5F3EC;
  --cr-border: #E8E4D9;
  --cr-border-strong: #D6D1C2;
  --cr-text: #2B2420;
  --cr-text-sec: #645D53;
  --cr-text-ter: #9C9488;
  --cr-coral: #C96442;
  --cr-coral-hover: #B0553A;
  --cr-coral-soft: #FAEEE5;
  --cr-ok: #65866E;
  --cr-ok-soft: #EBF2EC;
  --cr-warn: #C47E1A;
  --cr-warn-soft: #FBF1DC;
  --cr-danger: #B14D3C;
  --cr-danger-soft: #F7E5DF;

  --cr-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
  --cr-serif: 'Fraunces', 'Source Serif 4', Georgia, serif;
  --cr-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, monospace;
}

.dark .cr-theme,
.cr-theme.dark {
  --cr-bg: #1F1B17;
  --cr-surface: #2A2520;
  --cr-surface-soft: #34302A;
  --cr-border: #3F3932;
  --cr-border-strong: #524B42;
  --cr-text: #ECE6DA;
  --cr-text-sec: #A89F92;
  --cr-text-ter: #6E665B;
  --cr-coral: #E6896B;
  --cr-coral-hover: #ECA085;
  --cr-coral-soft: rgba(230, 137, 107, 0.12);
  --cr-ok: #8FB098;
  --cr-ok-soft: rgba(143, 176, 152, 0.12);
  --cr-warn: #E0A04C;
  --cr-warn-soft: rgba(224, 160, 76, 0.12);
  --cr-danger: #D37968;
  --cr-danger-soft: rgba(211, 121, 104, 0.12);
}

/* 工具类 */
.cr-theme {
  font-family: var(--cr-sans);
  color: var(--cr-text);
  background: var(--cr-bg);
  -webkit-font-smoothing: antialiased;
  font-size: 14px;
  line-height: 1.55;
}
.cr-theme .cr-mono { font-family: var(--cr-mono); font-feature-settings: 'tnum'; font-variant-numeric: tabular-nums; }
.cr-theme .cr-serif { font-family: var(--cr-serif); font-optical-sizing: auto; }

/* 通用卡片 */
.cr-theme .cr-card {
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 16px;
}
```

- [ ] **Step 2: 验证 CSS 无语法错误**

浏览器访问 `/api-stats`（flag on），DevTools Console 无报错；Network tab 可看到 Google Fonts 请求返回 200。

（如果 Google Fonts 被墙等问题，可替换为项目本地字体或 system stack — 暂时保留 Google Fonts 依赖，后续 Task 15 可能根据网络环境调整）

- [ ] **Step 3: Commit**

```bash
git add web/admin-spa/src/styles/claude-tokens.css
git commit -m "feat(stats-redesign): 新增 Claude 风设计令牌与字体"
```

---

### Task 6: `ApiStatsClaudeView.vue` 骨架 — 顶栏 + H1 + 登录态

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 替换占位为完整骨架**

整个文件替换为：

```vue
<template>
  <div class="cr-theme min-h-screen" :class="{ dark: isDarkMode }">
    <div class="cr-page">

      <!-- 顶栏 -->
      <nav class="cr-nav">
        <div class="cr-brand">
          <img
            v-if="oemSettings.siteIconData || oemSettings.siteIcon"
            :src="oemSettings.siteIconData || oemSettings.siteIcon"
            class="cr-logo-img"
            alt="logo"
          />
          <div v-else class="cr-logo-fallback cr-serif">
            {{ (oemSettings.siteName || 'R').charAt(0).toUpperCase() }}
          </div>
          <span class="cr-brand-text">
            {{ oemSettings.siteName || 'Claude Relay' }}
            <span class="cr-sep">·</span>
            <span class="cr-brand-sub">Stats</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link to="/insights" class="cr-nav-a">Insights</router-link>
          <a class="cr-nav-a" @click="currentTab = 'tutorial'">Tutorial</a>
          <ThemeToggle mode="dropdown" class="cr-theme-toggle" />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            to="/dashboard"
            class="cr-nav-a cr-nav-a-primary"
          >Admin</router-link>
        </div>
      </nav>

      <!-- 登录态：未输入 API Key -->
      <section v-if="!apiId && currentTab !== 'tutorial'" class="cr-auth">
        <div class="cr-card cr-auth-card">
          <h1 class="cr-serif cr-auth-title">Enter your API key</h1>
          <p class="cr-auth-sub">Sign in to view your usage, quota and model breakdown.</p>
          <ApiKeyInput />
        </div>
      </section>

      <!-- 教程 tab -->
      <section v-else-if="currentTab === 'tutorial'" class="cr-tut">
        <div class="cr-page-title">
          <a class="cr-back" @click="currentTab = 'stats'">← Back to stats</a>
          <h1 class="cr-serif">Usage tutorial</h1>
        </div>
        <div class="cr-card cr-tut-card">
          <TutorialView />
        </div>
      </section>

      <!-- 统计主体 -->
      <section v-else class="cr-main">
        <div class="cr-page-title">
          <h1 class="cr-serif">Your API usage</h1>
          <p>Track spend, limits, and model breakdown across all connected services.</p>
        </div>

        <!-- Toolbar / Hero / Quota+Services / Models / Per-key 等后续任务填充 -->
        <div class="cr-card" style="padding:18px">
          <p>Stats body — will be built in Task 7+</p>
        </div>
      </section>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ApiKeyInput from '@/components/apistats/ApiKeyInput.vue'
import ThemeToggle from '@/components/common/ThemeToggle.vue'
import TutorialView from './TutorialView.vue'
import '@/styles/claude-tokens.css'

const apiStatsStore = useApiStatsStore()
const themeStore = useThemeStore()

const { apiId, oemSettings } = storeToRefs(apiStatsStore)
const { loadOemSettings, loadApiKeyFromStorage, loadServiceRates } = apiStatsStore

const isDarkMode = computed(() => themeStore.isDarkMode)

const currentTab = ref('stats')

onMounted(() => {
  loadOemSettings()
  loadApiKeyFromStorage()
  loadServiceRates()
})
</script>

<style scoped>
.cr-page { padding: 24px; position: relative; }
@media (min-width: 1024px) { .cr-page { padding: 32px 48px; } }
@media (min-width: 1440px) { .cr-page { padding: 40px 80px; } }
@media (min-width: 1920px) { .cr-page { padding: 48px 120px; } }

.cr-nav { display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; gap: 12px; flex-wrap: wrap; }
.cr-brand { display: flex; align-items: center; gap: 10px; font-weight: 500; font-size: 16px; color: var(--cr-text); }
.cr-logo-img, .cr-logo-fallback { width: 28px; height: 28px; border-radius: 8px; }
.cr-logo-fallback { background: var(--cr-coral); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; }
.cr-brand-text { line-height: 1; }
.cr-sep { color: var(--cr-text-ter); font-weight: 400; margin: 0 4px; }
.cr-brand-sub { color: var(--cr-text-sec); font-weight: 400; }
.cr-nav-links { display: flex; gap: 4px; align-items: center; }
.cr-nav-a { font-size: 13px; padding: 8px 14px; border-radius: 8px; color: var(--cr-text-sec); font-weight: 500; cursor: pointer; transition: all .15s; text-decoration: none; }
.cr-nav-a:hover { color: var(--cr-text); background: var(--cr-surface-soft); }
.cr-nav-a-primary { background: var(--cr-text); color: var(--cr-bg); }
.cr-nav-a-primary:hover { background: var(--cr-text); color: var(--cr-bg); opacity: .9; }
:deep(.cr-theme-toggle) { margin: 0 2px; }

.cr-page-title { margin-bottom: 24px; }
.cr-page-title h1 { font-weight: 500; font-size: 32px; letter-spacing: -.02em; color: var(--cr-text); line-height: 1.1; }
.cr-page-title p { font-size: 14px; color: var(--cr-text-sec); margin-top: 6px; }

.cr-auth { max-width: 480px; margin: 48px auto; }
.cr-auth-card { padding: 32px; text-align: center; }
.cr-auth-title { font-size: 28px; font-weight: 500; letter-spacing: -.02em; margin-bottom: 6px; }
.cr-auth-sub { font-size: 13px; color: var(--cr-text-sec); margin-bottom: 20px; }

.cr-tut-card { padding: 24px; }
.cr-back { display: inline-block; font-size: 13px; color: var(--cr-coral); cursor: pointer; margin-bottom: 8px; font-weight: 500; }
.cr-back:hover { color: var(--cr-coral-hover); }
</style>
```

- [ ] **Step 2: 手动验证**

打开 flag，访问 `/api-stats`：
- 登录前：居中"Enter your API key" 大标题（衬线）+ 副文案 + ApiKeyInput 组件
- 登录后：出现 H1 "Your API usage" + 介绍段 + 占位卡片 "Stats body..."
- 点 Tutorial 链接 → 教程内容渲染，左上有"← Back to stats"
- 点 Back → 回到 stats 主体
- 点 Insights → 跳 `/insights`（由于 flag on，也是占位；回到 `/api-stats` 无干扰）
- 暗色模式切换 → `<html class="dark">` 时 tokens 切 dark variant

- [ ] **Step 3: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): ApiStatsClaudeView 骨架+顶栏+登录态+教程切换"
```

---

### Task 7: Toolbar — 身份条 + period 切换 + 登出

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 在"统计主体"section 中，删除占位卡片，插入 toolbar**

把 `<!-- 统计主体 -->` 下的 `<div class="cr-card" style="padding:18px">...</div>` 占位替换为：

```vue
        <!-- Toolbar: identity + period + signout -->
        <div class="cr-toolbar">
          <div class="cr-identity">
            <div class="cr-avatar cr-serif">
              {{ (statsData?.name || 'K').charAt(0).toUpperCase() }}
            </div>
            <div>
              <div class="cr-id-name">{{ statsData?.name || apiId }}</div>
              <div class="cr-id-meta">
                <span class="cr-status-dot"></span>
                {{ statsData?.isActive === false ? 'Inactive' : 'Active' }}
                <span v-if="multiKeyMode" class="cr-sep">·</span>
                <span v-if="multiKeyMode" class="cr-badge">{{ apiIds.length }} keys</span>
                <span v-if="statsData?.expiresAt" class="cr-sep">·</span>
                <span v-if="statsData?.expiresAt">Expires {{ expiresInText }}</span>
              </div>
            </div>
          </div>
          <div class="cr-toolbar-right">
            <div class="cr-period">
              <button
                :class="{ active: statsPeriod === 'daily' }"
                :disabled="loading"
                @click="switchPeriod('daily')"
              >Today</button>
              <button
                :class="{ active: statsPeriod === 'monthly' }"
                :disabled="loading"
                @click="switchPeriod('monthly')"
              >This month</button>
              <button
                :class="{ active: statsPeriod === 'alltime' }"
                :disabled="loading"
                @click="switchPeriod('alltime')"
              >All time</button>
            </div>
            <button class="cr-btn-ghost" @click="handleSignOut">Sign out</button>
          </div>
        </div>

        <!-- Hero / Quota+Services / Models / Per-key 续下（后续任务） -->
        <div class="cr-card" style="padding:18px;margin-top:24px">
          <p>Stats body — continued in Task 8+</p>
        </div>
```

- [ ] **Step 2: 补充 script 引用、computed、handler**

在 `<script setup>` 顶部 import / storeToRefs 区域替换为：

```js
const {
  apiId,
  apiKey,
  loading,
  statsPeriod,
  statsData,
  oemSettings,
  multiKeyMode,
  apiIds
} = storeToRefs(apiStatsStore)

const {
  loadOemSettings,
  loadApiKeyFromStorage,
  loadServiceRates,
  switchPeriod,
  reset
} = apiStatsStore
```

在 `onMounted` 之前加计算属性与登出：

```js
const expiresInText = computed(() => {
  const exp = statsData.value?.expiresAt
  if (!exp) return ''
  const days = Math.max(0, Math.round((new Date(exp) - Date.now()) / 86400000))
  if (days === 0) return 'today'
  if (days === 1) return 'in 1 day'
  if (days < 30) return `in ${days} days`
  if (days < 365) return `in ${Math.round(days / 30)} months`
  return `in ${Math.round(days / 365)} years`
})

function handleSignOut () {
  reset()
  currentTab.value = 'stats'
}
```

- [ ] **Step 3: 追加 toolbar 样式到 `<style scoped>`**

在现有 `<style scoped>` 末尾追加：

```css
.cr-toolbar { display: flex; justify-content: space-between; align-items: center; gap: 14px; flex-wrap: wrap; background: var(--cr-surface); border: 1px solid var(--cr-border); border-radius: 12px; padding: 10px 16px 10px 10px; margin-bottom: 28px; }
.cr-identity { display: flex; align-items: center; gap: 12px; }
.cr-avatar { width: 36px; height: 36px; border-radius: 10px; background: var(--cr-coral-soft); color: var(--cr-coral); display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; }
.cr-id-name { font-weight: 500; font-size: 14px; color: var(--cr-text); letter-spacing: -.01em; }
.cr-id-meta { display: flex; align-items: center; gap: 8px; color: var(--cr-text-sec); font-size: 12px; margin-top: 1px; flex-wrap: wrap; }
.cr-status-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--cr-ok); box-shadow: 0 0 0 3px rgba(101,134,110,.15); display: inline-block; }
.cr-badge { padding: 1px 8px; border-radius: 999px; background: var(--cr-coral-soft); color: var(--cr-coral); font-weight: 500; font-size: 11px; }
.cr-toolbar-right { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.cr-btn-ghost { font-size: 13px; padding: 8px 14px; border: 1px solid var(--cr-border); background: var(--cr-surface); border-radius: 8px; color: var(--cr-text-sec); cursor: pointer; font-weight: 500; font-family: inherit; transition: all .15s; }
.cr-btn-ghost:hover { border-color: var(--cr-border-strong); color: var(--cr-text); background: var(--cr-surface-soft); }
.cr-period { display: inline-flex; background: var(--cr-surface); border: 1px solid var(--cr-border); border-radius: 999px; padding: 3px; }
.cr-period > button { font-size: 13px; font-weight: 500; padding: 7px 16px; border: 0; background: transparent; border-radius: 999px; cursor: pointer; color: var(--cr-text-sec); font-family: inherit; transition: all .15s; }
.cr-period > button.active { background: var(--cr-text); color: var(--cr-bg); }
.cr-period > button:disabled { opacity: .5; cursor: not-allowed; }
.cr-period > button:hover:not(.active):not(:disabled) { color: var(--cr-text); }
```

- [ ] **Step 4: 手动验证**

登录一个 API key → 看到 toolbar：
- 身份信息：头像、name、● Active · Expires in X days
- period 三按钮 pill，激活态深色胶囊
- 点 period 按钮切换 → 对应数据 reload；loading 时按钮 disabled
- 点 "Sign out" → 回到登录卡片
- 多 key 模式（输入多个 key）→ 身份条显示 `N keys` 小徽章

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): 身份条 + period 切换 + 登出"
```

---

### Task 8: Hero row — 花费大数字 + 3 KPI

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 替换"Stats body continued"占位**

把 `<div class="cr-card" style="padding:18px;margin-top:24px">...</div>` 换成：

```vue
        <!-- Hero row -->
        <div class="cr-hero-row">
          <div class="cr-hero">
            <div class="cr-hero-label">
              {{ periodLabel }} spend
            </div>
            <div class="cr-hero-n cr-serif cr-mono">
              {{ formatCurrencyHero(currentPeriodData.cost) }}
            </div>
            <div class="cr-delta-row">
              <span v-if="costDelta !== null" class="cr-delta" :class="costDelta < 0 ? 'neg' : ''">
                {{ costDelta >= 0 ? '↑' : '↓' }} {{ Math.abs(costDelta).toFixed(0) }}% vs previous
              </span>
              <span class="cr-sub-note">Updated just now</span>
            </div>
          </div>

          <div class="cr-kpi">
            <div class="cr-kpi-label">Tokens</div>
            <div class="cr-kpi-n cr-serif cr-mono">
              {{ formatTokensShort(currentPeriodData.allTokens) }}
            </div>
            <div class="cr-kpi-d">
              <span class="cr-pill cr-mono">in {{ formatTokensShort(currentPeriodData.inputTokens) }}</span>
              <span class="cr-pill cr-mono">out {{ formatTokensShort(currentPeriodData.outputTokens) }}</span>
              <span
                v-if="(currentPeriodData.cacheReadTokens || 0) + (currentPeriodData.cacheCreateTokens || 0) > 0"
                class="cr-pill cr-mono"
              >cache {{ formatTokensShort((currentPeriodData.cacheReadTokens || 0) + (currentPeriodData.cacheCreateTokens || 0)) }}</span>
            </div>
          </div>

          <div class="cr-kpi">
            <div class="cr-kpi-label">Requests</div>
            <div class="cr-kpi-n cr-serif cr-mono">
              {{ (currentPeriodData.requests || 0).toLocaleString() }}
            </div>
            <div class="cr-kpi-d">
              <span
                v-if="successRate !== null"
                class="cr-pill cr-mono"
              >success {{ successRate.toFixed(1) }}%</span>
            </div>
          </div>

          <div v-if="avgLatencyMs !== null" class="cr-kpi cr-kpi-lat">
            <div class="cr-kpi-label">Latency</div>
            <div class="cr-kpi-n cr-serif cr-mono">
              {{ Math.round(avgLatencyMs) }}<span class="cr-unit">ms</span>
            </div>
            <div class="cr-kpi-d">
              <span class="cr-pill cr-mono">avg</span>
            </div>
          </div>
        </div>
```

- [ ] **Step 2: 补充 script 的 computed / helpers**

在 `<script setup>` 现有内容下方追加：

```js
const periodLabel = computed(() =>
  statsPeriod.value === 'daily' ? 'Today' :
  statsPeriod.value === 'monthly' ? 'This month' : 'All time'
)

const currentPeriodData = computed(() => apiStatsStore.currentPeriodData)

const costDelta = computed(() => {
  // 若后端提供 previous period cost 则计算；否则 null 不渲染 delta
  const cur = currentPeriodData.value?.cost || 0
  const prev = currentPeriodData.value?.previousCost
  if (prev == null || prev === 0) return null
  return ((cur - prev) / prev) * 100
})

const successRate = computed(() => {
  const total = currentPeriodData.value?.requests || 0
  const failed = currentPeriodData.value?.failedRequests
  if (!total || failed == null) return null
  return ((total - failed) / total) * 100
})

const avgLatencyMs = computed(() => {
  const ms = currentPeriodData.value?.avgLatencyMs
  return typeof ms === 'number' && isFinite(ms) ? ms : null
})

function formatCurrencyHero (cost) {
  if (cost == null) return '$0.00'
  // 保留两位小数但 cents 部分较小显示
  return '$' + (Number(cost) || 0).toFixed(2)
}

function formatTokensShort (n) {
  n = Number(n) || 0
  if (n >= 1e9) return (n / 1e9).toFixed(2).replace(/\.?0+$/, '') + 'B'
  if (n >= 1e6) return (n / 1e6).toFixed(2).replace(/\.?0+$/, '') + 'M'
  if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.?0+$/, '') + 'K'
  return String(n)
}
```

- [ ] **Step 3: 追加 hero 样式**

```css
.cr-hero-row { display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 14px; margin-bottom: 28px; }
@media (max-width: 1200px) { .cr-hero-row { grid-template-columns: 2fr 1fr 1fr; } .cr-hero-row .cr-kpi-lat { display: none; } }
@media (max-width: 800px) { .cr-hero-row { grid-template-columns: 1fr 1fr; } .cr-hero-row .cr-hero { grid-column: 1 / -1; } .cr-hero-row .cr-kpi-lat { display: block; } }
.cr-hero { background: var(--cr-surface); border: 1px solid var(--cr-border); border-radius: 16px; padding: 24px 28px; position: relative; overflow: hidden; }
.cr-hero::before { content: ""; position: absolute; top: -80px; right: -80px; width: 240px; height: 240px; background: radial-gradient(circle, var(--cr-coral-soft) 0%, transparent 70%); pointer-events: none; }
.cr-hero-label { font-size: 13px; color: var(--cr-text-sec); font-weight: 500; position: relative; }
.cr-hero-n { font-size: 56px; line-height: 1.05; letter-spacing: -.03em; color: var(--cr-text); margin-top: 8px; position: relative; font-weight: 500; }
.cr-delta-row { display: flex; align-items: center; gap: 10px; margin-top: 12px; position: relative; flex-wrap: wrap; }
.cr-delta { display: inline-flex; align-items: center; gap: 4px; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 500; background: var(--cr-ok-soft); color: var(--cr-ok); }
.cr-delta.neg { background: var(--cr-danger-soft); color: var(--cr-danger); }
.cr-sub-note { font-size: 13px; color: var(--cr-text-sec); }
.cr-kpi { background: var(--cr-surface); border: 1px solid var(--cr-border); border-radius: 16px; padding: 18px 22px; }
.cr-kpi-label { font-size: 13px; color: var(--cr-text-sec); font-weight: 500; }
.cr-kpi-n { font-size: 30px; line-height: 1.1; letter-spacing: -.02em; margin-top: 6px; color: var(--cr-text); font-weight: 500; }
.cr-kpi-n .cr-unit { color: var(--cr-text-ter); font-size: 18px; font-weight: 400; font-family: var(--cr-sans); }
.cr-kpi-d { font-size: 12px; color: var(--cr-text-ter); margin-top: 8px; display: flex; gap: 6px; flex-wrap: wrap; }
.cr-pill { background: var(--cr-surface-soft); padding: 2px 8px; border-radius: 6px; color: var(--cr-text-sec); }
```

- [ ] **Step 4: 手动验证**

- Hero 大数字显示 period 对应的 cost（两位小数）
- period 切换时数字更新
- Tokens KPI 显示总 token + pills 拆细（in/out/cache）
- Requests KPI 显示请求数 + success rate pill（若后端无 failedRequests 字段则不显示）
- 窄屏时 Latency KPI 首个消失；更窄时 hero 跨满

注：`previousCost` / `failedRequests` / `avgLatencyMs` 若后端 store 未暴露，则 delta/success/latency 自动隐藏（safe null handling）——不要为此报错。

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): hero row 花费 + 3 KPI"
```

---

### Task 9: Quota Status + Services 双列 block

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 在 hero-row 之后插入**

```vue
        <!-- Dual block: quota + services -->
        <div class="cr-dual">
          <div>
            <div class="cr-sec-head">
              <h3 class="cr-serif">Quota status</h3>
              <span class="cr-sec-meta" v-if="quotaRows.length">{{ quotaRows.length }} limits configured</span>
              <span class="cr-sec-meta" v-else>No limits set</span>
            </div>
            <div v-if="quotaRows.length" class="cr-card">
              <div v-for="row in quotaRows" :key="row.key" class="cr-row cr-lim-row">
                <span class="cr-k">{{ row.label }}</span>
                <div class="cr-bar">
                  <div :class="row.stateClass" :style="{ width: row.percent + '%' }"></div>
                </div>
                <span class="cr-v cr-mono">{{ row.valueText }}</span>
                <span class="cr-state" :class="row.stateClass">{{ row.percent }}%</span>
              </div>
            </div>
            <div v-else class="cr-card cr-empty">
              No limits configured for this key.
            </div>
          </div>

          <div>
            <div class="cr-sec-head">
              <h3 class="cr-serif">Services</h3>
              <span class="cr-sec-meta">{{ activeServicesCount }} of {{ serviceRows.length }} active</span>
            </div>
            <div class="cr-card">
              <div v-for="row in serviceRows" :key="row.name" class="cr-row cr-svc-row" :class="{ empty: !row.cost }">
                <span class="cr-name">{{ row.label }}</span>
                <span class="cr-val cr-mono">{{ row.cost ? formatCurrency(row.cost) : '—' }}</span>
                <div class="cr-bar"><div v-if="row.cost" :style="{ width: row.percent + '%' }"></div></div>
                <span class="cr-pct cr-mono">{{ row.cost ? row.percent + '%' : '—' }}</span>
              </div>
            </div>
          </div>
        </div>
```

- [ ] **Step 2: 补充 script 计算属性和 helpers**

```js
const quotaRows = computed(() => {
  const rows = []
  const limits = statsData.value?.limits || {}
  const usage = currentPeriodData.value || {}

  // 使用 limits 字段读取（字段名从 Legacy 的 LimitConfig.vue 里抄，若不同请以 store 为准）
  if (limits.costLimit != null && limits.costLimit > 0) {
    const used = usage.cost || 0
    const pct = Math.min(100, Math.round((used / limits.costLimit) * 100))
    rows.push({
      key: 'cost',
      label: 'Cost',
      percent: pct,
      valueText: `$${used.toFixed(2)} / $${Number(limits.costLimit).toFixed(2)}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }
  if (limits.rpmLimit != null && limits.rpmLimit > 0) {
    const used = statsData.value?.currentRpm || 0
    const pct = Math.min(100, Math.round((used / limits.rpmLimit) * 100))
    rows.push({
      key: 'rpm',
      label: 'RPM',
      percent: pct,
      valueText: `${used} / ${limits.rpmLimit}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }
  if (limits.dailyCostLimit != null && limits.dailyCostLimit > 0) {
    const used = statsData.value?.todayCost || 0
    const pct = Math.min(100, Math.round((used / limits.dailyCostLimit) * 100))
    rows.push({
      key: 'daily',
      label: 'Daily',
      percent: pct,
      valueText: `$${used.toFixed(2)} / $${Number(limits.dailyCostLimit).toFixed(2)}`,
      stateClass: pct >= 90 ? 'danger' : pct >= 60 ? 'warn' : 'ok'
    })
  }
  return rows
})

const serviceRows = computed(() => {
  // 服务列表来自 statsData.costsByService 或类似字段
  const KNOWN = [
    { key: 'claude', label: 'Claude' },
    { key: 'openai', label: 'OpenAI' },
    { key: 'gemini', label: 'Gemini' },
    { key: 'droid', label: 'Droid' },
    { key: 'bedrock', label: 'Bedrock' },
    { key: 'azure', label: 'Azure OpenAI' }
  ]
  const src = statsData.value?.costsByService || {}
  const totalCost = Object.values(src).reduce((a, b) => a + (Number(b) || 0), 0) || 1
  return KNOWN
    .map(({ key, label }) => {
      const cost = Number(src[key]) || 0
      return { name: key, label, cost, percent: Math.round((cost / totalCost) * 100) }
    })
    .sort((a, b) => b.cost - a.cost)
})

const activeServicesCount = computed(() => serviceRows.value.filter(r => r.cost > 0).length)

function formatCurrency (v) {
  const n = Number(v) || 0
  return '$' + n.toFixed(2)
}
```

**若 store/后端实际字段名不是 `limits.costLimit` / `statsData.costsByService` 等**：
Run: `grep -n "costLimit\|rpmLimit\|costsByService\|totalCost" web/admin-spa/src/stores/apistats.js web/admin-spa/src/views/ApiStatsLegacyView.vue web/admin-spa/src/components/apistats/LimitConfig.vue web/admin-spa/src/components/apistats/ServiceCostCards.vue`

拿到真实字段名替换上面的 `limits.XXX` / `costsByService` 引用，保持数据一致。

- [ ] **Step 3: 追加样式**

```css
.cr-sec-head { display: flex; justify-content: space-between; align-items: baseline; margin: 32px 0 12px 0; gap: 12px; flex-wrap: wrap; }
.cr-sec-head h3 { font-size: 20px; color: var(--cr-text); letter-spacing: -.01em; font-weight: 500; }
.cr-sec-head .cr-sec-meta { font-size: 13px; color: var(--cr-text-ter); }
.cr-dual { display: grid; grid-template-columns: 1fr; gap: 24px; }
@media (min-width: 1280px) { .cr-dual { grid-template-columns: 1fr 1fr; } }
.cr-row { display: grid; align-items: center; padding: 14px 22px; border-bottom: 1px solid var(--cr-border); gap: 16px; }
.cr-row:last-child { border-bottom: 0; }
.cr-lim-row { grid-template-columns: 90px 1fr 130px 80px; }
.cr-lim-row .cr-k { font-size: 14px; color: var(--cr-text); font-weight: 500; }
.cr-bar { height: 6px; background: var(--cr-surface-soft); border-radius: 3px; overflow: hidden; }
.cr-bar > div { height: 100%; border-radius: 3px; }
.cr-bar > div.ok { background: var(--cr-ok); }
.cr-bar > div.warn { background: var(--cr-warn); }
.cr-bar > div.danger { background: var(--cr-danger); }
.cr-lim-row .cr-v { font-size: 13px; text-align: right; color: var(--cr-text-sec); }
.cr-state { font-size: 12px; font-weight: 500; padding: 3px 10px; border-radius: 999px; text-align: center; }
.cr-state.ok { background: var(--cr-ok-soft); color: var(--cr-ok); }
.cr-state.warn { background: var(--cr-warn-soft); color: var(--cr-warn); }
.cr-state.danger { background: var(--cr-danger-soft); color: var(--cr-danger); }
.cr-svc-row { grid-template-columns: 110px 100px 1fr 50px; }
.cr-svc-row .cr-name { font-size: 14px; color: var(--cr-text); font-weight: 500; }
.cr-svc-row .cr-val { font-size: 14px; text-align: right; color: var(--cr-text); }
.cr-svc-row.empty .cr-val, .cr-svc-row.empty .cr-name { color: var(--cr-text-ter); }
.cr-svc-row .cr-bar > div { background: var(--cr-coral); }
.cr-svc-row .cr-pct { font-size: 13px; color: var(--cr-text-ter); text-align: right; }
.cr-empty { padding: 18px 22px; color: var(--cr-text-ter); font-size: 13px; }
```

- [ ] **Step 4: 手动验证**

- Quota 和 Services 在 ≥1280px 宽屏并列，窄屏单列
- 限额按状态配色（绿 OK / 琥珀 WARN ≥60% / 红 DANGER ≥90%）
- 服务按花费降序；零花费服务灰化 `—`，进度条不渲染
- 任何字段缺失时不报 js 错误

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): quota status + services 双列 block"
```

---

### Task 10: Top Models block（默认 5 条 + 展开全部）

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 在 dual 之后插入**

```vue
        <!-- Top models -->
        <div class="cr-sec-head">
          <h3 class="cr-serif">Top models</h3>
          <span class="cr-sec-meta">
            Showing {{ displayedModels.length }} of {{ sortedModels.length }}
          </span>
        </div>
        <div class="cr-card">
          <div v-for="(m, i) in displayedModels" :key="m.model" class="cr-row cr-mod-row">
            <span class="cr-rank cr-serif">{{ String(i + 1).padStart(2, '0') }}</span>
            <span class="cr-m">{{ m.model }}</span>
            <span class="cr-val cr-mono">{{ formatCurrency(m.cost) }}</span>
            <span class="cr-t cr-mono">{{ formatTokensShort(m.allTokens) }} tok</span>
          </div>
          <div v-if="sortedModels.length > 5 && !modelsExpanded" class="cr-mod-more">
            <a @click="modelsExpanded = true">Expand all →</a>
          </div>
          <div v-else-if="modelsExpanded && sortedModels.length > 5" class="cr-mod-more">
            <a @click="modelsExpanded = false">Collapse ↑</a>
          </div>
        </div>
```

- [ ] **Step 2: 添加 script 状态和计算属性**

```js
const modelsExpanded = ref(false)

const sortedModels = computed(() => {
  // 先尝试 store 的统一字段 modelStats（按 statsPeriod 自动切分的）
  const raw = apiStatsStore.modelStats || []
  return [...raw]
    .map(m => ({
      model: m.model || m.name || 'unknown',
      cost: Number(m.cost || m.totalCost || 0),
      allTokens: Number(m.allTokens || m.tokens || 0)
    }))
    .sort((a, b) => b.cost - a.cost)
})

const displayedModels = computed(() =>
  modelsExpanded.value ? sortedModels.value : sortedModels.value.slice(0, 5)
)
```

**验证字段名**：Run `grep -n "modelStats\|model: \|allTokens" web/admin-spa/src/stores/apistats.js web/admin-spa/src/components/apistats/ModelUsageStats.vue`，若实际字段名不同请替换。

- [ ] **Step 3: 样式**

```css
.cr-mod-row { grid-template-columns: 32px 1fr 110px 100px; gap: 14px; }
.cr-mod-row .cr-rank { font-size: 14px; color: var(--cr-text-ter); text-align: center; }
.cr-mod-row .cr-m { font-size: 14px; color: var(--cr-text); font-weight: 500; word-break: break-all; }
.cr-mod-row .cr-val { font-size: 14px; text-align: right; color: var(--cr-text); }
.cr-mod-row .cr-t { font-size: 13px; color: var(--cr-text-ter); text-align: right; }
.cr-mod-more { padding: 14px 22px; display: flex; justify-content: center; border-top: 1px solid var(--cr-border); }
.cr-mod-more a { font-size: 13px; color: var(--cr-coral); font-weight: 500; cursor: pointer; }
.cr-mod-more a:hover { color: var(--cr-coral-hover); text-decoration: underline; }
```

- [ ] **Step 4: 手动验证**

- 登录一个实际有数据的 key → Top models 显示排序后的模型列表（默认 5 条）
- `Expand all →` 点击后显示全部，按钮变 `Collapse ↑`
- period 切换时列表刷新（因为 modelStats 跟 period 联动）

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): top models 排行 block（默认 5 条 + 展开）"
```

---

### Task 11: Per-key breakdown（仅多 key 模式）

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 在 Top models 之后插入**

```vue
        <!-- Per-key breakdown (multi-key only) -->
        <template v-if="multiKeyMode && individualStats && individualStats.length">
          <div class="cr-sec-head">
            <h3 class="cr-serif">Per-key breakdown</h3>
            <span class="cr-sec-meta">{{ individualStats.length }} keys</span>
          </div>
          <div class="cr-card">
            <div v-for="(row, i) in perKeyRows" :key="row.id" class="cr-row cr-key-row">
              <span class="cr-rank cr-serif">{{ String(i + 1).padStart(2, '0') }}</span>
              <span class="cr-key-name">{{ row.name }}</span>
              <span class="cr-val cr-mono">{{ formatCurrency(row.cost) }}</span>
              <span class="cr-t cr-mono">{{ formatTokensShort(row.tokens) }} tok</span>
              <span class="cr-state" :class="row.stateClass">{{ row.stateLabel }}</span>
            </div>
          </div>
        </template>
```

- [ ] **Step 2: script 补充**

```js
const { individualStats } = storeToRefs(apiStatsStore)

const perKeyRows = computed(() => {
  if (!multiKeyMode.value || !individualStats.value) return []
  return individualStats.value.map(k => {
    const cost = Number(k?.usage?.[statsPeriod.value + 'Usage']?.cost
      ?? k?.cost
      ?? 0)
    const tokens = Number(k?.usage?.[statsPeriod.value + 'Usage']?.allTokens
      ?? k?.allTokens
      ?? 0)
    // 限额状态（取 cost limit 最严）
    const cl = k?.limits?.costLimit
    let stateClass = 'ok', stateLabel = 'OK'
    if (cl > 0) {
      const pct = (cost / cl) * 100
      if (pct >= 90) { stateClass = 'danger'; stateLabel = 'DANGER' }
      else if (pct >= 60) { stateClass = 'warn'; stateLabel = 'WARN' }
    }
    return {
      id: k.id || k.apiId || k.name,
      name: k.name || k.id || 'unnamed',
      cost,
      tokens,
      stateClass,
      stateLabel
    }
  }).sort((a, b) => b.cost - a.cost)
})
```

**字段验证**：运行 `grep -n "individualStats" web/admin-spa/src/stores/apistats.js` 确认实际 shape；按真实字段调整路径。

- [ ] **Step 3: 样式**

```css
.cr-key-row { grid-template-columns: 32px 1fr 110px 120px 80px; gap: 14px; }
.cr-key-row .cr-key-name { font-size: 14px; color: var(--cr-text); font-weight: 500; word-break: break-all; }
```

- [ ] **Step 4: 手动验证**

- 用逗号/换行分隔多个 key 登录 → 身份条 `N keys` 徽章出现
- 出现 `Per-key breakdown` 区块，每行显示：序号 / key 名 / 花费 / token / 限额状态
- 单 key 登录时此 block 不渲染

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): per-key breakdown（多 key 模式）"
```

---

### Task 12: 加载/错误态 + 通知弹窗 + 底部 footer

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`

- [ ] **Step 1: 在"统计主体"section 的 page-title 后、hero-row 前插入错误提示**

```vue
        <!-- Inline error -->
        <div v-if="error" class="cr-alert">
          <i class="fas fa-exclamation-triangle cr-alert-icon"></i>
          <span>{{ error }}</span>
        </div>

        <!-- Loading skeleton -->
        <div v-if="loading && !statsData" class="cr-card cr-loading">
          <div class="cr-skel cr-skel-hero"></div>
          <div class="cr-skel cr-skel-row"></div>
          <div class="cr-skel cr-skel-row"></div>
        </div>
```

然后把现有 hero / dual / models / per-key 用 `<template v-else>` 包起来（即 loading 时骨架占位，加载完后替换成真实内容）。

注意：period 切换的 `loading` 态不应整体骨架；只在"首次加载无 statsData"时显示骨架，切换时保留旧数据让 UI 不跳。所以条件是 `loading && !statsData`。

- [ ] **Step 2: 在"统计主体"section 底部追加 footer**

```vue
        <div class="cr-footer">
          <span><span class="cr-status-dot"></span>{{ error ? 'Issue detected' : 'All systems operational' }}</span>
          <span class="cr-mono" v-if="statsData?.updatedAt">Last sync {{ lastSyncText }}</span>
          <span class="cr-mono" v-if="appVersion">{{ appVersion }}</span>
        </div>
```

- [ ] **Step 3: 通知弹窗（复刻 Legacy 行为，换成 Claude 风卡片）**

在 `</section>` 之后（仍在 `.cr-page` 内）加：

```vue
    <!-- Notification modal (OEM apiStatsNotice) -->
    <Teleport to="body">
      <Transition name="fade">
        <div
          v-if="showNotice"
          class="cr-modal-overlay"
          @click.self="dismissNotice"
        >
          <div class="cr-card cr-modal" @click.stop>
            <div class="cr-modal-head">
              <div class="cr-modal-icon">
                <i class="fas fa-bell"></i>
              </div>
              <h3 class="cr-serif">{{ oemSettings.apiStatsNotice?.title || 'Notice' }}</h3>
            </div>
            <p class="cr-modal-body">{{ oemSettings.apiStatsNotice?.content }}</p>
            <label class="cr-modal-check">
              <input v-model="dontShowAgain" type="checkbox" />
              <span>Don't show again this session</span>
            </label>
            <button class="cr-btn-primary" @click="dismissNotice">Got it</button>
          </div>
        </div>
      </Transition>
    </Teleport>
```

- [ ] **Step 4: script 补充**

```js
const { error } = storeToRefs(apiStatsStore)

const appVersion = __APP_VERSION__ || ''  // 若 Vite 已注入；否则留空

const lastSyncText = computed(() => {
  const t = statsData.value?.updatedAt
  if (!t) return ''
  const sec = Math.round((Date.now() - new Date(t).getTime()) / 1000)
  if (sec < 60) return `${sec}s ago`
  if (sec < 3600) return `${Math.round(sec / 60)}m ago`
  return `${Math.round(sec / 3600)}h ago`
})

// notice modal
const showNotice = ref(false)
const dontShowAgain = ref(false)
const NOTICE_STORAGE_KEY = 'apiStatsNoticeRead'

function dismissNotice () {
  showNotice.value = false
  if (dontShowAgain.value) {
    try { sessionStorage.setItem(NOTICE_STORAGE_KEY, '1') } catch (e) { /* ignore */ }
  }
}

// 监听 OEM 加载 + apiId 就绪后决定是否展示通知
watch(
  () => [oemSettings.value?.apiStatsNotice?.enabled, apiId.value],
  ([enabled, id]) => {
    if (!enabled || !id) return
    try {
      if (sessionStorage.getItem(NOTICE_STORAGE_KEY) !== '1') {
        showNotice.value = true
      }
    } catch (e) { showNotice.value = true }
  }
)
```

确保 `watch` 从 `vue` import。

- [ ] **Step 5: 样式**

```css
.cr-alert { display: flex; align-items: center; gap: 10px; padding: 12px 16px; background: var(--cr-danger-soft); border: 1px solid var(--cr-danger); border-radius: 10px; color: var(--cr-danger); font-size: 14px; margin-bottom: 20px; }
.cr-alert-icon { font-size: 14px; }

.cr-loading { padding: 24px; }
.cr-skel { background: linear-gradient(90deg, var(--cr-surface-soft) 25%, var(--cr-border) 50%, var(--cr-surface-soft) 75%); background-size: 200% 100%; animation: crshimmer 1.4s infinite; border-radius: 8px; }
.cr-skel-hero { height: 80px; margin-bottom: 12px; }
.cr-skel-row { height: 32px; margin-bottom: 8px; }
@keyframes crshimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

.cr-footer { margin-top: 40px; padding-top: 24px; border-top: 1px solid var(--cr-border); font-size: 13px; color: var(--cr-text-ter); display: flex; justify-content: space-between; flex-wrap: wrap; gap: 10px; }

.cr-modal-overlay { position: fixed; inset: 0; background: rgba(43,36,32,.5); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 50; padding: 16px; }
.cr-modal { max-width: 440px; width: 100%; padding: 24px; }
.cr-modal-head { display: flex; align-items: center; gap: 12px; margin-bottom: 14px; }
.cr-modal-icon { width: 40px; height: 40px; border-radius: 10px; background: var(--cr-coral-soft); color: var(--cr-coral); display: flex; align-items: center; justify-content: center; }
.cr-modal-head h3 { font-size: 18px; font-weight: 500; color: var(--cr-text); }
.cr-modal-body { font-size: 14px; color: var(--cr-text-sec); white-space: pre-wrap; margin-bottom: 14px; }
.cr-modal-check { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--cr-text-sec); margin-bottom: 16px; cursor: pointer; }
.cr-btn-primary { width: 100%; padding: 10px 16px; background: var(--cr-coral); color: #fff; border: 0; border-radius: 8px; font-weight: 500; font-size: 14px; cursor: pointer; font-family: inherit; }
.cr-btn-primary:hover { background: var(--cr-coral-hover); }

.fade-enter-active, .fade-leave-active { transition: opacity .2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
```

- [ ] **Step 6: 手动验证**

- 输入无效 key → 顶部红色 inline alert 出现
- 首次输入有效 key → 短暂 shimmer 骨架（若网络慢）然后替换为真实内容
- period 切换时不出现骨架（保留旧数据即可）
- OEM 通知开启时，key 登录后弹窗出现；"Don't show again" 勾选 + Got it → 刷新不再弹
- footer 显示状态点 / last sync / 版本号

- [ ] **Step 7: Commit**

```bash
git add web/admin-spa/src/views/ApiStatsClaudeView.vue
git commit -m "feat(stats-redesign): 错误/加载态 + 通知弹窗 + footer"
```

---

### Task 13: `InsightsClaudeView.vue` — fun stats + 排行榜

**Files:**
- Modify: `web/admin-spa/src/views/InsightsClaudeView.vue`

- [ ] **Step 1: 阅读现有 Legacy 的数据流**

Run: `grep -n "funStats\|rank\|loadingRank\|usersData\|cacheKing\|topUser" web/admin-spa/src/views/InsightsLegacyView.vue | head -40`

理解 fun stats 4 块 + 主排行数据获取方式（API endpoint, store / local state）。记录相关变量与 action 名。

- [ ] **Step 2: 以原逻辑为蓝本，整体替换 InsightsClaudeView**

把文件内容替换为（数据逻辑按 Step 1 结果对齐，以下为模板骨架）：

```vue
<template>
  <div class="cr-theme min-h-screen" :class="{ dark: isDarkMode }">
    <div class="cr-page">

      <!-- 顶栏（结构与 ApiStatsClaudeView 一致） -->
      <nav class="cr-nav">
        <div class="cr-brand">
          <img
            v-if="oemSettings.siteIconData || oemSettings.siteIcon"
            :src="oemSettings.siteIconData || oemSettings.siteIcon"
            class="cr-logo-img"
            alt="logo"
          />
          <div v-else class="cr-logo-fallback cr-serif">
            {{ (oemSettings.siteName || 'R').charAt(0).toUpperCase() }}
          </div>
          <span class="cr-brand-text">
            {{ oemSettings.siteName || 'Claude Relay' }}
            <span class="cr-sep">·</span>
            <span class="cr-brand-sub">Insights</span>
          </span>
        </div>
        <div class="cr-nav-links">
          <router-link to="/api-stats" class="cr-nav-a">Stats</router-link>
          <ThemeToggle mode="dropdown" class="cr-theme-toggle" />
          <router-link
            v-if="oemSettings.showAdminButton !== false"
            to="/dashboard"
            class="cr-nav-a cr-nav-a-primary"
          >Admin</router-link>
        </div>
      </nav>

      <div class="cr-page-title">
        <h1 class="cr-serif">Insights & rankings</h1>
        <p>Top users, efficiency leaders, and aggregate spend across your organization.</p>
      </div>

      <!-- Fun stats row -->
      <div class="cr-fun-row">
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">{{ rangeLabel }} 卷王</div>
          <div class="cr-fun-name">{{ funStats.topUser?.name || '—' }}</div>
          <div class="cr-fun-meta cr-mono">${{ (funStats.topUser?.cost || 0).toFixed(2) }}</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">效率之星</div>
          <div class="cr-fun-name">{{ funStats.cacheKing?.name || '—' }}</div>
          <div class="cr-fun-meta">缓存率 {{ funStats.cacheKing?.rate || 0 }}%</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">Token 大户</div>
          <div class="cr-fun-name">{{ funStats.tokenKing?.name || '—' }}</div>
          <div class="cr-fun-meta cr-mono">{{ formatTokens(funStats.tokenKing?.tokens) }}</div>
        </div>
        <div class="cr-card cr-fun-card">
          <div class="cr-fun-label">{{ rangeLabel }} 总花费</div>
          <div class="cr-fun-name cr-serif cr-fun-big">${{ (funStats.todayCost || 0).toFixed(2) }}</div>
          <div class="cr-fun-meta">{{ (funStats.todayRequests || 0).toLocaleString() }} requests</div>
        </div>
      </div>

      <!-- Main rank list -->
      <div class="cr-sec-head">
        <h3 class="cr-serif">Top users</h3>
        <div class="cr-period">
          <button :class="{ active: rangeMode === 'daily' }" @click="changeRange('daily')">Today</button>
          <button :class="{ active: rangeMode === 'monthly' }" @click="changeRange('monthly')">Month</button>
          <button :class="{ active: rangeMode === 'alltime' }" @click="changeRange('alltime')">All time</button>
        </div>
      </div>
      <div v-if="loadingRank" class="cr-card cr-loading">
        <div class="cr-skel cr-skel-row"></div>
        <div class="cr-skel cr-skel-row"></div>
        <div class="cr-skel cr-skel-row"></div>
      </div>
      <div v-else-if="rankRows.length" class="cr-card">
        <div v-for="(row, i) in rankRows" :key="row.id" class="cr-row cr-rank-row">
          <span class="cr-rank-badge">
            <span v-if="i === 0">🥇</span>
            <span v-else-if="i === 1">🥈</span>
            <span v-else-if="i === 2">🥉</span>
            <span v-else class="cr-mono">{{ String(i + 1).padStart(2, '0') }}</span>
          </span>
          <span class="cr-rank-name">{{ row.name }}</span>
          <div class="cr-bar"><div :style="{ width: row.percent + '%' }"></div></div>
          <span class="cr-val cr-mono">${{ row.cost.toFixed(2) }}</span>
          <span class="cr-t cr-mono">{{ formatTokens(row.tokens) }}</span>
        </div>
      </div>
      <div v-else class="cr-card cr-empty">No data for this range.</div>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useThemeStore } from '@/stores/theme'
import ThemeToggle from '@/components/common/ThemeToggle.vue'
import '@/styles/claude-tokens.css'

// 数据获取逻辑从 InsightsLegacyView.vue 的 <script setup> 直接抄过来（仅改视图）
// 下方变量名若 Legacy 用的是别的（如 rangeMode -> timeRange），保持 Legacy 命名以减少 bug
// ---- BEGIN copied/adapted from InsightsLegacyView ----
const rangeMode = ref('daily')
const rangeLabel = computed(() => rangeMode.value === 'daily' ? '今日' : rangeMode.value === 'monthly' ? '本月' : '全部')
const loadingRank = ref(false)
const funStats = ref({
  topUser: null, cacheKing: null, tokenKing: null,
  todayCost: 0, todayRequests: 0
})
const rankRows = ref([])

async function loadData () {
  loadingRank.value = true
  try {
    // 调用与 Legacy 相同的接口（实际 API 名从 Legacy copy），把返回映射成 funStats + rankRows
    // TODO: 以 Legacy 真实逻辑为准 — 本模板假设有 getInsightsDataApi
    // const result = await getInsightsDataApi({ range: rangeMode.value })
    // funStats.value = result.funStats
    // rankRows.value = (result.users || []).map(u => ({
    //   id: u.id, name: u.name, cost: u.cost, tokens: u.tokens, percent: u.percent
    // }))
  } finally {
    loadingRank.value = false
  }
}

function changeRange (r) { rangeMode.value = r; loadData() }
function formatTokens (n) {
  n = Number(n) || 0
  if (n >= 1e6) return (n / 1e6).toFixed(1) + 'M'
  if (n >= 1e3) return (n / 1e3).toFixed(1) + 'K'
  return String(n)
}
// ---- END copied ----

const apiStatsStore = useApiStatsStore()
const themeStore = useThemeStore()
const { oemSettings } = storeToRefs(apiStatsStore)
const isDarkMode = computed(() => themeStore.isDarkMode)

onMounted(() => {
  apiStatsStore.loadOemSettings()
  loadData()
})
</script>

<style scoped>
/* 复用 Task 6-12 的 nav / page-title / footer / card / row / bar / state / period / skel 样式。
   将它们从 ApiStatsClaudeView.vue 拷贝到这里（因为是 scoped）。另外追加以下 fun-card 专用样式： */
.cr-fun-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 24px; }
@media (max-width: 900px) { .cr-fun-row { grid-template-columns: 1fr 1fr; } }
.cr-fun-card { padding: 18px 20px; }
.cr-fun-label { font-size: 12px; color: var(--cr-text-sec); font-weight: 500; letter-spacing: .02em; }
.cr-fun-name { font-size: 18px; color: var(--cr-text); font-weight: 600; margin-top: 4px; letter-spacing: -.01em; }
.cr-fun-name.cr-fun-big { font-size: 26px; font-weight: 500; letter-spacing: -.02em; }
.cr-fun-meta { font-size: 12px; color: var(--cr-text-ter); margin-top: 4px; }

.cr-rank-row { grid-template-columns: 48px 1fr 1fr 100px 90px; gap: 14px; }
.cr-rank-badge { font-size: 20px; text-align: center; color: var(--cr-text-ter); }
.cr-rank-name { font-size: 14px; color: var(--cr-text); font-weight: 500; }

/* 注意：若 Ops 上嫌 style 重复，可把共享 Claude-风样式提到一个 composable/.css 文件 */
</style>
```

- [ ] **Step 3: 共享样式处理**

两个 view 的 nav / page-title / card / row / bar / state / period / skel / footer 大段样式会重复。最简单策略：把 InsightsClaudeView.vue `<style scoped>` 起始处直接从 ApiStatsClaudeView.vue 的 scoped style 复制对应选择器（scoped 之间互不影响）。接受这一份冗余。如果将来第三个 Claude 风页面出现，再抽共享 CSS。

本 Task 不要回头改 ApiStatsClaudeView.vue 的 style。

- [ ] **Step 4: 手动验证**

- 访问 `/insights`（flag on）→ Claude 风顶栏 + H1
- 4 张 fun stats 卡片渲染；Loading 时骨架
- 排行榜：🥇🥈🥉 奖牌 emoji + 序号 04-N；percent bar 宽度正确
- time range 切换（Today/Month/All time）刷新数据

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src/views/InsightsClaudeView.vue
git commit -m "feat(stats-redesign): InsightsClaudeView 完成"
```

---

### Task 14: Dark mode 完整 pass + 响应式 QA

**Files:**
- Modify: `web/admin-spa/src/views/ApiStatsClaudeView.vue`（如需）
- Modify: `web/admin-spa/src/views/InsightsClaudeView.vue`（如需）
- Modify: `web/admin-spa/src/styles/claude-tokens.css` / `claude-shared.css`（如需）

- [ ] **Step 1: 浏览器切 Dark 模式逐屏核查**

Run: `cd web/admin-spa && npm run dev`
Browser: `/api-stats` + `/insights`，开 dark：

核对清单：
- 底色 / surface / 边框 都切到暖黑 variant
- Hero 大数字 / KPI 数字 / H1 在暗底上 contrast 足（WCAG AA：`#ECE6DA` on `#1F1B17` contrast ratio ≈ 14）
- Hero 右上软光晕 dark 版本低透明度（看不出明显圆）
- 状态 pill (ok/warn/danger) 软底在 dark 下仍可辨
- Period 激活态 `background: var(--cr-text)` 变成浅底 `#ECE6DA` 深字，检查是否反差刺眼（如刺眼，把 `.cr-period > button.active` 规则给 dark 单独定义 `--cr-surface` + `--cr-coral`）
- 通知 modal overlay dark 下仍能看到卡片轮廓

如发现对比度 / 刺眼问题，在 `claude-tokens.css` 中补充 dark 覆盖或在 scoped style 增加 `.cr-theme.dark` 特化 rule。

- [ ] **Step 2: 响应式逐断点核查**

DevTools 响应式工具依次设为：375 / 768 / 1024 / 1280 / 1440 / 1920 / 2560 px

核对清单：
- 375px：nav 可换行；toolbar 上下叠；hero 跨满；dual 单列；所有 row 不横溢
- 768px：hero 3 栏；dual 单列；toolbar 右侧下沉
- 1024px：padding 增大；hero 3 栏
- 1280px：dual 双列；所有 block 并排
- 1920+：padding 达 120px；内容居中观感；无无限拉伸行

- [ ] **Step 3: 针对发现的问题修复**

记录所有 UI bug，定位到 scoped style 修。修完再跑一次 Step 1-2 核对。

- [ ] **Step 4: flag off 回归**

关闭 `useClaudeStyleStats`，再次访问 `/api-stats` 和 `/insights` — 确保 Legacy 视图完全不受影响（无 css 泄漏到 Legacy 页面）。

- [ ] **Step 5: Commit**

```bash
git add web/admin-spa/src
git commit -m "fix(stats-redesign): 暗色模式与响应式 QA 修复"
```

---

### Task 15: Lint / 格式化 / 构建验证

**Files:**
- 所有改动的 Vue / CSS / JS 文件

- [ ] **Step 1: 后端 lint**

Run: `npm run lint`
Expected: 0 error

- [ ] **Step 2: 后端测试全跑**

Run: `npm test`
Expected: 所有绿（含 Task 1 新加的 3 个 oem 测试）

- [ ] **Step 3: Prettier 格式化新改动**

Run（Windows bash）:
```bash
npx prettier --write \
  src/routes/admin/system.js \
  tests/oemSettingsUseClaudeStyle.test.js \
  web/admin-spa/src/views/ApiStatsView.vue \
  web/admin-spa/src/views/ApiStatsLegacyView.vue \
  web/admin-spa/src/views/ApiStatsClaudeView.vue \
  web/admin-spa/src/views/InsightsView.vue \
  web/admin-spa/src/views/InsightsLegacyView.vue \
  web/admin-spa/src/views/InsightsClaudeView.vue \
  web/admin-spa/src/views/SettingsView.vue \
  web/admin-spa/src/styles/claude-tokens.css
```

Expected: 无报错；文件被格式化（若有变化需要再次 add + commit）。

- [ ] **Step 4: 前端构建**

Run: `npm run build:web`
Expected: Vite 成功产出 `web/admin-spa/dist`；无 Vue 模板编译错误、无 CSS 警告。

- [ ] **Step 5: Commit 格式化改动（若有）**

```bash
git add -A
git status  # 确认没有意外文件
git diff --cached --stat
git commit -m "chore(stats-redesign): prettier 格式化 + lint 修复"
```

---

### Task 16: 文档 & 最终发布准备

**Files:**
- Modify: `CHANGELOG.md`（若项目有）
- Modify: `docs/superpowers/plans/2026-04-18-api-stats-redesign.md`（本文件；在末尾补一个 "Completed" 章节）

- [ ] **Step 1: CHANGELOG（若存在）追加条目**

Run: `ls CHANGELOG.md 2>/dev/null`
若存在则追加：

```markdown
## [Unreleased]

### Added
- `/api-stats` 和 `/insights` 新增 Claude.ai 风视图（通过 OEM 开关 `useClaudeStyleStats` 启用，默认关闭）
```

若不存在 CHANGELOG.md 则跳过此步。

- [ ] **Step 2: 在 plan 文件末尾加完成标记**

在 `docs/superpowers/plans/2026-04-18-api-stats-redesign.md` 末尾追加：

```markdown
---

## Completed

- Implemented on: YYYY-MM-DD
- Merged on: YYYY-MM-DD
- Known follow-ups: （此处记录任何未做的边界或后续优化）
```

- [ ] **Step 3: 最终 end-to-end 手动 QA**

全程演练：
1. 开关 off → `/api-stats` 和 `/insights` 行为与改版前完全一致
2. 开关 on → Claude 风生效；登录 / period 切换 / 多 key / tutorial / 通知 / 暗色全部 OK
3. 开关反复切换 → 无 js 报错、无样式残留

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md docs/superpowers/plans/2026-04-18-api-stats-redesign.md
git commit -m "docs(stats-redesign): 标记 plan 完成并更新 changelog"
```

---

## Self-Review（作者内部核对，不计入 task）

Spec 覆盖：
- §3 设计令牌 → Task 5
- §4 信息架构 → Task 6-12
- §5 组件改动清单 → Task 3-4 (Shell) + 6-13 (new views)
- §6 feature flag → Task 1-2
- §7 响应式 → Task 14
- §8 边界情况 → Task 12 + 11 (multi-key) + 6 (empty state)
- §9 dark mode → Task 5 (tokens) + 14 (QA)
- §10 图标/emoji → Task 6 (FA 保留) + 13 (🥇🥈🥉)
- §11 迁移策略 → Task 16 (follow-up 记录)
- §12 验收标准 → Task 15 + 16

占位符扫描：Task 9/10/11 中"字段验证"要求 grep 对齐真实字段名（这是有意保留的 on-the-fly 验证，不是 placeholder）。

类型一致性：`oemSettings.useClaudeStyleStats`、`currentPeriodData.cost` 等命名在所有 task 中保持一致。CSS 变量 `--cr-*` 前缀统一。
