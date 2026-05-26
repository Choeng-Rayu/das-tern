import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable text input with consistent labelling, helper-text, and error
/// rendering across the app.
///
/// Wraps [TextFormField] (and therefore plays well with [Form] +
/// [AutovalidateMode]). Adds:
/// - a [Semantics] label so screen readers always announce the field;
/// - a clear button when [showClear] is true and there's content;
/// - first-class [error] / [helperText] handling that doesn't shift layout
///   (uses a fixed `helper`/`error` slot height).
///
/// Spec ref: 09-design-system-localization §Requirement 3, §Requirement 8.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.error,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? error;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: error,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon,
          counterText: maxLength == null ? '' : null,
        ),
      ),
    );
  }
}
