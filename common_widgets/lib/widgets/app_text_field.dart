import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_tokens.dart';
import '../core/responsive.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? prefixText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  /// Thin variant for compact surfaces (search bars): reduced vertical
  /// padding, dense layout, optional pill radius.
  final bool dense;

  /// Corner radius override (defaults to 10).
  final double radius;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.dense = false,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.fontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: Responsive.fontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: prefixIcon,
            prefixIconConstraints: dense
                ? const BoxConstraints(minWidth: 38, minHeight: 38)
                : null,
            suffixIcon: suffixIcon,
            counterText: '',
            isDense: dense,
            filled: true,
            fillColor: enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: EdgeInsets.symmetric(
              horizontal: dense ? 12 : Responsive.spacing(context, mobile: 16),
              vertical: dense ? 0 : Responsive.spacing(context, mobile: 14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterPressed;
  final Widget? trailing;

  const AppSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final searchInput = trailing == null
        ? AppTextField(
            hint: hint ?? 'Search jewellery',
            controller: controller,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            dense: true,
            radius: 20,
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: muted),
          )
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Icon(Icons.search_rounded, size: 18, color: muted),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: hint ?? 'Search jewellery',
                      // One box only: the outer Container above is the search
                      // box. The theme sets inputDecorationTheme.filled=true +
                      // a muted fillColor, so the inner TextField paints its
                      // own filled rounded rect nested inside the pill. Force
                      // it invisible; border variants are pinned to none as
                      // defence against any themed outline leaking in.
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                trailing!,
              ],
            ),
          );
    return Row(
      children: [
        Expanded(child: SizedBox(height: 40, child: searchInput)),
        if (onFilterPressed != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onFilterPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: Icon(
              Icons.tune,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool isExpanded;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: Responsive.fontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: isExpanded,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: AppPalette.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(color: AppPalette.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(color: AppPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
