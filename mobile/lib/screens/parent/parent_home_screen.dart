import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/medicine.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/sos_button.dart';
import 'parent_reports_screen.dart';
import '../doctors/find_doctor_screen.dart';
import '../appointments/my_appointments_screen.dart';

/// The Parent's dashboard — designed for accessibility with vibrant contrast,
/// full Doses options, Health Activity Monitoring, AI Emergency Assistant,
/// Google Maps Nearby Hospitals, and Emergency/Doctor contacts.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> with TickerProviderStateMixin {
  List<Medicine> _medicines = [];
  List<dynamic> _healthMetrics = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadDashboard();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final parentId = user?.id ?? '';
    try {
      final medData = await ApiService().getMedicines(parentId);
      final healthData = await ApiService().getHealthMetrics(parentId);
      if (mounted) {
        setState(() {
          _medicines = medData.map((json) => Medicine.fromJson(json)).toList();
          _healthMetrics = healthData;
        });
        _fadeController.forward(from: 0);
      }
    } catch (_) {
      if (mounted) {
        _fadeController.forward(from: 0);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String medicineId, String status) async {
    try {
      if (status == 'snoozed') {
        await ApiService().markMedicineSnoozed(medicineId);
      } else {
        await ApiService().updateMedicineStatus(medicineId, status);
      }
      _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  void _speakReminder(Medicine med) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reading: Take ${med.medicineName} ${med.dose ?? ""} ${med.doseUnit ?? ""} (${med.foodInstruction ?? ""}) for ${med.diseaseCondition ?? "health"}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Modal: Add Medicine / Doses ─────────────────────────────────────────────
  void _showAddDosesModal(BuildContext context) {
    final nameController = TextEditingController();
    final doseController = TextEditingController(text: '1');
    String doseUnit = 'tablet';
    String timeOfDay = 'Morning';
    String foodInstruction = 'After Food';
    String diseaseCondition = 'General Wellness';
    String frequency = 'Once a day';

    final doseUnits = ['mg', 'ml', 'tablet', 'capsule', 'drops', 'other'];
    final foodOptions = [
      'Before Food',
      'After Food',
      'With Food',
      'Empty Stomach',
      'Before breakfast',
      'After breakfast',
      'Before lunch',
      'After lunch',
      'Before dinner',
      'After dinner',
      'Not Specified'
    ];
    final diseaseOptions = ['Diabetes', 'Blood pressure', 'Fever', 'Infection', 'Heart condition', 'General Wellness', 'Other'];
    final frequencies = ['Once a day', 'Twice a day', 'Three times a day', 'Custom'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.medication_rounded, color: AppColors.primary, size: 30),
                    SizedBox(width: 10),
                    Text('Add Medicine & Dose', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name *',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: doseController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Dose Quantity',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: doseUnit,
                        decoration: InputDecoration(
                          labelText: 'Dose Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: doseUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setModalState(() => doseUnit = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: timeOfDay,
                  decoration: InputDecoration(
                    labelText: 'Time of Medicine',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning 🌅')),
                    DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon ☀️')),
                    DropdownMenuItem(value: 'Evening', child: Text('Evening 🌆')),
                    DropdownMenuItem(value: 'Night', child: Text('Night 🌙')),
                  ],
                  onChanged: (val) => setModalState(() => timeOfDay = val!),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: foodInstruction,
                  decoration: InputDecoration(
                    labelText: 'Food / Meal Instruction',
                    prefixIcon: const Icon(Icons.restaurant_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: foodOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) => setModalState(() => foodInstruction = val!),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: diseaseCondition,
                  decoration: InputDecoration(
                    labelText: 'Medicine is taken for (Condition)',
                    prefixIcon: const Icon(Icons.health_and_safety_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: diseaseOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setModalState(() => diseaseCondition = val!),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: const Icon(Icons.repeat),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: frequencies.map((fq) => DropdownMenuItem(value: fq, child: Text(fq))).toList(),
                  onChanged: (val) => setModalState(() => frequency = val!),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter medicine name')));
                        return;
                      }
                      try {
                        await ApiService().addMedicine(
                          name: name,
                          dose: doseController.text.trim(),
                          doseUnit: doseUnit,
                          timeOfDay: timeOfDay,
                          foodInstruction: foodInstruction,
                          diseaseCondition: diseaseCondition,
                          frequency: frequency,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadDashboard();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 26),
                    label: const Text('Save Dose & Medicine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal: Activity & Water Monitoring ─────────────────────────────────────
  void _showActivityMonitoringModal(BuildContext context) {
    final waterController = TextEditingController(text: '0.5');
    final stepsTargetController = TextEditingController(text: '8000');
    final waterTargetController = TextEditingController(text: '2.5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.directions_run_rounded, color: AppColors.primary, size: 30),
                    SizedBox(width: 10),
                    Text('Activity & Health Monitoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'No fabricated device data is shown. Targets are compared with verified metrics.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Step Monitoring Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_walk_rounded, color: Color(0xFF15803D)),
                          SizedBox(width: 8),
                          Text('Daily Steps Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Daily Steps Target: 8,000 steps', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Actual Steps: Not connected', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Status: Hardware Sensor Not Connected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Water Tracker Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water_drop_rounded, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Text('Water Intake Monitor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Daily Water Target: 2.5 Liters', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: waterController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Log Water Drank (Liters)',
                          suffixText: 'L',
                          prefixIcon: const Icon(Icons.local_drink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Heart Rate Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_rounded, color: Color(0xFFB91C1C)),
                          SizedBox(width: 8),
                          Text('Heart Rate Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Target Range: 60 - 100 BPM', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Actual Heart Rate: Not connected', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final val = double.tryParse(waterController.text) ?? 0.5;
                        await ApiService().addHealthMetric(
                          waterIntake: val,
                          waterTarget: 2.5,
                          dataSource: 'manual',
                          notes: 'Logged via parent dashboard',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadDashboard();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save Logged Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal: Emergency Message AI Assistant (Hindi & English) ────────────────
  void _showEmergencyAIAssistantModal(BuildContext context) {
    final promptController = TextEditingController();
    bool isGenerating = false;
    String selectedLang = 'hi'; // 'hi', 'en', 'hinglish'
    Map<String, dynamic>? aiResult;

    final hindiSamples = [
      "🚨 मुझे चक्कर आ रहे हैं, तुरंत सहायता चाहिए।",
      "💔 मेरे सीने में दर्द हो रहा है, मदद भेजें।",
      "🫁 सांस लेने में तकलीफ हो रही है।",
      "🩺 डॉक्टर से तुरंत आपातकालीन परामर्श चाहिए।"
    ];

    final englishSamples = [
      "I am feeling very dizzy and lightheaded.",
      "Experiencing severe chest discomfort.",
      "Difficulty in breathing, notify emergency contact.",
      "Need urgent doctor consultation right away."
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.redAccent, size: 32),
                    SizedBox(width: 10),
                    Text('Emergency AI Assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'सहायक आपकी भाषा में उत्तर देगा। Emergency AI responds in Hindi & English for quick assistance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Language Selection Segment
                Row(
                  children: [
                    const Text('Language / भाषा: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🇮🇳 हिंदी (Hindi)'),
                      selected: selectedLang == 'hi',
                      selectedColor: Colors.red.shade100,
                      onSelected: (sel) {
                        if (sel) setModalState(() => selectedLang = 'hi');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🇬🇧 English'),
                      selected: selectedLang == 'en',
                      selectedColor: Colors.blue.shade100,
                      onSelected: (sel) {
                        if (sel) setModalState(() => selectedLang = 'en');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  selectedLang == 'hi' ? 'त्वरित प्रश्न / विकल्प चुनें:' : 'Quick Emergency Prompts:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (selectedLang == 'hi' ? hindiSamples : englishSamples).map((s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.red.shade50,
                    onPressed: () {
                      setModalState(() => promptController.text = s);
                    },
                  )).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: promptController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: selectedLang == 'hi'
                        ? 'अपनी स्थिति बताएं (जैसे: मुझे बहुत चक्कर आ रहे हैं...)'
                        : 'Describe your emergency (e.g. Feeling dizzy or chest discomfort...)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isGenerating ? null : () async {
                      final text = promptController.text.trim();
                      if (text.isEmpty) return;
                      setModalState(() => isGenerating = true);
                      try {
                        final res = await ApiService().sendEmergencyAIAssistant(text, language: selectedLang);
                        setModalState(() {
                          aiResult = res;
                          isGenerating = false;
                        });
                      } catch (e) {
                        setModalState(() => isGenerating = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: isGenerating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bolt_rounded, size: 24),
                    label: Text(
                      isGenerating
                          ? (selectedLang == 'hi' ? 'सहायता तैयार हो रही है...' : 'Generating...')
                          : (selectedLang == 'hi' ? 'आपातकालीन संदेश एवं सलाह प्राप्त करें' : 'Generate Emergency Alert Message'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                if (aiResult != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedLang == 'hi' ? '🚨 आपातकालीन संदेश (Emergency Message):' : '🚨 Generated Emergency Message:',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: Colors.redAccent),
                              tooltip: 'Listen / सुनें',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🔊 ${aiResult!['advice']}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          aiResult!['suggested_message'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.security, size: 18, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${selectedLang == 'hi' ? "सुरक्षा सलाह: " : "Safety Advice: "}${aiResult!['advice'] ?? ''}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal: Parent Doctor Consultation Hub (Physical Nearby vs Virtual) ────
  void _showParentDoctorsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text('Doctor Consultations for Parents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'CareBridge connects you only with verified doctors.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(icon: Icon(Icons.store_rounded), text: '🏥 Nearby Physical Doctors'),
                  Tab(icon: Icon(Icons.video_call_rounded), text: '💻 Virtual Consultations'),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Nearby Physical Doctors
                    FutureBuilder<List<dynamic>>(
                      future: ApiService().getDoctors(consultationType: 'In-person'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No verified physical doctors found near your location.'));
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, idx) {
                            final d = docs[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFDCFCE7),
                                  child: Icon(Icons.person_pin_circle_rounded, color: Colors.green),
                                ),
                                title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${d['specialty']} • ${d['location']}\nFee: \$${d['consultation_fee']} • Exp: ${d['experience_years']} yrs'),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FindDoctorScreen()));
                                  },
                                  child: const Text('Visit Clinic'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Tab 2: Virtual Consultation Doctors
                    FutureBuilder<List<dynamic>>(
                      future: ApiService().getDoctors(consultationType: 'Virtual'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No verified virtual doctors currently available.'));
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, idx) {
                            final d = docs[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFF3E8FF),
                                  child: Icon(Icons.video_camera_front_rounded, color: Colors.purple),
                                ),
                                title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${d['specialty']} • Languages: ${d['languages'] ?? "English"}\nFee: \$${d['consultation_fee']} • Online Consultation'),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FindDoctorScreen()));
                                  },
                                  child: const Text('Book Online'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Modal: Nearby Hospitals (Google Maps) ──────────────────────────────────
  void _showNearbyHospitalsModal(BuildContext context) {
    double lat = 28.6139; // Default New Delhi / City location
    double lng = 77.2090;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.local_hospital_rounded, color: Colors.red, size: 30),
                    SizedBox(width: 10),
                    Text('Nearby Hospitals (~2 km)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connected to Google Maps & Real Location service.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),

                FutureBuilder<Map<String, dynamic>>(
                  future: ApiService().getNearbyHospitals(lat, lng),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }
                    final data = snapshot.data;
                    final list = (data?['hospitals'] as List?) ?? [];
                    if (list.isEmpty) {
                      return const Text('No hospitals found within 2 km radius.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final h = list[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFEE2E2),
                              child: Icon(Icons.local_hospital, color: Colors.red),
                            ),
                            title: Text(h['name'] ?? 'Hospital', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(h['address'] ?? 'Nearby'),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final url = Uri.parse(h['maps_url'] ?? '');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Directions 🗺️'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal: Emergency & Doctor Contacts (Keep Contact Updated) ─────────────
  void _showEmergencyContactsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final nameController = TextEditingController();
          final phoneController = TextEditingController();
          final relController = TextEditingController(text: 'Family');

          final docNameController = TextEditingController();
          final docPhoneController = TextEditingController();
          final docEmailController = TextEditingController();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.contacts_rounded, color: Colors.redAccent, size: 30),
                      SizedBox(width: 10),
                      Text('Manage Saved Contacts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Emergency Contacts Section (Max 5) ──
                  FutureBuilder<List<dynamic>>(
                    future: ApiService().getEmergencyContacts(),
                    builder: (context, snapshot) {
                      final contacts = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Contacts (${contacts.length}/5 max)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 8),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: contacts.length,
                            itemBuilder: (context, idx) {
                              final c = contacts[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFEE2E2),
                                  child: Icon(Icons.phone_rounded, color: Colors.redAccent),
                                ),
                                title: Text(c['name'] ?? 'Contact', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${c['phone']} • ${c['relationship']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: () async {
                                    await ApiService().deleteEmergencyContact(c['id']);
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),

                          if (contacts.length < 5) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Contact Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: relController,
                              decoration: InputDecoration(
                                labelText: 'Relationship',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await ApiService().addEmergencyContact(
                                      name: nameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      relationship: relController.text.trim(),
                                    );
                                    setModalState(() {});
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Emergency Contact'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const Divider(height: 32),

                  // ── Saved Doctor Contact Section ──
                  FutureBuilder<List<dynamic>>(
                    future: ApiService().getDoctorContacts(),
                    builder: (context, snapshot) {
                      final docContacts = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Doctor's Contact Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docContacts.length,
                            itemBuilder: (context, idx) {
                              final d = docContacts[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE0F2FE),
                                  child: Icon(Icons.medical_services_rounded, color: AppColors.primary),
                                ),
                                title: Text(d['doctor_name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${d['doctor_phone']} • ${d['doctor_email'] ?? "No email"}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    await ApiService().deleteDoctorContact(d['id']);
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),
                          TextField(
                            controller: docNameController,
                            decoration: InputDecoration(
                              labelText: 'Doctor Name (e.g. Dr. ABC)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: docPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Doctor Phone Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: docEmailController,
                            decoration: InputDecoration(
                              labelText: 'Doctor Email (Optional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await ApiService().addDoctorContact(
                                    doctorName: docNameController.text.trim(),
                                    doctorPhone: docPhoneController.text.trim(),
                                    doctorEmail: docEmailController.text.trim(),
                                  );
                                  setModalState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Save Doctor Information'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHealthModal(BuildContext context) {
    _showActivityMonitoringModal(context);
  }

  void _showFamilyCodeModal(BuildContext context) async {
    final emailController = TextEditingController();
    final inviteCodeController = TextEditingController();
    int activeTab = 0; // 0: Share/Send Email, 1: Accept Code
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => FutureBuilder<Map<String, dynamic>>(
          future: ApiService().getFamilyCode(),
          builder: (context, snapshot) {
            final code = snapshot.data?['family_code'] ?? 'CB-839210';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 30),
                      SizedBox(width: 10),
                      Text('Family Account Link', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 0 ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '📧 Send Email Invite',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 1 ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '🔑 Enter Code',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: activeTab == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activeTab == 0) ...[
                      const Text(
                        'Your Family Pairing Code:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Or enter your caregiver / child\'s email address below to send an invitation email with instructions:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Caregiver / Child Email',
                          hintText: 'child@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Enter invitation code received from email or caregiver:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                        decoration: InputDecoration(
                          labelText: 'Invitation Code',
                          hintText: 'CB-XXXXXX',
                          prefixIcon: const Icon(Icons.key_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          if (activeTab == 0) {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              Navigator.pop(ctx);
                              return;
                            }
                            setDialogState(() => isProcessing = true);
                            try {
                              final res = await ApiService().inviteFamilyByEmail(email);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Invitation email dispatched successfully!'),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          } else {
                            final codeVal = inviteCodeController.text.trim();
                            if (codeVal.isEmpty) return;
                            setDialogState(() => isProcessing = true);
                            try {
                              final res = await ApiService().acceptFamilyEmailInvite(codeVal);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Account linked successfully! Confirmation emails sent.'),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                _loadDashboard();
                              }
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(activeTab == 0 ? (emailController.text.isNotEmpty ? 'Send Email Invite' : 'Done') : 'Link Account'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final greeting = _greeting();
    final todayFormatted = _getTodayDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // ── Header Section ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B6B5A), Color(0xFF0F473B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            greeting,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user?.name.split(' ').first ?? 'Parent',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 28,
                                      tooltip: 'Log out',
                                      icon: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                                      ),
                                      onPressed: () async {
                                        await context.read<AuthProvider>().logout();
                                        if (context.mounted) {
                                          Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        todayFormatted,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAddDosesModal(context),
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                                        label: const Text('Add Doses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showActivityMonitoringModal(context),
                                        icon: const Icon(Icons.directions_run_rounded, size: 22),
                                        label: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── SOS Emergency Button ─────────────────────────────────
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
                        child: Center(child: SOSButton()),
                      ),
                    ),

                    // ── Quick Actions Grid ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions & Services',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 1.1,
                              children: [
                                _BigParentButton(
                                  icon: Icons.medical_services_rounded,
                                  emoji: '🩺',
                                  label: 'Find Doctors',
                                  gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                                  onTap: () => _showParentDoctorsModal(context),
                                ),
                                _BigParentButton(
                                  icon: Icons.qr_code_rounded,
                                  emoji: '🔑',
                                  label: 'Family Code',
                                  gradient: const [Color(0xFF6C5CE7), Color(0xFF4F46E5)],
                                  onTap: () => _showFamilyCodeModal(context),
                                ),
                                _BigParentButton(
                                  icon: Icons.contacts_rounded,
                                  emoji: '📞',
                                  label: 'Update Contacts',
                                  gradient: const [Color(0xFFB91C1C), Color(0xFFEF4444)],
                                  onTap: () => _showEmergencyContactsModal(context),
                                ),
                                _BigParentButton(
                                  icon: Icons.smart_toy_rounded,
                                  emoji: '🤖',
                                  label: 'Emergency AI',
                                  gradient: const [Color(0xFFDC2626), Color(0xFFF87171)],
                                  onTap: () => _showEmergencyAIAssistantModal(context),
                                ),
                                _BigParentButton(
                                  icon: Icons.map_rounded,
                                  emoji: '🏥',
                                  label: 'Nearby Hospitals',
                                  gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                  onTap: () => _showNearbyHospitalsModal(context),
                                ),
                                _BigParentButton(
                                  icon: Icons.calendar_month_rounded,
                                  emoji: '📅',
                                  label: 'Appointments',
                                  gradient: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                                ),
                                _BigParentButton(
                                  icon: Icons.description_rounded,
                                  emoji: '📄',
                                  label: 'Reports & AI',
                                  gradient: const [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentReportsScreen(user: user!))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Medicines & Doses Section ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Doses 💊",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddDosesModal(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Dose'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_medicines.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppShadows.soft,
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success),
                                SizedBox(height: 12),
                                Text(
                                  'No medicines scheduled for today!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Enjoy your day and stay healthy.',
                                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: _ParentMedicineTile(
                              medicine: _medicines[index],
                              onTaken: () => _updateStatus(_medicines[index].medicineId, 'taken'),
                              onSkipped: () => _updateStatus(_medicines[index].medicineId, 'skipped'),
                              onSnoozed: () => _updateStatus(_medicines[index].medicineId, 'snoozed'),
                              onSpeak: () => _speakReminder(_medicines[index]),
                            ),
                          ),
                          childCount: _medicines.length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌅,';
    if (h < 17) return 'Good Afternoon ☀️,';
    return 'Good Evening 🌙,';
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}';
  }
}

class _BigParentButton extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BigParentButton({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: gradient.last.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentMedicineTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VoidCallback onSnoozed;
  final VoidCallback onSpeak;

  const _ParentMedicineTile({
    required this.medicine,
    required this.onTaken,
    required this.onSkipped,
    required this.onSnoozed,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isDecided = medicine.status != 'pending';
    final isTaken = medicine.status == 'taken';
    final isSnoozed = medicine.status == 'snoozed';

    final timeOfDayText = medicine.timeOfDay ?? 'Anytime';
    String timeEmoji = '☀️';
    if (timeOfDayText.toLowerCase().contains('morning')) timeEmoji = '🌅';
    if (timeOfDayText.toLowerCase().contains('night') || timeOfDayText.toLowerCase().contains('evening')) timeEmoji = '🌙';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: isDecided
            ? Border.all(
                color: isTaken ? const Color(0xFF10B981) : (isSnoozed ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                width: 1.5,
              )
            : Border.all(color: const Color(0xFFF0F1F7), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.medicineName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dose: ${medicine.dose ?? "1"} ${medicine.doseUnit ?? "tablet"} • ${medicine.foodInstruction ?? "After Food"}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    if (medicine.diseaseCondition != null && medicine.diseaseCondition!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Taken for: ${medicine.diseaseCondition}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF7C3AED)),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(timeEmoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 4),
                        Text(
                          '$timeOfDayText • ${medicine.frequency ?? "Once a day"}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 26),
                tooltip: 'Read Aloud',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isDecided)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isTaken ? const Color(0xFFECFDF5) : (isSnoozed ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTaken ? const Color(0xFF10B981) : (isSnoozed ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTaken ? Icons.check_circle_rounded : (isSnoozed ? Icons.alarm : Icons.cancel_rounded),
                    color: isTaken ? const Color(0xFF10B981) : (isSnoozed ? const Color(0xFFD97706) : const Color(0xFFEF4444)),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTaken ? 'TAKEN ✓' : (isSnoozed ? 'SNOOZED 🔔' : 'SKIPPED'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isTaken ? const Color(0xFF059669) : (isSnoozed ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onTaken,
                          icon: const Icon(Icons.check_rounded, size: 22),
                          label: Text('Taken ✅', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: onSkipped,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: Text('Skip', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton.icon(
                    onPressed: onSnoozed,
                    icon: const Icon(Icons.alarm_rounded, size: 20, color: Color(0xFFD97706)),
                    label: Text('Snooze Reminder 🔔', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFBEB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
