// ignore_for_file: non_constant_identifier_names, unused_field, unused_element, must_be_immutable, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/events/couponscreen.dart';
import 'package:link_up/events/getcontroller.dart';
import 'package:link_up/events/ticketcontroller.dart';

class TicketType extends StatefulWidget {
  String? ticket_id;
  String? title;
  String? description;
  String? start_time;
  Timestamp? end_time;
  String? country;
  String? state;
  String? venue;
  String? uid;
  String? disclaimer;
  String? organizer;
  String? economy;
  String? vip_price;
  double? fees;

  Uint8List? image;
  String? discount;
  String? category;
  String? momo;
  String? dicountcode;
  TicketType({
    this.ticket_id,
    this.momo,
    this.category,
    this.discount,
    this.image,
    this.vip_price,
    this.fees,
    this.economy,
    this.organizer,
    this.disclaimer,
    this.title,
    this.description,
    this.end_time,
    this.start_time,
    this.country,
    this.state,
    this.venue,
    this.uid,
    this.dicountcode,
  });

  @override
  State<TicketType> createState() => _TicketTypeState();
}

class _TicketTypeState extends State<TicketType> {
  TicketController ticketController = Get.put(TicketController());

  List earlybirdcheck = [];
  int earlybirdchecknew = 0;
  late final _subscription2;
  late final _subscription;
  String? pop = '';
  int? discountt = 0;
  int? vip = 0;
  int? ecnmy;
  int? butn = 0;
  int? equal = 0;
  double? equal2;
  double? fee;
  double? tax1;
  String? total;
  String? tax = "7.5";
  int? tax3 = 0;
  String? resultfes;
  double? total1 = 0.0;
  int? total2 = 0;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? button;
  String? dropdownvalue;
  String? dropdownvalue2;
  EventController entcontroller = Get.put(EventController());
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late var _collection;
  String ticketId = '';

