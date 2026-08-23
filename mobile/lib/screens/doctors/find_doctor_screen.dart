import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/web_header.dart';
import '../../services/api_service.dart';
import '../../models/doctor.dart';
import 'doctor_profile_screen.dart';
import '../appointments/booking_modal.dart';

class FindDoctorScreen extends StatefulWidget {
  final String? initialSpecialty;
  const FindDoctorScreen({super.key, this.initialSpecialty});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;

  String _selectedSpecialty = 'All';
  String _selectedConsultationType = 'All';
  String _selectedSort = 'rating';

  final List<String> _specialties = [
    'All',
    'General Physician',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Dermatology'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSpecialty != null) {
      _selectedSpecialty = widget.initialSpecialty!;
    }
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService().getDoctors(
        search: _searchController.text.trim(),
        specialty: _selectedSpecialty,
        consultationType: _selectedConsultationType == 'All' ? null : _selectedConsultationType,
        sortBy: _selectedSort,
      );
      setState(() {
        _doctors = results.map((json) => DoctorModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: const WebHeader(activeRoute: 'Find Doctors'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SEARCH & HEADER BANNER
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Certified Medical Specialists',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Book in-clinic or virtual video consultations with verified doctors in your area.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Search Bar Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _fetchDoctors(),
                              decoration: InputDecoration(
                                hintText: 'Search by doctor name, specialty, or location...',
                                prefixIcon: const Icon(LucideIcons.search, color: AppColors.primary),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(LucideIcons.x, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _fetchDoctors();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onPressed: _fetchDoctors,
                            icon: const Icon(LucideIcons.search, size: 18),
                            label: const Text('Search'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Consultation Type Segment Filter
                      Row(
                        children: [
                          const Text('Consultation Mode: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('All Modes'),
                            selected: _selectedConsultationType == 'All',
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedConsultationType = 'All');
                                _fetchDoctors();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const Icon(LucideIcons.building, size: 14),
                            label: const Text('In-Person (Physical Clinic)'),
                            selected: _selectedConsultationType == 'In-person',
                            selectedColor: Colors.blue.shade100,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedConsultationType = 'In-person');
                                _fetchDoctors();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const Icon(LucideIcons.video, size: 14),
                            label: const Text('Virtual Consultation (Online)'),
                            selected: _selectedConsultationType == 'Virtual',
                            selectedColor: Colors.purple.shade100,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _selectedConsultationType = 'Virtual');
                                _fetchDoctors();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Specialty Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _specialties.map((spec) {
                            final isSelected = _selectedSpecialty == spec;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(spec),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSpecialty = spec;
                                  });
                                  _fetchDoctors();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // RESULTS SECTION
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 40.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // Sort & Result Count Bar
                      Row(
                        children: [
                          Text(
                            'Showing ${_doctors.length} Doctors',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          const Text('Sort by: ', style: TextStyle(color: AppColors.textSecondary)),
                          DropdownButton<String>(
                            value: _selectedSort,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
                              DropdownMenuItem(value: 'experience', child: Text('Most Experienced')),
                              DropdownMenuItem(value: 'fee', child: Text('Consultation Fee (Low to High)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSort = val);
                                _fetchDoctors();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(60.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (_doctors.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(48.0),
                          alignment: Alignment.center,
                          child: Column(
                            children: const [
                              Icon(LucideIcons.userX, size: 64, color: AppColors.textTertiary),
                              SizedBox(height: 16),
                              Text('No Doctors Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Try clearing your search terms or selecting a different specialty filter.', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 2 : 1,
                            childAspectRatio: isDesktop ? 1.6 : 1.35,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: _doctors.length,
                          itemBuilder: (context, index) {
                            final doc = _doctors[index];
                            return _DoctorCard(doctor: doc);
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

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: doctor.profileImage != null && doctor.profileImage!.startsWith('http')
                    ? Image.network(
                        doctor.profileImage!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (doctor.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doctor.qualifications} • ${doctor.experienceYears} Years Exp',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text('${doctor.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(' (${doctor.reviewCount} reviews)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              const Icon(LucideIcons.mapPin, color: AppColors.textTertiary, size: 14),
              const SizedBox(width: 4),
              Text(doctor.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${doctor.consultationFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: doctor.id)),
                  );
                },
                child: const Text('View Profile'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BookingModal(doctor: doctor),
                  );
                },
                child: const Text('Book Slot'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.primary.withOpacity(0.12),
      child: const Icon(LucideIcons.user, color: AppColors.primary, size: 36),
    );
  }
}
