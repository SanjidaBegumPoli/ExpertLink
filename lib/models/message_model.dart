import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(), // ✅ server time
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    final rawTs = map['timestamp'];
    DateTime parsedTime;

    if (rawTs == null) {
      parsedTime = DateTime.now();
    } else if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      parsedTime = DateTime.tryParse(rawTs.toString()) ?? DateTime.now();
    }

    return Message(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedTime,
    );
  }
}