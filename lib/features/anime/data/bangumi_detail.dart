import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/character_item.dart';
import 'package:mikomi/core/models/character_detail.dart';
import 'package:mikomi/core/models/character_comment.dart';
import 'package:mikomi/core/models/person_detail.dart';
import 'package:mikomi/core/models/person_comment.dart';
import 'package:mikomi/core/models/staff_item.dart';

class BangumiDetail {
  final DioClient _dioClient = DioClient();

  Future<List<CharacterItem>> getCharacters(int id) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/{0}/characters',
        [id],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map((item) => CharacterItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<StaffItem>> getStaff(int id) async {
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
          .map((item) => StaffItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<CharacterDetail?> getCharacterDetail(int characterId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}',
        [characterId],
      );

      final response = await _dioClient.get(url);
      return CharacterDetail.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<CharacterComment>> getCharacterComments(int characterId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}/comments',
        [characterId],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map(
            (item) => CharacterComment.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PersonDetail?> getPersonDetail(int personId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}',
        [personId],
      );

      final response = await _dioClient.get(url);
      return PersonDetail.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<PersonComment>> getPersonComments(int personId) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}/comments',
        [personId],
      );

      final response = await _dioClient.get(url);
      final data = response.data as List<dynamic>;

      return data
          .map((item) => PersonComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
