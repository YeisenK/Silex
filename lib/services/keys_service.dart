import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';

class KeysService {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  /// uploads the key bundle to the backend then calls the post
  static Future<void> uploadKeys(Map<String, dynamic> keyBundle) async {
    final token = await StorageService.getJwt();

    await _dio.post(
      '/keys',
      data: {
        'identityKey': keyBundle['identityKey'],
        'signedPrekey': keyBundle['signedPrekey'],
        'signedPrekeySignature': keyBundle['signedPrekeySignature'],
        'signedPrekeyId': keyBundle['signedPrekeyId'],
        'oneTimePrekeys': keyBundle['oneTimePrekeys'],
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  /// GET /keys/:userId 
  static Future<Map<String, dynamic>> getKeyBundle(String userId) async {
    final token = await StorageService.getJwt();
    final response = await _dio.get(
      '/keys/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data as Map<String, dynamic>;
  }

}