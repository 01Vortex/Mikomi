import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';

abstract class DetailRemoteDataSource {
  Future<List<dynamic>> getCharacters(int id);
  Future<Map<String, dynamic>> getStaff(int id);
  Future<Map<String, dynamic>> getCharacterDetail(int characterId);
  Future<List<dynamic>> getCharacterComments(int characterId);
  Future<Map<String, dynamic>> getPersonDetail(int personId);
  Future<List<dynamic>> getPersonComments(int personId);
}

class DetailRemoteDataSourceImpl implements DetailRemoteDataSource {
  final DioClient _dioClient;

  DetailRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<dynamic>> getCharacters(int id) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiDomain}/v0/subjects/{0}/characters',
      [id],
    );

    final response = await _dioClient.get(url);
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getStaff(int id) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/staffs/persons',
      [id],
    );

    final response = await _dioClient.get(url);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getCharacterDetail(int characterId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}',
      [characterId],
    );

    final response = await _dioClient.get(url);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getCharacterComments(int characterId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}/comments',
      [characterId],
    );

    final response = await _dioClient.get(url);
    return response.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPersonDetail(int personId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}',
      [personId],
    );

    final response = await _dioClient.get(url);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getPersonComments(int personId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}/comments',
      [personId],
    );

    final response = await _dioClient.get(url);
    return response.data as List<dynamic>;
  }
}
