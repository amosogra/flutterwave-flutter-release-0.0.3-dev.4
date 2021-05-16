import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave/models/requests/mpesa/mpesa_request.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/utils/flutterwave_urls.dart';
import 'package:http/http.dart' as http;

class MpesaPaymentManager {
  String publicKey;
  String currency;
  String amount;
  String txRef;
  bool isDebugMode;
  String phoneNumber;
  String serverlessUrl;
  String fullName;
  String email;
  String? redirectUrl;

  /// MpesaPaymentManager constructor.
  MpesaPaymentManager(
      {required this.publicKey,
      required this.isDebugMode,
      required this.amount,
      required this.currency,
      required this.email,
      required this.txRef,
      required this.fullName,
      required this.phoneNumber,
      required this.serverlessUrl,
      this.redirectUrl});

  /// Converts instance of MpesaPaymentManager to a map
  Map<String, dynamic> toJson() {
    return {
      'amount': this.amount,
      'currency': this.currency,
      'email': this.email,
      'tx_ref': this.txRef,
      'fullname': this.fullName,
      'phone_number': this.phoneNumber,
    };
  }

  /// Initiates payments via Mpesa
  /// Available for only payments with KES currency
  /// returns an instance of ChargeResponse or throws an error
  Future<ChargeResponse> payWithMpesa(MpesaRequest mpesaPayload, http.Client client) async {
    final url = FlutterwaveURLS.getBaseUrl(this.isDebugMode) + FlutterwaveURLS.PAY_WITH_MPESA;
    final requestBody = mpesaPayload.toJson();

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
        throw Exception('Error executing Mpesa transaction: ${response.statusCode} - ${response.reasonPhrase}');
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
