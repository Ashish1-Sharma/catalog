import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiResponse {
  final int statusCode;
  final String message;
  final dynamic body;
  final bool isSuccess;

  ApiResponse({
    required this.statusCode,
    required this.message,
    this.body,
    required this.isSuccess,
  });
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiResponse _parseResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final statusCode = data['statusCode'] is int
          ? data['statusCode'] as int
          : (response.statusCode ?? 500);
      final message = data['message']?.toString() ?? 'Unknown response';
      final body = data['body'];

      bool isSuccess = statusCode >= 200 && statusCode < 300;
      if (body is Map<String, dynamic> && body.containsKey('error')) {
        if (body['error'] == true) {
          isSuccess = false;
        }
      }

      return ApiResponse(
        statusCode: statusCode,
        message: message,
        body: body,
        isSuccess: isSuccess,
      );
    }

    return ApiResponse(
      statusCode: response.statusCode ?? 500,
      message: 'Invalid response format',
      body: data,
      isSuccess: false,
    );
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response!.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        final statusCode = data['statusCode'] is int ? data['statusCode'] as int : (error.response!.statusCode ?? 400);
        final message = data['message']?.toString() ?? error.message ?? 'Request failed';
        return ApiResponse(
          statusCode: statusCode,
          message: message,
          body: data['body'],
          isSuccess: false,
        );
      }
      return ApiResponse(
        statusCode: error.response?.statusCode ?? 500,
        message: error.message ?? 'Network error occurred',
        isSuccess: false,
      );
    }
    return ApiResponse(
      statusCode: 500,
      message: error.toString(),
      isSuccess: false,
    );
  }

  /// POST registration.php
  Future<ApiResponse> register({
    required String userName,
    required String userEmail,
    required String userMobile,
    String countryCode = '+91',
    String country = 'India',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registrationEndpoint,
        data: {
          'userName': userName,
          'userEmail': userEmail,
          'userMobile': userMobile,
          'countryCode': countryCode,
          'country': country,
        },
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST login.php
  Future<ApiResponse> login({
    required String userEmail,
    required String userMobile,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'userEmail': userEmail,
          'userMobile': userMobile,
        },
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET check_status.php?user_id={id}
  Future<ApiResponse> checkStatus({required int userId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.checkStatusEndpoint,
        queryParameters: {'user_id': userId},
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST update_purchase.php
  Future<ApiResponse> updatePurchase({
    required int userId,
    required String planCode,
    required String purchaseId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.updatePurchaseEndpoint,
        data: {
          'user_id': userId,
          'plan_code': planCode,
          'purchase_id': purchaseId,
        },
      );
      return _parseResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}
