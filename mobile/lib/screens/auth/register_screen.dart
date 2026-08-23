import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:carebridge_ai/theme/app_theme.dart';
import 'package:carebridge_ai/screens/auth/login_screen.dart';
import 'package:carebridge_ai/services/api_service.dart';
import 'package:carebridge_ai/services/auth_provider.dart';
import 'package:carebridge_ai/screens/parent/parent_home_screen.dart';
import 'package:carebridge_ai/screens/child/child_home_screen.dart';
import 'package:carebridge_ai/screens/doctors/doctor_dashboard_screen.dart';

import 'package:carebridge_ai/screens/auth/email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'parent', 'child', 'doctor'

  const RegisterScreen({super.key, this.role = 'parent'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late String _selectedRole;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _childEmailController = TextEditingController();

  // Doctor specific fields
  final _specialtyController = TextEditingController(text: 'General Physician');
  final _qualificationsController = TextEditingController(text: 'MBBS, MD');
  final _experienceController = TextEditingController(text: '5');
  final _feeController = TextEditingController(text: '50.0');
  final _locationController = TextEditingController(text: 'CareBridge Clinic');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().register(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
        phone: _phoneController.text.trim(),
        childEmail: _selectedRole == 'parent' ? _childEmailController.text.trim() : null,
        specialty: _selectedRole == 'doctor' ? _specialtyController.text.trim() : null,
        qualifications: _selectedRole == 'doctor' ? _qualificationsController.text.trim() : null,
        experienceYears: _selectedRole == 'doctor' ? int.tryParse(_experienceController.text.trim()) : null,
        consultationFee: _selectedRole == 'doctor' ? double.tryParse(_feeController.text.trim()) : null,
        location: _selectedRole == 'doctor' ? _locationController.text.trim() : null,
      );

      final loginRes = await ApiService().login(email, password);

      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = loginRes['access_token'] as String;
        final userJson = loginRes['user'] ?? {
          'name': name,
          'email': email,
          'role': _selectedRole,
        };
        await authProvider.setSession(token, userJson);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Confirmation email & code sent to $email.'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to Email Verification Screen first, then to Dashboard
        void navigateToDashboard() {
          if (_selectedRole == 'parent') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ParentHomeScreen()),
              (route) => false,
            );
          } else if (_selectedRole == 'doctor') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ChildHomeScreen()),
              (route) => false,
            );
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              onVerified: navigateToDashboard,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRoleCard(String roleKey, String label, IconData icon, Color activeColor) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey.shade600, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to get started with CareBridge',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              // Role selector
              Row(
                children: [
                  _buildRoleCard('parent', 'Parent', LucideIcons.heart, const Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  _buildRoleCard('child', 'Child/Caregiver', LucideIcons.users, const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildRoleCard('doctor', 'Doctor', LucideIcons.stethoscope, const Color(0xFF0EA5E9)),
                ],
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(LucideIcons.user),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(LucideIcons.mail),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(LucideIcons.lock),
                ),
              ),

              if (_selectedRole == 'parent') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _childEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Child\'s Email (Optional link)',
                    prefixIcon: Icon(LucideIcons.link),
                  ),
                ),
              ],

              if (_selectedRole == 'doctor') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Specialty',
                    prefixIcon: Icon(LucideIcons.stethoscope),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qualificationsController,
                  decoration: const InputDecoration(
                    labelText: 'Qualifications & Degrees',
                    prefixIcon: Icon(LucideIcons.award),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Experience (Years)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _feeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fee (\$)'),
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Clinic / Hospital Location',
                    prefixIcon: Icon(LucideIcons.mapPin),
                  ),
                ),
              ],

              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Register as ${_selectedRole.toUpperCase()}'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(role: _selectedRole),
                        ),
                      );
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
