package com.englishstudy.app.service

import android.util.Log
import com.englishstudy.app.model.Transcript
import com.englishstudy.app.model.TranscriptSegment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import java.util.regex.Pattern

class TranscriptService {
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
    
    companion object {
        private const val TAG = "TranscriptService"
    }
    
    suspend fun getTranscript(videoId: String): Transcript? = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Fetching transcript for video: $videoId using youtube-transcript-api approach")
            
            // 使用类似youtube-transcript-api的方法
            return@withContext fetchTranscriptViaInnerTubeAPI(videoId)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching transcript: ${e.message}", e)
            return@withContext null
        }
    }
    
    private suspend fun fetchTranscriptViaInnerTubeAPI(videoId: String): Transcript? = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Step 1: Fetching video HTML to extract InnerTube API key")
            
            // 步骤1：获取视频页面HTML
            val videoUrl = "https://www.youtube.com/watch?v=$videoId"
            val htmlRequest = Request.Builder()
                .url(videoUrl)
                .addHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36")
                .addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                .addHeader("Accept-Language", "en-US,en;q=0.9")
                .build()
            
            val htmlResponse = client.newCall(htmlRequest).execute()
            if (!htmlResponse.isSuccessful) {
                Log.w(TAG, "Failed to fetch video HTML: ${htmlResponse.code}")
                return@withContext null
            }
            
            val html = htmlResponse.body?.string() ?: return@withContext null
            Log.d(TAG, "Fetched video HTML, length: ${html.length}")
            
            // 步骤2：提取InnerTube API key
            val apiKey = extractInnerTubeApiKey(html)
            if (apiKey == null) {
                Log.w(TAG, "Could not extract InnerTube API key from HTML")
                return@withContext null
            }
            
            Log.d(TAG, "Step 2: Extracted InnerTube API key: $apiKey")
            
            // 步骤3：调用InnerTube API获取字幕数据
            val innerTubeData = fetchInnerTubeData(videoId, apiKey)
            if (innerTubeData == null) {
                Log.w(TAG, "Failed to fetch InnerTube data")
                return@withContext null
            }
            
            Log.d(TAG, "Step 3: Got InnerTube data, parsing captions...")
            
            // 步骤4：解析字幕数据
            return@withContext parseInnerTubeCaptionsData(innerTubeData)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in fetchTranscriptViaInnerTubeAPI: ${e.message}", e)
            return@withContext null
        }
    }
    
    private fun extractInnerTubeApiKey(html: String): String? {
        try {
            // 查找InnerTube API key的多种模式
            val patterns = listOf(
                "\"innertubeApiKey\"\\s*:\\s*\"([^\"]+)\"",
                "\"INNERTUBE_API_KEY\"\\s*:\\s*\"([^\"]+)\"",
                "innertubeApiKey\"\\s*:\\s*\"([^\"]+)\"",
                "INNERTUBE_API_KEY\"\\s*:\\s*\"([^\"]+)\""
            )
            
            for (pattern in patterns) {
                val regex = Pattern.compile(pattern)
                val matcher = regex.matcher(html)
                if (matcher.find()) {
                    val apiKey = matcher.group(1)
                    if (apiKey?.isNotBlank() == true) {
                        Log.d(TAG, "Found API key with pattern: $pattern")
                        return apiKey
                    }
                }
            }
            
            Log.w(TAG, "No InnerTube API key found in HTML")
            return null
            
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting API key: ${e.message}", e)
            return null
        }
    }
    
    private suspend fun fetchInnerTubeData(videoId: String, apiKey: String): String? = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Calling InnerTube API with key: $apiKey")
            
            // 构建InnerTube API请求 - 使用youtube-transcript-api的格式
            val requestBody = """{
                "context": {
                    "client": {
                        "clientName": "ANDROID",
                        "clientVersion": "20.10.38"
                    }
                },
                "videoId": "$videoId"
            }"""
            
            val request = Request.Builder()
                .url("https://www.youtube.com/youtubei/v1/player?key=$apiKey")
                .post(requestBody.toRequestBody("application/json".toMediaType()))
                .addHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36")
                .addHeader("Accept", "*/*")
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept-Language", "en-US,en;q=0.9")
                .build()
            
            val response = client.newCall(request).execute()
            Log.d(TAG, "InnerTube API response code: ${response.code}")
            
            if (!response.isSuccessful) {
                val errorBody = response.body?.string()
                Log.w(TAG, "InnerTube API failed: ${response.code} - $errorBody")
                return@withContext null
            }
            
            val responseBody = response.body?.string() ?: return@withContext null
            Log.d(TAG, "InnerTube API response length: ${responseBody.length}")
            Log.d(TAG, "Response preview: ${responseBody.take(300)}...")
            
            return@withContext responseBody
            
        } catch (e: Exception) {
            Log.e(TAG, "Error calling InnerTube API: ${e.message}", e)
            return@withContext null
        }
    }
    
    private fun parseInnerTubeCaptionsData(jsonData: String): Transcript? {
        try {
            val jsonObject = JSONObject(jsonData)
            
            // 打印响应长度以调试（避免日志过长）
            Log.d(TAG, "Parsing API response length: ${jsonData.length}")
            
            // 解析Player API响应中的字幕轨道信息
            val captions = jsonObject.optJSONObject("captions")
            if (captions == null) {
                Log.w(TAG, "No captions object found in player response")
                // 打印所有顶级键以了解响应结构
                val keys = jsonObject.keys()
                val keysList = mutableListOf<String>()
                while (keys.hasNext()) {
                    keysList.add(keys.next())
                }
                Log.d(TAG, "Available top-level keys: ${keysList.joinToString(", ")}")
                return null
            }
            
            Log.d(TAG, "Found captions object: $captions")
            
            val playerCaptionsRenderer = captions.optJSONObject("playerCaptionsTracklistRenderer")
            if (playerCaptionsRenderer == null) {
                Log.w(TAG, "No playerCaptionsTracklistRenderer found")
                // 打印captions对象的所有键
                val captionKeys = captions.keys()
                val captionKeysList = mutableListOf<String>()
                while (captionKeys.hasNext()) {
                    captionKeysList.add(captionKeys.next())
                }
                Log.d(TAG, "Available caption keys: ${captionKeysList.joinToString(", ")}")
                return null
            }
            
            val captionTracks = playerCaptionsRenderer.optJSONArray("captionTracks")
            if (captionTracks == null) {
                Log.w(TAG, "No captionTracks found")
                return null
            }
            
            Log.d(TAG, "Found ${captionTracks.length()} caption tracks")
            
            // 查找英文字幕轨道
            for (i in 0 until captionTracks.length()) {
                val track = captionTracks.getJSONObject(i)
                val languageCode = track.optString("languageCode", "")
                val baseUrl = track.optString("baseUrl", "")
                
                Log.d(TAG, "Caption track $i: language=$languageCode, hasUrl=${baseUrl.isNotEmpty()}")
                
                if (languageCode.startsWith("en") && baseUrl.isNotEmpty()) {
                    Log.d(TAG, "Found English caption track, fetching transcript from: $baseUrl")
                    return runBlocking { fetchAndParseTranscriptXml(baseUrl) }
                }
            }
            
            Log.w(TAG, "No English caption tracks found")
            return null
            
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing player API response: ${e.message}", e)
            return null
        }
    }
    
    private suspend fun fetchAndParseTranscriptXml(url: String): Transcript? = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Fetching transcript XML from: $url")
            
            val request = Request.Builder()
                .url(url)
                .addHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36")
                .build()
            
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) {
                Log.e(TAG, "Failed to fetch transcript XML: ${response.code}")
                return@withContext null
            }
            
            val xml = response.body?.string() ?: return@withContext null
            Log.d(TAG, "Downloaded transcript XML, length: ${xml.length}")
            
            return@withContext parseTranscriptXml(xml)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching transcript XML: ${e.message}", e)
            return@withContext null
        }
    }
    
    private fun parseTranscriptXml(xml: String): Transcript? {
        try {
            val segments = mutableListOf<TranscriptSegment>()
            
            Log.d(TAG, "Parsing XML format, first 500 chars: ${xml.take(500)}")
            
            // 解析srv3格式的XML字幕 - 使用<p>标签
            val paragraphPattern = Pattern.compile(
                "<p t=\"([^\"]+)\" d=\"([^\"]+)\"[^>]*>(.*?)</p>",
                Pattern.CASE_INSENSITIVE or Pattern.DOTALL
            )
            val paragraphMatcher = paragraphPattern.matcher(xml)
            
            while (paragraphMatcher.find()) {
                try {
                    val startTimeMs = paragraphMatcher.group(1)?.toLongOrNull() ?: continue
                    val durationMs = paragraphMatcher.group(2)?.toLongOrNull() ?: continue
                    val content = paragraphMatcher.group(3) ?: continue
                    
                    // 转换毫秒到秒
                    val startTime = startTimeMs / 1000.0f
                    val duration = durationMs / 1000.0f
                    
                    // 提取<s>标签中的文本
                    val textBuilder = StringBuilder()
                    val sPattern = Pattern.compile("<s[^>]*>([^<]*)</s>", Pattern.CASE_INSENSITIVE)
                    val sMatcher = sPattern.matcher(content)
                    
                    while (sMatcher.find()) {
                        val sText = sMatcher.group(1) ?: ""
                        textBuilder.append(sText)
                    }
                    
                    var text = textBuilder.toString()
                    
                    // 清理文本
                    text = text
                        .replace("&amp;", "&")
                        .replace("&lt;", "<")
                        .replace("&gt;", ">")
                        .replace("&quot;", "\"")
                        .replace("&#39;", "'")
                        .replace("&apos;", "'")
                        .replace("\\s+".toRegex(), " ")
                        .trim()
                    
                    if (text.isNotBlank()) {
                        segments.add(TranscriptSegment(startTime, duration, text))
                        Log.d(TAG, "Parsed segment: ${String.format("%.2f", startTime)}s - '$text'")
                    }
                    
                } catch (e: Exception) {
                    Log.w(TAG, "Error parsing paragraph: ${e.message}")
                    continue
                }
            }
            
            return if (segments.isNotEmpty()) {
                Log.d(TAG, "Successfully parsed ${segments.size} transcript segments from srv3 XML")
                Transcript("English", "en", segments.sortedBy { it.startTime })
            } else {
                Log.w(TAG, "No transcript segments found in srv3 XML")
                null
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing transcript XML: ${e.message}", e)
            return null
        }
    }
}