import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/stat_card.dart';
import '../data/report_service.dart';
import '../models/monthly_report.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _handleShare(MonthlyReport report) async {
    final text = ReportService.buildPlainTextSummary(report);
    // ignore: deprecated_member_use
    await Share.share(text, subject: 'FleetBoard Summary ${report.monthKey}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(reportSelectedMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final trendsAsync = ref.watch(historicalTrendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        actions: [
          reportAsync.when(
            data: (r) => IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Summary',
              onPressed: () => _handleShare(r),
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => ref.read(reportSelectedMonthProvider.notifier).previous(),
                ),
                Text(
                  MonthKey.formatMonthLabel(selectedMonth),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => ref.read(reportSelectedMonthProvider.notifier).next(),
                ),
              ],
            ),
          ),

          // Main Reports Content
          Expanded(
            child: reportAsync.when(
              loading: () => const LoadingView(message: 'Generating monthly report...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(monthlyReportProvider),
              ),
              data: (report) {
                if (report.totalTrips == 0 && report.totalExpenses == 0) {
                  return EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'No activity in ${MonthKey.formatMonthLabel(selectedMonth)}',
                    description: 'No completed trips or expenses recorded for this month.',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. KPI 2x2 Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          StatCard(
                            label: 'Gross Earning',
                            value: Formatters.currency(report.grossEarnings),
                            icon: Icons.payments_outlined,
                            valueColor: theme.colorScheme.primary,
                          ),
                          StatCard(
                            label: 'Total Expenses',
                            value: Formatters.currency(report.totalExpenses),
                            icon: Icons.receipt_long_outlined,
                            valueColor: theme.colorScheme.error,
                            subtitle: 'Extra: ${Formatters.currency(report.extraExpenses)}',
                          ),
                          StatCard(
                            label: 'Net Profit',
                            value: Formatters.currency(report.netProfit),
                            icon: Icons.trending_up_rounded,
                            valueColor: report.netProfit >= 0 ? Colors.green : theme.colorScheme.error,
                          ),
                          StatCard(
                            label: 'Trips & Distance',
                            value: '${report.totalTrips} Trips',
                            icon: Icons.route_outlined,
                            subtitle: Formatters.km(report.totalKm),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Payment Modes & Pending Balance
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Collection & Balances', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 12),
                              _reportRow('UPI Payments Received', Formatters.currency(report.receivedUpi)),
                              _reportRow('Cash Payments Received', Formatters.currency(report.receivedCash)),
                              const Divider(height: 16),
                              _reportRow(
                                'Pending Balance',
                                Formatters.currency(report.pendingPayments),
                                isBold: true,
                                color: report.pendingPayments > 0 ? theme.colorScheme.error : Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Car-Wise Performance Table
                      Text('Vehicle Performance', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (report.carWise.isNotEmpty) ...[
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 18,
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              columns: const [
                                DataColumn(label: Text('Car')),
                                DataColumn(label: Text('Trips')),
                                DataColumn(label: Text('KM')),
                                DataColumn(label: Text('Earning')),
                                DataColumn(label: Text('Expenses')),
                                DataColumn(label: Text('Net Profit')),
                              ],
                              rows: report.carWise.map((c) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(c.carNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text('${c.tripsCount}')),
                                    DataCell(Text(Formatters.km(c.totalKm))),
                                    DataCell(Text(Formatters.currency(c.grossEarnings))),
                                    DataCell(Text(Formatters.currency(c.totalExpenses))),
                                    DataCell(
                                      Text(
                                        Formatters.currency(c.netProfit),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: c.netProfit >= 0 ? Colors.green : theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text('No vehicle performance data.'),
                      ],

                      const SizedBox(height: 24),

                      // 3. Expense Category Breakdown
                      if (report.categoryBreakdown.isNotEmpty) ...[
                        Text('Expense Category Breakdown', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: report.categoryBreakdown.map((cat) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(ExpenseCategories.label(cat.category), style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text('${Formatters.currency(cat.amount)} (${cat.percentage.toStringAsFixed(1)}%)'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: cat.percentage / 100,
                                        backgroundColor: theme.colorScheme.outline.withAlpha(50),
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                        minHeight: 6,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 4. 6-Month Trend Chart (Earning vs Expenses)
                      Text('6-Month Performance Trend', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      trendsAsync.when(
                        loading: () => const SizedBox(height: 180, child: LoadingView()),
                        error: (err, stack) => const Text('Could not load historical trends.'),
                        data: (points) {
                          if (points.isEmpty) return const SizedBox.shrink();

                          final maxVal = points.fold<int>(
                            1000,
                            (max, p) => p.earnings > max ? p.earnings : (p.expenses > max ? p.expenses : max),
                          );

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _chartLegend(theme.colorScheme.primary, 'Earnings'),
                                      const SizedBox(width: 20),
                                      _chartLegend(theme.colorScheme.error, 'Expenses'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 180,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: (maxVal * 1.2).toDouble(),
                                        barTouchData: BarTouchData(enabled: true),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx >= 0 && idx < points.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(points[idx].label, style: const TextStyle(fontSize: 11)),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        barGroups: points.asMap().entries.map((e) {
                                          final idx = e.key;
                                          final pt = e.value;
                                          return BarChartGroupData(
                                            x: idx,
                                            barRods: [
                                              BarChartRodData(
                                                toY: pt.earnings.toDouble(),
                                                color: theme.colorScheme.primary,
                                                width: 10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              BarChartRodData(
                                                toY: pt.expenses.toDouble(),
                                                color: theme.colorScheme.error,
                                                width: 10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Share Plain Text Summary CTA
                      AppButton(
                        label: 'Share Monthly Summary via WhatsApp',
                        icon: Icons.share_rounded,
                        onPressed: () => _handleShare(report),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
