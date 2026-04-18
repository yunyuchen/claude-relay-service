import { watch, onMounted, onUnmounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useThemeStore } from '@/stores/theme'

// Claude 风视图激活时接管 body/html 的背景，避免 Legacy 紫色渐变和
// body::before 径向光晕透过来造成色调不协调。
// 在 ApiStatsClaudeView / InsightsClaudeView 的 setup 中调用即可。
export function useClaudeBodyTheme() {
  const themeStore = useThemeStore()
  const { isDarkMode } = storeToRefs(themeStore)

  const LIGHT_BG = '#FAF9F5'
  const DARK_BG = '#1F1B17'

  function apply() {
    document.body.classList.add('cr-claude-body')
    document.body.style.setProperty(
      'background',
      isDarkMode.value ? DARK_BG : LIGHT_BG,
      'important'
    )
    document.body.style.setProperty('background-attachment', 'fixed', 'important')
  }

  function restore() {
    document.body.classList.remove('cr-claude-body')
    document.body.style.removeProperty('background')
    document.body.style.removeProperty('background-attachment')
  }

  onMounted(apply)
  onUnmounted(restore)
  watch(isDarkMode, apply)
}
