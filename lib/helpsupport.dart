// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rideal/authservices.dart'; // Make sure to import your authservices

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SupportChatScreenState createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final String supportPhoneNumber = '06792451322';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = [];
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    Future.delayed(Duration(milliseconds: 500), () {
      _addSupportMessage("Hello! Welcome to RiDeal Support.\nHow can I help you today?");
    });
  }

  void _addSupportMessage(String text) {
    setState(() {
      messages.add(Message(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: supportPhoneNumber,
    );
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showCallErrorDialog();
      }
    } catch (e) {
      _showCallErrorDialog();
    }
  }

  void _showCallErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unable to Make Call'),
          content: Text('Phone calls are not supported on this device or the number $supportPhoneNumber is not valid.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show ticket creation dialog
  void _showCreateTicketDialog() {
    // ignore: unused_local_variable
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final TextEditingController rideIdController = TextEditingController();
    String selectedCategory = 'General Issue';
    bool isSubmitting = false;

    final List<String> categories = [
      'General Issue',
      'Payment Problem',
      'Driver Issue',
      'Vehicle Problem',
      'App Technical Issue',
      'Account Problem',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.green.shade400),
                  SizedBox(width: 8),
                  Text('Create Support Ticket'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    // SizedBox(height: 16),
                    // Text('Ride ID (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                    // SizedBox(height: 8),
                    // TextFormField(
                    //   controller: rideIdController,
                    //   decoration: InputDecoration(
                    //     hintText: 'Enter ride ID if applicable',
                    //     border: OutlineInputBorder(),
                    //     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    //   ),
                    // ),
                    SizedBox(height: 16),
                    Text('Message', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: messageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe your issue in detail (minimum 10 characters)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting ? null : () async {
                    if (messageController.text.trim().length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please provide at least 10 characters in your message')),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSubmitting = true;
                    });

                    try {
                      await Authservices.createTicket(
                        selectedCategory,
                        messageController.text.trim(),
                        rideIdController.text.trim().isEmpty ? 'N/A' : rideIdController.text.trim(),
                      );

                      Navigator.of(context).pop(); // Close dialog

                      // Add success message to chat
                      _addSupportMessage("✅ Your support ticket has been created successfully! Our team will review your request and get back to you soon.\n\nTicket Category: $selectedCategory");

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Support ticket created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        isSubmitting = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating ticket: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Create Ticket'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _addUserMessage(String text) {
    setState(() {
      messages.add(Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _handleUserMessage(text);
  }

  void _handleUserMessage(String userMessage) {
    setState(() {
      isTyping = true;
    });

    // Simulate support response delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isTyping = false;
      });

      String response = _generateSupportResponse(userMessage);
      _addSupportMessage(response);
    });
  }

  String _generateSupportResponse(String userMessage) {
    String lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('ticket') || lowerMessage.contains('complaint')) {
      return "I can help you create a support ticket! Please tap the ticket icon (🎫) at the top right to create a formal support ticket that our team can track and respond to.";
    } else if (lowerMessage.contains('earnings') || lowerMessage.contains('payment')) {
      return "I'd be happy to help you with payment issues! For detailed assistance, please create a support ticket using the ticket button so our team can investigate your account.";
    } else if (lowerMessage.contains('hi') || lowerMessage.contains('hello')) {
      return "Thank you for your message. I've noted your query and will assist you accordingly. For urgent issues, feel free to create a support ticket using the ticket button below.";
    } else if (lowerMessage.contains('account') || lowerMessage.contains('profile')) {
      return "I can help you with account-related issues. For account problems that require investigation, please create a support ticket so our team can review your account details securely.";
    } else if (lowerMessage.contains('order') || lowerMessage.contains('delivery')) {
      return "I understand you have a query about orders or delivery. Please create a support ticket with your ride ID for faster resolution.";
    } else {
      return "Thank you for contacting support. I'm here to help! For complex issues, you can create a support ticket using the ticket button (🎫) below for detailed assistance.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _addUserMessage(text);
      _messageController.clear();
    }
  }

  String _formatTime(DateTime dateTime) {
    // ignore: unused_local_variable
    String hour = dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    int displayHour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    if (displayHour == 0) displayHour = 12;
    
    return '$displayHour:$minute $period';
  }

  Widget _buildMessageBubble(Message message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange,
              child: Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.green.shade400 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.shade400,
            child: Icon(Icons.support_agent, color: Colors.white, size: 20),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.more_horiz)
                ),
                SizedBox(width: 8),
                Text(
                  "Typing...",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.green.shade400,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(Icons.support_agent, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RiDeal Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
               IconButton(
        onPressed: _showCreateTicketDialog,
        // backgroundColor: Colors.green.shade400,
        icon: Icon(Icons.confirmation_num,color: Colors.white),
        tooltip: 'Create Support Ticket',
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              IconButton(
                icon: Icon(Icons.call, color: Colors.white),
                onPressed: _makePhoneCall,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner about ticket creation
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For formal support requests, create a ticket using the button above',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}