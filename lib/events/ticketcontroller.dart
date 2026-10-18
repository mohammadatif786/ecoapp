// ignore_for_file: unrelated_type_equality_checks, non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TicketController extends GetxController {
  RxString ticketId = "".obs;
  RxBool ticketavailable = false.obs;
  RxBool amounthai = false.obs;
  RxBool percentagehai = false.obs;
  RxDouble dicountamount = 0.0.obs;
  RxDouble dicountpercentage = 0.0.obs;
  RxDouble priceafterdiscountgenral = 0.0.obs;
  RxDouble priceafterdiscountearly = 0.0.obs;

  RxInt countervip = 0.obs;
  RxInt countergeneral = 0.obs;
  RxInt counterearlyvip = 0.obs;
  RxInt counterearlygeneral = 0.obs;

  RxDouble earlybirdpriceorignal = 0.0.obs;
  RxDouble generalpriceorignal = 0.0.obs;
  RxDouble earlybirdvippriceorignal = 0.0.obs;
  RxDouble vippriceorignal = 0.0.obs;
  RxDouble earlybirdpricenew = 0.0.obs;
  RxDouble generalpricenew = 0.0.obs;
  RxDouble earlybirdvippricenew = 0.0.obs;
  RxDouble vippricenew = 0.0.obs;

  RxDouble earlybirdtax = 12.0.obs;
  RxDouble generaltax = 12.0.obs;
  RxDouble earlybirdviptax = 12.0.obs;
  RxDouble viptax = 12.0.obs;

  RxDouble earlybirdtaxnew = 0.0.obs;
  RxDouble generaltaxnew = 0.0.obs;
  RxDouble earlybirdviptaxnew = 0.0.obs;
  RxDouble viptaxnew = 0.0.obs;

  RxDouble feeearlybirdgeneralorignal = 7.5.obs;
  RxDouble feegeneralorignal = 7.5.obs;
  RxDouble feeearlybirdviporignal = 7.5.obs;
  RxDouble feeviporignal = 7.5.obs;

  RxDouble feeearlybirdgeneralnew = 0.0.obs;
  RxDouble feegeneralnew = 0.0.obs;
  RxDouble feeearlybirdvipnew = 0.0.obs;
  RxDouble feevipnew = 0.0.obs;

  RxDouble totalgeneral = 0.0.obs;
  RxDouble totalearlygeneral = 0.0.obs;
  RxDouble totalvip = 0.0.obs;
  RxDouble totalearlyvip = 0.0.obs;
  RxDouble totalearlyticket = 0.0.obs;
  RxDouble totalgeneralticket = 0.0.obs;

  RxString discountcode = ''.obs;
  RxBool discountavailable = false.obs;
  RxBool notwaitforcode = false.obs;
  RxDouble Pricettotalfordiscountgeneral = 0.0.obs;
  RxDouble Pricettotalfordiscountearly = 0.0.obs;
  RxDouble totalpricewithouttaxgenreral = 0.0.obs;
  RxDouble totalpricewithouttaxearly = 0.0.obs;
  RxDouble generaltotaldiscout = 0.0.obs;
  totaltaxgeneral() {
    generaltaxnew.value = (totalgeneralticket.value * generaltax.value) / 100;

    update();
  }

  totaldiscount() {
    generaltotaldiscout.value =
        (totalgeneralticket.value * dicountpercentage.value) / 100;
  }

  void getprices(String ticketId) {
    var _subscription = FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .get()
        .then((value) {
      vippriceorignal.value =
          double.parse(int.parse(value['price_vip']).toString());

      generalpriceorignal.value =
          double.parse(int.parse(value['price_economy']).toString());
      earlybirdvippriceorignal.value =
          double.parse(int.parse(value['early_bird_vip_price']).toString());
      earlybirdpriceorignal.value =
          double.parse(int.parse(value['early_bird_economy_price']).toString());
      print('asd');
      var _subscrption2 = FirebaseFirestore.instance
          .collection('events')
          .doc(value['event_id'])
          .get()
          .then((value) {
        print(value['event_fee']);
        feeearlybirdgeneralorignal.value =
            double.parse(int.parse(value['event_fee']).toString());
        feegeneralorignal.value =
            double.parse(int.parse(value['event_fee']).toString());
        feeearlybirdviporignal.value =
            double.parse(int.parse(value['event_fee']).toString());
        feeviporignal.value =
            double.parse(int.parse(value['event_fee']).toString());
      });

      update();
    });
  }

  // increment counter
  void incrementvip() {
    print('vip');
    if (amounthai.value == true) {
      print('calculation for amount hai');
      countervip.value++;
      vippricenew.value = vippriceorignal.value * countervip.value;

      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;
      priceafterdiscountgenral.value =
          totalpricewithouttaxgenreral.value - dicountamount.value;

      feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
      viptaxnew.value = (vippricenew.value * viptax.value) / 100;
      totalvip.value =
          viptaxnew.value + feevipnew.value + priceafterdiscountgenral.value;

      totalgeneralticket.value = totalgeneral.value + totalvip.value;
    } else if (percentagehai.value == true) {
      print('calculation for percentage hai');
      countervip.value++;
      print('lion');
      vippricenew.value = vippriceorignal.value * countervip.value;

      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;

      priceafterdiscountgenral.value = totalpricewithouttaxgenreral.value -
          (totalpricewithouttaxgenreral.value * dicountpercentage.value) / 100;
      feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
      viptaxnew.value = (vippricenew.value * viptax.value) / 100;
      totalvip.value =
          viptaxnew.value + feevipnew.value + priceafterdiscountgenral.value;
      print('hello');
      print(totalvip.value);
      print(totalgeneral.value);
      totalgeneralticket.value = totalgeneral.value + totalvip.value;
    } else {
      countervip.value++;
      vippricenew.value = vippriceorignal.value * countervip.value;
      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;
      feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
      viptaxnew.value = (vippricenew.value * viptax.value) / 100;
      totalvip.value = viptaxnew.value + feevipnew.value + vippricenew.value;
      print('vip' + totalvip.value.toString());
      print('gen' + totalgeneral.value.toString());
      totalgeneralticket.value = totalgeneral.value + totalvip.value;
      print(totalgeneralticket.value);
    }
  }

  void incrementgeneral() {
    if (amounthai == true) {
      print('calculation for amount hai');
      countergeneral.value++;

      generalpricenew.value = generalpriceorignal.value * countergeneral.value;
      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;

      priceafterdiscountgenral.value =
          totalpricewithouttaxgenreral.value - dicountamount.value;
      feegeneralnew.value =
          (generalpricenew.value * feegeneralorignal.value) / 100;
      generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
      totalgeneral.value =
          generaltaxnew.value + feegeneralnew.value + generalpricenew.value;
      totalgeneralticket.value = totalgeneral.value + totalvip.value;
    } else if (percentagehai.value == true) {
      print('calculation for percentage hai');
      countergeneral.value++;

      generalpricenew.value = generalpriceorignal.value * countergeneral.value;
      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;

      priceafterdiscountgenral.value = totalpricewithouttaxgenreral.value -
          (totalpricewithouttaxgenreral.value * dicountpercentage.value) / 100;
      feegeneralnew.value =
          (generalpricenew.value * feegeneralorignal.value) / 100;
      generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
      totalgeneral.value = generaltaxnew.value +
          feegeneralnew.value +
          priceafterdiscountgenral.value;
      print('rana hah');
      print(totalgeneral.value);
      totalgeneralticket.value = totalgeneral.value + totalvip.value;

      print(totalgeneralticket.value);
    } else {
      countergeneral.value++;

      generalpricenew.value = generalpriceorignal.value * countergeneral.value;
      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;
      feegeneralnew.value =
          (generalpricenew.value * feegeneralorignal.value) / 100;
      generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
      totalgeneral.value =
          generaltaxnew.value + feegeneralnew.value + generalpricenew.value;
      totalgeneralticket.value = totalgeneral.value + totalvip.value;
    }
  }

  void incrementearlyvip() {
    if (amounthai.value == true) {
      counterearlyvip.value++;
      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      Pricettotalfordiscountearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;

      priceafterdiscountearly.value =
          Pricettotalfordiscountearly.value - dicountamount.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value = totalearlyticket.value - dicountamount.value;
    } else if (percentagehai.value == true) {
      counterearlyvip.value++;
      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value =
          totalearlyticket.value * (100 - dicountpercentage.value) / 100;
    } else {
      counterearlyvip.value++;
      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      totalpricewithouttaxearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
    }
  }

  void incrementearlygeneral() {
    print('calculation for amount hai early general increment');
    if (amounthai.value == true) {
      counterearlygeneral.value++;
      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;
      Pricettotalfordiscountearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;

      priceafterdiscountearly.value =
          Pricettotalfordiscountearly.value - dicountamount.value;

      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value = totalearlyticket.value - dicountamount.value;
    } else if (percentagehai.value == true) {
      print('calculation for percentage hai early general increment');
      counterearlygeneral.value++;
      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;
      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value =
          totalearlyticket.value * (100 - dicountpercentage.value) / 100;
      print(totalearlyticket.value);
    } else {
      counterearlygeneral.value++;
      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;
      totalpricewithouttaxearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;
      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
    }
  }

  // decrement counter
  void decrementvip() {
    if (amounthai.value == true) {
      if (countervip.value > 0) {
        countervip.value = countervip.value - 1;
        vippricenew.value = vippriceorignal.value * countervip.value;
        totalpricewithouttaxgenreral.value =
            vippricenew.value + generalpricenew.value;

        priceafterdiscountgenral.value =
            totalpricewithouttaxgenreral.value - dicountamount.value;
        feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
        viptaxnew.value = (vippricenew.value * viptax.value) / 100;
        totalvip.value = viptaxnew.value + feevipnew.value + vippricenew.value;

        totalgeneralticket.value = totalgeneral.value + totalvip.value;
      } else {
        totalvip.value = 0.0;
        print('cannot decrement');
      }
    } else if (percentagehai.value == true) {
      if (countervip.value > 0) {
        countervip.value = countervip.value - 1;
        vippricenew.value = vippriceorignal.value * countervip.value;
        totalpricewithouttaxgenreral.value =
            vippricenew.value + generalpricenew.value;

        priceafterdiscountgenral.value = totalpricewithouttaxgenreral.value -
            (totalpricewithouttaxgenreral.value * dicountpercentage.value) /
                100;
        feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
        viptaxnew.value = (vippricenew.value * viptax.value) / 100;
        totalvip.value =
            viptaxnew.value + feevipnew.value + priceafterdiscountgenral.value;
        print('haha');
        print(totalvip.value);
        print(totalgeneral.value);

        totalgeneralticket.value = totalgeneral.value + totalvip.value;
      } else {
        totalvip.value = 0.0;
        print('cannot decrement');
      }
    } else {
      if (countervip.value > 0) {
        countervip.value = countervip.value - 1;
        vippricenew.value = vippriceorignal.value * countervip.value;
        totalpricewithouttaxgenreral.value =
            vippricenew.value + generalpricenew.value;
        feevipnew.value = (vippricenew.value * feeviporignal.value) / 100;
        viptaxnew.value = (vippricenew.value * viptax.value) / 100;
        totalvip.value = viptaxnew.value + feevipnew.value + vippricenew.value;

        totalgeneralticket.value = totalgeneral.value + totalvip.value;
      } else {
        print('cannot decrement');
      }
    }
  }

  void decrementgeneral() {
    if (amounthai.value == true) {
      if (countergeneral.value > 0) {
        countergeneral.value = countergeneral.value - 1;
        generalpricenew.value =
            generalpriceorignal.value * countergeneral.value;
        totalpricewithouttaxgenreral.value =
            vippricenew.value + generalpricenew.value;

        priceafterdiscountgenral.value =
            totalpricewithouttaxgenreral.value - dicountamount.value;
        feegeneralnew.value =
            (generalpricenew.value * feegeneralorignal.value) / 100;
        generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
        totalgeneral.value =
            generaltaxnew.value + feegeneralnew.value + generalpricenew.value;
        totalgeneralticket.value = totalgeneral.value + totalvip.value;
        totalgeneralticket.value =
            totalgeneralticket.value - dicountamount.value;
      } else {
        totalgeneral.value = 0.0;
        print('cannot decrement');
      }
    } else if (percentagehai == true) {
      print('calculation for percentage hai general decrement');
      if (countergeneral.value > 0) {
        countergeneral.value = countergeneral.value - 1;
        generalpricenew.value =
            generalpriceorignal.value * countergeneral.value;
        totalpricewithouttaxgenreral.value =
            vippricenew.value + generalpricenew.value;

        priceafterdiscountgenral.value = totalpricewithouttaxgenreral.value -
            (totalpricewithouttaxgenreral.value * dicountpercentage.value) /
                100;
        feegeneralnew.value =
            (generalpricenew.value * feegeneralorignal.value) / 100;
        generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
        totalgeneral.value = generaltaxnew.value +
            feegeneralnew.value +
            priceafterdiscountgenral.value;
        print('hmmm');
        print(totalgeneral.value);
        print(totalvip.value);
        totalgeneralticket.value = totalgeneral.value + totalvip.value;
        print(totalgeneralticket.value);
        print('sadsad');
      } else {
        totalgeneral.value = 0.0;
        print('cannot decrement');
      }
    } else {
      countergeneral.value > 0
          ? countergeneral.value--
          : print('cannot decrement');
      generalpricenew.value = generalpriceorignal.value * countergeneral.value;
      totalpricewithouttaxgenreral.value =
          vippricenew.value + generalpricenew.value;
      feegeneralnew.value =
          (generalpricenew.value * feegeneralorignal.value) / 100;
      generaltaxnew.value = (generalpricenew.value * generaltax.value) / 100;
      totalgeneral.value =
          generaltaxnew.value + feegeneralnew.value + generalpricenew.value;
      totalgeneralticket.value = totalgeneral.value + totalvip.value;
    }
  }

  void decrementearlyvip() {
    if (amounthai.value == true) {
      print('calculation for amount hai early vip decrement');
      print('hello');
      counterearlyvip.value > 0
          ? counterearlyvip.value--
          : print('cannot decrement');

      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      Pricettotalfordiscountearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;

      priceafterdiscountearly.value =
          Pricettotalfordiscountearly.value - dicountamount.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value = totalearlyticket.value - dicountamount.value;
    } else if (percentagehai.value == true) {
      print('calculation for percentage hai early vip decrement');
      counterearlyvip.value > 0
          ? counterearlyvip.value--
          : print('cannot decrement');

      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value =
          totalearlyticket.value * (100 - dicountpercentage.value) / 100;
    } else {
      counterearlyvip.value > 0
          ? counterearlyvip.value--
          : print('cannot decrement');
      earlybirdvippricenew.value =
          earlybirdvippriceorignal.value * counterearlyvip.value;
      totalpricewithouttaxearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;
      feeearlybirdvipnew.value =
          (earlybirdvippricenew.value * feeearlybirdviporignal.value) / 100;
      earlybirdviptaxnew.value =
          (earlybirdvippricenew.value * earlybirdviptax.value) / 100;
      totalearlyvip.value = earlybirdviptaxnew.value +
          feeearlybirdvipnew.value +
          earlybirdvippricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
    }
  }

  void decrementearlygeneral() {
    print('calculation for amount hai early general decrement');
    if (amounthai.value == true) {
      counterearlygeneral.value > 0
          ? counterearlygeneral.value--
          : print('cannot decrement');

      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;

      Pricettotalfordiscountearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;

      priceafterdiscountearly.value =
          Pricettotalfordiscountearly.value - dicountamount.value;
      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value = totalearlyticket.value - dicountamount.value;
    } else if (percentagehai.value == true) {
      print('calculation for percentage hai early general increment');
      counterearlygeneral.value > 0
          ? counterearlygeneral.value--
          : print('cannot decrement');
      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;
      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
      totalearlyticket.value =
          totalearlyticket.value * (100 - dicountpercentage.value) / 100;
    } else {
      counterearlygeneral.value > 0
          ? counterearlygeneral.value--
          : print('cannot decrement');
      earlybirdpricenew.value =
          earlybirdpriceorignal.value * counterearlygeneral.value;

      totalpricewithouttaxearly.value =
          earlybirdvippricenew.value + earlybirdpricenew.value;

      feeearlybirdgeneralnew.value =
          (earlybirdpricenew.value * feeearlybirdgeneralorignal.value) / 100;
      earlybirdtaxnew.value =
          (earlybirdpricenew.value * earlybirdtax.value) / 100;
      totalearlygeneral.value = earlybirdtaxnew.value +
          feeearlybirdgeneralnew.value +
          earlybirdpricenew.value;
      totalearlyticket.value = totalearlyvip.value + totalearlygeneral.value;
    }
  }

  void getdiscount() {
    // ignore: cancel_subscriptions
    var sub = FirebaseFirestore.instance
        .collection('coupons')
        .where('ticket_id', isEqualTo: ticketId.value)
        .where('code', isEqualTo: discountcode.value)
        .snapshots()
        .listen((event) {
      if (event.docs.length == 1) {
        if (event.docs[0]['discount_type'] == 'percentage') {
          percentagehai.value = true;
          amounthai.value = false;
          dicountpercentage.value =
              double.parse(int.parse(event.docs[0]['discount']).toString());
          print('yeh discount hoga  pertage main ' +
              dicountpercentage.value.toString());
        }
        if (event.docs[0]['discount_type'] == 'amount') {
          print('amount hai ');
          amounthai.value = true;
          percentagehai.value = false;
          dicountamount.value =
              double.parse(int.parse(event.docs[0]['discount']).toString());

          print('yeh discount hoga  ' + dicountamount.value.toString());
        }
      } else if (event.docs.length == 0) {
        print('no coupon');
      } else {
        print('more than one coupon');
      }
    });
  }

  void post(
      {double? discount,
      double? fee,
      double? subtotal,
      double? tax,
      double? total,
      String? transaction_id,
      String? user_id,
      String? event_id,
      String? nooftickets,
      String? ticket_type}) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var data = {
      'created': DateTime.now().microsecondsSinceEpoch,
      'discount': '15.2',
      'fee': '1.2',
      'payment_method': 'cash',
      'event_id': event_id,
      'seat_details': {
        '0': {'nooftickets': '2', 'ticket_type': 'early bird general'}
      },
      'subtotal': subtotal.toString(),
      'tax': tax.toString(),
      'ticket_id': '6167ab6ad71a4053afbe',
      'ticket_status': 'not canceled',
      'total': total.toString(),
      'transaction_id': 'RJWmy5PTN56CbfW7BH5T',
      'user_id': '5PZZFGCFskNJ3OkfXdpLuuxU09w1'
    };
    firestore.collection('ticketSales').add(data).then((value) {
      print(value.id);
    });
  }
}
