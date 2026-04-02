class AniListQueries {
  static const String base = '''
query (
  \$page: Int,
  \$perPage: Int,
  \$sort: [MediaSort],
  \$country: CountryCode,
  \$genre: String,
  \$seasonYear: Int,
  \$status: MediaStatus
) {
  Page(page: \$page, perPage: \$perPage) {
    media(
      type: ANIME,
      sort: \$sort,
      countryOfOrigin: \$country,
      genre: \$genre,
      seasonYear: \$seasonYear,
      status: \$status
    ) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        medium
      }
      averageScore
      popularity
      favourites
      startDate {
        year
        month
        day
      }
      genres
    }
  }
}
''';

  static const String japanese = '''
query (
  \$page: Int,
  \$perPage: Int,
  \$sort: [MediaSort],
  \$country: CountryCode
) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, sort: \$sort, countryOfOrigin: \$country) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        medium
      }
      averageScore
      popularity
      favourites
      startDate {
        year
        month
        day
      }
      genres
    }
  }
}
''';

  static const String airingSchedule = '''
query (
  \$page: Int,
  \$perPage: Int
) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, status: RELEASING, sort: POPULARITY_DESC) {
      id
      countryOfOrigin
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        medium
      }
      averageScore
      popularity
      genres
      nextAiringEpisode {
        airingAt
        episode
      }
    }
  }
}
''';
}
