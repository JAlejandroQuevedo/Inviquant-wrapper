import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

const kStartUrl = "https://app.inviquant.com/login_movil";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(false);
  }

  runApp(const WebWrapperApp());
}

class WebWrapperApp extends StatelessWidget {
  const WebWrapperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inviquant',
      theme: ThemeData(useMaterial3: true),
      home: const WebHome(),
    );
  }
}

class WebHome extends StatefulWidget {
  const WebHome({super.key});
  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  InAppWebViewController? _controller;
  final _pullToRefresh = PullToRefreshController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await initCookies();
    });
  }

  Future<void> initCookies() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.setCookie(
      url: WebUri(kStartUrl),
      name: "dummy",
      value: "persist",
      isSecure: true,
      sameSite: HTTPCookieSameSitePolicy.LAX,
    );
  }

  Future<void> loadLocalErrorHtml() async {
    final html = await rootBundle.loadString("assets/html/error.html");
    await _controller?.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  Future<bool> _handleExternalSchemes(Uri url) async {
    final s = url.toString();
    final isExternal =
        s.startsWith("mailto:") ||
        s.startsWith("tel:") ||
        s.startsWith("whatsapp:") ||
        s.startsWith("intent:");

    if (isExternal) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);

        if (_controller != null && await _controller!.canGoBack()) {
          _controller!.goBack();
          return;
        }
        final popped = await navigator.maybePop();
        if (!popped) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_progress > 0 && _progress < 1)
                LinearProgressIndicator(value: _progress),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(kStartUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    cacheEnabled: true,
                    domStorageEnabled: true,
                    userAgent: "AndroidWebWrapper/1.0",
                    supportZoom: false,
                    useOnDownloadStart: true,
                    useShouldOverrideUrlLoading: true,
                    clearCache: false,
                    clearSessionCache: false,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    thirdPartyCookiesEnabled: true,
                    incognito: false,
                  ),
                  pullToRefreshController: _pullToRefresh,
                  onWebViewCreated: (controller) async {
                    _controller = controller;

                    controller.addJavaScriptHandler(
                      handlerName: "reloadMainSite",
                      callback: (args) async {
                        await controller.loadUrl(
                          urlRequest: URLRequest(url: WebUri(kStartUrl)),
                        );
                      },
                    );
                  },
                  onLoadStart: (c, url) async {
                    if (url != null && await _handleExternalSchemes(url)) {
                      c.stopLoading();
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri != null && await _handleExternalSchemes(uri)) {
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (!uri.toString().startsWith("https://")) {
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                  onLoadStop: (controller, url) async {
                    _pullToRefresh.endRefreshing();
                    if (url.toString().startsWith("chrome-error://")) {
                      await loadLocalErrorHtml();
                    }
                  },
                  onReceivedError: (controller, request, error) async {
                    _pullToRefresh.endRefreshing();
                    final isMainFrame = request.isForMainFrame ?? false;
                    if (isMainFrame) {
                      await loadLocalErrorHtml();
                    }
                  },
                  onReceivedHttpError: (controller, request, response) async {
                    _pullToRefresh.endRefreshing();
                    final isMainFrame = request.isForMainFrame ?? false;
                    if (isMainFrame && response.statusCode! >= 400) {
                      await loadLocalErrorHtml();
                    }
                  },
                  onProgressChanged: (c, progress) {
                    setState(() => _progress = progress / 100.0);
                    if (progress == 100) _pullToRefresh.endRefreshing();
                  },
                  onPermissionRequest: (c, req) async {
                    return PermissionResponse(
                      resources: req.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  onDownloadStartRequest: (c, req) async {
                    final url = req.url.toString();
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
