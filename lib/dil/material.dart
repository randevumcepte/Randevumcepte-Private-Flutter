// Müşteri ekranlarının kullandığı Material: 'package:flutter/material.dart' ile aynı; farkı Text, TextSpan ve
// InputDecoration metinlerinin seçili dile çevrilmesi (Dil). Türkçede birebir eski davranış.
export 'package:flutter/material.dart' hide Text, TextSpan, InputDecoration;

import 'package:flutter/material.dart' as m;

import 'dil.dart';

class Text extends m.Text {
  const Text(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  const Text.rich(
    super.textSpan, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : super.rich();

  @override
  String? get data {
    final s = super.data;
    return s == null ? null : Dil.cevir(s);
  }
}

class TextSpan extends m.TextSpan {
  const TextSpan({
    super.text,
    super.children,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.locale,
    super.spellOut,
  });

  @override
  String? get text {
    final s = super.text;
    return s == null ? null : Dil.cevir(s);
  }
}

class InputDecoration extends m.InputDecoration {
  const InputDecoration({
    super.icon,
    super.iconColor,
    super.label,
    super.labelText,
    super.labelStyle,
    super.floatingLabelStyle,
    super.helper,
    super.helperText,
    super.helperStyle,
    super.helperMaxLines,
    super.hintText,
    super.hint,
    super.hintStyle,
    super.hintTextDirection,
    super.hintMaxLines,
    super.hintFadeDuration,
    super.maintainHintSize,
    super.maintainLabelSize,
    super.error,
    super.errorText,
    super.errorStyle,
    super.errorMaxLines,
    super.floatingLabelBehavior,
    super.floatingLabelAlignment,
    super.isCollapsed,
    super.isDense,
    super.contentPadding,
    super.prefixIcon,
    super.prefixIconConstraints,
    super.prefix,
    super.prefixText,
    super.prefixStyle,
    super.prefixIconColor,
    super.suffixIcon,
    super.suffix,
    super.suffixText,
    super.suffixStyle,
    super.suffixIconColor,
    super.suffixIconConstraints,
    super.counter,
    super.counterText,
    super.counterStyle,
    super.filled,
    super.fillColor,
    super.focusColor,
    super.hoverColor,
    super.errorBorder,
    super.focusedBorder,
    super.focusedErrorBorder,
    super.disabledBorder,
    super.enabledBorder,
    super.border,
    super.enabled,
    super.semanticCounterText,
    super.alignLabelWithHint,
    super.constraints,
    super.visualDensity,
  });

  const InputDecoration.collapsed({
    required super.hintText,
    super.hintStyle,
    super.hint,
    super.hintTextDirection,
    super.hintMaxLines,
    super.hintFadeDuration,
    super.maintainHintSize,
    super.maintainLabelSize,
    super.filled,
    super.fillColor,
    super.focusColor,
    super.hoverColor,
    super.border,
    super.enabled,
    super.constraints,
  }) : super.collapsed();

  static String? _c(String? s) => s == null ? null : Dil.cevir(s);

  @override
  String? get labelText => _c(super.labelText);
  @override
  String? get hintText => _c(super.hintText);
  @override
  String? get helperText => _c(super.helperText);
  @override
  String? get errorText => _c(super.errorText);
  @override
  String? get counterText => _c(super.counterText);
}
