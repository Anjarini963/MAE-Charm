import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Reviews extends StatefulWidget {
  final String uid;
  const Reviews({Key? key, required this.uid}) : super(key: key);

  @override
  _ReviewsState createState() => _ReviewsState();
}

class _ReviewsState extends State<Reviews> {
  String? _selectedDealId;
  List<Map<String, String>> _deals = [];
  List<Map<String, dynamic>> _reviews = [];

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

  Future<void> _loadReviews(String dealId) async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance.collection('Reviews').where('DealID', isEqualTo: dealId).get();
    List<Map<String, dynamic>> loadedReviews = [];
    for (var doc in reviewSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      loadedReviews.add(data);
    }
    setState(() {
      _reviews = loadedReviews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews', style: TextStyle(color: Colors.white)),
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
                    _loadReviews(value);
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Deal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _reviews.isEmpty
                ? const Text('No reviews available for this deal.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      var review = _reviews[index];
                      return Card(
                        child: ListTile(
                          title: Text(review['Username']),
                          subtitle: Text(review['Review']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text(review['Rating'].toString()),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
