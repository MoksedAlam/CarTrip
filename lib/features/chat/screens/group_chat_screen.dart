import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/chat_message.dart';
import '../providers/chat_providers.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend({String? mediaType, String? mediaUrl}) async {
    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
        senderId: user.uid,
        senderName: user.name.isNotEmpty ? user.name : 'Member',
        senderPhotoUrl: user.photoUrl,
        senderRole: user.role,
        text: text,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showMediaDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Media or Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share a photo URL or link to the group. Media is stored locally on device without bloating database.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Image or Link URL',
                hintText: 'https://example.com/photo.jpg',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              Navigator.pop(ctx);
              if (url.isNotEmpty) {
                _handleSend(mediaType: url.contains(RegExp(r'\.(jpg|png|jpeg|webp)$')) ? 'image' : 'link', mediaUrl: url);
              }
            },
            child: const Text('Send to Group'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(groupMessagesStreamProvider);
    final isMuted = ref.watch(isGroupMutedProvider);
    final currentUser = ref.watch(currentUserDocProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CarTrip Community', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'Owners & Drivers Fleet Group',
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded),
            tooltip: isMuted ? 'Unmute Group' : 'Mute Group',
            color: isMuted ? theme.colorScheme.error : theme.colorScheme.primary,
            onPressed: () {
              ref.read(isGroupMutedProvider.notifier).toggle();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isMuted ? 'Group notifications unmuted' : 'Group muted'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Group Rules',
            onPressed: () => _showGroupRules(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Notice banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Official Fleet Group • Messages cannot be deleted • Permanent record',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

            // Messages Stream
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Welcome to CarTrip Community!',
                      description: 'Start the conversation with other fleet owners and drivers.',
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.uid;
                      return _buildMessageBubble(context, msg, isMe);
                    },
                  );
                },
                loading: () => const LoadingView(message: 'Loading group messages...'),
                error: (err, _) => ErrorView(message: err.toString()),
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    tooltip: 'Share photo or link',
                    onPressed: _showMediaDialog,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message to the fleet...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    onPressed: _isSending ? null : () => _handleSend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe) {
    final theme = Theme.of(context);
    final isSuperAdmin = msg.senderRole == 'superAdmin';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSuperAdmin ? Colors.amber.shade800 : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: (isSuperAdmin ? Colors.amber : theme.colorScheme.secondary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      msg.senderRole.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSuperAdmin ? Colors.amber.shade900 : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Media attachment if present
            if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
              if (msg.mediaType == 'image') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black12,
                      child: const Row(
                        children: [
                          Icon(Icons.broken_image_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Image attachment', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ] else ...[
                InkWell(
                  onTap: () => launchUrl(Uri.parse(msg.mediaUrl!), mode: LaunchMode.externalApplication),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            msg.mediaUrl!,
                            style: const TextStyle(fontSize: 11, decoration: TextDecoration.underline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],

            // Text
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                ),
              ),

            const SizedBox(height: 2),

            // Timestamp
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                Formatters.time(msg.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: (isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant)
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text('Community Guidelines'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• This is an open group for all registered CarTrip vehicle owners and drivers.'),
            SizedBox(height: 6),
            Text('• No private 1-on-1 messaging is allowed to ensure complete transparency.'),
            SizedBox(height: 6),
            Text('• Messages cannot be deleted once sent (audit trail maintained).'),
            SizedBox(height: 6),
            Text('• Media and links are shared directly without server bloat.'),
            SizedBox(height: 6),
            Text('• You can mute notifications anytime from the bell icon.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
  }
}
