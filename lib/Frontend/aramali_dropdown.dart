import 'package:dropdown_button2/dropdown_button2.dart';
export 'package:dropdown_button2/dropdown_button2.dart'
    show
        ButtonStyleData,
        IconStyleData,
        DropdownStyleData,
        MenuItemStyleData,
        DropdownSearchData;
import 'package:flutter/material.dart';

/// Uygulama genelinde kullanilan ortak "aranabilir" dropdown bilesenleri.
///
/// Iki wrapper sunar:
///  - [AramaliDropdown]          -> `DropdownButtonHideUnderline(child: DropdownButton2(...))`
///                                  ve duz `DropdownButton(...)` kullanimlarinin yerine gecer.
///  - [AramaliDropdownFormField] -> `DropdownButtonFormField(...)` (InputDecoration'li)
///                                  kullanimlarinin yerine gecer.
///
/// Oge sayisi [kAramaEsigi] ve uzerindeyse menu acildiginda ustte bir arama
/// kutusu belirir; daha kisa listelerde (Cinsiyet, Evet/Hayir gibi) arama kutusu
/// gizli kalir. Arama, varsayilan olarak her ogenin gorunen metni (Text child)
/// uzerinden yapilir; ozel bir metin gerekiyorsa [searchText] verilebilir.
///
/// Standart `DropdownButton`/`DropdownButtonFormField` paramlari (icon, iconSize,
/// dropdownColor, menuMaxHeight, elevation, borderRadius, itemHeight) da kolayca
/// gecirilebilir; bunlar otomatik olarak DropdownButton2 StyleData nesnelerine
/// donusturulur. Ayrica *StyleData nesneleri dogrudan verilirse onlar kullanilir.

/// Arama kutusunun gorunmeye baslayacagi minimum oge sayisi.
const int kAramaEsigi = 8;

/// Bir [DropdownMenuItem] child widget agacindan aranabilir metni cikarir.
/// Text / Row / Column / Padding / Container gibi yaygin sarmalayicilar icinde
/// gezinerek ilk anlamli metni toplar.
String _widgettanMetin(Widget? widget) {
  if (widget == null) return '';
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }
  if (widget is Flexible) return _widgettanMetin(widget.child);
  if (widget is Padding) return _widgettanMetin(widget.child);
  if (widget is Align) return _widgettanMetin(widget.child);
  if (widget is Center) return _widgettanMetin(widget.child);
  if (widget is SizedBox) return _widgettanMetin(widget.child);
  if (widget is Container) return _widgettanMetin(widget.child);
  if (widget is DecoratedBox) return _widgettanMetin(widget.child);
  if (widget is Tooltip) return _widgettanMetin(widget.child);
  if (widget is Row) {
    return widget.children.map(_widgettanMetin).where((e) => e.isNotEmpty).join(' ');
  }
  if (widget is Column) {
    return widget.children.map(_widgettanMetin).where((e) => e.isNotEmpty).join(' ');
  }
  if (widget is Wrap) {
    return widget.children.map(_widgettanMetin).where((e) => e.isNotEmpty).join(' ');
  }
  return '';
}

/// Menü içindeki arama kutusunu (TextField) olusturur.
Widget _aramaKutusu(BuildContext context, TextEditingController controller) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4, left: 8, right: 8),
    child: TextFormField(
      controller: controller,
      expands: false,
      autofocus: false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: 'Ara...',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              splashRadius: 18,
              onPressed: controller.clear,
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
    ),
  );
}

/// [items] uzunlugu esige ulastiysa arama verisini olusturur, aksi halde null.
DropdownSearchData<T>? _aramaVerisi<T>({
  required BuildContext context,
  required List<DropdownMenuItem<T>>? items,
  required TextEditingController controller,
  required int esik,
  String Function(T value)? searchText,
}) {
  if (items == null || items.length < esik) return null;
  return DropdownSearchData<T>(
    searchController: controller,
    searchInnerWidgetHeight: 56,
    searchInnerWidget: _aramaKutusu(context, controller),
    searchMatchFn: (item, aranan) {
      final q = aranan.trim().toLowerCase();
      if (q.isEmpty) return true;
      final metin = searchText != null && item.value != null
          ? searchText(item.value as T)
          : _widgettanMetin(item.child);
      return metin.toLowerCase().contains(q);
    },
  );
}

