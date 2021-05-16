import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave/core/metrics/metric_manager.dart';
import 'package:flutterwave/models/requests/pay_with_bank_account/pay_with_bank_account.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/utils/flutterwave_urls.dart';
import 'package:http/http.dart' as http;

class BankAccountPaymentManager {
  String publicKey;
  String currency;
  String amount;
  String email;
  String txRef;
  bool isDebugMode;
  String phoneNumber;
  String serverlessUrl;
  String? accountBank;
  String? accountNumber;
  String fullName;
  String? redirectUrl;

  Stopwatch? stopWatch;

  /// BankAccountPaymentManager constructor
  /// Available for only payments with NGN currency
  BankAccountPaymentManager({
    required this.publicKey,
    required this.currency,
    required this.amount,
    required this.email,
    required this.txRef,
    required this.isDebugMode,
    required this.phoneNumber,
    required this.serverlessUrl,
    required this.fullName,
    this.accountBank,
    this.accountNumber,
    this.redirectUrl,
  });

  /// Initiates payments via Bank Account
  /// Available for only payments with NGN currency
  /// returns an instance of ChargeResponse or throws an error
  Future<ChargeResponse> payWithAccount(BankAccountPaymentRequest bankAccountRequest, http.Client client) async {
    stopWatch = Stopwatch();
    final requestBody = bankAccountRequest.toJson();
    final url = FlutterwaveURLS.getBaseUrl(this.isDebugMode) + FlutterwaveURLS.PAY_WITH_ACCOUNT;

    final headers = {HttpHeaders.authorizationHeader: this.publicKey, HttpHeaders.contentTypeHeader: "application/json"};
    var payload = {'url': url, 'headers': headers, 'body': requestBody};

    stopWatch?.start();
    try {
      http.Response response;
      if (!kIsWeb) {
        response = await client.post(Uri.parse(url), headers: headers, body: jsonEncode(requestBody));
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw Exception('Error executing Bank Account transaction: ${response.statusCode} - ${response.reasonPhrase}');
      }

      MetricManager.logMetric(client, publicKey, MetricManager.INITIATE_ACCOUNT_CHARGE, "${stopWatch?.elapsedMilliseconds}ms");

      ChargeResponse bankTransferResponse = ChargeResponse.fromJson(json.decode(response.body));

      return bankTransferResponse;
    } catch (error) {
      MetricManager.logMetric(client, publicKey, MetricManager.INITIATE_ACCOUNT_CHARGE_ERROR, "${stopWatch?.elapsedMilliseconds}ms");
      throw (FlutterError(error.toString()));
    } finally {
      stopWatch?.stop();
    }
  }
}
