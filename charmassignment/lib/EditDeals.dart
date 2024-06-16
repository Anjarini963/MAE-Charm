import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditDeals extends StatefulWidget {
  final String uid;
  const EditDeals({Key? key, required this.uid}) : super(key: key);

  @override
  _EditDealsState createState() => _EditDealsState();
}

class _EditDealsState extends State<EditDeals> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _couponNameController = TextEditingController();
  final TextEditingController _googleMapsLinkController = TextEditingController();
  File? _logoImage;
  File? _restaurantImage;
  String? _logoImageUrl;
  String? _restaurantImageUrl;
  final picker = ImagePicker();
  String? _selectedDealId;
  List<Map<String, String>> _deals = [];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    QuerySnapshot dealSnapshot = await FirebaseFirestore.instance.collection('Deals').where('uid', isEqualTo: widget.uid).get();
    List<Map<String, String>> loadedDeals = [];
    for (var doc in dealSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      loadedDeals.add({
        'dealId': doc.id,
        'couponName': data['Coupon Name'] ?? 'Unknown Coupon',
      });
    }
    setState(() {
      _deals = loadedDeals;
    });
  }

  Future<void> _loadDealData(String dealId) async {
    DocumentSnapshot dealDoc = await FirebaseFirestore.instance.collection('Deals').doc(dealId).get();

    if (dealDoc.exists) {
      var dealData = dealDoc.data() as Map<String, dynamic>;
      _detailsController.text = dealData['Description'] ?? '';
      _categoryController.text = dealData['Category'] ?? '';
      _couponNameController.text = dealData['Coupon Name'] ?? '';
      _googleMapsLinkController.text = dealData['Google Maps Link'] ?? '';
      _logoImageUrl = dealData['Merchant photo'];
      _restaurantImageUrl = dealData['Deal Image'];
      setState(() {});
    }
  }

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

  Future<void> updateDeal() async {
    if (_selectedDealId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a deal to update.')));
      return;
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      String logoUrl = _logoImage != null
          ? await uploadImage(_logoImage, 'logos/$_selectedDealId')
          : _logoImageUrl ?? '';

      String restaurantImageUrl = _restaurantImage != null
          ? await uploadImage(_restaurantImage, 'restaurants/$_selectedDealId')
          : _restaurantImageUrl ?? '';

      await FirebaseFirestore.instance.collection('Deals').doc(_selectedDealId!).update({
        'uid': uid,
        'Coupon Name': _couponNameController.text,
        'Description': _detailsController.text,
        'Category': _categoryController.text,
        'Google Maps Link': _googleMapsLinkController.text,
        'Merchant photo': logoUrl,
        'Deal Image': restaurantImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal updated successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update deal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit a Deal', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedDealId,
              items: _deals.map((deal) {
                return DropdownMenuItem<String>(
                  value: deal['dealId'],
                  child: Text(deal['couponName']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDealId = value;
                  if (value != null) {
                    _loadDealData(value);
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Deal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponNameController,
              decoration: const InputDecoration(
                labelText: 'Coupon Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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
              controller: _googleMapsLinkController,
              decoration: const InputDecoration(
                labelText: 'Google Maps Link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _logoImage != null
                ? Image.file(_logoImage!)
                : _logoImageUrl != null
                    ? Image.network(_logoImageUrl!)
                    : const Text('No logo image selected.'),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Upload Logo Image'),
              onPressed: () => getImage(true),
            ),
            const SizedBox(height: 20),
            _restaurantImage != null
                ? Image.file(_restaurantImage!)
                : _restaurantImageUrl != null
                    ? Image.network(_restaurantImageUrl!)
                    : const Text('No Merchant image selected.'),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Upload Merchant Image'),
              onPressed: () => getImage(false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateDeal,
              child: const Text('Update Deal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
