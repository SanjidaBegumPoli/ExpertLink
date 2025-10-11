import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'blog_model.dart';

class PrefectDetailPage extends StatefulWidget {
  final String prefectId;
  final String prefectName;

  const PrefectDetailPage({
    super.key,
    required this.prefectId,
    required this.prefectName,
  });

  @override
  State<PrefectDetailPage> createState() => _PrefectDetailPageState();
}

class _PrefectDetailPageState extends State<PrefectDetailPage> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _editBlog(BuildContext context, String blogId, String title, String content) {
    final titleController = TextEditingController(text: title);
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Blog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('blogs').doc(blogId).update({
                'title': titleController.text,
                'content': contentController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBlog(String blogId) async {
    await FirebaseFirestore.instance.collection('blogs').doc(blogId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final prefectRef = FirebaseFirestore.instance.collection('users').doc(widget.prefectId);
    final blogStream = FirebaseFirestore.instance
        .collection('blogs')
        .where('prefectid', isEqualTo: widget.prefectId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(widget.prefectName), backgroundColor: Colors.pink),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: prefectRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.pink.shade100,
                    backgroundImage: data['profileImage'] != null ? NetworkImage(data['profileImage']) : null,
                    child: data['profileImage'] == null
                        ? const Icon(Icons.person, size: 50, color: Colors.pink)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(data['name'] ?? 'Unknown Prefect', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
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
                    if (!blogSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = blogSnap.data!.docs;
                    if (docs.isEmpty) return const Text("No blogs uploaded yet.");

                    final blogs = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return BlogModel(
                        id: doc.id,
                        title: data['title'] ?? '',
                        content: data['content'] ?? '',
                        prefectId: data['prefectId'] ?? '',
                        assetName: data['assetName'] ?? '',
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
                                  InkWell(
                                    onTap: () => _launchUrl(blog.assetUrl!),
                                    child: Text('View Link: ${blog.assetName}', style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline)),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editBlog(context, blog.id, blog.title, blog.content);
                                } else if (value == 'delete') {
                                  _deleteBlog(blog.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
