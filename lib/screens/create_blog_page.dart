import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateBlogPage extends StatefulWidget {
  final String userId;

  const CreateBlogPage({super.key, required this.userId});

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  Future<void> _saveBlog() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('blogs').add({
      'title': titleController.text,
      'content': contentController.text,
      'prefectId': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    titleController.clear();
    contentController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blog uploaded successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Blog"), backgroundColor: Colors.pink),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: "Content"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBlog,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: const Text("Upload Blog"),
            ),
          ],
        ),
      ),
    );
  }
}