import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/features/anime/models/anime_related_info_model.dart';
import 'package:mikomi/features/anime/models/character_info_model.dart';
import 'package:mikomi/features/anime/models/character_teasing_model.dart';
import 'package:mikomi/features/anime/models/person_info_model.dart';
import 'package:mikomi/features/anime/models/person_teasing_model.dart';
import 'package:mikomi/features/anime/models/staff_info_model.dart';

class BangumiDetail {
  final DioClient _dioClient = DioClient();

  Future<List<AnimeRelatedInfoModel>> getCharacters(int id) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/{0}/characters',
        [id],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map((item) => AnimeRelatedInfoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<StaffInfoModel>> getStaff(int id) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/staffs/persons',
        [id],
      );

      final response = await _dioClient.get(url);
      final data = response.data as Map<String, dynamic>;
      final staffList = data['data'] as List?;
      if (staffList == null) return [];

      return staffList
          .map((item) => StaffInfoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<CharacterInfoModel?> getCharacterInfoModel(int characterId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}',
        [characterId],
      );

      final response = await _dioClient.get(url);
      return CharacterInfoModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<CharacterTeasingModel>> getCharacterTeasingModels(int characterId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}/comments',
        [characterId],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map(
            (item) => CharacterTeasingModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PersonInfoModel?> getPersonInfoModel(int personId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}',
        [personId],
      );

      final response = await _dioClient.get(url);
      return PersonInfoModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<PersonTeasingModel>> getPersonTeasingModels(int personId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}/comments',
        [personId],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map((item) => PersonTeasingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
