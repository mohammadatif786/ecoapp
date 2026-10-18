import 'package:flutter/material.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Mirrors web `OTPVerification.vue` (wizard phone step).
class WizardOtpSheet extends StatefulWidget {
  final String phone;
  final String otpToken;
  final VoidCallback onVerified;
  final VoidCallback? onCancel;

  const WizardOtpSheet({
    super.key,
    required this.phone,
    required this.otpToken,
    required this.onVerified,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String phone,
    required String otpToken,
    required VoidCallback onVerified,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: WizardOtpSheet(
          phone: phone,
          otpToken: otpToken,
          onVerified: onVerified,
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  State<WizardOtpSheet> createState() => _WizardOtpSheetState();
}

class _WizardOtpSheetState extends State<WizardOtpSheet> {
  late String _otpToken;
  String _otp = '';
  String? _error;
  String? _success;
  bool _loading = false;
  bool _resendDisabled = true;
  int _resendSeconds = 30;

  @override
  void initState() {
    super.initState();
    _otpToken = widget.otpToken;
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendDisabled = true;
    _resendSeconds = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) _resendDisabled = false;
      });
      return _resendSeconds > 0;
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LinkupApiService.verifyOtp(otpToken: _otpToken, otp: _otp);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onVerified();
    } on LinkupApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LinkupApiService.resendOtp(_otpToken);
      setState(() => _success = 'A new code has been sent');
      _startResendCooldown();
    } on LinkupApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verify your phone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel ?? () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Enter the 6-digit code sent to ${widget.phone}',
              style: const TextStyle(color: LinkUpColors.textMuted),
            ),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 6,
              keyboardType: TextInputType.number,
              onChanged: (v) => _otp = v,
              onCompleted: (v) {
                _otp = v;
                _verify();
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 52,
                fieldWidth: 44,
                activeColor: LinkUpColors.brandBlue,
                selectedColor: LinkUpColors.brandBlue,
                inactiveColor: LinkUpColors.border,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 8),
              Text(_success!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading || _otp.length != 6 ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinkUpColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _resendDisabled || _loading ? null : _resend,
                  child: const Text('Resend code'),
                ),
                Text(
                  _resendDisabled ? 'Resend in ${_resendSeconds}s' : '',
                  style: const TextStyle(color: LinkUpColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
