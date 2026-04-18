import { watch, onMounted, onUnmounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore } from '@/stores/theme'

// Claude 风视图激活时同时接管 html 与 body 的背景，避免：
// 1) Legacy `body { linear-gradient(--bg-gradient-start...) }` 透过来
// 2) `body::before` 径向光晕
// 3) html 自身透明、露出 Element Plus `html.dark { color-scheme: dark }` 触发的浏览器默认灰底
// 在 ApiStatsClaudeView / InsightsClaudeView 的 setup 中调用即可。
export function useClaudeBodyTheme() {
  const themeStore = useThemeStore()
  const { isDarkMode } = storeToRefs(themeStore)

  const LIGHT_BG = '#FAF9F5'
  const DARK_BG = '#221812'

  function apply() {
    const bg = isDarkMode.value ? DARK_BG : LIGHT_BG
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

  onMounted(apply)
  onUnmounted(restore)
  watch(isDarkMode, apply)
}
