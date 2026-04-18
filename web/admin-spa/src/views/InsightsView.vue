<template>
  <component :is="ActiveView" />
</template>

<script setup>
import { computed, defineAsyncComponent, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'
import { useClaudeBodyTheme } from '@/composables/useClaudeBodyTheme'

const LegacyView = defineAsyncComponent(() => import('./InsightsLegacyView.vue'))
const ClaudeView = defineAsyncComponent(() => import('./InsightsClaudeView.vue'))

const apiStatsStore = useApiStatsStore()
const { oemSettings } = storeToRefs(apiStatsStore)

const isClaudeMode = computed(() => oemSettings.value?.useClaudeStyleStats === true)

const ActiveView = computed(() => (isClaudeMode.value ? ClaudeView : LegacyView))

useClaudeBodyTheme({ enabled: isClaudeMode })

onMounted(() => {
  if (!oemSettings.value?.updatedAt) {
    apiStatsStore.loadOemSettings()
  }
})
</script>
