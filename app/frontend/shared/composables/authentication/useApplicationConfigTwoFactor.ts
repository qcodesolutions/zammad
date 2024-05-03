// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'

const { twoFactorMethods } = useTwoFactorPlugins()

export const useApplicationConfigTwoFactor = () => {
  const application = useApplicationStore()

  const { config } = storeToRefs(application)

  const twoFactorEnabledMethods = computed(() =>
    twoFactorMethods.filter(
      (method) =>
        config.value[`two_factor_authentication_method_${method.name}`],
    ),
  )

  const hasEnabledMethods = computed(() =>
    Boolean(twoFactorEnabledMethods.value.length),
  )

  const hasEnabledRecoveryCodes = computed(
    () => config.value.two_factor_authentication_recovery_codes,
  )

  return {
    hasEnabledMethods,
    hasEnabledRecoveryCodes,
    twoFactorEnabledMethods,
  }
}