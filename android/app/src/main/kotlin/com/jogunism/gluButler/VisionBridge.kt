package com.jogunism.gluButler

import android.graphics.BitmapFactory
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VisionBridge(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "VisionBridge"
        private val FOOD_KEYWORDS = setOf(
            "food", "meal", "dish", "cuisine", "plate",
            "pizza", "burger", "sandwich", "salad", "soup",
            "pasta", "rice", "noodle", "bread", "cake",
            "fruit", "vegetable", "meat", "fish", "chicken",
            "dessert", "snack", "breakfast", "lunch", "dinner",
            "coffee", "tea", "drink", "beverage",
            "sushi", "ramen", "curry", "steak", "taco",
            "bakery", "baked goods", "fast food", "seafood",
            "produce", "ingredient", "condiment", "spice",
        )
    }

    private val channel = MethodChannel(messenger, "vision_analysis")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "analyzeFoodPhoto" -> analyzeFoodPhoto(call, result)
            "extractMetadata" -> result.success(emptyMap<String, Any>())
            else -> result.notImplemented()
        }
    }

    private fun analyzeFoodPhoto(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: run {
            result.error("INVALID_ARGS", "File path required", null)
            return
        }

        val bitmap = try {
            BitmapFactory.decodeFile(filePath)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decode image: $filePath", e)
            null
        }

        if (bitmap == null) {
            result.error("INVALID_IMAGE", "Could not load image", null)
            return
        }

        val image = InputImage.fromBitmap(bitmap, 0)
        val labeler = ImageLabeling.getClient(
            ImageLabelerOptions.Builder()
                .setConfidenceThreshold(0.5f)
                .build()
        )

        labeler.process(image)
            .addOnSuccessListener { labels ->
                val foodItems = mutableListOf<String>()
                var maxConfidence = 0.0
                var isFood = false

                for (label in labels.take(10)) {
                    val text = label.text.lowercase()
                    for (keyword in FOOD_KEYWORDS) {
                        if (text.contains(keyword)) {
                            isFood = true
                            foodItems.add(label.text)
                            maxConfidence = maxOf(maxConfidence, label.confidence.toDouble())
                            break
                        }
                    }
                }

                Log.d(TAG, "Food analysis - isFood: $isFood, items: $foodItems, confidence: $maxConfidence")
                result.success(mapOf(
                    "isFood" to isFood,
                    "foodItems" to foodItems,
                    "confidence" to maxConfidence,
                ))
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Image labeling failed", e)
                result.success(mapOf(
                    "isFood" to false,
                    "foodItems" to emptyList<String>(),
                    "confidence" to 0.0,
                ))
            }
    }
}
