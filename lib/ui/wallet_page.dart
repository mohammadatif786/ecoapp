import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'vibes_page.dart';
import 'eats_page.dart';
import 'live_page.dart';
import 'chat_home_page.dart';
import '../services/wallet_demo_service.dart';
import '../services/linkup_api_service.dart';
import '../model/wallet_result.dart';
import 'wallet_pin_sheet.dart';
import 'package:link_up/ui/notification_page.dart';

void _logAddContact(String step, [Object? extra]) {
  final suffix = extra == null ? '' : ' | $extra';
  debugPrint('[AddContact] $step$suffix');
}

void _logAsue(String step, [Object? extra]) {
  final suffix = extra == null ? '' : ' | $extra';
  debugPrint('[Asue] $step$suffix');
}

class WalletPage extends StatefulWidget {
  final bool triggerBuyCoins;
  final bool scrollToPayBills;
  final bool showSavings;
  const WalletPage({super.key, this.triggerBuyCoins = false, this.scrollToPayBills = false, this.showSavings = false});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final HomeController homeController = Get.find(tag: HomeController().toString());
  final ChatController chatController = Get.find(tag: ChatController().toString());
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _payBillsKey = GlobalKey();
  double _walletBalance = WalletDemoService.fallbackWalletBalance;
  List<WalletCurrency> _currencies = WalletDemoService.fallbackCurrencies;
  WalletSendLimits _sendLimits = const WalletSendLimits(standard: 2500, premium: 10000);
  double _sent24hAmount = 0;
  bool _showSavingsPanel = false;
  int _selectedCardTheme = 0;
  bool _isCardAddedToWallet = false;
  bool _walletApiLoaded = false;
  bool _walletLoading = false;
  int _coinBalance = 0;
  List<WalletTransaction> _transactions = const [];
  List<WalletContact> _walletContacts = const [];
  List<WalletContact> _suggestedUsers = const [];
  List<WalletMoneyRequest> _sentRequests = const [];
  List<WalletActivityItem> _activityItems = const [];
  bool _activityLoading = false;
  WalletActiveAsue? _activeAsue;

  static const List<List<Color>> _cardThemePresets = <List<Color>>[
    <Color>[Color(0xff1e3a8a), Color(0xff2d98e5), Color(0xff7c3aed)],
    <Color>[Color(0xffffa600), Color(0xffef4444)],
    <Color>[Color(0xff06a77d), Color(0xff14b8a6)],
    <Color>[Color(0xff0f172a), Color(0xff334155)],
  ];

  List<Color> get _activeCardTheme => _cardThemePresets[_selectedCardTheme];
  String get _currentFullName => LinkUpCurrentUser.fullName();
  String get _currentCardName => _currentFullName.toUpperCase();
  String get _currentCardFirstName => LinkUpCurrentUser.firstName().toUpperCase();

