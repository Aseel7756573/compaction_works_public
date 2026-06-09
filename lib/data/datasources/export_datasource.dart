
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/color_system.dart';
import '../../core/utils/compaction_model.dart';
import '../../core/utils/unit_system.dart';
import '../../domain/entities/compaction_point.dart';

class ExportDatasource {

  
  
  
  Future<String> exportExcel({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) async {
    final excel = Excel.createExcel();

    
    final dataSheet = excel['بيانات الدمك'];
    excel.setDefaultSheet('بيانات الدمك');

    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#1f6feb'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = [
      'رقم النقطة', 'خط العرض', 'خط الطول',
      'عدد الدورات', 'الرطوبة الحقلية %', 'معامل الدمك %',
      'الحالة', 'دقة GPS (م)', 'الوقت',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int r = 0; r < points.length; r++) {
      final p = points[r];
      final rowData = [
        p.pointId,
        p.latitude.toStringAsFixed(7),
        p.longitude.toStringAsFixed(7),
        p.passes.toString(),
        p.moistureField.toStringAsFixed(1),
        p.compactionPercent.toStringAsFixed(2),
        _statusLabel(p.statusType),
        p.accuracyM.toStringAsFixed(1),
        DateFormat('HH:mm:ss').format(p.timestamp),
      ];

      final color = CompactionColorSystem.getColor(p.compactionPercent);
      final hex = _colorToHex(color);

      for (int c = 0; c < rowData.length; c++) {
        final cell = dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(rowData[c]);
        if (c == 5) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('#$hex'),
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }
    }

    
    final summarySheet = excel['ملخص المشروع'];
    final summaryData = [
      ['اسم المشروع', meta.name],
      ['الموقع', meta.location],
      ['المهندس', meta.engineer],
      ['الجهة المشرفة', meta.supervisor],
      ['الجهة المنفذة', meta.contractor],
      ['مرحلة العمل', meta.stage],
      ['رقم الطبقة', meta.layerNo.toString()],
      ['التاريخ', DateFormat('yyyy-MM-dd').format(DateTime.now())],
      ['', ''],
      ['أقصى كثافة معملية', unitSystem.formatDensity(calibration.maxDryDensityGcm3)],
      ['المحتوى الرطوبي الأمثل (OMC)', '${calibration.omc.toStringAsFixed(1)}%'],
      ['معامل الدمك الأولي', '${calibration.initialCompaction.toStringAsFixed(1)}%'],
      ['معامل الدمك النهائي', '${calibration.finalCompaction.toStringAsFixed(1)}%'],
      ['الرطوبة قبل الدمك', '${calibration.moistureBefore.toStringAsFixed(1)}%'],
      ['الرطوبة بعد الدمك', '${calibration.moistureAfter.toStringAsFixed(1)}%'],
      ['عدد الدورات المرجعية', calibration.refPasses.toString()],
      ['كفاءة المعدة', calibration.equipmentEfficiency.toStringAsFixed(2)],
      ['', ''],
      ['إجمالي النقاط', points.length.toString()],
      ['المتوسط', '${_avg(points).toStringAsFixed(2)}%'],
      ['الأعلى', '${_max(points).toStringAsFixed(2)}%'],
      ['الأدنى', '${_min(points).toStringAsFixed(2)}%'],
      ['نقاط مقبولة', points.where((p) => p.statusType == 'good').length.toString()],
      ['نقاط غير مقبولة', points.where((p) => p.statusType == 'poor').length.toString()],
      ['نقاط دمك مفرط', points.where((p) => p.statusType == 'over').length.toString()],
    ];

    for (int i = 0; i < summaryData.length; i++) {
      for (int j = 0; j < summaryData[i].length; j++) {
        final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i));
        cell.value = TextCellValue(summaryData[i][j]);
        if (j == 0 && summaryData[i][0].isNotEmpty) {
          cell.cellStyle = CellStyle(bold: true);
        }
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/FMA_${meta.projectId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final bytes = excel.encode();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
    }
    return path;
  }

  
  
  
  Future<String> exportPdf({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) async {
    
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont    = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    
    pw.TextStyle ar({
      double size = 10,
      bool bold = false,
      PdfColor? color,
    }) =>
        pw.TextStyle(
          font: bold ? boldFont : regularFont,
          fontSize: size,
          color: color,
        );

    pw.Widget arText(String text, {double size = 10, bool bold = false, PdfColor? color}) =>
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(text, style: ar(size: size, bold: bold, color: color)),
        );

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final pdf = pw.Document(theme: theme);

    
    
    
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(2 * PdfPageFormat.cm),
      theme: theme,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1565C0'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('FMA Compaction Analyzer Pro',
                    style: pw.TextStyle(
                      font: boldFont, fontSize: 20, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                arText('تقرير إشرافي تقني معتمد',
                    size: 13, bold: true, color: PdfColors.white),
                pw.SizedBox(height: 4),
                pw.Text(dateStr,
                    style: ar(size: 10, color: const PdfColor(1, 1, 1, 0.7))),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          _arSection('بيانات المشروع', boldFont),
          pw.SizedBox(height: 6),
          _arTable([
            ['اسم المشروع', meta.name,         'الموقع',           meta.location],
            ['المهندس',     meta.engineer,      'الجهة المشرفة',    meta.supervisor],
            ['الجهة المنفذة', meta.contractor,  'مرحلة العمل',      meta.stage],
            ['رقم الطبقة',  meta.layerNo.toString(), 'التاريخ',    dateStr],
          ], regularFont, boldFont),
          pw.SizedBox(height: 14),

          _arSection('بيانات المعايرة المرجعية', boldFont),
          pw.SizedBox(height: 6),
          _arTable([
            ['أقصى كثافة معملية', unitSystem.formatDensity(calibration.maxDryDensityGcm3),
             'OMC', '${calibration.omc}%'],
            ['دمك أولي', '${calibration.initialCompaction}%',
             'دمك نهائي', '${calibration.finalCompaction}%'],
            ['رطوبة قبل', '${calibration.moistureBefore}%',
             'رطوبة بعد', '${calibration.moistureAfter}%'],
            ['دورات مرجعية', calibration.refPasses.toString(),
             'كفاءة المعدة', calibration.equipmentEfficiency.toString()],
            ['نوع التربة', calibration.soilType,
             'الهدف الأدنى', '${calibration.targetMin}%'],
          ], regularFont, boldFont),
          pw.SizedBox(height: 14),

          _arSection('ملخص النتائج', boldFont),
          pw.SizedBox(height: 6),
          _buildStatsTable(points, regularFont, boldFont),
        ],
      ),
    ));

    
    
    
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(1.5 * PdfPageFormat.cm),
      theme: theme,
      build: (ctx) => [
        _arSection('جدول البيانات التفصيلي', boldFont),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(45),
            1: const pw.FixedColumnWidth(62),
            2: const pw.FixedColumnWidth(62),
            3: const pw.FixedColumnWidth(38),
            4: const pw.FixedColumnWidth(42),
            5: const pw.FixedColumnWidth(40),
            6: const pw.FlexColumnWidth(),
          },
          children: [
            
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1565C0)),
              children: [
                'رقم النقطة', 'خط العرض', 'خط الطول',
                'الدورات', 'الرطوبة%', 'الدمك%', 'الحالة',
              ].map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4, vertical: 5),
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          font: boldFont,
                          color: PdfColors.white,
                          fontSize: 8)),
                ),
              )).toList(),
            ),
            
            ...points.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final rowBg = i.isEven ? PdfColors.grey50 : PdfColors.white;
              final compColor = _pdfColorFromHex(
                  '#${_colorToHex(CompactionColorSystem.getColor(p.compactionPercent))}');
              final cells = [
                p.pointId,
                p.latitude.toStringAsFixed(6),
                p.longitude.toStringAsFixed(6),
                p.passes.toString(),
                p.moistureField.toStringAsFixed(1),
                p.compactionPercent.toStringAsFixed(2),
                _statusLabel(p.statusType),
              ];
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rowBg),
                children: cells.asMap().entries.map((e) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  color: e.key == 5 ? compColor : null,
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(e.value,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 7.5,
                          color: e.key == 5
                              ? PdfColors.white
                              : PdfColors.black,
                        )),
                  ),
                )).toList(),
              );
            }),
          ],
        ),
        pw.SizedBox(height: 20),

        
        _arSection('مفتاح الألوان — 11 تدرج', boldFont),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 4,
          runSpacing: 4,
          children: CompactionColorSystem.ranges.map((r) {
            final hex = _colorToHex(r.color);
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _pdfColorFromHex('#$hex'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(r.label,
                    style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 7,
                        color: PdfColors.white)),
              ),
            );
          }).toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            'تم إنشاء هذا التقرير بواسطة FMA Compaction Analyzer Pro v5.0 | $dateStr',
            style: pw.TextStyle(
                font: regularFont, fontSize: 8, color: PdfColors.grey),
          ),
        ),
      ],
    ));

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/FMA_${meta.projectId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final bytes = await pdf.save();
    await File(path).writeAsBytes(bytes);
    return path;
  }

  

  pw.Widget _arSection(String title, pw.Font boldFont) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#E3F2FD'),
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(
              color: PdfColor.fromHex('#1565C0'), width: 0.8),
        ),
        child: pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: PdfColor.fromHex('#1565C0'),
              )),
        ),
      );

  pw.Widget _arTable(
    List<List<String>> rows,
    pw.Font regularFont,
    pw.Font boldFont,
  ) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: rows.map((row) => pw.TableRow(
          children: row.asMap().entries.map((e) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                e.value,
                style: pw.TextStyle(
                  font: e.key.isEven ? boldFont : regularFont,
                  fontSize: 9,
                  color: e.key.isEven
                      ? PdfColor.fromHex('#1565C0')
                      : PdfColors.black,
                ),
              ),
            ),
          )).toList(),
        )).toList(),
      );

  pw.Widget _buildStatsTable(
    List<CompactionPoint> points,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final n    = points.length;
    final good = points.where((p) => p.statusType == 'good').length;
    final poor = points.where((p) => p.statusType == 'poor').length;
    final over = points.where((p) => p.statusType == 'over').length;
    return _arTable([
      ['إجمالي النقاط', n.toString(),
       'المتوسط', '${_avg(points).toStringAsFixed(2)}%'],
      ['الأعلى', '${_max(points).toStringAsFixed(2)}%',
       'الأدنى', '${_min(points).toStringAsFixed(2)}%'],
      ['مقبول (>=95%)',
       '$good (${(good / n.clamp(1, 999999) * 100).toStringAsFixed(1)}%)',
       'غير مقبول',
       '$poor (${(poor / n.clamp(1, 999999) * 100).toStringAsFixed(1)}%)'],
      ['دمك مفرط',
       '$over (${(over / n.clamp(1, 999999) * 100).toStringAsFixed(1)}%)',
       'معدل الاجتياز',
       '${(good / n.clamp(1, 999999) * 100).toStringAsFixed(1)}%'],
    ], regularFont, boldFont);
  }

  
  double _avg(List<CompactionPoint> pts) =>
      pts.isEmpty ? 0 : pts.map((p) => p.compactionPercent).reduce((a, b) => a + b) / pts.length;
  double _max(List<CompactionPoint> pts) =>
      pts.isEmpty ? 0 : pts.map((p) => p.compactionPercent).reduce((a, b) => a > b ? a : b);
  double _min(List<CompactionPoint> pts) =>
      pts.isEmpty ? 0 : pts.map((p) => p.compactionPercent).reduce((a, b) => a < b ? a : b);

  String _statusLabel(String type) {
    switch (type) {
      case 'good':  return 'مقبول';
      case 'poor':  return 'غير مقبول';
      case 'over':  return 'مفرط';
      default:      return type;
    }
  }

  String _colorToHex(dynamic color) {
    final value = color.value as int;
    return (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  PdfColor _pdfColorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
    final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
    final b = int.parse(hex.substring(4, 6), radix: 16) / 255;
    return PdfColor(r, g, b);
  }
}
