import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../models/doctor.dart';
import 'my_appointments_screen.dart';

class BookingModal extends StatefulWidget {
  final DoctorModel doctor;
  final DateTime? initialDate;
  final String? initialSlot;

  const BookingModal({
    super.key,
    required this.doctor,
    this.initialDate,
    this.initialSlot,
  });

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  late DateTime _selectedDate;
  String? _selectedSlot;
  String _appointmentType = 'In-person';
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedSlot = widget.initialSlot;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      _nameController.text = auth.user!.name;
      _phoneController.text = auth.user!.phone ?? '';
    }

    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoadingSlots = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final slots = await ApiService().getAvailableSlots(widget.doctor.id, dateStr);
      setState(() {
        _availableSlots = slots;
        if (_selectedSlot == null || !_availableSlots.contains(_selectedSlot)) {
          _selectedSlot = _availableSlots.isNotEmpty ? _availableSlots.first : null;
        }
        _isLoadingSlots = false;
      });
    } catch (_) {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final result = await ApiService().bookAppointment(
        doctorId: widget.doctor.id,
        appointmentDate: dateStr,
        timeSlot: _selectedSlot!,
        appointmentType: _appointmentType,
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
        patientNotes: _notesController.text.trim(),
      );

      setState(() => _isSubmitting = false);
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 28),
                SizedBox(width: 10),
                Text('Appointment Booked!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your consultation with ${widget.doctor.name} has been confirmed.'),
                const SizedBox(height: 12),
                Text('📅 Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}'),
                Text('⏰ Time: $_selectedSlot'),
                Text('🩺 Type: $_appointmentType'),
                Text('👤 Patient: ${_nameController.text}'),
                Text('💵 Fee: \$${widget.doctor.consultationFee.toStringAsFixed(0)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('View My Appointments'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendarCheck, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    const Text('Confirm Appointment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(LucideIcons.user, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(widget.doctor.specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Text('\$${widget.doctor.consultationFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Appointment Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person, size: 16), SizedBox(width: 6), Text('In-person')]),
                        selected: _appointmentType == 'In-person',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _appointmentType == 'In-person' ? Colors.white : Colors.black87),
                        onSelected: (val) => setState(() => _appointmentType = 'In-person'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_call, size: 16), SizedBox(width: 6), Text('Virtual Call')]),
                        selected: _appointmentType == 'Virtual',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _appointmentType == 'Virtual' ? Colors.white : Colors.black87),
                        onSelected: (val) => setState(() => _appointmentType = 'Virtual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Appointment Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _fetchSlots();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(LucideIcons.chevronDown, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Available Time Slots (Backend Validated)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                if (_isLoadingSlots)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                else if (_availableSlots.isEmpty)
                  const Text('No open slots on this date. Please pick another date.', style: TextStyle(color: AppColors.emergency, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSlot = slot);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Patient Full Name *'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Reason for visit / Medical Notes (Optional)'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedSlot == null ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Book Appointment'),
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
