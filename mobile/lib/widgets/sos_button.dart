import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:carebridge_ai/theme/app_theme.dart';
import 'package:carebridge_ai/services/api_service.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSOS() async {
    try {
      await _apiService.triggerSOS(lat: '0.0', lng: '0.0');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.emergencyLight,
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 36),
                SizedBox(width: 12),
                Text(
                  'SOS Alert Sent!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergency,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your emergency alert has been sent to your caregiver and emergency contacts. Stay calm, help is on the way.',
              style: TextStyle(fontSize: 18, height: 1.4, color: AppColors.textPrimary),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK, I Understand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _progressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (_progressController.value < 1.0) {
          _progressController.reverse();
        } else {
          _triggerSOS();
          _progressController.reset();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _progressController.reverse();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing visual glow ring
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergency.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Circular progress track during press hold
                SizedBox(
                  width: 144,
                  height: 144,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: 9,
                        color: Colors.white,
                        backgroundColor: AppColors.emergency.withValues(alpha: 0.3),
                      );
                    },
                  ),
                ),
                // Inner primary SOS Button
                Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.alertTriangle, color: Colors.white, size: 38),
                      SizedBox(height: 2),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'HOLD 1.5s',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emergencyLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: AppColors.emergency),
                SizedBox(width: 6),
                Text(
                  'Press & Hold for Emergency',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emergency,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

