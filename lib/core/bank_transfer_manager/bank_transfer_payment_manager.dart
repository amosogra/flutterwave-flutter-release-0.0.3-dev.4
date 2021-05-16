import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave/core/flutterwave_error.dart';
import 'package:flutterwave/models/requests/bank_transfer/bank_transfer_request.dart';
import 'package:flutterwave/models/requests/verify_charge_request.dart';
import 'package:flutterwave/models/responses/bank_transfer_response/bank_transfer_response.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/utils/flutterwave_urls.dart';
import 'package:http/http.dart' as http;

class BankTransferPaymentManager {
  String publicKey;
  String currency;
  String amount;
  String email;
  String txRef;
  bool isDebugMode;
  String phoneNumber;
  String serverlessUrl;
  int? frequency;
  int? duration;
  String? narration;
  bool? isPermanent;
  String? redirectUrl;

  /// Bank Transfer Payment Manager Constructor
  /// This is responsible for creating instances of BankTransferPaymentManager
  BankTransferPaymentManager(
      {required this.publicKey,
      required this.currency,
      required this.amount,
      required this.email,
      required this.txRef,
      required this.isDebugMode,
      required this.phoneNumber,
      required this.serverlessUrl,
      required this.frequency,
      required this.narration,
      this.duration,
      this.isPermanent,
      this.redirectUrl});

  /// Resposnsible for making payments with bank transfer
  /// it returns a bank transfer response or throws an error
  Future<BankTransferResponse> payWithBankTransfer(BankTransferRequest bankTransferRequest, http.Client client) async {
    final requestBody = bankTransferRequest.toJson();
    final url = FlutterwaveURLS.getBaseUrl(this.isDebugMode) + FlutterwaveURLS.BANK_TRANSFER;
    final headers = {HttpHeaders.authorizationHeader: this.publicKey};
    var payload = {'url': url, 'headers': headers, 'body': requestBody};

    try {
      http.Response response;
      if (!kIsWeb) {
        response = await client.post(Uri.parse(url), headers: headers, body: jsonEncode(requestBody));
      } else {
        response = await client.post(Uri.parse(serverlessUrl), headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: jsonEncode(payload));
      }

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw Exception('Error executing Bank Transfer transaction: ${response.statusCode} - ${response.reasonPhrase}');
      }

      BankTransferResponse bankTransferResponse = BankTransferResponse.fromJson(json.decode(response.body));

      return bankTransferResponse;
    } catch (error) {
      throw (FlutterError(error.toString()));
    }
  }

  /// Responsible for verifying payments made with bank transfers
  /// it returns an instance of ChargeResponse or throws an error
  Future<ChargeResponse> verifyPayment(final String flwRef, final http.Client client) async {
    final url = FlutterwaveURLS.getBaseUrl(this.isDebugMode) + FlutterwaveURLS.VERIFY_TRANSACTION;
    final VerifyChargeRequest verifyRequest = VerifyChargeRequest(flwRef);
    final requestPayload = verifyRequest.toJson();
    final headers = {HttpHeaders.authorizationHeader: this.publicKey, HttpHeaders.contentTypeHeader: "application/json"};
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

      final ChargeResponse cardResponse = ChargeResponse.fromJson(jsonDecode(response.body));
      return cardResponse;
    } catch (error) {
      throw (FlutterWaveError(error.toString()));
    }
  }
}
