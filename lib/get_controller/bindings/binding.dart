import 'package:get/get.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/base_controller.dart';
import 'package:link_up/get_controller/call_controller.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/get_controller/map_controller.dart';
import 'package:link_up/get_controller/payment_controller.dart';
import 'package:link_up/get_controller/events_controller.dart';
import 'package:link_up/get_controller/news_controller.dart';
import 'package:link_up/get_controller/event_booking_controller.dart';
import 'package:link_up/get_controller/social_controller.dart';
import 'package:link_up/get_controller/live_controller.dart';
import 'package:link_up/get_controller/notifications_controller.dart';
import 'package:link_up/get_controller/nightlife_controller.dart';

class InitBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BaseController(), tag: BaseController().toString());
    Get.put(AuthController(), tag: AuthController().toString());
    Get.put(HomeController(), tag: HomeController().toString());
    Get.put(ChatController(), tag: ChatController().toString());
    Get.put(CallController(), tag: CallController().toString());
    Get.put(PaymentController(), tag: PaymentController().toString());
    Get.put(MapController(), tag: MapController().toString());
    Get.put(EventsController());
    Get.put(NewsController());
    Get.put(EventBookingController());
    Get.put(SocialController());
    Get.put(LiveController());
    Get.put(NotificationsController());
    Get.put(NightlifeController());
  }
}
