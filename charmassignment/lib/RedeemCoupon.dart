/*

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class RedeemCoupon extends StatefulWidget {
  final String uid;

  const RedeemCoupon({Key? key, required this.uid}) : super(key: key);

  @override
  _RedeemCouponState createState() => _RedeemCouponState();
}

class _RedeemCouponState extends State<RedeemCoupon> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _couponCodeController = TextEditingController();
  List<Map<String, dynamic>> _coupons = [];
  String? _selectedCouponId;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Coupons')
          .where('uid', isEqualTo: widget.uid)
          .get();

      setState(() {
        _coupons = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'data': doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching coupons: $e');
    }
  }

  Future<void> redeemCoupon(String couponCode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Coupons')
          .where('Coupon Code', isEqualTo: couponCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot couponDoc = snapshot.docs.first;

        await couponDoc.reference.update({'Status': 'redeemed'});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon redeemed successfully!')),
        );

        _couponCodeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coupon code.')),
        );
      }
    } catch (e) {
      print('Error redeeming coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to redeem coupon: $e')),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _couponCodeController.text = result!.code!;
        redeemCoupon(result!.code!);
        controller.pauseCamera();
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Redeem Coupon', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_coupons.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Select a Coupon'),
                value: _selectedCouponId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCouponId = newValue;
                    _couponCodeController.text =
                        _coupons.firstWhere((coupon) => coupon['id'] == newValue)['data']['Coupon Code'];
                  });
                },
                items: _coupons.map<DropdownMenuItem<String>>((Map<String, dynamic> coupon) {
                  return DropdownMenuItem<String>(
                    value: coupon['id'],
                    child: Text(coupon['data']['Coupon Code']),
                  );
                }).toList(),
              ),
            TextField(
              controller: _couponCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Coupon Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Redeem Coupon'),
              onPressed: () {
                redeemCoupon(_couponCodeController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Scan QR Code'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Scan QR Code'),
                            backgroundColor: Colors.red,
                          ),
                          body: QRView(
                            key: qrKey,
                            onQRViewCreated: _onQRViewCreated,
                            overlay: QrScannerOverlayShape(
                              borderColor: Colors.red,
                              borderRadius: 10,
                              borderLength: 30,
                              borderWidth: 10,
                              cutOutSize: 300,
                            ),
                          ),
                        )));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}


*/