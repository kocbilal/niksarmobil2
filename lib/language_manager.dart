import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = 'selected_language';
  static const String turkish = 'tr';
  static const String english = 'en';
  
  static LanguageManager? _instance;
  static LanguageManager get instance => _instance ??= LanguageManager._();
  
  LanguageManager._();
  
  String _currentLanguage = turkish;
  
  // Dil değişikliği listener'ları
  final List<Function()> _languageChangeListeners = [];
  
  String get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == english;
  bool get isTurkish => _currentLanguage == turkish;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? turkish;
  }
  
  Future<void> setLanguage(String language) async {
    if (language != turkish && language != english) return;
    
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    
    // Tüm listener'ları tetikle
    _notifyLanguageChangeListeners();
  }
  
  // Dil değişikliği listener'ı ekle
  void addLanguageChangeListener(Function() listener) {
    _languageChangeListeners.add(listener);
  }
  
  // Dil değişikliği listener'ı kaldır
  void removeLanguageChangeListener(Function() listener) {
    _languageChangeListeners.remove(listener);
  }
  
  // Tüm listener'ları tetikle
  void _notifyLanguageChangeListeners() {
    for (final listener in _languageChangeListeners) {
      try {
        listener();
      } catch (e) {
        print('Language change listener error: $e');
      }
    }
  }
  
  String getTranslation(String key) {
    final translations = isEnglish ? _englishTranslations : _turkishTranslations;
    return translations[key] ?? key;
  }
  
  String getUrlWithLanguage(String baseUrl) {
    if (isEnglish) {
      // /kesfet -> /en/discover gibi dönüşümler
      final slugTranslations = {
        '/kesfet': '/en/discover',
        '/nobetci-eczaneler': '/en/pharmacy-on-duty',
        '/ulasim': '/en/transportation',
        '/belediyem': '/en/my-municipality',
        '/etkinlikler': '/en/events',
        '/odeme': '/en/payment',
        '/rehber': '/en/directory',
      };
      
      for (final entry in slugTranslations.entries) {
        if (baseUrl.contains(entry.key)) {
          return baseUrl.replaceAll(entry.key, entry.value);
        }
      }
      
      // Genel durumlar için /en prefix'i ekle
      if (!baseUrl.contains('/en/') && baseUrl.contains('niksarmobil.tr/')) {
        return baseUrl.replaceAll('niksarmobil.tr/', 'niksarmobil.tr/en/');
      }
    }
    
    return baseUrl;
  }
}

// Türkçe çeviriler
const Map<String, String> _turkishTranslations = {
  // Ana menü
  'home': 'Anasayfa',
  'discover': 'Keşfet',
  'send_photo': 'Çek Gönder',
  'pharmacy_on_duty': 'Nöbetçi',
  'settings': 'Ayarlar',
  
  // Ayarlar sayfası
  'settings_title': 'Ayarlar',
  'language_selection': 'Dil Seçimi',
  'turkish': 'Türkçe',
  'english': 'English',
  'language_changed': 'Dil değiştirildi',
  'app_info': 'Uygulama Bilgileri',
  'version': 'Sürüm',
  'about': 'Hakkında',
  
  // Ana sayfa
  'welcome': 'Hoş Geldiniz!',
  'discover_niksar': 'Niksar\'ın güzelliklerini keşfedin',
  'search_placeholder': 'Niksar\'da ara...',
  'quick_access': 'Hızlı Erişim',
  'popular_places': 'Önerilen Yerler',
  
  // Hızlı erişim butonları
  'transportation': 'Ulaşım',
  'my_municipality': 'Belediyem',
  'events': 'Etkinlikler',
  'online_payment': 'Online\nÖdeme',
  'directory': 'Rehber',
  'emergency': 'Acil\nDurum',
  'emergency_coming_soon': 'Acil durum sayfası yakında eklenecek',
  'no_places_yet': 'Henüz önerilen yer bulunmuyor',

  
  // Acil durum sayfası
  'emergency_subtitle': 'Acil durumlarda hızlı erişim',
  'assembly_points': 'Toplanma Noktaları',
  'assembly_points_desc': 'Güvenli toplanma yerleri',
  'turn_on_light': 'Işığı Aç',
  'turn_off_light': 'Işığı Kapat',
  'turn_on_alarm': 'Ses Çal',
  'turn_off_alarm': 'Sesi Durdur',
  'flashlight_desc': 'Flaş ışığını yak',
  'alarm_desc': 'Yüksek sesli alarm sesi',
  'call_112': '112\'yi Ara',
  'call_112_desc': 'Acil durum numarası',
  'message_112': '112\'ye Mesaj At',
  'message_112_desc': 'Konum ile SMS gönder',

  'your_location': 'Konumunuz',
  'getting_location': 'Konum bilgisi alınıyor...',
  'latitude': 'Enlem',
  'longitude': 'Boylam',
  'accuracy': 'Hassasiyet',
  'location_error': 'Konum alınamadı',
  'flashlight_coming_soon': 'Fener özelliği yakında eklenecek',
  'alarm_coming_soon': 'Alarm özelliği yakında eklenecek',
  'cannot_call': 'Arama yapılamadı',
  'cannot_message': 'Mesaj gönderilemedi',
  'copy_coordinates': 'Koordinatları kopyala',
  'coordinates_copied': 'Koordinatlar kopyalandı',


  
  // Genel
  'loading': 'Yükleniyor...',
  'error': 'Hata',
  'retry': 'Tekrar Dene',
  'cancel': 'İptal',
  'ok': 'Tamam',
};

