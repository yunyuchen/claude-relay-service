<template>
  <form class="cr-ak" @submit.prevent="queryStats">
    <div class="cr-ak-tabs">
      <button
        class="cr-ak-tab"
        :class="{ active: !multiKeyMode }"
        type="button"
        @click="multiKeyMode = false"
      >
        Single key
      </button>
      <button
        class="cr-ak-tab"
        :class="{ active: multiKeyMode }"
        type="button"
        @click="multiKeyMode = true"
      >
        Aggregate
        <span v-if="multiKeyMode && parsedApiKeys.length > 0" class="cr-ak-count">
          {{ parsedApiKeys.length }}
        </span>
      </button>
    </div>

    <div v-if="!multiKeyMode" class="cr-ak-field">
      <input
        v-model="apiKey"
        autocomplete="off"
        class="cr-ak-input"
        :disabled="loading"
        placeholder="cr_..."
        :type="showPassword ? 'text' : 'password'"
        @keyup.enter="queryStats"
      />
      <button
        :aria-label="showPassword ? 'Hide' : 'Show'"
        class="cr-ak-eye"
        type="button"
        @click="showPassword = !showPassword"
      >
        <i :class="showPassword ? 'fas fa-eye-slash' : 'fas fa-eye'"></i>
      </button>
    </div>
    <div v-else class="cr-ak-field">
      <textarea
        v-model="apiKey"
        class="cr-ak-textarea"
        :disabled="loading"
        placeholder="cr_xxx&#10;cr_yyy&#10;or cr_xxx, cr_yyy"
        rows="4"
        @keyup.ctrl.enter="queryStats"
      />
      <button
        v-if="apiKey && !loading"
        aria-label="Clear"
        class="cr-ak-clear"
        type="button"
        @click="clearInput"
      >
        <i class="fas fa-times-circle"></i>
      </button>
    </div>

    <button class="cr-ak-submit" :disabled="loading || !hasValidInput" type="submit">
      <i v-if="loading" class="fas fa-spinner cr-ak-spin"></i>
      {{ loading ? 'Loading…' : 'View stats' }}
    </button>

    <p class="cr-ak-note">
      <i class="fas fa-shield-alt"></i>
      {{
        multiKeyMode
          ? 'Aggregate mode reads your keys for display only; they are not stored. Up to 30 keys.'
          : 'Your API key is used only to view your own usage. It is not stored.'
      }}
    </p>
  </form>
</template>

<script setup>
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useApiStatsStore } from '@/stores/apistats'

const apiStatsStore = useApiStatsStore()
const { apiKey, loading, multiKeyMode } = storeToRefs(apiStatsStore)
const { queryStats, clearInput } = apiStatsStore

const showPassword = ref(false)

const parsedApiKeys = computed(() => {
  if (!multiKeyMode.value || !apiKey.value) return []
  const keys = apiKey.value
    .split(/[,\n]+/)
    .map((k) => k.trim())
    .filter((k) => k.length > 0)
  return [...new Set(keys)].slice(0, 30)
})

const hasValidInput = computed(() => {
  if (multiKeyMode.value) return parsedApiKeys.value.length > 0
  return apiKey.value && apiKey.value.trim().length > 0
})
</script>

<style scoped>
.cr-ak {
  display: flex;
  flex-direction: column;
  gap: 14px;
  text-align: left;
}

.cr-ak-tabs {
  display: inline-flex;
  align-self: center;
  background: var(--cr-surface-soft);
  border: 1px solid var(--cr-border);
  border-radius: 999px;
  padding: 3px;
}
.cr-ak-tab {
  font-family: inherit;
  font-size: 12px;
  font-weight: 500;
  padding: 6px 14px;
  border: 0;
  background: transparent;
  border-radius: 999px;
  cursor: pointer;
  color: var(--cr-text-sec);
  transition: all 0.15s;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.cr-ak-tab:hover:not(.active) {
  color: var(--cr-text);
}
.cr-ak-tab.active {
  background: var(--cr-text);
  color: var(--cr-bg);
}
.cr-ak-count {
  background: var(--cr-bg);
  color: var(--cr-text);
  border-radius: 999px;
  padding: 0 6px;
  font-size: 11px;
}

.cr-ak-field {
  position: relative;
}
.cr-ak-input,
.cr-ak-textarea {
  width: 100%;
  font-family: var(--cr-mono);
  font-size: 14px;
  padding: 12px 14px;
  background: var(--cr-surface);
  border: 1px solid var(--cr-border);
  border-radius: 10px;
  color: var(--cr-text);
  outline: none;
  transition:
    border-color 0.15s,
    box-shadow 0.15s;
  box-sizing: border-box;
}
.cr-ak-textarea {
  resize: vertical;
  min-height: 96px;
  font-family: var(--cr-mono);
}
.cr-ak-input::placeholder,
.cr-ak-textarea::placeholder {
  color: var(--cr-text-ter);
}
.cr-ak-input:focus,
.cr-ak-textarea:focus {
  border-color: var(--cr-coral);
  box-shadow: 0 0 0 3px var(--cr-coral-soft);
}
.cr-ak-input:disabled,
.cr-ak-textarea:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.cr-ak-input {
  padding-right: 42px;
}
.cr-ak-eye,
.cr-ak-clear {
  position: absolute;
  top: 50%;
  right: 10px;
  transform: translateY(-50%);
  background: transparent;
  border: 0;
  color: var(--cr-text-ter);
  cursor: pointer;
  padding: 4px 6px;
  font-size: 14px;
}
.cr-ak-clear {
  top: 10px;
  transform: none;
}
.cr-ak-eye:hover,
.cr-ak-clear:hover {
  color: var(--cr-text);
}

.cr-ak-submit {
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
  padding: 11px 16px;
  background: var(--cr-coral);
  color: #fff;
  border: 0;
  border-radius: 10px;
  cursor: pointer;
  transition:
    background 0.15s,
    opacity 0.15s;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.cr-ak-submit:hover:not(:disabled) {
  background: var(--cr-coral-hover);
}
.cr-ak-submit:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.cr-ak-spin {
  animation: cr-ak-spin 0.8s linear infinite;
}
@keyframes cr-ak-spin {
  from {
    transform: rotate(0);
  }
  to {
    transform: rotate(360deg);
  }
}

.cr-ak-note {
  font-size: 12px;
  color: var(--cr-text-ter);
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  line-height: 1.5;
}
.cr-ak-note i {
  color: var(--cr-ok);
}
</style>
