import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

import 'export_package_writer.dart';
import 'pdf_report_service.dart';

abstract class PdfReportWriter {
  Future<ExportWriteResult> save(PdfReportFile report);
}

class FilePickerPdfReportWriter implements PdfReportWriter {
  const FilePickerPdfReportWriter();

  @override
  Future<ExportWriteResult> save(PdfReportFile report) async {
    final fileName = p.posix.basename(report.path);
    final destination = await FilePicker.saveFile(
      fileName: fileName,
      bytes: report.bytes,
      mimeType: 'application/pdf',
    );
    return ExportWriteResult(
      fileName: fileName,
      bytes: report.bytes,
      byteLength: report.byteLength,
      checksum: report.checksum,
      destinationUri: destination,
    );
  }
}

abstract class PdfReportDispatcher {
  Future<void> share(PdfReportFile report);

  Future<void> print(PdfReportFile report);
}

class PrintingPdfReportDispatcher implements PdfReportDispatcher {
  const PrintingPdfReportDispatcher();

  @override
  Future<void> share(PdfReportFile report) async {
    await Printing.sharePdf(
      bytes: report.bytes,
      filename: p.posix.basename(report.path),
    );
  }

  @override
  Future<void> print(PdfReportFile report) async {
    await Printing.layoutPdf(onLayout: (_) async => report.bytes);
  }
}
