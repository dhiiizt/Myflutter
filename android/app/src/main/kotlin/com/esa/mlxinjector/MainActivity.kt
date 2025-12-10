package com.esa.mlxinjector

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import rikka.shizuku.Shizuku.OnRequestPermissionResultListener
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Semaphore
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap
import android.util.Log

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.esa.mlxinjector/native"
    private var savedTreeUri: String? = null
    private val TREE_REQUEST_CODE = 1234
    private var pendingResult: MethodChannel.Result? = null

    // === Tambahan untuk Shizuku ===
    private var shizukuPermissionResult: MethodChannel.Result? = null
    private val shizukuPermissionListener =
        OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode == 1000) {
                Handler(Looper.getMainLooper()).post {
                    shizukuPermissionResult?.success(grantResult == PackageManager.PERMISSION_GRANTED)
                    shizukuPermissionResult = null
                }
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = getSharedPreferences("saf_prefs", Context.MODE_PRIVATE)
        savedTreeUri = prefs.getString("tree_uri", null)

        // Daftarkan listener Shizuku
        Shizuku.addRequestPermissionResultListener(shizukuPermissionListener)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("package") ?: ""
                    result.success(isAppInstalled(packageName))
                }

                "openDocumentTreeForPackage" -> {
                    val packageName = call.argument<String>("package") ?: ""
                    openDocumentTree(packageName, result)
                }

                "getSavedTreeUri" -> result.success(savedTreeUri)

                "clearSavedTreeUri" -> {
                    prefs.edit().remove("tree_uri").apply()
                    savedTreeUri = null
                    result.success(null)
                }

                // === Shizuku bridge ===
                "isShizukuAvailable" -> result.success(isShizukuAvailable())
                "hasShizukuPermission" -> result.success(hasShizukuPermission())
                "requestShizukuPermission" -> requestShizukuPermission(result)
                "execShizukuCommand" -> {
                    val cmd = call.argument<String>("cmd") ?: "id"
                    val resultText = execShizukuCommand(cmd)
                    result.success(resultText)
                }
                "copyDirectoryToSAF1" -> {
                    val sourceDir = call.argument<String>("sourceDir")
                    val treeUriStr = call.argument<String>("treeUri")
                
                    if (sourceDir == null || treeUriStr == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                
                    GlobalScope.launch(Dispatchers.IO) {
                        var success = false
                        try {
                            val treeUri = Uri.parse(treeUriStr)
                            val targetTree = DocumentFile.fromTreeUri(this@MainActivity, treeUri)
                            if (targetTree != null && targetTree.canWrite()) {
           
                                copyFilesDrone(File(sourceDir), targetTree, this@MainActivity)
                                success = true
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    }
                }

                // === Copy folder via SAF ===
                "copyDirectoryToSAF" -> {
                    val sourceDir = call.argument<String>("sourceDir")
                    val treeUriStr = call.argument<String>("treeUri")
                
                    if (sourceDir == null || treeUriStr == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                
                    GlobalScope.launch(Dispatchers.IO) {
                        var success = false
                        try {
                            val treeUri = Uri.parse(treeUriStr)
                            val targetTree = DocumentFile.fromTreeUri(this@MainActivity, treeUri)
                            if (targetTree != null && targetTree.canWrite()) {
           
                                copyFilesOnly(File(sourceDir), targetTree, this@MainActivity)
                                success = true
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                
                        withContext(Dispatchers.Main) {
                            result.success(success)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // ==========================================================
    // =============== Bagian Shizuku Permission =================
    // ==========================================================

    private fun isShizukuAvailable(): Boolean {
        return try {
            Shizuku.pingBinder()
        } catch (e: Exception) {
            false
        }
    }

    private fun hasShizukuPermission(): Boolean {
        return Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    }

    private fun requestShizukuPermission(result: MethodChannel.Result) {
        if (!isShizukuAvailable()) {
            result.error("UNAVAILABLE", "Shizuku service not running", null)
            return
        }

        if (hasShizukuPermission()) {
            result.success(true)
            return
        }

        shizukuPermissionResult = result
        Handler(Looper.getMainLooper()).post {
            try {
                Shizuku.requestPermission(1000)
            } catch (e: Exception) {
                result.error("REQUEST_FAILED", e.message, null)
            }
        }
    }

    // ==========================================================
    // =============== Eksekusi Command via Shizuku ==============
    // ==========================================================
    private fun execShizukuCommand(cmd: String): String {
        return try {
            val clazz = Class.forName("rikka.shizuku.Shizuku")
            val method = clazz.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java,
                Array<String>::class.java,
                String::class.java
            )
            method.isAccessible = true

            val process = method.invoke(
                null,
                arrayOf("sh", "-c", cmd),
                null,
                null
            ) as Process

            val output = process.inputStream.bufferedReader().readText()
            val error = process.errorStream.bufferedReader().readText()

            if (error.isNotEmpty()) error else output
        } catch (e: Exception) {
            e.printStackTrace()
            "Error: ${e.message}"
        }
    }

    // ==========================================================
    // =============== Copy folder dengan SAF ===================
    // ==========================================================
private suspend fun copyFilesOnly(source: File, targetTree: DocumentFile, context: Context) {
    runBlocking {
        val maxParallel = 6
        val sem = Semaphore(maxParallel)
        val scope = CoroutineScope(Dispatchers.IO)

        // 🔹 Buat folder dragon2017/assets di dalam targetTree
        val dragonFolder = targetTree.findFile("dragon2017") ?: targetTree.createDirectory("dragon2017")
        val assetsFolder = dragonFolder?.findFile("assets") ?: dragonFolder?.createDirectory("assets")

        if (assetsFolder == null) {
            Log.e("CopyFilesOnly", "Gagal membuat folder dragon2017/assets")
            return@runBlocking
        }

        // Folder tujuan utama kita sekarang
        val realTargetTree = assetsFolder

        // 🔹 Cache folder yang sudah ditemukan
        val folderCache = ConcurrentHashMap<String, DocumentFile>().apply {
            put("", realTargetTree)
        }

        // 🔹 Ambil semua file yang akan disalin
        val allFiles = source.walkTopDown().filter { it.isFile }.toList()
        val totalBytesAllFiles = allFiles.sumOf { it.length() }.toDouble().coerceAtLeast(1.0)
        var totalWritten = 0L

        // 🔹 Fungsi untuk memastikan folder target sudah ada
        suspend fun ensureFolder(path: String): DocumentFile? {
            folderCache[path]?.let { return it }
            if (path.isEmpty()) return realTargetTree

            val parts = path.split(File.separator)
            var currentDir: DocumentFile? = realTargetTree
            var currentPath = ""

            for (part in parts) {
                currentPath = if (currentPath.isEmpty()) part else "$currentPath/$part"
                if (folderCache.containsKey(currentPath)) {
                    currentDir = folderCache[currentPath]
                    continue
                }

                // Cari folder, buat kalau belum ada
                var found = currentDir?.findFile(part)
                if (found == null || !found.isDirectory) {
                    found = currentDir?.createDirectory(part)
                }

                if (found == null) return null

                folderCache[currentPath] = found
                currentDir = found
            }

            return currentDir
        }

        // 🔹 Fungsi untuk menyalin 1 file
        suspend fun copyFile(srcFile: File) {
            sem.acquire()
            try {
                val relPath = srcFile.relativeTo(source).parent ?: ""
                val targetSubDir = ensureFolder(relPath) ?: return

                val safeName = sanitizeFileName(srcFile.name)
                targetSubDir.findFile(safeName)?.delete() // hapus jika sudah ada

                val destFile = targetSubDir.createFile("application/octet-stream", safeName) ?: return

                FileInputStream(srcFile).use { input ->
                    context.contentResolver.openOutputStream(destFile.uri, "w")?.use { output ->
                        val buf = ByteArray(64 * 1024)
                        var read: Int
                        while (input.read(buf).also { read = it } != -1) {
                            output.write(buf, 0, read)
                            totalWritten += read
                            val progress = (totalWritten / totalBytesAllFiles).coerceIn(0.0, 1.0)

                            Handler(Looper.getMainLooper()).post {
                                MethodChannel(
                                    flutterEngine!!.dartExecutor.binaryMessenger,
                                    "com.esa.mlxinjector/native"
                                ).invokeMethod("onMoveProgress", progress)
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                sem.release()
            }
        }

        // 🔹 Jalankan semua copy file paralel
        try {
            allFiles.map { srcFile -> scope.async { copyFile(srcFile) } }.awaitAll()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            scope.cancel()
            Handler(Looper.getMainLooper()).post {
                MethodChannel(
                    flutterEngine!!.dartExecutor.binaryMessenger,
                    "com.esa.mlxinjector/native"
                ).invokeMethod("onMoveProgress", 1.0)
            }
        }
    }
}

private fun sanitizeFileName(name: String): String {
    return name.replace(Regex("[\\\\/:*?\"<>|]"), "_")
}

private suspend fun copyFilesDrone(source: File, targetTree: DocumentFile, context: Context) {
    runBlocking {
        val maxParallel = 6 // sesuaikan dengan kemampuan HP
        val sem = Semaphore(maxParallel)
        val scope = CoroutineScope(Dispatchers.IO)

        // 🔹 1️⃣ Hitung semua file
        val allFiles = source.walkTopDown().filter { it.isFile }.toList()
        val totalBytesAllFiles = allFiles.sumOf { it.length() }.toDouble().coerceAtLeast(1.0)
        var totalWritten = 0L

        suspend fun copyDirRec(srcDir: File, dstDir: DocumentFile) {
            if (!dstDir.isDirectory) return

            // 📋 Cache semua file & folder di level ini
            val existingFiles = dstDir.listFiles()
                .associateBy { it.name ?: "" }

            // 🔁 Copy semua file di folder ini (paralel)
            val files = srcDir.listFiles()?.filter { it.isFile } ?: emptyList()
            val jobs = mutableListOf<Deferred<Unit>>()

            for (file in files) {
                val job = scope.async {
                    sem.acquire()
                    try {
                        val safeName = sanitizeFileName(file.name ?: "unnamed")
                        existingFiles[safeName]?.delete()
                        val destFile = dstDir.createFile("application/octet-stream", safeName)
                            ?: return@async

                        FileInputStream(file).use { input ->
                            context.contentResolver.openOutputStream(destFile.uri, "w")?.use { output ->
                                val buf = ByteArray(64 * 1024)
                                var read: Int
                                while (input.read(buf).also { read = it } != -1) {
                                    output.write(buf, 0, read)

                                    // 🔹 Update total written global
                                    totalWritten += read
                                    val overallProgress =
                                        (totalWritten / totalBytesAllFiles).coerceIn(0.0, 1.0)

                                    // 🔹 Kirim progress ke Flutter
                                    Handler(Looper.getMainLooper()).post {
                                        MethodChannel(
                                            flutterEngine!!.dartExecutor.binaryMessenger,
                                            "com.esa.mlxinjector/native"
                                        ).invokeMethod("onMoveProgress", overallProgress)
                                    }
                                }
                            }
                        }
                    } finally {
                        sem.release()
                    }
                }
                jobs.add(job)
            }

            jobs.awaitAll()

            // 📁 Rekursi ke subfolder
            val subDirs = srcDir.listFiles()?.filter { it.isDirectory } ?: emptyList()
            for (folder in subDirs) {
                val safeName = sanitizeFileName(folder.name ?: "unnamed")
                val subTarget = existingFiles[safeName]?.takeIf { it.isDirectory }
                    ?: dstDir.createDirectory(safeName) ?: continue
                copyDirRec(folder, subTarget)
            }
        }

        try {
            copyDirRec(source, targetTree)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            scope.cancel()
            // pastikan progress terakhir 100%
            Handler(Looper.getMainLooper()).post {
                MethodChannel(
                    flutterEngine!!.dartExecutor.binaryMessenger,
                    "com.esa.mlxinjector/native"
                ).invokeMethod("onMoveProgress", 1.0)
            }
        }
    }
}

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    // ==========================================================
    // =============== SAF Open Document Tree ===================
    // ==========================================================
    private fun openDocumentTree(packageName: String, result: MethodChannel.Result) {
        pendingResult = result

        val zwj = "%E2%81%A0"
        val baseUri =
            "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fdat$zwj" +
                    "a/document/primary%3AAndroid%2Fdat$zwj" +
                    "a%2F"

        val initialUri = Uri.parse(baseUri + Uri.encode(packageName) + "%2Ffiles%2F")

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.putExtra("android.provider.extra.INITIAL_URI", initialUri)
        intent.addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
        )

        startActivityForResult(intent, TREE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == TREE_REQUEST_CODE) {
            val resultUri: String? = if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                if (
                        isValidMLTreeUri(uri, "com.mobile.legends") ||
                        isValidMLTreeUri(uri, "com.mobiin.gp") ||
                        isValidMLTreeUri(uri, "com.vng.mlbbvn") ||
                        isValidMLTreeUri(uri, "com.mobile.legends.usa") ||
                        isValidMLTreeUri(uri, "com.mobilelegends.mi") ||
                        isValidMLTreeUri(uri, "com.mobile.legends.hwag")
                    ) {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                    savedTreeUri = uri.toString()
                    getSharedPreferences("saf_prefs", Context.MODE_PRIVATE)
                        .edit().putString("tree_uri", savedTreeUri).apply()
                    savedTreeUri
                } else null
            } else null

            pendingResult?.success(resultUri)
            pendingResult = null
        }
    }

    companion object {
        fun isValidMLTreeUri(uri: Uri, targetPkg: String): Boolean {
            return try {
                var docId = DocumentsContract.getTreeDocumentId(uri) ?: return false
                docId = docId.replace("\u2060", "").trim()
                val expected = "primary:Android/data/$targetPkg/files"
                docId == expected || docId == "$expected/"
            } catch (e: Exception) {
                false
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Shizuku.removeRequestPermissionResultListener(shizukuPermissionListener)
    }
}