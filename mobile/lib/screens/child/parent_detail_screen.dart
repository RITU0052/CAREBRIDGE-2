import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../models/parent_profile.dart';
import '../../models/health_vital.dart';
import '../../models/appointment.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/health_card.dart';
import '../../widgets/status_badge.dart';

class ParentDetailScreen extends StatefulWidget {
  final ParentProfile parent;
  const ParentDetailScreen({super.key, required this.parent});

  @override
  State<ParentDetailScreen> createState() => _ParentDetailScreenState();
}

class _ParentDetailScreenState extends State<ParentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Medicine>> _medicinesFuture;
  late Future<List<dynamic>> _reportsFuture;
  final List<HealthVital> _vitals = [];
  List<AppointmentModel> _appointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _medicinesFuture = _loadMedicines();
    _reportsFuture = _loadReports();
    _vitals.addAll(MockVitals.forParent(widget.parent.parentProfileId));
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final raw = await ApiService().getMyAppointments();
      if (mounted) {
        setState(() {
          _appointments = raw.map((a) => AppointmentModel.fromJson(a)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Medicine>> _loadMedicines() async {
    final raw = await ApiService().getMedicines(widget.parent.parentProfileId.toString());
    return raw.map((m) => Medicine.fromJson(m)).toList();
  }

  void _refresh() => setState(() => _medicinesFuture = _loadMedicines());

  Future<List<dynamic>> _loadReports() async {
    return await ApiService().getReports(widget.parent.parentProfileId.toString());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken': return AppColors.success;
      case 'skipped': return AppColors.emergency;
      default: return AppColors.warning;
    }
  }

  HealthStatus _toHealthStatus(String s) {
    if (s == 'warning') return HealthStatus.warning;
    if (s == 'critical') return HealthStatus.critical;
    return HealthStatus.normal;
  }

  Color _vitalColor(String type) {
    switch (type) {
      case 'bp': return AppColors.bpColor;
      case 'sugar': return AppColors.sugarColor;
      case 'heart_rate': return AppColors.heartColor;
      case 'oxygen': return AppColors.oxygenColor;
      case 'temperature': return AppColors.tempColor;
      default: return AppColors.weightColor;
    }
  }

  IconData _vitalIcon(String type) {
    switch (type) {
      case 'bp': return Icons.monitor_heart_rounded;
      case 'sugar': return Icons.water_drop_rounded;
      case 'heart_rate': return Icons.favorite_rounded;
      case 'oxygen': return Icons.air_rounded;
      case 'temperature': return Icons.thermostat_rounded;
      default: return Icons.scale_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.white24, Colors.white10]),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              widget.parent.name.isNotEmpty ? widget.parent.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.parent.name, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _InfoChip(text: 'Age ${widget.parent.age ?? "N/A"}'),
                                  const SizedBox(width: 8),
                                  _InfoChip(text: widget.parent.bloodGroup ?? 'Blood N/A'),
                                ],
                              ),
                              if (widget.parent.medicalHistory != null && widget.parent.medicalHistory!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.parent.medicalHistory!,
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Medicines'),
                Tab(text: 'Health'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMedicinesTab(),
            _buildHealthTab(),
            _buildReportsTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddMedicineDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Medicine'),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    final pendingMeds = widget.parent.medicinesToday.where((m) => m.status == 'pending').length;
    final takenMeds = widget.parent.medicinesToday.where((m) => m.status == 'taken').length;
    final total = widget.parent.medicinesToday.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health Status', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('92', style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 42)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('/100', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54)),
                          ),
                        ],
                      ),
                      Text('Vitals stable today', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(text: 'Stable', color: const Color(0xFF4ADE80)),
                    const SizedBox(height: 12),
                    Text('Last updated', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                    Text('Just now', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (total > 0) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Medicines Today', style: AppTextStyles.headlineSmall),
                      Text('$takenMeds/$total taken', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total > 0 ? takenMeds / total : 0,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 10,
                    ),
                  ),
                  if (pendingMeds > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.medication_rounded, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Text('$pendingMeds medicine(s) pending today', style: const TextStyle(color: AppColors.warning, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_appointments.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming Appointments', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                ..._appointments.take(2).map((a) => _AppointmentCard(appointment: a)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return FutureBuilder<List<Medicine>>(
      future: _medicinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final meds = snapshot.data ?? [];
        if (meds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication_outlined, size: 60, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('No medicines added yet', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Tap the + button to add medicines', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: meds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final med = meds[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.medicineName, style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 2),
                        Text('${med.dose ?? "N/A"} • ${med.timeOfDay ?? "N/A"}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(med.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      med.status.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor(med.status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHealthTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemCount: _vitals.length,
      itemBuilder: (_, i) {
        final v = _vitals[i];
        return HealthCard(
          label: v.label,
          value: v.value,
          unit: v.displayUnit,
          icon: _vitalIcon(v.type),
          color: _vitalColor(v.type),
          status: _toHealthStatus(v.status),
          trend: i % 2 == 0 ? '↓ 2%' : '↑ 5%',
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load reports'));
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return const Center(child: Text('No reports available for this parent.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final r = reports[i];
            final dateStr = r['upload_date'] ?? '';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.description_rounded, color: AppColors.info, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] ?? 'Untitled', style: AppTextStyles.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(dateStr, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8)),
                        child: Text((r['file_type'] ?? 'DOC').toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('${ApiConfig.baseUrl.replaceAll("/api", "")}${r['file_path']}');
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              await launchUrl(url, mode: LaunchMode.platformDefault);
                            }
                          } catch (_) {
                            await launchUrl(url);
                          }
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('View'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddMedicineDialog() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    String timeOfDay = 'Morning';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Medicine', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine name',
                    prefixIcon: Icon(Icons.medication_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose (e.g. 500mg)',
                    prefixIcon: Icon(Icons.scale_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: timeOfDay,
                  decoration: const InputDecoration(
                    labelText: 'Time of day',
                    prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.primary),
                  ),
                  items: ['Morning', 'Afternoon', 'Evening', 'Night']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => timeOfDay = v ?? 'Morning'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      try {
                        await ApiService().addMedicine(
                          name: nameController.text.trim(),
                          dose: doseController.text.trim(),
                          timeOfDay: timeOfDay,
                          parentId: widget.parent.parentProfileId.toString(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _refresh();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    child: const Text('Save Medicine'),
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

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.doctorName, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${appointment.appointmentDate} • ${appointment.timeSlot}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
