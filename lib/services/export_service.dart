import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';

/// Service for exporting transaction data into PDF and Excel reports.
///
/// Generates professional, styled reports with summaries and breakdowns.
class ExportService {
  ExportService();

  // ---------------------------------------------------------------------------
  // PDF Export
  // ---------------------------------------------------------------------------

  /// Generate a beautifully styled PDF report for the given [month] and [year].
  ///
  /// Returns the raw PDF bytes (`Uint8List`) that can be saved, shared, or
  /// previewed via [previewPdf].
  Future<Uint8List> exportToPdf({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity> categories,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document(
      title: 'Expense Report — ${_monthName(month)} $year',
      author: 'Expense Tracker',
      creator: 'Expense Tracker App',
    );

    // Pre-compute aggregates
    final dateFormat = DateFormat('MMM dd, yyyy');
    final monthName = _monthName(month);

    // Filter transactions for the target month/year
    final filtered = transactions.where((t) {
      return t.date.month == month && t.date.year == year;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    // Build category lookup map
    final categoryMap = <String, CategoryEntity>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat;
    }

    // Category-wise breakdown
    final categoryTotals = <String, double>{};
    for (final tx in filtered) {
      final catName = categoryMap[tx.categoryId]?.name ?? 'Unknown';
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;
    }

    // Theme colors
    const primaryColor = PdfColor.fromInt(0xFF1E88E5);
    const darkColor = PdfColor.fromInt(0xFF212121);
    const lightGray = PdfColor.fromInt(0xFFF5F5F5);
    const white = PdfColor.fromInt(0xFFFFFFFF);
    const incomeColor = PdfColor.fromInt(0xFF43A047);
    const expenseColor = PdfColor.fromInt(0xFFE53935);

    // Load a built-in font for consistent rendering
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontLight = await PdfGoogleFonts.robotoLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontLight,
        ),
        header: (context) => _buildPdfHeader(
          monthName: monthName,
          year: year,
          primaryColor: primaryColor,
          white: white,
          fontBold: fontBold,
          fontLight: fontLight,
        ),
        footer: (context) => _buildPdfFooter(context, darkColor),
        build: (context) => [
          // ── Summary Cards ──
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                'Total Income',
                '\$${totalIncome.toStringAsFixed(2)}',
                incomeColor,
                fontBold,
              ),
              _buildSummaryCard(
                'Total Expense',
                '\$${totalExpense.toStringAsFixed(2)}',
                expenseColor,
                fontBold,
              ),
              _buildSummaryCard(
                'Balance',
                '\$${balance.toStringAsFixed(2)}',
                primaryColor,
                fontBold,
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Transaction Table ──
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: darkColor),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionTable(
            filtered,
            categoryMap,
            dateFormat,
            fontBold,
            lightGray,
            incomeColor,
            expenseColor,
          ),
          pw.SizedBox(height: 24),

          // ── Category Breakdown ──
          pw.Text(
            'Category-wise Breakdown',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: darkColor),
          ),
          pw.SizedBox(height: 8),
          _buildCategoryBreakdownTable(
            categoryTotals,
            fontBold,
            lightGray,
            primaryColor,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    debugPrint('ExportService: PDF generated (${bytes.length} bytes)');
    return bytes;
  }

  /// Build the gradient-style header bar for the PDF.
  pw.Widget _buildPdfHeader({
    required String monthName,
    required int year,
    required PdfColor primaryColor,
    required PdfColor white,
    required pw.Font fontBold,
    required pw.Font fontLight,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Expense Tracker',
            style: pw.TextStyle(font: fontBold, fontSize: 20, color: white),
          ),
          pw.Text(
            '$monthName $year Report',
            style: pw.TextStyle(font: fontLight, fontSize: 14, color: white),
          ),
        ],
      ),
    );
  }

  /// Build a page footer with page numbers.
  pw.Widget _buildPdfFooter(pw.Context context, PdfColor color) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  /// Build a single summary card widget for the PDF.
  pw.Widget _buildSummaryCard(
    String label,
    String value,
    PdfColor color,
    pw.Font fontBold,
  ) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(font: fontBold, fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the main transactions table with alternating row colors.
  pw.Widget _buildTransactionTable(
    List<TransactionEntity> transactions,
    Map<String, CategoryEntity> categoryMap,
    DateFormat dateFormat,
    pw.Font fontBold,
    PdfColor alternateColor,
    PdfColor incomeColor,
    PdfColor expenseColor,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE3F2FD),
      ),
      rowDecoration: const pw.BoxDecoration(),
      oddRowDecoration: pw.BoxDecoration(color: alternateColor),
      headers: ['Date', 'Category', 'Note', 'Type', 'Amount'],
      data: transactions.map((tx) {
        final categoryName = categoryMap[tx.categoryId]?.name ?? 'Unknown';
        final typeLabel =
            tx.type == TransactionType.income ? 'Income' : 'Expense';
        final amountPrefix =
            tx.type == TransactionType.income ? '+' : '-';
        return [
          dateFormat.format(tx.date),
          categoryName,
          tx.note.isEmpty ? '—' : tx.note,
          typeLabel,
          '$amountPrefix\$${tx.amount.toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  /// Build a category-wise breakdown table.
  pw.Widget _buildCategoryBreakdownTable(
    Map<String, double> categoryTotals,
    pw.Font fontBold,
    PdfColor alternateColor,
    PdfColor primaryColor,
  ) {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grandTotal =
        sortedEntries.fold<double>(0, (sum, e) => sum + e.value);

    final data = sortedEntries.map((entry) {
      final percent =
          grandTotal > 0 ? (entry.value / grandTotal * 100) : 0.0;
      return [
        entry.key,
        '\$${entry.value.toStringAsFixed(2)}',
        '${percent.toStringAsFixed(1)}%',
      ];
    }).toList();

    // Add totals row
    data.add(['Total', '\$${grandTotal.toStringAsFixed(2)}', '100%']);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE3F2FD),
      ),
      oddRowDecoration: pw.BoxDecoration(color: alternateColor),
      headers: ['Category', 'Amount', 'Percentage'],
      data: data,
    );
  }

  // ---------------------------------------------------------------------------
  // Excel Export
  // ---------------------------------------------------------------------------

  /// Generate an Excel (.xlsx) workbook for the given [month] and [year].
  ///
  /// - **Sheet 1 — Transactions**: All transactions with details.
  /// - **Sheet 2 — Summary**: Category-wise totals and overall totals.
  ///
  /// Returns the raw Excel bytes (`Uint8List`).
  Future<Uint8List> exportToExcel({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity> categories,
    required int month,
    required int year,
  }) async {
    final workbook = excel_lib.Excel.createExcel();

    // Build category lookup
    final categoryMap = <String, CategoryEntity>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat;
    }

    // Filter transactions for the target month/year
    final filtered = transactions.where((t) {
      return t.date.month == month && t.date.year == year;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // ── Sheet 1: Transactions ──
    final txSheetName = 'Transactions';
    workbook.rename(workbook.getDefaultSheet()!, txSheetName);
    final txSheet = workbook[txSheetName];

    // Header row style
    final headerStyle = excel_lib.CellStyle(
      bold: true,
      fontColorHex: excel_lib.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: excel_lib.ExcelColor.fromHexString('#1E88E5'),
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Write header row
    final txHeaders = ['Date', 'Category', 'Type', 'Amount', 'Note'];
    for (var col = 0; col < txHeaders.length; col++) {
      final cell = txSheet.cell(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = excel_lib.TextCellValue(txHeaders[col]);
      cell.cellStyle = headerStyle;
    }

    // Write transaction rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var i = 0; i < filtered.length; i++) {
      final tx = filtered[i];
      final row = i + 1; // Row 0 is header
      final categoryName = categoryMap[tx.categoryId]?.name ?? 'Unknown';
      final typeLabel =
          tx.type == TransactionType.income ? 'Income' : 'Expense';

      txSheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: row))
          .value = excel_lib.TextCellValue(dateFormat.format(tx.date));
      txSheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: row))
          .value = excel_lib.TextCellValue(categoryName);
      txSheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: row))
          .value = excel_lib.TextCellValue(typeLabel);
      txSheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: row))
          .value = excel_lib.DoubleCellValue(tx.amount);
      txSheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 4, rowIndex: row))
          .value = excel_lib.TextCellValue(tx.note.isEmpty ? '—' : tx.note);
    }

    // Set column widths for readability
    txSheet.setColumnWidth(0, 15); // Date
    txSheet.setColumnWidth(1, 20); // Category
    txSheet.setColumnWidth(2, 10); // Type
    txSheet.setColumnWidth(3, 15); // Amount
    txSheet.setColumnWidth(4, 30); // Note

    // ── Sheet 2: Summary ──
    const summarySheetName = 'Summary';
    final summarySheet = workbook[summarySheetName];

    // Title
    summarySheet
        .cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = excel_lib.TextCellValue(
          'Expense Report — ${_monthName(month)} $year',
        );
    summarySheet
        .cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
          bold: true,
          fontSize: 14,
        );

    // Overall totals
    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    var summaryRow = 2;
    _writeExcelRow(summarySheet, summaryRow++, ['Total Income', totalIncome],
        isBold: true);
    _writeExcelRow(summarySheet, summaryRow++, ['Total Expense', totalExpense],
        isBold: true);
    _writeExcelRow(summarySheet, summaryRow++, ['Net Balance', balance],
        isBold: true);

    summaryRow++; // Blank row

    // Category-wise breakdown header
    final breakdownHeaders = ['Category', 'Total Amount', 'Percentage'];
    for (var col = 0; col < breakdownHeaders.length; col++) {
      final cell = summarySheet.cell(
        excel_lib.CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: summaryRow),
      );
      cell.value = excel_lib.TextCellValue(breakdownHeaders[col]);
      cell.cellStyle = headerStyle;
    }
    summaryRow++;

    // Category totals
    final categoryTotals = <String, double>{};
    for (final tx in filtered) {
      final catName = categoryMap[tx.categoryId]?.name ?? 'Unknown';
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;
    }

    final grandTotal =
        categoryTotals.values.fold<double>(0, (sum, v) => sum + v);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final percent =
          grandTotal > 0 ? (entry.value / grandTotal * 100) : 0.0;
      summarySheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: summaryRow))
          .value = excel_lib.TextCellValue(entry.key);
      summarySheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: summaryRow))
          .value = excel_lib.DoubleCellValue(entry.value);
      summarySheet
          .cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: summaryRow))
          .value = excel_lib.TextCellValue('${percent.toStringAsFixed(1)}%');
      summaryRow++;
    }

    // Grand total row
    _writeExcelRow(
      summarySheet,
      summaryRow,
      ['Grand Total', grandTotal, '100%'],
      isBold: true,
    );

    summarySheet.setColumnWidth(0, 25);
    summarySheet.setColumnWidth(1, 18);
    summarySheet.setColumnWidth(2, 15);

    // Encode workbook
    final encoded = workbook.encode();
    if (encoded == null) {
      throw Exception('ExportService: Failed to encode Excel workbook');
    }
    final bytes = Uint8List.fromList(encoded);
    debugPrint('ExportService: Excel generated (${bytes.length} bytes)');
    return bytes;
  }

  /// Helper to write a row of mixed values to an Excel sheet.
  void _writeExcelRow(
    excel_lib.Sheet sheet,
    int rowIndex,
    List<dynamic> values, {
    bool isBold = false,
  }) {
    for (var col = 0; col < values.length; col++) {
      final cell = sheet.cell(
        excel_lib.CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: rowIndex),
      );

      final value = values[col];
      if (value is double) {
        cell.value = excel_lib.DoubleCellValue(value);
      } else {
        cell.value = excel_lib.TextCellValue(value.toString());
      }

      if (isBold) {
        cell.cellStyle = excel_lib.CellStyle(bold: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Sharing & Preview
  // ---------------------------------------------------------------------------

  /// Save bytes to a temporary file and share it via the system share sheet.
  ///
  /// [bytes]    — the file content to share.
  /// [fileName] — desired file name (e.g., `report_june_2026.pdf`).
  /// [mimeType] — MIME type for the share intent (e.g., `application/pdf`).
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Expense Tracker Report',
      );

      debugPrint('ExportService: Shared file "$fileName"');
    } catch (e) {
      debugPrint('ExportService: Error sharing file — $e');
      rethrow;
    }
  }

  /// Preview a PDF document using the system print/preview dialog.
  ///
  /// [bytes] — raw PDF data to preview.
  Future<void> previewPdf(Uint8List bytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Expense Report',
      );
      debugPrint('ExportService: PDF preview launched');
    } catch (e) {
      debugPrint('ExportService: Error previewing PDF — $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Convert a month number (1-12) to its full name.
  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}
