import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/base_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/auth/widgets/linkup_auth_widgets.dart';

// Kept public enum/name so the existing LoginPage, SignUpUsingEmail, and routes
// continue to work without any flow changes.
enum AuthTab { signup, signin }

class AuthScreen extends StatefulWidget {
  final AuthTab initialTab;

  const AuthScreen({super.key, this.initialTab = AuthTab.signin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final RegExp _pwRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).{8,}$',
  );

  final AuthController _auth = Get.find(tag: AuthController().toString());
  final BaseController _base = Get.find(tag: BaseController().toString());
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GlobalKey<FormState> _signupKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signinKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _forgotKey = GlobalKey<FormState>();

  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _linkupIdController = TextEditingController();
  final TextEditingController _forgotEmailController = TextEditingController();

  late int _tabIndex;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;
  bool _showSigninPassword = false;
  bool _showForgotModal = false;
  bool _forgotSuccess = false;
  bool _forgotLoading = false;

  String _handleStatus = 'waiting';
  String _handleMessage = 'Type your name to generate a unique ID.';
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab == AuthTab.signup ? 0 : 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _auth.updateLoading(false);
    });
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _linkupIdController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  String _normalizeHandle(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '').trim();
  }

  String _fromAtHandle(String value) => value.replaceAll(RegExp(r'^@+'), '').trim();

  String _clampHandle(String value) {
    if (value.length < 3) return '';
    return value.length > 20 ? value.substring(0, 20) : value;
  }

  List<String> _baseCandidates(String first, String last) {
    final f = _normalizeHandle(first);
    final l = _normalizeHandle(last);
    if (f.isEmpty || l.isEmpty) return <String>[];
    return <String>{
      _clampHandle('$f$l'),
      _clampHandle('${f}_$l'),
      _clampHandle('$f${l[0]}'),
      _clampHandle('${f[0]}$l'),
    }.where((item) => item.isNotEmpty).toList();
  }

  void _generateHandleFromName() {
    final candidates = _baseCandidates(
      _auth.firstnameController.text,
      _auth.lastnameController.text,
    );
    if (candidates.isEmpty) {
      _linkupIdController.clear();
      if (!mounted) return;
      setState(() {
        _handleStatus = 'waiting';
        _handleMessage = 'Type your name to generate a unique ID.';
        _suggestions = <String>[];
      });
      return;
    }

    final selected = candidates[Random().nextInt(candidates.length)];
    _linkupIdController.text = '@$selected';
    if (!mounted) return;
    setState(() {
      _handleStatus = 'available';
      _handleMessage = 'This LinkUp ID is available.';
      _suggestions = candidates.where((c) => c != selected).take(3).toList();
    });
  }

  void _onHandleInput() {
    final cleaned = _clampHandle(_normalizeHandle(_fromAtHandle(_linkupIdController.text)));
    if (cleaned.isEmpty) {
      setState(() {
        _handleStatus = 'waiting';
        _handleMessage = 'Enter 3–20 letters, numbers, or underscore characters.';
        _suggestions = <String>[];
      });
      return;
    }

    _linkupIdController.text = '@$cleaned';
    _linkupIdController.selection = TextSelection.fromPosition(
      TextPosition(offset: _linkupIdController.text.length),
    );
    setState(() {
      _handleStatus = 'available';
      _handleMessage = 'This LinkUp ID is available.';
    });
  }

  bool get _isSignupValid {
    final linkupId = _fromAtHandle(_linkupIdController.text);
    return _auth.firstnameController.text.trim().isNotEmpty &&
        _auth.lastnameController.text.trim().isNotEmpty &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_auth.emailController.text.trim()) &&
        _pwRegex.hasMatch(_auth.passwordController.text) &&
        _auth.passwordController.text == _confirmPasswordController.text &&
        linkupId.length >= 3 &&
        _handleStatus == 'available';
  }

  void _submitSignup() {
    FocusScope.of(context).unfocus();
    if (!(_signupKey.currentState?.validate() ?? false) || !_isSignupValid) return;
    _auth.register(context, linkupId: _fromAtHandle(_linkupIdController.text));
  }

  void _submitSignin() {
    FocusScope.of(context).unfocus();
    if (!(_signinKey.currentState?.validate() ?? false)) return;
    _auth.login(context);
  }

  Future<void> _submitForgot() async {
    if (!(_forgotKey.currentState?.validate() ?? false)) return;
    setState(() => _forgotLoading = true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: _forgotEmailController.text.trim());
      if (!mounted) return;
      setState(() {
        _forgotLoading = false;
        _forgotSuccess = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _forgotLoading = false);
      _base.alert1('Unable to send reset email. Please try again.');
    }
  }

  void _toggleForgot(bool show) {
    setState(() {
      _showForgotModal = show;
      if (!show) {
        _forgotSuccess = false;
        _forgotEmailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: _auth,
      builder: (_) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xffeaf2fb),
          body: Stack(
            children: [
              SizedBox.expand(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _AuthHeader(onBack: () { Navigator.maybePop(context); }),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: -34,
                          child: _SegmentedAuthSwitch(
                            selectedIndex: _tabIndex,
                            onChanged: (index) => setState(() => _tabIndex = index),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 52),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: _tabIndex == 0 ? _buildSignupForm() : _buildSigninForm(),
                      ),
                    ),
                  ],
                ),
              ),
              _buildForgotModal(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignupForm() {
    return _WebCard(
      child: Form(
        key: _signupKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 27,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: LinkUpColors.textPrimary,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Step 1 of 2 · then a quick 60-second profile.',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xff93a4b8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: 'G',
                    label: 'Google',
                    onTap: () { _auth.signInWithGoogle(context); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    icon: 'assets/apple.png',
                    label: 'Apple',
                    onTap: () => _base.alert1('Apple sign-in will be available soon.'),
                  ),
                ),
              ],
            ),
            const _OrLine(),
            Row(
              children: [
                Expanded(
                  child: LinkUpTextField(
                    label: 'FIRST NAME',
                    hint: 'Aaliyah',
                    controller: _auth.firstnameController,
                    onChanged: _generateHandleFromName,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinkUpTextField(
                    label: 'LAST NAME',
                    hint: 'Brown',
                    controller: _auth.lastnameController,
                    onChanged: _generateHandleFromName,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('LINKUP ID'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _linkupIdController,
                    onChanged: (_) => _onHandleInput(),
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: LinkUpColors.textPrimary,
                    ),
                    decoration: _inputDecoration('@aaliyahbrown'),
                    validator: (v) => _fromAtHandle(v ?? '').length < 3 ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _generateHandleFromName,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: LinkUpColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Color(0xff111827)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _HandleStatusRow(status: _handleStatus, message: _handleMessage),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  return ActionChip(
                    label: Text('@$s'),
                    onPressed: () {
                      _linkupIdController.text = '@$s';
                      _onHandleInput();
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            LinkUpTextField(
              label: 'EMAIL',
              hint: 'you@example.com',
              controller: _auth.emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LinkUpTextField(
                    label: 'PASSWORD',
                    hint: '••••••••',
                    controller: _auth.passwordController,
                    obscureText: !_showSignupPassword,
                    suffix: IconButton(
                      onPressed: () => setState(() => _showSignupPassword = !_showSignupPassword),
                      icon: Icon(
                        _showSignupPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: LinkUpColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!_pwRegex.hasMatch(v)) return 'Weak password';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinkUpTextField(
                    label: 'CONFIRM',
                    hint: '••••••••',
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    suffix: IconButton(
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: LinkUpColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (v) => v != _auth.passwordController.text ? 'No match' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: const Color(0xff1985ff),
                  visualDensity: VisualDensity.compact,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms',
                            style: TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: Color(0xff50627b),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinkUpGradientButton(
              label: 'Create account',
              isLoading: _auth.loading.value,
              onPressed: _isSignupValid ? _submitSignup : null,
            ),
            const SizedBox(height: 14),
            const _SecureNote(),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 1),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Already have an account? ', style: TextStyle(color: Color(0xff93a4b8))),
                      TextSpan(text: 'Sign in', style: TextStyle(color: Color(0xff111827), fontWeight: FontWeight.w900)),
                    ],
                  ),
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  RoutePath.home_screen,
                  arguments: {'isGuest': true},
                ),
                child: const Text(
                  'Explore as guest',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Color(0xff93a4b8),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSigninForm() {
    return _WebCard(
      child: Form(
        key: _signinKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 27,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: LinkUpColors.textPrimary,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to pick up where you left off.',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xff93a4b8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _SocialButton(icon: 'G', label: 'Google', onTap: () { _auth.signInWithGoogle(context); })),
                const SizedBox(width: 12),
                Expanded(child: _SocialButton(icon: 'assets/apple.png', label: 'Apple', onTap: () => _base.alert1('Apple sign-in will be available soon.'))),
              ],
            ),
            const _OrLine(),
            LinkUpTextField(
              label: 'EMAIL OR LINKUP ID',
              hint: 'you@example.com',
              controller: _auth.emailController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            LinkUpTextField(
              label: 'PASSWORD',
              hint: '••••••••',
              controller: _auth.passwordController,
              obscureText: !_showSigninPassword,
              suffix: IconButton(
                onPressed: () => setState(() => _showSigninPassword = !_showSigninPassword),
                icon: Icon(
                  _showSigninPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: LinkUpColors.textMuted,
                  size: 20,
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _toggleForgot(true),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  color: Color(0xff116df5),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            LinkUpGradientButton(label: 'Sign in', isLoading: _auth.loading.value, onPressed: _submitSignin),
            const SizedBox(height: 18),
            const _SecureNote(),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = 0),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'New here? ', style: TextStyle(color: Color(0xff93a4b8))),
                      TextSpan(text: 'Create account', style: TextStyle(color: Color(0xff111827), fontWeight: FontWeight.w900)),
                    ],
                  ),
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  RoutePath.home_screen,
                  arguments: {'isGuest': true},
                ),
                child: const Text(
                  'Explore as guest',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Color(0xff93a4b8),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'OpenSans', color: Color(0xffa1adbd), fontWeight: FontWeight.w700),
      filled: true,
      fillColor: const Color(0xfff9fbff),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LinkUpColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LinkUpColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff1985ff), width: 1.4),
      ),
    );
  }

  Widget _buildForgotModal() {
    if (!_showForgotModal) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 10, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff1985ff), Color(0xff37c7df)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Reset password',
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _toggleForgot(false),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: _forgotSuccess
                        ? Column(
                            children: [
                              const Icon(Icons.mark_email_read_rounded, color: Color(0xff16a34a), size: 44),
                              const SizedBox(height: 12),
                              const Text(
                                'Check your email',
                                style: TextStyle(fontFamily: 'OpenSans', fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'If the email exists, reset instructions have been sent.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'OpenSans', color: LinkUpColors.textMuted, height: 1.35),
                              ),
                              const SizedBox(height: 18),
                              LinkUpGradientButton(label: 'Done', onPressed: () => _toggleForgot(false)),
                            ],
                          )
                        : Form(
                            key: _forgotKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enter the email linked to your LinkUp account.',
                                  style: TextStyle(fontFamily: 'OpenSans', color: LinkUpColors.textMuted, height: 1.35),
                                ),
                                const SizedBox(height: 16),
                                LinkUpTextField(
                                  label: 'EMAIL',
                                  hint: 'you@example.com',
                                  controller: _forgotEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _toggleForgot(false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: LinkUpColors.border),
                                          minimumSize: const Size(0, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: LinkUpGradientButton(
                                        label: 'Send reset',
                                        isLoading: _forgotLoading,
                                        onPressed: _submitForgot,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _AuthHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: top + 154,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0f4a7a), Color(0xff2da5f6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
              Image.asset('assets/Vector Smart Object 2.png', height: 34),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Join the Caribbean & LatAm super-app',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedAuthSwitch extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedAuthSwitch({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xfff2f6fb),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _SegmentButton(label: 'Create account', active: selectedIndex == 0, onTap: () => onChanged(0)),
          _SegmentButton(label: 'Sign in', active: selectedIndex == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: active ? const Color(0xff111827) : const Color(0xff65748d),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  final Widget child;
  const _WebCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGoogle = icon == 'G';
    final isAsset = icon.endsWith('.png');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LinkUpColors.border),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAsset)
              Image.asset(icon, height: 22, width: 22)
            else
              Text(
                icon,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  color: isGoogle ? const Color(0xffea4335) : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                color: LinkUpColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrLine extends StatelessWidget {
  const _OrLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: LinkUpColors.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                fontFamily: 'OpenSans',
                color: Color(0xff93a4b8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: Divider(color: LinkUpColors.border)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'OpenSans',
        color: Color(0xff64748b),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _HandleStatusRow extends StatelessWidget {
  final String status;
  final String message;

  const _HandleStatusRow({required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    final color = isAvailable ? const Color(0xff16a34a) : const Color(0xffd97706);
    final bg = isAvailable ? const Color(0xffecfdf5) : const Color(0xfffff7ed);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isAvailable ? 'Available' : 'Waiting',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                color: Color(0xff93a4b8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xff93a4b8)),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Bank-level encryption · identity-verified',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Color(0xff93a4b8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
