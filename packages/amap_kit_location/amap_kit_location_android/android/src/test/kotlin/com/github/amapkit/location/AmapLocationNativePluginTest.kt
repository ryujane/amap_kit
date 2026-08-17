package com.github.amapkit.location

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

internal class AmapLocationNativePluginTest {
  @Test
  fun generatedErrorCodesRemainStable() {
    assertEquals(
      NativeLocationErrorCode.PRIVACY_NOT_CONFIGURED,
      NativeLocationErrorCode.ofRaw(0),
    )
    assertEquals(
      NativeLocationErrorCode.CLIENT_NOT_FOUND,
      NativeLocationErrorCode.ofRaw(11),
    )
  }

  @Test
  fun repeatedAcceptedPrivacyStatusIsIdempotentAfterClientCreation() {
    val plugin = pluginWithAcceptedPrivacyAndExistingClient()

    plugin.setPrivacyStatus(acceptedPrivacyStatus())
  }

  @Test
  fun changedPrivacyStatusIsRejectedAfterClientCreation() {
    val plugin = pluginWithAcceptedPrivacyAndExistingClient()

    val error =
      assertFailsWith<FlutterError> {
        plugin.setPrivacyStatus(
          NativePrivacyStatus(
            privacyNoticeShown = true,
            containsAmapPrivacyPolicy = true,
            userAgreed = false,
          ),
        )
      }

    assertEquals("operation_in_progress", error.code)
  }

  @Test
  fun repeatedApiKeyIsIdempotentAfterClientCreation() {
    val plugin = AmapLocationNativePlugin()
    setField(plugin, "configuredApiKey", "test-api-key")
    setField(plugin, "hasCreatedClient", true)

    plugin.setApiKey("  test-api-key  ")
  }

  @Test
  fun changedApiKeyIsRejectedAfterClientCreation() {
    val plugin = AmapLocationNativePlugin()
    setField(plugin, "configuredApiKey", "test-api-key")
    setField(plugin, "hasCreatedClient", true)

    val error =
      assertFailsWith<FlutterError> {
        plugin.setApiKey("different-api-key")
      }

    assertEquals("operation_in_progress", error.code)
  }

  @Test
  fun stoppedClientCanSetLocationOption() {
    ensureLocationOptionCanBeSet(started = false, oneShotPending = false)
  }

  @Test
  fun startedClientCannotSetLocationOption() {
    val error =
      assertFailsWith<FlutterError> {
        ensureLocationOptionCanBeSet(started = true, oneShotPending = false)
      }

    assertEquals("operation_in_progress", error.code)
  }

  @Test
  fun clientWithPendingOneShotCannotSetLocationOption() {
    val error =
      assertFailsWith<FlutterError> {
        ensureLocationOptionCanBeSet(started = false, oneShotPending = true)
      }

    assertEquals("operation_in_progress", error.code)
  }

  private fun pluginWithAcceptedPrivacyAndExistingClient(): AmapLocationNativePlugin {
    val plugin = AmapLocationNativePlugin()
    setField(plugin, "privacyConfigured", true)
    setField(plugin, "configuredPrivacyStatus", acceptedPrivacyStatus())
    @Suppress("UNCHECKED_CAST")
    val clients = field(plugin, "clients") as MutableMap<Long, Any>
    clients[1L] = Any()
    return plugin
  }

  private fun acceptedPrivacyStatus() =
    NativePrivacyStatus(
      privacyNoticeShown = true,
      containsAmapPrivacyPolicy = true,
      userAgreed = true,
    )

  private fun setField(
    target: Any,
    name: String,
    value: Any,
  ) {
    target.javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(target, value)
    }
  }

  private fun field(
    target: Any,
    name: String,
  ): Any? =
    target.javaClass.getDeclaredField(name).let {
      it.isAccessible = true
      it.get(target)
    }
}
