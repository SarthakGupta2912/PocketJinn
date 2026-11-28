// What is this file for?
// Keeps one Flutter engine alive for the whole app process. The activity can be
// destroyed when the user swipes the app away, but the engine (and the wake
// detector inside it) keeps running while the microphone service is alive.
package com.Sarthak.pocket_jinn

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

/// Holds the one Flutter engine shared by the activity and the service.
object PocketJinnEngine {
    private var engine: FlutterEngine? = null

    /// Returns the shared engine, creating and starting it on first use.
    fun get(context: Context): FlutterEngine {
        engine?.let { return it }
        val created = FlutterEngine(context.applicationContext)
        GeneratedPluginRegistrant.registerWith(created)
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        engine = created
        return created
    }
}
