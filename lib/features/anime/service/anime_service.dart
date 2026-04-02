import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/core/network/app_api.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/anime/models/anime_related_info_model.dart';
import 'package:mikomi/features/anime/models/anime_teasing_model.dart';
import 'package:mikomi/features/anime/models/character_info_model.dart';
import 'package:mikomi/features/anime/models/character_teasing_model.dart';
import 'package:mikomi/features/anime/models/person_info_model.dart';
import 'package:mikomi/features/anime/models/person_teasing_model.dart';
import 'package:mikomi/features/anime/models/staff_info_model.dart';
import 'package:mikomi/features/anime/repository/anime_repository.dart';

class AnimeService {
  final AnimeRepository _repository;
  final DioClient _dioClient;

  AnimeService({AnimeRepository? repository, DioClient? dioClient})
    : _repository = repository ?? AnimeRepository(),
      _dioClient = dioClient ?? DioClient();

  Future<Anime?> getAnimeDetailById(int id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/$id',
      );

      if (response.data != null) {
        return Anime.fromJson(response.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<AnimeRelatedInfoModel>> getCharacters(int subjectId) {
    return _repository.getCharacters(subjectId);
  }

  Future<List<StaffInfoModel>> getStaff(int subjectId) {
    return _repository.getStaff(subjectId);
  }

  Future<CharacterInfoModel?> getCharacterInfo(int characterId) {
    return _repository.getCharacterInfo(characterId);
  }

  Future<List<CharacterTeasingModel>> getCharacterComments(int characterId) {
    return _repository.getCharacterComments(characterId);
  }

  Future<PersonInfoModel?> getPersonInfo(int personId) {
    return _repository.getPersonInfo(personId);
  }

  Future<List<PersonTeasingModel>> getPersonComments(int personId) {
    return _repository.getPersonComments(personId);
  }

  Future<List<CommentItem>> getSubjectComments(
    int subjectId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getSubjectComments(
      subjectId,
      limit: limit,
      offset: offset,
    );
  }
}
