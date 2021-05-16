import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave/models/requests/ussd/ussd_request.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/utils/flutterwave_urls.dart';
import 'package:http/http.dart' as http;

class USSDPaymentManager {
  String publicKey;
  String currency;
  String amount;
  String email;
  String txRef;
  bool isDebugMode;
  String phoneNumber;
  String serverlessUrl;
  String fullName;
  String? redirectUrl;

  /// USSDPaymentManager constructor
  /// Available for only payments with NGN currency
  /// returns an instance of USSDPaymentManager
  USSDPaymentManager(
      {required this.publicKey,
      required this.currency,
      required this.amount,
      required this.email,
      required this.txRef,
      required this.isDebugMode,
      required this.phoneNumber,
      required this.serverlessUrl,
      required this.fullName,
      this.redirectUrl});

  /// Initiates payments via USSD
  /// Available for only payments with NGN currency
  /// returns an instance of ChargeResponse or throws an error
  Future<ChargeResponse> payWithUSSD(USSDRequest ussdRequest, http.Client client) async {
    final requestBody = ussdRequest.toJson();
    final url = FlutterwaveURLS.getBaseUrl(isDebugMode) + FlutterwaveURLS.PAY_WITH_USSD;
    final headers = {HttpHeaders.authorizationHeader: this.publicKey, HttpHeaders.contentTypeHeader: "application/json"};
    var payload = {'url': url, 'headers': headers, 'body': requestBody};

    try {
      http.Response response;
      if (!kIsWeb) {
        response = await client.post(Uri.parse(url), headers: headers, body: jsonEncode(requestBody));
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw Exception('Error executing USSD transaction: ${response.statusCode} - ${response.reasonPhrase}');
      }

      ChargeResponse chargeResponse = ChargeResponse.fromJson(json.decode(response.body));
      return chargeResponse;
    } catch (error) {
      throw (FlutterError(error.toString()));
    } finally {
      client.close();
    }
  }
}
