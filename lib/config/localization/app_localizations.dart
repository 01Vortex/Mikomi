import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_name': 'Mikomi',
      'home': 'الصفحة الرئيسية',
      'add': 'إضافة',
      'pilgrimage': 'زيارة المواقع',
      'message': 'الرسائل',
      'profile': 'حسابي',
      'search': 'بحث',
      'search_bangumi': 'ابحث عن أنمي',
      'search_history': 'سجل البحث',
      'no_search_history': 'لا توجد عمليات بحث سابقة',
      'popularity_ranking': 'الأكثر مشاهدة',
      'pilgrimage_map': 'خريطة المواقع',
      'pilgrimage_developing': 'هذه الميزة قيد التطوير حالياً',
      'coming_soon': 'قريباً',
      'no_results': 'لم نجد أي نتائج',
      'loading': 'جاري التحميل',
      'watch_history': 'سجل المشاهدة',
      'no_history': 'لا يوجد',
      'more': 'المزيد',
      'recommend': 'مقترحات',
    },
    'de': {
      'app_name': 'Mikomi',
      'home': 'Start',
      'add': 'Hinzufügen',
      'pilgrimage': 'Schauplätze',
      'message': 'Nachrichten',
      'profile': 'Mein Profil',
      'search': 'Suche',
      'search_bangumi': 'Anime suchen',
      'search_history': 'Verlauf',
      'no_search_history': 'Noch keine Suchanfragen',
      'popularity_ranking': 'Beliebteste',
      'pilgrimage_map': 'Schauplatz-Karte',
      'pilgrimage_developing': 'Diese Funktion ist noch in Arbeit',
      'coming_soon': 'Bald verfügbar',
      'no_results': 'Keine Treffer',
      'loading': 'Lädt',
      'watch_history': 'Verlauf',
      'no_history': 'Leer',
      'more': 'Mehr',
      'recommend': 'Empfehlungen',
    },
    'en': {
      'app_name': 'Mikomi',
      'home': 'Home',
      'add': 'Add',
      'pilgrimage': 'Locations',
      'message': 'Messages',
      'profile': 'Me',
      'search': 'Search',
      'search_bangumi': 'Search anime',
      'search_history': 'Recent searches',
      'no_search_history': 'No recent searches',
      'popularity_ranking': 'Trending',
      'pilgrimage_map': 'Location Map',
      'pilgrimage_developing': 'This feature is coming soon',
      'coming_soon': 'Stay tuned',
      'no_results': 'No results found',
      'loading': 'Loading',
      'watch_history': 'Watch history',
      'no_history': 'None',
      'more': 'More',
      'recommend': 'Recommended',
    },
    'es': {
      'app_name': 'Mikomi',
      'home': 'Inicio',
      'add': 'Añadir',
      'pilgrimage': 'Locaciones',
      'message': 'Mensajes',
      'profile': 'Mi perfil',
      'search': 'Buscar',
      'search_bangumi': 'Buscar anime',
      'search_history': 'Búsquedas recientes',
      'no_search_history': 'Sin búsquedas recientes',
      'popularity_ranking': 'Tendencias',
      'pilgrimage_map': 'Mapa de locaciones',
      'pilgrimage_developing': 'Esta función estará disponible pronto',
      'coming_soon': 'Muy pronto',
      'no_results': 'Sin resultados',
      'loading': 'Cargando',
      'watch_history': 'Historial',
      'no_history': 'Vacío',
      'more': 'Más',
      'recommend': 'Recomendados',
    },
    'fr': {
      'app_name': 'Mikomi',
      'home': 'Accueil',
      'add': 'Ajouter',
      'pilgrimage': 'Lieux',
      'message': 'Messages',
      'profile': 'Mon profil',
      'search': 'Recherche',
      'search_bangumi': 'Rechercher un anime',
      'search_history': 'Recherches récentes',
      'no_search_history': 'Aucune recherche récente',
      'popularity_ranking': 'Tendances',
      'pilgrimage_map': 'Carte des lieux',
      'pilgrimage_developing': 'Cette fonctionnalité arrive bientôt',
      'coming_soon': 'À venir',
      'no_results': 'Aucun résultat',
      'loading': 'Chargement',
      'watch_history': 'Historique',
      'no_history': 'Vide',
      'more': 'Plus',
      'recommend': 'Recommandés',
    },
    'ja': {
      'app_name': 'Mikomi',
      'home': 'ホーム',
      'add': '追加',
      'pilgrimage': '聖地巡礼',
      'message': 'メッセージ',
      'profile': 'マイページ',
      'search': '検索',
      'search_bangumi': 'アニメを検索',
      'search_history': '検索履歴',
      'no_search_history': '検索履歴はありません',
      'popularity_ranking': '人気作品',
      'pilgrimage_map': '聖地マップ',
      'pilgrimage_developing': 'この機能は開発中です',
      'coming_soon': '近日公開',
      'no_results': '見つかりませんでした',
      'loading': '読み込み中',
      'watch_history': '視聴履歴',
      'no_history': 'なし',
      'more': 'もっと見る',
      'recommend': 'おすすめ',
    },
    'pt': {
      'app_name': 'Mikomi',
      'home': 'Início',
      'add': 'Adicionar',
      'pilgrimage': 'Locais',
      'message': 'Mensagens',
      'profile': 'Meu perfil',
      'search': 'Buscar',
      'search_bangumi': 'Buscar anime',
      'search_history': 'Buscas recentes',
      'no_search_history': 'Nenhuma busca recente',
      'popularity_ranking': 'Em alta',
      'pilgrimage_map': 'Mapa de locais',
      'pilgrimage_developing': 'Este recurso estará disponível em breve',
      'coming_soon': 'Em breve',
      'no_results': 'Nenhum resultado',
      'loading': 'Carregando',
      'watch_history': 'Histórico',
      'no_history': 'Vazio',
      'more': 'Mais',
      'recommend': 'Recomendados',
    },
    'ru': {
      'app_name': 'Mikomi',
      'home': 'Главная',
      'add': 'Добавить',
      'pilgrimage': 'Места',
      'message': 'Сообщения',
      'profile': 'Профиль',
      'search': 'Поиск',
      'search_bangumi': 'Найти аниме',
      'search_history': 'История поиска',
      'no_search_history': 'История пуста',
      'popularity_ranking': 'Популярное',
      'pilgrimage_map': 'Карта мест',
      'pilgrimage_developing': 'Эта функция скоро появится',
      'coming_soon': 'Скоро',
      'no_results': 'Ничего не найдено',
      'loading': 'Загрузка',
      'watch_history': 'История',
      'no_history': 'Пусто',
      'more': 'Ещё',
      'recommend': 'Рекомендации',
    },
    'zh-Hans': {
      'app_name': 'Mikomi',
      'home': '首页',
      'add': '添加',
      'pilgrimage': '巡礼',
      'message': '消息',
      'profile': '我的',
      'search': '搜索',
      'search_bangumi': '搜索番剧',
      'search_history': '搜索历史',
      'no_search_history': '暂无搜索历史',
      'popularity_ranking': '热度排行',
      'pilgrimage_map': '巡礼地图',
      'pilgrimage_developing': '巡礼功能开发中',
      'coming_soon': '敬请期待',
      'no_results': '未找到相关番剧',
      'loading': '加载中',
      'watch_history': '播放记录',
      'no_history': '暂无',
      'more': '更多',
      'recommend': '推荐',
    },
    'zh-Hant': {
      'app_name': 'Mikomi',
      'home': '首頁',
      'add': '新增',
      'pilgrimage': '巡禮',
      'message': '訊息',
      'profile': '我的',
      'search': '搜尋',
      'search_bangumi': '搜尋番劇',
      'search_history': '搜尋記錄',
      'no_search_history': '暫無搜尋記錄',
      'popularity_ranking': '熱度排行',
      'pilgrimage_map': '巡禮地圖',
      'pilgrimage_developing': '巡禮功能開發中',
      'coming_soon': '敬請期待',
      'no_results': '未找到相關番劇',
      'loading': '載入中',
      'watch_history': '播放記錄',
      'no_history': '暫無',
      'more': '更多',
      'recommend': '推薦',
    },
  };

  String translate(String key) {
    // 优先使用完整的locale（如zh-Hans, zh-Hant）
    final scriptCode = locale.scriptCode;
    if (scriptCode != null && scriptCode.isNotEmpty) {
      String localeKey = '${locale.languageCode}-$scriptCode';
      if (_localizedValues.containsKey(localeKey)) {
        return _localizedValues[localeKey]?[key] ?? key;
      }
    }
    // 回退到语言代码
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get appName => translate('app_name');
  String get home => translate('home');
  String get add => translate('add');
  String get pilgrimage => translate('pilgrimage');
  String get message => translate('message');
  String get profile => translate('profile');
  String get search => translate('search');
  String get searchBangumi => translate('search_bangumi');
  String get searchHistory => translate('search_history');
  String get noSearchHistory => translate('no_search_history');
  String get popularityRanking => translate('popularity_ranking');
  String get pilgrimageMap => translate('pilgrimage_map');
  String get pilgrimageDeveloping => translate('pilgrimage_developing');
  String get comingSoon => translate('coming_soon');
  String get noResults => translate('no_results');
  String get loading => translate('loading');
  String get watchHistory => translate('watch_history');
  String get noHistory => translate('no_history');
  String get more => translate('more');
  String get recommend => translate('recommend');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // 支持完整locale或语言代码
    String localeKey = locale.scriptCode != null
        ? '${locale.languageCode}-${locale.scriptCode}'
        : locale.languageCode;

    return [
          'ar',
          'de',
          'en',
          'es',
          'fr',
          'ja',
          'pt',
          'ru',
          'zh-Hans',
          'zh-Hant',
        ].contains(localeKey) ||
        [
          'ar',
          'de',
          'en',
          'es',
          'fr',
          'ja',
          'pt',
          'ru',
          'zh',
        ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
