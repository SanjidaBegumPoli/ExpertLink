import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrefectProfilePage extends StatelessWidget {
  final String userId;

  const PrefectProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("No profile data"));
          }
          return Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: data['profileImageUrl'] != null
                        ? NetworkImage(data['profileImageUrl'])
                        : null,
                    child: data['profileImageUrl'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(data['name'] ?? '',
                      style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Category: ${data['category']}"),
                  const SizedBox(height: 8),
                  Text("Status: ${data['approvalStatus']}",
                      style: TextStyle(
                          color: data['approvalStatus'] == 'approved'
                              ? Colors.green
                              : Colors.orange)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
