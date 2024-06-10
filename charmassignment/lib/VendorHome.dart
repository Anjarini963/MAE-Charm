import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CreateDeal.dart';  // This is hypothetical, ensure you have this screen created for creating deals
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
      } else{
        print("something went wrong");
      }
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Home', style: Theme.of(context).textTheme.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _profilePhotoUrl.isEmpty
                  ? const AssetImage('assets/Profilephoto.png')
                  : NetworkImage(_profilePhotoUrl) as ImageProvider,
            ),
            title: Text(_username),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to a profile editing screen if needed
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // NAVIGATES TO CREATE DEAL PAGE (CreateDeal.dart)
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateDeal()));
            },
            child: const Text('Create a Deal'),
          ),
        ],
      ),
    );
  }
}


