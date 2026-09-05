import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildSkeleton() : _buildContent();
  }

  Widget _buildSkeleton() {
    return Row(
      children: [
        if (!Responsive.isMobile(context))
          SizedBox(
            width: Responsive.maxValue(context, mobile: 250, tablet: 300, desktop: 350),
            child: SkeletonList(itemCount: 5),
          ),
        const Expanded(
          child: Column(
            children: [
              SkeletonCard(height: 60),
              Expanded(child: SkeletonList(itemCount: 4)),
              SkeletonCard(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (Responsive.isMobile(context)) {
      return _buildMobileLayout();
    }
    return _buildDesktopLayout();
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildChatHeader(),
        Expanded(child: _buildMessages()),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: Responsive.maxValue(context, mobile: 250, tablet: 300, desktop: 350), child: _buildChatList()),
        Expanded(
          child: Column(
            children: [
              _buildChatHeader(),
              Expanded(child: _buildMessages()),
              _buildMessageInput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    final chats = [
      {'name': 'Admin', 'lastMsg': 'Please check the invoice', 'time': '11:20 AM', 'unread': 2, 'avatar': 'A'},
      {'name': 'Client A', 'lastMsg': 'Payment received', 'time': '10:15 AM', 'unread': 0, 'avatar': 'C'},
      {'name': 'Vendor B', 'lastMsg': 'Please send the bill', 'time': 'Yesterday', 'unread': 1, 'avatar': 'V'},
      {'name': 'Client C', 'lastMsg': 'Thanks!', 'time': 'Yesterday', 'unread': 0, 'avatar': 'C'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppSearchField(hint: 'Search chats...'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatListItem(chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat) {
    return AppListTile(
      title: chat['name'],
      subtitle: chat['lastMsg'],
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(chat['avatar'], style: const TextStyle(color: Colors.white)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chat['time'], style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (chat['unread'] > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${chat['unread']}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Text('A', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const Text('Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconAppButton(icon: Icons.phone, onPressed: () {}),
          const SizedBox(width: 8),
          IconAppButton(icon: Icons.videocam, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final messages = [
      {'text': 'Please check the invoice from Client A', 'isMe': false, 'time': '11:20 AM'},
      {'text': 'Yes, checking now', 'isMe': true, 'time': '11:25 AM'},
      {'text': 'Payment received for INV-001', 'isMe': false, 'time': '11:30 AM'},
      {'text': 'Thank you!', 'isMe': true, 'time': '11:35 AM'},
    ];

    return ListView.builder(
      padding: Responsive.padding(context),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['text'],
              style: TextStyle(fontSize: 14, color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              message['time'],
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconAppButton(icon: Icons.attach_file, onPressed: () {}),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
