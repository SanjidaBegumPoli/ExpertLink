import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';

class PrefectChatListPage extends StatelessWidget {
  const PrefectChatListPage({super.key});

  Future<Map<String, dynamic>?> _getStudentData(String studentId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final prefectId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats with Students"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('prefectId', isEqualTo: prefectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;

          if (chats.isEmpty) return const Center(child: Text("No chats yet"));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final studentId = chat['studentId'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getStudentData(studentId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text("Loading..."),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final studentName = userData['name'] ?? 'Unknown Student';
                  final studentPhoto = userData['profileImage'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                      studentPhoto.isNotEmpty ? NetworkImage(studentPhoto) : null,
                      child: studentPhoto.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                      backgroundColor: Colors.pink.shade200,
                    ),
                    title: Text(studentName),
                    subtitle: Text("Tap to chat"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatPage(chatId: chatId, receiverId: studentId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
