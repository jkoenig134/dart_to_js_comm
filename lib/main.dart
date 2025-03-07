import 'dart:convert';
import 'dart:io';

import 'package:dart_to_js_comm/event_bus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MainApp());
}

const _htmlContent = """<!DOCTYPE html><html><head><meta http-equiv="Content-Security-Policy"
  content="default-src 'self' http://localhost:* http://*.enmeshed.eu https://*.enmeshed.eu https://firebaseinstallations.googleapis.com https://fcmregistrations.googleapis.com mailto: nmshd: data: gap: https://ssl.gstatic.com; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; frame-src 'self'"
/></head></html>""";

final initialData = InAppWebViewInitialData(data: _htmlContent, mimeType: 'text/html', encoding: 'utf-8', baseUrl: WebUri('nmshd://prod'));

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: Home()));
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final HeadlessInAppWebView _headlessWebView;
  late InAppWebViewController _controller;

  final eventBus = EventBus();

  @override
  void initState() {
    super.initState();

    PlatformInAppWebViewController.debugLoggingSettings.excludeFilter.addAll([RegExp(r'.*')]);

    _headlessWebView = HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(isInspectable: kDebugMode),
      initialData: initialData,
      onWebViewCreated: (controller) async {
        _controller = controller;
        await _addJavaScriptHandlers(controller);
        print('WebView created');
      },
      onConsoleMessage: (_, consoleMessage) {
        print('js runtime: ${consoleMessage.message}');
      },
      onLoadStop: (controller, _) async {
        await _loadLibs(controller);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _headlessWebView.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Row(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed:
                    _headlessWebView.isRunning()
                        ? null
                        : () async {
                          await _headlessWebView.run();
                          setState(() {});
                        },
                child: Text("start"),
              ),
              FilledButton(
                onPressed:
                    !_headlessWebView.isRunning()
                        ? null
                        : () async {
                          await _headlessWebView.dispose();
                          setState(() {});
                        },
                child: Text("stop"),
              ),
            ],
          ),
          FilledButton(
            onPressed:
                !_headlessWebView.isRunning() ? null : () async => await _controller.evaluateJavascript(source: "aClassDoingStuff.doSomeStuff()"),
            child: Text("aClassDoingStuff"),
          ),
          FilledButton(
            onPressed:
                !_headlessWebView.isRunning()
                    ? null
                    : () async => await _controller.callAsyncJavaScript(functionBody: "doSomeStuff(aParam)", arguments: {"aParam": "aValue"}),
            child: Text("doSomeStuff"),
          ),
          StreamBuilder(
            stream: eventBus.on<ArbitraryEvent>(),
            builder:
                (_, snapshot) => switch (snapshot.data) {
                  null => Text("no event received"),
                  final ArbitraryEvent e => Text(jsonEncode(e.data)),
                },
          ),
        ],
      ),
    );
  }

  Future<void> _addJavaScriptHandlers(InAppWebViewController controller) async {
    controller.addJavaScriptHandler(
      handlerName: 'handleEvent',
      callback: (args) => eventBus.publish(ArbitraryEvent(namespace: args[0], data: args[1])),
    );

    controller.addJavaScriptHandler(
      handlerName: 'pickFile',
      callback: (_) async {
        final result = await FilePicker.platform.pickFiles(allowMultiple: false, dialogTitle: "Pick a file");
        return result?.files.firstOrNull?.path;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'readFile',
      callback: (args) async {
        final file = args[0] as String;

        return await File(file).readAsString();
      },
    );
  }

  Future<void> _loadLibs(InAppWebViewController controller) async {
    await controller.injectJavascriptFileFromAsset(assetFilePath: 'assets/index.js');
  }
}