  @override
  void initState() {
    super.initState();
    _reloadWalletBridge();
    if (widget.triggerBuyCoins) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWalletTopUps(context, initialTab: 1);
      });
    }
    if (widget.showSavings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showSavingsPanel = true);
      });
    }
    if (widget.scrollToPayBills) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showSavingsPanel = false);
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = _payBillsKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, alignment: 0.1);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadWalletBridge() async {
    final currencies = await WalletDemoService.loadCurrencies();
    final limits = await WalletDemoService.loadSendLimits();
    final sent = await WalletDemoService.sent24h();
    if (mounted) {
      setState(() {
        _currencies = currencies;
        _sendLimits = limits;
        _sent24hAmount = sent;
      });
    }
    await _loadWalletApi();
  }

  Future<void> _loadWalletApi({String reason = 'unspecified'}) async {
    _logAddContact('loadWalletApi start', 'reason=$reason mounted=$mounted');
    if (mounted) setState(() => _walletLoading = true);
    try {
      final result = await LinkupApiService.fetchUserWallet();
      _logAddContact('loadWalletApi response', 'mounted=$mounted contacts=${result.contacts.length} users=${result.suggestedUsers.length} sentRequests=${result.sentRequests.length} activeAsue=${result.activeAsue?.id}');
      if (!mounted) return;
      homeController.applyWallet(
        amount: result.currentBalance.toStringAsFixed(2),
        coinCount: result.coinBalance,
      );
      setState(() {
        _walletBalance = result.currentBalance;
        _coinBalance = result.coinBalance;
        _transactions = result.transactions;
        _walletContacts = result.contacts;
        _suggestedUsers = result.suggestedUsers;
        _sentRequests = result.sentRequests;
        _activeAsue = result.activeAsue;
        _walletApiLoaded = true;
        _walletLoading = false;
      });
      _logAddContact('loadWalletApi setState done');
      _logAsue(
        'wallet index',
        'reason=$reason activeAsue=${result.activeAsue == null ? 'null (completed or none)' : 'id=${result.activeAsue!.id} status=${result.activeAsue!.status} turn=${result.activeAsue!.currentTurn} payoutAccepted=${result.activeAsue!.payoutAccepted} accepted=${result.activeAsue!.acceptedCount}/${result.activeAsue!.maxMembers}'}',
      );
      await _loadWalletActivity();
    } catch (e) {
      _logAddContact('loadWalletApi failed', e);
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _loadWalletActivity() async {
    if (mounted) setState(() => _activityLoading = true);
    try {
      final items = await LinkupApiService.fetchWalletActivity();
      if (!mounted) return;
      setState(() {
        _activityItems = items;
        _activityLoading = false;
      });
    } catch (e) {
      debugPrint('fetchWalletActivity failed: $e');
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  int? get _currentUserId => LinkUpCurrentUser.user?.laravelId;

  WalletAsueMember? _currentAsueMember(WalletActiveAsue? asue) {
    if (asue == null) return null;
    return asue.memberForUser(
      userId: _currentUserId,
      tag: LinkUpCurrentUser.handle(fallback: ''),
      email: LinkUpCurrentUser.email(),
    );
  }

  Future<void> _openDigitalAsue(BuildContext context) async {
    _logAsue('digital asue tapped', 'walletApiLoaded=$_walletApiLoaded currentUserId=$_currentUserId');
    await _loadWalletApi(reason: 'before-asue');
    if (!mounted) return;

    final asue = _activeAsue;
    final member = _currentAsueMember(asue);
    _logAsue(
      'digital asue route',
      'asueId=${asue?.id} name=${asue?.name} status=${asue?.status} memberId=${member?.id} participation=${member?.participationStatus}',
    );

    if (asue != null && member != null && member.isInvited) {
      _showAsueInvitePopup(asue, member);
      return;
    }

    if (asue != null && asue.allMembersAccepted) {
      _showAsueActivePopup(asue);
      return;
    }

    await _showStartAsue(context);
  }

  void _showAsueInvitePopup(WalletActiveAsue asue, WalletAsueMember currentMember) {
    final asueId = currentMember.asueId > 0 ? currentMember.asueId : asue.id;
    _logAsue('show invite popup', 'asueId=$asueId pivotAsueId=${currentMember.asueId} members=${asue.invitedUsers.length}');
    var accepting = false;
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        Future<void> acceptInvite() async {
          if (accepting) return;
          if (asueId <= 0) {
            _logAsue('accept skipped, missing pivot asue_id');
            _notifyWallet('Could not accept invitation', 'Missing Asue id on this invitation.');
            return;
          }
          setDialogState(() => accepting = true);
          _logAsue('accept invitation tapped', 'POST /api/regular-user/wallet/asues/$asueId/accept-participation');
          try {
            await LinkupApiService.acceptWalletAsueParticipation(asueId: asueId);
            _logAsue('accept invitation done');
          } catch (err, st) {
            _logAsue('accept invitation failed', '$err\n$st');
            if (dialogContext.mounted) setDialogState(() => accepting = false);
            if (mounted) {
              _notifyWallet('Could not accept invitation', err.toString().replaceFirst('Exception: ', ''));
            }
            return;
          }
          if (dialogContext.mounted) {
            final navigator = Navigator.of(dialogContext);
            if (navigator.canPop()) navigator.pop();
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
          await _loadWalletApi(reason: 'after-asue-accept');
          if (!mounted) return;
          _notifyWallet('Invitation accepted', 'You joined ${asue.name}.');
        }

        return _whiteDialogShell(
          context,
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asue.name.isEmpty ? 'Asue' : asue.name,
                        style: const TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.w900, fontSize: 28),
                      ),
                    ),
                    IconButton(
                      onPressed: accepting
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (dialogContext.mounted) {
                                final navigator = Navigator.of(dialogContext);
                                if (navigator.canPop()) navigator.pop();
                              }
                            },
                      icon: const Icon(Icons.close, color: Color(0xff64748b)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(color: const Color(0xff0f766e), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL POT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Text('\$${asue.totalPot.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
                            const SizedBox(height: 6),
                            Text('Fee (3%): -\$${asue.fee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(height: 1, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text('Payout: \$${asue.payout.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
                          const SizedBox(height: 4),
                          Text(asue.status.isEmpty ? 'inviting' : asue.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...asue.membersByPosition.map((member) => _asueInviteMemberRow(asue, member)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff7ed),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xfffdba74)),
                  ),
                  child: Text(
                    'Awaiting participation confirmations: ${asue.acceptedCount} / ${asue.maxMembers} accepted.',
                    style: const TextStyle(color: Color(0xffc2410c), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: accepting ? null : acceptInvite,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xff0f766e), borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: accepting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : const Text('Accept Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      barrierDismissible: false,
    );
  }

  void _showAsueActivePopup(WalletActiveAsue asue) {
    var view = asue;
    var busyAction = '';
    var completed = false;
    final asueId = () {
      final mine = _currentAsueMember(view)?.asueId ?? 0;
      if (mine > 0) return mine;
      for (final member in view.invitedUsers) {
        if (member.asueId > 0) return member.asueId;
      }
      return view.id;
    }();
    _logAsue(
      'show active popup',
      'asueId=$asueId status=${view.status} turn=${view.currentTurn} payoutAccepted=${view.payoutAccepted} accepted=${view.acceptedCount}/${view.maxMembers}',
    );

    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        void popLocal() {
          FocusManager.instance.primaryFocus?.unfocus();
          if (dialogContext.mounted) {
            final navigator = Navigator.of(dialogContext);
            if (navigator.canPop()) navigator.pop();
          }
        }

        Future<void> runAction({
          required String label,
          required Future<void> Function() request,
          required String successTitle,
          required String successMessage,
        }) async {
          if (busyAction.isNotEmpty || completed) return;
          if (asueId <= 0) {
            _notifyWallet('Could not simulate', 'Missing Asue id.');
            return;
          }
          setDialogState(() => busyAction = label);
          _logAsue('$label tapped', 'asueId=$asueId currentUserId=$_currentUserId turn=${view.currentTurn} highlight=${view.highlightTurn} payoutAccepted=${view.payoutAccepted}');
          try {
            await request();
            _logAsue('$label api done', 'reloading wallet index');
          } catch (err, st) {
            _logAsue('$label failed', '$err\n$st');
            if (dialogContext.mounted) setDialogState(() => busyAction = '');
            if (mounted) {
              _notifyWallet('Could not $label', err.toString().replaceFirst('Exception: ', ''));
            }
            return;
          }
          await _loadWalletApi(reason: 'after-$label');
          if (!mounted) return;
          if (_activeAsue == null) {
            completed = true;
            _logAsue('asue completed', 'activeAsue is null after $label — circle finished');
          } else {
            view = _activeAsue!;
            _logAsue(
              'wallet index after $label',
              'id=${view.id} status=${view.status} turn=${view.currentTurn} highlight=${view.highlightTurn} payoutAccepted=${view.payoutAccepted}',
            );
          }
          if (dialogContext.mounted) setDialogState(() => busyAction = '');
          if (completed) {
            _notifyWallet('Asue complete', '${view.name} has finished all cycles.');
          } else {
            _notifyWallet(successTitle, successMessage);
          }
        }

        return _whiteDialogShell(
          context,
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        view.name.isEmpty ? 'Asue' : view.name,
                        style: const TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.w900, fontSize: 28),
                      ),
                    ),
                    IconButton(
                      onPressed: busyAction.isNotEmpty ? null : popLocal,
                      icon: const Icon(Icons.close, color: Color(0xff64748b)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(color: const Color(0xff0f766e), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL POT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Text('\$${view.totalPot.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
                            const SizedBox(height: 6),
                            Text('Fee (3%): -\$${view.fee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(height: 1, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text('Payout: \$${view.payout.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
                          const SizedBox(height: 4),
                          Text(completed ? 'completed' : (view.status.isEmpty ? 'active' : view.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...view.membersByPosition.map((member) => _asueActiveMemberRow(view, member, completed: completed)),
                const SizedBox(height: 6),
                _asueCycleBanner(view, completed: completed),
                if (!completed) ...[
                const SizedBox(height: 14),
                Builder(builder: (_) {
                  final me = _currentAsueMember(view);
                  final waitingOnMe = me != null && me.position == view.highlightTurn && !view.payoutDoneFor(me);
                  final showAccept = waitingOnMe;
                  final showCycle = !waitingOnMe || !view.hasPaidPayout;
                  return Row(
                    children: [
                      if (showAccept)
                        Expanded(
                          child: InkWell(
                            onTap: busyAction.isNotEmpty
                                ? null
                                : () => runAction(
                                      label: 'simulate-accept',
                                      request: () => LinkupApiService.simulateWalletAsueAccept(asueId: asueId),
                                      successTitle: 'Payout accepted',
                                      successMessage: '${view.highlightedMember?.name ?? 'Member'} payout was accepted.',
                                    ),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(color: const Color(0xffe8eef5), borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                child: busyAction == 'simulate-accept'
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xff334155)))
                                    : const Text('Simulate Accepts', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                      if (showAccept && showCycle) const SizedBox(width: 10),
                      if (showCycle)
                        Expanded(
                          child: InkWell(
                            onTap: busyAction.isNotEmpty
                                ? null
                                : () => runAction(
                                      label: 'simulate-cycle',
                                      request: () => LinkupApiService.simulateWalletAsueWeekPayout(asueId: asueId),
                                      successTitle: 'Week/payout simulated',
                                      successMessage: 'The next week payout was simulated.',
                                    ),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(color: const Color(0xff0f766e), borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                child: busyAction == 'simulate-cycle'
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                    : const Text('Simulate Week/Payout', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                ],
              ],
            ),
          ),
        );
      }),
      barrierDismissible: false,
    );
  }

  Widget _asueCycleBanner(WalletActiveAsue view, {required bool completed}) {
    if (completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xffecfdf5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xff6ee7b7)),
        ),
        child: const Text(
          'This Asue is complete. Wallet index returned no activeAsue.',
          style: TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w800, fontSize: 12, height: 1.35),
        ),
      );
    }
    final paidMember = view.currentTurnMember;
    if (view.payoutAccepted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xffecfdf5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xff6ee7b7)),
        ),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w800, fontSize: 12, height: 1.35),
            children: [
              const TextSpan(text: 'Payout accepted for '),
              TextSpan(
                text: paidMember?.name ?? 'this member',
                style: const TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
              ),
              TextSpan(text: ' · \$${view.payout.toStringAsFixed(2)} (after fee).'),
            ],
          ),
        ),
      );
    }
    final turnMember = view.highlightedMember;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffff7ed),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xfffdba74)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: Color(0xffc2410c), fontWeight: FontWeight.w800, fontSize: 12, height: 1.35),
          children: [
            const TextSpan(text: 'Waiting for '),
            TextSpan(
              text: turnMember?.name ?? 'the current member',
              style: const TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
            ),
            TextSpan(text: ' to accept the payout of \$${view.payout.toStringAsFixed(2)} (after fee).'),
          ],
        ),
      ),
    );
  }

  Widget _asueActiveMemberRow(WalletActiveAsue asue, WalletAsueMember member, {bool completed = false}) {
    final isCurrentTurn = asue.isCurrentTurn(member);
    final paid = completed || asue.payoutDoneFor(member);
    final turnDate = asue.payoutDateFor(member);
    final dateLabel = turnDate == null
        ? ''
        : '${turnDate.month.toString().padLeft(2, '0')}/${turnDate.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrentTurn ? const Color(0xff0f766e) : const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                if (dateLabel.isNotEmpty)
                  Text(dateLabel, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 10)),
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrentTurn ? const Color(0xff0f766e) : const Color(0xffe2e8f0),
                  child: Text(
                    '${member.position <= 0 ? 1 : member.position}',
                    style: TextStyle(color: isCurrentTurn ? Colors.white : const Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(member.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          Text(
            paid ? 'PAID' : 'PENDING',
            style: TextStyle(
              color: paid ? const Color(0xff047857) : const Color(0xff94a3b8),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _asueInviteMemberRow(WalletActiveAsue asue, WalletAsueMember member) {
    final accepted = member.isAccepted;
    final turnDate = asue.payoutDateFor(member);
    final dateLabel = turnDate == null
        ? ''
        : '${turnDate.month.toString().padLeft(2, '0')}/${turnDate.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accepted ? const Color(0xff0f766e) : const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                if (dateLabel.isNotEmpty)
                  Text(dateLabel, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 10)),
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accepted ? const Color(0xffe2e8f0) : const Color(0xff0f766e),
                  child: Text(
                    '${member.position <= 0 ? 1 : member.position}',
                    style: TextStyle(color: accepted ? const Color(0xff334155) : Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(member.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accepted ? const Color(0xffecfdf5) : const Color(0xffffedd5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              accepted ? 'ACCEPTED' : 'INVITED',
              style: TextStyle(
                color: accepted ? const Color(0xff047857) : const Color(0xffc2410c),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<WalletContact> get _activeContacts =>
      _walletApiLoaded ? _walletContacts : WalletDemoService.contacts;

  List<WalletContact> get _addableUsers {
    final savedIds = _walletContacts.map((contact) => contact.userId).whereType<int>().toSet();
    return _suggestedUsers.where((user) => user.userId == null || !savedIds.contains(user.userId)).toList();
  }

  WalletContact? _matchUserToAdd({required String name, required String tag}) {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceFirst(RegExp(r'^[~@]'), '');

    final needleTag = normalize(tag);
    final needleName = name.trim().toLowerCase();
    if (needleTag.isEmpty && needleName.isEmpty) return null;

    WalletContact? matchIn(List<WalletContact> users, {required bool exactTag}) {
      for (final user in users) {
        final userTag = normalize(user.tag);
        if (exactTag) {
          if (needleTag.isNotEmpty && userTag == needleTag) return user;
          continue;
        }
        if (needleTag.isNotEmpty && (userTag.contains(needleTag) || user.tag.toLowerCase().contains(needleTag))) {
          return user;
        }
        if (needleName.isNotEmpty && user.name.toLowerCase().contains(needleName)) return user;
      }
      return null;
    }

    return matchIn(_addableUsers, exactTag: true) ?? matchIn(_addableUsers, exactTag: false);
  }

  List<WalletContact> _usersMatchingSearch(String query) {
    return _peopleMatchingQuery(query, _addableUsers);
  }

  List<WalletContact> _peopleMatchingQuery(String query, List<WalletContact> pool) {
    final raw = query.trim().toLowerCase();
    if (raw.isEmpty) return const [];
    final needle = raw.replaceFirst(RegExp(r'^[~@]'), '');
    final searchable = pool.where((user) => user.userId != null).toList();
    if (needle.isEmpty) return searchable;
    return searchable.where((user) {
      final tag = user.tag.toLowerCase().replaceFirst(RegExp(r'^@'), '');
      return tag.contains(needle) || user.name.toLowerCase().contains(needle);
    }).toList();
  }

  void _notifyWallet(String title, String message) {
    _logAddContact('notifyWallet scheduled', '$title / $message mounted=$mounted');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logAddContact('notifyWallet frame', 'mounted=$mounted');
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        _logAddContact('notifyWallet skipped, no ScaffoldMessenger');
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('$title. $message'),
          behavior: SnackBarBehavior.floating,
        ));
      _logAddContact('notifyWallet shown');
    });
  }

  String get _displayBalance =>
      _walletApiLoaded ? _walletBalance.toStringAsFixed(2) : homeController.walletAmount;

  int get _displayCoins => _walletApiLoaded ? _coinBalance : homeController.coins;

  ImageProvider _contactAvatar(WalletContact contact) {
    final url = contact.imageUrl;
    if (url != null && url.startsWith('http')) return NetworkImage(url);
    return AssetImage(contact.imageAsset);
  }

  IconData _transactionIcon(WalletTransaction txn) {
    if (txn.isDeposit || txn.type == 'recharge') return Icons.add_circle_outline;
    if (txn.isPositive) return Icons.call_received_rounded;
    if (txn.type.startsWith('bank_withdrawal')) return Icons.account_balance_outlined;
    if (txn.type.startsWith('asue')) return Icons.groups_outlined;
    return Icons.send;
  }

  Color _transactionColor(WalletTransaction txn) {
    return txn.isPositive ? const Color(0xff10b981) : Colors.blueGrey;
  }

  IconData _activityTypeIcon(WalletActivityItem item) {
    switch (item.type) {
      case 'recharge':
        return Icons.add_circle_outline;
      case 'money_request_payment':
        return Icons.handshake_outlined;
      case 'asue_contribution':
      case 'asue_payout':
        return Icons.groups_outlined;
      case 'wallet':
        return item.isPositive ? Icons.account_balance_wallet_outlined : Icons.payments_outlined;
      case 'p2p_transfer':
        return item.isPositive ? Icons.call_received_rounded : Icons.send;
    }
    if (item.type.contains('withdraw')) return Icons.account_balance_outlined;
    if (item.type.contains('coin')) return Icons.monetization_on_outlined;
    return item.isPositive ? Icons.call_received_rounded : Icons.send;
  }

  WalletContact get _fallbackContact => const WalletContact(
        name: 'Recipient',
        tag: '',
        imageAsset: 'assets/profile2.jpg',
        currency: WalletDemoService.myCurrency,
        country: '',
      );

  bool _isPremiumSubscriber() {
    try {
      final authController = Get.find<AuthController>(tag: AuthController().toString());
      final dynamic user = authController.user?.value;
      final dynamic subscriptions = user?.subscription;
      if (subscriptions is Iterable) {
        final now = DateTime.now();
        for (final dynamic item in subscriptions) {
          if (item is Map && item['expiry'] is int && DateTime.fromMillisecondsSinceEpoch(item['expiry'] as int).isAfter(now)) {
            return true;
          }
        }
      }
      return user?.isTopShelf == true || user?.isRestaurant == true || user?.isClub == true || user?.isLiveStream == true;
    } catch (_) {
      return false;
    }
  }

  double get _dailyLimit => _isPremiumSubscriber() ? _sendLimits.premium : _sendLimits.standard;

  double get _remaining24h => math.max(0, _dailyLimit - _sent24hAmount);

  String _money(double amount) => WalletDemoService.money(amount);

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  void _closeWalletOverlay<T>([T? result]) {
    final overlayContext = Get.overlayContext;
    if (overlayContext != null) {
      final navigator = Navigator.of(overlayContext, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop<T>(result);
        return;
      }
    }

    final currentContext = Get.context;
    if (currentContext != null) {
      final navigator = Navigator.of(currentContext, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop<T>(result);
        return;
      }
    }

    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back(result: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f7ff),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _locationBar(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xff2d98e5),
                onRefresh: _reloadWalletBridge,
                child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                children: [
                  const SizedBox(height: 14),
                  const Text('Wallet', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 26)),
                  const SizedBox(height: 14),
                  _balanceCard(context),
                  const SizedBox(height: 12),
                  _coinsCard(context),
                  const SizedBox(height: 12),
                  _actionGrid(context),
                  const SizedBox(height: 18),
                  _quickLinkUps(context),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _showSavingsPanel ? _linkUpSaveCard(context) : Container(key: _payBillsKey, child: _payBills(context)),
                  ),
                  const SizedBox(height: 18),
                  _featureGrid(context),
                  const SizedBox(height: 12),
                  _savingsBar(context),
                  const SizedBox(height: 20),
                  _recentActivity(context),
                  const SizedBox(height: 30),
                ],
              ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: _ui(context, 60),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 18)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2298f2), Color(0xff1976d2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 22,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Text('ui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Link', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                TextSpan(text: 'up', style: TextStyle(color: Color(0xffffde3b), fontSize: 21, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 5),
                Text('$_displayCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const LinkUpNotificationBell(
            iconSize: 29,
            badgeSize: 16,
            badgeFontSize: 8,
          ),
          const SizedBox(width: 10),
          LinkUpCurrentUserAvatar(
            radius: 19,
            innerRadius: 17,
            borderColor: Colors.white24,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
          ),
        ],
      ),
    );
  }

  Widget _locationBar(BuildContext context) {
    return const LinkupLocationBar(
      height: 32,
      horizontalPadding: 16,
      iconSize: 17,
      fontSize: 12,
      changeFontSize: 12,
      textColor: Color(0xff1e293b),
      changeColor: Color(0xff0878d8),
      iconColor: Color(0xff2d98e5),
      border: Border(bottom: BorderSide(color: Color(0xffe5eef8), width: 1)),
    );
  }

  Widget _balanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff071327), Color(0xff183f66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xff0f172a).withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 15),
              const SizedBox(width: 7),
              Text('LINK UP DIGITAL WALLET', style: TextStyle(color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$$_displayBalance', style: const TextStyle(color: Colors.white, fontSize: 37, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _cardButton(
                  context,
                  'Scan to Pay',
                  Icons.qr_code_scanner,
                  const Color(0xff12b8c5),
                  Colors.white,
                  () => _showPayMerchant(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cardButton(
                  context,
                  'My QR',
                  Icons.qr_code_2,
                  Colors.white.withOpacity(0.14),
                  Colors.white,
                  () => _showMyQr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _walletMiniButton('Top Up', Icons.add, const Color(0xff35a9f4), () => _showWalletTopUps(context)),
              const SizedBox(width: 8),
              _walletMiniButton('Transfer', Icons.swap_horiz_rounded, Colors.white.withOpacity(0.14), () => _showTransfer(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletMiniButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _coinsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffffa600), Color(0xffffc01f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xffffa600).withOpacity(0.16), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.diamond_outlined, color: Colors.white, size: 16),
              SizedBox(width: 7),
              Text('LINK UP COINS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 7),
          Text('$_displayCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36)),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _showWalletTopUps(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.32), borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 17),
                    SizedBox(width: 5),
                    Text('Buy More', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardButton(BuildContext context, String text, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _actionGrid(BuildContext context) {
    final actions = [
      ['Send Money', Icons.send, const Color(0xff2d98e5), () => _showSendMoney(context)],
      ['Requested', Icons.download, const Color(0xff10b981), () => _showRequestedMoney(context)],
      ['Request', Icons.handshake_outlined, const Color(0xfff59e0b), () => _showRequestMoney(context)],
      ['Pay Bills', Icons.receipt_long, const Color(0xff0ea5e9), () => setState(() => _showSavingsPanel = false)],
      ['Merchant', Icons.storefront, const Color(0xff8b5cf6), () => _showPayMerchant(context)],
      ['Activity', Icons.history, const Color(0xff64748b), () => _showWalletActivity(context)],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: actions[index][3] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(actions[index][1] as IconData, color: actions[index][2] as Color, size: 24),
                const SizedBox(height: 8),
                Text(actions[index][0] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xff334155))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickLinkUps(BuildContext context) {
    final contacts = _activeContacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK LINK UPS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickContact('New', Icons.add, null, () => _showAddContact(context)),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 18),
                  child: Text('No contacts yet', style: TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: 12)),
                )
              else
                ...contacts.map((contact) {
                  return _quickContact(
                    contact.shortName,
                    null,
                    contact.imageUrl ?? contact.imageAsset,
                    () => _showSendMoney(context, initial: contact),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickContact(String name, IconData? icon, String? img, VoidCallback onTap) {
    ImageProvider? imageProvider;
    if (img != null) {
      if (img.startsWith('http')) {
        imageProvider = NetworkImage(img);
      } else {
        imageProvider = AssetImage(img);
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: imageProvider,
              child: icon != null ? Icon(icon, color: Colors.grey, size: 28) : null,
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff334155))),
          ],
        ),
      ),
    );
  }

  Widget _payBills(BuildContext context) {
    return Container(
      key: const ValueKey('pay-bills-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 12)]),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xff169bed), size: 18),
              const SizedBox(width: 8),
              const Text('Pay Bills', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xff1e293b))),
              const Spacer(),
              InkWell(
                onTap: () => _showAddBiller(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('+ Add Biller', style: TextStyle(color: Color(0xff0284e8), fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _billItem(context, 'BPL Electricity', 'Due Jun 18', Icons.bolt, const Color(0xff2d98e5)),
          _billItem(context, 'Cable Bahamas Internet', 'Due Jun 22', Icons.wifi, const Color(0xff2d98e5)),
          _billItem(context, 'Water & Sewerage', 'Due Jun 23', Icons.water_drop, const Color(0xff2d98e5)),
          _billItem(context, 'BTC Mobile', 'Due Jun 28', Icons.phone_android, const Color(0xff2d98e5)),
        ],
      ),
    );
  }

  Widget _billItem(BuildContext context, String name, String due, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xff1e293b))),
                const SizedBox(height: 2),
                Text(due, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showPayBill(context, name, due, icon),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xff0ea5e9), borderRadius: BorderRadius.circular(20)),
              child: const Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        GestureDetector(onTap: () => _showMyCard(context), child: _visaCard('•••• 7560', 'CASSIUS · 07/29')),
        GestureDetector(onTap: () => _openDigitalAsue(context), child: _featureCard('Digital Asue', 'Start a savings circle', const Color(0xff0f766e), Icons.groups)),
        GestureDetector(onTap: () => _showCrypto(context), child: _featureCard('Crypto', r'BTC $96,420 +2.1%' '\n' r'ETH $3,650 +1.4%', const Color(0xff312e81), Icons.currency_bitcoin)),
        GestureDetector(onTap: () => _showBankDetails(context), child: _featureCard('Bank Accounts', 'Manage your bank details', const Color(0xff065f46), Icons.account_balance)),
      ],
    );
  }

  Widget _visaCard(String number, String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _activeCardTheme,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LinkUp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              Icon(Icons.wifi, color: Colors.white.withOpacity(0.8), size: 18),
            ],
          ),
          Row(
            children: [
              Container(
                width: 30,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xffffd700),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                ),
              ),
              const SizedBox(width: 10),
              const Text('•••• 7560', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 9)),
              const Text('Mastercard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _featureCard(String title, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _savingsBar(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _showSavingsPanel = !_showSavingsPanel),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xff059669), Color(0xff12b981)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xff059669).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text('LinkUp Save · High-yield savings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
            Icon(_showSavingsPanel ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _linkUpSaveCard(BuildContext context) {
    return Container(
      key: const ValueKey('linkup-save-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff07966f), Color(0xff20c6a9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xff059669).withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('LinkUp Save', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(999)),
                child: const Text('Powered by Scotiabank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Available Savings Balance', style: TextStyle(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(r'$2,450.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text('Tier ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('Standard', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              SizedBox(width: 16),
              Text('APY ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('3.0%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              SizedBox(width: 16),
              Text('Earned this month ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(r'$8.17', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Text('Standard', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('Premium at ${_money(5000)}', style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: 0.49,
              backgroundColor: Colors.white.withOpacity(0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _saveButton('Deposit', Colors.white, const Color(0xff047857), () => _showSavingsDeposit(context))),
              const SizedBox(width: 10),
              Expanded(child: _saveButton('Withdraw', Colors.white.withOpacity(0.32), Colors.white, () => _showSavingsWithdraw(context))),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showSavingsHistory(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.24), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Sweep 10% of each payout into savings', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 10)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showAutoSave(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Edit', style: TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 13))),
      ),
    );
  }

  Widget _recentActivity(BuildContext context) {
    final items = _activityItems.take(5).toList();
    return Column(
      children: [
        Row(
          children: [
            const Text('Recent Activity', style: TextStyle(color: Color(0xff1e293b), fontWeight: FontWeight.w900, fontSize: 18)),
            const Spacer(),
            TextButton(
              onPressed: () => _showWalletActivity(context),
              child: const Text('See all ›', style: TextStyle(color: Color(0xff2d98e5), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if ((_walletLoading || _activityLoading) && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Color(0xff2d98e5))),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('No recent activity', style: TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700)),
          )
        else
          ...items.map((item) => _activityItem(
                item.title,
                item.signedAmount,
                _activityTypeIcon(item),
                item.isPositive ? const Color(0xff10b981) : Colors.blueGrey,
                subtitle: item.subtitle,
              )),
      ],
    );
  }

  Widget _activityItem(String title, String amount, IconData icon, Color color, {String? subtitle}) {
    bool isNegative = amount.contains('-');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xff1e293b))),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isNegative ? Colors.redAccent : const Color(0xff10b981))),
        ],
      ),
    );
  }


  // CLIENT WALLET CHANGES: send flow with FX preview, 24h limits and transaction PIN.

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  double? _fxQuote(double amount, String toCurrency) {
    return WalletDemoService.fxQuote(_currencies, amount, WalletDemoService.myCurrency, toCurrency);
  }

  Widget _sendContactPill(WalletContact contact, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xffeff6ff) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? const Color(0xff2d98e5) : const Color(0xffe2e8f0), width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: _contactAvatar(contact)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 12)),
                Text('${contact.currency} · ${contact.country}', style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fxPreviewBox(WalletContact person, double amount) {
    if (amount <= 0) return const SizedBox.shrink();

    if (person.currency == WalletDemoService.myCurrency) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xffecfdf5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffa7f3d0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Domestic · same currency', style: TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 3),
            Text('No FX. ${person.name} receives ${WalletDemoService.formatCurrency(_currencies, amount, WalletDemoService.myCurrency)}.', style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      );
    }

    final received = _fxQuote(amount, person.currency);
    final one = _fxQuote(1, person.currency);
    final currency = WalletDemoService.currencyFrom(_currencies, person.currency);
    final isPegged = currency?.mode == 'pegged';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffbfdbfe))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('International transfer', style: TextStyle(color: Color(0xff1d4ed8), fontWeight: FontWeight.w900, fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: isPegged ? const Color(0xffe0f2fe) : const Color(0xfffff7ed), borderRadius: BorderRadius.circular(999)),
                child: Text(isPegged ? 'fixed peg' : 'market rate', style: TextStyle(color: isPegged ? const Color(0xff0369a1) : const Color(0xffc2410c), fontWeight: FontWeight.w900, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${person.name} (${person.country}) receives ${WalletDemoService.formatCurrency(_currencies, received, person.currency)}', style: const TextStyle(color: Color(0xff334155), fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 3),
          Text("1 ${WalletDemoService.myCurrency} ≈ ${one?.toStringAsFixed(4) ?? '—'} ${person.currency} · LinkUp FX spread included", style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _sendLimitBox(double amount) {
    final over = amount > _remaining24h;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: over ? const Color(0xfffff1f2) : const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: over ? const Color(0xfffecdd3) : const Color(0xffe2e8f0)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xff64748b)),
          children: [
            TextSpan(text: '24h send limit ${_money(_dailyLimit)}', style: TextStyle(color: over ? const Color(0xffdc2626) : const Color(0xff334155), fontWeight: FontWeight.w900)),
            const TextSpan(text: ' · '),
            TextSpan(
              text: over ? 'over by ${_money(amount - _remaining24h)}' : '${_money(_remaining24h)} left today',
              style: TextStyle(color: over ? const Color(0xffdc2626) : const Color(0xff64748b), fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendMoney(BuildContext context, {WalletContact? initial}) {
    final contacts = _activeContacts;
    final starting = initial ?? (contacts.isNotEmpty ? contacts.first : _fallbackContact);
    final toController = TextEditingController(text: starting.tag);
    final amountController = TextEditingController();
    WalletContact selectedContact = starting;
    var sheetOpen = true;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void safeSet(VoidCallback fn) {
            if (sheetOpen && sheetContext.mounted) setSheetState(fn);
          }

          final amount = _parseAmount(amountController.text);
          final person = WalletDemoService.resolveContact(toController.text, pool: contacts);

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xff2d98e5), Color(0xff14b8a6)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Send Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                            Text('FX preview, send limits and PIN protection', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          sheetOpen = false;
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('QUICK CONTACTS', style: TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: contacts.map((contact) {
                            return _sendContactPill(contact, selectedContact.tag == contact.tag, () {
                              selectedContact = contact;
                              toController.text = contact.tag;
                              safeSet(() {});
                            });
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('To (@tag or name)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xff1e293b))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: toController,
                        decoration: InputDecoration(
                          hintText: '@username',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xff94a3b8), size: 18),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) {
                          selectedContact = WalletDemoService.resolveContact(toController.text, pool: contacts);
                          safeSet(() {});
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffe2e8f0))),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 22, backgroundImage: _contactAvatar(person)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(person.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 14)),
                                  Text('${person.tag} · ${person.country} · ${person.currency}', style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Color(0xff10b981), size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Amount (BSD)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xff1e293b))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'B\$ ',
                          prefixStyle: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) => safeSet(() {}),
                      ),
                      _fxPreviewBox(person, amount),
                      _sendLimitBox(amount),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _walletSendReview(sheetContext, person, amount),
                          icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                          label: const Text('Review & Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2d98e5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Demo storage uses the same bridge keys as the web handoff: lk_currencies, lk_send_limits, lk_send_log and lk_send_pin.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: 10, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      sheetOpen = false;
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        toController.dispose();
        amountController.dispose();
      });
    });
  }

  Future<void> _walletSendReview(BuildContext sheetContext, WalletContact person, double amount) async {
    if (amount <= 0) {
      Get.snackbar('Enter an amount', 'Amount must be greater than zero.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (amount > _walletBalance) {
      Get.snackbar('Insufficient balance', 'Your wallet balance is ${_money(_walletBalance)}.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (amount > _remaining24h) {
      Get.snackbar('Over your 24h send limit', '${_money(_remaining24h)} left today. Limit ${_money(_dailyLimit)}.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (person.userId == null) {
      Get.snackbar('Choose a recipient', 'Pick someone from your wallet contacts to send money.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final received = person.currency == WalletDemoService.myCurrency ? amount : _fxQuote(amount, person.currency);
    final confirmed = await Get.dialog<bool>(
      Builder(
        builder: (dialogContext) {
          void popReview([bool result = false]) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(result);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff0f172a), Color(0xff1e3a8a)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Review transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                        IconButton(onPressed: popReview, icon: const Icon(Icons.close, color: Colors.white, size: 20)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 30, backgroundImage: _contactAvatar(person)),
                        const SizedBox(height: 12),
                        Text(_money(amount), style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 34)),
                        const SizedBox(height: 4),
                        Text('To ${person.name} · ${person.tag}', style: const TextStyle(color: Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Recipient receives ${WalletDemoService.formatCurrency(_currencies, received, person.currency)}', style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(height: 18),
                        _reviewLine('Source wallet', WalletDemoService.myCurrency),
                        _reviewLine('Destination', '${person.country} · ${person.currency}'),
                        _reviewLine('24h remaining after send', _money(_remaining24h - amount)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: popReview,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xffe2e8f0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xff334155), fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => popReview(true),
                                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 17),
                                label: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff2d98e5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    if (amount > _remaining24h) {
      Get.snackbar('Transfer blocked', 'Your 24h limit changed before confirmation.', snackPosition: SnackPosition.BOTTOM);
      await _reloadWalletBridge();
      return;
    }

    final recipientId = person.userId;
    if (recipientId == null) {
      Get.snackbar('Choose a recipient', 'Pick someone from your wallet contacts to send money.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final recipientName = person.name;
    FocusManager.instance.primaryFocus?.unfocus();
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    } else if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final pinOk = await verifyWalletPinForSend(context, amount);
    if (!pinOk || !mounted) return;

    try {
      await LinkupApiService.sendWalletMoney(amount: amount, recipientId: recipientId);
    } catch (err) {
      if (!mounted) return;
      _notifyWallet('Could not send money', err.toString().replaceFirst('Exception: ', ''));
      return;
    }

    try {
      await WalletDemoService.recordSend(amount);
    } catch (_) {}
    if (!mounted) return;
    await _loadWalletApi(reason: 'after-send-money');
    if (!mounted) return;
    _notifyWallet('Transfer sent', '${_money(amount)} sent to $recipientName.');
  }

  Widget _reviewLine(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w800, fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }


  Widget _modalSurface(BuildContext context, Widget child) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }



  Widget _webHeader({
    required String title,
    required String subtitle,
    IconData? icon,
    List<Color> colors = const [Color(0xff102a45), Color(0xff153f67)],
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          Builder(
            builder: (headerContext) {
              return IconButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (headerContext.mounted) {
                    final navigator = Navigator.of(headerContext);
                    if (navigator.canPop()) navigator.pop();
                  }
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _whiteDialogShell(BuildContext context, {required Widget child, double width = 390}) {
    return _modalSurface(
      context,
      Container(
        width: _ui(context, width),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 30, offset: const Offset(0, 18))],
        ),
        child: child,
      ),
    );
  }

  Widget _softInput(TextEditingController controller, String hint, {TextInputType? keyboardType, Widget? suffixIcon, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff9aa7b8), fontWeight: FontWeight.w800),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xfff8fafc),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xff2d98e5), width: 1.5)),
      ),
    );
  }

  Widget _gradientAction(String label, VoidCallback onTap, {IconData? icon, List<Color> colors = const [Color(0xff2d98e5), Color(0xff14b8a6)]}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 7),
              ],
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choicePill(String label, bool selected, VoidCallback onTap, {Color active = const Color(0xff2d98e5)}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 43,
          decoration: BoxDecoration(
            color: selected ? active : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? active : const Color(0xffdce6f2)),
          ),
          child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _largeCardPreview({List<Color>? colors}) {
    final cardColors = colors ?? _activeCardTheme;
    return Container(
      height: 170,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cardColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardColors.first.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LinkUp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23)),
              Icon(Icons.wifi, color: Colors.white.withOpacity(0.8), size: 26),
            ],
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xffffd700),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 14),
              const Text('••••  ••••  ••••  7560', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: 2.4)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CARD HOLDER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 9)),
                Text(_currentCardName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              ]),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('EXPIRES', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 9)),
                const Text('07/29', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              ]),
              const Text('Mastercard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }


  Future<void> _showAddContact(BuildContext context) async {
    _logAddContact('open dialog', 'walletApiLoaded=$_walletApiLoaded addable=${_addableUsers.length}');
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _logAddContact('FLUTTER ERROR', '${details.exceptionAsString()}\n${details.stack}');
      previousOnError?.call(details);
    };
    try {
    if (!_walletApiLoaded) await _loadWalletApi(reason: 'before-add-contact');
    if (!mounted) return;

    var saving = false;
    var dialogOpen = true;
    WalletContact? selected;

    final saved = await Get.dialog<WalletContact>(
      _whiteDialogShell(
        context,
        child: _OwnedTextControllers(
          builder: (dialogContext, nameController, tagController) {
            return StatefulBuilder(
              builder: (dialogContext, setDialogState) {
            void safeSet(VoidCallback fn) {
              _logAddContact('safeSet', 'dialogOpen=$dialogOpen dialogMounted=${dialogContext.mounted}');
              if (dialogOpen && dialogContext.mounted) setDialogState(fn);
            }

            final matches = _usersMatchingSearch(tagController.text);
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 10, 12),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Add Contact', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 24))),
                        IconButton(
                          onPressed: saving
                              ? null
                              : () {
                                  _logAddContact('close tapped');
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  dialogOpen = false;
                                  Navigator.of(dialogContext, rootNavigator: true).pop();
                                },
                          icon: const Icon(Icons.close, color: Colors.black, size: 22),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('NAME'),
                        _softInput(nameController, 'e.g. Dad'),
                        const SizedBox(height: 18),
                        _fieldLabel('LINKTAG SEARCH'),
                        _softInput(
                          tagController,
                          'e.g. ~Dad',
                          suffixIcon: const Icon(Icons.search, color: Color(0xff8aa0bc)),
                          onChanged: (_) => safeSet(() {}),
                        ),
                        if (tagController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          if (matches.isEmpty)
                            const Text(
                              'No matching people.',
                              style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: matches.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (_, index) {
                                  final user = matches[index];
                                  final isSelected = selected?.userId != null && selected?.userId == user.userId;
                                  return InkWell(
                                    onTap: saving
                                        ? null
                                        : () => safeSet(() {
                                              selected = user;
                                              _logAddContact('picked user', '${user.name} id=${user.userId} tag=${user.tag}');
                                              nameController.text = user.name;
                                              tagController.text = user.tag;
                                            }),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xffe8f4ff) : const Color(0xfff8fafc),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isSelected ? const Color(0xff2d98e5) : const Color(0xffe2e8f0)),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(radius: 16, backgroundImage: _contactAvatar(user)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(user.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w800, fontSize: 13)),
                                                Text(user.tag, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xff2d98e5), size: 18),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                        const SizedBox(height: 22),
                        _gradientAction('Save Contact', () async {
                          _logAddContact('save tapped', 'saving=$saving dialogOpen=$dialogOpen selected=${selected?.userId}');
                          if (saving || !dialogOpen) return;
                          safeSet(() => saving = true);
                          try {
                            final user = (selected?.userId != null ? selected : null) ??
                                _matchUserToAdd(name: nameController.text, tag: tagController.text);
                            final userId = user?.userId;
                            _logAddContact('matched user', '${user?.name} id=$userId tag=${user?.tag}');
                            if (user == null || userId == null) {
                              safeSet(() => saving = false);
                              _notifyWallet('Contact not found', 'Enter a name or @linktag that matches someone you can add.');
                              return;
                            }
                            _logAddContact('api addWalletContact start', userId);
                            await LinkupApiService.addWalletContact(contactUserId: userId);
                            _logAddContact('api addWalletContact done');
                            FocusManager.instance.primaryFocus?.unfocus();
                            dialogOpen = false;
                            _logAddContact('pop dialog', 'dialogMounted=${dialogContext.mounted}');
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext, rootNavigator: true).pop(user);
                              _logAddContact('Navigator.pop called');
                            } else {
                              _logAddContact('skip pop, dialog not mounted');
                            }
                          } catch (err, st) {
                            _logAddContact('save failed', '$err\n$st');
                            safeSet(() => saving = false);
                            _notifyWallet('Could not save contact', err.toString().replaceFirst('Exception: ', ''));
                          }
                        }, colors: const [Color(0xff7bb8ee), Color(0xff7bb8ee)]),
                      ],
                    ),
                  ),
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );

    _logAddContact('dialog closed', 'saved=${saved?.name} mounted=$mounted dialogOpen=${Get.isDialogOpen}');
    if (!mounted) return;
    if (saved != null) {
      _logAddContact('waiting before reload');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _logAddContact('reload after save', 'mounted=$mounted dialogOpen=${Get.isDialogOpen}');
      if (!mounted) return;
      await _loadWalletApi(reason: 'after-save-contact');
      if (!mounted) return;
      _notifyWallet('Contact saved', '${saved.name} was added.');
    }
    } finally {
      FlutterError.onError = previousOnError;
      _logAddContact('error hook restored');
    }
  }

  void _showPayBill(BuildContext context, String biller, String due, IconData icon) {
    final amountController = TextEditingController();
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _webHeader(title: 'Pay Bill', subtitle: '$biller · $due', icon: icon, colors: const [Color(0xff0f6cae), Color(0xff159eea)]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe2e8f0))),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xffe0f2fe), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xff0ea5e9))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(biller, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), Text(due, style: const TextStyle(color: Color(0xff8aa0bc), fontWeight: FontWeight.w700, fontSize: 11))])),
                        const Text('Ready', style: TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.w900, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('AMOUNT (USD)'),
                  _softInput(amountController, '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffbfdbfe))),
                    child: const Row(children: [Icon(Icons.info_outline, color: Color(0xff2563eb), size: 18), SizedBox(width: 9), Expanded(child: Text('Confirm the biller and amount before paying from your LinkUp Wallet.', style: TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.w700, fontSize: 11)))]),
                  ),
                  const SizedBox(height: 18),
                  _gradientAction('Pay Bill', () {
                    final amount = amountController.text.trim().isEmpty ? '0.00' : amountController.text.trim();
                    _closeWalletOverlay();
                    Get.snackbar('Bill payment sent', '$biller payment of \$$amount is processing.', snackPosition: SnackPosition.BOTTOM);
                  }, icon: Icons.receipt_long),
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(amountController.dispose);
  }

  void _showSavingsHistory(BuildContext context) {
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _webHeader(title: 'Savings History', subtitle: '', colors: const [Color(0xff06a77d), Color(0xff20c6a9)]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _savingHistoryRow('Interest posted', 'Apr 30', '+\$8.17', const Color(0xff059669)),
                  _savingHistoryRow('Auto-Save sweep (10%)', 'Apr 28', '+\$120.00', const Color(0xff059669)),
                  _savingHistoryRow('Deposit from Wallet', 'Apr 15', '+\$500.00', const Color(0xff059669)),
                  _savingHistoryRow('Interest posted', 'Mar 31', '+\$7.40', const Color(0xff059669)),
                  _savingHistoryRow('Withdrawal to Wallet', 'Mar 12', '-\$200.00', const Color(0xffe11d48)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savingHistoryRow(String title, String date, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 13)), const SizedBox(height: 2), Text(date, style: const TextStyle(color: Color(0xff8aa0bc), fontWeight: FontWeight.w700, fontSize: 11))])),
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  void _showSavingsDeposit(BuildContext context) {
    final amountController = TextEditingController();
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _webHeader(title: 'Deposit to Savings', subtitle: 'Wallet available: \$1,284.50 · Top-up min \$100.00', colors: const [Color(0xff06a77d), Color(0xff20c6a9)]),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _choicePill('\$100', amountController.text == '100', () { amountController.text = '100'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                        const SizedBox(width: 8),
                        _choicePill('\$500', amountController.text == '500', () { amountController.text = '500'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                        const SizedBox(width: 8),
                        _choicePill('\$1000', amountController.text == '1000', () { amountController.text = '1000'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _softInput(amountController, 'Amount (USD)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xffecfdf5), borderRadius: BorderRadius.circular(14)), child: const Text('Moves from Wallet › LinkUp Save. Interest accrues daily, posts monthly.', style: TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w800, fontSize: 12))),
                    const SizedBox(height: 16),
                    _gradientAction('Deposit', () { _closeWalletOverlay(); Get.snackbar('Deposit scheduled', 'Savings deposit submitted.', snackPosition: SnackPosition.BOTTOM); }, colors: const [Color(0xff06a77d), Color(0xff14b8a6)]),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ).whenComplete(amountController.dispose);
  }

  void _showSavingsWithdraw(BuildContext context) {
    final amountController = TextEditingController();
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _webHeader(title: 'Withdraw Savings', subtitle: 'Savings balance: \$2,450.00', colors: const [Color(0xff06a77d), Color(0xff20c6a9)]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _softInput(amountController, 'Amount (USD)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xfffffbeb), borderRadius: BorderRadius.circular(14)), child: const Text('⚠️ Funds are locked for 30 days. Early withdrawal incurs a 1.5% penalty.', style: TextStyle(color: Color(0xff92400e), fontWeight: FontWeight.w800, fontSize: 12))),
                  const SizedBox(height: 16),
                  _gradientAction('Withdraw to Wallet', () { _closeWalletOverlay(); Get.snackbar('Withdrawal requested', 'Savings withdrawal submitted.', snackPosition: SnackPosition.BOTTOM); }, colors: const [Color(0xff06a77d), Color(0xff14b8a6)]),
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(amountController.dispose);
  }

  void _showAutoSave(BuildContext context) {
    final percentController = TextEditingController(text: '10');
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _webHeader(title: 'Auto-Save', subtitle: 'Sweep a % of each payout into savings automatically.', colors: const [Color(0xff06a77d), Color(0xff20c6a9)]),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sweep percentage', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _choicePill('0%', percentController.text == '0', () { percentController.text = '0'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                      const SizedBox(width: 8),
                      _choicePill('5%', percentController.text == '5', () { percentController.text = '5'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                      const SizedBox(width: 8),
                      _choicePill('10%', percentController.text == '10', () { percentController.text = '10'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                      const SizedBox(width: 8),
                      _choicePill('25%', percentController.text == '25', () { percentController.text = '25'; setDialogState(() {}); }, active: const Color(0xff10b981)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _softInput(percentController, '10', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _gradientAction('Save Rule', () { _closeWalletOverlay(); Get.snackbar('Auto-Save updated', '${percentController.text}% sweep rule saved.', snackPosition: SnackPosition.BOTTOM); }, colors: const [Color(0xff06a77d), Color(0xff14b8a6)]),
                ]),
              ),
            ],
          ),
        );
      }),
    ).whenComplete(percentController.dispose);
  }

  void _showMyCard(BuildContext context) {
    int selectedTheme = _selectedCardTheme;
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Expanded(child: Text('My Card', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 22))), IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close, color: Colors.black))]),
                const SizedBox(height: 4),
                _largeCardPreview(colors: _cardThemePresets[selectedTheme]),
                const SizedBox(height: 18),
                Row(children: [
                  const Text('Theme', style: TextStyle(color: Color(0xff8aa0bc), fontWeight: FontWeight.w900, fontSize: 11)),
                  const SizedBox(width: 10),
                  for (int i = 0; i < _cardThemePresets.length; i++)
                    _themeDot(
                      _cardThemePresets[i],
                      selectedTheme == i,
                      onTap: () {
                        setDialogState(() => selectedTheme = i);
                        if (mounted) setState(() => _selectedCardTheme = i);
                      },
                    ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _outlineAction('Freeze', () => Get.snackbar('Card frozen', 'Demo card freeze toggle.', snackPosition: SnackPosition.BOTTOM))),
                  const SizedBox(width: 10),
                  Expanded(child: _outlineAction('View Details', () { _closeWalletOverlay(); Future.delayed(const Duration(milliseconds: 150), () => _showCardDetails(context)); })),
                ]),
                const SizedBox(height: 10),
                _gradientAction('Add to Mobile Wallet', () { _closeWalletOverlay(); Future.delayed(const Duration(milliseconds: 150), () => _showMobileWallet(context)); }, icon: Icons.account_balance_wallet_outlined),
              ],

            ),
          ),
        );
      }),
    );
  }

  Widget _themeDot(List<Color> colors, bool selected, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: EdgeInsets.all(selected ? 2 : 0),
        decoration: BoxDecoration(shape: BoxShape.circle, border: selected ? Border.all(color: const Color(0xff0f172a), width: 2) : null),
        child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors))),
      ),
    );
  }

  Widget _outlineAction(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffdce6f2))), child: Center(child: Text(label, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 13)))),
    );
  }

  void _showCardDetails(BuildContext context) {
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Card Details', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 24))),
                  IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close, color: Colors.black, size: 24)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xfffffbeb),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xfffef3c7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xff92400e), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'For your eyes only — never share your full card number or CVV with anyone, including LinkUp support.',
                        style: TextStyle(color: const Color(0xff92400e), fontWeight: FontWeight.w700, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _detailItem('CARD NUMBER', '5189  8348  8329  7560', isLarge: true),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _detailItem('EXPIRES', '07/29')),
                  Expanded(child: _detailItem('CVV', '442')),
                ],
              ),
              const SizedBox(height: 20),
              _detailItem('CARDHOLDER', 'CASSIUS STUART'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _detailItem('NETWORK', 'Mastercard')),
                  Expanded(child: _detailItem('ISSUING BANK', 'Scotiabank')),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: InkWell(
                  onTap: () => Get.snackbar('Copied', 'Card number copied to clipboard.', snackPosition: SnackPosition.BOTTOM),
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text('Copy Card Number', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xff0f172a),
            fontWeight: FontWeight.w900,
            fontSize: isLarge ? 20 : 16,
            letterSpacing: isLarge ? 1.2 : 0,
          ),
        ),
      ],
    );
  }


  void _showMobileWallet(BuildContext context) {
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('Add to Mobile Wallet', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 20))),
                    IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close, color: Colors.black, size: 24)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provision your LinkUp card •••• 7560 for Tap to Pay. LinkUp sends a tokenized device number (network token) to the mobile wallet — your real card number is never shared with merchants or stored on the device.',
                      style: TextStyle(color: const Color(0xff64748b), fontSize: 11, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (!_isCardAddedToWallet) ...[
                      _walletButton('Add to Apple Pay', Icons.apple, () {
                        setState(() => _isCardAddedToWallet = true);
                        setDialogState(() {});
                      }),
                      const SizedBox(height: 12),
                      _walletButton('Add to Google Pay', Icons.phone_android, () {
                        setState(() => _isCardAddedToWallet = true);
                        setDialogState(() {});
                      }),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xfff0fdf4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffdcfce7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xff16a34a), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ready to tap', style: TextStyle(color: Color(0xff16a34a), fontWeight: FontWeight.w900, fontSize: 14)),
                                  Text('Google Pay · token •••• 2340 · added Aug 4, 2026', style: TextStyle(color: const Color(0xff16a34a).withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xfffecdd3)),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() => _isCardAddedToWallet = false);
                            setDialogState(() {});
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text('Remove from Mobile Wallet', style: TextStyle(color: Color(0xffe11d48), fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _walletButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xff0f172a),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }


  Future<void> _showStartAsue(BuildContext context) async {
    _logAsue('open dialog', 'walletApiLoaded=$_walletApiLoaded contacts=${_walletContacts.length}');
    if (!_walletApiLoaded) await _loadWalletApi(reason: 'before-asue');
    if (!mounted) return;

    final nameController = TextEditingController();
    final amountController = TextEditingController(text: '100');
    final membersController = TextEditingController(text: '4');
    final dateController = TextEditingController();
    final tagController = TextEditingController();
    String frequency = 'Weekly';
    var accepted = false;
    var submitting = false;
    final invited = <int, WalletContact>{};
    final invitePool = <int, WalletContact>{};
    for (final contact in [..._walletContacts, ..._suggestedUsers, ..._activeContacts]) {
      final id = contact.userId;
      if (id != null) invitePool[id] = contact;
    }

    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        void safeSet(VoidCallback fn) {
          if (dialogContext.mounted) setDialogState(fn);
        }

        Future<void> pickStartDate() async {
          if (submitting) return;
          FocusManager.instance.primaryFocus?.unfocus();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final parsed = _parseAsueStartDate(dateController.text);
          final initial = (parsed != null && !parsed.isBefore(today)) ? parsed : today;
          _logAsue('open calendar', 'initial=$initial');
          final picked = await showDatePicker(
            context: dialogContext,
            initialDate: initial,
            firstDate: today,
            lastDate: today.add(const Duration(days: 365 * 3)),
          );
          if (picked == null) {
            _logAsue('calendar cancelled');
            return;
          }
          dateController.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          _logAsue('start date picked', dateController.text);
          safeSet(() {});
        }

        Future<void> pledgeAndContinue() async {
          if (submitting) return;
          FocusManager.instance.primaryFocus?.unfocus();

          final name = nameController.text.trim();
          final handAmount = _parseAmount(amountController.text);
          final maxMembers = int.tryParse(membersController.text.trim()) ?? 0;
          final startDate = _formatAsueStartDate(dateController.text);
          final userIds = invited.keys.toList();

          _logAsue('pledge tapped', 'name="$name" hand=$handAmount members=$maxMembers frequency=$frequency start=${dateController.text} iso=$startDate accepted=$accepted userIds=$userIds tags=${invited.values.map((c) => c.tag).toList()}');

          if (name.isEmpty) {
            _notifyWallet('Name required', 'Enter a circle name before pledging.');
            return;
          }
          if (handAmount <= 0) {
            _notifyWallet('Enter an amount', 'Hand amount must be greater than zero.');
            return;
          }
          if (maxMembers < 2) {
            _notifyWallet('Need more members', 'An Asue needs at least 2 members.');
            return;
          }
          if (startDate == null) {
            _notifyWallet('Pick a start date', 'Open the calendar and choose a start date.');
            return;
          }
          if (!accepted) {
            _notifyWallet('Agree to continue', 'Tick the disclosure before pledging.');
            return;
          }
          if (userIds.isEmpty) {
            _notifyWallet('Invite members', 'Select at least one person to invite into this Asue.');
            return;
          }
          if (userIds.length >= maxMembers) {
            _notifyWallet('Too many invites', 'Leave room for yourself. Invite at most ${maxMembers - 1} people.');
            return;
          }

          safeSet(() => submitting = true);
          try {
            _logAsue('api createWalletAsue start');
            await LinkupApiService.createWalletAsue(
              name: name,
              frequency: _asueFrequencyApiValue(frequency),
              handAmount: handAmount,
              maxMembers: maxMembers,
              startDate: startDate,
              disclaimerAgreed: accepted,
              userIds: userIds,
            );
            _logAsue('api createWalletAsue done');
          } catch (err, st) {
            _logAsue('api failed', '$err\n$st');
            if (dialogContext.mounted) safeSet(() => submitting = false);
            if (mounted) {
              _notifyWallet('Could not start Asue', err.toString().replaceFirst('Exception: ', ''));
            }
            return;
          }

          if (dialogContext.mounted) {
            final navigator = Navigator.of(dialogContext);
            if (navigator.canPop()) navigator.pop();
            _logAsue('dialog popped');
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
          await _loadWalletApi(reason: 'after-asue');
          if (!mounted) return;
          _notifyWallet('Asue started', '$name pledge created.');
        }

        return _whiteDialogShell(
          context,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _webHeader(title: 'Start an Asue', subtitle: 'You are the Coordinator — pledge the circle', colors: const [Color(0xff06a77d), Color(0xff20c6a9)]),
                const SizedBox(height: 18),
                _fieldLabel('CIRCLE / CLIENT NAME'),
                _softInput(nameController, 'e.g. Christmas Pot'),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('AMOUNT / HAND (\$)'),
                    _softInput(amountController, '100', keyboardType: TextInputType.number),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('# MEMBERS'),
                    _softInput(membersController, '4', keyboardType: TextInputType.number, onChanged: (_) => safeSet(() {})),
                  ])),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('FREQUENCY'),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      items: ['Weekly', 'Bi-weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: submitting ? null : (v) => safeSet(() => frequency = v ?? 'Weekly'),
                      decoration: InputDecoration(filled: true, fillColor: const Color(0xfff8fafc), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0)))),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('START DATE'),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      canRequestFocus: false,
                      enableInteractiveSelection: false,
                      onTap: submitting ? null : pickStartDate,
                      decoration: InputDecoration(
                        hintText: 'Tap to pick a date',
                        hintStyle: const TextStyle(color: Color(0xff9aa7b8), fontWeight: FontWeight.w800),
                        suffixIcon: IconButton(
                          onPressed: submitting ? null : pickStartDate,
                          icon: const Icon(Icons.calendar_month, size: 18),
                        ),
                        filled: true,
                        fillColor: const Color(0xfff8fafc),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xff2d98e5), width: 1.5)),
                      ),
                    ),
                  ])),
                ]),
                const SizedBox(height: 14),
                _fieldLabel('INVITE WITH @LINKTAG'),
                _softInput(
                  tagController,
                  'e.g. @cassius_stuart',
                  suffixIcon: const Icon(Icons.search, color: Color(0xff8aa0bc)),
                  onChanged: (_) => safeSet(() {}),
                ),
                if (tagController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    final matches = _peopleMatchingQuery(tagController.text, invitePool.values.toList())
                        .where((user) => user.userId != null && !invited.containsKey(user.userId))
                        .toList();
                    if (matches.isEmpty) {
                      return const Text(
                        'No matching people.',
                        style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12),
                      );
                    }
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, index) {
                          final user = matches[index];
                          return InkWell(
                            onTap: submitting
                                ? null
                                : () {
                                    final id = user.userId;
                                    if (id == null) return;
                                    safeSet(() {
                                      invited[id] = user;
                                      tagController.clear();
                                    });
                                    _logAsue('invite added', '${user.name} id=$id tag=${user.tag} invited=${invited.keys.toList()}');
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xfff8fafc),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xffe2e8f0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 16, backgroundImage: _contactAvatar(user)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w800, fontSize: 13)),
                                        Text(user.tag, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.add_circle_outline, color: Color(0xff0f766e), size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
                if (invited.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: invited.values.map((contact) {
                      return InputChip(
                        avatar: CircleAvatar(backgroundImage: _contactAvatar(contact)),
                        label: Text(contact.tag.isNotEmpty ? contact.tag : contact.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        onDeleted: submitting
                            ? null
                            : () {
                                final id = contact.userId;
                                if (id == null) return;
                                safeSet(() => invited.remove(id));
                                _logAsue('invite removed', '${contact.name} id=$id');
                              },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xffecfdf5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xff99f6e4))), child: const Text('Each round the pot is \$400.00 (\$100.00 × 4). LinkUp fee (3%): \$12.00 › recipient nets \$388.00. Runs 4 weekly rounds.', style: TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.w800, fontSize: 12, height: 1.35))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xffeef2ff), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: accepted,
                        onChanged: submitting ? null : (v) => safeSet(() => accepted = v ?? false),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Expanded(child: Text('Disclosure: LinkUp is a facilitator and is not responsible for the solvency of group members. Each cycle, every member is debited the hand amount; pooled funds are sent to that round’s recipient.', style: TextStyle(color: Color(0xff3730a3), fontWeight: FontWeight.w700, fontSize: 11, height: 1.35))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: submitting ? null : pledgeAndContinue,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xff0f766e), Color(0xff0f766e)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : const Text('Pledge & Continue ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
        amountController.dispose();
        membersController.dispose();
        dateController.dispose();
        tagController.dispose();
        _logAsue('controllers disposed');
      });
    });
  }

  DateTime? _parseAsueStartDate(String raw) {
    final iso = _formatAsueStartDate(raw);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  String? _formatAsueStartDate(String raw) {
    final value = raw.trim();
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (iso != null) return value;
    final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (dmy == null) return null;
    final day = int.parse(dmy.group(1)!);
    final month = int.parse(dmy.group(2)!);
    final year = int.parse(dmy.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String _asueFrequencyApiValue(String frequency) {
    switch (frequency) {
      case 'Bi-weekly':
        return 'bi-weekly';
      case 'Monthly':
        return 'monthly';
      default:
        return 'weekly';
    }
  }

  void _showCrypto(BuildContext context) {
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _webHeader(title: 'Crypto', subtitle: 'Buy, sell & hold — settled to your Wallet.', colors: const [Color(0xff312e81), Color(0xff4f46e5)]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _cryptoRow('BTC', 'Bitcoin', '+2.1%', '\$96,420', true),
                _cryptoRow('ETH', 'Ethereum', '+1.4%', '\$3,650', true),
                _cryptoRow('SOL', 'Solana', '-0.6%', '\$182', false),
                _cryptoRow('USDC', 'USDC', '+0.0%', '\$1.00', true),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cryptoRow(String code, String name, String change, String price, bool up) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffe8eef5))),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: const Color(0xfff1f5f9), child: Text(code, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 10))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), Text(change, style: TextStyle(color: up ? const Color(0xff059669) : const Color(0xffe11d48), fontWeight: FontWeight.w800, fontSize: 10))])),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(width: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: const Color(0xff4f46e5), borderRadius: BorderRadius.circular(999)), child: const Text('Trade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
      ]),
    );
  }

  void _showBankDetails(BuildContext context) {
    final paypalController = TextEditingController();
    final bankController = TextEditingController();
    final accountController = TextEditingController();
    final routingController = TextEditingController();
    String accountType = 'Checking';
    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 10), child: Row(children: [const Expanded(child: Text('Add Bank Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))), IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close))])),
                _fieldLabel('PayPal ID'),
                const Text('Email associated with your PayPal account for withdrawals.', style: TextStyle(color: Color(0xff8aa0bc), fontWeight: FontWeight.w700, fontSize: 10)),
                const SizedBox(height: 8),
                _softInput(paypalController, 'Enter your PayPal email address', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 18),
                Row(children: [const Expanded(child: Text('Bank Accounts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xff2d98e5), borderRadius: BorderRadius.circular(999)), child: const Text('+ Add Bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)))]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bank 1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    Row(children: [Radio<bool>(value: true, groupValue: true, onChanged: (_) {}), const Text('Set as default bank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))]),
                    const Padding(padding: EdgeInsets.only(left: 42, bottom: 10), child: Text('Used for all transactions by default.', style: TextStyle(color: Color(0xff8aa0bc), fontWeight: FontWeight.w700, fontSize: 10))),
                    _fieldLabel('Bank Name'),
                    _softInput(bankController, 'e.g., RBC Royal Bank'),
                    const SizedBox(height: 10),
                    _fieldLabel('Account Number'),
                    _softInput(accountController, 'Enter account number', keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _fieldLabel('Routing Number'),
                    _softInput(routingController, 'Enter routing number', keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _fieldLabel('Account Type'),
                    DropdownButtonFormField<String>(value: accountType, items: ['Checking', 'Savings', 'Business'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setDialogState(() => accountType = v ?? 'Checking'), decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))))),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: _outlineAction('Cancel', () => _closeWalletOverlay())), const SizedBox(width: 10), Expanded(child: _gradientAction('Save Bank Details', () { _closeWalletOverlay(); Get.snackbar('Bank details saved', 'Default bank account updated.', snackPosition: SnackPosition.BOTTOM); }, colors: const [Color(0xff102a45), Color(0xff102a45)]))]),
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() { paypalController.dispose(); bankController.dispose(); accountController.dispose(); routingController.dispose(); });
  }

  void _showWalletTopUps(BuildContext context, {int initialTab = 0}) {
    int selectedTab = initialTab; // 0: Top Up Cash, 1: Buy Coins
    final amountController = TextEditingController();

    final packs = <Map<String, dynamic>>[
      {'coins': 100, 'price': '\$1'},
      {'coins': 550, 'price': '\$5'},
      {'coins': 1200, 'price': '\$10'},
      {'coins': 3000, 'price': '\$25'},
    ];

    Get.dialog(
      StatefulBuilder(builder: (dialogContext, setDialogState) {
        return _whiteDialogShell(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Wallet Top Up', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 24)),
                    ),
                    IconButton(
                      onPressed: () => _closeWalletOverlay(),
                      icon: const Icon(Icons.close, color: Colors.black, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xffeef2f7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedTab = 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: selectedTab == 0
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Top Up Cash',
                                style: TextStyle(
                                  color: selectedTab == 0 ? const Color(0xff0f172a) : const Color(0xff94a3b8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedTab = 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: selectedTab == 1
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Buy Coins',
                                style: TextStyle(
                                  color: selectedTab == 1 ? const Color(0xff0f172a) : const Color(0xff94a3b8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  children: [
                    if (selectedTab == 0) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _fieldLabel('AMOUNT (USD)'),
                      ),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w800, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w800, fontSize: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff2d98e5), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _gradientAction('Add Funds', () {
                        final amount = amountController.text.trim().isEmpty ? '0.00' : amountController.text.trim();
                        _closeWalletOverlay();
                        _notifyWallet('Top-up started', 'Wallet top-up of \$$amount submitted.');
                      }, colors: const [Color(0xff2d98e5), Color(0xff2d98e5)]),
                    ] else ...[
                      // BUY COINS VIEW
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.45,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: packs.length,
                        itemBuilder: (_, index) {
                          final pack = packs[index];
                          final coins = pack['coins'] as int;
                          return InkWell(
                            onTap: () {
                              _closeWalletOverlay();
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (mounted) _showBuyCoinsDetail(context, pack);
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xffe2e8f0)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$coins LUC', style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(pack['price'] as String, style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), amountController.dispose);
    });
  }

  void _showBuyCoinsDetail(BuildContext context, Map<String, dynamic> pack) {
    final int coins = pack['coins'] as int;
    final String price = pack['price'] as String;

    Get.dialog(
      _whiteDialogShell(
        context,
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Buy $coins LUC', style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                  IconButton(
                    onPressed: () => _closeWalletOverlay(),
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xfff1f5f9), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(price, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 44)),
                        const SizedBox(height: 4),
                        Text('$coins LinkUp Coins', style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('PAY WITH', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                  _paymentMethodOption(
                    title: 'Card',
                    icon: Icons.credit_card,
                    onTap: () {
                      _closeWalletOverlay();
                      Get.snackbar('Purchase successful', 'Added $coins LUC to your wallet.', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                  const SizedBox(height: 12),
                  _paymentMethodOption(
                    title: 'Scotiabank Account',
                    icon: Icons.account_balance,
                    onTap: () {
                      _closeWalletOverlay();
                      Get.snackbar('Purchase successful', 'Added $coins LUC to your wallet.', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodOption({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff64748b), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }



  Widget _topUpOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffe2e8f0)),
          boxShadow: [BoxShadow(color: const Color(0xff0f172a).withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xff94a3b8), size: 26),
          ],
        ),
      ),
    );
  }



  void _showTransfer(BuildContext context) {
    Get.dialog(
      _whiteDialogShell(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Transfer', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 22)),
                  ),
                  IconButton(
                    onPressed: () => _closeWalletOverlay(),
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: _transferBox(
                      title: 'To Bank',
                      icon: Icons.account_balance_outlined,
                      onTap: () {
                        _closeWalletOverlay();
                        Future.delayed(const Duration(milliseconds: 150), () => _showBankTransferInput(context));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _transferBox(
                      title: 'To Save',
                      icon: Icons.savings_outlined,
                      onTap: () {
                        _closeWalletOverlay();
                        Future.delayed(const Duration(milliseconds: 150), () => _showSavingsDeposit(context));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _transferBox(
                      title: 'To Coins',
                      icon: Icons.diamond_outlined,
                      onTap: () {
                        _closeWalletOverlay();
                        Future.delayed(const Duration(milliseconds: 150), () => _showWalletTopUps(context, initialTab: 1));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankTransferInput(BuildContext context) {
    final amountController = TextEditingController();
    Get.dialog(_whiteDialogShell(context, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text('Transfer to Bank', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 20)),
            ),
            IconButton(
              onPressed: () => _closeWalletOverlay(),
              icon: const Icon(Icons.close, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
      Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffe2e8f0))),
          child: Row(
            children: [
              const Icon(Icons.account_balance, color: Color(0xff64748b), size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('From LinkUp Wallet › Bank 1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xff334155)))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _fieldLabel('AMOUNT (USD)'),
        _softInput(amountController, '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 20),
        _gradientAction('Transfer to Bank', () { _closeWalletOverlay(); Get.snackbar('Transfer started', 'Bank transfer submitted.', snackPosition: SnackPosition.BOTTOM); }, icon: null, colors: const [Color(0xff102a45), Color(0xff102a45)]),
      ])),
    ]))).whenComplete(amountController.dispose);
  }

  Widget _transferBox({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xff0f172a), size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ),
      ),
    );
  }


  void _showMyQr(BuildContext context) {
    Get.dialog(_whiteDialogShell(context, child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [const Expanded(child: Text('My QR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))), IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close))]),
      const SizedBox(height: 10),
      Container(width: 220, height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xffe2e8f0))), child: const Center(child: Icon(Icons.qr_code_2, size: 150, color: Color(0xff0f172a)))),
      const SizedBox(height: 12),
      const Text('@cassius · Scan to send me money', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      _gradientAction('Share QR', () => Get.snackbar('QR shared', 'Demo QR share action.', snackPosition: SnackPosition.BOTTOM), icon: Icons.share),
    ]))));
  }

  // POPUPS

  void _showVerificationRequired(BuildContext context) {
    Get.dialog(
      Center(
        child: Container(
          width: _ui(context, 340),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xff2d98e5), Color(0xff1e293b)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Verification Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.lock_open, color: Color(0xff2d98e5), size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('Verify your identity first', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xff1e293b))),
                    const SizedBox(height: 12),
                    const Text(
                      'As a licensed fintech, LinkUp requires identity verification (KYC) before you can send money. Browsing, chatting & Vibes stay free.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _closeWalletOverlay(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2d98e5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Verify Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _closeWalletOverlay(),
                      child: const Text('Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRequestedMoney(BuildContext context) async {
    if (!_walletApiLoaded) await _loadWalletApi(reason: 'before-requested-money');
    if (!mounted) return;
    final requests = _sentRequests;

    Get.dialog(
      Builder(
        builder: (dialogContext) {
          return _modalSurface(
            context,
            Container(
              width: _ui(context, 382),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 18))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff102a45), Color(0xff153f67)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requested Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                              SizedBox(height: 2),
                              Text('Requests you sent from your wallet.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: requests.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(16, 28, 16, 32),
                            child: Text(
                              'No money requests yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xff8aa0bc), fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: requests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final request = requests[index];
                              final name = request.recipientName.isNotEmpty ? request.recipientName : request.recipientTag;
                              return _requestedMoneyRow(
                                name: name.isEmpty ? 'Recipient' : name,
                                sub: request.subtitle,
                                amount: '\$${request.amount.toStringAsFixed(2)}',
                                action: request.actionLabel,
                                isPaid: request.isPaid,
                                imageUrl: request.recipientAvatar,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _requestedMoneyRow({
    required String name,
    required String sub,
    required String amount,
    required String action,
    required bool isPaid,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xffe8eef5))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (imageUrl != null && imageUrl.startsWith('http')
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/profile2.jpg')) as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xff0f172a))),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Color(0xff8aa0bc), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(color: isPaid ? const Color(0xffd8f8eb) : const Color(0xff2d98e5), borderRadius: BorderRadius.circular(999)),
            child: Text(action, style: TextStyle(color: isPaid ? const Color(0xff059669) : Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestMoney(BuildContext context) async {
    if (!_walletApiLoaded) await _loadWalletApi(reason: 'before-request-money');
    if (!mounted) return;
    final contacts = _activeContacts;
    final fromController = TextEditingController();
    final amountController = TextEditingController();
    WalletContact selected = contacts.isNotEmpty ? contacts.first : _fallbackContact;
    var dialogOpen = true;
    var sending = false;

    Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void safeSet(VoidCallback fn) {
            if (dialogOpen && dialogContext.mounted) setDialogState(fn);
          }

          void closeRequest() {
            FocusManager.instance.primaryFocus?.unfocus();
            dialogOpen = false;
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          }

          final searchPool = <WalletContact>[
            ...contacts,
            ..._suggestedUsers.where((user) {
              if (user.userId == null) return false;
              return !contacts.any((contact) => contact.userId == user.userId);
            }),
          ];
          final matches = _peopleMatchingQuery(fromController.text, searchPool);

          return _modalSurface(
            context,
            Container(
              width: _ui(context, 382),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 18))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff102a45), Color(0xff153f67)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Request Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                              SizedBox(height: 2),
                              Text('Confirm who you’re asking by their photo.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: closeRequest, icon: const Icon(Icons.close, color: Colors.white, size: 22)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QUICK CONTACTS', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.6)),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: contacts.map((contact) {
                                return _requestContactBubble(contact, selected.tag == contact.tag, () {
                                  selected = contact;
                                  fromController.text = contact.tag;
                                  safeSet(() {});
                                });
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('From (@tag or name)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xff0f172a))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: fromController,
                            decoration: InputDecoration(
                              hintText: '@username or name',
                              hintStyle: const TextStyle(color: Color(0xff9aa7b8), fontWeight: FontWeight.w800),
                              suffixIcon: const Icon(Icons.search, color: Color(0xff8aa0bc)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                            ),
                            onChanged: (value) {
                              final hits = _peopleMatchingQuery(value, searchPool);
                              if (hits.length == 1) {
                                selected = hits.first;
                              } else {
                                WalletContact? exact;
                                final needle = value.trim().toLowerCase().replaceFirst(RegExp(r'^[~@]'), '');
                                for (final user in hits) {
                                  final tag = user.tag.toLowerCase().replaceFirst(RegExp(r'^@'), '');
                                  if (tag == needle || user.name.toLowerCase() == value.trim().toLowerCase()) {
                                    exact = user;
                                    break;
                                  }
                                }
                                if (exact != null) selected = exact;
                              }
                              safeSet(() {});
                            },
                          ),
                          if (fromController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            if (matches.isEmpty)
                              const Text(
                                'No matching people.',
                                style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: 12),
                              )
                            else
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: matches.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                                  itemBuilder: (_, index) {
                                    final user = matches[index];
                                    final isSelected = selected.userId != null && selected.userId == user.userId;
                                    return InkWell(
                                      onTap: sending
                                          ? null
                                          : () => safeSet(() {
                                                selected = user;
                                                fromController.text = user.tag;
                                              }),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xffe8f4ff) : const Color(0xfff8fafc),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: isSelected ? const Color(0xff2d98e5) : const Color(0xffe2e8f0)),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(radius: 16, backgroundImage: _contactAvatar(user)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(user.name, style: const TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w800, fontSize: 13)),
                                                  Text(user.tag, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            if (isSelected) const Icon(Icons.check_circle, color: Color(0xff2d98e5), size: 18),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xfff5f8fc), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 18, backgroundImage: _contactAvatar(selected)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    fromController.text.trim().isEmpty
                                        ? 'Pick a contact or type a @tag — their photo appears here so you can confirm it’s the right person.'
                                        : '${selected.name} · ${selected.tag}',
                                    style: const TextStyle(color: Color(0xff8aa0bc), fontSize: 11, fontWeight: FontWeight.w700, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Amount (USD)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xff0f172a))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Color(0xff9aa7b8), fontWeight: FontWeight.w900, fontSize: 18),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xff2d98e5), Color(0xff14b8a6)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: sending
                                  ? null
                                  : () async {
                                      if (sending || !dialogOpen) return;
                                      final amount = _parseAmount(amountController.text);
                                      if (amount <= 0) {
                                        Get.snackbar('Enter an amount', 'Amount must be greater than zero.', snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      final recipientId = selected.userId;
                                      if (recipientId == null) {
                                        Get.snackbar('Choose a recipient', 'Pick someone from your wallet contacts to request money.', snackPosition: SnackPosition.BOTTOM);
                                        return;
                                      }
                                      safeSet(() => sending = true);
                                      try {
                                        await LinkupApiService.requestWalletMoney(amount: amount, recipientId: recipientId);
                                      } catch (err) {
                                        safeSet(() => sending = false);
                                        Get.snackbar(
                                          'Could not send request',
                                          err.toString().replaceFirst('Exception: ', ''),
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        return;
                                      }
                                      final recipientName = selected.name;
                                      closeRequest();
                                      await Future<void>.delayed(const Duration(milliseconds: 400));
                                      if (!mounted) return;
                                      await _loadWalletApi(reason: 'after-request-money');
                                      if (!mounted) return;
                                      _notifyWallet('Request sent', 'Money request sent to $recipientName.');
                                    },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      dialogOpen = false;
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        fromController.dispose();
        amountController.dispose();
      });
    });
  }

  Widget _requestContactBubble(WalletContact contact, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(selected ? 2 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected ? Border.all(color: const Color(0xff2d98e5), width: 2) : null,
              ),
              child: CircleAvatar(radius: 21, backgroundImage: _contactAvatar(contact)),
            ),
            const SizedBox(height: 6),
            Text(contact.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
          ],
        ),
      ),
    );
  }

  Widget _smallContact(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/profile2.jpg')),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xff334155))),
        ],
      ),
    );
  }

  void _showAddBiller(BuildContext context) {
    final companyController = TextEditingController();
    final accountController = TextEditingController();
    final holderController = TextEditingController();
    String selectedCategory = 'Electricity';
    final categories = <Map<String, dynamic>>[
      {'label': 'Electricity', 'icon': Icons.bolt},
      {'label': 'Water', 'icon': Icons.water_drop_outlined},
      {'label': 'Internet / Cable', 'icon': Icons.wifi},
      {'label': 'Mobile / Phone', 'icon': Icons.phone_android},
      {'label': 'Insurance', 'icon': Icons.shield_outlined},
      {'label': 'Other', 'icon': Icons.receipt_long},
    ];

    Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return _modalSurface(
            context,
            Container(
              width: _ui(context, 390),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 30, offset: const Offset(0, 18))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff102a45), Color(0xff153f67)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add a Biller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                              SizedBox(height: 2),
                              Text('Add any company you pay bills to', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close, color: Colors.white, size: 22)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Company / Biller Name'),
                          _plainTextField(companyController, 'e.g. ALIV Mobile'),
                          const SizedBox(height: 14),
                          _fieldLabel('Category'),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categories.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.5),
                            itemBuilder: (context, index) {
                              final item = categories[index];
                              final active = selectedCategory == item['label'];
                              return InkWell(
                                onTap: () => setDialogState(() => selectedCategory = item['label'] as String),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xffeff6ff) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: active ? const Color(0xff2d98e5) : const Color(0xffe2e8f0), width: active ? 2 : 1),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(item['icon'] as IconData, color: active ? const Color(0xff2563eb) : const Color(0xff475569), size: 19),
                                      const SizedBox(height: 6),
                                      Text(item['label'] as String, textAlign: TextAlign.center, style: TextStyle(color: active ? const Color(0xff2563eb) : const Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Your Account Number with this Biller'),
                          _plainTextField(accountController, 'e.g. 100234567'),
                          const SizedBox(height: 14),
                          _fieldLabel('Account Holder Name (optional)'),
                          _plainTextField(holderController, 'Name on the account'),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffbfdbfe))),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xff2563eb), size: 18),
                                SizedBox(width: 10),
                                Expanded(child: Text('Your account is linked now — you’ll just enter an amount each time you pay, since bills change every cycle.', style: TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.w700, fontSize: 11, height: 1.3))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                _closeWalletOverlay();
                                Get.snackbar('Biller added', '${companyController.text.trim().isEmpty ? selectedCategory : companyController.text.trim()} is ready for bill pay.', snackPosition: SnackPosition.BOTTOM);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2d98e5), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: const Text('Add Biller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      companyController.dispose();
      accountController.dispose();
      holderController.dispose();
    });
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }

  Widget _plainTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff9aa7b8), fontWeight: FontWeight.w800),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
      ),
    );
  }

  void _showPayMerchant(BuildContext context) {
    Get.dialog(
      _modalSurface(
        context,
        Container(
          width: _ui(context, 340),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: Color(0xff8b5cf6), size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pay a Merchant', style: TextStyle(color: Color(0xff1e293b), fontWeight: FontWeight.w900, fontSize: 18)),
                          Text('Scan the merchant\'s checkout QR to pay from your Wallet.', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _closeWalletOverlay(), icon: const Icon(Icons.close, color: Colors.grey, size: 20)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xff0f172a), borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 100,
                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Camera blocked - paste a QR or use the demo below.', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Or paste a merchant QR',
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(color: const Color(0xff8b5cf6), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('Demo: scan a sample merchant checkout QR', style: TextStyle(color: Color(0xff334155), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWalletActivity(BuildContext context) async {
    await _loadWalletActivity();
    if (!mounted) return;

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    var sent30 = 0.0;
    var received30 = 0.0;
    for (final item in _activityItems) {
      if (item.date != null && item.date!.isBefore(cutoff)) continue;
      if (item.isPositive) {
        received30 += item.amount;
      } else {
        sent30 += item.amount;
      }
    }

    var tab = 'All';
    var query = '';
    const tabs = <String>[
      'Deposits',
      'Sent',
      'Received',
      'Requested',
      'Withdrawals',
      'Wallet & Coins',
      'All',
    ];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          bool matchesTab(WalletActivityItem item) {
            switch (tab) {
              case 'Deposits':
                return item.isDeposit;
              case 'Sent':
                return item.isSent;
              case 'Received':
                return item.isReceived;
              case 'Requested':
                return item.isRequested;
              case 'Withdrawals':
                return item.isWithdrawal;
              case 'Wallet & Coins':
                return item.isWalletOrCoin;
              default:
                return true;
            }
          }

          final needle = query.trim().toLowerCase();
          final items = _activityItems.where((item) {
            if (!matchesTab(item)) return false;
            if (needle.isEmpty) return true;
            final haystack = '${item.title} ${item.counterparty} ${item.note} ${item.type}'.toLowerCase();
            return haystack.contains(needle);
          }).toList();
          final grouped = <String, List<WalletActivityItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.monthLabel, () => []).add(item);
          }

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Icon(Icons.description_outlined, color: Color(0xff2d98e5), size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wallet Activity', style: TextStyle(color: Color(0xff1e293b), fontWeight: FontWeight.w900, fontSize: 18)),
                            Text('Live ledger from your LinkUp wallet', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _summaryItem('SENT (30D)', WalletDemoService.money(sent30)),
                          const SizedBox(width: 20),
                          _summaryItem('RECEIVED (30D)', WalletDemoService.money(received30)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _summaryItem('BALANCE', '\$$_displayBalance'),
                          const SizedBox(width: 20),
                          _summaryItem('TOTAL SHOWN', '${items.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final label in tabs)
                        GestureDetector(
                          onTap: () => setSheetState(() => tab = label),
                          child: _activityTab(label, tab == label),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xffe8eef5)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (value) => setSheetState(() => query = value),
                    decoration: InputDecoration(
                      hintText: 'Search e.g. lunch, @user..',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.05),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _activityLoading && items.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Color(0xff2d98e5)))
                      : items.isEmpty
                          ? Center(
                              child: Text(
                                tab == 'Requested' ? 'No money requests yet.' : 'No transactions',
                                style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                for (final entry in grouped.entries) ...[
                                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xff1e293b))),
                                  for (final item in entry.value)
                                    _activityRow(
                                      item.title,
                                      item.subtitle,
                                      item.signedAmount,
                                      item.counterparty,
                                      item.status.isEmpty ? 'Success' : item.status,
                                      item.isPositive ? const Color(0xff10b981) : Colors.redAccent,
                                    ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xff1e293b), fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _activityTab(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xffdbeafe) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xff1e3a8a) : const Color(0xff64748b),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _activityRow(String name, String sub, String amount, String id, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xff1e293b))),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                Text(id, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', true],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', false],
      [Icons.favorite_border, 'LinkUp', false],
    ];

    return Container(
      height: _ui(context, 64) + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: _ui(context, 12),
        right: _ui(context, 12),
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item[2] as bool;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 18)),
              onTap: () {
                if (item[1] == 'Vibes') Get.to(() => const VibesPage());
                if (item[1] == 'Eats') Get.to(() => const EatsPage());
                if (item[1] == 'Live') Get.to(() => const LivePage());
                if (item[1] == 'LinkUp') Get.to(ChatHomePage());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: selected ? _ui(context, 30) : _ui(context, 26),
                    height: selected ? _ui(context, 30) : _ui(context, 26),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xff2d98e5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(_ui(context, 11)),
                    ),
                    child: Icon(item[0] as IconData, color: selected ? Colors.white : const Color(0xff69768a), size: 24),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item[1] as String,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected ? const Color(0xff2589df) : const Color(0xff627085),
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OwnedTextControllers extends StatefulWidget {
  const _OwnedTextControllers({required this.builder});

  final Widget Function(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController tagController,
  ) builder;

  @override
  State<_OwnedTextControllers> createState() => _OwnedTextControllersState();
}

class _OwnedTextControllersState extends State<_OwnedTextControllers> {
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logAddContact('controllers created', 'name=${nameController.hashCode} tag=${tagController.hashCode}');
  }

  @override
  void dispose() {
    _logAddContact('controllers disposing', 'mounted=$mounted name=${nameController.hashCode} tag=${tagController.hashCode}');
    nameController.dispose();
    tagController.dispose();
    _logAddContact('controllers disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logAddContact('controllers build', 'mounted=$mounted');
    return widget.builder(context, nameController, tagController);
  }
}
