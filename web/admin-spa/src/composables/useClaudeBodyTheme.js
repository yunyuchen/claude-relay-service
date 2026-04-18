import { watch, onUnmounted, unref } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore } from '@/stores/theme'

// Claude 风视图激活时同时接管 html 与 body 的背景，避免：
// 1) Legacy `body { linear-gradient(--bg-gradient-start...) }` 透过来
// 2) `body::before` 径向光晕
// 3) html 自身透明、露出 Element Plus `html.dark { color-scheme: dark }` 触发的浏览器默认灰底
//
// 用法：
//   useClaudeBodyTheme()                              // 无条件 apply
//   useClaudeBodyTheme({ enabled: isClaudeModeRef })  // 根据 ref 条件化
//
// 实现说明：
//   - setup 阶段立即同步 apply/restore 一次，不等 onMounted，避免首帧闪烁
//   - isDarkMode 直接从 localStorage + media query 读取，不依赖 themeStore.initTheme
//     （initTheme 在 App.vue onMounted 里调，比子组件 setup 晚）
//   - enabled 默认 true；若 OEM 尚未加载时调用方传入 undefined 态 ref，按 true 处理
const LIGHT_BG = '#FAF9F5'
const DARK_BG = '#221812'

function detectDarkSync() {
  try {
    const saved = localStorage.getItem('themeMode')
    if (saved === 'dark') return true
    if (saved === 'light') return false
  } catch (_) {
    // localStorage 不可用时走 media query
  }
  return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
}

export function useClaudeBodyTheme(options = {}) {
  const themeStore = useThemeStore()
  const { isDarkMode } = storeToRefs(themeStore)

  function apply() {
    // themeStore 未 init 时，isDarkMode 可能还没反映真实状态，退回同步检测
    const dark = isDarkMode.value || detectDarkSync()
    const bg = dark ? DARK_BG : LIGHT_BG
    document.body.classList.add('cr-claude-body')
    document.documentElement.classList.add('cr-claude-root')
    for (const el of [document.documentElement, document.body]) {
      el.style.setProperty('background', bg, 'important')
      el.style.setProperty('background-image', 'none', 'important')
      el.style.setProperty('background-attachment', 'fixed', 'important')
    }
  }

  function restore() {
    document.body.classList.remove('cr-claude-body')
    document.documentElement.classList.remove('cr-claude-root')
    for (const el of [document.documentElement, document.body]) {
      el.style.removeProperty('background')
      el.style.removeProperty('background-image')
      el.style.removeProperty('background-attachment')
    }
  }

  function sync() {
    if (unref(options.enabled) === false) restore()
    else apply()
  }

  // setup 阶段立即执行一次（document.body / documentElement 已存在）
  sync()

  onUnmounted(restore)
  watch(isDarkMode, sync)
  if (options.enabled !== undefined) {
    watch(() => unref(options.enabled), sync)
  }
}
