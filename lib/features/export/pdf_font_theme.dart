import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

const pdfRegularFontAsset = 'assets/fonts/Roboto-Regular.ttf';
const pdfBoldFontAsset = 'assets/fonts/Roboto-Bold.ttf';

/// Loads the embedded fonts used by every generated PDF.
///
/// The `pdf` package defaults to the 14 built-in PDF fonts, including
/// Helvetica. Those fonts do not contain extended Unicode glyphs and emit
/// warnings or render replacement glyphs for names such as `José` or `Ñ`. A
/// document theme makes the embedded fonts the default for styles that do not
/// explicitly provide a font.
Future<pw.ThemeData> loadPdfTheme() async {
  final regularData = await rootBundle.load(pdfRegularFontAsset);
  final boldData = await rootBundle.load(pdfBoldFontAsset);
  final regular = pw.Font.ttf(regularData);
  final bold = pw.Font.ttf(boldData);

  return pw.ThemeData.withFont(
    base: regular,
    bold: bold,
    italic: regular,
    boldItalic: bold,
  );
}
