import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/presentation/providers/analytics_provider.dart';

class TrendLineChart extends StatelessWidget {
  final List<MonthlyTrend> trends;

  const TrendLineChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (trends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'No historical trends available.',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E92A4),
            ),
          ),
        ),
      );
    }

    // Find maximum value to scale Y axis
    final maxIncome = trends.map((t) => t.income).reduce((a, b) => a > b ? a : b);
    final maxExpense = trends.map((t) => t.expense).reduce((a, b) => a > b ? a : b);
    final maxVal = maxIncome > maxExpense ? maxIncome : maxExpense;
    final yMax = maxVal > 0 ? maxVal * 1.2 : 100.0;
    final yInterval = yMax / 4;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark
                    ? const Color(0xFF2D3250).withOpacity(0.3)
                    : Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        trends[index].monthLabel,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8E92A4),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 26,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  String text;
                  if (value >= 1000) {
                    text = '\$${(value / 1000).toStringAsFixed(1)}k';
                  } else {
                    text = '\$${value.toInt()}';
                  }
                  return Text(
                    text,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E92A4),
                      fontSize: 9,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trends.length - 1).toDouble(),
          minY: 0,
          maxY: yMax,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark ? const Color(0xFF1E295D) : Colors.grey[200]!,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final isIncomeLine = touchedSpot.barIndex == 0;
                  return LineTooltipItem(
                    '${isIncomeLine ? 'Income' : 'Expense'}\n\$${touchedSpot.y.toStringAsFixed(2)}',
                    GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Income Line (Green)
            LineChartBarData(
              spots: List.generate(trends.length, (i) {
                return FlSpot(i.toDouble(), trends[i].income);
              }),
              isCurved: true,
              color: const Color(0xFF00E676),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00E676).withOpacity(0.08),
              ),
            ),
            
            // Expense Line (Red)
            LineChartBarData(
              spots: List.generate(trends.length, (i) {
                return FlSpot(i.toDouble(), trends[i].expense);
              }),
              isCurved: true,
              color: const Color(0xFFFF5252),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF5252).withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
