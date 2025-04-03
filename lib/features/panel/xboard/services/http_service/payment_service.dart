import 'dart:io';

import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  /// Submits an order for checkout.
  ///
  /// For mobile (iOS/Android) and desktop (macOS/Windows), a deep link is
  /// provided as the return URL (e.g., "hiddify://order/{tradeNo}"). For web,
  /// this remains null so that the backend can build the return URL based on
  /// the HTTP origin.
  Future<Map<String, dynamic>> submitOrder(
    String tradeNo,
    String method,
    String accessToken,
  ) async {
    String? customReturnUrl;
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS || Platform.isWindows) {
      customReturnUrl = "hiddify://order/$tradeNo";
    } else {
      // For web or unsupported platforms, let the backend handle the return URL.
      customReturnUrl = null;
    }

    return await _httpService.postRequest(
      "/api/v1/user/order/checkout",
      {
        "trade_no": tradeNo,
        "method": method,
        "return_url": customReturnUrl, // Deep link for mobile & desktop; null for web.
      },
      headers: {'Authorization': accessToken},
    );
  }

  /// Retrieves available payment methods.
  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    final response = await _httpService.getRequest(
      "/api/v1/user/order/getPaymentMethod",
      headers: {'Authorization': accessToken},
    );
    return (response['data'] as List).cast<dynamic>();
  }
}
