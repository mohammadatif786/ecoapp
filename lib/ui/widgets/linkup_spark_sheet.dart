import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/model/user_model.dart';

class _VibeGift {
  final String label;
  final String emoji;
  final int cost;
  final String tagline;

  const _VibeGift(this.label, this.emoji, this.cost, this.tagline);
}

class LinkUpSparkSheet extends StatefulWidget {
  final UserModel user;
  final int coins;
  final Future<void> Function(String label, String emoji, int cost)? onSend;

  const LinkUpSparkSheet({
    Key? key,
    required this.user,
    required this.coins,
    this.onSend,
  }) : super(key: key);

  static const gifts = <_VibeGift>[
    _VibeGift('Wha Gwaan', '👋', 0, 'Just saying hi 👋'),
    _VibeGift('Likkle Smile', '😊', 10, 'A sweet island smile'),
    _VibeGift('Soca Vibe', '🎶', 35, 'Feel the riddim with me'),
    _VibeGift('Wine & Dance', '💃', 50, 'Pull up and wine 💃'),
    _VibeGift('Sunset Lime', '🌅', 75, 'Catch a sunset together'),
    _VibeGift('Coconut Cheers', '🥥', 90, 'Cheers from the islands'),
    _VibeGift('Island Rose', '🌹', 120, 'A rose, respectfully 🌹'),
    _VibeGift('Sweet Kiss', '😘', 150, 'Flirty but classy'),
    _VibeGift('Candlelit Date', '🕯️', 220, 'Dinner by candlelight'),
    _VibeGift('Beach Linkup', '🏝️', 250, 'Link up by the sea'),
    _VibeGift('Sweetheart', '💖', 300, 'I really like you 💖'),
    _VibeGift('Island Royalty', '👑', 400, 'You\'re my King/Queen 👑'),
  ];

  @override
  State<LinkUpSparkSheet> createState() => _LinkUpSparkSheetState();
}

class _LinkUpSparkSheetState extends State<LinkUpSparkSheet> {
  int? _selected;
  bool _sending = false;

  String get _name {
    final name = widget.user.firstName.trim();
    return name.isNotEmpty ? name : 'them';
  }

  String _formatCoins(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected == null ? null : LinkUpSparkSheet.gifts[_selected!];
    final canSend = selected != null && selected.cost <= widget.coins && !_sending;
    final after = selected == null ? null : (widget.coins - selected.cost);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [Color(0xfffff1f2), Color(0xfffff7ed), Color(0xffffffff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌹', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send a Vibe',
                              style: TextStyle(
                                color: Color(0xff0f2744),
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send $_name a gift — they earn the coins 💰',
                              style: const TextStyle(
                                color: Color(0xff8b99b2),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.close, size: 18, color: Color(0xff64748b)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff2f9bef),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatCoins(widget.coins)} Coins',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Pick a gift',
                        style: TextStyle(color: Color(0xff0f2744), fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                itemCount: LinkUpSparkSheet.gifts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 198,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final gift = LinkUpSparkSheet.gifts[index];
                  final selectedCard = _selected == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = index),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selectedCard ? const Color(0xff2f9bef) : const Color(0xffe8edf5),
                          width: selectedCard ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Color(0xfff3e8ff), shape: BoxShape.circle),
                            child: Text(gift.emoji, style: const TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gift.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xff142035)),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 34,
                            child: Text(
                              gift.tagline,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xff8b99b2), fontWeight: FontWeight.w600, height: 1.2),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: gift.cost == 0 ? const Color(0xffffe14d) : const Color(0xff2f9bef),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: gift.cost == 0
                                ? const Text('Free', style: TextStyle(color: Color(0xff142035), fontWeight: FontWeight.w900, fontSize: 13))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link, color: Colors.white, size: 13),
                                      const SizedBox(width: 4),
                                      Text('${gift.cost}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSend
                      ? () async {
                          setState(() => _sending = true);
                          try {
                            await widget.onSend?.call(
                              selected.label,
                              selected.emoji,
                              selected.cost,
                            );
                            if (mounted) Get.back();
                          } catch (e) {
                            if (mounted) setState(() => _sending = false);
                            Get.snackbar('Gift failed', e.toString());
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2f9bef),
                    disabledBackgroundColor: const Color(0xffc5d8ea),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                children: [
                  _summary('Selected', selected?.label ?? '—'),
                  _summary('Cost', selected == null ? '—' : (selected.cost == 0 ? 'Free' : '${selected.cost}')),
                  _summary('After', after == null ? '—' : _formatCoins(after)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value) {
    return Expanded(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xff8b99b2), fontSize: 13, fontWeight: FontWeight.w700)),
            TextSpan(text: value, style: const TextStyle(color: Color(0xff142035), fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
