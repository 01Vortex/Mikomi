class AniListQueries {
  static const String base = '''
query (
  \$page: Int,
  \$perPage: Int,
  \$sort: [MediaSort]
) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, sort: \$sort) {
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
}
