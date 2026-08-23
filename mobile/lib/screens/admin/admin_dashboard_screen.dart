import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeNavIndex = 0; // 0: Dashboard, 1: Patients, 2: Parents, 3: Doctors, 4: Appointments, 5: Medicines
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  // Data lists
  List<AppUser> _allUsers = [];
  List<dynamic> _doctors = [];
  bool _isLoadingData = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoadingStats = true);
    try {
      final statsRes = await ApiService().adminGetStats();
      final usersRes = await ApiService().adminGetUsers(search: _searchQuery);
      final docsRes = await ApiService().getDoctors(includePending: true);

      setState(() {
        _stats = statsRes;
        _allUsers = usersRes.map((json) => AppUser.fromJson(json)).toList();
        _doctors = docsRes;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  void _showAddUserModal(String defaultRole) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController(text: 'Password123');
    final phoneCtrl = TextEditingController();
    String selectedRole = defaultRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add New ${selectedRole.capitalize()} Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(LucideIcons.user),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Initial Password *',
                    prefixIcon: Icon(LucideIcons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Account Role'),
                  items: const [
                    DropdownMenuItem(value: 'parent', child: Text('Parent / Guardian')),
                    DropdownMenuItem(value: 'child', child: Text('Child (Patient)')),
                    DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || pwdCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter name, email and password.')),
                  );
                  return;
                }
                try {
                  await ApiService().adminCreateUser(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: pwdCtrl.text,
                    role: selectedRole,
                    phone: phoneCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _loadAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New ${selectedRole.capitalize()} account created successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${user.role.capitalize()} Account'),
        content: Text('Are you sure you want to delete "${user.name}" (${user.email})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService().adminDeleteUser(user.id);
                Navigator.pop(ctx);
                _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account for "${user.name}" deleted.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleDoctorVerification(String doctorId, String currentStatus) async {
    final newStatus = (currentStatus == 'verified') ? 'pending' : 'verified';
    try {
      await ApiService().adminVerifyDoctor(doctorId, newStatus);
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doctor verification status updated to: ${newStatus.toUpperCase()}'),
          backgroundColor: newStatus == 'verified' ? AppTheme.success : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final parents = _allUsers.where((u) => u.role == 'parent').toList();
    final children = _allUsers.where((u) => u.role == 'child').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: isMobile ? _buildSidebar() : null,
      appBar: isMobile
          ? AppBar(
              title: const Text('CareBridge Admin'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Admin Header Bar
                  _buildTopAdminHeader(),
                  const SizedBox(height: 24),

                  if (_activeNavIndex == 0) ...[
                    // Stat Cards Grid
                    _buildStatCardsGrid(),
                    const SizedBox(height: 24),

                    // Charts Row (Patient Trends & Medicine Stock)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildPatientTrendChartCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildMedicineStockChartCard()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Appointments & Emergency Alerts Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRecentAppointmentsCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildEmergencyAlertsCard()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Reports & Activity Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRecentReportsCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildRecentActivityCard()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Footer
                    _buildQuickActionsBar(),
                  ] else if (_activeNavIndex == 1) ...[
                    // PATIENTS (CHILDREN) MANAGEMENT
                    _buildUserManagementTable('Children / Patients', children, 'child'),
                  ] else if (_activeNavIndex == 2) ...[
                    // PARENTS MANAGEMENT
                    _buildUserManagementTable('Parents & Guardians', parents, 'parent'),
                  ] else if (_activeNavIndex == 3) ...[
                    // DOCTORS VERIFICATION & MANAGEMENT
                    _buildDoctorsManagementTable(),
                  ] else if (_activeNavIndex == 4) ...[
                    // APPOINTMENTS MANAGEMENT
                    _buildRecentAppointmentsCard(),
                  ] else if (_activeNavIndex == 5) ...[
                    // MEDICINE MANAGEMENT
                    _buildMedicineStockChartCard(),
                  ] else if (_activeNavIndex == 6) ...[
                    // REPORTS MANAGEMENT
                    _buildRecentReportsCard(),
                  ] else if (_activeNavIndex == 7) ...[
                    // EMERGENCY ALERTS
                    _buildEmergencyAlertsCard(),
                  ] else ...[
                    // DEFAULT DASHBOARD VIEW
                    _buildStatCardsGrid(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.heartPulse, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CareBridge AI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    Text('Admin Panel', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F7)),
          const SizedBox(height: 16),
          _sidebarItem(0, 'Dashboard', LucideIcons.layoutDashboard),
          _sidebarItem(1, 'Patients', LucideIcons.users),
          _sidebarItem(2, 'Parents / Guardians', LucideIcons.heart),
          _sidebarItem(3, 'Doctors', LucideIcons.stethoscope),
          _sidebarItem(4, 'Appointments', LucideIcons.calendar),
          _sidebarItem(5, 'Medicine Management', LucideIcons.pill),
          _sidebarItem(6, 'Reports Management', LucideIcons.fileText),
          _sidebarItem(7, 'Emergency Contacts', LucideIcons.shieldAlert),
          const Spacer(),
          // System status badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Systems Operational', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                      Text('Uptime: 99.9%', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F7)),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
            title: Text('Log Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon) {
    final isActive = _activeNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        gradient: isActive ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]) : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                const BoxShadow(
                  color: Color(0x256366F1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: isActive ? Colors.white : AppColors.textSecondary, size: 18),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () => setState(() => _activeNavIndex = index),
      ),
    );
  }

  Widget _buildTopAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                'Welcome back, Admin!',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Search input field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search patients, reports, doctors...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('20 May 2025', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell icon with unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(LucideIcons.bell, size: 18, color: AppColors.textPrimary),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          // User avatar profile info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin User', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Super Admin • Online', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1000 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _statCard('Total Patients', '${_stats?['total_children'] ?? 1248}', '+12.5%', LucideIcons.users, const Color(0xFF6366F1)),
            _statCard('Parents / Guardians', '${_stats?['total_parents'] ?? 986}', '+8.3%', LucideIcons.heart, const Color(0xFF8B5CF6)),
            _statCard('Total Appointments', '${_stats?['total_appointments'] ?? 342}', '+15.7%', LucideIcons.calendar, const Color(0xFF10B981)),
            _statCard('Medicines Stock', '256', '+5.2%', LucideIcons.pill, const Color(0xFFF59E0B)),
            _statCard('Emergency Alerts', '${_stats?['active_sos'] ?? 8}', '-20.0%', LucideIcons.shieldAlert, const Color(0xFFEF4444)),
            _statCard('Reports Uploaded', '${_stats?['total_reports'] ?? 1732}', '+18.9%', LucideIcons.fileText, const Color(0xFF3B82F6)),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, String trend, IconData icon, Color color) {
    final isPositive = !trend.startsWith('-');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                      size: 12,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Patients Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text('This Month', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 0:
                            return Text('1 May', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                          case 1:
                            return Text('6 May', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                          case 2:
                            return Text('11 May', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                          case 3:
                            return Text('16 May', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                          case 4:
                            return Text('20 May', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 300),
                      FlSpot(1, 580),
                      FlSpot(2, 620),
                      FlSpot(3, 890),
                      FlSpot(4, 1248),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildMedicineStockChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Medicine Stock Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Text('View All', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: const Color(0xFF10B981), value: 156, title: '61%', radius: 28, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  PieChartSectionData(color: const Color(0xFFF59E0B), value: 68, title: '27%', radius: 28, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  PieChartSectionData(color: const Color(0xFFEF4444), value: 32, title: '12%', radius: 28, titleStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _legendDot('In Stock', Color(0xFF10B981), '156'),
              _legendDot('Low Stock', Color(0xFFF59E0B), '68'),
              _legendDot('Out of Stock', Color(0xFFEF4444), '32'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAppointmentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Text('View All', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _appointmentRow('Aarav Sharma', 'Dr. Rajeev Verma', '20 May 2025', '11:00 AM', 'Upcoming'),
          _appointmentRow('Diya Patel', 'Dr. Neha Sharma', '20 May 2025', '02:30 PM', 'Upcoming'),
          _appointmentRow('Vivaan Mehta', 'Dr. Rajeev Verma', '21 May 2025', '10:30 AM', 'Upcoming'),
          _appointmentRow('Ananya Gupta', 'Dr. Pooja Singh', '21 May 2025', '03:00 PM', 'Confirmed'),
        ],
      ),
    );
  }

  Widget _appointmentRow(String patient, String doctor, String date, String time, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(patient[0], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                Text('$doctor • $date ($time)', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          StatusBadge.fromStatus(status),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Emergency Alerts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFFEF4444))),
              const Spacer(),
              Text('View All', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _alertItem('High Fever Detected', 'Aarav Sharma • 20 May 2025, 10:20 AM'),
          _alertItem('Medicine Missed', 'Diya Patel • 20 May 2025, 09:15 AM'),
          _alertItem('Low Oxygen Level', 'Vivaan Mehta • 20 May 2025, 08:40 AM'),
        ],
      ),
    );
  }

  Widget _alertItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.bell, color: Color(0xFFEF4444), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFDC2626), fontSize: 13)),
                Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 11)),
              ],
            ),
          ),
          const StatusBadge(label: 'High', type: StatusBadgeType.highAlert),
        ],
      ),
    );
  }

  Widget _buildRecentReportsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Reports', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Text('View All', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text('Report Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('Patient', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('Action', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary))),
                ],
              ),
              _reportTableRow('Blood Test Report', 'Aarav Sharma', '20 May 2025'),
              _reportTableRow('X-Ray Chest', 'Diya Patel', '20 May 2025'),
              _reportTableRow('MRI Brain', 'Vivaan Mehta', '19 May 2025'),
              _reportTableRow('ECG Report', 'Ananya Gupta', '19 May 2025'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _reportTableRow(String name, String patient, String date) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              const Icon(LucideIcons.fileText, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(6), child: Text(patient, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
        Padding(padding: const EdgeInsets.all(6), child: Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary))),
        Padding(
          padding: const EdgeInsets.all(6),
          child: IconButton(
            icon: const Icon(LucideIcons.download, size: 15, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $name...')));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Activity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              Text('View All', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _activityItem('New patient Aarav Sharma registered', '20 May 2025, 10:15 AM', LucideIcons.userPlus),
          _activityItem('Report uploaded for Diya Patel', '20 May 2025, 09:45 AM', LucideIcons.filePlus),
          _activityItem('Appointment scheduled for Vivaan', '20 May 2025, 09:30 AM', LucideIcons.calendar),
          _activityItem('Medicine Paracetamol added', '20 May 2025, 09:10 AM', LucideIcons.pill),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
                onPressed: () => _showAddUserModal('child'),
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Add New Patient'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                ),
                onPressed: () {},
                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                label: const Text('Upload Report'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF10B981),
                  elevation: 0,
                ),
                onPressed: () {},
                icon: const Icon(LucideIcons.pill, size: 16),
                label: const Text('Add Medicine'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F3FF),
                  foregroundColor: const Color(0xFF7C3AED),
                  elevation: 0,
                ),
                onPressed: () => _showAddUserModal('doctor'),
                icon: const Icon(LucideIcons.stethoscope, size: 16),
                label: const Text('Add Doctor'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  foregroundColor: const Color(0xFFD97706),
                  elevation: 0,
                ),
                onPressed: () {},
                icon: const Icon(LucideIcons.bell, size: 16),
                label: const Text('Send Notification'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 1),
                icon: const Icon(LucideIcons.users, size: 16),
                label: const Text('View All Users'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTable(String title, List<AppUser> users, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddUserModal(role),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add ${role.capitalize()}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text('No accounts registered yet.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFF0F1F7)),
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(u.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  subtitle: Text('${u.email} • Phone: ${u.phone ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: u.role.toUpperCase(),
                        type: StatusBadgeType.info,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                        onPressed: () => _confirmDeleteUser(u),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorsManagementTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Doctors Verification & Management', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showAddUserModal('doctor'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add Doctor', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text('No doctor profiles found.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctors.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFF0F1F7)),
              itemBuilder: (context, index) {
                final doc = _doctors[index];
                final isVerified = doc['is_verified'] == true || doc['status'] == 'verified';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    child: Icon(LucideIcons.stethoscope, color: isVerified ? const Color(0xFF10B981) : const Color(0xFFD97706), size: 18),
                  ),
                  title: Text(doc['name'] ?? 'Doctor', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  subtitle: Text('${doc['specialty']} • Exp: ${doc['experience_years']} yrs', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: isVerified ? 'VERIFIED' : 'PENDING',
                        type: isVerified ? StatusBadgeType.confirmed : StatusBadgeType.warning,
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: isVerified,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          _toggleDoctorVerification(doc['id'], doc['status'] ?? 'pending');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _legendDot extends StatelessWidget {
  final String label;
  final Color color;
  final String count;

  const _legendDot(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ($count)', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
