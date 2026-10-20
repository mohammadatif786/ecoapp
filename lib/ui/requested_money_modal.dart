import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:link_up/model/wallet_result.dart';
import 'package:link_up/services/linkup_api_service.dart';

class RequestedMoneyModal extends StatefulWidget {
  final String? userToken;
  final String baseUrl;

  const RequestedMoneyModal({
    Key? key,
    this.userToken,
    this.baseUrl = 'https://linkupvibes.com/api/regular-user/wallet',
  }) : super(key: key);

  @override
  State<RequestedMoneyModal> createState() => _RequestedMoneyModalState();
}

class _RequestedMoneyModalState extends State<RequestedMoneyModal> {
  List<MoneyRequest> _requests = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Map<String, String> get _headers => {
        if (widget.userToken != null && widget.userToken!.isNotEmpty)
          'Authorization': 'Bearer ${widget.userToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.userToken != null && widget.userToken!.isNotEmpty) {
        final res = await http.get(
          Uri.parse('${widget.baseUrl}/requested-money'),
          headers: _headers,
        );
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['moneyRequests'] != null) {
          if (mounted) {
            setState(() {
              _requests = (data['moneyRequests'] as List)
                  .map((e) => MoneyRequest.fromJson(e))
                  .toList();
            });
          }
        }
      } else {
        final requests = await LinkupApiService.fetchMoneyRequests();
        if (mounted) {
          setState(() {
            _requests = requests;
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load requests: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performAction(String action, int requestId) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (widget.userToken != null && widget.userToken!.isNotEmpty) {
        final res = await http.post(
          Uri.parse('${widget.baseUrl}/requested-money/$requestId/$action'),
          headers: _headers,
        );
        final data = jsonDecode(res.body);

        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Action completed.')),
            );
          }
          await _fetchRequests(); // Refresh list after action
        } else {
          if (mounted) {
            setState(() => _errorMessage = data['message'] ?? 'Action failed');
          }
        }
      } else {
        if (action == 'pay') {
          await LinkupApiService.payMoneyRequest(requestId);
        } else if (action == 'reject') {
          await LinkupApiService.rejectMoneyRequest(requestId);
        } else if (action == 'cancel') {
          await LinkupApiService.cancelMoneyRequest(requestId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request ${action}ed successfully.')),
          );
        }
        await _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade700;
      case 'accepted':
      case 'paid':
      case 'success':
        return const Color(0xff059669);
      case 'rejected':
        return Colors.red.shade700;
      case 'cancelled':
      default:
        return Colors.blueGrey.shade600;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade50;
      case 'accepted':
      case 'paid':
      case 'success':
        return const Color(0xffd8f8eb);
      case 'rejected':
        return Colors.red.shade50;
      case 'cancelled':
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Requested Money',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'See who is asking before you pay.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 15),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: CircularProgressIndicator(),
            )
          else if (_requests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: Text('No money requests.'),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: req.person.img.isNotEmpty && req.person.img.startsWith('http')
                                  ? NetworkImage(req.person.img)
                                  : const AssetImage('assets/profile2.jpg') as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        req.person.name.isNotEmpty
                                            ? req.person.name
                                            : (req.person.tag.isNotEmpty ? req.person.tag : 'LinkUp User'),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusBg(req.status),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          req.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(req.status),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                    req.isIncoming
                                        ? 'Requested from you'
                                        : 'You requested',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  if (req.note != null && req.note!.isNotEmpty)
                                    Text(
                                      req.note!,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black54),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${req.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        // Actions for Pending Items
                        if (req.isPending) ...[
                          const SizedBox(height: 10),
                          if (req.isIncoming)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff2d98e5),
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _performAction('pay', req.id),
                                    child: const Text('Pay',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () =>
                                            _performAction('reject', req.id),
                                    child: Text(
                                      'Reject',
                                      style: TextStyle(
                                          color: Colors.red.shade700),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                ),
                                onPressed: _isProcessing
                                    ? null
                                    : () => _performAction('cancel', req.id),
                                child: const Text(
                                  'Cancel Request',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            )
                        ]
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
