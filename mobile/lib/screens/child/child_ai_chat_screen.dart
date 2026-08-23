import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_theme.dart';

/// AI Chatbot screen — simulates conversation about parent's health
class ChildAiChatScreen extends StatefulWidget {
  const ChildAiChatScreen({super.key});

  @override
  State<ChildAiChatScreen> createState() => _ChildAiChatScreenState();
}

class _ChildAiChatScreenState extends State<ChildAiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Hello! I'm CareBridge AI 👋\n\nI can help you check on your parents' health. Ask me anything like:\n• How is Mom's sugar today?\n• What medicines did Dad take?\n• Is BP normal?",
      isAI: true,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  final List<String> _quickQuestions = [
    'How is Mom today?',
    'Medicine status?',
    'Is BP normal?',
    'Health summary',
    'Risk assessment',
    'Upcoming appointments',
  ];

  // Simulated AI responses
  String _getAIResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('mom') || q.contains('summary') || q.contains('today')) {
      return "📊 **Health Summary for Mom (Today)**\n\n• Blood Pressure: 128/82 mmHg ✅ Normal\n• Sugar: 145 mg/dL ⚠️ Slightly High\n• Heart Rate: 78 bpm ✅ Normal\n• Oxygen: 97% ✅ Normal\n\n💊 Medicines:\n• Morning: Metformin 500mg ✅ Taken\n• Evening: Amlodipine 5mg ⏰ Pending\n\n🤖 AI Insight: Sugar is slightly elevated compared to last week. Recommend checking diet and ensuring evening medicine is taken.";
    } else if (q.contains('medicine') || q.contains('med')) {
      return "💊 **Medicine Status — Today**\n\n✅ Metformin 500mg — Morning — TAKEN (9:15 AM)\n✅ Amlodipine 5mg — Afternoon — TAKEN (1:30 PM)\n⏰ Metformin 500mg — Evening — PENDING\n\nYour parent has taken 2 out of 3 medicines today. I'll send an alert when the evening medicine is due (8:00 PM).";
    } else if (q.contains('bp') || q.contains('blood pressure')) {
      return "❤️ **Blood Pressure Report**\n\n• Latest: 128/82 mmHg — ✅ Normal Range\n• Last week avg: 132/86 mmHg\n• Trend: 📉 Improving\n\nThe systolic pressure has decreased by 4 points compared to last week. This is a positive trend. Continue current medication and low-sodium diet.";
    } else if (q.contains('risk') || q.contains('assessment')) {
      return "🧠 **AI Risk Assessment**\n\n• Overall Risk: 🟡 Moderate (38/100)\n• Stroke Risk: Low ✅\n• Heart Disease Risk: Moderate ⚠️\n• Diabetes Control: Needs Attention ⚠️\n\nKey factors:\n→ Sugar slightly high (145 mg/dL)\n→ Missed 2 evening medicines this week\n→ BP improving — continue monitoring\n\n💡 Recommendation: Schedule a doctor consultation within 2 weeks.";
    } else if (q.contains('appointment')) {
      return "📅 **Upcoming Appointments**\n\n1. Dr. Priya Sharma (Cardiologist)\n   📍 Apollo Hospital\n   📅 Tomorrow — 10:00 AM\n\n2. Path Labs — HbA1c Test\n   📍 City Diagnostics\n   📅 Aug 6 — 8:30 AM\n\nShall I send a reminder to your parent?";
    } else {
      return "I understand you're asking about \"$question\".\n\nHere's what I found:\n• All vitals are within normal range today\n• 2/3 medicines taken\n• Next appointment: Tomorrow at Apollo Hospital\n\nIs there anything specific you'd like to know? 😊";
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isAI: false, time: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: _getAIResponse(text), isAI: true, time: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F1F7), height: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CareBridge AI', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Active Medical Assistant', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ── Chat messages ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                ..._messages.map((msg) => _MessageBubble(message: msg)),
                if (_isTyping) const _TypingIndicator(),
              ],
            ),
          ),

          // ── Quick questions ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick questions', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickQuestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _sendMessage(_quickQuestions[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                        ),
                        child: Text(
                          _quickQuestions[i],
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about Mom\'s health...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.primaryGradient),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAI;
  final DateTime time;

  _ChatMessage({required this.text, required this.isAI, required this.time});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAI ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isAI ? Radius.zero : const Radius.circular(18),
                  bottomRight: isAI ? const Radius.circular(18) : Radius.zero,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isAI ? AppColors.textPrimary : Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.time),
                    style: AppTextStyles.caption.copyWith(
                      color: isAI ? AppColors.textTertiary : Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 150)),
    );
    _animations = _controllers.map((c) => Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: List.generate(3, (i) => AnimatedBuilder(
              animation: _animations[i],
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _animations[i].value),
                child: Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.6), shape: BoxShape.circle),
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }
}
