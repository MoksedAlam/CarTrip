import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String senderRole; // owner, driver, superAdmin
  final String text;
  final String? mediaType; // 'image', 'video', 'link'
  final String? mediaUrl;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.senderRole,
    required this.text,
    this.mediaType,
    this.mediaUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'senderRole': senderRole,
      'text': text,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      senderRole: data['senderRole'] as String? ?? 'owner',
      text: data['text'] as String? ?? '',
      mediaType: data['mediaType'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
