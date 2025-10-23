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
  _LazyDropdownState createState() => _LazyDropdownState();
}

class _LazyDropdownState extends State<LazyDropdown> {
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

    // Overlay rebuild
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
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              height: 300,
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Müşteri/Danışan Ara...',
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
                      itemCount: items.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < items.length) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.name),
                            onTap: () {
                              setState(() {
                                selectedItem = item;
                              });
                              if (widget.onChanged != null)
                                widget.onChanged!(item);
                              toggleDropdown();
                            },
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: toggleDropdown,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF6A1B9A)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedItem?.name ?? 'Müşteri/Danışan Seç'),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
