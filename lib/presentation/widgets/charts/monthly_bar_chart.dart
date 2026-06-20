import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/presentation/providers/analytics_provider.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<DailyData> data;

  const MonthlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if we have any entries
    final maxAmount = data.isNotEmpty
        ? data.map((d) => d.amount).reduce((a, b) => a > b ? a : b)
        : 0.0;

    if (maxAmount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'No daily transactions recorded.',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E92A4),
            ),
          ),
        ),
      );
    }

    // Determine interval for vertical grid
    final double yInterval = maxAmount > 0 ? (maxAmount / 4) : 10.0;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? const Color(0xFF1E295D) : Colors.grey[200]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Day ${group.x}\n\$${rod.toY.toStringAsFixed(2)}',
                  GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final intVal = value.toInt();
                  // Label every 5 days to prevent clutter
                  if (intVal == 1 || intVal == 5 || intVal == 10 || intVal == 15 || intVal == 20 || intVal == 25 || intVal == 30) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        '$intVal',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8E92A4),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 22,
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
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
          borderData: FlBorderData(show: false),
          barGroups: data.map((d) {
            return BarChartGroupData(
              x: d.date.day,
              barRods: [
                BarChartRodData(
                  toY: d.amount,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF7A5CFF)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 5,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
