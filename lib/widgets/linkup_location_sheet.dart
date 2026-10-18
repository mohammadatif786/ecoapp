import 'package:flutter/material.dart';

class LinkupLocation {
  final String city;
  final String region;
  final String country;
  final String flag;

  const LinkupLocation({
    required this.city,
    required this.region,
    required this.country,
    required this.flag,
  });

  String get title => city;
  String get subtitle => region.isEmpty ? country : '$region, $country';
  String get label => flag.endsWith('.png') ? '$city, $country' : '$city, $country $flag';
}

class LinkupLocationService {
  static final ValueNotifier<LinkupLocation> selected = ValueNotifier<LinkupLocation>(
    const LinkupLocation(city: 'The Valley', region: 'Anguilla', country: 'Anguilla', flag: 'assets/ai.png'),
  );

  static const List<LinkupLocation> locations = <LinkupLocation>[
    LinkupLocation(city: 'The Valley', region: 'Anguilla', country: 'Anguilla', flag: 'assets/ai.png'),
    LinkupLocation(city: "St. John's", region: 'Saint John', country: 'Antigua & Barbuda', flag: 'assets/ag.png'),
    LinkupLocation(city: 'Oranjestad', region: 'Aruba', country: 'Aruba', flag: 'assets/aw.png'),
    LinkupLocation(city: 'Nassau', region: 'New Providence', country: 'Bahamas', flag: 'assets/bs.png'),
    LinkupLocation(city: 'Freeport', region: 'Grand Bahama', country: 'Bahamas', flag: 'assets/bs.png'),
    LinkupLocation(city: 'Bridgetown', region: 'Saint Michael', country: 'Barbados', flag: 'assets/bb.png'),
    LinkupLocation(city: 'Kralendijk', region: 'Bonaire', country: 'Bonaire', flag: 'assets/bq.png'),
    LinkupLocation(city: 'Road Town', region: 'Tortola', country: 'British Virgin Islands', flag: 'assets/vg.png'),
    LinkupLocation(city: 'George Town', region: 'Grand Cayman', country: 'Cayman Islands', flag: 'assets/ky.png'),
    LinkupLocation(city: 'Havana', region: 'La Habana', country: 'Cuba', flag: 'assets/cu.png'),
    LinkupLocation(city: 'Roseau', region: 'Saint George', country: 'Dominica', flag: 'assets/dm.png'),
    LinkupLocation(city: 'Santo Domingo', region: 'Distrito Nacional', country: 'Dominican Republic', flag: 'assets/do.png'),
    LinkupLocation(city: 'St. George\'s', region: 'Saint George', country: 'Grenada', flag: 'assets/gd.png'),
    LinkupLocation(city: 'Kingston', region: 'Surrey', country: 'Jamaica', flag: 'assets/jm.png'),
    LinkupLocation(city: 'Montego Bay', region: 'Saint James', country: 'Jamaica', flag: 'assets/jm.png'),
    LinkupLocation(city: 'San Juan', region: 'Puerto Rico', country: 'Puerto Rico', flag: 'assets/pr.png'),
    LinkupLocation(city: 'Castries', region: 'Castries', country: 'Saint Lucia', flag: 'assets/lc.png'),
    LinkupLocation(city: 'Port of Spain', region: 'Trinidad', country: 'Trinidad & Tobago', flag: 'assets/tt.png'),
    LinkupLocation(city: 'Miami', region: 'Florida', country: 'United States', flag: 'assets/us.png'),
  ];

  static void setLocation(LinkupLocation location) {
    selected.value = location;
  }

  static Future<LinkupLocation?> showPicker(BuildContext context) {
    return showModalBottomSheet<LinkupLocation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final maxHeight = media.size.height * 0.88;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, -10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Location', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text(
                            'LinkUp is geo-aware — distance, events & sellers tune to where you are.',
                            style: TextStyle(color: Color(0xddffffff), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final current = selected.value;
                    Navigator.of(sheetContext).pop(current);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xff2f9bef), borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('Use my current location', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ValueListenableBuilder<LinkupLocation>(
                  valueListenable: selected,
                  builder: (_, current, __) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                      itemCount: locations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final item = locations[index];
                        final isSelected = item.city == current.city && item.country == current.country;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setLocation(item);
                            Navigator.of(sheetContext).pop(item);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xffeff6ff) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? const Color(0xff60a5fa) : const Color(0xffe8eef6), width: isSelected ? 1.4 : 1),
                            ),
                            child: Row(
                              children: [
                                if (item.flag.endsWith('.png'))
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.asset(item.flag, width: 30, height: 22, fit: BoxFit.cover),
                                  )
                                else
                                  Text(item.flag, style: const TextStyle(fontSize: 21)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.city, style: const TextStyle(color: Color(0xff111827), fontSize: 15, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 2),
                                      Text(item.subtitle, style: const TextStyle(color: Color(0xff8aa0bc), fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                if (isSelected) const Icon(Icons.check_rounded, color: Color(0xff2f9bef), size: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LinkupLocationBar extends StatelessWidget {
  final double height;
  final double horizontalPadding;
  final double iconSize;
  final double fontSize;
  final double changeFontSize;
  final FontWeight fontWeight;
  final Color iconColor;
  final Color textColor;
  final Color changeColor;
  final Color backgroundColor;
  final Border? border;
  final bool dense;
  final EdgeInsetsGeometry? margin;

  const LinkupLocationBar({
    super.key,
    this.height = 30,
    this.horizontalPadding = 16,
    this.iconSize = 16,
    this.fontSize = 12,
    this.changeFontSize = 12,
    this.fontWeight = FontWeight.w900,
    this.iconColor = const Color(0xff2f9bef),
    this.textColor = const Color(0xff26364d),
    this.changeColor = const Color(0xff168eea),
    this.backgroundColor = Colors.white,
    this.border,
    this.dense = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => LinkupLocationService.showPicker(context),
      child: Container(
        height: height,
        margin: margin,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(color: backgroundColor, border: border),
        child: ValueListenableBuilder<LinkupLocation>(
          valueListenable: LinkupLocationService.selected,
          builder: (_, location, __) {
            return Row(
              children: [
                Icon(Icons.location_on_outlined, color: iconColor, size: iconSize),
                SizedBox(width: dense ? 6 : 8),
                Expanded(
                  child: Row(
                    children: [
                      if (location.flag.endsWith('.png')) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.asset(location.flag, width: 22, height: 16, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          location.flag.endsWith('.png') ? '${location.city}, ${location.country}' : location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: TextStyle(color: changeColor, fontSize: changeFontSize, fontWeight: FontWeight.w900),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
