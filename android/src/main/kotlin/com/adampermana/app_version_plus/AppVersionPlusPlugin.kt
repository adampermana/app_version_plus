package com.adampermana.app_version_plus

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

private const val CHANNEL = "app_version_plus/in_app_update"
private const val REQUEST_CODE_UPDATE = 8743

class AppVersionPlusPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var appUpdateManager: AppUpdateManager? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Pending result for update flow
    private var pendingResult: Result? = null

    // Listener for flexible update install state
    private var installStateListener: InstallStateUpdatedListener? = null

    // ── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        unregisterInstallListener()
    }

    // ── ActivityAware ────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        appUpdateManager = AppUpdateManagerFactory.create(binding.activity)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        unregisterInstallListener()
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
        appUpdateManager = null
    }

    // ── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkUpdateAvailability" -> checkUpdateAvailability(result)
            "startImmediateUpdate" -> startUpdate(AppUpdateType.IMMEDIATE, result)
            "startFlexibleUpdate" -> startUpdate(AppUpdateType.FLEXIBLE, result)
            "completeFlexibleUpdate" -> completeFlexibleUpdate(result)
            else -> result.notImplemented()
        }
    }

    // ── Handlers ─────────────────────────────────────────────────────────────

    private fun checkUpdateAvailability(result: Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.error("UNAVAILABLE", "AppUpdateManager not initialized", null)
            return
        }

        manager.appUpdateInfo.addOnSuccessListener { info ->
            result.success(
                mapOf(
                    "updateAvailability" to info.updateAvailability(),
                    "availableVersionCode" to info.availableVersionCode(),
                    "isImmediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                    "isFlexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                )
            )
        }.addOnFailureListener { e ->
            result.error("CHECK_FAILED", e.message, null)
        }
    }

    private fun startUpdate(updateType: Int, result: Result) {
        val manager = appUpdateManager
        val currentActivity = activity

        if (manager == null || currentActivity == null) {
            result.error("UNAVAILABLE", "AppUpdateManager or Activity not initialized", null)
            return
        }

        // Store pending result to resolve after onActivityResult
        pendingResult = result

        manager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE
                && info.updateAvailability() != UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
            ) {
                pendingResult?.success("UPDATE_NOT_AVAILABLE")
                pendingResult = null
                return@addOnSuccessListener
            }

            if (!info.isUpdateTypeAllowed(updateType)) {
                pendingResult?.success("UPDATE_TYPE_NOT_ALLOWED")
                pendingResult = null
                return@addOnSuccessListener
            }

            if (updateType == AppUpdateType.FLEXIBLE) {
                registerInstallListener(manager, result)
            }

            try {
                manager.startUpdateFlowForResult(
                    info,
                    currentActivity,
                    AppUpdateOptions.newBuilder(updateType).build(),
                    REQUEST_CODE_UPDATE,
                )
            } catch (e: Exception) {
                pendingResult?.error("START_FAILED", e.message, null)
                pendingResult = null
                if (updateType == AppUpdateType.FLEXIBLE) {
                    unregisterInstallListener()
                }
            }
        }.addOnFailureListener { e ->
            pendingResult?.error("CHECK_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun completeFlexibleUpdate(result: Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.error("UNAVAILABLE", "AppUpdateManager not initialized", null)
            return
        }
        manager.completeUpdate()
            .addOnSuccessListener { result.success("COMPLETE_SUCCESS") }
            .addOnFailureListener { e -> result.error("COMPLETE_FAILED", e.message, null) }
    }

    // ── Install State Listener (Flexible) ────────────────────────────────────

    private fun registerInstallListener(manager: AppUpdateManager, result: Result) {
        unregisterInstallListener()

        val listener = InstallStateUpdatedListener { state ->
            when (state.installStatus()) {
                InstallStatus.DOWNLOADED -> {
                    // Notify Flutter that download is complete; Flutter decides when to call completeFlexibleUpdate
                    channel.invokeMethod("onFlexibleUpdateDownloaded", null)
                }
                InstallStatus.FAILED -> {
                    result.error("INSTALL_FAILED", "Install failed with error: ${state.installErrorCode()}", null)
                    unregisterInstallListener()
                }
                InstallStatus.CANCELED -> {
                    result.success("INSTALL_CANCELED")
                    unregisterInstallListener()
                }
                else -> { /* installing / pending — ignore */ }
            }
        }

        manager.registerListener(listener)
        installStateListener = listener
    }

    private fun unregisterInstallListener() {
        val listener = installStateListener ?: return
        appUpdateManager?.unregisterListener(listener)
        installStateListener = null
    }

    // ── ActivityResultListener ───────────────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_UPDATE) return false

        when (resultCode) {
            Activity.RESULT_OK -> pendingResult?.success("UPDATE_ACCEPTED")
            Activity.RESULT_CANCELED -> pendingResult?.success("UPDATE_CANCELED")
            else -> pendingResult?.error("UPDATE_FAILED", "Activity result: $resultCode", null)
        }

        pendingResult = null
        return true
    }
}
