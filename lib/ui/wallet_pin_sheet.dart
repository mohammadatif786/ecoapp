import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/wallet_demo_service.dart';
import '../services/linkup_api_service.dart';

Future<bool> openWalletPinSetup(BuildContext context) async {
  if (await WalletDemoService.hasPin()) {
    final verified = await _verifyCurrentPin(context, title: 'Enter current PIN', subtitle: 'Confirm it is you before changing your PIN.');
    if (!verified) return false;
  }

  final created = await _createNewPin(context);
  if (created) {
    Get.snackbar('Transaction PIN saved', 'Your 4-digit send PIN is now active.', snackPosition: SnackPosition.BOTTOM);
  }
  return created;
}

Future<bool> verifyWalletPinForSend(BuildContext context, double amount) async {
  final amountLabel = WalletDemoService.money(amount);
  final controller = TextEditingController();
  String error = '';
  var tries = 0;

  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submit() async {
              final pin = controller.text;
              if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                setDialogState(() => error = 'Enter all 4 digits');
                return;
              }
              setDialogState(() => error = 'Verifying...');
              try {
                final res = await LinkupApiService.verifyTransactionPin(pin: pin);
                if (res['success'] == true) {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                } else {
                  tries += 1;
                  final msg = res['message']?.toString() ?? 'Incorrect PIN.';
                  if (tries >= 3) {
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop(false);
                    Get.snackbar('Transfer cancelled', 'Too many incorrect PIN attempts.', snackPosition: SnackPosition.BOTTOM);
                  } else {
                    setDialogState(() {
                      controller.clear();
                      error = msg;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() => error = 'Verification error: $e');
              }
            }

            return _pinDialogShell(
              dialogContext: dialogContext,
              icon: Icons.lock_outline_rounded,
              title: 'Enter your PIN',
              subtitle: 'Required to send $amountLabel.',
              child: Column(
                children: [
                  _pinField(
                    controller: controller,
                    onSubmitted: () => submit(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 18,
                    child: Text(error, style: const TextStyle(color: Color(0xffe11d48), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  _pinContinueButton(
                    onPressed: submit,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result == true;
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
  }
}

Future<bool> _verifyCurrentPin(
  BuildContext context, {
  required String title,
  required String subtitle,
  String cancelMessage = 'PIN verification cancelled',
}) async {
  final savedPin = await WalletDemoService.getPin();
  var tries = 0;

  while (tries < 3) {
    final pin = await _pinPrompt(
      context,
      title: title,
      subtitle: tries == 0 ? subtitle : 'Incorrect PIN · ${3 - tries} ${3 - tries == 1 ? 'try' : 'tries'} left.',
      icon: Icons.lock_outline_rounded,
    );
    if (pin == null) return false;
    if (pin == savedPin) return true;
    tries += 1;
  }

  Get.snackbar(cancelMessage, 'Too many incorrect PIN attempts.', snackPosition: SnackPosition.BOTTOM);
  return false;
}

Future<bool> _createNewPin(
  BuildContext context, {
  String title = 'Create a 4-digit PIN',
  String subtitle = 'This PIN protects wallet sends.',
}) async {
  final pin = await _createPinPrompt(
    context,
    title: title,
    subtitle: subtitle,
  );
  if (pin == null) return false;
  await WalletDemoService.setPin(pin);
  return true;
}

Future<String?> _pinPrompt(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
}) async {
  if (!context.mounted) return null;
  final controller = TextEditingController();
  String error = '';

  try {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return _pinDialogShell(
              dialogContext: dialogContext,
              icon: icon,
              title: title,
              subtitle: subtitle,
              child: Column(
                children: [
                  _pinField(
                    controller: controller,
                    onSubmitted: () => _submitPin(controller.text, setDialogState, (message) => error = message, dialogContext),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 18,
                    child: Text(error, style: const TextStyle(color: Color(0xffe11d48), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  _pinContinueButton(
                    onPressed: () => _submitPin(controller.text, setDialogState, (message) => error = message, dialogContext),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
  }
}

Future<String?> _createPinPrompt(
  BuildContext context, {
  required String title,
  required String subtitle,
}) async {
  if (!context.mounted) return null;
  final firstController = TextEditingController();
  final secondController = TextEditingController();
  String error = '';

  try {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submit() {
              final first = firstController.text;
              final second = secondController.text;
              if (!RegExp(r'^\d{4}$').hasMatch(first) || !RegExp(r'^\d{4}$').hasMatch(second)) {
                setDialogState(() => error = 'Enter all 4 digits twice');
                return;
              }
              if (first != second) {
                setDialogState(() => error = 'PINs did not match');
                return;
              }
              Navigator.of(dialogContext).pop<String>(first);
            }

            return _pinDialogShell(
              dialogContext: dialogContext,
              icon: Icons.shield_outlined,
              title: title,
              subtitle: subtitle,
              child: Column(
                children: [
                  _pinField(controller: firstController, hint: 'New PIN', onSubmitted: submit),
                  const SizedBox(height: 12),
                  _pinField(controller: secondController, hint: 'Confirm PIN', onSubmitted: submit),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 18,
                    child: Text(error, style: const TextStyle(color: Color(0xffe11d48), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  _pinContinueButton(onPressed: submit),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      firstController.dispose();
      secondController.dispose();
    });
  }
}

Widget _pinDialogShell({
  required BuildContext dialogContext,
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xff0b2942), Color(0xff1e3a5f)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Row(
              children: [
                const Text('Transaction PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop<String>(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(color: const Color(0xff2d98e5), borderRadius: BorderRadius.circular(18)),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12, height: 1.35)),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _pinField({
  required TextEditingController controller,
  required VoidCallback onSubmitted,
  String hint = '••••',
}) {
  return TextField(
    controller: controller,
    autofocus: hint == '••••',
    obscureText: true,
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    maxLength: 4,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
    decoration: InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.35), letterSpacing: hint == '••••' ? 8 : 1, fontSize: hint == '••••' ? 28 : 14, fontWeight: FontWeight.w800),
      filled: true,
      fillColor: const Color(0xfff1f5f9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xff2d98e5), width: 2)),
    ),
    onSubmitted: (_) => onSubmitted(),
  );
}

Widget _pinContinueButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2d98e5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    ),
  );
}

void _submitPin(
  String value,
  StateSetter setDialogState,
  void Function(String message) setError,
  BuildContext dialogContext,
) {
  if (!RegExp(r'^\d{4}$').hasMatch(value)) {
    setDialogState(() => setError('Enter all 4 digits'));
    return;
  }
  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop<String>(value);
  }
}
