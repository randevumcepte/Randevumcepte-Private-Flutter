import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

class YarinkiGorevler extends StatefulWidget {
  final dynamic isletmebilgi;
  YarinkiGorevler({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  _YarinkiGorevlerState createState() => _YarinkiGorevlerState();
}

class _YarinkiGorevlerState extends State<YarinkiGorevler> {
  TextEditingController _controller = TextEditingController();
  late EAsistanDataSource _easistanDataGridSource;
  late String? seciliisletme;
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    seciliisletme = await secilisalonid();
    DateTime today = DateTime.now();
    DateTime tomorrow = today.add(const Duration(days: 1));
    String tomorrowString = tomorrow.toString();
    setState(() {
      _easistanDataGridSource = EAsistanDataSource(
        isletmebilgi: widget.isletmebilgi,
        rowsPerPage: 10,
        salonid: seciliisletme!,
        context: context,
        bugunyarin: tomorrowString,
      );
      _easistanDataGridSource.isLoadingNotifier
          .addListener(_onLoadingStateChanged);
      _isLoading = false;
    });
  }

  void _onLoadingStateChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double calculateTextHeight(String text, double maxWidth, TextStyle style,
      {int maxLines = 3}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.height + 10;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Expanded(
            child: _easistanDataGridSource.rows.isEmpty
                ? _buildEmptyState(scheme)
                : PremiumGlassCard(
                    padding: EdgeInsets.zero,
                    child: SfDataGrid(
                      source: _easistanDataGridSource,
                      shrinkWrapRows: true,
                      columnWidthMode: ColumnWidthMode.fill,
                      defaultColumnWidth: 120,
                      allowSwiping: true,
                      headerRowHeight: 46,
                      gridLinesVisibility: GridLinesVisibility.none,
                      headerGridLinesVisibility: GridLinesVisibility.none,
                      onQueryRowHeight: (details) {
                        if (details.rowIndex == 0) {
                          return details.rowHeight;
                        }
                        final row = _easistanDataGridSource
                            .effectiveRows[details.rowIndex - 1];
                        final columnWidths = {
                          'asistan': width * 0.0,
                          'id': width * 0.0,
                          'baslik': width * 0.35 - 10,
                          'aramasaati': width * 0.25 - 10,
                          'sonuc': width * 0.40 - 10,
                          'islem': width * 0.1 - 10,
                        };
                        double maxHeight = 0;
                        row.getCells().forEach((cell) {
                          if (columnWidths.containsKey(cell.columnName)) {
                            final cellText = cell.value.toString();
                            final cellHeight = calculateTextHeight(
                              cellText,
                              columnWidths[cell.columnName]!,
                              const TextStyle(fontSize: 14),
                            );
                            if (cellHeight > maxHeight) {
                              maxHeight = cellHeight;
                            }
                          }
                        });
                        return maxHeight;
                      },
                      onSwipeStart: (details) {
                        details.setSwipeMaxOffset(50);
                        return true;
                      },
                      onCellTap: (DataGridCellTapDetails details) {
                        if (details.rowColumnIndex.rowIndex > 0) {
                          final task = _easistanDataGridSource
                              .rows[details.rowColumnIndex.rowIndex - 1];
                          _easistanDataGridSource.showTaskDetails(
                              context, task.getCells()[0].value);
                        }
                      },
                      columns: _buildColumns(width, scheme),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _buildPaginationControls(scheme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<GridColumn> _buildColumns(double width, ColorScheme scheme) {
    final headerStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: scheme.primary,
      letterSpacing: 0.1,
    );
    Widget header(String text, {Alignment align = Alignment.centerLeft}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: align,
          child: Text(text, style: headerStyle),
        );

    return [
      GridColumn(
          columnName: 'asistan', width: width * 0.0, label: Container()),
      GridColumn(columnName: 'id', width: width * 0.0, label: Container()),
      GridColumn(
          columnName: 'baslik',
          width: width * 0.30,
          label: header('Müşteri')),
      GridColumn(
          columnName: 'aramasaati',
          width: width * 0.20,
          label: header('Arama Saati')),
      GridColumn(
          columnName: 'sonuc',
          width: width * 0.50,
          label: header('Sonuç')),
      GridColumn(
          columnName: 'islem', width: width * 0.0, label: Container()),
    ];
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: PremiumGlassCard(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.tertiary.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: scheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yarın için göreviniz yok',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yeni görevler oluştuğunda burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.55),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(ColorScheme scheme) {
    final totalPages = (_easistanDataGridSource.totalPages).ceil();
    final canPrev = _easistanDataGridSource.currentPage > 1;
    final canNext = _easistanDataGridSource.currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pagerButton(
            scheme: scheme,
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () {
              setState(() {
                _easistanDataGridSource
                    .setPage(_easistanDataGridSource.currentPage - 1);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
                children: [
                  const TextSpan(text: 'Sayfa '),
                  TextSpan(
                    text: '${_easistanDataGridSource.currentPage}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  TextSpan(text: ' / $totalPages'),
                ],
              ),
            ),
          ),
          _pagerButton(
            scheme: scheme,
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () {
              setState(() {
                _easistanDataGridSource
                    .setPage(_easistanDataGridSource.currentPage + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _pagerButton({
    required ColorScheme scheme,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled
                ? LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : scheme.onSurface.withValues(alpha: 0.06),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? scheme.onPrimary
                : scheme.onSurface.withValues(alpha: 0.30),
          ),
        ),
      ),
    );
  }
}
