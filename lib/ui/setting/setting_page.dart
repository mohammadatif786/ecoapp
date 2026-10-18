import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_up/element/full_screen_image.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/DrawerScreen.dart';
import 'package:link_up/ui/setting/email_setting_page.dart';

import 'package:link_up/widgets/linkup_current_user.dart';
import 'package:link_up/ui/wallet_page.dart';

Future<void> showLinkUpSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

Future<void> showLinkUpSubscriptionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SubscriptionPlansSheet(),
  );
}

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fc),
      drawer: Drawer(child: DrawerScreen()),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)]),
              ),
              child: Row(
                children: [
                  Text('Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                ],
              ),
            ),
            const Expanded(child: _SettingsContent()),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPlansSheet extends StatelessWidget {
  const _SubscriptionPlansSheet();

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.88, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  @override
  Widget build(BuildContext context) {
    return _MiniSheet(
      title: 'Subscription',
      subtitle: 'Choose the plan that fits how you use LinkUp.',
      child: Column(
        children: [
          _plan(context, '🌬️ Brisa', 'Free', 'Current Plan', true),
          _plan(context, '☀️ Calor', '\$4.99/mo', 'Choose Calor', false),
          _plan(context, '🥁 Ritmo', '\$9.99/mo', 'Choose Ritmo', false),
        ],
      ),
    );
  }

  Widget _plan(BuildContext context, String title, String price, String button, bool current) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 16)),
        border: Border.all(color: current ? const Color(0xffe6edf7) : const Color(0xff2f9bef), width: current ? 1 : 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: _font(context, 17), fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(fontSize: _font(context, 28), fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 8),
        ...['Browse events & community feed', 'Create your profile', 'Buy tickets & shop'].map((e) => Padding(
          padding: EdgeInsets.only(bottom: _ui(context, 4)),
          child: Text('✔️ $e', style: TextStyle(color: const Color(0xff40516a), fontSize: _font(context, 13), fontWeight: FontWeight.w600)),
        )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: _ui(context, 42),
          child: ElevatedButton(
            onPressed: current ? null : () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2f9bef),
              disabledBackgroundColor: const Color(0xffeef2f7),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 12))),
            ),
            child: Text(button, style: TextStyle(color: current ? const Color(0xff697990) : Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.91),
      decoration: const BoxDecoration(
        color: Color(0xffeef6ff),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ],
            ),
          ),
          const Expanded(child: _SettingsContent()),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  final ImagePicker _picker = ImagePicker();
  bool _push = false;
  bool _notifyMatches = true;
  bool _notifyMessages = true;
  bool _notifyGifts = true;
  bool _notifyOrders = true;
  bool _notifyPayments = true;
  bool _notifyTickets = true;
  bool _notifyLive = true;
  bool _notifyDelivery = true;
  bool _notifySystem = true;

  bool _matching = true;
  bool _active = true;
  bool _receipts = true;
  bool _location = true;
  bool _ads = true;
  bool _pin = true;
  bool _biometric = false;
  bool _2fa = false;
  bool _darkMode = false;
  String _language = 'English';
  String _locationName = 'Anguilla';
  bool _newsTicker = true;

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.88, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        final auth = Get.find<AuthController>(tag: AuthController().toString());
        if (auth.user != null) {
          auth.user!.value.avatar = picked.path;
          auth.update();
        }
        Get.snackbar(
          'Profile Photo',
          'Avatar updated locally! (Upload to server not implemented)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff2f9bef),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        setState(() {});
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  void _showImageSourceModal(BuildContext context) {
    final avatarUrl = LinkUpCurrentUser.avatarUrl();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniSheet(
        title: 'Profile Photo',
        subtitle: 'Update your public avatar',
        icon: Icons.camera_alt_rounded,
        child: Column(
          children: [
            if (avatarUrl.isNotEmpty)
              _row(context, 'View Profile Photo', value: 'Preview', onTap: () {
                Navigator.pop(context);
                Get.to(() => FullScreenImage(imageURL: avatarUrl, tag: 'profile_avatar'));
              }),
            _row(context, 'Take Photo', value: 'Camera', onTap: () {
              Navigator.pop(context);
              _pickAvatar(ImageSource.camera);
            }),
            _row(context, 'Choose from Gallery', value: 'Photos', onTap: () {
              Navigator.pop(context);
              _pickAvatar(ImageSource.gallery);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 14), _ui(context, 12), _ui(context, 24)),
      children: [
        _profileRow(context),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'ACCOUNT', [
          _row(context, 'Personal Information', onTap: () => _showPersonalInformation(context)),
          _row(context, 'Subscription', value: 'Brisa', onTap: () => _showSubscription(context)),
          _row(context, 'Payment Methods', onTap: () => _showPaymentMethods(context)),
          _row(context, 'Advertise My Business', onTap: () => _showBusinessAds(context)),
          _row(context, 'Verification', value: 'Not verified', onTap: () => _showVerification(context)),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'NOTIFICATIONS', [
          _toggleRow(context, 'Push notifications', 'Master switch for all alerts', _push, (v) => setState(() => _push = v)),
          if (_push) ...[
            _toggleRow(context, 'Matches', '', _notifyMatches, (v) => setState(() => _notifyMatches = v)),
            _toggleRow(context, 'Messages', '', _notifyMessages, (v) => setState(() => _notifyMessages = v)),
            _toggleRow(context, 'Gifts', '', _notifyGifts, (v) => setState(() => _notifyGifts = v)),
            _toggleRow(context, 'Marketplace Orders', '', _notifyOrders, (v) => setState(() => _notifyOrders = v)),
            _toggleRow(context, 'Payments', '', _notifyPayments, (v) => setState(() => _notifyPayments = v)),
            _toggleRow(context, 'Tickets', '', _notifyTickets, (v) => setState(() => _notifyTickets = v)),
            _toggleRow(context, 'Live', '', _notifyLive, (v) => setState(() => _notifyLive = v)),
            _toggleRow(context, 'Delivery', '', _notifyDelivery, (v) => setState(() => _notifyDelivery = v)),
            _toggleRow(context, 'System', '', _notifySystem, (v) => setState(() => _notifySystem = v)),
          ],
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'PRIVACY & SAFETY', [
          _toggleRow(context, 'Show me on LinkUp (matching)', 'Appear in dating / swipe', _matching, (v) => setState(() => _matching = v)),
          _toggleRow(context, 'Active status', 'Show when you’re online', _active, (v) => setState(() => _active = v)),
          _toggleRow(context, 'Read receipts', '', _receipts, (v) => setState(() => _receipts = v)),
          _toggleRow(context, 'Share my location', 'Used for distance, events & delivery', _location, (v) => setState(() => _location = v)),
          _toggleRow(context, 'Personalized ads', '', _ads, (v) => setState(() => _ads = v)),
          _row(context, 'Blocked accounts', onTap: () => _showBlocked(context)),
          _row(context, 'Who can message me', value: 'Everyone', onTap: () {}),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'IDENTITY VERIFICATION (KYC)', [
          _row(context, 'Verify my identity', value: 'Not verified', onTap: () => _showVerification(context)),
          Padding(
            padding: EdgeInsets.only(bottom: _ui(context, 8), top: _ui(context, 4)),
            child: Text(
              'Required to send/withdraw money, sell, and get the verified badge.\nUpload a photo ID and take a selfie.',
              style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'SECURITY', [
          _toggleRow(context, 'Face ID / biometric unlock', '', _biometric, (v) => setState(() => _biometric = v)),
          _toggleRow(context, 'Two-factor authentication', '', _2fa, (v) => setState(() => _2fa = v)),
          _row(context, 'Change password', onTap: () {}),
          _row(context, 'Active sessions', value: '2 devices', onTap: () => _showSimpleInfo(context, 'Login devices', 'iPhone 15 Pro · active now\nChrome Desktop · 3 hours ago')),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'PREFERENCES', [
          _row(context, 'Language', value: _language, onTap: () => _showLanguageSheet(context)),
          _row(context, 'Currency', value: 'USD (B\$)', onTap: () {}),
          _row(context, 'Region / Country', value: _locationName, onTap: () => _showLocationSheet(context)),
          _toggleRow(context, 'Dark mode', '', _darkMode, (v) => setState(() => _darkMode = v)),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'HOME & NEWS', [
          _toggleRow(context, 'Breaking news ticker', 'Show the scrolling headline strip on Home', _newsTicker, (v) => setState(() => _newsTicker = v)),
          _row(context, 'News I want to see', value: 'All countries', onTap: () => _showFeedPreferencesSheet(context)),
        ]),
        SizedBox(height: _ui(context, 12)),
        _section(context, 'SUPPORT & LEGAL', [
          _row(context, 'Help & Support', onTap: () => _showHelpSupport(context)),
          _row(context, 'Contact Us', onTap: () => _showContactUs(context)),
          _row(context, 'Legal Center', onTap: () => _showLegalCenter(context)),
          _row(context, 'Terms of Service', onTap: () => _showTerms(context)),
          _row(context, 'Privacy Policy', onTap: () => _showPrivacy(context)),
          _row(context, 'App Version', value: 'v1.0.0', onTap: () {}),
        ]),
        SizedBox(height: _ui(context, 16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: _ui(context, 54),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xffdc2626),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_ui(context, 16)),
                      side: const BorderSide(color: Color(0xfffecaca), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _confirmDeleteAccount(context),
                child: Text('Delete my account', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceModal(context),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: LinkUpCurrentUser.avatarProvider(),
              backgroundColor: const Color(0xfff0f4f8),
            ),
          ),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      LinkUpCurrentUser.fullName(),
                      style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showPersonalInformation(context),
                      child: Icon(Icons.edit_outlined, size: _ui(context, 15), color: const Color(0xff1d63ff)),
                    ),
                  ],
                ),
                Text(
                  '@${LinkUpCurrentUser.firstName().toLowerCase()} · Brisa plan',
                  style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 4)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 7)),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String title, {String? value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: _ui(context, 12)),
        child: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14), fontWeight: FontWeight.w900))),
            if (value != null) Text(value, style: TextStyle(color: const Color(0xff9aa8ba), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
            SizedBox(width: _ui(context, 4)),
            Icon(Icons.chevron_right_rounded, color: const Color(0xff9aa8ba), size: _ui(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _ui(context, 8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xff2f9bef),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xffdfe6ef),
          ),
        ],
      ),
    );
  }

  Widget _destructiveRow(BuildContext context) {
    return const SizedBox.shrink();
  }

  void _showPersonalInformation(BuildContext context) {
    final name = TextEditingController(text: LinkUpCurrentUser.fullName());
    final bio = TextEditingController(text: 'Caribbean explorer & vibe seeker.');
    final job = TextEditingController(text: 'Marketing');
    final country = TextEditingController(text: 'Bahamas');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _MiniSheet(
          title: 'Profile Information',
          subtitle: 'Update your public identity on LinkUp.',
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceModal(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: LinkUpCurrentUser.avatarProvider(),
                        backgroundColor: const Color(0xfff0f4f8),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xff2f9bef), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _field(context, 'Display Name', name),
              _field(context, 'Biography', bio, lines: 3),
              _field(context, 'Job / Profession', job),
              _field(context, 'Roots / Country', country),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSubscription(BuildContext context) {
    showLinkUpSubscriptionSheet(context);
  }

  void _showPaymentMethods(BuildContext context) {
    Get.to(() => const WalletPage());
  }

  void _showBusinessAds(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdvertisePlansSheet(),
    );
  }

  void _showVerification(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _IdentityVerificationSheet(),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _MiniSheet(
          title: 'Language',
          subtitle: '',
          child: Column(
            children: [
              _selectRow(context, 'English', '🇬🇧', _language == 'English', () {
                setSheetState(() => _language = 'English');
                setState(() {});
              }),
              _selectRow(context, 'Español', '🇪🇸', _language == 'Español', () {
                setSheetState(() => _language = 'Español');
                setState(() {});
              }),
              _selectRow(context, 'Português', '🇧🇷', _language == 'Português', () {
                setSheetState(() => _language = 'Português');
                setState(() {});
              }),
              _selectRow(context, 'Kreyòl Ayisyen', '🇭🇹', _language == 'Kreyòl Ayisyen', () {
                setSheetState(() => _language = 'Kreyòl Ayisyen');
                setState(() {});
              }),
              _selectRow(context, 'Français', '🇫🇷', _language == 'Français', () {
                setSheetState(() => _language = 'Français');
                setState(() {});
              }),
              const SizedBox(height: 12),
              const Text(
                'LinkUp serves the Caribbean & Latin America in English, Español, Português, Kreyòl & Français.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _MiniSheet(
          title: 'Your Location',
          subtitle: 'LinkUp is geo-aware — distance, events & sellers tune to where you are.',
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.explore_outlined, color: Colors.white, size: 20),
                  label: const Text('Use my current location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2f9bef),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...[
                {'name': 'The Valley', 'sub': 'Anguilla, Anguilla', 'flag': '🇦🇮'},
                {'name': "St. John's", 'sub': 'Saint John, Antigua & Barbuda', 'flag': '🇦🇬'},
                {'name': 'Oranjestad', 'sub': 'Aruba, Aruba', 'flag': '🇦🇼'},
                {'name': 'Nassau', 'sub': 'New Providence, Bahamas', 'flag': '🇧🇸'},
                {'name': 'Freeport', 'sub': 'Grand Bahama, Bahamas', 'flag': '🇧🇸'},
                {'name': 'Bridgetown', 'sub': 'Saint Michael, Barbados', 'flag': '🇧🇧'},
                {'name': 'Kralendijk', 'sub': 'Bonaire, Bonaire', 'flag': '🇧🇶'},
                {'name': 'Road Town', 'sub': 'Tortola, British Virgin Islands', 'flag': '🇻🇬'},
                {'name': 'George Town', 'sub': 'Grand Cayman, Cayman Islands', 'flag': '🇰🇾'},
                {'name': 'Havana', 'sub': 'La Habana, Cuba', 'flag': '🇨🇺'},
              ].map((loc) => _selectRow(
                    context,
                    loc['name']!,
                    loc['flag']!,
                    _locationName == loc['name'],
                    () {
                      setSheetState(() => _locationName = loc['name']!);
                      setState(() {});
                    },
                    subtitle: loc['sub'],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectRow(BuildContext context, String title, String flag, bool selected, VoidCallback onTap, {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xff2f9bef) : const Color(0xffdfe6ef), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_rounded, color: Color(0xff2f9bef), size: 20),
          ],
        ),
      ),
    );
  }

  void _showFeedPreferencesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedPreferencesSheet(),
    );
  }

  void _showHelpSupport(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Help & Support',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Help & Support
Effective 1 January 2026 · Last updated 1 January 2026

We're here to help you get the most out of LinkUp.

GETTING STARTED
• Create your account, complete onboarding, and verify your identity (KYC) to unlock the Wallet, marketplace selling, going Live, and savings circles.
• Set your location and language so we can show events, people and food near you.

ACCOUNT & SECURITY
• Manage your profile, privacy, language and notifications in Settings.
• Turn on Face ID / biometric unlock and two-factor authentication for extra protection.
• Forgot your password? Use "Forgot password" on the sign-in screen.
• Lost or stolen device? Contact support immediately to secure your account.

VERIFICATION (KYC)
• Have your government ID and proof of address ready, and take your selfie in good lighting.
• If a check doesn't pass automatically, it goes to manual review — you'll be notified when approved (usually within 24–48 hours).

WALLET, COINS & PAYMENTS
• Top up your Wallet, buy LinkUp Coins, send Big Ups, and cash out earnings.
• Verification is required to send, withdraw or earn money.
• See the Payments, Wallet, Coins & Refunds Policy for details.

TICKETS, MARKETPLACE & EATS
• Find tickets under Profile › Tickets & Events (each has a QR code and can be added to Apple/Google Wallet).
• Track marketplace orders and Eats deliveries in your dashboard.
• For order issues, use "Contact Us" and include your order/ticket number.

TRUST & SAFETY
• Report users or content in-app. Never send money to someone you haven't met.
• Review our Community Guidelines for the rules of the road.

CONTACT
• In-app: Settings › Support & Legal › Contact Us
• Email: support@linkupvibes.com — typical response within 24 hours.
''',
    );
  }

  void _showContactUs(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Contact Us',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Contact Us
Effective 1 January 2026 · Last updated 1 January 2026

We'd love to hear from you.

GENERAL & SUPPORT
support@linkupvibes.com

PAYMENTS & WALLET
payments@linkupvibes.com

PRIVACY / DATA PROTECTION (DPO)
privacy@linkupvibes.com

IDENTITY / COMPLIANCE (KYC / AML)
compliance@linkupvibes.com

LEGAL
legal@linkupvibes.com

BUSINESS, ADVERTISING & PARTNERSHIPS
partners@linkupvibes.com

MAILING ADDRESS
LinkUp Vibes Ltd.
Nassau, New Providence, The Bahamas

WEBSITE
https://linkupvibes.com

For the fastest help, use Settings › Support & Legal › Contact Us inside the app so we can see your account and order details.
''',
    );
  }

  void _showLegalCenter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniSheet(
        title: 'Legal Center',
        subtitle: 'Effective 1 January 2026',
        icon: Icons.gavel_rounded,
        gradientColors: const [Color(0xff0f172a), Color(0xff2563eb)],
        child: Column(
          children: [
            _legalRow(context, 'Terms of Service', Icons.description_outlined, () {
              Navigator.pop(context);
              _showTerms(context);
            }),
            _legalRow(context, 'Privacy Policy', Icons.shield_outlined, () {
              Navigator.pop(context);
              _showPrivacy(context);
            }),
            _legalRow(context, 'Community Guidelines', Icons.people_outline_rounded, () {
              Navigator.pop(context);
              _showCommunityGuidelines(context);
            }),
            _legalRow(context, 'Payments, Wallet, Coins & Refunds', Icons.account_balance_wallet_outlined, () {
              Navigator.pop(context);
              _showPaymentsPolicy(context);
            }),
            _legalRow(context, 'KYC / AML Policy', Icons.verified_user_outlined, () {
              Navigator.pop(context);
              _showKycAmlPolicy(context);
            }),
            _legalRow(context, 'Cookie Policy', Icons.cookie_outlined, () {
              Navigator.pop(context);
              _showCookiePolicy(context);
            }),
            _legalRow(context, 'Help & Support', Icons.support_rounded, () {
              Navigator.pop(context);
              _showHelpSupport(context);
            }),
            _legalRow(context, 'Contact Us', Icons.email_outlined, () {
              Navigator.pop(context);
              _showContactUs(context);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _legalRow(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xfff8fbff),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xff8ca0ba), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 20),
          ],
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Terms of Service',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Terms of Service
Effective 1 January 2026 · Last updated 1 January 2026

PLEASE READ THESE TERMS CAREFULLY. THEY CONTAIN A BINDING ARBITRATION CLAUSE AND CLASS-ACTION WAIVER (SECTION 21) AND LIMIT OUR LIABILITY (SECTION 18).

1. WHO WE ARE & ACCEPTANCE
These Terms of Service ("Terms") are a binding agreement between you and LinkUp Vibes Ltd. and its affiliates ("LinkUp", "we", "us", "our"). They govern your access to and use of the LinkUp mobile application, websites and all related features and services (collectively, the "Services"). By creating an account, tapping "I agree", or accessing or using the Services, you accept these Terms, our Privacy Policy, Community Guidelines, Payments/Wallet/Coins & Refunds Policy, KYC/AML Policy and Cookie Policy, all of which are incorporated by reference. If you do not agree, do not use the Services.

2. ELIGIBILITY
You must be at least 18 years old, of legal age to form a binding contract, and not barred from using the Services under the laws of your jurisdiction. You may not use the Services if you are a convicted sex offender or appear on any sanctions or prohibited-persons list. You represent that all information you provide is true, accurate, current and complete and that you will keep it updated.

3. YOUR ACCOUNT
Your account is personal and non-transferable. You are responsible for all activity under your account and for keeping your credentials, device and one-time codes secure. Notify us immediately at support@linkupvibes.com of any unauthorized access. We may require identity verification (KYC) and may refuse, restrict, suspend or reclaim usernames/IDs at our discretion.

4. THE SERVICES
LinkUp is a Caribbean & Latin American "super-app" that may include, without limitation: social discovery and dating; the Vibes feed, reels and stories; live streaming (LinkUp Live); events discovery and ticketing; a peer-to-peer and merchant Marketplace; food discovery and delivery (LinkUp Eats); a digital Wallet; LinkUp Coins; gifting ("Big Ups"); savings circles (ASUE/Susu); messaging; and Caribbean 360 news. Features vary by country, may be added, changed, suspended or removed, and some require a subscription and/or identity verification.

5. LICENCE
Subject to these Terms, we grant you a limited, revocable, non-exclusive, non-transferable, non-sublicensable licence to use the Services for your personal, non-commercial purposes. All rights not expressly granted are reserved.

6. SUBSCRIPTIONS, BILLING & AUTO-RENEWAL
Certain features require a paid subscription. Paid plans renew automatically for successive periods until cancelled, and you authorize us (or the applicable app store) to charge your payment method on each renewal at the then-current price. You may cancel at any time; cancellation takes effect at the end of the current billing period and, except where required by law, fees already paid are non-refundable. Where you purchase through Apple or Google, billing, renewal and refunds are controlled by that store's terms. We may change prices and features with prior notice.

7. DIGITAL WALLET, COINS & FINANCIAL FEATURES
The LinkUp Wallet, LinkUp Coins, gifting, payouts and savings circles are governed by our Payments, Wallet, Coins & Refunds Policy, which forms part of these Terms. In summary: the Wallet is not a bank account and balances are not insured deposits; LinkUp Coins are a limited-purpose in-app feature (1 coin = US\$0.01), are not legal tender, securities, cryptocurrency or a stored-value instrument redeemable on demand, have no cash value outside the Services except as expressly stated, and are generally non-refundable. Identity verification (KYC) is required to send money, withdraw, sell, earn or run a savings circle.

8. MARKETPLACE (BUYERS & SELLERS)
LinkUp provides a venue connecting buyers and sellers; we are not the buyer or seller and do not manufacture, inspect, store or deliver goods. Sellers are solely responsible for their listings, the accuracy of descriptions, the legality, safety, quality and delivery of items, warranties, and all applicable taxes and licences. Buyers transact at their own risk. We may charge service fees, hold or escrow funds until delivery is confirmed, and remove listings or suspend sellers who violate these Terms or the law.

9. EVENTS & TICKETS
Organizers are solely responsible for their events, pricing, capacity, health & safety, cancellations and ticket terms. Tickets are issued with a unique QR code; duplication, fraudulent transfer or unauthorized resale may void a ticket. Refunds for events follow the organizer's stated policy and applicable law. LinkUp is not responsible for the conduct of organizers or attendees.

10. LINKUP LIVE & GIFTS
Hosts are responsible for their broadcasts and must comply with these Terms and the Community Guidelines. Viewers may send Coin-based gifts ("Big Ups"); gifts are voluntary, are consumed when sent and are non-refundable. Eligible creator earnings may be converted to Wallet cash subject to minimums, verification and a platform share shown in-app.

11. USER CONTENT
You retain ownership of content you create, but you grant LinkUp a worldwide, perpetual (for content you have not deleted), irrevocable to the extent necessary for backups/legal compliance, non-exclusive, royalty-free, sublicensable and transferable licence to host, store, use, reproduce, adapt, publish, translate, distribute and display your content in connection with operating, promoting and improving the Services. You represent that you own or have all rights to your content and that it does not violate any law or third-party right. We may, but are not obligated to, moderate, remove or refuse content.

12. PROHIBITED CONDUCT
You agree not to, and not to assist others to: (a) impersonate any person or misrepresent your identity, age or affiliation; (b) harass, bully, threaten, defraud, stalk or harm others; (c) post or transmit content that is unlawful, hateful, discriminatory, defamatory, obscene, sexually explicit, or that exploits or endangers minors; (d) solicit money, donations, gifts or financial information under false pretences, or run pyramid/Ponzi or "romance" scams; (e) sell or promote illegal, dangerous, counterfeit, stolen or regulated goods; (f) use bots, scrapers, or automated means, or reverse engineer, decompile or interfere with the Services; (g) circumvent fees, payments, security or geographic restrictions; (h) infringe intellectual-property or privacy rights; or (i) use the Services for money laundering, terrorist financing, sanctions evasion or any unlawful purpose. Violations may result in content removal, limits, suspension, permanent ban, forfeiture of balances obtained through fraud, and referral to authorities.

13. SAFETY DISCLAIMER
LINKUP DOES NOT CONDUCT CRIMINAL BACKGROUND CHECKS OR IDENTITY-VERIFY EVERY USER BEYOND OUR KYC PROCESS, AND DOES NOT GUARANTEE THE CONDUCT OF ANY USER. You are solely responsible for your interactions. Meet in public, tell someone your plans, do not share financial information, and never send money to people you have not met. You assume all risk arising from contact with other users, sellers, organizers, hosts and drivers.

14. THIRD-PARTY SERVICES
The Services integrate third parties (e.g., payment processors, mapping, identity-verification providers, and banking/KYC partners such as Scotiabank). We are not responsible for third-party services, and your use of them may be subject to their separate terms and privacy policies.

15. PRIVACY & DATA
Your use of the Services is subject to our Privacy Policy, which explains how we collect, use and share personal information, including KYC and biometric (face-match) data used to verify identity and prevent fraud.

16. INTELLECTUAL PROPERTY; FEEDBACK
The LinkUp name, "ü" logo, designs, software and content (excluding user content) are owned by or licensed to LinkUp and protected by law. If you submit feedback or suggestions, you grant us an unrestricted, royalty-free right to use them without obligation to you.

17. SUSPENSION & TERMINATION
We may suspend, limit or terminate your access at any time, with or without notice, for any reason, including suspected breach of these Terms or risk to the community or our compliance obligations. You may stop using and delete your account at any time. Sections that by their nature should survive (including 7–9, 11–13, 16, 18–22) survive termination. We may retain certain data as required by law (e.g., financial and KYC records).

18. DISCLAIMERS
TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, NON-INFRINGEMENT, AND ANY WARRANTY THAT THE SERVICES WILL BE UNINTERRUPTED, SECURE, ERROR-FREE OR THAT MATCHES, RESULTS OR EARNINGS WILL BE ACHIEVED.

19. LIMITATION OF LIABILITY
TO THE MAXIMUM EXTENT PERMITTED BY LAW, LINKUP AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AGENTS AND PARTNERS WILL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, GOODWILL OR DAMAGES ARISING FROM YOUR INTERACTIONS WITH OTHER USERS OR THIRD PARTIES. OUR TOTAL AGGREGATE LIABILITY FOR ANY CLAIM RELATING TO THE SERVICES WILL NOT EXCEED THE GREATER OF (A) THE AMOUNTS YOU PAID US IN THE 12 MONTHS BEFORE THE EVENT GIVING RISE TO THE CLAIM, OR (B) US\$100. Some jurisdictions do not allow certain limitations, so some may not apply to you.

20. INDEMNIFICATION
You agree to defend, indemnify and hold harmless LinkUp and its affiliates from and against any claims, liabilities, damages, losses and expenses (including reasonable legal fees) arising out of or related to your use of the Services, your content, your breach of these Terms, or your violation of any law or third-party right.

21. DISPUTE RESOLUTION; ARBITRATION; CLASS WAIVER
Most concerns can be resolved by contacting support@linkupvibes.com. Where permitted by law, you and LinkUp agree that any dispute not resolved informally will be settled by final and binding individual arbitration, and that disputes will be brought only in an individual capacity and not as a plaintiff or class member in any class or representative proceeding. You may opt out of arbitration within 30 days of first accepting these Terms by emailing legal@linkupvibes.com.

22. GOVERNING LAW
These Terms are governed by the laws of the Commonwealth of The Bahamas, without regard to conflict-of-laws principles, and, subject to Section 21, the courts located in The Bahamas have jurisdiction.

23. CHANGES TO THE TERMS
We may update these Terms from time to time. Material changes will be notified in-app or by email. Your continued use after changes become effective constitutes acceptance.

24. MISCELLANEOUS
These Terms are the entire agreement between you and LinkUp regarding the Services. If any provision is held unenforceable, the remainder remains in effect. Our failure to enforce a right is not a waiver. You may not assign these Terms; we may assign them to an affiliate or successor. Headings are for convenience only.

25. CONTACT
LinkUp Vibes Ltd., Nassau, New Providence, The Bahamas — legal@linkupvibes.com

This document is a template provided for convenience and does not constitute legal advice. Please have it reviewed by qualified counsel before relying on it.
''',
    );
  }

  void _showPrivacy(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Privacy Policy',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Privacy Policy
Effective 1 January 2026 · Last updated 1 January 2026

1. INTRODUCTION
This Privacy Policy describes how LinkUp Vibes Ltd. ("LinkUp", "we") collects, uses, discloses and protects personal information when you use our app, websites and related services (the "Services"). By using the Services you agree to this Policy.

2. INFORMATION WE COLLECT
(a) Information you provide:
• Account: name, LinkUp ID, email, phone, password, date of birth, gender, language.
• Profile: photos/video, bio, roots/country, religion, interests, languages, university, profession, relationship intent, and who you want to see.
• Identity (KYC): government-issued ID, a selfie and biometric facial-geometry data used for liveness/face-match, and proof of address.
• Financial: wallet activity, transactions, LinkUp Coins, gifts, payouts and savings-circle activity. Card/bank details are collected and processed by our payment partners, not stored by us in full.
• Content & communications: posts, vibes, reels, messages, reviews, support requests.
(b) Information collected automatically: device identifiers, IP address, app/version, log and usage data, interactions, and cookies/local storage (see our Cookie Policy).
(c) Location: precise or approximate location (with your permission) for distance, "near you", events, delivery and live features.
(d) From third parties: payment processors, identity-verification and banking/KYC partners (e.g., Scotiabank), and social login providers if you connect them.

3. HOW WE USE INFORMATION
To create and operate your account; provide, personalize and improve the Services; match and connect you with people, events, food and products; process payments, coins, gifts and payouts; verify identity and prevent fraud, money laundering and abuse (KYC/AML); enable safety and content moderation; communicate with you (service messages, and marketing where permitted); run analytics; and comply with legal and regulatory obligations.

4. LEGAL BASES
Where required, we rely on: performance of our contract with you; your consent (e.g., precise location, biometric KYC, marketing); our legitimate interests (security, fraud prevention, product improvement); and compliance with legal obligations (including financial-services and AML laws).

5. HOW WE SHARE INFORMATION
• With other users, according to your profile and privacy settings.
• With service providers acting on our behalf (hosting, analytics, messaging, mapping, customer support).
• With payment processors and banking/identity partners (including Scotiabank) to enable, verify and settle financial transactions and to meet KYC/AML obligations.
• With sellers, organizers, hosts and delivery drivers as needed to fulfil tickets, orders and deliveries.
• For legal, safety and compliance reasons, or to enforce our Terms.
• In a merger, acquisition or asset sale, subject to this Policy.
We do NOT sell your personal information.

6. KYC, BIOMETRIC & FINANCIAL DATA
Identity documents and biometric face-match data are used strictly to verify your identity, meet legal obligations and prevent fraud. This data is encrypted in transit and at rest and shared only with authorized verification/banking partners for review and approval. Where required, we obtain your explicit consent to process biometric data, and we retain it only as long as necessary or as required by law.

7. COOKIES & SIMILAR TECHNOLOGIES
We use cookies and local storage as described in our Cookie Policy. You can manage preferences in your device settings and in-app privacy controls.

8. DATA RETENTION
We keep personal data only as long as necessary for the purposes in this Policy or as required by law. Financial and KYC/AML records may be retained for statutory periods after account closure.

9. SECURITY
We use technical and organizational safeguards (encryption, access controls, monitoring). No system is completely secure, and we cannot guarantee absolute security.

10. YOUR RIGHTS & CHOICES
Subject to local law, you may access, correct, delete, or export your data; object to or restrict certain processing; withdraw consent; and opt out of marketing. You can manage profile visibility, location sharing, personalized ads and notifications in Settings. To exercise rights, contact privacy@linkupvibes.com. You may also lodge a complaint with your local data-protection authority.

11. CHILDREN
The Services are for adults 18+. We do not knowingly collect data from anyone under 18; if we learn we have, we will delete it.

12. INTERNATIONAL TRANSFERS
We may process and store data in countries other than where you live; where required, we apply appropriate safeguards for cross-border transfers.

13. THIRD-PARTY LINKS
The Services may link to third-party sites/apps we do not control; their privacy practices govern your use of them.

14. CHANGES
We may update this Policy; material changes will be notified in-app or by email.

15. CONTACT
Data Protection Officer, LinkUp Vibes Ltd., Nassau, The Bahamas — privacy@linkupvibes.com

This document is a template and not legal advice.
''',
    );
  }

  void _showCommunityGuidelines(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Community Guidelines',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Community Guidelines
Effective 1 January 2026 · Last updated 1 January 2026

LinkUp is built on island warmth, respect and good vibes. These Guidelines apply everywhere on LinkUp — profiles, Vibes, reels, messages, Live, events, marketplace and comments. Breaking them can lead to content removal, feature limits, suspension or a permanent ban, and where appropriate, referral to law enforcement.

1. BE AUTHENTIC
Use your real identity, your own recent photos, and accurate information. No fake, impersonating, or bot accounts. One person, one account.

2. BE 18+ AND KEEP MINORS OFF THE PLATFORM
LinkUp is strictly for adults. Any content that sexualizes or endangers minors is prohibited and will be reported to authorities.

3. TREAT PEOPLE WITH RESPECT
No harassment, bullying, threats, intimidation, stalking, or hate speech or discrimination based on race, ethnicity, nationality, religion, sex, gender identity, sexual orientation, disability or any protected characteristic.

4. KEEP IT APPROPRIATE
No nudity, sexually explicit content, or content that is excessively violent, graphic or disturbing. Keep public spaces suitable for the community.

5. NO SCAMS, FRAUD OR SOLICITATION
Never ask users for money, gifts, banking details or one-time codes. No romance scams, investment/"money-flip" schemes, phishing, or deceptive links. Do not solicit for prostitution or any illegal service.

6. NOTHING ILLEGAL
No drugs, weapons, stolen, counterfeit or regulated goods; no human trafficking; no promotion of illegal activity anywhere on LinkUp, including the marketplace and live streams.

7. PROTECT PRIVACY
Do not share other people's private information, photos or messages without consent. No "outing", doxxing or non-consensual intimate content.

8. RESPECT INTELLECTUAL PROPERTY
Only post content you own or have permission to use.

9. PLAY FAIR ON LIVE, EVENTS & MARKETPLACE
No spam, manipulation, ticket fraud, fake reviews, or abuse of creators, organizers, sellers or drivers.

10. STAY SAFE
Meet in public, trust your instincts, and report anything that feels wrong. Never send money to someone you have not met.

REPORTING & ENFORCEMENT
Use the in-app report tools to flag users or content. Our Trust & Safety team reviews reports and applies actions proportionate to the violation. Serious or repeated violations result in permanent removal. We may preserve and share information with authorities where required.
''',
    );
  }

  void _showPaymentsPolicy(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Payments, Wallet, Coins & Refunds',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Payments, Wallet, Coins & Refunds Policy
Effective 1 January 2026 · Last updated 1 January 2026

This Policy forms part of the Terms of Service and explains money-related features. Identity verification (KYC) is required to send money, withdraw, sell, earn or run a savings circle.

1. THE LINKUP WALLET
The Wallet lets you hold a balance to pay for tickets, marketplace items, Eats orders, subscriptions and more. The Wallet is a limited-purpose payment feature, NOT a bank account; balances are NOT insured deposits and do not earn interest unless expressly offered (e.g., LinkUp Save, per its own terms).

2. TOP-UPS & PURCHASES
You can add funds and buy LinkUp Coins or subscriptions using approved payment methods. Some purchases (coins, subscriptions, top-ups) may be completed on linkupvibes.com. You authorize us and our processors to charge the amounts shown at checkout, including applicable taxes and fees.

3. LINKUP COINS
LinkUp Coins are an in-app digital credit where 1 coin = US\$0.01. Coins are NOT legal tender, NOT a bank deposit, NOT a security, NOT cryptocurrency, and NOT a stored-value instrument redeemable on demand. Coins have no value outside the Services, are licensed (not sold) to you for use within LinkUp, and are generally non-refundable. We may modify coin pricing, packs and conversion rates prospectively.

4. GIFTS / "BIG UPS" & CREATOR EARNINGS
Gifts and Big Ups sent on Vibes, Live and in chats convert your Coins into a benefit for the recipient and are consumed when sent (non-refundable). Eligible creators may convert received gift Coins into Wallet cash subject to a minimum threshold, identity verification, and a platform share/commission disclosed in-app. We may withhold amounts associated with fraud, chargebacks or policy violations.

5. ASUE / SUSU SAVINGS CIRCLES
LinkUp is a technology facilitator of rotating savings circles and is NOT a party to, guarantor of, or insurer of any circle. Each cycle, every member is debited the agreed hand amount; the pooled funds, minus a stated LinkUp service fee per payout, are sent to that round's recipient. You are responsible for the people you join with. LinkUp is not liable for any member's failure to contribute. Participation is voluntary and at your own risk.

6. FEES
Service, processing, delivery, payout and currency-conversion fees are disclosed before you confirm a transaction. Bank withdrawals/transfers may incur a processing fee (e.g., a percentage of the amount). Fees may change with notice.

7. PAYOUTS & CASH OUT
Marketplace sales, creator earnings and savings-circle payouts may be credited to your Wallet and then withdrawn to a verified linked bank account, subject to identity verification, holding periods, minimums, limits and fees, and to fraud/AML checks.

8. REFUNDS
• Event tickets: governed by the organizer's stated policy and applicable law.
• Marketplace: governed by the seller's policy; LinkUp may mediate disputes and, where warranted, reverse held funds.
• LinkUp Eats: refunds or credits for orders that fail or are materially incorrect, per in-app support.
• Coins & subscriptions: generally non-refundable, except where required by law or by the applicable app store's rules.
Approved refunds are returned to the original payment method or your Wallet at our discretion.

9. AUTHORIZATION, HOLDS & REVERSALS
We may place temporary holds, request additional information, decline or reverse transactions, and freeze balances to investigate suspected fraud, chargebacks, error, or violations of this Policy or law.

10. ERRORS & UNAUTHORIZED ACTIVITY
Report suspected errors or unauthorized transactions promptly to payments@linkupvibes.com so we can investigate.

11. TAXES
You are responsible for any taxes arising from your sales, earnings or transactions.

12. CONTACT
payments@linkupvibes.com. This document is a template and not financial or legal advice.
''',
    );
  }

  void _showKycAmlPolicy(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'KYC / AML Policy',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Know-Your-Customer (KYC) & Anti-Money-Laundering (AML) Policy
Effective 1 January 2026 · Last updated 1 January 2026

As a fintech-enabled platform, LinkUp is committed to preventing money laundering, terrorist financing, fraud and sanctions evasion, and to complying with applicable KYC/AML laws and the requirements of our banking partners.

1. CUSTOMER IDENTIFICATION (KYC)
Before you can send money, withdraw, sell on the marketplace, earn creator payouts or operate a savings circle, you must complete identity verification, which may include: a valid government-issued photo ID; a live selfie used for liveness detection and biometric face-matching to your ID; and proof of address (a recent document showing your name and address).

2. VERIFICATION & APPROVAL WORKFLOW
We use automated document authenticity and face-match checks. Even where an automated face match does not pass, your submission is still recorded and routed for MANUAL review. Final approval is performed by LinkUp compliance administrators and, where applicable, by authorized banking partners (e.g., the Scotiabank KYC portal). Until approved, financial features remain restricted.

3. SANCTIONS & WATCHLIST SCREENING
We may screen users and transactions against sanctions, politically-exposed-person (PEP) and watch lists, and may decline, restrict or terminate service based on the results.

4. ONGOING MONITORING & ENHANCED DUE DILIGENCE
We monitor activity for unusual or suspicious patterns and may apply enhanced due diligence, request additional information or documentation, set transaction limits, place holds, or suspend accounts. We may file reports (including Suspicious Activity Reports) with the relevant authorities as required by law, and we are not permitted to "tip off" customers about such reports.

5. RECORD KEEPING
Identity records, verification results and transaction data are retained for the periods required by law (typically several years after the relationship ends).

6. PROHIBITED USE
The Services may not be used for money laundering, terrorist financing, fraud, sanctions evasion or any unlawful purpose. Violations result in immediate suspension, possible forfeiture of implicated funds, and referral to authorities.

7. DATA PROTECTION
KYC and biometric data are handled in accordance with our Privacy Policy, encrypted, and shared only with authorized verification/banking partners and regulators as required.

8. CONTACT
compliance@linkupvibes.com. This document is a template and not legal advice.
''',
    );
  }

  void _showCookiePolicy(BuildContext context) {
    _showLegalDoc(
      context,
      title: 'Cookie Policy',
      icon: Icons.gavel_rounded,
      content: '''
LinkUp Vibes — Cookie Policy
Effective 1 January 2026 · Last updated 1 January 2026

This Policy explains how LinkUp uses cookies and similar technologies (such as local storage, SDKs and device identifiers) in our app and websites.

1. WHAT THEY ARE
Cookies and similar technologies store small amounts of data on your device to make the Services work and to remember information about you and your preferences.

2. TYPES WE USE
• Strictly necessary: sign-in, session management, security and fraud prevention. These cannot be switched off.
• Functional: remembering preferences such as language, location, currency and theme.
• Analytics/performance: understanding how features are used so we can improve them.
• Advertising: where enabled, to show and measure relevant ads. You can turn off personalized ads in Settings.

3. THIRD PARTIES
Some cookies/SDKs are set by our service providers (e.g., analytics, payment, mapping). Their use is governed by their policies.

4. YOUR CHOICES
You can manage cookies through your device/browser settings and your in-app privacy controls. Disabling some technologies may affect functionality.

5. CHANGES & CONTACT
We may update this Policy; material changes will be notified in-app. Questions: privacy@linkupvibes.com. This document is a template and not legal advice.
''',
    );
  }

  void _showLegalDoc(BuildContext context, {required String title, required String content, required IconData icon}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniSheet(
        title: title,
        subtitle: '',
        icon: icon,
        gradientColors: const [Color(0xff0f172a), Color(0xff2563eb)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(color: Color(0xff40516a), fontSize: 13, fontWeight: FontWeight.w600, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showLegalCenter(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xffdfe6ef)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: const Color(0xff40516a),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('All legal documents', style: TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBlocked(BuildContext context) {
    _showSimpleInfo(context, 'Blocked accounts', '@spam_vendor\n@fake_support\nNo recent blocked messages.');
  }

  void _showSimpleInfo(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniSheet(
        title: title,
        subtitle: 'LinkUp account control',
        child: Text(body, style: TextStyle(color: const Color(0xff3b4960), fontSize: _font(context, 14), fontWeight: FontWeight.w700, height: 1.45)),
      ),
    );
  }

  void _showFormSheet(BuildContext context, String title, String subtitle, List<Widget> children, {String buttonLabel = 'Save Changes'}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniSheet(
        title: title,
        subtitle: subtitle,
        child: Column(
          children: [
            ...children,
            SizedBox(
              width: double.infinity,
              height: _ui(context, 50),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2f9bef),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 14))),
                ),
                child: Text(buttonLabel, style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, String label, TextEditingController controller, {String? hint, int lines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: const Color(0xff70829b), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 6)),
          TextField(
            controller: controller,
            maxLines: lines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xfff8fbff),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffdfe9f5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffdfe9f5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsNotice(BuildContext context, IconData icon, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(_ui(context, 14)), border: Border.all(color: const Color(0xffbfdbfe))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff2563eb), size: _ui(context, 19)),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: Text(text, style: TextStyle(color: const Color(0xff1e3a8a), fontSize: _font(context, 12), fontWeight: FontWeight.w700, height: 1.35))),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final authController = Get.isRegistered<AuthController>(tag: AuthController().toString())
        ? Get.find<AuthController>(tag: AuthController().toString())
        : null;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?', textAlign: TextAlign.center),
        content: const Text('This permanently deletes your LinkUp account data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authController?.deleteUser(context);
            },
            child: const Text('Delete', style: TextStyle(color: LinkUpColors.badgeRed)),
          ),
        ],
      ),
    );
  }
}

class _MiniSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final IconData? icon;
  final Widget? headerBottom;
  final Widget? headerAction;
  final bool darkHeader;
  final List<Color>? gradientColors;
  const _MiniSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.headerBottom,
    this.headerAction,
    this.darkHeader = true,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final headerColor = darkHeader ? Colors.white : Colors.black;
    final subtitleColor = darkHeader ? Colors.white.withOpacity(0.9) : const Color(0xff8ca0ba);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.91),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                gradient: darkHeader
                    ? LinearGradient(
                        colors: gradientColors ?? [const Color(0xff2f9bef), const Color(0xff2487e0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: darkHeader ? null : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: darkHeader ? null : const Border(bottom: BorderSide(color: Color(0xfff0f4f8))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(icon, color: headerColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(color: headerColor, fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (headerAction != null) ...[
                        headerAction!,
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: headerColor, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (headerBottom != null) ...[
                    const SizedBox(height: 12),
                    headerBottom!,
                  ],
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvertisePlansSheet extends StatelessWidget {
  const _AdvertisePlansSheet();

  @override
  Widget build(BuildContext context) {
    return _MiniSheet(
      title: 'Advertise',
      subtitle: 'Reach customers across LinkUp',
      child: Column(
        children: [
          _adPlan(context, 'Starter', '\$49', 'Vibes Feed + listing boost', '50k impressions/mo'),
          _adPlan(context, 'Pro', '\$149', '+ Push + Email + News', '250k impressions/mo', isPopular: true),
          _adPlan(context, 'Headliner', '\$399', '+ In-App + Live + homepage', '1M impressions/mo'),
          const SizedBox(height: 12),
          const Text(
            'Paid by Wallet, Card or Bank Transfer.',
            style: TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _adPlan(BuildContext context, String title, String price, String desc, String impressions, {bool isPopular = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? const Color(0xff2f9bef) : const Color(0xffe6edf7),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [BoxShadow(color: const Color(0xff2f9bef).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)),
                  const Text(' /mo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff8ca0ba))),
                ],
              ),
              const SizedBox(height: 10),
              Text(desc, style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(impressions, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _PayForAdSheet(plan: title, price: price),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff121826),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Choose $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Popular',
                  style: TextStyle(color: Color(0xff2f9bef), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayForAdSheet extends StatefulWidget {
  final String plan;
  final String price;
  const _PayForAdSheet({required this.plan, required this.price});

  @override
  State<_PayForAdSheet> createState() => _PayForAdSheetState();
}

class _PayForAdSheetState extends State<_PayForAdSheet> {
  String _method = 'wallet';

  @override
  Widget build(BuildContext context) {
    return _MiniSheet(
      title: 'Pay for Ad',
      subtitle: 'Complete your sponsorship',
      darkHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xfff8fbff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.plan} plan (monthly)',
                  style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.price,
                  style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _methodRow('wallet', 'Wallet', Icons.account_balance_wallet_outlined),
          _methodRow('card', 'Credit / Debit Card', Icons.credit_card_rounded),
          _methodRow('bank', 'Bank Transfer', Icons.account_balance_rounded),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff121826),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _methodRow(String id, String label, IconData icon) {
    final selected = _method == id;
    return InkWell(
      onTap: () => setState(() => _method = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xff2f9bef) : const Color(0xffdfe6ef), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xff2f9bef) : const Color(0xffdfe6ef),
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Icon(icon, color: const Color(0xff8ca0ba), size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityVerificationSheet extends StatefulWidget {
  const _IdentityVerificationSheet();

  @override
  State<_IdentityVerificationSheet> createState() => _IdentityVerificationSheetState();
}

class _IdentityVerificationSheetState extends State<_IdentityVerificationSheet> {
  int _step = 1;
  String _docType = 'Passport';

  @override
  Widget build(BuildContext context) {
    if (_step == 1) return _step1();
    return _step2();
  }

  Widget _progressBar(int step) {
    return Row(
      children: List.generate(5, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }),
    );
  }

  Widget _step1() {
    return _MiniSheet(
      title: 'Identity Verification',
      subtitle: 'Step 1 - Choose your ID',
      icon: Icons.verified_user_rounded,
      headerBottom: _progressBar(1),
      gradientColors: const [Color(0xff0f172a), Color(0xff2563eb)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffdbeafe)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xff2f9bef), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'As a financial app, LinkUp must verify your identity (KYC). It’s encrypted and used only for verification.',
                    style: TextStyle(
                      color: const Color(0xff3b82f6).withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SELECT DOCUMENT TYPE',
            style: TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          _docOption('Passport', Icons.badge_outlined),
          _docOption("Driver's License", Icons.drive_eta_outlined),
          _docOption('National ID', Icons.perm_identity_rounded),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3b82f6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _step2() {
    return _MiniSheet(
      title: 'Identity Verification',
      subtitle: 'Step 2 - Upload your $_docType',
      icon: Icons.verified_user_rounded,
      headerBottom: _progressBar(2),
      gradientColors: const [Color(0xff0f172a), Color(0xff2563eb)],
      child: Column(
        children: [
          if (_docType == 'Passport')
            _uploadBox('Photo ID', 'Tap to open camera')
          else ...[
            _uploadBox('Front of Photo ID', 'Tap to open camera'),
            const SizedBox(height: 16),
            _uploadBox('Back of ID', 'Tap to open camera'),
          ],
          const SizedBox(height: 24),
          const Text(
            'Make sure all text is clear and the whole document is visible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xffdfe6ef)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3b82f6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _docOption(String type, IconData icon) {
    final selected = _docType == type;
    return InkWell(
      onTap: () => setState(() => _docType = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xff2f9bef) : const Color(0xffdfe6ef),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff8ca0ba), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                type,
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xff2f9bef) : Colors.transparent,
                border: Border.all(
                  color: selected ? const Color(0xff2f9bef) : const Color(0xffdfe6ef),
                  width: 1.5,
                ),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadBox(String label, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdfe6ef), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.badge_outlined, color: Color(0xff8ca0ba), size: 28),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FeedPreferencesSheet extends StatefulWidget {
  const _FeedPreferencesSheet();

  @override
  State<_FeedPreferencesSheet> createState() => _FeedPreferencesSheetState();
}

class _FeedPreferencesSheetState extends State<_FeedPreferencesSheet> {
  final Set<String> _selectedRegions = {'Caribbean', 'Latin America', 'Global 360'};
  final Set<String> _selectedCountries = {
    'Anguilla', 'Antigua & Barbuda', 'Aruba', 'Bahamas', 'Barbados', 'Bonaire',
    'British Virgin Islands', 'Cayman Islands', 'Cuba', 'Curaçao', 'Dominica', 'Dominican Republic'
  };
  final Set<String> _selectedCategories = {
    'Breaking News', 'Politics', 'Business', 'Entertainment', 'Sports', 'Culture', 'Technology', 'Faith'
  };
  final Set<String> _selectedSources = {'Feeds (Simulated)', 'Internal Uploads'};
  String _personalization = 'Balanced';

  @override
  Widget build(BuildContext context) {
    return _MiniSheet(
      title: 'Feed Preferences',
      subtitle: 'Choose countries, categories, and sources',
      headerAction: SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.save_outlined, color: Colors.white, size: 16),
          label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff4facfe),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetSection('Regions', [
            _checkRow('Caribbean', '🇯🇲', _selectedRegions.contains('Caribbean'), (v) => _toggle(_selectedRegions, 'Caribbean', v)),
            _checkRow('Latin America', '📍', _selectedRegions.contains('Latin America'), (v) => _toggle(_selectedRegions, 'Latin America', v)),
            _checkRow('Global 360', '🌐', _selectedRegions.contains('Global 360'), (v) => _toggle(_selectedRegions, 'Global 360', v)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xfff0fdf4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffdcfce7))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personalization Mode', style: TextStyle(color: Color(0xff166534), fontSize: 13, fontWeight: FontWeight.w900)),
                  const Text('Choose how strict filtering should be.', style: TextStyle(color: Color(0xff166534), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xffdcfce7))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _personalization,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: ['Strict', 'Balanced', 'Relaxed'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                        onChanged: (v) => setState(() => _personalization = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _sheetSection('Countries', [
            const Text('Select what you want to see.', style: TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _filterBtn('✔️ Carib.', true),
                const SizedBox(width: 8),
                _filterBtn('✔️ LatAm.', true),
                const SizedBox(width: 8),
                _filterBtn('Clear', false),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                {'name': 'Anguilla', 'flag': '🇦🇮'},
                {'name': 'Antigua & Barbuda', 'flag': '🇦🇬'},
                {'name': 'Aruba', 'flag': '🇦🇼'},
                {'name': 'Bahamas', 'flag': '🇧🇸'},
                {'name': 'Barbados', 'flag': '🇧🇧'},
                {'name': 'Bonaire', 'flag': '🇧🇶'},
                {'name': 'British Virgin Islands', 'flag': '🇻🇬'},
                {'name': 'Cayman Islands', 'flag': '🇰🇾'},
                {'name': 'Cuba', 'flag': '🇨🇺'},
                {'name': 'Curaçao', 'flag': '🇨🇼'},
                {'name': 'Dominica', 'flag': '🇩🇲'},
                {'name': 'Dominican Republic', 'flag': '🇩🇴'},
              ].map((c) => _gridCheck(c['name']!, _selectedCountries.contains(c['name']), (v) => _toggle(_selectedCountries, c['name']!, v), flag: c['flag'])).toList(),
            ),
          ]),
          const SizedBox(height: 20),
          _sheetSection('Categories', [
            Row(
              children: [
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Select All', style: TextStyle(color: Color(0xff16a34a), fontSize: 12, fontWeight: FontWeight.w900))),
                TextButton(onPressed: () {}, child: const Text('Clear', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900))),
              ],
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                'Breaking News', 'Politics', 'Business', 'Entertainment', 'Sports', 'Culture', 'Technology', 'Faith'
              ].map((c) => _gridCheck(c, _selectedCategories.contains(c), (v) => _toggle(_selectedCategories, c, v))).toList(),
            ),
          ]),
          const SizedBox(height: 20),
          _sheetSection('Source Types', [
            _checkRow('Feeds (Simulated)', '🛰️', _selectedSources.contains('Feeds (Simulated)'), (v) => _toggle(_selectedSources, 'Feeds (Simulated)', v)),
            _checkRow('Internal Uploads', '📄', _selectedSources.contains('Internal Uploads'), (v) => _toggle(_selectedSources, 'Internal Uploads', v)),
            _checkRow('Community (Phase 2)', '👥', false, null),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xfffff7f6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xfffee2e2))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Breaking News Strip', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                        Text('Breaking stories show regardless of category filters.', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Text('⚡ Always On', style: TextStyle(color: Color(0xfff97316), fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _toggle(Set<String> set, String item, bool? value) {
    if (value == null) return;
    setState(() {
      if (value) set.add(item); else set.remove(item);
    });
  }

  Widget _sheetSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xfff0f4f8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _checkRow(String title, String icon, bool selected, ValueChanged<bool?>? onChanged) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: onChanged == null ? const Color(0xffcbd5e1) : Colors.black, fontSize: 15, fontWeight: FontWeight.w800))),
            Checkbox(
              value: selected,
              onChanged: onChanged,
              activeColor: const Color(0xff3b82f6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCheck(String title, bool selected, ValueChanged<bool?> onChanged, {String? flag}) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xff3b82f6) : const Color(0xfff0f4f8)),
        ),
        child: Row(
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis)),
            Checkbox(
              value: selected,
              onChanged: onChanged,
              activeColor: const Color(0xff3b82f6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xfff0fdf4) : const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: active ? const Color(0xff166534) : Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}
