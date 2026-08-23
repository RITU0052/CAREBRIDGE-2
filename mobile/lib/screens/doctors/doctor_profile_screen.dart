import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/web_header.dart';
import '../../services/api_service.dart';
import '../../models/doctor.dart';
import '../appointments/booking_modal.dart';
import 'doctor_chat_screen.dart';


class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  DoctorModel? _doctor;
  List<dynamic> _reviews = [];
  List<String> _availableSlots = [];
  bool _isLoading = true;
  bool _isLoadingSlots = false;

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final docData = await ApiService().getDoctorById(widget.doctorId);
      final reviewsData = await ApiService().getDoctorReviews(widget.doctorId);
      setState(() {
        _doctor = DoctorModel.fromJson(docData);
        _reviews = reviewsData;
        _isLoading = false;
      });
      _fetchAvailableSlots(_selectedDate);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final slots = await ApiService().getAvailableSlots(widget.doctorId, dateStr);
      setState(() {
        _availableSlots = slots;
        _selectedSlot = slots.isNotEmpty ? slots.first : null;
        _isLoadingSlots = false;
      });
    } catch (_) {
      setState(() => _isLoadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (_isLoading) {
      return const Scaffold(
        appBar: WebHeader(activeRoute: 'Find Doctors'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        appBar: const WebHeader(activeRoute: 'Find Doctors'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Doctor details unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Doctors'),
              ),
            ],
          ),
        ),
      );
    }

    final doc = _doctor!;

    return Scaffold(
      appBar: const WebHeader(activeRoute: 'Find Doctors'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER PROFILE HERO
            Container(
              width: double.infinity,
              color: AppColors.surfaceVariant,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 40.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: doc.profileImage != null && doc.profileImage!.startsWith('http')
                            ? Image.network(doc.profileImage!, width: 120, height: 120, fit: BoxFit.cover)
                            : Container(
                                width: 120,
                                height: 120,
                                color: AppColors.primary.withOpacity(0.15),
                                child: const Icon(LucideIcons.user, size: 60, color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(doc.name, style: GoogleFonts.inter(fontSize: isDesktop ? 28 : 22, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                if (doc.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Verified Doctor', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(doc.specialty, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('${doc.qualifications} • ${doc.experienceYears} Years Experience', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(LucideIcons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text('${doc.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(' (${doc.reviewCount} Patient Reviews)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                const SizedBox(width: 20),
                                const Icon(LucideIcons.globe, color: AppColors.textTertiary, size: 16),
                                const SizedBox(width: 4),
                                Text(doc.languages, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorChatScreen(
                                          doctorName: doc.name,
                                          doctorSpecialty: doc.specialty,
                                          profileImage: doc.profileImage,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.messageSquare, size: 16),
                                  label: const Text('Chat with Doctor'),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // MAIN CONTENT BODY
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 40.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildDoctorLeftDetails(doc)),
                            const SizedBox(width: 32),
                            Expanded(flex: 2, child: _buildBookingWidget(doc)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildBookingWidget(doc),
                            const SizedBox(height: 32),
                            _buildDoctorLeftDetails(doc),
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

  Widget _buildDoctorLeftDetails(DoctorModel doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Biography
        const Text('About Doctor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          doc.bio.isNotEmpty
              ? doc.bio
              : 'Dr. ${doc.name} is a highly respected specialist dedicated to delivering personalized medical consultations and comprehensive patient care.',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 32),

        // Clinic & Practice Info
        const Text('Clinic & Consultation Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                title: const Text('Clinic Address'),
                subtitle: Text(doc.location),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.calendarDays, color: AppColors.primary),
                title: const Text('Available Practice Days'),
                subtitle: Text(doc.availableDays),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.dollarSign, color: AppColors.primary),
                title: const Text('Consultation Fee'),
                subtitle: Text('\$${doc.consultationFee.toStringAsFixed(0)} per session'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Patient Reviews
        Row(
          children: [
            const Text('Patient Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_reviews.length} Verified Reviews', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          const Text('No reviews yet. Be the first to consult and leave a review!', style: TextStyle(color: AppColors.textSecondary))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rev = _reviews[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(rev['user_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              LucideIcons.star,
                              size: 14,
                              color: i < (rev['rating'] ?? 5) ? Colors.amber : AppColors.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rev['comment'] ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBookingWidget(DoctorModel doc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Book Consultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('\$${doc.consultationFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 24),
          const Text('1. Select Date:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
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
                _fetchAvailableSlots(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.chevronDown, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('2. Select Available Time Slot:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),

          if (_isLoadingSlots)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_availableSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('No unbooked slots left for this date.', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.w500)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
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

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _availableSlots.isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (_) => BookingModal(
                          doctor: doc,
                          initialDate: _selectedDate,
                          initialSlot: _selectedSlot,
                        ),
                      );
                    },
              child: const Text('Proceed to Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
