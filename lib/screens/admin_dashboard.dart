import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const PendingPrefectApprovalsPage(),
      const StudentProfilesPage(),
      const PrefectProfilesPage(),
    ]);
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel",
            style: TextStyle(
                color: Colors.white
            )
        ),
        backgroundColor: Colors.pink,
        leading: IconButton(
          icon: Icon(
              Icons.arrow_back,
              color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No new notifications.")),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: "Pending Prefects",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Students",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: "Prefects",
          ),
        ],
      ),
    );
  }
}

// Helper function
String _safeGet(Map<String, dynamic> data, String key) {
  final val = data[key];
  if (val == null) return '';
  if (val is List && val.isNotEmpty) return val.join(', ');
  return val.toString();
}

//Pending Prefect Approvals
class PendingPrefectApprovalsPage extends StatelessWidget {
  const PendingPrefectApprovalsPage(
      {
        super.key
      }
      );

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'prefect')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return
            Center(
                child: CircularProgressIndicator()
            );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return
            Center(
                child: Text
                  (
                    "No pending prefects."
                )
            );
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['name'] ?? 'No name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("Email: ${_safeGet(data, 'email')}"),
                    Text("Batch: ${_safeGet(data, 'batch')}"),
                    Text("Contact: ${_safeGet(data, 'phone')}"),
                    Text("Expertise: ${_safeGet(data, 'expertise')}"),
                    SizedBox(
                        height: 10
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .update({'status': 'approved'});
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "${data['name']} approved"
                                    )
                                )
                            );
                          },
                          child: Text("Approve"),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${data['name']} rejected")));
                          },
                          child: Text("Reject"),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.info, color: Colors.pink),
                          onPressed: () => _showDetailDialog(context, data),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//Student Profiles
class StudentProfilesPage extends StatelessWidget {
  const StudentProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No students found."));
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.pink,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(data['name'] ?? 'No name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${_safeGet(data, 'email')}"),
                  Text("Batch: ${_safeGet(data, 'batch')}"),
                  //Text("Expertise: ${_safeGet(data, 'expertise')}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(docs[index].id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${data['name']} removed")));
                },
              ),
              onTap: () => _showDetailDialog(context, data),
            );
          },
        );
      },
    );
  }
}

//Approved Prefect Profiles
class PrefectProfilesPage extends StatelessWidget {
  const PrefectProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'prefect')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No approved prefects."));
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.pink,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(data['name'] ?? 'No name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${_safeGet(data, 'email')}"),
                  Text("Batch: ${_safeGet(data, 'batch')}"),
                  Text("Expertise: ${_safeGet(data, 'expertise')}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(docs[index].id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${data['name']} removed")));
                },
              ),
              onTap: () => _showDetailDialog(context, data),
            );
          },
        );
      },
    );
  }
}

//Show detail dialog
void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.pink,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(data['name'] ?? 'No name',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['email'] != null) Text("Email: ${data['email']}"),
          if (data['batch'] != null) Text("Batch: ${data['batch']}"),
          if (data['phone'] != null) Text("Contact: ${data['phone']}"),
          if (data['expertise'] != null) Text("Expertise: ${data['expertise']}"),
          if (data['bio'] != null) ...[
            const SizedBox(height: 8),
            const Text("About:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['bio']),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.pink)),
        ),
      ],
    ),
  );
}