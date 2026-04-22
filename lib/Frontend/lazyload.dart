import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/MusteriDanisanSecimLazyLoad.dart';
import '../Models/musteri_danisanlar.dart';

class LazyDropdown extends StatefulWidget {
  final String salonId;
  final MusteriDanisan? selectedItem;
  final void Function(MusteriDanisan?)? onChanged;

  const LazyDropdown({
    required this.salonId,
    this.selectedItem,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  LazyDropdownState createState() => LazyDropdownState();
}

class LazyDropdownState extends State<LazyDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();

  List<MusteriDanisan> items = [];
  bool isLoading = false;
  bool hasMore = true;
  int offset = 0;
  final int limit = 50;

  MusteriDanisan? selectedItem;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItem;
    fetchMore();


    scrollController.addListener(() {
    if (scrollController.position.pixels >=
    scrollController.position.maxScrollExtent - 50 &&
    !isLoading &&
    hasMore) {
    fetchMore();
    }
    });


  }
  @override
  void didUpdateWidget(covariant LazyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedItem != widget.selectedItem) {
      setState(() {
        selectedItem = widget.selectedItem;
      });
    }
  }
  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> fetchMore() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final result = await MusteriDanisanSecimLazyLoad.fetch(
    seciliMusteri: selectedItem?.id ?? '',
    salonId: widget.salonId,
    search: searchController.text,
    offset: offset,
    limit: limit,
    );

    setState(() {
    if (offset == 0) items = result;
    else items.addAll(result);

    offset += limit;
    isLoading = false;
    if (result.length < limit) hasMore = false;
    });

    _overlayEntry?.markNeedsBuild();


  }

  void toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
    builder: (context) => Positioned(
    width: size.width,
    child: CompositedTransformFollower(
    link: _layerLink,
    showWhenUnlinked: false,
    offset: Offset(0.0, size.height + 0.0),
    child: Material(
    elevation: 0.0,
    child: Container(
    height: 300,
    color: Colors.white,
    child: Column(
    children: [
    Padding(
    padding:
    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: TextField(
    controller: searchController,
    decoration: InputDecoration(
    hintText: 'Müşteri Ara...',
    isDense: true,
    contentPadding:
    EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    border: OutlineInputBorder(),
    ),
    onChanged: (value) {
    offset = 0;
    items.clear();
    hasMore = true;
    fetchMore();
    },
    ),
    ),
    Expanded(
    child: items.isEmpty && !isLoading
    ? Center(child: Text('Veri bulunamadı'))
        : ListView.builder(
    controller: scrollController,
    padding: EdgeInsets.zero,
    itemCount: items.length + (hasMore ? 1 : 0),
    itemBuilder: (context, index) {
    if (index < items.length) {
    final item = items[index];
    return InkWell(
    onTap: () {
    setState(() {
    selectedItem = item;
    });
    widget.onChanged?.call(item);
    toggleDropdown();
    },
    child: Container(
    padding: EdgeInsets.symmetric(
    vertical: 10, horizontal: 10),
    child: Text(
    item.name,
    style: TextStyle(fontSize: 16),
    ),
    ),
    );
    } else {
    return Center(
    child: Padding(
    padding: EdgeInsets.all(8.0),
    child: CircularProgressIndicator(),
    ),
    );
    }
    },
    ),
    ),
    ],
    ),
    ),
    ),
    ),
    ),
    );


  }

// ✅ Yeni müşteri ekleyip seçme metodu
  void addItemAndSelect(MusteriDanisan newItem) {
    setState(() {
      items.insert(0, newItem); // listenin başına ekle
      selectedItem = newItem;
    });
    widget.onChanged?.call(newItem);
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: toggleDropdown,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedItem?.name ?? 'Müşteri Seçin'),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
