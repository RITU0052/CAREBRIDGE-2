import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:carebridge_ai/theme/app_theme.dart';

class DoctorChatScreen extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String? profileImage;

  const DoctorChatScreen({
    super.key,
    required this.doctorName,
    required this.doctorSpecialty,
    this.profileImage,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'doctor',
      'text': 'I would recommend some medicine',
      'type': 'text',
      'time': '09:15 AM'
    },
    {
      'sender': 'doctor',
      'text': 'Medicine recommendation 💊',
      'type': 'recommendation',
      'time': '09:16 AM'
    },
    {
      'sender': 'user',
      'text': 'Thank you Doctor!',
      'type': 'text',
      'time': '09:18 AM'
    },
    {
      'sender': 'user',
      'text': 'Good Morning Doctor',
      'type': 'text',
      'time': '09:20 AM'
    },
    {
      'sender': 'doctor',
      'text': 'Hello! Very Good Morning',
      'type': 'text',
      'time': '09:21 AM'
    },
    {
      'sender': 'user',
      'text': 'I have been suffering from fever since today and also feel headache and cold.',
      'type': 'text',
      'time': '09:22 AM'
    },
    {
      'sender': 'doctor',
      'text': 'Don\'t worry, nothing serious. I\'m giving you some medicine, you will be all right in a few days.',
      'type': 'text',
      'time': '09:25 AM'
    },
    {
      'sender': 'doctor',
      'duration': '00:30',
      'type': 'audio',
      'time': '09:26 AM'
    },
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'type': 'text',
        'time': '09:28 AM',
      });
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: widget.profileImage != null && widget.profileImage!.startsWith('http')
                  ? NetworkImage(widget.profileImage!)
                  : null,
              child: widget.profileImage == null || !widget.profileImage!.startsWith('http')
                  ? const Icon(LucideIcons.user, size: 20, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  widget.doctorSpecialty,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(LucideIcons.video, size: 18, color: AppColors.primary),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Video Call with Doctor...')),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(LucideIcons.phone, size: 18, color: AppColors.primary),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Audio Call with Doctor...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';

                if (msg['type'] == 'audio') {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 12, right: 60),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.pause, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Icon(LucideIcons.activity, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          msg['duration'] ?? '00:30',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                if (msg['type'] == 'recommendation') {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 12, right: 80),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pill, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          msg['text'] ?? 'Medicine Recommendation',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator notice
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: const [
                Text(
                  'Dr. Katherine is typing...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.mic, color: AppColors.primary),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: const Color(0xFFF2F4F8),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
