package com.logicbuilder8.shikshapulprep

import android.app.ActivityManager
import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val modelChannel = "com.shikshapul.app/model_assets"
    private val bundledModelAsset = "models/qwen-0.5b-q3_k_m.gguf"
    private val extractionExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        if (BuildConfig.FLAVOR == "full") {
            super.configureFlutterEngine(flutterEngine)
        } else {
            // The optional llama plugin is ARM64-only and loads native code
            // during registration. Never register it in Lite: Samsung phones
            // must reach Flutter even when their OS is 32-bit or memory-starved.
            registerLitePlugins(flutterEngine)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, modelChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "deviceCapacity") {
                    result.success(deviceCapacity())
                    return@setMethodCallHandler
                }
                if (call.method == "prepareModel") {
                    extractionExecutor.execute {
                        try {
                            val assetPath = call.argument<String>("assetPath")
                                ?: error("assetPath is required")
                            val expectedSha = call.argument<String>("sha256")
                                ?: error("sha256 is required")
                            val modelPath = prepareModel(assetPath, expectedSha)
                            runOnUiThread { result.success(modelPath) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error(
                                    "MODEL_EXTRACTION_FAILED",
                                    error.message,
                                    null,
                                )
                            }
                        }
                    }
                    return@setMethodCallHandler
                }
                result.notImplemented()
            }
    }

    private fun registerLitePlugins(flutterEngine: FlutterEngine) {
        val plugins = flutterEngine.plugins
        val registrations = listOf<() -> Unit>(
            { plugins.add(dev.fluttercommunity.plus.connectivity.ConnectivityPlugin()) },
            { plugins.add(dev.fluttercommunity.plus.share.SharePlusPlugin()) },
            { plugins.add(com.tekartik.sqflite.SqflitePlugin()) },
            { plugins.add(io.flutter.plugins.urllauncher.UrlLauncherPlugin()) },
        )
        registrations.forEach { register ->
            try {
                register()
            } catch (error: Throwable) {
                // One optional integration must never take down exam practice.
                Log.e("ShikshaPul", "Optional Lite plugin unavailable", error)
            }
        }
    }

    private fun deviceCapacity(): Map<String, Any> {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(memory)
        return mapOf(
            "availableBytes" to memory.availMem,
            "totalBytes" to memory.totalMem,
            "lowMemory" to memory.lowMemory,
            "lowRamDevice" to manager.isLowRamDevice,
            "memoryClassMb" to manager.memoryClass,
            "modelBundled" to isModelBundled(),
        )
    }

    private fun isModelBundled(): Boolean = try {
        assets.open(bundledModelAsset).use { }
        true
    } catch (_: Exception) {
        false
    }

    override fun onDestroy() {
        extractionExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun prepareModel(assetPath: String, expectedSha: String): String {
        val modelDir = File(filesDir, "models").apply { mkdirs() }
        val target = File(modelDir, File(assetPath).name)
        if (target.exists() && sha256(target).equals(expectedSha, ignoreCase = true)) {
            return target.absolutePath
        }

        val partial = File(modelDir, "${target.name}.part")
        if (partial.exists()) partial.delete()
        openModelAsset(assetPath).use { input ->
            partial.outputStream().buffered().use { output -> input.copyTo(output) }
        }
        if (!sha256(partial).equals(expectedSha, ignoreCase = true)) {
            partial.delete()
            error("Bundled model checksum does not match the manifest")
        }
        if (target.exists()) target.delete()
        check(partial.renameTo(target)) { "Could not finalize extracted model" }
        return target.absolutePath
    }

    private fun openModelAsset(assetPath: String): InputStream {
        val flutterKey = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset(assetPath)
        return try {
            assets.open(flutterKey)
        } catch (_: Exception) {
            // Full-AI flavor stores the model outside Flutter's asset bundle.
            assets.open("models/${File(assetPath).name}")
        }
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).buffered().use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") {
            "%02x".format(it.toInt() and 0xff)
        }
    }
}
