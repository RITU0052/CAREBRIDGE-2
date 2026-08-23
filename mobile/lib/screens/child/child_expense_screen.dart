import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../widgets/app_theme.dart';

/// Expense tracker screen with pie/bar charts and expense list
class ChildExpenseScreen extends StatefulWidget {
  const ChildExpenseScreen({super.key});

  @override
  State<ChildExpenseScreen> createState() => _ChildExpenseScreenState();
}

class _ChildExpenseScreenState extends State<ChildExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ExpenseModel> _expenses = MockExpenses.sample();
  int _touchedIndex = -1;

  final Map<String, Color> _catColors = {
    'hospital': AppColors.emergency,
    'pharmacy': AppColors.primary,
    'lab': AppColors.bpColor,
    'insurance': AppColors.sugarColor,
    'ambulance': AppColors.heartColor,
    'other': AppColors.textSecondary,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _total => _expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final totals = MockExpenses.categoryTotals(_expenses);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: AppColors.heroGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Expense Tracker',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('This Month',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: Colors.white60)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(_total.toInt())}',
                                  style: AppTextStyles.displayLarge.copyWith(
                                      color: Colors.white, fontSize: 30),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.trending_down_rounded,
                                      color: Color(0xFF4ADE80), size: 18),
                                  const SizedBox(width: 6),
                                  Text('5% vs last month',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.white70)),
                                ],
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Overview tab ─────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Pie chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spending by Category',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse?.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse!
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: totals.entries.map((e) {
                                final index =
                                    totals.keys.toList().indexOf(e.key);
                                final isTouched = index == _touchedIndex;
                                return PieChartSectionData(
                                  color: _catColors[e.key] ??
                                      AppColors.textSecondary,
                                  value: e.value,
                                  title: isTouched ? '₹${e.value.toInt()}' : '',
                                  radius: isTouched ? 70 : 56,
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...totals.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _catColors[e.key] ??
                                          AppColors.textSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      ExpenseModel(
                                              amount: 0,
                                              category: e.key,
                                              date: DateTime.now())
                                          .categoryLabel,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(e.value.toInt())}',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(e.value / _total * 100).toStringAsFixed(0)}%',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bar chart — monthly comparison
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('6-Month Trend',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 5000,
                                getDrawingHorizontalLine: (v) => FlLine(
                                    color: AppColors.divider, strokeWidth: 1),
                                drawVerticalLine: false,
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (v, _) {
                                    const months = [
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug'
                                    ];
                                    if (v.toInt() >= months.length)
                                      return const SizedBox.shrink();
                                    return Text(months[v.toInt()],
                                        style: AppTextStyles.caption);
                                  },
                                )),
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (v, _) => Text(
                                      '₹${(v / 1000).toInt()}k',
                                      style: AppTextStyles.caption),
                                )),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (int i = 0; i < 6; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: [
                                          12000.0,
                                          15500.0,
                                          8200.0,
                                          18700.0,
                                          14200.0,
                                          _total
                                        ][i],
                                        color: i == 5
                                            ? AppColors.primary
                                            : AppColors.primary
                                                .withOpacity(0.35),
                                        width: 22,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(6)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Transactions tab ─────────────────────────────────────────
            ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _expenses.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                    ),
                  );
                }
                final e = _expenses[i - 1];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.soft),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (_catColors[e.category] ??
                                  AppColors.textSecondary)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon(e.category),
                            color: _catColors[e.category] ??
                                AppColors.textSecondary,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.description ?? e.categoryLabel,
                                style: AppTextStyles.bodyLarge
                                    .copyWith(fontWeight: FontWeight.w600)),
                            Text(DateFormat('MMM d, yyyy').format(e.date),
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${NumberFormat('#,##,###').format(e.amount.toInt())}',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: AppColors.emergency),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_catColors[e.category] ??
                                      AppColors.textSecondary)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              e.categoryLabel,
                              style: AppTextStyles.caption.copyWith(
                                  color: _catColors[e.category] ??
                                      AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'pharmacy':
        return Icons.medication_rounded;
      case 'lab':
        return Icons.science_rounded;
      case 'insurance':
        return Icons.security_rounded;
      case 'ambulance':
        return Icons.emergency_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}