// --- Standart DropdownButton paramlarini StyleData'ya cevirme yardimcilari ---

IconStyleData _iconStyle(
    IconStyleData? given, Widget? icon, double? iconSize, Color? enabled, Color? disabled) {
  if (given != null) return given;
  if (icon == null && iconSize == null && enabled == null && disabled == null) {
    return const IconStyleData();
  }
  return IconStyleData(
    icon: icon ?? const Icon(Icons.arrow_drop_down),
    iconSize: iconSize ?? 24,
    iconEnabledColor: enabled,
    iconDisabledColor: disabled,
  );
}

DropdownStyleData _dropdownStyle(DropdownStyleData? given, int? elevation, Color? color,
    double? maxHeight, BorderRadius? radius) {
  if (given != null) return given;
  if (elevation == null && color == null && maxHeight == null && radius == null) {
    return const DropdownStyleData();
  }
  return DropdownStyleData(
    maxHeight: maxHeight,
    elevation: elevation ?? 8,
    decoration: (color != null || radius != null)
        ? BoxDecoration(color: color, borderRadius: radius ?? BorderRadius.circular(4))
        : null,
  );
}

MenuItemStyleData _menuItemStyle(
    MenuItemStyleData? given, double? height, EdgeInsetsGeometry? padding) {
  if (given != null) return given;
  if (height == null && padding == null) return const MenuItemStyleData();
  if (height == null) return MenuItemStyleData(padding: padding);
  return MenuItemStyleData(height: height, padding: padding);
}

/// `DropdownButtonHideUnderline(child: DropdownButton2(...))` ve duz
/// `DropdownButton(...)` yerine kullanilir. Arama otomatik eklenir.
class AramaliDropdown<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final bool isExpanded;
  final bool isDense;
  final TextStyle? style;
  final Widget? underline;
  final Widget? customButton;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final AlignmentGeometry alignment;

  // Dogrudan StyleData nesneleri (verilirse asagidaki kisayollara oncelikli).
  final ButtonStyleData? buttonStyleData;
  final IconStyleData? iconStyleData;
  final DropdownStyleData? dropdownStyleData;
  final MenuItemStyleData? menuItemStyleData;

  // Standart DropdownButton kisayol paramlari (StyleData'ya cevrilir).
  final Widget? icon;
  final double? iconSize;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final int? elevation;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final double? itemHeight;
  final EdgeInsetsGeometry? itemPadding;

  final DropdownSearchData<T>? dropdownSearchData;
  final OnMenuStateChangeFn? onMenuStateChange;

  /// Arama kutusunun gorunecegi minimum oge sayisi (varsayilan [kAramaEsigi]).
  final int aramaEsigi;

  /// Her oge icin ozel arama metni. Verilmezse ogenin gorunen metni kullanilir.
  final String Function(T value)? searchText;

  const AramaliDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.disabledHint,
    this.isExpanded = true,
    this.isDense = true,
    this.style,
    this.underline,
    this.customButton,
    this.selectedItemBuilder,
    this.alignment = AlignmentDirectional.centerStart,
    this.buttonStyleData,
    this.iconStyleData,
    this.dropdownStyleData,
    this.menuItemStyleData,
    this.icon,
    this.iconSize,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.elevation,
    this.dropdownColor,
    this.menuMaxHeight,
    this.borderRadius,
    this.itemHeight,
    this.itemPadding,
    this.dropdownSearchData,
    this.onMenuStateChange,
    this.aramaEsigi = kAramaEsigi,
    this.searchText,
  });

  @override
  State<AramaliDropdown<T>> createState() => _AramaliDropdownState<T>();
}

