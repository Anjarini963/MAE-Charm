import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateDeal extends StatefulWidget {
  const CreateDeal({Key? key}) : super(key: key);

  @override
  _CreateDealState createState() => _CreateDealState();
}

class _CreateDealState extends State<CreateDeal> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _couponNameController = TextEditingController(); // New controller for coupon name
  final TextEditingController _couponCountController = TextEditingController();
  File? _logoImage;
  File? _restaurantImage;
  final picker = ImagePicker();

  Future<void> getImage(bool isLogo) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
        } else {
          _restaurantImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String> uploadImage(File? imageFile, String path) async {
    if (imageFile != null) {
      var snapshot = await FirebaseStorage.instance.ref(path).putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    }
    return '';
  }

  Future<void> createDeal() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String dealId = FirebaseFirestore.instance.collection('Deals').doc().id;
    String vendorName = 'Unknown Vendor';
    int couponNumber = int.tryParse(_couponCountController.text) ?? 0;

    if (_logoImage != null && _restaurantImage != null) {
      try {
        String logoUrl = await uploadImage(_logoImage, 'logos/$dealId');
        String restaurantImageUrl = await uploadImage(_restaurantImage, 'restaurants/$dealId');

        DocumentSnapshot vendorDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
        if (vendorDoc.exists) {
          Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;
          vendorName = vendorData['fullName'] ?? 'Unknown Vendor';
        }

        await FirebaseFirestore.instance.collection('Deals').doc(dealId).set({
          'uid': uid,
          'DealID': dealId,
          'Vendor Name': vendorName,
          'Merchant photo': logoUrl,
          'Deal Image': restaurantImageUrl,
          'Description': _detailsController.text,
          'Rating': 0,
          'Category': _categoryController.text,
          'Coupon Name': _couponNameController.text,  // New field for coupon name
        });

        for (int i = 0; i < couponNumber; i++) {
          String couponCode = generateCouponCode();
          String couponId = FirebaseFirestore.instance.collection('Coupons').doc().id;

          await FirebaseFirestore.instance.collection('Coupons').doc(couponId).set({
            'CollectionID': couponId,
            'uid': uid,
            'DealID': dealId,
            'Coupon Code': couponCode,
            'Status': 'unused',
          });
        }

        _detailsController.clear();
        _categoryController.clear();
        _couponNameController.clear(); // Clear the new coupon name controller
        _couponCountController.clear();
        setState(() {
          _logoImage = null;
          _restaurantImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal created successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create deal: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both images before creating a deal.')));
    }
  }

  String generateCouponCode() {
    var rng = Random();
    return List.generate(9, (index) => rng.nextInt(10).toString()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Deal'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponNameController,  // New text field for coupon name
              decoration: const InputDecoration(
                labelText: 'Coupon Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponCountController,
              decoration: const InputDecoration(
                labelText: 'How many coupons?',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _logoImage == null
                ? const Text('No logo image selected.')
                : Image.file(_logoImage!),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Upload Logo Image'),
              onPressed: () => getImage(true),
            ),
            const SizedBox(height: 20),
            _restaurantImage == null
                ? const Text('No Merchant image selected.')
                : Image.file(_restaurantImage!),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Upload Merchant Image'),
              onPressed: () => getImage(false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createDeal,
              child: const Text('Create Deal'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
