import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MerchantDetails.dart';
import 'account.dart';
import 'package:intl/intl.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  _CustomerHomeState createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = "Loading...";
  String _profilePhotoUrl = "";
  List<Map<String, dynamic>> _deals = [];
  List<Map<String, dynamic>> _filteredDeals = [];
  final List<String> categories = [
    'All',
    'Restaurant',
    'Cafe',
    'Entertainment'
  ];
  String selectedCategory = 'All';
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadDeals();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = userData['fullName'] ?? 'No Name';
          _profilePhotoUrl = userData['profilePhoto'] ?? '';
        });
      }
    }
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _loadDeals() async {
    QuerySnapshot dealSnapshot = await _firestore.collection('Deals').get();
    List<Map<String, dynamic>> loadedDeals = [];
    for (var doc in dealSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data != null) {
        loadedDeals.add({
          'uid': data['uid'],
          'merchantName': data['Vendor Name'] ?? 'Unknown Merchant',
          'couponName': data['Coupon Name'] ?? 'Unknown Coupon', // Added coupon name
          'category': data['Category'] ?? 'No Category',
          'profilePhoto': data['Merchant photo'] ?? '',
          'docId': doc.id,
        });
      }
    }
    setState(() {
      _deals = loadedDeals;
      _filterDeals();
    });
  }

  void _filterDeals() {
    List<Map<String, dynamic>> tempDeals = _deals.where((deal) {
      final matchCategory =
          selectedCategory == 'All' || deal['category'] == selectedCategory;
      final matchSearch = deal['merchantName']
          .toLowerCase()
          .contains(_searchTerm.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
    setState(() {
      _filteredDeals = tempDeals;
    });
  }

  String getCurrentLabel() {
    if (_searchTerm.isNotEmpty) {
      return 'Search results for: "$_searchTerm"';
    } else if (selectedCategory == 'All') {
      return 'All Deals';
    } else {
      return '$selectedCategory Deals';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height / 4,
            color: Colors.red,
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          _username,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const Account()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: _profilePhotoUrl.isEmpty
                            ? const AssetImage('assets/images/Profilephoto.png')
                            : NetworkImage(_profilePhotoUrl) as ImageProvider,
                      ),
                    ),
                  ],
                ),
                TextField(
                  onChanged: (value) {
                    _searchTerm = value;
                    _filterDeals();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, color: Colors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          backgroundColor: selectedCategory == category
                              ? Colors.red
                              : Colors.white,
                          label: Text(category,
                              style: TextStyle(
                                  color: selectedCategory == category
                                      ? Colors.white
                                      : Colors.red)),
                          selected: selectedCategory == category,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedCategory = category;
                              _filterDeals();
                            });
                          },
                          side: const BorderSide(
                              color: Colors
                                  .red), // Red border for unselected chips
                          selectedColor: Colors
                              .red, // Background color when the chip is selected
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              getCurrentLabel(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDeals.length,
              itemBuilder: (context, index) {
                var deal = _filteredDeals[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(12), // Increased margin
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MerchantDetails(
                            dealId: deal['docId'],
                            username: _username, // Pass username to MerchantDetails
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Increased padding
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              image: DecorationImage(
                                image: deal['profilePhoto'].isEmpty
                                    ? const AssetImage(
                                        'assets/images/MerchantImage.png')
                                    : NetworkImage(deal['profilePhoto'])
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  deal['couponName'], // Display coupon name
                                  style: const TextStyle(
                                    fontSize: 18, // Increased font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  deal['merchantName'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  deal['category'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