class _AramaliDropdownState<T> extends State<AramaliDropdown<T>> {
  final TextEditingController _aramaController = TextEditingController();

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aramaVerisi = widget.dropdownSearchData ??
        _aramaVerisi<T>(
          context: context,
          items: widget.items,
          controller: _aramaController,
          esik: widget.aramaEsigi,
          searchText: widget.searchText,
        );

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: widget.isExpanded,
        isDense: widget.isDense,
        hint: widget.hint,
        disabledHint: widget.disabledHint,
        value: widget.value,
        items: widget.items,
        onChanged: widget.onChanged,
        style: widget.style,
        underline: widget.underline,
        customButton: widget.customButton,
        selectedItemBuilder: widget.selectedItemBuilder,
        alignment: widget.alignment,
        buttonStyleData: widget.buttonStyleData,
        iconStyleData: _iconStyle(widget.iconStyleData, widget.icon, widget.iconSize,
            widget.iconEnabledColor, widget.iconDisabledColor),
        dropdownStyleData: _dropdownStyle(widget.dropdownStyleData, widget.elevation,
            widget.dropdownColor, widget.menuMaxHeight, widget.borderRadius),
        menuItemStyleData:
            _menuItemStyle(widget.menuItemStyleData, widget.itemHeight, widget.itemPadding),
        dropdownSearchData: aramaVerisi,
        onMenuStateChange: (acik) {
          if (!acik) _aramaController.clear();
          widget.onMenuStateChange?.call(acik);
        },
      ),
    );
  }
}

/// `DropdownButtonFormField(...)` yerine kullanilir. InputDecoration destekler,
/// FormField oldugu icin validator ile calisir ve arama otomatik eklenir.
class AramaliDropdownFormField<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final bool isExpanded;
  final bool isDense;
  final TextStyle? style;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final AlignmentGeometry alignment;

  final ButtonStyleData? buttonStyleData;
  final IconStyleData? iconStyleData;
  final DropdownStyleData? dropdownStyleData;
  final MenuItemStyleData? menuItemStyleData;

  final Widget? icon;
  final double? iconSize;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final int? elevation;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final double? itemHeight;
  final EdgeInsetsGeometry? itemPadding;

  final DropdownSearchData<T>? dropdownSearchData;
  final OnMenuStateChangeFn? onMenuStateChange;
  final int aramaEsigi;
  final String Function(T value)? searchText;

  const AramaliDropdownFormField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.disabledHint,
    this.isExpanded = true,
    this.isDense = true,
    this.style,
    this.decoration,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.selectedItemBuilder,
    this.alignment = AlignmentDirectional.centerStart,
    this.buttonStyleData,
    this.iconStyleData,
    this.dropdownStyleData,
    this.menuItemStyleData,
    this.icon,
    this.iconSize,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.elevation,
    this.dropdownColor,
    this.menuMaxHeight,
    this.borderRadius,
    this.itemHeight,
    this.itemPadding,
    this.dropdownSearchData,
    this.onMenuStateChange,
    this.aramaEsigi = kAramaEsigi,
    this.searchText,
  });

  @override
  State<AramaliDropdownFormField<T>> createState() =>
      _AramaliDropdownFormFieldState<T>();
}

class _AramaliDropdownFormFieldState<T>
    extends State<AramaliDropdownFormField<T>> {
  final TextEditingController _aramaController = TextEditingController();

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aramaVerisi = widget.dropdownSearchData ??
        _aramaVerisi<T>(
          context: context,
          items: widget.items,
          controller: _aramaController,
          esik: widget.aramaEsigi,
          searchText: widget.searchText,
        );

    return DropdownButtonFormField2<T>(
      isExpanded: widget.isExpanded,
      isDense: widget.isDense,
      hint: widget.hint,
      disabledHint: widget.disabledHint,
      value: widget.value,
      items: widget.items,
      onChanged: widget.onChanged,
      style: widget.style,
      decoration: widget.decoration ?? const InputDecoration(),
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      selectedItemBuilder: widget.selectedItemBuilder,
      alignment: widget.alignment,
      buttonStyleData: widget.buttonStyleData,
      iconStyleData: _iconStyle(widget.iconStyleData, widget.icon, widget.iconSize,
          widget.iconEnabledColor, widget.iconDisabledColor),
      dropdownStyleData: _dropdownStyle(widget.dropdownStyleData, widget.elevation,
          widget.dropdownColor, widget.menuMaxHeight, widget.borderRadius),
      menuItemStyleData:
          _menuItemStyle(widget.menuItemStyleData, widget.itemHeight, widget.itemPadding),
      dropdownSearchData: aramaVerisi,
      onMenuStateChange: (acik) {
        if (!acik) _aramaController.clear();
        widget.onMenuStateChange?.call(acik);
      },
    );
  }
}
