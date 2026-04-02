import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/features/anime/models/anime_related_info_model.dart';
import 'package:mikomi/features/anime/models/anime_teasing_model.dart';
import 'package:mikomi/features/anime/models/character_info_model.dart';
import 'package:mikomi/features/anime/models/character_teasing_model.dart';
import 'package:mikomi/features/anime/models/person_info_model.dart';
import 'package:mikomi/features/anime/models/person_teasing_model.dart';
import 'package:mikomi/features/anime/models/staff_info_model.dart';

class AnimeRepository {
  final BangumiSource _source;

  AnimeRepository({BangumiSource? source}) : _source = source ?? BangumiSource();

  Future<List<AnimeRelatedInfoModel>> getCharacters(int subjectId) async {
    try {
      final data = await _source.fetchSubjectCharacters(subjectId);
      return data
          .whereType<Map>()
          .map((item) => AnimeRelatedInfoModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StaffInfoModel>> getStaff(int subjectId) async {
    try {
      final data = await _source.fetchSubjectStaff(subjectId);
      return data
          .whereType<Map>()
          .map((item) => StaffInfoModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CharacterInfoModel?> getCharacterInfo(int characterId) async {
    try {
      final json = await _source.fetchCharacterInfo(characterId);
      if (json == null) {
        return null;
      }
      return CharacterInfoModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<CharacterTeasingModel>> getCharacterComments(int characterId) async {
    try {
      final data = await _source.fetchCharacterComments(characterId);
      return data
          .whereType<Map>()
          .map((item) => CharacterTeasingModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PersonInfoModel?> getPersonInfo(int personId) async {
    try {
      final json = await _source.fetchPersonInfo(personId);
      if (json == null) {
        return null;
      }
      return PersonInfoModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<PersonTeasingModel>> getPersonComments(int personId) async {
    try {
      final data = await _source.fetchPersonComments(personId);
      return data
          .whereType<Map>()
          .map((item) => PersonTeasingModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CommentItem>> getSubjectComments(
    int subjectId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _source.fetchSubjectComments(
        subjectId,
        limit: limit,
        offset: offset,
      );

      return data
          .whereType<Map>()
          .map((item) => CommentItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
