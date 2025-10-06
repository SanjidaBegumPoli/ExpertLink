import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrefectDetailPage extends StatelessWidget {
  final String prefectId;
  final String prefectName;

  const PrefectDetailPage({
    super.key,
    required this.prefectId,
    required this.prefectName,
  });

  @override
  Widget build(BuildContext context) {
    final prefectRef =
    FirebaseFirestore.instance.collection('users').doc(prefectId);

    final blogStream = FirebaseFirestore.instance
        .collection('blogs')
        .where('prefectId', isEqualTo: prefectId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(prefectName),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: prefectRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.pink.shade100,
                    backgroundImage: data['profileImage'] != null
                        ? NetworkImage(data['profileImage'])
                        : null,
                    child: data['profileImage'] == null
                        ? const Icon(Icons.person, size: 50, color: Colors.pink)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    data['name'] ?? 'Unknown Prefect',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text("Department: ${data['department'] ?? 'N/A'}"),
                Text("Batch: ${data['batch'] ?? 'N/A'}"),
                Text("Email: ${data['email'] ?? 'N/A'}"),
                Text("Phone: ${data['phone'] ?? 'N/A'}"),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Blogs:",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: blogStream,
                  builder: (context, blogSnap) {
                    if (!blogSnap.hasData ||
                        blogSnap.data!.docs.isEmpty) {
                      return const Text("No blogs uploaded yet.");
                    }

                    final blogs = blogSnap.data!.docs;
                    return Column(
                      children: blogs.map((doc) {
                        final blog = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(blog['title'] ?? 'Untitled'),
                            subtitle: Text(blog['content'] ?? ''),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
