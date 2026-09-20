import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../models/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final groupMessagesStreamProvider = StreamProvider<List<ChatMessage>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchGroupMessages();
});

class GroupMutedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setMuted(bool val) => state = val;
}

final isGroupMutedProvider =
    NotifierProvider<GroupMutedNotifier, bool>(GroupMutedNotifier.new);
