import 'package:flutter/material.dart';

/// A user-friendly form field for selecting and inputting dates.
///
/// Provides a [TextFormField] with formatted text input (YYYY-MM-DD),
/// a calendar icon button that opens Flutter's native [showDatePicker],
/// and a clear button for optional fields.
class AppDatePickerFormField extends StatelessWidget {
  const AppDatePickerFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.helperText = 'Select date or enter YYYY-MM-DD.',
    this.hintText = 'YYYY-MM-DD',
    this.validator,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.isEnabled = true,
    this.isRequired = true,
    this.pickerButtonKey,
    this.clearButtonKey,
    this.onDateSelected,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String? hintText;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final bool isEnabled;
  final bool isRequired;
  final Key? pickerButtonKey;
  final Key? clearButtonKey;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  static DateTime? parseIsoDate(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (match == null) {
      return null;
    }
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _openDatePicker(BuildContext context) async {
    if (!isEnabled) {
      return;
    }

    final effectiveFirstDate = firstDate ?? DateTime(2000, 1, 1);
    final effectiveLastDate = lastDate ?? DateTime(2100, 12, 31);

    final currentParsed = parseIsoDate(controller.text);
    var effectiveInitialDate =
        currentParsed ?? initialDate ?? DateTime.now();

    if (effectiveInitialDate.isBefore(effectiveFirstDate)) {
      effectiveInitialDate = effectiveFirstDate;
    } else if (effectiveInitialDate.isAfter(effectiveLastDate)) {
      effectiveInitialDate = effectiveLastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      helpText: 'Select $labelText',
    );

    if (picked != null) {
      final formatted = formatIsoDate(picked);
      controller.text = formatted;
      onDateSelected?.call(picked);
      onChanged?.call(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPickerKey = key is ValueKey<String>
        ? Key('${(key! as ValueKey<String>).value}PickerButton')
        : null;
    final defaultClearKey = key is ValueKey<String>
        ? Key('${(key! as ValueKey<String>).value}ClearButton')
        : null;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;
        final showClear = !isRequired && hasText && isEnabled;

        return TextFormField(
          controller: controller,
          enabled: isEnabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          keyboardType: TextInputType.datetime,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            helperText: helperText,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showClear)
                  IconButton(
                    key: clearButtonKey ?? defaultClearKey,
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: 'Clear $labelText',
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
                IconButton(
                  key: pickerButtonKey ?? defaultPickerKey,
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  tooltip: 'Select $labelText',
                  onPressed: isEnabled ? () => _openDatePicker(context) : null,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
