import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: Colors.pink,

      ),
      body: const Center(
        child: Text("All Notifications will appear here.", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}