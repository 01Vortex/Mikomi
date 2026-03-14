import 'package:mikomi/core/models/character_item.dart';
import 'package:mikomi/core/models/character_detail.dart';
import 'package:mikomi/core/models/character_comment.dart';
import 'package:mikomi/core/models/person_detail.dart';
import 'package:mikomi/core/models/person_comment.dart';
import 'package:mikomi/core/models/staff_item.dart';
import 'package:mikomi/features/anime/data/datasources/detail_remote_datasource.dart';
import 'package:mikomi/features/anime/domain/repositories/detail_repository.dart';

class DetailRepositoryImpl implements DetailRepository {
  final DetailRemoteDataSource _remoteDataSource;

  DetailRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CharacterItem>> getCharacters(int id) async {
    try {
      final data = await _remoteDataSource.getCharacters(id);
      return data
          .map((item) => CharacterItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<StaffItem>> getStaff(int id) async {
    try {
      final data = await _remoteDataSource.getStaff(id);
      final staffList = data['data'] as List?;
      if (staffList == null) return [];

      return staffList
          .map((item) => StaffItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<CharacterDetail?> getCharacterDetail(int characterId) async {
    try {
      final data = await _remoteDataSource.getCharacterDetail(characterId);
      return CharacterDetail.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<CharacterComment>> getCharacterComments(int characterId) async {
    try {
      final data = await _remoteDataSource.getCharacterComments(characterId);
      return data
          .map(
            (item) => CharacterComment.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PersonDetail?> getPersonDetail(int personId) async {
    try {
      final data = await _remoteDataSource.getPersonDetail(personId);
      return PersonDetail.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PersonComment>> getPersonComments(int personId) async {
    try {
      final data = await _remoteDataSource.getPersonComments(personId);
      return data
          .map((item) => PersonComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
