package com.example.ai_checker

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Accessibility service that monitors user interaction in other applications.
 * Specifically detects focus on text input fields (EditText / TextInput) and
 * broadcasts events to Flutter via MethodChannel / BroadcastReceiver.
 */
class GrammarAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "GrammarA11yService"
        const val ACTION_TEXT_FOCUSED = "com.example.ai_checker.TEXT_FOCUSED"
        const val EXTRA_FOCUSED = "extra_focused"
        const val EXTRA_TEXT = "extra_text"
        const val EXTRA_PACKAGE = "extra_package"

        var isServiceRunning = false
            private set
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        Log.d(TAG, "GrammarAccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val eventType = event.eventType
        val packageName = event.packageName?.toString() ?: ""

        // Avoid self-monitoring to prevent infinite feedback loops
        if (packageName == applicationContext.packageName) {
            return
        }

        when (eventType) {
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                val source: AccessibilityNodeInfo? = event.source
                if (source != null && isEditableField(source)) {
                    val currentText = source.text?.toString() ?: ""
                    notifyTextFocused(isFocused = true, text = currentText, packageName = packageName)
                }
            }
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                val source: AccessibilityNodeInfo? = event.source
                if (source != null && isEditableField(source)) {
                    val currentText = source.text?.toString() ?: ""
                    notifyTextFocused(isFocused = true, text = currentText, packageName = packageName)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Window changed or closed
                val rootNode: AccessibilityNodeInfo? = rootInActiveWindow
                val focusedNode = rootNode?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                val isFocused = focusedNode != null && isEditableField(focusedNode)
                val text = focusedNode?.text?.toString() ?: ""
                notifyTextFocused(isFocused = isFocused, text = text, packageName = packageName)
            }
        }
    }

    private fun isEditableField(node: AccessibilityNodeInfo): Boolean {
        return node.isEditable || 
               node.className?.toString()?.contains("EditText", ignoreCase = true) == true
    }

    private fun notifyTextFocused(isFocused: Boolean, text: String, packageName: String) {
        val intent = Intent(ACTION_TEXT_FOCUSED).apply {
            setPackage(applicationContext.packageName)
            putExtra(EXTRA_FOCUSED, isFocused)
            putExtra(EXTRA_TEXT, text)
            putExtra(EXTRA_PACKAGE, packageName)
        }
        sendBroadcast(intent)
        MainActivity.sendTextEventToFlutter(isFocused, text, packageName)
    }

    override fun onInterrupt() {
        Log.w(TAG, "GrammarAccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        Log.d(TAG, "GrammarAccessibilityService destroyed")
    }
}
