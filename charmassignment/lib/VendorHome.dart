import 'package:charmassignment/Reviews.dart';
import 'package:charmassignment/VendorAccount.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CreateDeal.dart';
import 'EditDeals.dart';
import 'Login.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({Key? key}) : super(key: key);

  @override
  _VendorHomeState createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? currentUser;
  String _username = "Loading...";
  String _profilePhotoUrl = "";

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = userData['fullName'] as String? ?? 'No Name';
          _profilePhotoUrl = userData['profilePhoto'] as String? ?? '';
        });
      } else {
        print("something went wrong");
      }
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
  }

  void _navigateToEditDeal() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditDeals(uid: currentUser!.uid)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _username,
              style: const TextStyle(color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VendorAccount()));
              },
              child: CircleAvatar(
                backgroundImage: _profilePhotoUrl.isEmpty
                    ? const AssetImage('assets/Profilephoto.png')
                    : NetworkImage(_profilePhotoUrl) as ImageProvider,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              icon: Icons.add_circle,
              label: 'Create Deal',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateDeal()));
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              icon: Icons.edit,
              label: 'Edit Deals',
              onPressed: _navigateToEditDeal,
            ),
            const SizedBox(height: 20),
            _buildButton(
              icon: Icons.qr_code_scanner,
              label: 'Redeem Coupon',
              onPressed: () {
                //Navigator.of(context).push(MaterialPageRoute(builder: (_) => RedeemCoupon(uid: currentUser!.uid)));
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              icon: Icons.reviews,
              label: 'Reviews',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => Reviews(uid: currentUser!.uid)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
