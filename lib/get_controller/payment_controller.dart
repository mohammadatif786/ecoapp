import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/app_config.dart';
import 'package:link_up/model/subscription_model.dart';
import 'package:link_up/ui/home_page.dart';

class PaymentController extends GetxController {
  RxBool isLoading = false.obs;

  void changeLoadingStatus(bool value) {
    isLoading.value = value;
    update();
  }

  purchaseAndPay({
    required String packageID,
    required String price,
    required BuildContext context,
    required String userID,
    required String duration,
    required String customerId, // signature same rakha taake callers na toote
  }) async {
    changeLoadingStatus(true);
    final transaction = FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('transaction')
        .doc();

    try {
      final url = Uri.parse('https://your-api.com/api/YOUR_ENDPOINT');
      final amountInCents = (double.parse(price) * 100).round();

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInCents,
          'currency': App.currency,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] != true || data['client_secret'] == null) {
        throw Exception(data['message'] ?? 'Payment intent failed');
      }

      await transaction.set({
        "intent": {
          "payment_intent_id": data['payment_intent_id'],
          "customer_id": data['customer_id'],
          "amount": data['amount'],
          "currency": data['currency'],
        },
        "status": "pending",
      });

      Stripe.publishableKey = data['publishableKey'];
      await Stripe.instance.applySettings();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['client_secret'],
          merchantDisplayName: "LinkUp",
          customerId: data['customer_id'],
          customerEphemeralKeySecret: data['ephemeralKey'],
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await transaction.update({"status": "success"});

      final subscription = Subscription(
        packageId: packageID,
        transactionId: transaction.id,
        userId: userID,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
        expiry: DateTime.now()
            .add(Duration(days: int.parse(duration) * 30))
            .millisecondsSinceEpoch,
      );
      await addSubscription(userID, subscription);

      final authController =
          Get.find<AuthController>(tag: AuthController().toString());
      authController.getUser(userID, context);

      changeLoadingStatus(false);
      Get.offAll(HomePage());
    } catch (e) {
      changeLoadingStatus(false);

      final cancelled =
          e is StripeException && e.error.code == FailureCode.Canceled;
      await transaction.set({"status": cancelled ? "cancelled" : "failed"},
          SetOptions(merge: true));

      final msg = e is StripeException
          ? (e.error.localizedMessage ?? 'Something went wrong!')
          : 'Payment failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> addSubscription(String userID, Subscription subscription) async {
    await FirebaseFirestore.instance.collection('users').doc(userID).update({
      "subscription": FieldValue.arrayUnion([subscription.toJson()])
    });
  }
}
