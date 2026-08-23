import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/web_header.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../models/appointment.dart';
import '../doctors/find_doctor_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService().getMyAppointments();
      setState(() {
        _appointments = results.map((json) => AppointmentModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this scheduled consultation? The time slot will be released.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Appointment')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergency),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().cancelAppointment(appointmentId);
        _fetchAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  // ── Reschedule Appointment Modal ──────────────────────────────────────────
  Future<void> _rescheduleAppointmentModal(AppointmentModel app) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTimeSlot = "10:00 AM";
    final availableSlots = [
      "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
      "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM", "04:00 PM", "04:30 PM"
    ];
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Reschedule with ${app.doctorName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Schedule: ${app.appointmentDate} at ${app.timeSlot}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 14),

              const Text('Select New Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, "0")}-${selectedDate.day.toString().padLeft(2, "0")}'),
              ),
              const SizedBox(height: 14),

              const Text('Select New Time Slot:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedTimeSlot,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: availableSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedTimeSlot = val!),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for rescheduling (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Reschedule'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, "0")}-${selectedDate.day.toString().padLeft(2, "0")}';
      try {
        await ApiService().rescheduleAppointment(
          appointmentId: app.id,
          newDate: dateStr,
          newTimeSlot: selectedTimeSlot,
          reason: reasonController.text.trim(),
        );
        _fetchAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Appointment rescheduled. Patient requested appointment to $dateStr at $selectedTimeSlot.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reschedule failed: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: AppColors.emergency),
          );
        }
      }
    }
  }

  // ── Appointment Reminder Modal ───────────────────────────────────────────
  void _showReminderModal(AppointmentModel app) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alarm, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text('Set Appointment Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Appointment with ${app.doctorName} on ${app.appointmentDate} at ${app.timeSlot}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('30 Minutes Before'),
              onTap: () => _saveReminder(app.id, 30),
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('1 Hour Before'),
              onTap: () => _saveReminder(app.id, 60),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('2 Hours Before'),
              onTap: () => _saveReminder(app.id, 120),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder(String app_id, int mins) async {
    Navigator.pop(context);
    try {
      await ApiService().setAppointmentReminder(appointmentId: app_id, minutesBefore: mins);
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Reminder set for $mins minutes before appointment!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting reminder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final filteredAppointments = _appointments.where((app) {
      if (_activeFilter == 'Scheduled') return app.isScheduled;
      if (_activeFilter == 'Completed') return app.isCompleted;
      if (_activeFilter == 'Cancelled') return app.isCancelled;
      return true;
    }).toList();

    return Scaffold(
      appBar: const WebHeader(activeRoute: 'Appointments'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surfaceVariant,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 36.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Appointments',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage upcoming consultations, reschedule, set reminders, or join virtual calls.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                          );
                        },
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Book New Consultation'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 36.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: ['All', 'Scheduled', 'Completed', 'Cancelled'].map((tab) {
                          final isSelected = _activeFilter == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(tab),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              onSelected: (_) => setState(() => _activeFilter = tab),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(60.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        )
                      else if (filteredAppointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(48.0),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(LucideIcons.calendarX, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 16),
                              const Text('No Appointments Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('You have no consultations matching this filter status.', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Find a Doctor & Book'),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAppointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final app = filteredAppointments[index];
                            return _AppointmentCard(
                              appointment: app,
                              onCancel: () => _cancelAppointment(app.id),
                              onReschedule: () => _rescheduleAppointmentModal(app),
                              onReminder: () => _showReminderModal(app),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onReminder;

  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
    required this.onReschedule,
    required this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    StatusBadgeType badgeType = StatusBadgeType.info;

    if (appointment.isRescheduled) {
      badgeType = StatusBadgeType.warning;
    } else if (appointment.isScheduled) {
      badgeType = StatusBadgeType.upcoming;
    } else if (appointment.isCompleted) {
      badgeType = StatusBadgeType.success;
    } else if (appointment.isCancelled) {
      badgeType = StatusBadgeType.highAlert;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F7)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: appointment.doctorImage != null && appointment.doctorImage!.startsWith('http')
                    ? Image.network(appointment.doctorImage!, width: 52, height: 52, fit: BoxFit.cover)
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.user, color: AppColors.primary),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.doctorName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${appointment.doctorSpecialty} • ${appointment.appointmentType}', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              StatusBadge(
                label: appointment.status.toUpperCase(),
                type: badgeType,
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0F1F7)),

          if (appointment.isRescheduled && appointment.previousDateTime != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10)),
              child: Text(
                '🔄 Rescheduled from ${appointment.previousDateTime}',
                style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Date: ${appointment.appointmentDate}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Slot: ${appointment.timeSlot}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.user, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Patient: ${appointment.patientName}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          if (appointment.patientNotes != null && appointment.patientNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes: ${appointment.patientNotes}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
              Text('Fee: \$${appointment.fee.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              const Spacer(),
              if (appointment.isScheduled) ...[
                IconButton(
                  tooltip: 'Set Reminder',
                  icon: const Icon(Icons.alarm_rounded, color: AppColors.primary),
                  onPressed: onReminder,
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: onReschedule,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: Text('Reschedule', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                if (appointment.isVirtual && appointment.virtualLink != null) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(appointment.virtualLink!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.video_call, size: 18),
                    label: Text('Join Virtual', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onCancel,
                  icon: const Icon(LucideIcons.xCircle, size: 16),
                  label: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
