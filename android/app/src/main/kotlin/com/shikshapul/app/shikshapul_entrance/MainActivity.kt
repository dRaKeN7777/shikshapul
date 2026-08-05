package com.shikshapul.app.shikshapul_entrance

import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val modelChannel = "com.shikshapul.app/model_assets"
    private val extractionExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, modelChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "prepareModel") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                extractionExecutor.execute {
                    try {
                        val assetPath = call.argument<String>("assetPath")
                            ?: error("assetPath is required")
                        val expectedSha = call.argument<String>("sha256")
                            ?: error("sha256 is required")
                        result.success(prepareModel(assetPath, expectedSha))
                    } catch (error: Exception) {
                        result.error("MODEL_EXTRACTION_FAILED", error.message, null)
                    }
                }
            }
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
        val assetKey = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset(assetPath)
        assets.open(assetKey).use { input ->
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
