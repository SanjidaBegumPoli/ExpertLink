import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_page.dart';
import 'student_home.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class StudentChatListPage extends StatefulWidget {
  final String userName;

  const StudentChatListPage({super.key, required this.userName});

  @override
  State<StudentChatListPage> createState() => _StudentChatListPageState();
}

class _StudentChatListPageState extends State<StudentChatListPage> {
  int _selectedIndex = 2;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      StudentHomePage(userName: widget.userName),
      const ProfilePage(),
      _buildChatPage(),
      const SettingsPage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildChatPage() {
    final String studentId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Prefects"),
        backgroundColor: Colors.pink,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'prefect')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No prefects available"));
          }

          final prefects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: prefects.length,
            itemBuilder: (context, index) {
              final prefect = prefects[index].data();
              final prefectId = prefects[index].id;

              return ListTile(
                title: Text(prefect['name'] ?? 'Unknown Prefect'),
                subtitle: Text(prefect['email'] ?? ''),
                trailing: const Icon(Icons.chat, color: Colors.pink),
                onTap: () async {
                  final chatId = await getOrCreateChat(studentId, prefectId);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: chatId,
                          receiverId: prefectId,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _pages[_selectedIndex];
  }
}
