import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class DioClient {
  static Dio? _instance;
  static Dio get instance => _instance ??= _create();

  static Dio _create() {
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    return dio;
  }
}
