import 'package:dio/dio.dart';
import 'package:beyblade_x_collection/core/constants/app_constants.dart';
import 'package:beyblade_x_collection/data/models/parts_database.dart';

class RemoteDatasource {
  final Dio _dio;

  RemoteDatasource({Dio? dio}) : _dio = dio ?? Dio();

  Future<PartsDatabase?> fetchDatabase() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.remoteDbUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.data != null) {
        return PartsDatabase.fromJson(response.data!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
