<template>
  <button
    :aria-label="isDarkMode ? '切换为浅色模式' : '切换为深色模式'"
    class="cr-theme-btn"
    :title="isDarkMode ? '切换为浅色模式' : '切换为深色模式'"
    type="button"
    @click="toggle"
  >
    <i v-if="isDarkMode" class="fas fa-sun"></i>
    <i v-else class="fas fa-moon"></i>
  </button>
</template>

<script setup>
import { computed } from 'vue'
import { useThemeStore, ThemeMode } from '@/stores/theme'

const themeStore = useThemeStore()
const isDarkMode = computed(() => themeStore.isDarkMode)

function toggle() {
  themeStore.setThemeMode(isDarkMode.value ? ThemeMode.LIGHT : ThemeMode.DARK)
}
</script>

<style scoped>
.cr-theme-btn {
  width: 34px;
  height: 34px;
  border-radius: 999px;
  border: 1px solid var(--cr-border);
  background: var(--cr-surface);
  color: var(--cr-text-sec);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-family: inherit;
  font-size: 14px;
  transition: all 0.15s;
  padding: 0;
}
.cr-theme-btn:hover {
  color: var(--cr-text);
  border-color: var(--cr-border-strong);
  background: var(--cr-surface-soft);
}
</style>