// İngilizce çeviriler
const Map<String, String> _englishTranslations = {
  // Ana menü
  'home': 'Home',
  'discover': 'Discover',
  'send_photo': 'Send Photo',
  'pharmacy_on_duty': 'Pharmacy',
  'settings': 'Settings',
  
  // Ayarlar sayfası
  'settings_title': 'Settings',
  'language_selection': 'Language Selection',
  'turkish': 'Türkçe',
  'english': 'English',
  'language_changed': 'Language changed',
  'app_info': 'App Information',
  'version': 'Version',
  'about': 'About',
  
  // Ana sayfa
  'welcome': 'Welcome!',
  'discover_niksar': 'Discover the beauties of Niksar',
  'search_placeholder': 'Search in Niksar...',
  'quick_access': 'Quick Access',
  'popular_places': 'Popular Places',
  
  // Hızlı erişim butonları
  'transportation': 'Transport',
  'my_municipality': 'Municipality',
  'events': 'Events',
  'online_payment': 'Online\nPayment',
  'directory': 'Directory',
  'emergency': 'Emergency',
  'emergency_coming_soon': 'Emergency page coming soon',
  'no_places_yet': 'No recommended places yet',

  
  // Emergency page
  'emergency_subtitle': 'Quick access in emergencies',
  'assembly_points': 'Assembly Points',
  'assembly_points_desc': 'Safe assembly locations',
  'turn_on_light': 'Turn on Light',
  'turn_off_light': 'Turn off Light',
  'turn_on_alarm': 'Play Sound',
  'turn_off_alarm': 'Stop Sound',
  'flashlight_desc': 'Turn on flashlight',
  'alarm_desc': 'High volume alarm sound',
  'call_112': 'Call 112',
  'call_112_desc': 'Emergency number',
  'message_112': 'Message 112',
  'message_112_desc': 'Send SMS with location',

  'your_location': 'Your Location',
  'getting_location': 'Getting location information...',
  'latitude': 'Latitude',
  'longitude': 'Longitude',
  'accuracy': 'Accuracy',
  'location_error': 'Could not get location',
  'flashlight_coming_soon': 'Flashlight feature coming soon',
  'alarm_coming_soon': 'Alarm feature coming soon',
  'cannot_call': 'Could not make call',
  'cannot_message': 'Could not send message',
  'copy_coordinates': 'Copy coordinates',
  'coordinates_copied': 'Coordinates copied',


  
  // Genel
  'loading': 'Loading...',
  'error': 'Error',
  'retry': 'Retry',
  'cancel': 'Cancel',
  'ok': 'OK',
};
