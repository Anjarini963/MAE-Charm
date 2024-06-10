import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Coupons.dart';

class MerchantDetails extends StatefulWidget {
  final String dealId;
  final String username;

  const MerchantDetails({Key? key, required this.dealId, required this.username}) : super(key: key);

  @override
  _MerchantDetailsState createState() => _MerchantDetailsState();
}

class _MerchantDetailsState extends State<MerchantDetails> {
  bool isLoading = true;
  Map<String, dynamic>? dealData;
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  List<Map<String, dynamic>> reviews = [];
  int totalCoupons = 0;
  int pendingOrRedeemedCoupons = 0;

  @override
  void initState() {
    super.initState();
    fetchDealData();
    fetchReviews();
    fetchCouponData();
  }

  Future<void> fetchDealData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Deals')
          .doc(widget.dealId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        dealData = snapshot.data() as Map<String, dynamic>;
        setState(() => isLoading = false);
      } else {
        throw Exception('Deal not found');
      }
    } catch (e) {
      print('Error fetching deal: $e');
      Navigator.pop(context);
    }
  }

  Future<void> fetchReviews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .where('DealID', isEqualTo: widget.dealId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        reviews = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> fetchCouponData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Coupons')
          .where('DealID', isEqualTo: widget.dealId)
          .get();

      totalCoupons = snapshot.docs.length;
      pendingOrRedeemedCoupons = snapshot.docs.where((doc) {
        String status = doc['Status'];
        return status == 'pending redemption' || status == 'redeemed';
      }).length;

      setState(() {});
    } catch (e) {
      print('Error fetching coupon data: $e');
    }
  }

  Future<void> _getCoupon() async {
    try {
      QuerySnapshot couponSnapshot = await FirebaseFirestore.instance
          .collection('Coupons')
          .where('DealID', isEqualTo: widget.dealId)
          .where('Status', isEqualTo: 'unused')
          .limit(1)
          .get();

      if (couponSnapshot.docs.isNotEmpty) {
        DocumentSnapshot couponDoc = couponSnapshot.docs.first;
        String couponCode = couponDoc['Coupon Code'];

        await couponDoc.reference.update({'Status': 'pending redemption'});

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Coupons(
              collectionId: couponDoc.id,
              username: widget.username,
              category: dealData!['Category'],
              restaurant: dealData!['Vendor Name'],
              date: DateTime.now().toString(),
              couponCode: couponCode,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No coupons available for this deal.")),
        );
      }
    } catch (e) {
      print('Error fetching coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch coupon: $e")),
      );
    }
  }

  Future<void> _submitReview() async {
    String uid = widget.username;

    try {
      await FirebaseFirestore.instance.collection('Reviews').add({
        'DealID': widget.dealId,
        'UID': uid,
        'Review': _reviewController.text,
        'Rating': int.parse(_ratingController.text),
        'Username': widget.username, // Add the username field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully.")),
      );

      _reviewController.clear();
      _ratingController.clear();
      fetchReviews(); // Refresh the reviews list
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.red,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(dealData?['Vendor Name'] ?? 'Vendor Details',
                  style: const TextStyle(color: Colors.white)),
              centerTitle: true,
            ),
            body: CustomScrollView(
              slivers: [
                _buildImageSection(dealData?['Deal Image'] ?? ''),
                _buildDetailsSection(dealData?['Category'] ?? 'N/A', dealData?['Rating'].toString() ?? 'N/A'),
                _buildCouponDetails(dealData?['Description'] ?? ''),
                _buildReviewsSection(),
                _buildReviewSection(),
                _buildCouponProgressBar(),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(context),
          );
  }

  Widget _buildImageSection(String imageUrl) => SliverToBoxAdapter(
        child: Image.network(
          imageUrl,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('assets/images/default.png', fit: BoxFit.cover),
        ),
      );

  Widget _buildDetailsSection(String category, String rating) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(category, style: const TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  Text(' $rating', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildCouponDetails(String description) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Coupon Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

  Widget _buildReviewsSection() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              reviews.isEmpty
                  ? const Text('No reviews available for this deal.', style: TextStyle(fontSize: 16))
                  : Column(
                      children: reviews.map((review) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(review['Username'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 24),
                                        Text(review['Rating'].toString(), style: const TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(review['Review'], style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      );

  Widget _buildReviewSection() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Rating out of 5',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitReview,
                child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Widget _buildCouponProgressBar() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Coupons Left', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: totalCoupons == 0 ? 0 : pendingOrRedeemedCoupons / totalCoupons,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 10),
              Text(
                'Coupons: $pendingOrRedeemedCoupons / $totalCoupons',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );

  Widget _buildBottomBar(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: ElevatedButton(
          onPressed: _getCoupon,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_offer, color: Colors.white),
              Text(' Get Coupon', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
}
