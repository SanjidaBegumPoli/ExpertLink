import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'blog_model.dart';

class PrefectDetailPage extends StatelessWidget {
  final String prefectId;
  final String prefectName;

  const PrefectDetailPage({
    super.key,
    required this.prefectId,
    required this.prefectName,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefectRef = FirebaseFirestore.instance.collection('users').doc(prefectId);

    final blogStream = FirebaseFirestore.instance
        .collection('blogs')
        .where('prefectid', isEqualTo: prefectId) // ✅ match Firestore field
    //.orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true);

    return Scaffold(
      appBar: AppBar(title: Text(prefectName), backgroundColor: Colors.pink),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: prefectRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                  child: Text(data['name'] ?? 'Unknown Prefect',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text("Department: ${data['department'] ?? 'N/A'}"),
                Text("Batch: ${data['batch'] ?? 'N/A'}"),
                Text("Email: ${data['email'] ?? 'N/A'}"),
                Text("Phone: ${data['phone'] ?? 'N/A'}"),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Blogs:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: blogStream,
                  builder: (context, blogSnap) {
                    if (blogSnap.hasError) {
                      return Text("Error loading blogs: ${blogSnap.error}");
                    }

                    if (blogSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = blogSnap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Text("No blogs uploaded yet.");
                    }

                    final blogs = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return BlogModel(
                        id: doc.id,
                        title: data['title'] ?? '',
                        content: data['content'] ?? '',
                        prefectId: data['prefectId'] ?? '',
                        assetName: data['assetName'] ?? 'No Name',
                        assetUrl: data['assetUrl'] ?? '',
                        createdAt: data['createdAt'],
                      );
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: blogs.length,
                      itemBuilder: (context, index) {
                        final blog = blogs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(blog.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(blog.content),
                                if (blog.assetUrl != null && blog.assetUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: InkWell(
                                      onTap: () async {
                                        try {
                                          await _launchUrl(blog.assetUrl!);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error opening link: $e')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        'View Link: ${blog.assetName ?? 'Click here'}',
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            );
          },
        ),
      ),
    );
  }
}