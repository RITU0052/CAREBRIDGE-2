import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/web_header.dart';
import '../services/api_service.dart';
import '../models/service_model.dart';
import 'doctors/find_doctor_screen.dart';
import 'auth/register_screen.dart';

class LandingPageScreen extends StatefulWidget {
  final bool scrollToServices;
  const LandingPageScreen({super.key, this.scrollToServices = false});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _servicesKey = GlobalKey();

  List<HealthcareServiceModel> _services = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadServices();

    if (widget.scrollToServices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToServices();
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      final data = await ApiService().getServices();
      setState(() {
        _services = data.map((json) => HealthcareServiceModel.fromJson(json)).toList();
        _isLoadingServices = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  void _scrollToServices() {
    final context = _servicesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: const WebHeader(activeRoute: 'Home'),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // HERO SECTION
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: isDesktop ? 64.0 : 36.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isDesktop
                      ? Row(
                          children: [
                            Expanded(child: _buildHeroLeftContent(context, isDesktop)),
                            const SizedBox(width: 48),
                            Expanded(child: _buildHeroVisualCard(context)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildHeroLeftContent(context, isDesktop),
                            const SizedBox(height: 36),
                            _buildHeroVisualCard(context),
                          ],
                        ),
                ),
              ),
            ),

            // TRUST INDICATORS SECTION
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 48.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text(
                        'TRUSTED HEALTHCARE & ELDERCARE PLATFORM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Designed for Safety, Clarity, and Peace of Mind',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: isDesktop ? 28 : 22,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: const [
                          _TrustBadge(
                            icon: LucideIcons.shieldCheck,
                            title: 'Secure Healthcare',
                            subtitle: 'Protected patient data with strict server privacy controls',
                          ),
                          _TrustBadge(
                            icon: LucideIcons.userCheck,
                            title: 'Verified Professionals',
                            subtitle: 'Board-certified doctors and verified medical specialists',
                          ),
                          _TrustBadge(
                            icon: LucideIcons.calendarCheck,
                            title: 'Easy Management',
                            subtitle: 'Real-time slot availability and instant appointment booking',
                          ),
                          _TrustBadge(
                            icon: LucideIcons.heart,
                            title: 'Patient-Centered Care',
                            subtitle: 'Elderly-friendly interface and instant emergency alerts',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SERVICES SECTION
            Container(
              key: _servicesKey,
              width: double.infinity,
              color: AppColors.surfaceVariant.withValues(alpha: 0.4),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 64.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text(
                        'OUR HEALTHCARE SERVICES',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete Care Solutions for You & Your Family',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: isDesktop ? 28 : 22,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_isLoadingServices)
                        const Center(child: CircularProgressIndicator())
                      else
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: _services.map((service) {
                            return _ServiceCard(
                              service: service,
                              isDesktop: isDesktop,
                              onTap: () {
                                if (service.name.contains('Doctor') || service.name.contains('Booking')) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Service: ${service.name} is fully active!')),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // CALL TO ACTION FOOTER BANNER
            Container(
              width: double.infinity,
              color: AppColors.primaryDark,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80.0 : 24.0,
                vertical: 56.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        'Start Managing Your Family Health Today',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 30 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect with certified doctors, keep track of daily medicines, and ensure peace of mind for elderly parents.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Create Free Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildHeroLeftContent(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(LucideIcons.sparkles, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'CareBridge Platform v2.0',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your Health.\nConnected. Simplified.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 46 : 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CareBridge bridges the gap between elderly parents and family caregivers. Discover top medical specialists, book appointments with real available slots, monitor vital signs, and receive instant emergency alerts.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                );
              },
              icon: const Icon(LucideIcons.search, size: 18),
              label: const Text('Find a Doctor'),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: _scrollToServices,
              icon: const Icon(LucideIcons.grid, size: 18),
              label: const Text('Explore Services'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisualCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.medium,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Icon(LucideIcons.userCheck, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Dr. Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Cardiology Specialist • 14 Yrs Exp', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('Next Available Consultation Slots:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: const [
              _HeroSlotBadge(time: '09:00 AM', isSelected: false),
              SizedBox(width: 8),
              _HeroSlotBadge(time: '10:30 AM', isSelected: true),
              SizedBox(width: 8),
              _HeroSlotBadge(time: '02:00 PM', isSelected: false),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                );
              },
              child: const Text('Book Appointment Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlotBadge extends StatelessWidget {
  final String time;
  final bool isSelected;
  const _HeroSlotBadge({required this.time, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final HealthcareServiceModel service;
  final bool isDesktop;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isDesktop,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'stethoscope':
        return LucideIcons.stethoscope;
      case 'calendar':
        return LucideIcons.calendar;
      case 'video':
        return LucideIcons.video;
      case 'file-text':
        return LucideIcons.fileText;
      case 'pill':
        return LucideIcons.pill;
      case 'shield-alert':
        return LucideIcons.shieldAlert;
      default:
        return LucideIcons.activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDesktop ? 350 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getIconData(service.icon), color: AppColors.primary, size: 26),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.category,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(service.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Learn More', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(width: 6),
                Icon(LucideIcons.arrowRight, color: AppColors.primary, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
