import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../src/rust/dto/stream.dart';
import 'payload_poller.dart';
import 'plan_guard.dart';

class WebViewStreamRunner {
  const WebViewStreamRunner({
    this.timeout = const Duration(seconds: 25),
    this.interval = const Duration(milliseconds: 350),
  });

  final Duration timeout;
  final Duration interval;

  Future<String> collectPayload(StreamPlanDto plan) async {
    final page = checkedPlanUrl(url: plan.url, allowedHost: plan.allowedHost);
    InAppWebViewController? controller;
    final headless = HeadlessInAppWebView(
      initialSize: const Size(1, 1),
      initialUrlRequest: URLRequest(
        url: WebUri.uri(page),
        headers: plan.referer.isEmpty ? null : {'Referer': plan.referer},
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      ),
      onWebViewCreated: (created) => controller = created,
      shouldOverrideUrlLoading: (_, action) async {
        final target = action.request.url?.uriValue;
        final allowed =
            target != null &&
            navigationAllowed(target: target, allowedHost: plan.allowedHost);
        return allowed
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
    );
    await headless.run();
    try {
      return await pollForPayload(
        evaluate: () async =>
            controller?.evaluateJavascript(source: plan.script),
        timeout: timeout,
        interval: interval,
      );
    } finally {
      await headless.dispose();
    }
  }
}
