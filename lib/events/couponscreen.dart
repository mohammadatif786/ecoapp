// ignore_for_file: unnecessary_statements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart';
import 'package:link_up/events/TicketType.dart';
import 'package:link_up/events/getcontroller.dart';
import 'package:link_up/events/ticketcontroller.dart';

class CouponScreen extends StatefulWidget {
  String? id;
  CouponScreen({Key? key, this.id}) : super(key: key);

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  String? code;
  String? discount;
  TicketController ticketController = Get.put(TicketController());

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  EventController entcontroller = Get.put(EventController());
  String? discountcode;
  @override
  void initState() {
    print('not null');
    var _collection1 = FirebaseFirestore.instance
        .collection('coupons')
        .where('ticket_id', isEqualTo: ticketController.ticketId.value);

    // Get the data from the collection
    _collection1.get().then((snapshot) {
      print(snapshot.docs.length);
      if (snapshot.docs.length == 0) {
        print('no coupon');
      } else if (snapshot.docs.length > 1) {
        print('more than one coupon');
      }
      snapshot.docs.forEach((doc) {
        print(doc.data());
        print('ode ' + doc.data()['code']);
        if (doc.data()['code'] == '') {
          print('empty');
        } else {
          print('agya');

          ticketController.discountcode.value = doc.data()['code'];
          print('casdsa' + doc.data()['code']);

          print('yrs' + ticketController.discountcode.value);
        }
        // entcontroller.discountcode.value = doc.data()['code'];
        // if (doc.data()['discount_type'] == "amount") {
        //   entcontroller.discount!.value = doc.data()['discount'];
        //   entcontroller.percentage!.value = '';
        // } else if (doc.data()['discount_type'] == "percentage") {
        //   entcontroller.percentage!.value = doc.data()['discount'];
        //   entcontroller.discount!.value = '';
        //   print('percentage');
        //   print(entcontroller.percentage!.value);
        // }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/Group 163959 (2).jpg"),
                      fit: BoxFit.cover)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 35, left: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Available Coupon",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        // Text(id.toString())
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/Rectangle.png",
                    height: 30,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Get 10% OFF up to \$100",
                    style: TextStyle(
                        fontFamily: "OpenSans",
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "In case the cashback is not credited within stipulatedtimeline, please contact 0120-4456-456",
                    style: TextStyle(
                        fontFamily: "OpenSans",
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    children: [
                      // Image.asset(
                      //   "assets/VIP.png",
                      //   height: 40,
                      // ),
                      Container(
                        height: 45,
                        width: 120,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.yellow, width: 2),
                            borderRadius: BorderRadius.circular(7)),
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          controller: entcontroller.codecONTROLLER.value,
                          onChanged: (value) {
                            setState(() {
                              value = entcontroller.codecONTROLLER.value.text;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      ticketController.discountcode.value == ''
                          ? Text('Loading...')
                          : Obx(() => InkWell(
                              onTap: () {
                                ticketController.discountavailable.value = true;
                                Get.to(() => TicketType());
                              },
                              child: ticketController.discountcode.value ==
                                      entcontroller.codecONTROLLER.value.text
                                  ? Container(
                                      child: Image.asset(
                                      "assets/Economy.png",
                                      height: 40,
                                    ))
                                  : Text('Please Apply Coupon')))
                    ],
                  ),
                  // Text(codeController.text),
                  SizedBox(
                    height: 35,
                  ),
                  Image.asset(
                    "assets/Rectangle (1).png",
                    height: 30,
                  ),
                  Text(
                    "Cashback using CityBank",
                    style: TextStyle(
                        fontFamily: "OpenSans",
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text(
                    "applicable with Paytm wallet.Paytm cashback will becredited in your wallet within 24 hours of ordercompletion In casse the cashback is no...",
                    style: TextStyle(
                        fontFamily: "OpenSans",
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/VIP (1).png",
                        height: 40,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Image.asset(
                        "assets/Economy.png",
                        height: 40,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
