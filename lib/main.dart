





import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';

import 'language_manager.dart';

/// Header component that shows logo on main page and page titles on other pages
class AppHeader extends StatelessWidget {
  final bool isMainPage;
  final String? pageTitle;
  final VoidCallback? onBackPressed;
  
  const AppHeader({
    super.key,
    this.isMainPage = false,
    this.pageTitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isMainPage) {
      // Main page - show logo
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BF80),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 16,
                ),
              );
            },
          ),
        ),
      );
           } else {
         // Other pages - show page title
         return Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
           decoration: const BoxDecoration(
             color: Colors.white,
             boxShadow: [
               BoxShadow(
                 color: Color(0x14000000),
                 blurRadius: 5,
                 offset: Offset(0, 1),
               ),
             ],
           ),
           child: Row(
             children: [
                               // Back button
                if (onBackPressed != null)
                  IconButton(
                    onPressed: onBackPressed,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF2C3E50),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
               // Page title (centered when no back button, left-aligned when back button exists)
               Expanded(
                 child: onBackPressed != null
                     ? Text(
                         pageTitle ?? '',
                         style: const TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.w600,
                           color: Color(0xFF2C3E50),
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       )
                     : Center(
                         child: Text(
                           pageTitle ?? '',
                           style: const TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w600,
                             color: Color(0xFF2C3E50),
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
               ),
             ],
           ),
         );
       }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageManager.instance.initialize();
  runApp(const NiksarMobilApp());
}

// Deep link handling için global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NiksarMobilApp extends StatelessWidget {
  const NiksarMobilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niksar Mobil',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BF80)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const SplashGate(child: RootShell()),
    );
  }
}

/// Basit splash
class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _ready
          ? widget.child
          : Scaffold(
        body: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BF80), Color(0xFF00A874)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Niksar Mobil',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              SizedBox(height: 16),
              CircularProgressIndicator.adaptive(),
            ],
          ),
        ),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

enum BottomItem { home, kesfet, cekGonder, nobetci, ayarlar }

class _RootShellState extends State<RootShell> with SingleTickerProviderStateMixin {
  // IndexedStack aktif sayfa
  int _stackIndex = 0;
  
  // Dil değişikliği için listener
  String? _currentLanguage;

  // --- Stack indexleri (sabit)
  static const int idxHome = 0;
  static const int idxKesfet = 1;
  static const int idxDummy = 2;
  static const int idxNobetci = 3;
  static const int idxSettings = 4;
  static const int idxUlasim = 5;
  static const int idxBelediyem = 6;
  static const int idxEtkinlikler = 7;
  static const int idxOdeme = 8;
  static const int idxRehber = 9;
  static const int idxSearch = 10;
  static const int idxEmergency = 11;

  // WebView key’leri
  final _keyKesfet = GlobalKey<_WebTabState>();
  final _keyNobetci = GlobalKey<_WebTabState>();
  final _keyUlasim = GlobalKey<_WebTabState>();
  final _keyBelediyem = GlobalKey<_WebTabState>();
  final _keyEtkinlikler = GlobalKey<_WebTabState>();
  final _keyOdeme = GlobalKey<_WebTabState>();
  final _keyRehber = GlobalKey<_WebTabState>();
  final _keySearch = GlobalKey<_WebTabState>();

