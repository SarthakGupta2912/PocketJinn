// What is this file for?
// Wraps Android's SpeechRecognizer in offline mode and the debug broadcast so
// the Flutter speech engine does not need to know any Android API details.
package com.Sarthak.pocket_jinn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.MediaPlayer
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel

/// Runs offline Android speech recognition and reports results to Dart.
class AndroidSpeechBridge(
    private val activity: android.app.Activity,
    private val channel: MethodChannel,
    private val debugChannel: MethodChannel,
) {
    private var recognizer: SpeechRecognizer? = null
    private var debugReceiver: BroadcastReceiver? = null

    /// True when the device has a speech recognition service.
    fun isAvailable(): Boolean = SpeechRecognizer.isRecognitionAvailable(activity)

    /// Starts listening, preferring offline recognition on the device.
    fun start(languageCode: String) {
        stop()
        recognizer = SpeechRecognizer.createSpeechRecognizer(activity)
        recognizer?.setRecognitionListener(buildListener())
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
        )
        intent.putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
        if (languageCode.isNotBlank()) {
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageCode)
        }
        recognizer?.startListening(intent)
    }

    /// Asks Android to finish the current recording.
    fun stop() {
        recognizer?.stopListening()
    }

    /// Registers the DEBUG_COMMAND broadcast used by adb tests.
    fun registerDebugReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val text = intent.getStringExtra("text")
                val audioPath = intent.getStringExtra("audio_path")
                val name = intent.getStringExtra("name")
                val playPath = intent.getStringExtra("play_path")
                when {
                    !playPath.isNullOrBlank() -> playTestAudio(playPath)
                    !audioPath.isNullOrBlank() ->
                        debugChannel.invokeMethod(
                            "onDebugAudioFile",
                            mapOf("path" to audioPath),
                        )
                    !text.isNullOrBlank() ->
                        debugChannel.invokeMethod(
                            "onDebugCommand",
                            mapOf("text" to text),
                        )
                    !name.isNullOrBlank() ->
                        debugChannel.invokeMethod(
                            "onDebugName",
                            mapOf("name" to name),
                        )
                }
            }
        }
        val filter = IntentFilter("${activity.packageName}.DEBUG_COMMAND")
        ContextCompat.registerReceiver(
            activity,
            receiver,
            filter,
            ContextCompat.RECEIVER_EXPORTED,
        )
        debugReceiver = receiver
    }

    /// Plays a pushed WAV through the tablet speaker for mic-path testing.
    private fun playTestAudio(path: String) {
        try {
            val player = MediaPlayer()
            player.setDataSource(path)
            player.prepare()
            player.start()
            Log.d("PocketJinnDebug", "play start")
            player.setOnCompletionListener { it.release() }
        } catch (error: Exception) {
            debugChannel.invokeMethod(
                "onDebugError",
                mapOf("message" to (error.message ?: "Playback failed")),
            )
        }
    }

    /// Releases the recognizer and the debug receiver.
    fun dispose() {
        stop()
        recognizer?.destroy()
        recognizer = null
        debugReceiver?.let { activity.unregisterReceiver(it) }
        debugReceiver = null
    }

    /// Builds the callback that sends recognition events back to Dart.
    private fun buildListener(): RecognitionListener =
        object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}

            override fun onEndOfSpeech() {
                channel.invokeMethod("onSpeechEnd", null)
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull().orEmpty()
                channel.invokeMethod("onSpeechResult", mapOf("text" to text))
            }

            override fun onError(error: Int) {
                channel.invokeMethod("onSpeechError", mapOf("code" to error))
            }
        }
}
