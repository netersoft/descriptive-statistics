package com.neteru.tixtat

import com.google.android.play.core.review.ReviewManagerFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Play in-app review, called by ReviewService. Answers true once the
        // review flow has run (Google never says whether the sheet was shown),
        // false when it couldn't start (no Play Store, not installed from Play...).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.neteru.tixtat/review").setMethodCallHandler { call, result ->
            if (call.method != "requestReview") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val manager = ReviewManagerFactory.create(this)
            manager.requestReviewFlow().addOnCompleteListener { request ->
                if (!request.isSuccessful) {
                    result.success(false)
                    return@addOnCompleteListener
                }
                manager.launchReviewFlow(this, request.result).addOnCompleteListener { result.success(true) }
            }
        }
    }
}
