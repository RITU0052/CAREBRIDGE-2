import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/health_vital.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/health_card.dart';

/// Full health monitoring screen with vitals grid + 7-day trend charts
class ChildHealthMonitorScreen extends StatefulWidget {
  const ChildHealthMonitorScreen({super.key});

  @override
  State<ChildHealthMonitorScreen> createState() => _ChildHealthMonitorScreenState();
}

class _ChildHealthMonitorScreenState extends State<ChildHealthMonitorScreen> {
  // Mock vitals — in production these come from the API
  final List<HealthVital> _vitals = MockVitals.forParent(1);
  bool _showAddSheet = false;

  HealthStatus _toStatus(String s) {
    if (s == 'warning') return HealthStatus.warning;
    if (s == 'critical') return HealthStatus.critical;
    return HealthStatus.normal;
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'bp': return AppColors.bpColor;
      case 'sugar': return AppColors.sugarColor;
      case 'heart_rate': return AppColors.heartColor;
      case 'oxygen': return AppColors.oxygenColor;
      case 'temperature': return AppColors.tempColor;
      case 'weight': return AppColors.weightColor;
      default: return AppColors.primary;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'bp': return Icons.monitor_heart_rounded;
      case 'sugar': return Icons.water_drop_rounded;
      case 'heart_rate': return Icons.favorite_rounded;
      case 'oxygen': return Icons.air_rounded;
      case 'temperature': return Icons.thermostat_rounded;
      case 'weight': return Icons.scale_rounded;
      default: return Icons.health_and_safety_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 90,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: Text('Health Overview', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF0F1F7), height: 1),
            ),
          ),

          // ── AI health score card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Health Score', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('78', style: GoogleFonts.poppins(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('/100', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Good — Sugar slightly elevated', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '78%',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Vitals", style: AppTextStyles.headlineMedium),
                  TextButton.icon(
                    onPressed: _showAddVitalSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          // ── Vitals grid ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vital = _vitals[index];
                  return HealthCard(
                    label: vital.label,
                    value: vital.value,
                    unit: vital.displayUnit,
                    icon: _icon(vital.type),
                    color: _iconColor(vital.type),
                    status: _toStatus(vital.status),
                    trend: index == 1 ? '↑ 12%' : index == 0 ? '↓ 3%' : null,
                  );
                },
                childCount: _vitals.length,
              ),
            ),
          ),

          // ── 7-day trend chart ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Day Sugar Trend', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text('mg/dL', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.card,
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 50,
                          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.divider, strokeWidth: 1),
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= days.length) return const SizedBox.shrink();
                                return Text(days[value.toInt()], style: AppTextStyles.caption);
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: AppTextStyles.caption),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 80,
                        maxY: 230,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 130), FlSpot(1, 145), FlSpot(2, 118), FlSpot(3, 162),
                              FlSpot(4, 138), FlSpot(5, 155), FlSpot(6, 145),
                            ],
                            isCurved: true,
                            color: AppColors.sugarColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppColors.sugarColor,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [AppColors.sugarColor.withOpacity(0.2), AppColors.sugarColor.withOpacity(0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BP chart ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Day Heart Rate Trend', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text('bpm', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.card,
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.divider, strokeWidth: 1),
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= days.length) return const SizedBox.shrink();
                                return Text(days[value.toInt()], style: AppTextStyles.caption);
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: AppTextStyles.caption),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 50,
                        maxY: 120,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 72), FlSpot(1, 78), FlSpot(2, 74), FlSpot(3, 92),
                              FlSpot(4, 80), FlSpot(5, 76), FlSpot(6, 78),
                            ],
                            isCurved: true,
                            color: AppColors.heartColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppColors.heartColor,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [AppColors.heartColor.withOpacity(0.2), AppColors.heartColor.withOpacity(0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVitalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddVitalSheet(),
    );
  }
}

class _AddVitalSheet extends StatefulWidget {
  @override
  State<_AddVitalSheet> createState() => _AddVitalSheetState();
}

class _AddVitalSheetState extends State<_AddVitalSheet> {
  String _selectedType = 'bp';
  final _controller = TextEditingController();

  final _types = [
    {'key': 'bp', 'label': 'Blood Pressure', 'hint': '120/80', 'icon': Icons.monitor_heart_rounded},
    {'key': 'sugar', 'label': 'Blood Sugar', 'hint': '105', 'icon': Icons.water_drop_rounded},
    {'key': 'heart_rate', 'label': 'Heart Rate', 'hint': '72', 'icon': Icons.favorite_rounded},
    {'key': 'oxygen', 'label': 'Oxygen SpO₂', 'hint': '97', 'icon': Icons.air_rounded},
    {'key': 'temperature', 'label': 'Temperature', 'hint': '37.1', 'icon': Icons.thermostat_rounded},
    {'key': 'weight', 'label': 'Weight', 'hint': '68', 'icon': Icons.scale_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text('Add Vital Reading', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final selected = _selectedType == t['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(t['icon'] as IconData, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            (t['label'] as String).split(' ').first,
                            style: AppTextStyles.caption.copyWith(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: _types.firstWhere((t) => t['key'] == _selectedType)['hint'] as String,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vital reading saved!'), backgroundColor: AppColors.success),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Reading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
