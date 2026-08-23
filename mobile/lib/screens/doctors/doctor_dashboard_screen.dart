import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../landing_page_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _doctorProfile;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    setState(() => _isLoading = true);
    try {
      final docProfile = await ApiService().getDoctorProfileMe();
      final appts = await ApiService().getDoctorScheduleMe();
      setState(() {
        _doctorProfile = docProfile;
        _appointments = appts;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPageScreen()),
        (route) => false,
      );
    }
  }

  void _editDoctorProfileDialog() {
    final qualificationsController = TextEditingController(text: _doctorProfile?['qualifications'] ?? 'MBBS, MD');
    final specialtyController = TextEditingController(text: _doctorProfile?['specialty'] ?? 'General Physician');
    final professionController = TextEditingController(text: _doctorProfile?['profession'] ?? 'Doctor');
    final phoneController = TextEditingController(text: _doctorProfile?['phone'] ?? '');
    final emailController = TextEditingController(text: _doctorProfile?['email'] ?? '');
    final locationController = TextEditingController(text: _doctorProfile?['location'] ?? 'Medical Center');
    final feeController = TextEditingController(text: (_doctorProfile?['consultation_fee'] ?? 50.0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Edit Doctor Profile'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qualificationsController, decoration: const InputDecoration(labelText: 'Qualifications (MBBS, MD...)')),
              const SizedBox(height: 10),
              TextField(controller: specialtyController, decoration: const InputDecoration(labelText: 'Specialization')),
              const SizedBox(height: 10),
              TextField(controller: professionController, decoration: const InputDecoration(labelText: 'Profession')),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Contact Phone')),
              const SizedBox(height: 10),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Contact Email')),
              const SizedBox(height: 10),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Clinic / Hospital Location')),
              const SizedBox(height: 10),
              TextField(controller: feeController, decoration: const InputDecoration(labelText: 'Consultation Fee (\$)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              try {
                await ApiService().updateDoctorProfileMe(
                  qualifications: qualificationsController.text.trim(),
                  specialty: specialtyController.text.trim(),
                  profession: professionController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  location: locationController.text.trim(),
                  fee: double.tryParse(feeController.text.trim()) ?? 50.0,
                );
                Navigator.pop(ctx);
                _fetchDoctorData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Profile updated successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final doctorName = _doctorProfile?['name'] ?? user?.name ?? 'Doctor';
    final isVerified = _doctorProfile?['is_verified'] ?? false;
    final statusStr = (_doctorProfile?['status'] ?? 'pending').toString().toUpperCase();

    final rescheduledAppts = _appointments.where((a) => a['status'] == 'rescheduled').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doctor Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _fetchDoctorData,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchDoctorData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Profile Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x256366F1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  doctorName.isNotEmpty ? doctorName[0] : 'D',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. $doctorName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_doctorProfile?['qualifications'] ?? 'MBBS, MD'} • ${_doctorProfile?['specialty'] ?? 'General Physician'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _editDoctorProfileDialog,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isVerified ? Colors.lightGreenAccent : Colors.amberAccent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified ? LucideIcons.checkCircle : LucideIcons.clock,
                                      color: isVerified ? Colors.lightGreenAccent : Colors.amberAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verification: $statusStr',
                                      style: TextStyle(
                                        color: isVerified ? Colors.lightGreenAccent : Colors.amberAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text('Fee: \$${_doctorProfile?['consultation_fee'] ?? 50}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rescheduled Notifications Banners
                    if (rescheduledAppts.isNotEmpty) ...[
                      const Text(
                        '🔔 Rescheduled Appointments Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const SizedBox(height: 10),
                      ...rescheduledAppts.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active_rounded, color: Colors.purple),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Appointment Rescheduled! Patient ${r['patient_name']} requested appointment to ${r['appointment_date']} at ${r['time_slot']}. Reason: ${r['reschedule_reason'] ?? "Patient request"}',
                                    style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Appointments Schedule (${_appointments.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_appointments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(LucideIcons.calendar, size: 40, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No appointments scheduled yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appt = _appointments[index];
                          final isVirtual = (appt['appointment_type'] ?? '').toString().toLowerCase() == 'virtual';
                          final isRescheduled = appt['status'] == 'rescheduled';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isRescheduled ? Colors.purple.shade300 : Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isVirtual ? const Color(0xFFE0F2FE) : AppColors.primary.withValues(alpha: 0.1),
                                      child: Icon(isVirtual ? Icons.video_call : LucideIcons.user, color: AppColors.primary),
                                    ),
                                    title: Text(
                                      '${appt['patient_name'] ?? 'Patient'} (${appt['appointment_type'] ?? 'In-person'})',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${appt['appointment_date']} at ${appt['time_slot']} • Phone: ${appt['patient_phone'] ?? "N/A"}',
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        (appt['status'] ?? 'Scheduled').toString().toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: isRescheduled
                                          ? Colors.purple
                                          : (appt['status'] == 'completed' ? Colors.green : AppColors.primary),
                                    ),
                                  ),
                                  if (isVirtual && appt['virtual_link'] != null) ...[
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final uri = Uri.parse(appt['virtual_link']);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.video_call_rounded, size: 18),
                                      label: const Text('Start Virtual Consultation Room'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
