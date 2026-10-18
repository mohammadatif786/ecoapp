import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as IO;

import 'package:path_provider/path_provider.dart';

class PDFScreen extends StatefulWidget {
  final Map<String, dynamic> arg;
  PDFScreen({Key? key, required this.arg}) : super(key: key);

  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool isLoading = false;
  Uint8List? pdfByte;

  void getPolicy() async {
    setState(() {
      isLoading = true;
    });
    
    String? url;
    if (widget.arg.containsKey('url')) {
      url = widget.arg['url'];
    } else {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('hHVpFZPwUyaVATLmcvPE')
          .get();
      url = doc.data()?[widget.arg['key']];
    }

    if (url == null || url.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'PDF URL not found';
      });
      return;
    }

    try {
      var pdfUrl = Uri.parse(url);
      final response = await http.get(pdfUrl);
      Uint8List byte = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file =
          IO.File("${dir.path}/${DateTime.now().microsecondsSinceEpoch}.pdf");

      await file.writeAsBytes(byte, flush: true);
      setState(() {
        pdfByte = byte;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getPolicy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 56, 171, 216),
        title: Text(widget.arg['title'] ??
            (widget.arg['key'] == 'privacy_policy'
                ? "privacy_policy".tr
                : 'term_condition'.tr)),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Stack(
        children: <Widget>[
          if (isLoading)
            Container(
                child: Center(
              child: CircularProgressIndicator.adaptive(),
            )),
          if (!isLoading)
            PDFView(
              pdfData: pdfByte,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: currentPage!,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation:
                  false, // if set to true the link is handled in flutter
              onRender: (_pages) {
                setState(() {
                  pages = _pages;
                  isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  errorMessage = '$page: ${error.toString()}';
                });
              },
              onViewCreated: (PDFViewController pdfViewController) {
                _controller.complete(pdfViewController);
              },
              onLinkHandler: (String? uri) {},
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page;
                });
              },
            ),
        ],
      ),
    );
  }
}
