import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      _firestore.collection('group_messages');

  Stream<List<ChatMessage>> watchGroupMessages({int limit = 100}) {
    return _messagesCollection
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String senderRole,
    required String text,
    String? mediaType,
    String? mediaUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    await _messagesCollection.add({
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'senderRole': senderRole,
      'text': cleanText,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
