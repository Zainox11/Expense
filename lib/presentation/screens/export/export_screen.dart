import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/presentation/providers/category_provider.dart';
import 'package:expense_tracker/presentation/providers/theme_provider.dart';
import 'package:expense_tracker/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/presentation/widgets/common/custom_button.dart';
import 'package:expense_tracker/presentation/widgets/common/glass_card.dart';
import 'package:expense_tracker/services/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ExportService _exportService = ExportService();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _exportFormat = 0; // 0 for PDF, 1 for Excel
  bool _isLoading = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Future<void> _export() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('No logged in user found.');

      // Load all transactions for selected month/year
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

      final repo = ref.read(transactionRepositoryProvider);
      final transactions = await repo.getTransactions(
        user.id,
        startDate: startDate,
        endDate: endDate,
      );

      final categories = ref.read(categoriesProvider).valueOrNull ?? [];

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions recorded for the selected month.'),
              backgroundColor: Color(0xFFFFAB40),
            ),
          );
        }
        return;
      }

      if (_exportFormat == 0) {
        // PDF Export
        final pdfBytes = await _exportService.exportToPdf(
          transactions: transactions,
          categories: categories,
          month: _selectedMonth,
          year: _selectedYear,
        );
        
        await _exportService.shareFile(
          bytes: pdfBytes,
          fileName: 'Expense_Report_${_months[_selectedMonth - 1]}_$_selectedYear.pdf',
          mimeType: 'application/pdf',
        );
      } else {
        // Excel Export
        final excelBytes = await _exportService.exportToExcel(
          transactions: transactions,
          categories: categories,
          month: _selectedMonth,
          year: _selectedYear,
        );

        await _exportService.shareFile(
          bytes: excelBytes,
          fileName: 'Expense_Spreadsheet_${_months[_selectedMonth - 1]}_$_selectedYear.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Export Reports',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual header card
              _buildIntroCard(),
              const SizedBox(height: 24),

              // Month / Year parameters selection
              _buildPeriodSelector(isDark),
              const SizedBox(height: 24),

              // Format selector
              _buildFormatSelector(isDark),
              const SizedBox(height: 36),

              // Export action button
              CustomButton(
                text: _exportFormat == 0 ? 'Export PDF Report' : 'Export Excel Worksheet',
                isLoading: _isLoading,
                onPressed: _export,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D2FF).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF00D2FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statements & Reports',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Generate complete summaries of your financial data for backups, taxes or analysis.',
                  style: TextStyle(color: Color(0xFF8E92A4), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Period',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F38) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMonth = val;
                        });
                      }
                    },
                    items: List.generate(12, (i) => i + 1).map((m) {
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(
                          _months[m - 1],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F38) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3250) : Colors.grey[200]!,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1A1F38) : Colors.white,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedYear = val;
                        });
                      }
                    },
                    items: [
                      DateTime.now().year - 1,
                      DateTime.now().year,
                      DateTime.now().year + 1,
                    ].map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8E92A4) : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // PDF Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _exportFormat = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _exportFormat == 0
                        ? const Color(0xFFFF5252).withOpacity(0.12)
                        : (isDark ? const Color(0xFF1A1F38) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _exportFormat == 0
                          ? const Color(0xFFFF5252)
                          : (isDark ? const Color(0xFF2D3250) : Colors.grey[200]!),
                      width: _exportFormat == 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFFFF5252),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PDF Document',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Clean formatted report ready to print or email.',
                        style: TextStyle(color: Color(0xFF8E92A4), fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Excel Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _exportFormat = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _exportFormat == 1
                        ? const Color(0xFF00E676).withOpacity(0.12)
                        : (isDark ? const Color(0xFF1A1F38) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _exportFormat == 1
                          ? const Color(0xFF00E676)
                          : (isDark ? const Color(0xFF2D3250) : Colors.grey[200]!),
                      width: _exportFormat == 1 ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.table_view_rounded,
                        color: Color(0xFF00E676),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Excel Worksheet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tabular raw data. Perfect for complex spreadsheets.',
                        style: TextStyle(color: Color(0xFF8E92A4), fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
