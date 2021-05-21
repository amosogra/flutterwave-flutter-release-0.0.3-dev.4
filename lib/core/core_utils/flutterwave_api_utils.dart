import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutterwave/core/flutterwave_error.dart';
import 'package:flutterwave/core/metrics/metric_manager.dart';
import 'package:flutterwave/models/bank.dart';
import 'package:flutterwave/models/requests/charge_card/validate_charge_request.dart';
import 'package:flutterwave/models/requests/verify_charge_request.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/utils/flutterwave_urls.dart';
import 'package:http/http.dart' as http;

/// Flutterwave Utility class
class FlutterwaveAPIUtils {
  /// This method fetches a list of Nigerian banks
  /// it returns an instance of GetBanksResponse or throws an error
  static Future<List<Bank>> getBanks(final http.Client client, String serverlessUrl) async {
    final url = "https://api.flutterwave.com/v3/banks/NG";
    final headers = {HttpHeaders.authorizationHeader: "Bearer FLWSECK_TEST-SANDBOXDEMOKEY-X", HttpHeaders.contentTypeHeader: 'application/json'};
    var payload = {'url': url, 'headers': headers, 'method': 'GET'};

    try {
      http.Response response;
      if (!kIsWeb) {
        response = await client.get(Uri.parse(url), headers: headers);
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }

      if (response.statusCode == 200) {
        final List<dynamic> banks = jsonDecode(response.body)["data"];
        final result = banks.map((e) => Bank.fromJson(e)).toList();
        return result;
      } else {
        throw (FlutterWaveError("Unable to fetch banks. Please contact support"));
      }
    } catch (error) {
      throw (FlutterWaveError(error.toString()));
    } finally {
      client.close();
    }
  }

  /// Validates payments with OTP
  /// returns an instance of ChargeResponse or throws an error
  static Future<ChargeResponse> validatePayment(
      String otp, String flwRef, http.Client client, String serverlessUrl, final bool isDebugMode, final String publicKey, final isBankAccount,
      [String feature = ""]) async {
    final stopWatch = Stopwatch();

    final url = FlutterwaveURLS.getBaseUrl(isDebugMode) + FlutterwaveURLS.VALIDATE_CHARGE;
    final ValidateChargeRequest chargeRequest = ValidateChargeRequest(otp, flwRef, isBankAccount);

    final requestPayload = chargeRequest.toJson();
    final headers = {HttpHeaders.authorizationHeader: publicKey};
    var payload = {'url': url, 'headers': headers, 'body': requestPayload};

    try {
      http.Response response;
      if (!kIsWeb) {
        response = await client.post(Uri.parse(url), headers: headers, body: jsonEncode(requestPayload));
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw Exception('Error verifying Bank Transfer transaction: ${response.statusCode} - ${response.reasonPhrase}');
      }

      if (feature.isNotEmpty) {
        MetricManager.logMetric(client, publicKey, feature, "${stopWatch.elapsedMilliseconds}ms");
      }
      final ChargeResponse cardResponse = ChargeResponse.fromJson(jsonDecode(response.body));
      return cardResponse;
    } catch (error) {
      if (feature.isNotEmpty) {
        MetricManager.logMetric(client, publicKey, "{$feature}_ERROR", "${stopWatch.elapsedMilliseconds}ms");
      }
      throw (FlutterWaveError(error.toString()));
    }
  }

  /// Verifies payments with Flutterwave reference
  /// returns an instance of ChargeResponse or throws an error
  static Future<ChargeResponse> verifyPayment(final String flwRef, final http.Client client, final String publicKey, String serverlessUrl, final bool isDebugMode,
      [String feature = ""]) async {
    final stopWatch = Stopwatch();

    final url = FlutterwaveURLS.getBaseUrl(isDebugMode) + FlutterwaveURLS.VERIFY_TRANSACTION;
    final VerifyChargeRequest verifyRequest = VerifyChargeRequest(flwRef);

    final requestPayload = verifyRequest.toJson();
    final headers = {HttpHeaders.authorizationHeader: publicKey};
    var payload = {'url': url, 'headers': headers, 'body': requestPayload};

    try {
      stopWatch.start();
      http.Response response;
      if (!kIsWeb) {
        response = await client.post(Uri.parse(url), headers: headers, body: jsonEncode(requestPayload));
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }
      stopWatch.stop();
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw Exception('Error verifying Bank Transfer transaction: ${response.statusCode} - ${response.reasonPhrase}');
      }

      final ChargeResponse cardResponse = ChargeResponse.fromJson(jsonDecode(response.body));
      if (feature.isNotEmpty) {
        MetricManager.logMetric(client, publicKey, feature, "${stopWatch.elapsedMilliseconds}ms");
      }
      return cardResponse;
    } catch (error) {
      if (feature.isNotEmpty) {
        MetricManager.logMetric(client, publicKey, "{$feature}_ERROR", "${stopWatch.elapsedMilliseconds}ms");
      }
      throw (FlutterWaveError(error.toString()));
    }
  }
}