  late final AnimationController _fadeCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 140));

  @override
  void initState() {
    super.initState();
    _currentLanguage = LanguageManager.instance.currentLanguage;
    _ensureLocationPermission();
    _initDeepLinkHandling();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _initDeepLinkHandling() async {
    // Deep link handling
    final appLinks = AppLinks();
    
    // Initial link handling
    try {
      final uri = await appLinks.getInitialAppLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('Initial link error: $e');
    }

    // Link stream handling
    appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');
    
    // Custom scheme handling (niksarmobil://)
    if (uri.scheme == 'niksarmobil') {
      if (uri.host == 'open' && uri.queryParameters.containsKey('url')) {
        final url = uri.queryParameters['url']!;
        _openWebPage(url);
      }
      return;
    }
    
    // Universal Links handling (https://niksarmobil.tr)
    if (uri.scheme == 'https' && uri.host == 'niksarmobil.tr') {
      print('Universal Link detected: ${uri.toString()}');
      _openWebPage(uri.toString());
    }
  }
  
  void _openWebPage(String url) {
    // URL'i Search WebView'de aç
    _keySearch.currentState?.loadUrl(url);
    setState(() => _stackIndex = idxSearch);
    _fadePulse();
  }

  Future<void> _fadePulse() async {
    try {
      await _fadeCtrl.forward();
      await _fadeCtrl.reverse();
    } catch (_) {}
  }

  BottomItem? _currentBottom() {
    switch (_stackIndex) {
      case idxHome:     return BottomItem.home;
      case idxKesfet:   return BottomItem.kesfet;
      case idxDummy:    return BottomItem.cekGonder;
      case idxNobetci:  return BottomItem.nobetci;
      case idxSettings: return BottomItem.ayarlar;
      default:          return null; // Ulaşım/Belediyem/Etkinlikler/Ödeme/Rehber/Search
    }
  }

  void _selectBottom(BottomItem item) {
    switch (item) {
      case BottomItem.home:      _stackIndex = idxHome; break;
      case BottomItem.kesfet:    _stackIndex = idxKesfet; break;
      case BottomItem.cekGonder: _stackIndex = idxDummy; break; // WhatsApp dışa açılacak
      case BottomItem.nobetci:   _stackIndex = idxNobetci; break;
      case BottomItem.ayarlar:   _stackIndex = idxSettings; break;
    }
    setState(() {});
    _fadePulse();
  }

  // Anasayfa kısayolları → ilgili hazır WebView'e git (alt menüde seçim YOK)
  void _openShortcut(String url) {
    final u = Uri.tryParse(url);
    final path = (u?.path ?? '').toLowerCase();
    final host = u?.host.toLowerCase() ?? '';

    if (path.contains('nobetci-eczaneler')) {
      _stackIndex = idxNobetci;
    } else if (path.contains('kesfet')) {
      _stackIndex = idxKesfet;
    } else if (path.contains('ulasim')) {
      _stackIndex = idxUlasim;
    } else if (host.contains('niksar.bel.tr')) {
      // Belediyem için özel kontrol
      _stackIndex = idxBelediyem;
    } else if (path.contains('etkinlikler')) {
      _stackIndex = idxEtkinlikler;
    } else if (path.contains('odeme')) {
      _stackIndex = idxOdeme;
    } else if (path.contains('rehber')) {
      _stackIndex = idxRehber;
    } else {
      _stackIndex = idxKesfet;
    }
    setState(() {});
    _fadePulse();
  }

  // Yer kartına tıklanınca WebView'de aç
  void _openPlace(String url) {
    // Yer sayfasını Search WebView'de aç (çünkü Search WebView'i zaten hazır)
    _keySearch.currentState?.loadUrl(url);
    setState(() => _stackIndex = idxSearch);
    _fadePulse();
  }

  // Arama → Search WebView'i önce yükle sonra göster
  Future<void> _openSearch(String query) async {
    final baseUrl = 'https://niksarmobil.tr/?s=$query';
    final url = LanguageManager.instance.getUrlWithLanguage(baseUrl);
    await _keySearch.currentState?.loadUrlAndWait(url);
    setState(() => _stackIndex = idxSearch);
    _fadePulse();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/905018050060?text=Merhaba%2C%20Niksar%20Mobil%27den%20yaz%C4%B1yorum.');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
    }
  }

  void _reloadWebViewsIfLanguageChanged() {
    final newLanguage = LanguageManager.instance.currentLanguage;
    if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;
      
      // WebView'leri yeni dil URL'leriyle yeniden yükle
      _keyKesfet.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/kesfet'));
      _keyNobetci.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/nobetci-eczaneler'));
      _keyUlasim.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/ulasim'));
      _keyBelediyem.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/belediyem'));
      _keyEtkinlikler.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/etkinlikler'));
      _keyOdeme.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/odeme'));
      _keyRehber.currentState?.loadUrl(LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/rehber'));
    }
  }

  @override
  Widget build(BuildContext context) {
    _reloadWebViewsIfLanguageChanged();
    
         final pages = <Widget>[
       HomeNativePage(
         onShortcut: _openShortcut, 
         onSearch: _openSearch,
         onPlaceTap: _openPlace,
       ),
      WebTab(key: _keyKesfet, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/kesfet')),
      const _DummyPage(), // Çek Gönder dışa açılıyor
      WebTab(key: _keyNobetci, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/nobetci-eczaneler')),
      const SettingsPage(),
      WebTab(key: _keyUlasim, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/ulasim')),
      WebTab(key: _keyBelediyem, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/belediyem')),
      WebTab(key: _keyEtkinlikler, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/etkinlikler')),
      WebTab(key: _keyOdeme, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/odeme')),
      WebTab(key: _keyRehber, initialUrl: LanguageManager.instance.getUrlWithLanguage('https://niksarmobil.tr/rehber')),
      WebTab(key: _keySearch, initialUrl: 'about:blank'),
      const EmergencyPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _stackIndex, children: pages),
          IgnorePointer(
            ignoring: true,
            child: FadeTransition(
              opacity: _fadeCtrl.drive(Tween(begin: 0.0, end: 0.06)),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        selected: _currentBottom(),
        onTap: (item) async {
          if (item == BottomItem.cekGonder) {
            await _openWhatsApp();
            return;
          }
          _selectBottom(item);
        },
      ),
    );
  }
}

/// Web sekmesi + iOS için erken geolocation enjeksiyonu + sol kenardan geri kaydırma
class WebTab extends StatefulWidget {
  final String initialUrl;
  const WebTab({super.key, required this.initialUrl});
  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  int _progress = 0;
  Completer<void>? _navStarted;

  // geolocation watch abonelikleri
  final Map<String, StreamSubscription<Position>> _watchSubs = {};
  bool _polyfillInjected = false;

  // iOS sol kenar geri kaydırma (basit eşik)
  double _dragDx = 0;

  Future<void> loadUrlAndWait(String url) {
    _navStarted ??= Completer<void>();
    _controller.loadRequest(Uri.parse(url));
    return _navStarted!.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }

  void loadUrl(String url) => _controller.loadRequest(Uri.parse(url));

  @override
  void dispose() {
    for (final s in _watchSubs.values) {
      s.cancel();
    }
    _watchSubs.clear();
    super.dispose();
  }

  // --- Geolocation polyfill (JS)
  static const _geoPolyfill = r'''
(function(){
  if (window.__nativeGeoPolyfilled) return;
  window.__nativeGeoPolyfilled = true;

  window.__nativeGeo = { onceCb: null, watchers: {} };

  window.__nativeGeo_receiveOnce = function(lat, lon, acc) {
    try { if (window.__nativeGeo.onceCb && window.__nativeGeo.onceCb.success) {
      window.__nativeGeo.onceCb.success({ coords: { latitude: lat, longitude: lon, accuracy: acc } });
      window.__nativeGeo.onceCb = null;
    }} catch(e){}
  };

  window.__nativeGeo_receiveWatch = function(id, lat, lon, acc) {
    try {
      var w = window.__nativeGeo.watchers[id];
      if (w && w.success) { w.success({ coords: { latitude: lat, longitude: lon, accuracy: acc } }); }
    } catch(e){}
  };

  var original = navigator.geolocation;

  navigator.geolocation.getCurrentPosition = function(success, error, options) {
    try {
      window.__nativeGeo.onceCb = { success: success, error: error };
      NativeGeo.postMessage(JSON.stringify({type:'getOnce'}));
    } catch(e) {
      if (original && original.getCurrentPosition) { return original.getCurrentPosition(success, error, options); }
    }
  };

  navigator.geolocation.watchPosition = function(success, error, options) {
    try {
      var id = Math.random().toString(36).slice(2);
      window.__nativeGeo.watchers[id] = { success: success, error: error };
      NativeGeo.postMessage(JSON.stringify({type:'watch', id:id}));
      return id;
    } catch(e) {
      if (original && original.watchPosition) { return original.watchPosition(success, error, options); }
    }
  };

  navigator.geolocation.clearWatch = function(id) {
    try {
      NativeGeo.postMessage(JSON.stringify({type:'clear', id:id}));
      delete window.__nativeGeo.watchers[id];
    } catch(e) {
      if (original && original.clearWatch) { return original.clearWatch(id); }
    }
  };
})();
''';

  Future<void> _injectGeoPolyfill({bool force = false}) async {
    if (_polyfillInjected && !force) return;
    try {
      await _controller.runJavaScript(_geoPolyfill);
      _polyfillInjected = true;
      // SPA/iframe gecikmeleri için küçük tekrarlar
      Future.delayed(const Duration(milliseconds: 300), () {
        _controller.runJavaScript(_geoPolyfill);
      });
      Future.delayed(const Duration(seconds: 1), () {
        _controller.runJavaScript(_geoPolyfill);
      });
    } catch (_) {}
  }

  // JS → Dart köprüsü
  Future<void> _onGeoMessage(JavaScriptMessage msg) async {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final type = data['type'] as String;

      if (type == 'getOnce') {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await _controller.runJavaScript(
          "window.__nativeGeo_receiveOnce(${pos.latitude},${pos.longitude},${pos.accuracy});",
        );
      } else if (type == 'watch') {
        final id = data['id'] as String;
        _watchSubs[id]?.cancel();
        final sub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3),
        ).listen((pos) {
          _controller.runJavaScript(
            "window.__nativeGeo_receiveWatch('$id',${pos.latitude},${pos.longitude},${pos.accuracy});",
          );
        });
        _watchSubs[id] = sub;
      } else if (type == 'clear') {
        final id = data['id'] as String;
        await _watchSubs[id]?.cancel();
        _watchSubs.remove(id);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('NativeGeo', onMessageReceived: _onGeoMessage)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            // (Search preload için) sayfa başladı sinyali
            _navStarted?.complete();
            _navStarted = null;
            // iOS için erken polyfill
            _polyfillInjected = false;
            _injectGeoPolyfill(force: true);
          },
          onPageFinished: (_) {
            // SPA/iframe için tekrar
            _injectGeoPolyfill(force: true);
          },
          onProgress: (p) => setState(() => _progress = p),
          onNavigationRequest: (req) async {
            if (await _handleExternal(req.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<bool> _handleExternal(String url) async {
    try {
      if (url.startsWith('intent://')) {
        final m = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(url);
        if (m != null) {
          final fb = Uri.decodeComponent(m.group(1)!);
          return await launchUrl(Uri.parse(fb), mode: LaunchMode.externalApplication);
        }
        final httpsUrl = url.replaceFirst('intent://', 'https://');
        return await launchUrl(Uri.parse(httpsUrl), mode: LaunchMode.externalApplication);
      }
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();
      const ext = {'tel', 'sms', 'mailto', 'whatsapp', 'geo'};
      if (ext.contains(scheme)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      final h = uri.host.toLowerCase();
      final p = uri.path.toLowerCase();
      final isMap = h.contains('maps.app.goo.gl') ||
          (h.contains('goo.gl') && p.contains('/maps')) ||
          (h.contains('google.com') && p.contains('/maps')) ||
          (h.contains('yandex.') && p.contains('maps')) ||
          h.contains('waze.com');
      if (isMap) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    // WebView'de geri gidilemiyorsa ana sayfaya dön
    if (context.findAncestorStateOfType<_RootShellState>() != null) {
      context.findAncestorStateOfType<_RootShellState>()!.setState(() {
        context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 0; // idxHome
      });
      return false;
    }
    return true;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // WebView + iOS kenar geri kaydırma overlay’i
    // Get page title based on URL
    String getPageTitle() {
      final url = widget.initialUrl.toLowerCase();
      if (url.contains('kesfet') || url.contains('discover')) {
        return LanguageManager.instance.getTranslation('discover');
      } else if (url.contains('nobetci') || url.contains('pharmacy')) {
        return LanguageManager.instance.getTranslation('pharmacy_on_duty');
      } else if (url.contains('ulasim') || url.contains('transportation')) {
        return LanguageManager.instance.getTranslation('transportation');
      } else if (url.contains('belediyem') || url.contains('municipality')) {
        return LanguageManager.instance.getTranslation('my_municipality');
      } else if (url.contains('etkinlikler') || url.contains('events')) {
        return LanguageManager.instance.getTranslation('events');
      } else if (url.contains('odeme') || url.contains('payment')) {
        return LanguageManager.instance.getTranslation('online_payment');
      } else if (url.contains('rehber') || url.contains('directory')) {
        return LanguageManager.instance.getTranslation('directory');
      } else if (url.contains('toplanma') || url.contains('assembly')) {
        return LanguageManager.instance.getTranslation('assembly_points');
      } else {
        return 'Niksar Mobil';
      }
    }
    
         final webColumn = Column(
       children: [
         // Header with page title
         AppHeader(
           isMainPage: false,
           pageTitle: getPageTitle(),
           onBackPressed: () async {
             if (await _controller.canGoBack()) {
               await _controller.goBack();
             } else {
               // WebView'de geri gidilemiyorsa ana sayfaya dön
               if (context.findAncestorStateOfType<_RootShellState>() != null) {
                 context.findAncestorStateOfType<_RootShellState>()!.setState(() {
                   context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 0; // idxHome
                 });
               }
             }
           },
         ),
         Expanded(child: WebViewWidget(controller: _controller)),
       ],
     );

    return SafeArea(
      child: WillPopScope(
        onWillPop: _handleBack,
        child: Stack(
          children: [
            webColumn,
            if (Platform.isIOS)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 24, // sol kenar "geri" tutacağı
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _dragDx = 0,
                  onHorizontalDragUpdate: (d) {
                    if (d.delta.dx > 0) _dragDx += d.delta.dx; // sağa doğru sürükleme
                  },
                                     onHorizontalDragEnd: (_) async {
                     if (_dragDx > 60) {
                       if (await _controller.canGoBack()) {
                         await _controller.goBack();
                       } else {
                         // WebView'de geri gidilemiyorsa ana sayfaya dön
                         if (context.findAncestorStateOfType<_RootShellState>() != null) {
                           context.findAncestorStateOfType<_RootShellState>()!.setState(() {
                             context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 0; // idxHome
                           });
                         }
                       }
                     }
                     _dragDx = 0;
                   },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Anasayfa — yeni tasarım ile güncellendi
class HomeNativePage extends StatefulWidget {
  final void Function(String url) onShortcut;
  final Future<void> Function(String encodedQuery) onSearch;
  final void Function(String url) onPlaceTap; // Yer kartına tıklanınca WebView açmak için
  const HomeNativePage({
    super.key, 
    required this.onShortcut, 
    required this.onSearch,
    required this.onPlaceTap,
  });

  @override
  State<HomeNativePage> createState() => _HomeNativePageState();
}

class _HomeNativePageState extends State<HomeNativePage> {
  List<Map<String, dynamic>> _recommendedPlaces = [];
  bool _isLoadingPlaces = true;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = LanguageManager.instance.currentLanguage;
    _fetchRecommendedPlaces();
    
    // Dil değişikliği listener'ını ekle
    LanguageManager.instance.addLanguageChangeListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    // Listener'ı kaldır
    LanguageManager.instance.removeLanguageChangeListener(_onLanguageChanged);
    super.dispose();
  }

  // Dil değişikliği callback'i
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _currentLanguage = LanguageManager.instance.currentLanguage;
        _isLoadingPlaces = true;
      });
      _fetchRecommendedPlaces(); // Yeni dilde yerleri yeniden yükle
    }
  }

  Future<void> _fetchRecommendedPlaces() async {
    try {
      // WordPress REST API'den tüm "Yer" post type'ını çek, sonra dil filtrelemesi yap
      final response = await http.get(
        Uri.parse('https://niksarmobil.tr/wp-json/wp/v2/yer?per_page=50&_embed'),
        headers: {'Accept': 'application/json'},
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final List<dynamic> allData = json.decode(response.body);
        print('API Data Length: ${allData.length}');
        
        // Seçilen dile göre yerleri filtrele
        final currentLang = LanguageManager.instance.currentLanguage;
        final isEnglish = currentLang == LanguageManager.english;
        
        final List<dynamic> filteredData = allData.where((item) {
          final link = item['link'] ?? '';
          if (isEnglish) {
            // İngilizce için /en/ içeren URL'leri kabul et
            return link.contains('/en/');
          } else {
            // Türkçe için /en/ içermeyen URL'leri kabul et
            return !link.contains('/en/');
          }
        }).toList();
        
        print('Filtered Data Length: ${filteredData.length}');
        print('Current Language: $currentLang');
        
        setState(() {
          _recommendedPlaces = filteredData.map((item) {
             // Featured image URL'sini _embedded'den al
             String featuredImageUrl = '';
             if (item['_embedded'] != null && 
                 item['_embedded']['wp:featuredmedia'] != null && 
                 item['_embedded']['wp:featuredmedia'].isNotEmpty) {
               final media = item['_embedded']['wp:featuredmedia'][0];
               featuredImageUrl = media['source_url'] ?? '';
               print('Found image: $featuredImageUrl');
             }
             
             // Tip bilgisini class_list'ten al
             String kategori = '';
             if (item['class_list'] != null) {
               final classList = item['class_list'] as List;
               for (String className in classList) {
                 if (className.startsWith('tip-')) {
                   kategori = className.replaceFirst('tip-', '');
                   break;
                 }
               }
             }
             
             return {
               'id': item['id'],
               'title': item['title']['rendered'] ?? '',
               'excerpt': item['excerpt']?['rendered'] ?? '',
               'content': item['content']['rendered'] ?? '',
               'featured_media': item['featured_media'] ?? 0,
               'featured_image_url': featuredImageUrl,
               'link': item['link'] ?? '',
               // ACF alanları boş olduğu için varsayılan değerler
               'adres': 'Niksar, Tokat',
               'telefon': '',
               'website': '',
               'calisma_saatleri': '',
               'kategori': kategori,
               'modified': item['modified'] ?? '', // Güncellenme tarihi eklendi
             };
           }).toList();
           
           // Güncellenme tarihine göre sırala (en yeni güncellenen en üstte)
           _recommendedPlaces.sort((a, b) {
             final dateA = DateTime.tryParse(a['modified'] ?? '') ?? DateTime(1900);
             final dateB = DateTime.tryParse(b['modified'] ?? '') ?? DateTime(1900);
             return dateB.compareTo(dateA); // Azalan sıralama (en yeni önce)
           });
           
           _isLoadingPlaces = false;
         });
        
        print('Processed Places: ${_recommendedPlaces.length}');
        print('First Place: ${_recommendedPlaces.isNotEmpty ? _recommendedPlaces.first : 'No places'}');
        print('Language Filter Applied: ${isEnglish ? 'English' : 'Turkish'}');
      } else {
        print('API Hatası: ${response.statusCode}');
        print('Error Body: ${response.body}');
        setState(() {
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      print('Veri çekme hatası: $e');
      setState(() {
        _isLoadingPlaces = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF00BF80);
    final searchCtrl = TextEditingController();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
                                // Header with logo
                    const AppHeader(isMainPage: true),
            // Üst kısım - Arkaplan görseli + karşılama mesajı
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                // Arkaplan görseli assets'ten yükleniyor
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  // Arkaplan görseli
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Image.asset(
                        'assets/header.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: green.withOpacity(0.9),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Karşılama mesajı
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageManager.instance.getTranslation('welcome'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LanguageManager.instance.getTranslation('discover_niksar'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Arama kutusu
                        Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onSubmitted: (v) {
                          final q = v.trim();
                              if (q.isNotEmpty) widget.onSearch(Uri.encodeQueryComponent(q));
                        },
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                              hintText: LanguageManager.instance.getTranslation('search_placeholder'),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                          suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Color(0xFF00BF80)),
                            onPressed: () {
                              final q = searchCtrl.text.trim();
                                  if (q.isNotEmpty) widget.onSearch(Uri.encodeQueryComponent(q));
                            },
                          ),
                          border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // 30'dan 20'ye düşürüldü

            // 8 buton grid - kompakt tasarım
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 20'den 16'ya düşürüldü
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    LanguageManager.instance.getTranslation('quick_access'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12), // 20'den 12'ye düşürüldü
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: [
                      _Quick(
                        icon: Icons.explore_outlined,
                        label: LanguageManager.instance.getTranslation('discover'),
                        url: 'https://niksarmobil.tr/kesfet',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.medication,
                        label: LanguageManager.instance.getTranslation('pharmacy_on_duty'),
                        url: 'https://niksarmobil.tr/nobetci-eczaneler',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.directions_bus,
                        label: LanguageManager.instance.getTranslation('transportation'),
                        url: 'https://niksarmobil.tr/ulasim',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.apartment,
                        label: LanguageManager.instance.getTranslation('my_municipality'),
                        url: 'https://niksar.bel.tr',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.event,
                        label: LanguageManager.instance.getTranslation('events'),
                        url: 'https://niksarmobil.tr/etkinlikler',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.credit_card,
                        label: LanguageManager.instance.getTranslation('online_payment'),
                        url: 'https://e-hizmet.niksar.bel.tr/#/home',
                        onTap: (url) async {
                          // Harici tarayıcıda aç
                          final uri = Uri.parse(url);
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                      _Quick(
                        icon: Icons.phone,
                        label: LanguageManager.instance.getTranslation('directory'),
                        url: 'https://niksarmobil.tr/rehber',
                        onTap: widget.onShortcut,
                      ),
                      _Quick(
                        icon: Icons.emergency,
                        label: LanguageManager.instance.getTranslation('emergency'),
                        url: 'acil_durum',
                        onTap: (url) {
                          // Acil durum sayfasını aç
                          if (context.findAncestorStateOfType<_RootShellState>() != null) {
                            context.findAncestorStateOfType<_RootShellState>()!.setState(() {
                              context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 11; // idxEmergency
                            });
                          }
                        },
                      ),

                    ],
                  ),
                ],
              ),
            ),

                         const SizedBox(height: 2), // 12'den 8'e düşürüldü

                          // Önerilen yerler
             Container(
               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // 16'dan 8'e düşürüldü
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageManager.instance.getTranslation('popular_places'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                                     const SizedBox(height: 2), // 12'den 8'e düşürüldü
                  if (_isLoadingPlaces)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BF80),
                      ),
                    )
                  else if (_recommendedPlaces.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedPlaces.length,
                        itemBuilder: (context, index) {
                          final place = _recommendedPlaces[index];
                                                     return GestureDetector(
                             onTap: () => widget.onPlaceTap(place['link']),
                             child: Container(
                               width: 280,
                               margin: const EdgeInsets.only(right: 16),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(16),
                                 boxShadow: const [
                                   BoxShadow(
                                     color: Colors.black12,
                                     blurRadius: 10,
                                     offset: Offset(0, 4),
                                   ),
                                 ],
                               ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Yer görseli
                                if (place['featured_image_url'].isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      place['featured_image_url'],
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          height: 120,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                // Yer bilgileri
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place['title'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (place['excerpt'].isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          place['excerpt'].replaceAll(RegExp(r'<[^>]*>'), ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          LanguageManager.instance.getTranslation('no_places_yet'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

                         const SizedBox(height: 10), // 30'dan 20'ye düşürüldü
          ],
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

/// Acil Durum Sayfası - Güncellenmiş tasarım
class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isFlashlightOn = false;
  bool _isAlarmOn = false;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9), // Ana uygulama ile aynı arka plan
      body: SafeArea(
        child: Column(
          children: [
                         // Header with page title
             AppHeader(
               isMainPage: false,
               pageTitle: LanguageManager.instance.getTranslation('emergency'),
               onBackPressed: () {
                 if (context.findAncestorStateOfType<_RootShellState>() != null) {
                   context.findAncestorStateOfType<_RootShellState>()!.setState(() {
                     context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 0; // idxHome
                   });
                 }
               },
             ),
            // Subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                LanguageManager.instance.getTranslation('emergency_subtitle'),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Acil durum seçenekleri - Grid layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // Toplanma Noktaları
                    _buildEmergencyCard(
                      icon: Icons.location_on,
                      title: LanguageManager.instance.getTranslation('assembly_points'),
                      subtitle: LanguageManager.instance.getTranslation('assembly_points_desc'),
                      color: const Color(0xFF3498DB),
                      onTap: () => _openAssemblyPoints(),
                    ),
                    
                    // Işığı Aç/Kapat
                    _buildEmergencyCard(
                      icon: _isFlashlightOn ? Icons.flashlight_off : Icons.flashlight_on,
                      title: _isFlashlightOn 
                          ? LanguageManager.instance.getTranslation('turn_off_light')
                          : LanguageManager.instance.getTranslation('turn_on_light'),
                      subtitle: LanguageManager.instance.getTranslation('flashlight_desc'),
                      color: _isFlashlightOn ? const Color(0xFFE74C3C) : const Color(0xFFF39C12),
                      onTap: () => _toggleFlashlight(),
                    ),
                    
                    // Ses Çal/Durdur
                    _buildEmergencyCard(
                      icon: _isAlarmOn ? Icons.volume_off : Icons.volume_up,
                      title: _isAlarmOn 
                          ? LanguageManager.instance.getTranslation('turn_off_alarm')
                          : LanguageManager.instance.getTranslation('turn_on_alarm'),
                      subtitle: LanguageManager.instance.getTranslation('alarm_desc'),
                      color: _isAlarmOn ? const Color(0xFFE74C3C) : const Color(0xFF9B59B6),
                      onTap: () => _toggleAlarm(),
                    ),
                    
                    // 112'yi Ara
                    _buildEmergencyCard(
                      icon: Icons.phone,
                      title: LanguageManager.instance.getTranslation('call_112'),
                      subtitle: LanguageManager.instance.getTranslation('call_112_desc'),
                      color: const Color(0xFFE74C3C),
                      onTap: () => _callEmergency(),
                    ),
                    
                    // 112'ye Mesaj At
                    _buildEmergencyCard(
                      icon: Icons.message,
                      title: LanguageManager.instance.getTranslation('message_112'),
                      subtitle: LanguageManager.instance.getTranslation('message_112_desc'),
                      color: const Color(0xFF27AE60),
                      onTap: () => _messageEmergency(),
                    ),
                    

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Konum bilgisi kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BF80).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF00BF80),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        LanguageManager.instance.getTranslation('your_location'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingLocation)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00BF80),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          LanguageManager.instance.getTranslation('getting_location'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    )
                  else if (_currentPosition != null) ...[
                    _buildLocationInfo(
                      'Latitude',
                      _currentPosition!.latitude.toStringAsFixed(6),
                      Icons.north,
                    ),
                    const SizedBox(height: 8),
                    _buildLocationInfo(
                      'Longitude',
                      _currentPosition!.longitude.toStringAsFixed(6),
                      Icons.east,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _copyCoordinates(),
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(LanguageManager.instance.getTranslation('copy_coordinates')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BF80),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ] else
                    Text(
                      LanguageManager.instance.getTranslation('location_error'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                BoxShadow(
                  color: const Color(0x14000000),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF7F8C8D),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }

  void _openAssemblyPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebTab(
          initialUrl: LanguageManager.instance.getUrlWithLanguage(
            'https://niksarmobil.tr/toplanma-yerleri'
          ),
        ),
      ),
    );
  }

  void _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        setState(() {
          _isFlashlightOn = false;
        });
      } else {
        await TorchLight.enableTorch();
        setState(() {
          _isFlashlightOn = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flaş özelliği kullanılamıyor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleAlarm() async {
    try {
      if (_isAlarmOn) {
        // Sesi durdur
        await _audioPlayer.stop();
        setState(() {
          _isAlarmOn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses durduruldu'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        setState(() {
          _isAlarmOn = true;
        });
        
        // Alarm sesini çal
        try {
          await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alarm sesi çalınıyor'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 10 saniye sonra otomatik durdur
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && _isAlarmOn) {
              _audioPlayer.stop();
              setState(() {
                _isAlarmOn = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ses otomatik olarak durduruldu'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } catch (e) {
          // Ses dosyası bulunamadıysa titreşim kullan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ses dosyası bulunamadı, sadece görsel alarm aktif'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // 5 saniye sonra otomatik kapat
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _isAlarmOn) {
              setState(() {
                _isAlarmOn = false;
              });
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm özelliği kullanılamıyor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _callEmergency() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageManager.instance.getTranslation('cannot_call')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _messageEmergency() async {
    if (_currentPosition != null) {
      try {
        // Konum bilgisini hazırla
        final coordinates = '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';
        final message = 'Acil durum! Konumum: $coordinates';
        
        // SMS uygulamasını açmayı dene
        bool smsOpened = false;
        
        try {
          // Önce tam SMS URI'ı dene (Android için)
          final fullSmsUri = Uri.parse('sms:112?body=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(fullSmsUri)) {
            await launchUrl(fullSmsUri);
            smsOpened = true;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('SMS uygulaması açıldı - 112 numarasına konum bilgisi ile mesaj yazabilirsiniz'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          print('Tam SMS URI hatası: $e');
        }
        
        // Tam URI çalışmadıysa sadece SMS uygulamasını açmayı dene
        if (!smsOpened) {
          try {
            final simpleSmsUri = Uri.parse('sms:112');
            if (await canLaunchUrl(simpleSmsUri)) {
              await launchUrl(simpleSmsUri);
              smsOpened = true;
              
              // Konum bilgisini panoya kopyala
              await Clipboard.setData(ClipboardData(text: message));
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SMS uygulaması açıldı. Konum bilgisi panoya kopyalandı, yapıştırabilirsiniz.'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } catch (e) {
            print('Basit SMS URI hatası: $e');
          }
        }
        
        // SMS hiç açılamadıysa konum bilgisini panoya kopyala
        if (!smsOpened) {
          await Clipboard.setData(ClipboardData(text: message));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS açılamadı. Konum bilgisi panoya kopyalandı. Manuel olarak 112\'ye SMS atabilirsiniz.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        print('SMS fonksiyonunda hata: $e');
        
        // Hata durumunda sadece koordinatları kopyala
        try {
          final coordinates = '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';
          await Clipboard.setData(ClipboardData(text: coordinates));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konum bilgisi panoya kopyalandı. Manuel olarak 112\'ye SMS atabilirsiniz.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e2) {
          print('Koordinat kopyalama hatası: $e2');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konum bilgisi kopyalanamadı: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum bilgisi alınamadı. Lütfen konum iznini verin.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }



  void _copyCoordinates() {
    if (_currentPosition != null) {
      final coordinates = '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';
      Clipboard.setData(ClipboardData(text: coordinates));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageManager.instance.getTranslation('coordinates_copied')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final void Function(String url) onTap;
  const _Quick({required this.icon, required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF00BF80);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(url),
          child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: green,
                size: 20,
          ),
        ),
        const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DummyPage extends StatelessWidget {
  const _DummyPage({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
                         // Header with page title
             AppHeader(
               isMainPage: false,
               pageTitle: LanguageManager.instance.getTranslation('settings_title'),
               onBackPressed: () {
                 if (context.findAncestorStateOfType<_RootShellState>() != null) {
                   context.findAncestorStateOfType<_RootShellState>()!.setState(() {
                     context.findAncestorStateOfType<_RootShellState>()!._stackIndex = 0; // idxHome
                   });
                 }
               },
             ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingsGroup([
                    _buildLanguageOption(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSettingsGroup([
                    _buildInfoOption(
                      icon: Icons.info_outline,
                      title: LanguageManager.instance.getTranslation('version'),
                      subtitle: '1.0.0+2',
                    ),
                    _buildInfoOption(
                      icon: Icons.business_outlined,
                      title: LanguageManager.instance.getTranslation('about'),
                      subtitle: 'Niksar Mobil Uygulaması',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildLanguageOption() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.language,
          color: Color(0xFF4CAF50),
          size: 24,
        ),
      ),
      title: Text(
        LanguageManager.instance.getTranslation('language_selection'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        LanguageManager.instance.isEnglish 
          ? LanguageManager.instance.getTranslation('english')
          : LanguageManager.instance.getTranslation('turkish'),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF718096),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Color(0xFF718096),
        size: 16,
      ),
      onTap: () => _showLanguageDialog(),
    );
  }

  Widget _buildInfoOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF718096),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LanguageManager.instance.getTranslation('language_selection'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageRadio(
              title: 'Türkçe',
              value: LanguageManager.turkish,
              groupValue: LanguageManager.instance.currentLanguage,
            ),
            _buildLanguageRadio(
              title: 'English',
              value: LanguageManager.english,
              groupValue: LanguageManager.instance.currentLanguage,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LanguageManager.instance.getTranslation('cancel'),
              style: const TextStyle(color: Color(0xFF718096)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRadio({
    required String title,
    required String value,
    required String groupValue,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2D3748),
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: const Color(0xFF4CAF50),
      onChanged: (value) async {
        if (value != null) {
          await LanguageManager.instance.setLanguage(value);
          if (mounted) {
            Navigator.of(context).pop();
            setState(() {});
            
            // Ana uygulama state'ini yeniden oluştur
            if (context.findAncestorStateOfType<_RootShellState>() != null) {
              context.findAncestorStateOfType<_RootShellState>()!.setState(() {});
            }
            
            // Snackbar göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LanguageManager.instance.getTranslation('language_changed'),
                ),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }
}

/// Alt menü – görseldeki tasarıma uygun modern tasarım
class CustomBottomBar extends StatelessWidget {
  final BottomItem? selected;
  final void Function(BottomItem) onTap;
  const CustomBottomBar({super.key, required this.selected, required this.onTap});

  // Her tab için özel renkler
  Color _getActiveColor(BottomItem item) {
    switch (item) {
      case BottomItem.home:
        return const Color(0xFF7F52B5); // Mor
      case BottomItem.kesfet:
        return const Color(0xFFE91E63); // Pembe
      case BottomItem.cekGonder:
        return const Color(0xFFFF9800); // Turuncu
      case BottomItem.nobetci:
        return const Color(0xFF00BCD4); // Teal
      case BottomItem.ayarlar:
        return const Color(0xFF4CAF50); // Yeşil
    }
  }

  Color _getBackgroundColor(BottomItem item) {
    switch (item) {
      case BottomItem.home:
        return const Color(0xFFE0D4F7); // Açık mor
      case BottomItem.kesfet:
        return const Color(0xFFFCE4EC); // Açık pembe
      case BottomItem.cekGonder:
        return const Color(0xFFFFF3E0); // Açık turuncu
      case BottomItem.nobetci:
        return const Color(0xFFE0F7FA); // Açık teal
      case BottomItem.ayarlar:
        return const Color(0xFFE8F5E8); // Açık yeşil
    }
  }

  IconData _getIcon(BottomItem item) {
    switch (item) {
      case BottomItem.home:
        return Icons.home_outlined;
      case BottomItem.kesfet:
        return Icons.explore_outlined;
      case BottomItem.cekGonder:
        return Icons.photo_camera_outlined;
      case BottomItem.nobetci:
        return Icons.medication; // İlaç ikonu
      case BottomItem.ayarlar:
        return Icons.settings_outlined;
    }
  }

  String _getLabel(BottomItem item) {
    switch (item) {
      case BottomItem.home:
        return LanguageManager.instance.getTranslation('home');
      case BottomItem.kesfet:
        return LanguageManager.instance.getTranslation('discover');
      case BottomItem.cekGonder:
        return LanguageManager.instance.getTranslation('send_photo');
      case BottomItem.nobetci:
        return LanguageManager.instance.getTranslation('pharmacy_on_duty');
      case BottomItem.ayarlar:
        return LanguageManager.instance.getTranslation('settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // Görseldeki açık gri arka plan
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Horizontal padding kısaltıldı
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(BottomItem.home),
              _buildTab(BottomItem.kesfet),
              _buildTab(BottomItem.cekGonder),
              _buildTab(BottomItem.nobetci),
              _buildTab(BottomItem.ayarlar),
            ],
          ),
          ),
        ),
      );
    }

  Widget _buildTab(BottomItem item) {
    final isSelected = selected == item;
    
    if (isSelected) {
      // Aktif tab - pill-shaped background ile icon + text
      return GestureDetector(
        onTap: () => onTap(item),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Horizontal padding kısaltıldı
        decoration: BoxDecoration(
            color: _getBackgroundColor(item),
            borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
          children: [
              Icon(
                _getIcon(item),
                color: _getActiveColor(item),
                size: 20, // Icon boyutu küçültüldü
              ),
              const SizedBox(width: 6), // Boşluk kısaltıldı
              Text(
                _getLabel(item),
                style: TextStyle(
                  color: _getActiveColor(item),
                  fontWeight: FontWeight.w600,
                  fontSize: 13, // Font boyutu küçültüldü
                ),
              ),
          ],
        ),
      ),
    );
    } else {
      // İnaktif tab - sadece icon
      return GestureDetector(
        onTap: () => onTap(item),
        child: Container(
          padding: const EdgeInsets.all(12), // Padding kısaltıldı
          child: Icon(
            _getIcon(item),
            color: const Color(0xFF8E8E93),
            size: 24, // Icon boyutu küçültüldü
          ),
        ),
      );
    }
  }
}


