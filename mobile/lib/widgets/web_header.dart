import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/doctors/find_doctor_screen.dart';
import '../screens/appointments/my_appointments_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/parent/parent_home_screen.dart';
import '../screens/child/child_home_screen.dart';
import '../screens/doctors/doctor_dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/landing_page_screen.dart';

class WebHeader extends StatelessWidget implements PreferredSizeWidget {
  final String activeRoute;
  const WebHeader({super.key, this.activeRoute = 'Home'});

  @override
  Size get preferredSize => const Size.fromHeight(72.0);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        boxShadow: AppShadows.soft,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              // Logo & Brand
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPageScreen()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.heartPulse, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'CareBridge AI',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Desktop Navigation Links
              if (isDesktop) ...[
                _NavLink(
                  label: 'Home',
                  isActive: activeRoute == 'Home',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPageScreen()),
                  ),
                ),
                const SizedBox(width: 20),
                _NavLink(
                  label: 'Find Doctors',
                  isActive: activeRoute == 'Find Doctors',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FindDoctorScreen()),
                  ),
                ),
                const SizedBox(width: 20),
                _NavLink(
                  label: 'Services',
                  isActive: activeRoute == 'Services',
                  onTap: () => _scrollToServices(context),
                ),
                const SizedBox(width: 20),
                if (auth.isLoggedIn) ...[
                  _NavLink(
                    label: 'Appointments',
                    isActive: activeRoute == 'Appointments',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                _NavLink(
                  label: 'About',
                  isActive: activeRoute == 'About',
                  onTap: () => _showAboutModal(context),
                ),
                const SizedBox(width: 20),
                _NavLink(
                  label: 'Contact',
                  isActive: activeRoute == 'Contact',
                  onTap: () => _showContactModal(context),
                ),
                const SizedBox(width: 28),
              ],

              // User Actions / Auth Buttons
              if (auth.isLoggedIn && user != null) ...[
                if (user.isAdmin) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                    icon: const Icon(LucideIcons.shieldCheck, size: 16),
                    label: const Text('Admin Area'),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    final role = user.role.toLowerCase();
                    if (role == 'parent') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
                    } else if (role == 'child') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildHomeScreen()));
                    } else if (role == 'doctor') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()));
                    } else if (role == 'admin') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    }
                  },
                  icon: const Icon(LucideIcons.layoutDashboard, size: 16),
                  label: Text('Dashboard (${user.role.toUpperCase()})'),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Profile',
                  icon: const Icon(LucideIcons.user, color: AppColors.primary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(LucideIcons.logOut, color: AppColors.textSecondary),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LandingPageScreen()),
                      );
                    }
                  },
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Log In'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Sign Up'),
                ),
              ],

              // Mobile Hamburger Trigger
              if (!isDesktop) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(LucideIcons.menu, color: AppColors.textPrimary),
                  onPressed: () => _openMobileMenu(context, auth),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToServices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LandingPageScreen(scrollToServices: true)),
    );
  }

  void _showAboutModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.heartPulse, color: AppColors.primary),
            SizedBox(width: 10),
            Text('About CareBridge AI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'CareBridge AI is a next-generation healthcare platform dedicated to bridging distance in eldercare.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              '• Professional doctor discovery & instant booking\n'
              '• Real-time family medication tracking\n'
              '• Vital health metrics monitoring\n'
              '• One-touch emergency SOS alerts',
              style: TextStyle(height: 1.6, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  void _showContactModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.phoneCall, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Contact CareBridge Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('We are available 24/7 to assist with your medical care management.'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.mail, color: AppColors.primary),
              title: Text('Email'),
              subtitle: Text('carebridge.notifications@gmail.com'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(LucideIcons.phone, color: AppColors.primary),
              title: Text('Contact Number'),
              subtitle: Text('7042363267'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  void _openMobileMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPageScreen()));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.search),
              title: const Text('Find Doctors'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FindDoctorScreen()));
              },
            ),
            if (auth.isLoggedIn)
              ListTile(
                leading: const Icon(LucideIcons.calendar),
                title: const Text('My Appointments'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                _showAboutModal(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.phone),
              title: const Text('Contact'),
              onTap: () {
                Navigator.pop(context);
                _showContactModal(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