  void getearlybrddata() {
    _subscription2 = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.uid)
        .get()
        .then((value) {
      print('talha value hai yeh');
      print(value['early_bird_price_date_limit']);
      if (value['early_bird_price_date_limit'].runtimeType == Timestamp) {
        setState(() {
          earlybirdchecknew =
              value['early_bird_price_date_limit'].compareTo(Timestamp.now());
        });

        print(earlybirdchecknew);
      }
    });
  }

  getcoupondata() async {
    _collection = FirebaseFirestore.instance
        .collection('tickets')
        .where('event_id', isEqualTo: widget.uid)
        .snapshots()
        .listen((event) {
      event.docs.forEach((element) async {
        entcontroller.ticketid!.value = element.id;
        print(entcontroller.ticketid!.value);
        var collection = await FirebaseFirestore.instance
            .collection('coupons')
            .where('ticket_id', isEqualTo: entcontroller.ticketid!.value)
            .get();
        collection.docs.forEach((element) {
          print(element.data());
        });
      });
    });
  }

  void getticketdata() {
    print('ticket id');
    print(ticketController.ticketId.value);
    ticketId = ticketController.ticketId.value;
  }

  @override
  void initState() {
    getticketdata();
    getearlybrddata();
    getcoupondata();
    ticketController.getprices(ticketId);

    super.initState();
  }

  @override
  void dispose() {
    entcontroller.ticketid = ''.toString().obs;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TicketController ticketController = Get.put(TicketController());

    var appSize = MediaQuery.of(context).size;
    var appSize2 = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0.0,
        flexibleSpace: FlexibleSpaceBar(
          background: Image.asset(
            'assets/image/bacgroundlinkup.png',
            fit: BoxFit.fill,
          ),
        ),
        leadingWidth: 20,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 50, left: 10),
          child: Icon(Icons.menu),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 50, left: 10),
          child: Text('Ticket Type'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SizedBox(height: 20),
            (earlybirdchecknew == 1)
                ? Column(
                    children: [
                      Obx(
                        () => TicketTypeContainer(
                            ticketname: 'Early Bird General Tickets   \$' +
                                ticketController.earlybirdpriceorignal.value
                                    .toString(),
                            Price: ticketController.earlybirdpricenew.value,
                            fee: ticketController.feeearlybirdgeneralnew.value,
                            tax: ticketController.earlybirdtaxnew.value,
                            saleendmessage: 'Sales end on Jan 7, 2023',
                            color: Color.fromARGB(
                              253,
                              56,
                              171,
                              216,
                            ),
                            description:
                                'This RSVP guarantees entrance to The Shrine before 11pm.',
                            onTapincrement: (() =>
                                ticketController.incrementearlygeneral()),
                            onTapdecrement: (() =>
                                ticketController.decrementearlygeneral()),
                            counter: ticketController.counterearlygeneral),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Obx(
                        () => TicketTypeContainer(
                          ticketname: 'Early Bird VIP      \$' +
                              ticketController.earlybirdvippriceorignal.value
                                  .toString(),
                          Price: ticketController.earlybirdvippricenew.value,
                          fee: ticketController.feeearlybirdvipnew.value,
                          tax: ticketController.earlybirdviptaxnew.value,
                          saleendmessage: 'Sales end on Jan 7, 2023',
                          description: 'This Ticket is a VIP seating Ticket',
                          color: Color.fromARGB(253, 56, 171, 216),
                          onTapincrement: () =>
                              ticketController.incrementearlyvip(),
                          onTapdecrement: () =>
                              ticketController.decrementearlyvip(),
                          counter: ticketController.counterearlyvip,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Obx(
                        () => TicketTypeContainer(
                          ticketname: 'VIP     \$' +
                              ticketController.vippriceorignal.value.toString(),
                          Price: ticketController.vippricenew.value,
                          fee: ticketController.feevipnew.value,
                          tax: ticketController.viptaxnew.value,
                          saleendmessage: '',
                          description: 'This is a VIP seating Ticket ',
                          color: Color.fromARGB(253, 56, 171, 216),
                          onTapincrement: () => ticketController.incrementvip(),
                          onTapdecrement: () => ticketController.decrementvip(),
                          counter: ticketController.countervip,
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Obx(
                        () => TicketTypeContainer(
                          ticketname: 'General Admission   \$' +
                              ticketController.generalpriceorignal.value
                                  .toString(),
                          Price: ticketController.generalpricenew.value,
                          fee: ticketController.feegeneralnew.value,
                          tax: ticketController.generaltaxnew.value,
                          saleendmessage: '',
                          description:
                              'This Ticket is for General admission only',
                          color: Color.fromARGB(255, 213, 220, 22),
                          onTapincrement: () =>
                              ticketController.incrementgeneral(),
                          onTapdecrement: () =>
                              ticketController.decrementgeneral(),
                          counter: ticketController.countergeneral,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Get.to(() => CouponScreen());
                  },
                  child: smallContainer(
                      'Event Coupon',
                      Color.fromARGB(255, 213, 220, 22),
                      Image.asset(
                        'assets/image/arrowgreen.png',
                        height: 20,
                      )),
                ),
                smallContainer(
                    'Pay From wallet ',
                    Color.fromARGB(255, 56, 171, 216),
                    Image.asset(
                      'assets/image/arrowblue.png',
                      height: 20,
                    )),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Obx(
              () => Center(
                child: ticketController.discountavailable.value.toString() ==
                        true.toString()
                    ? Column(
                        children: [
                          Text(
                            'Discount Applied',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 110, 110, 110)),
                          ),
                          Obx(() => ticketController.amounthai.value == true
                              ? Center(
                                  child: Text(
                                    'Discount Amount: \$' +
                                        ticketController.dicountamount.value
                                            .toStringAsFixed(2),
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Color.fromARGB(255, 110, 110, 110)),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'Discount Percentage: ' +
                                        ticketController.dicountpercentage
                                            .toStringAsFixed(2) +
                                        ' %',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Color.fromARGB(255, 110, 110, 110)),
                                  ),
                                ))
                        ],
                      )
                    : Text(
                        'Discount Not Applied',
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110)),
                      ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ticketController.discountavailable.value == true
                ? SizedBox(
                    height: 20,
                  )
                : SizedBox(
                    height: 0,
                  ),
            earlybirdchecknew == 1
                ? Obx(
                    () => Center(
                      child: Text(
                        'Total Price without Tax:  \$' +
                            ticketController.Pricettotalfordiscountearly.value
                                .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110)),
                      ),
                    ),
                  )
                : Obx(
                    () => Center(
                      child: Text(
                        'Total Price without Tax: \$' +
                            ticketController.totalpricewithouttaxgenreral.value
                                .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110)),
                      ),
                    ),
                  ),
            SizedBox(
              height: 20,
            ),
            earlybirdchecknew == 1
                ? Obx(
                    () => Center(
                      child: Text(
                        'Total Price after Discount: \$' +
                            ticketController.priceafterdiscountearly.value
                                .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110)),
                      ),
                    ),
                  )
                : Obx(
                    () => Center(
                      child: Text(
                        'Total Price after Discount \$' +
                            ticketController.priceafterdiscountgenral.value
                                .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110)),
                      ),
                    ),
                  ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: Obx(() => Text(
                    earlybirdchecknew == 1
                        ? ticketController.counterearlyvip.value == 0 &&
                                ticketController.counterearlygeneral.value == 0
                            ? 'Total   \$ 0.0 '
                            : 'Total   \$' +
                                ticketController.totalearlyticket.value
                                    .toStringAsFixed(2)
                        : ticketController.countergeneral.value == 0 &&
                                ticketController.countervip.value == 0
                            ? 'Total   \$ 0.0 '
                            : 'Total  \$ ' +
                                ticketController.totalgeneralticket.value
                                    .toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 110, 110, 110)),
                  )),
            ),
            SizedBox(
              height: 20,
            ),
            earlybirdchecknew == 1
                ? Obx(() => ticketController.counterearlyvip.value == 0 &&
                        ticketController.counterearlygeneral.value == 0
                    ? Center(
                        child: Text(
                          'Please add a Ticket First',
                          style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 56, 171, 216),
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : Center(
                        child: Container(
                          height: 40,
                          width: 170,
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 213, 220, 22),
                              borderRadius: BorderRadius.circular(6)),
                          child: Center(
                            child: Text(
                              'Checkout',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ))
                : Obx(
                    () => ticketController.countergeneral.value == 0 &&
                            ticketController.countervip.value == 0
                        ? Center(
                            child: Text(
                              'Please add a Ticket First',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 56, 171, 216),
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              print(ticketController.generaltotaldiscout.value);
                              ticketController.post(
                                discount:
                                    ticketController.generaltotaldiscout.value,
                                total:
                                    ticketController.totalgeneralticket.value,
                                tax: ticketController.generaltaxnew.value,
                                subtotal: ticketController
                                    .totalpricewithouttaxgenreral.value,
                                event_id: widget.uid,
                                ticket_type: 'VIP',
                                nooftickets: ticketController.countervip.value
                                    .toString(),
                              );
                            },
                            child: Center(
                              child: Container(
                                height: 40,
                                width: 170,
                                decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 213, 220, 22),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Center(
                                  child: Text(
                                    'Checkout',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}

Container smallContainer(
  String text,
  Color color,
  Image image,
) {
  return Container(
    height: 40,
    width: 170,
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          text,
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        image,
      ],
    ),
  );
}

class TicketTypeContainer extends StatefulWidget {
  TicketTypeContainer(
      {required this.ticketname,
      required this.saleendmessage,
      required this.description,
      required this.color,
      required this.onTapincrement,
      required this.onTapdecrement,
      required this.counter,
      required this.Price,
      required this.fee,
      required this.tax});
  String ticketname;

  String saleendmessage;
  String description;
  Color color;
  RxInt counter;
  void Function()? onTapincrement;
  void Function()? onTapdecrement;
  double Price;
  double fee;
  double tax;

  @override
  State<TicketTypeContainer> createState() => _TicketTypeContainerState();
}

class _TicketTypeContainerState extends State<TicketTypeContainer> {
  GetxController ticketcontroller = Get.put(TicketController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
            border: Border.all(color: widget.color),
            color: Colors.white,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                widget.ticketname,
                style: TextStyle(
                    fontSize: 20,
                    color: widget.color,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              height: 40,
              color: widget.color,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(children: [
                        Text(
                          '\$' + widget.Price.toString(),
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+ \$' + widget.fee.toString() + ' Fee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' + \$' + widget.tax.toString() + ' Tax',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                    InkWell(
                      onTap: widget.onTapdecrement,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(255, 219, 239, 246),
                            borderRadius: BorderRadius.circular(6)),
                        child: Center(
                          child: Text(
                            '-',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Obx(
                      () => Text(
                        widget.counter.toString(),
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    InkWell(
                      onTap: widget.onTapincrement,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(255, 219, 239, 246),
                            borderRadius: BorderRadius.circular(6)),
                        child: Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.saleendmessage,
                  style: TextStyle(
                    color: Color.fromARGB(255, 110, 110, 110),
                    fontSize: 16,
                  )),
            ),
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.description,
                  style: TextStyle(
                    color: Color.fromARGB(255, 110, 110, 110),
                    fontSize: 12,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
