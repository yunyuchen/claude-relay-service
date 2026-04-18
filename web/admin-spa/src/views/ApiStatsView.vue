<template>
  <component :is="ActiveView" v-if="oemReady" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const LegacyView = defineAsyncComponent(() => import('./ApiStatsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./ApiStatsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

// OEM 加载完成后才决定渲染哪个视图，避免 flag=true 用户先看到 Legacy 再切 Claude 的闪烁
const oemReady = computed(() => !!oemSettings.value?.updatedAt)

const ActiveView = computed(() =>
  oemSettings.value?.useClaudeStyleStats === true ? ClaudeView : LegacyView
)

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
