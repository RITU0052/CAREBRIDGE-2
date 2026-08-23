import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/parent_profile.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import 'parent_detail_screen.dart';
import 'child_health_monitor_screen.dart';
import 'child_ai_chat_screen.dart';
import 'child_expense_screen.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../parent/parent_reports_screen.dart';
import '../../widgets/papa_daily_summary_card.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> with TickerProviderStateMixin {
  late Future<List<ParentProfile>> _parentsFuture;
  late Future<List<dynamic>> _sosFuture;
  int _currentIndex = 0;
  late AnimationController _headerFadeController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _parentsFuture = _loadParents();
    _sosFuture = _loadSOS();
    _headerFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerFadeController, curve: Curves.easeOut);
    _headerFadeController.forward();
  }

  @override
  void dispose() {
    _headerFadeController.dispose();
    super.dispose();
  }

  Future<List<ParentProfile>> _loadParents() async {
    try {
      final me = await ApiService().getMe();
      if (me['linked_users'] != null) {
        final List<dynamic> linked = me['linked_users'];
        return linked.map((p) => ParentProfile.fromJson(p)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> _loadSOS() async {
    return await ApiService().getActiveSOS();
  }

  Future<void> _refresh() async {
    setState(() {
      _parentsFuture = _loadParents();
      _sosFuture = _loadSOS();
    });
  }

  void _showConnectFamilyDialog(BuildContext context) {
    final codeController = TextEditingController();
    final emailController = TextEditingController();
    int activeTab = 0; // 0: Invite by Email, 1: Enter Code
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text('Link Parent Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: activeTab == 0 ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '📧 Invite via Email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: activeTab == 1 ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '🔑 Enter Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeTab == 0) ...[
                const Text(
                  'Enter your parent\'s email address. We will send them an official email invitation with pairing instructions and an invitation code.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Parent\'s Email Address',
                    hintText: 'parent@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ] else ...[
                const Text(
                  'Enter the 6-digit Family Invitation Code received via email or shown on your parent\'s dashboard (e.g. CB-123456).',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: 'Family Link Code',
                    hintText: 'CB-XXXXXX',
                    prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (activeTab == 0) {
                        final email = emailController.text.trim();
                        if (email.isEmpty) return;

                        setDialogState(() => isProcessing = true);
                        try {
                          final res = await ApiService().inviteFamilyByEmail(email);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Invitation email dispatched successfully!'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: AppColors.emergency,
                              ),
                            );
                          }
                        }
                      } else {
                        final code = codeController.text.trim();
                        if (code.isEmpty) return;

                        setDialogState(() => isProcessing = true);
                        try {
                          final res = await ApiService().acceptFamilyEmailInvite(code);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Successfully linked account! Confirmation emails sent.'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: AppColors.emergency,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(activeTab == 0 ? 'Send Email Invite' : 'Link Account'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHomeTab(String userName) {
    final user = context.watch<AuthProvider>().user;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFade,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.75)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userName,
                                  style: AppTextStyles.displayMedium.copyWith(color: Colors.white, fontSize: 24),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _HeaderIconButton(
                                  icon: Icons.notifications_outlined,
                                  badge: true,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _HeaderIconButton(
                                  icon: Icons.person_outline_rounded,
                                  badge: false,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Active SOS Alerts
                        FutureBuilder<List<dynamic>>(
                          future: _sosFuture,
                          builder: (context, snapshot) {
                            final alerts = snapshot.data ?? [];
                            if (alerts.isEmpty) return const SizedBox.shrink();
                            
                            return Column(
                              children: alerts.map((alert) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.emergency,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.emergency.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sos_rounded, color: Colors.white, size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ACTIVE SOS ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 2),
                                          Text('Emergency triggered by parent.', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9))),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await ApiService().resolveSOS(alert['id']);
                                        _refresh();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.emergency,
                                      ),
                                      child: const Text('Resolve'),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: FutureBuilder<List<ParentProfile>>(
                future: _parentsFuture,
                builder: (_, snap) {
                  final parents = snap.data ?? [];
                  final pendingMeds = parents.fold<int>(0, (sum, p) => sum + p.medicinesToday.where((m) => m.status == 'pending').length);
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Parents',
                          value: '${parents.length}',
                          icon: Icons.elderly_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Medicines Pending',
                          value: '$pendingMeds',
                          icon: Icons.medication_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Alerts',
                          value: '1',
                          icon: Icons.notifications_active_rounded,
                          color: AppColors.emergency,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Papa's Daily Summary ("Peace of Mind" Card)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: FutureBuilder<List<ParentProfile>>(
                future: _parentsFuture,
                builder: (_, snap) {
                  final parents = snap.data ?? [];
                  final totalMeds = parents.fold<int>(0, (sum, p) => sum + p.medicinesToday.length);
                  final takenMeds = parents.fold<int>(0, (sum, p) => sum + p.medicinesToday.where((m) => m.status == 'taken').length);
                  final parentName = parents.isNotEmpty ? parents.first.name : "Papa";
                  return PapaDailySummaryCard(
                    parentName: parentName,
                    takenMeds: takenMeds,
                    totalMeds: totalMeds > 0 ? totalMeds : 2,
                    reportsCount: 0,
                    appointmentsCount: 0,
                    hasActiveEmergency: false,
                  );
                },
              ),
            ),
          ),

          // Section: Your Parents
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Parents', style: AppTextStyles.headlineMedium),
                  ElevatedButton.icon(
                    onPressed: () => _showConnectFamilyDialog(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Enter Family Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Parent cards
          FutureBuilder<List<ParentProfile>>(
            future: _parentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: List.generate(2, (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.emergency.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Failed to load parents. Pull to refresh.', style: TextStyle(color: AppColors.emergency)),
                    ),
                  ),
                );
              }
              final parents = snapshot.data ?? [];
              if (parents.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _EmptyState(),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: _ParentCard(
                      parent: parents[index],
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ParentDetailScreen(parent: parents[index])),
                        );
                        _refresh();
                      },
                    ),
                  ),
                  childCount: parents.length,
                ),
              );
            },
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _QuickAction(icon: Icons.psychology_rounded, label: 'AI Chat', color: AppColors.info, onTap: () => setState(() => _currentIndex = 2))),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.receipt_long_rounded, label: 'Expenses', color: AppColors.accent, onTap: () => setState(() => _currentIndex = 3))),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.monitor_heart_outlined, label: 'Vitals', color: AppColors.bpColor, onTap: () => setState(() => _currentIndex = 1))),
                      const SizedBox(width: 10),
                      Expanded(child: _QuickAction(icon: Icons.file_present_rounded, label: 'Reports', color: AppColors.success, onTap: () {
                        if (user != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ParentReportsScreen(user: user)));
                        }
                      })),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.name.split(' ').first ?? '';

    final screens = [
      _buildHomeTab(userName),
      const ChildHealthMonitorScreen(),
      const ChildAiChatScreen(),
      const ChildExpenseScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_outlined), label: 'Health'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }
              },
              backgroundColor: AppColors.textSecondary.withOpacity(0.2),
              foregroundColor: AppColors.textSecondary,
              mini: true,
              elevation: 0,
              child: const Icon(Icons.logout_rounded, size: 20),
            )
          : null,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.family_restroom_rounded, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('No Parents Linked', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Ask your parent to register with your email as their linked child.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  final ParentProfile parent;
  final VoidCallback onTap;

  const _ParentCard({required this.parent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pendingCount = parent.medicinesToday.where((m) => m.status == 'pending').length;
    final takenCount = parent.medicinesToday.where((m) => m.status == 'taken').length;
    final total = parent.medicinesToday.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      parent.name.isNotEmpty ? parent.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parent.name, style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        parent.age != null ? 'Age ${parent.age} • ${parent.bloodGroup ?? "N/A"}' : parent.email,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Active', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.medication_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Medicines today', style: AppTextStyles.caption),
                            Text('$takenCount/$total taken', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? takenCount / total : 0,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.medication_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(parent.medicineSummary.isNotEmpty ? parent.medicineSummary : 'No medicines today', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('View details', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
