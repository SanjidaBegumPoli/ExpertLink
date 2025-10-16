import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> getOrCreateChat(String studentId, String prefectId) async {
  final chatQuery = await FirebaseFirestore.instance
      .collection('chats')
      .where('studentId', isEqualTo: studentId)
      .where('prefectId', isEqualTo: prefectId)
      .limit(1)
      .get();

  if (chatQuery.docs.isNotEmpty) {
    return chatQuery.docs.first.id;
  }

  final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
    'studentId': studentId,
    'prefectId': prefectId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return chatDoc.id;
}
