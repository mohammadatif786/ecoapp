import 'package:link_up/model/user_model.dart';

/// Prints swipe-card debug info to the `flutter run` terminal.
/// Every line is prefixed with [tag] so you can filter: `flutter run | grep SWIPE_CONSOLE`
class SwipeConsoleLog {
  static const tag = 'SWIPE_CONSOLE';

  static void _line(String message) {
    // ignore: avoid_print
    print('$tag|$message');
  }

  static void printCards(List<dynamic> cards, {String? source}) {
    final src = source ?? 'unknown';
    _line('BEGIN|$src|count=${cards.length}');
    if (cards.isEmpty) {
      _line('EMPTY|no users in swipe stack');
      _line('END|$src');
      return;
    }
    for (var i = 0; i < cards.length; i++) {
      final data = cards[i];
      if (data is UserModel) {
        final name = '${data.firstName} ${data.lastName}'.trim();
        final label = name.isEmpty ? (data.uid ?? '?') : name;
        final img = data.cardImageUrl.isNotEmpty ? 'img_ok' : 'no_img';
        _line(
          '[$i]|$label|uid=${data.uid}|apiId=${data.laravelId}|$img|age=${data.age}|gender=${data.gender}',
        );
        if (data.cardImageUrl.isNotEmpty) {
          _line('[$i]|url=${data.cardImageUrl}');
        }
      } else {
        _line('[$i]|AD|$data');
      }
    }
    _line('END|$src');
  }
}
