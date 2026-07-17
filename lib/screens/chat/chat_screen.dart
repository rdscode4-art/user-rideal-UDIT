import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/services/chat_api_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.rideId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  bool _isLoading = true;
  String _myUserId = '';

  @override
  void initState() {
    super.initState();
    _getMyUserId();
    _fetchMessages();
    _startPolling();
  }

  Future<void> _getMyUserId() async {
    // Assuming user details or token is stored, we just need a way to differentiate sender.
    // If the API returns senderId, we can compare it with widget.receiverId.
    // So anything where senderId == widget.receiverId is from them.
    // We don't strictly need myUserId if we just assume != receiverId means it's mine.
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(isBackground: true);
    });
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isLoading = true);
    }
    
    final messages = await ChatApiService.getChatHistory(widget.rideId);
    
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Auto-scroll to bottom if new messages arrived
      if (!isBackground) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI update
    final newMessage = {
      'message': text,
      'senderId': 'ME', // Temporary ID to show as my message
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    setState(() {
      _messages.add(newMessage);
      _msgController.clear();
    });
    
    _scrollToBottom();

    final success = await ChatApiService.sendMessage(
      rideId: widget.rideId,
      receiverId: widget.receiverId,
      message: text,
    );

    if (success) {
      // Force an immediate refresh to get the real DB message
      _fetchMessages(isBackground: true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
        // Revert optimistic update
        setState(() {
          _messages.removeLast();
        });
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          widget.receiverName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages yet.\nStart the conversation!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final messageText = msg['message']?.toString() ?? '';
                          final senderId = msg['senderId']?.toString() ?? '';
                          
                          // If senderId matches receiverId, it's from the driver. Otherwise it's ours.
                          final isMe = senderId != widget.receiverId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12.w),
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.r),
                                  topRight: Radius.circular(16.r),
                                  bottomLeft: Radius.circular(isMe ? 16.r : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16.r),
                                ),
                              ),
                              child: Text(
                                messageText,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
