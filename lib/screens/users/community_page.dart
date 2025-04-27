import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;
  late String _currentUserId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  // Colors to match Login Page
  static const Color primaryColor = Color(0xFF4ABECD); // Turquoise button
  static const Color backgroundColor =
      Color(0xFFFFFAE7); // Light cream background
  static const Color accentColor = Color(0xFF1A237E); // Indigo[900]
  static const Color secondaryTextColor = Color(0xFF757575); // Black54

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id ?? '';
    _setupRealtime();
    _fetchInitialMessages();
  }

  Future<void> _fetchInitialMessages() async {
    try {
      final response = await _supabase
          .from('community_messages')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _messages = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: accentColor,
          ),
        );
      }
    }
  }

  void _setupRealtime() {
    _channel = _supabase.channel('community_chat');

    _channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'community_messages',
      ),
      (payload, [ref]) {
        final newMessage = payload['new'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _messages.insert(0, newMessage);
          });
        }
      },
    ).subscribe();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      await _supabase.from('community_messages').insert({
        'user_id': user.id,
        'message': message,
        'user_name': user.email?.split('@').first ?? 'Anonymous',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: accentColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Petpal Community',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentColor),
            onPressed: _fetchInitialMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: accentColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to say hello!',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message['user_id'] == _currentUserId;
                          return _MessageItem(
                            message: message,
                            isCurrentUser: isCurrentUser,
                          );
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: _MessageInput(
              controller: _messageController,
              onSend: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;

  const _MessageItem({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _CommunityPageState.accentColor;
    final primaryColor = _CommunityPageState.primaryColor;
    final secondaryTextColor = _CommunityPageState.secondaryTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isCurrentUser ? primaryColor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft:
                    isCurrentUser ? Radius.circular(16) : Radius.circular(4),
                bottomRight:
                    isCurrentUser ? Radius.circular(4) : Radius.circular(16),
              ),
              border: Border.all(
                color: isCurrentUser
                    ? primaryColor.withOpacity(0.3)
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      message['user_name'] ?? 'Anonymous',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Text(
                  message['message'],
                  style: TextStyle(
                    fontSize: 15,
                    color: isCurrentUser ? Colors.black87 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  timeago
                      .format(DateTime.parse(message['created_at']).toLocal()),
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = _CommunityPageState.primaryColor;
    final accentColor = _CommunityPageState.accentColor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.indigo[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.indigo[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  suffixIcon: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onSend,
                    ),
                  ),
                ),
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
