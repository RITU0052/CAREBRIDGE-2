import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_theme.dart';
import '../../services/api_service.dart';

class ParentReportsScreen extends StatefulWidget {
  final dynamic user;
  const ParentReportsScreen({super.key, required this.user});

  @override
  State<ParentReportsScreen> createState() => _ParentReportsScreenState();
}

class _ParentReportsScreenState extends State<ParentReportsScreen> {
  late Future<List<dynamic>> _reportsFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<dynamic>> _loadReports() async {
    String parentId = '';
    try {
      final user = widget.user;
      final role = (user is Map) ? user['role'] : user.role;
      final isChild = role == 'child';

      if (isChild) {
        parentId = (user is Map)
            ? (user['linked_user_id'] ?? user['id'] ?? '').toString()
            : (user.linkedUserId ?? user.id ?? '').toString();
      } else {
        parentId = (user is Map)
            ? (user['id'] ?? user['user_id'] ?? '').toString()
            : (user.id ?? '').toString();
      }
    } catch (_) {
      parentId = '';
    }

    if (parentId.isEmpty) return [];
    return await ApiService().getReports(parentId);
  }

  Future<void> _pickAndUploadReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      String title = await _askForTitle();
      if (title.trim().isEmpty) return;

      setState(() => _isUploading = true);
      try {
        if (file.bytes != null) {
          await ApiService().uploadReport(
            null,
            title,
            bytes: file.bytes,
            filename: file.name,
          );
        } else if (file.path != null) {
          await ApiService().uploadReport(
            file.path,
            title,
          );
        } else {
          throw Exception('Unable to read selected file');
        }

        setState(() {
          _reportsFuture = _loadReports();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Report uploaded successfully!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading report: $e'), backgroundColor: AppColors.emergency),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<String> _askForTitle() async {
    TextEditingController titleController = TextEditingController();
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Title'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'e.g. Blood Test Report / X-Ray'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, titleController.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save & Upload'),
            ),
          ],
        );
      },
    ) ?? '';
  }

  void _showAISummaryDialog(BuildContext context, String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService().summarizeReportAI(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 140,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('🤖 AI Medical Agent Analyzing Report...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('AI Analysis Warning'),
              content: Text('Could not generate summary: ${snapshot.error.toString().replaceAll("Exception: ", "")}'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            );
          }

          final data = snapshot.data ?? {};
          final overall = data['overall_summary'] ?? 'Report analysis overview.';
          final importantValues = List<String>.from(data['important_values'] ?? []);
          final questions = List<String>.from(data['suggested_questions'] ?? []);
          final nextSteps = data['recommended_next_steps'] ?? 'Consult your doctor.';
          final disclaimer = data['disclaimer'] ?? 'This AI summary is for informational purposes only and is not a medical diagnosis.';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text('AI Report Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      disclaimer,
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Summary Findings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(overall, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),

                  const Text('Important Values & Markers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  ...importantValues.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  const Text('Questions for Your Doctor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  ...questions.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('❓ ', style: TextStyle(fontSize: 13)),
                            Expanded(child: Text(q, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  const Text('Recommended Next Steps:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(nextSteps, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Close Summary'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await ApiService().deleteReport(reportId);
      setState(() {
        _reportsFuture = _loadReports();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text('Medical Reports', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F1F7), height: 1),
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : FutureBuilder<List<dynamic>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load reports', style: GoogleFonts.inter(color: AppColors.textSecondary)));
                }

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                            child: const Icon(Icons.description_outlined, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('No reports uploaded yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text('Click "Upload Report" below to add lab test or diagnostic results.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final isPdf = report['file_type'] == 'pdf';
                    final uploadDateStr = report['upload_date'] ?? '';
                    final date = DateTime.tryParse(uploadDateStr) ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF0F1F7)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                  child: Icon(
                                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(report['title'] ?? 'Medical Report', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      Text('Uploaded: ${date.day}/${date.month}/${date.year}', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  onPressed: () => _deleteReport(report['id']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showAISummaryDialog(context, report['id']),
                                    icon: const Icon(Icons.smart_toy_rounded, size: 16),
                                    label: Text('Analyze Report 🤖', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final rawPath = report['file_path'] ?? '';
                                    final fullUrl = '${ApiConfig.baseUrl.replaceAll("/api", "")}$rawPath';
                                    final uri = Uri.parse(fullUrl);
                                    try {
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                                      }
                                    } catch (_) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: Text('View', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadReport,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: Text('Upload Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
