import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';

abstract class DetailRemoteDataSource {
  Future<List<dynamic>> getCharacters(int id);
  Future<Map<String, dynamic>> getStaff(int id);
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
}
