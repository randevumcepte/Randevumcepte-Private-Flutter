import 'dart:async';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/ongorusmeler.dart';
import 'package:randevu_sistem/theme/premium_components.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/popupdialogs.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'ongorusmeduzenle.dart';
import 'ongorusmeekle.dart';

class OnGorusmeler extends StatefulWidget {
	final dynamic isletmebilgi;
	final int kullanicirolu;

	const OnGorusmeler({Key? key, required this.isletmebilgi, required this.kullanicirolu}) : super(key: key);
	@override
	_OnGorusmelerState createState() => _OnGorusmelerState();
}

class _OnGorusmelerState extends State<OnGorusmeler> {
	final TextEditingController _controller = TextEditingController();
	late OnGorusmeDataSource _ongorusmeDataGridSource;
	late String? seciliisletme;
	bool _isLoading = true;
	Timer? _debounce;
	String? _lastQuery;
	String _statusFilter = 'all'; // 'all' | 'pending' | 'sold' | 'notsold'

	@override
	void initState() {
		super.initState();
		initialize();
		_controller.addListener(_onSearchChanged);
	}

	void _onSearchChanged() {
		final text = _controller.text.trim();
		if (text.length == 0 || text.length >= 3) {
			if (_debounce?.isActive ?? false) _debounce!.cancel();
			_debounce = Timer(const Duration(milliseconds: 450), () {
				if (text != _lastQuery) {
					_lastQuery = text;
					setState(() {
						_ongorusmeDataGridSource.search(text);
					});
				}
			});
		}
	}

	@override
	void dispose() {
		_controller.dispose();
		_debounce?.cancel();
		_ongorusmeDataGridSource.isLoadingNotifier.removeListener(_onLoadingStateChanged);
		super.dispose();
	}

	Future<void> initialize() async {
		seciliisletme = await secilisalonid();
		setState(() {
			_ongorusmeDataGridSource = OnGorusmeDataSource(
				isletmebilgi: widget.isletmebilgi,
				rowsPerPage: 10,
				salonid: seciliisletme!,
				context: context,
				arama: _controller.text,
			);
			_ongorusmeDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
			_isLoading = false;
		});
	}

	void _onLoadingStateChanged() {
		if (mounted) setState(() {});
	}

	Future<void> _refresh() async {
		await _ongorusmeDataGridSource.fetchData(
			_ongorusmeDataGridSource.currentPage.toString(),
			_controller.text,
			true,
		);
	}

	List<OnGorusme> get _filteredList {
		final all = _ongorusmeDataGridSource.ongorusme;
		switch (_statusFilter) {
			case 'sold':
				return all.where((e) => e.durum == '1').toList();
			case 'notsold':
				return all.where((e) => e.durum == '0').toList();
			case 'pending':
				return all.where((e) => e.durum != '1' && e.durum != '0').toList();
			default:
				return all;
		}
	}

	int _statusCount(String filter) {
		final all = _ongorusmeDataGridSource.ongorusme;
		switch (filter) {
			case 'sold':
				return all.where((e) => e.durum == '1').length;
			case 'notsold':
				return all.where((e) => e.durum == '0').length;
			case 'pending':
				return all.where((e) => e.durum != '1' && e.durum != '0').length;
			default:
				return all.length;
		}
	}

	@override
	Widget build(BuildContext context) {
		if (_isLoading) {
			return Scaffold(
				backgroundColor: Colors.white,
				body: PremiumGradientBg(
					child: Center(
						child: CircularProgressIndicator(
							color: Theme.of(context).colorScheme.primary,
						),
					),
				),
			);
		}

		final scheme = Theme.of(context).colorScheme;
		return GestureDetector(
			onTap: () => FocusScope.of(context).unfocus(),
			child: Scaffold(
				backgroundColor: Colors.white,
				resizeToAvoidBottomInset: true,
				body: PremiumGradientBg(
					child: SafeArea(
						bottom: false,
						child: Column(
							children: [
								_premiumTopBar(context),
								const SizedBox(height: 12),
								_premiumGreeting(context),
								const SizedBox(height: 14),
								_premiumSearchBar(context),
								const SizedBox(height: 12),
								_statusFilters(context),
								const SizedBox(height: 6),
								Expanded(
									child: RefreshIndicator(
										color: scheme.primary,
										backgroundColor: Colors.white,
										strokeWidth: 3,
										onRefresh: _refresh,
										child: _buildBody(context),
									),
								),
								_premiumPagination(context),
							],
						),
					),
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Top bar
	// ────────────────────────────────────────────────────────────────────────
	Widget _premiumTopBar(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDemo = widget.isletmebilgi["demo_hesabi"].toString() == "1";
		return Padding(
			padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
			child: Row(
				children: [
					PremiumCircleAction(
						icon: Icons.arrow_back_rounded,
						onTap: () => Navigator.of(context).pop(),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
							decoration: BoxDecoration(
								color: scheme.primary.withValues(alpha: 0.10),
								borderRadius: BorderRadius.circular(999),
							),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Icon(Icons.handshake_outlined,
											size: 16, color: scheme.primary),
									const SizedBox(width: 6),
									Flexible(
										child: Text(
											'Ön Görüşmeler',
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: TextStyle(
												fontSize: 13,
												fontWeight: FontWeight.w700,
												color: scheme.primary,
												letterSpacing: 0.1,
											),
										),
									),
								],
							),
						),
					),
					if (isDemo) ...[
						const SizedBox(width: 12),
						SizedBox(
							height: 44,
							child: YukseltButonu(isletme_bilgi: widget.isletmebilgi),
						),
					],
				],
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Greeting / başlık
	// ────────────────────────────────────────────────────────────────────────
	Widget _premiumGreeting(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final total = _ongorusmeDataGridSource.ongorusme.length;
		final page = _ongorusmeDataGridSource.currentPage;
		final totalPages = _ongorusmeDataGridSource.totalPages;
		return Padding(
			padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.end,
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Ön Görüşmeler',
									style: TextStyle(
										fontSize: 26,
										fontWeight: FontWeight.w800,
										letterSpacing: -0.5,
										color: scheme.onSurface,
										height: 1.1,
									),
								),
								const SizedBox(height: 4),
								Text(
									'$total kayıt · Sayfa $page / $totalPages',
									style: TextStyle(
										fontSize: 12,
										fontWeight: FontWeight.w500,
										color: scheme.onSurface.withValues(alpha: 0.55),
									),
								),
							],
						),
					),
					if (Yetki.varMi('gorusme.ekle_duzenle'))
						PremiumGradientPill(
							icon: Icons.add_rounded,
							label: 'Yeni',
							onTap: () {
								Navigator.push(
									context,
									PageTransition(
										type: PageTransitionType.rightToLeft,
										duration: const Duration(milliseconds: 350),
										child: YeniOnGorusme(
											kullanicirolu: widget.kullanicirolu,
											ongorusmedatasource: _ongorusmeDataGridSource,
											isletmebilgi: widget.isletmebilgi,
										),
									),
								);
							},
						),
				],
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Search bar
	// ────────────────────────────────────────────────────────────────────────
	Widget _premiumSearchBar(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 20),
			child: Container(
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(16),
					boxShadow: [
						BoxShadow(
							color: scheme.primary.withValues(alpha: 0.10),
							blurRadius: 16,
							offset: const Offset(0, 5),
						),
					],
				),
				child: TextField(
					controller: _controller,
					textInputAction: TextInputAction.search,
					style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
					decoration: InputDecoration(
						hintText: 'Müşteri adı ile ara…',
						hintStyle: TextStyle(
							color: scheme.onSurface.withValues(alpha: 0.40),
							fontWeight: FontWeight.w500,
							fontSize: 14,
						),
						prefixIcon: Icon(Icons.search_rounded,
								color: scheme.primary, size: 22),
						suffixIcon: _controller.text.isNotEmpty
								? IconButton(
									icon: Icon(Icons.close_rounded,
											color: scheme.onSurface.withValues(alpha: 0.45),
											size: 20),
									onPressed: () {
										_controller.clear();
										_onSearchChanged();
									},
								)
								: null,
						border: InputBorder.none,
						enabledBorder: InputBorder.none,
						focusedBorder: InputBorder.none,
						contentPadding:
								const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
					),
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Status filter chips
	// ────────────────────────────────────────────────────────────────────────
	Widget _statusFilters(BuildContext context) {
		final chips = [
			_FilterChipData('all', 'Tümü', Icons.list_alt_rounded),
			_FilterChipData('pending', 'Beklemede', Icons.schedule_rounded,
					color: const Color(0xFFD97706)),
			_FilterChipData('sold', 'Satıldı', Icons.check_circle_rounded,
					color: const Color(0xFF16A34A)),
			_FilterChipData('notsold', 'Satılmadı', Icons.cancel_rounded,
					color: const Color(0xFFDC2626)),
		];
		return SizedBox(
			height: 42,
			child: ListView.separated(
				scrollDirection: Axis.horizontal,
				padding: const EdgeInsets.symmetric(horizontal: 20),
				itemCount: chips.length,
				separatorBuilder: (_, __) => const SizedBox(width: 8),
				itemBuilder: (_, i) {
					final c = chips[i];
					final selected = _statusFilter == c.value;
					final count = _statusCount(c.value);
					return _filterChip(c, selected, count);
				},
			),
		);
	}

	Widget _filterChip(_FilterChipData c, bool selected, int count) {
		final scheme = Theme.of(context).colorScheme;
		final accent = c.color ?? scheme.primary;
		return Material(
			color: Colors.transparent,
			borderRadius: BorderRadius.circular(999),
			child: InkWell(
				onTap: () => setState(() => _statusFilter = c.value),
				borderRadius: BorderRadius.circular(999),
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 220),
					curve: Curves.easeOut,
					padding:
							const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
					decoration: BoxDecoration(
						color: selected ? accent : Colors.white,
						borderRadius: BorderRadius.circular(999),
						boxShadow: [
							BoxShadow(
								color: selected
										? accent.withValues(alpha: 0.30)
										: scheme.primary.withValues(alpha: 0.08),
								blurRadius: selected ? 14 : 10,
								offset: const Offset(0, 4),
							),
						],
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(c.icon,
									size: 15,
									color: selected ? Colors.white : accent),
							const SizedBox(width: 6),
							Text(
								c.label,
								style: TextStyle(
									fontSize: 12.5,
									fontWeight: FontWeight.w700,
									color: selected
											? Colors.white
											: scheme.onSurface.withValues(alpha: 0.78),
								),
							),
							const SizedBox(width: 6),
							Container(
								padding: const EdgeInsets.symmetric(
										horizontal: 7, vertical: 2),
								decoration: BoxDecoration(
									color: selected
											? Colors.white.withValues(alpha: 0.25)
											: accent.withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(999),
								),
								child: Text(
									'$count',
									style: TextStyle(
										fontSize: 10.5,
										fontWeight: FontWeight.w800,
										color: selected ? Colors.white : accent,
										height: 1.1,
									),
								),
							),
						],
					),
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Liste / boş durum / loading
	// ────────────────────────────────────────────────────────────────────────
	Widget _buildBody(BuildContext context) {
		final loading = _ongorusmeDataGridSource.isLoadingNotifier.value;
		final list = _filteredList;

		if (loading && list.isEmpty) {
			return Center(
				child: CircularProgressIndicator(
					color: Theme.of(context).colorScheme.primary,
				),
			);
		}
		if (list.isEmpty) {
			return _emptyState(context);
		}
		return ListView.builder(
			physics: const BouncingScrollPhysics(
					parent: AlwaysScrollableScrollPhysics()),
			padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
			itemCount: list.length,
			itemBuilder: (_, i) => Padding(
				padding: const EdgeInsets.only(bottom: 10),
				child: _ongorusmeKart(list[i]),
			),
		);
	}

	Widget _emptyState(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isSearching = _controller.text.isNotEmpty;
		return ListView(
			physics: const AlwaysScrollableScrollPhysics(
					parent: BouncingScrollPhysics()),
			children: [
				const SizedBox(height: 80),
				Center(
					child: Container(
						width: 96,
						height: 96,
						decoration: BoxDecoration(
							color: Colors.white,
							shape: BoxShape.circle,
							boxShadow: [
								BoxShadow(
									color: scheme.primary.withValues(alpha: 0.16),
									blurRadius: 20,
									offset: const Offset(0, 8),
								),
							],
						),
						child: Icon(
							isSearching
									? Icons.search_off_rounded
									: Icons.inbox_outlined,
							size: 44,
							color: scheme.primary,
						),
					),
				),
				const SizedBox(height: 20),
				Center(
					child: Text(
						isSearching
								? 'Sonuç bulunamadı'
								: _statusFilter == 'all'
										? 'Henüz ön görüşme yok'
										: 'Bu filtreye uyan kayıt yok',
						style: TextStyle(
							fontSize: 16,
							fontWeight: FontWeight.w700,
							color: scheme.onSurface,
						),
					),
				),
				const SizedBox(height: 6),
				Center(
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 40),
						child: Text(
							isSearching
									? 'Farklı bir isim deneyin veya aramayı temizleyin.'
									: 'Sağ üstteki + butonuyla yeni bir ön görüşme oluşturabilirsiniz.',
							textAlign: TextAlign.center,
							style: TextStyle(
								fontSize: 13,
								fontWeight: FontWeight.w500,
								color: scheme.onSurface.withValues(alpha: 0.55),
								height: 1.4,
							),
						),
					),
				),
			],
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Ön görüşme kartı
	// ────────────────────────────────────────────────────────────────────────
	Widget _ongorusmeKart(OnGorusme e) {
		final scheme = Theme.of(context).colorScheme;
		final paketUrun = _paketUrunAdi(e);
		final isPending = e.durum != '1' && e.durum != '0';
		final isSold = e.durum == '1';
		final isNotSold = e.durum == '0';

		final statusColor = isSold
				? const Color(0xFF16A34A)
				: isNotSold
						? const Color(0xFFDC2626)
						: const Color(0xFFD97706);
		final statusText = isSold
				? 'Satıldı'
				: isNotSold
						? 'Satılmadı'
						: 'Beklemede';
		final statusIcon = isSold
				? Icons.check_circle_rounded
				: isNotSold
						? Icons.cancel_rounded
						: Icons.schedule_rounded;

		return PremiumGlassCard(
			padding: const EdgeInsets.all(14),
			onTap: () => _openEdit(e),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_avatar(e.ad_soyad),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										Expanded(
											child: Text(
												e.ad_soyad.isEmpty ? '—' : e.ad_soyad,
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: TextStyle(
													fontSize: 15,
													fontWeight: FontWeight.w700,
													color: scheme.onSurface,
													letterSpacing: -0.2,
												),
											),
										),
										const SizedBox(width: 8),
										_statusBadge(statusIcon, statusText, statusColor),
									],
								),
								const SizedBox(height: 6),
								Row(
									children: [
										Icon(Icons.inventory_2_outlined,
												size: 14,
												color: scheme.primary.withValues(alpha: 0.75)),
										const SizedBox(width: 5),
										Expanded(
											child: Text(
												paketUrun,
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
												style: TextStyle(
													fontSize: 12.5,
													fontWeight: FontWeight.w600,
													color: scheme.onSurface.withValues(alpha: 0.70),
												),
											),
										),
									],
								),
								if (e.tarih.isNotEmpty || e.saat.isNotEmpty) ...[
									const SizedBox(height: 4),
									Row(
										children: [
											Icon(Icons.event_outlined,
													size: 13,
													color: scheme.onSurface
															.withValues(alpha: 0.50)),
											const SizedBox(width: 5),
											Flexible(
												child: Text(
													_formatTarihSaat(e.tarih, e.saat),
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: TextStyle(
														fontSize: 11.5,
														fontWeight: FontWeight.w500,
														color: scheme.onSurface
																.withValues(alpha: 0.55),
													),
												),
											),
											if (e.cep_telefon.isNotEmpty) ...[
												const SizedBox(width: 10),
												Icon(Icons.phone_outlined,
														size: 13,
														color: scheme.onSurface
																.withValues(alpha: 0.50)),
												const SizedBox(width: 4),
												Flexible(
													child: Text(
														Yetki.telefonGoster(e.cep_telefon),
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
														style: TextStyle(
															fontSize: 11.5,
															fontWeight: FontWeight.w500,
															color: scheme.onSurface
																	.withValues(alpha: 0.55),
														),
													),
												),
											],
										],
									),
								],
							],
						),
					),
					const SizedBox(width: 6),
					_kartActionButton(e, isPending, isNotSold),
				],
			),
		);
	}

	Widget _avatar(String name) {
		final scheme = Theme.of(context).colorScheme;
		final initials = _initials(name);
		return Container(
			width: 46,
			height: 46,
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [
						scheme.primary.withValues(alpha: 0.20),
						scheme.tertiary.withValues(alpha: 0.20),
					],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				shape: BoxShape.circle,
			),
			child: Center(
				child: Text(
					initials,
					style: TextStyle(
						fontSize: 15,
						fontWeight: FontWeight.w800,
						color: scheme.primary,
						letterSpacing: 0.5,
					),
				),
			),
		);
	}

	Widget _statusBadge(IconData icon, String text, Color color) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 11, color: color),
					const SizedBox(width: 4),
					Text(
						text,
						style: TextStyle(
							fontSize: 10.5,
							fontWeight: FontWeight.w800,
							color: color,
							height: 1.1,
						),
					),
				],
			),
		);
	}

	Widget _kartActionButton(OnGorusme e, bool isPending, bool isNotSold) {
		final scheme = Theme.of(context).colorScheme;
		if (isNotSold) {
			return InkWell(
				onTap: () => _showReasonDialog(e),
				borderRadius: BorderRadius.circular(999),
				child: Container(
					width: 34,
					height: 34,
					decoration: BoxDecoration(
						color: scheme.primary.withValues(alpha: 0.08),
						shape: BoxShape.circle,
					),
					child: Icon(Icons.info_outline_rounded,
							size: 18, color: scheme.primary),
				),
			);
		}
		if (!isPending) {
			return Container(
				width: 34,
				height: 34,
				decoration: BoxDecoration(
					color: scheme.primary.withValues(alpha: 0.06),
					shape: BoxShape.circle,
				),
				child: Icon(Icons.chevron_right_rounded,
						size: 20, color: scheme.primary.withValues(alpha: 0.55)),
			);
		}
		return InkWell(
			onTap: () => _showActionSheet(e),
			borderRadius: BorderRadius.circular(999),
			child: Container(
				width: 34,
				height: 34,
				decoration: BoxDecoration(
					color: scheme.primary.withValues(alpha: 0.10),
					shape: BoxShape.circle,
				),
				child: Icon(Icons.more_vert_rounded,
						size: 18, color: scheme.primary),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Pagination
	// ────────────────────────────────────────────────────────────────────────
	Widget _premiumPagination(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final totalPages = _ongorusmeDataGridSource.totalPages;
		final page = _ongorusmeDataGridSource.currentPage;
		final canPrev = page > 1;
		final canNext = page < totalPages;
		return SafeArea(
			top: false,
			child: Padding(
				padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
				child: Row(
					children: [
						_pageBtn(
							icon: Icons.arrow_back_rounded,
							enabled: canPrev,
							onTap: () => setState(() => _ongorusmeDataGridSource.setPage(page - 1)),
						),
						const SizedBox(width: 10),
						Expanded(
							child: Container(
								height: 44,
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
								child: Center(
									child: Text(
										'Sayfa $page / $totalPages',
										style: TextStyle(
											fontSize: 13,
											fontWeight: FontWeight.w700,
											color: scheme.onSurface,
										),
									),
								),
							),
						),
						const SizedBox(width: 10),
						_pageBtn(
							icon: Icons.arrow_forward_rounded,
							enabled: canNext,
							onTap: () => setState(() => _ongorusmeDataGridSource.setPage(page + 1)),
						),
					],
				),
			),
		);
	}

	Widget _pageBtn({
		required IconData icon,
		required bool enabled,
		required VoidCallback onTap,
	}) {
		final scheme = Theme.of(context).colorScheme;
		return Material(
			color: Colors.transparent,
			shape: const CircleBorder(),
			child: InkWell(
				onTap: enabled ? onTap : null,
				customBorder: const CircleBorder(),
				child: Container(
					width: 44,
					height: 44,
					decoration: BoxDecoration(
						color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.6),
						shape: BoxShape.circle,
						boxShadow: [
							BoxShadow(
								color: scheme.primary.withValues(
										alpha: enabled ? 0.14 : 0.06),
								blurRadius: 14,
								offset: const Offset(0, 4),
							),
						],
					),
					child: Icon(
						icon,
						size: 20,
						color: enabled
								? scheme.primary
								: scheme.primary.withValues(alpha: 0.35),
					),
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Action sheet (bottom sheet)
	// ────────────────────────────────────────────────────────────────────────
	void _showActionSheet(OnGorusme e) {
		final scheme = Theme.of(context).colorScheme;
		showModalBottomSheet(
			context: context,
			backgroundColor: Colors.transparent,
			isScrollControlled: true,
			builder: (ctx) {
				return SafeArea(
					top: false,
					child: Container(
						margin: const EdgeInsets.all(12),
						decoration: BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.circular(24),
							boxShadow: [
								BoxShadow(
									color: scheme.primary.withValues(alpha: 0.16),
									blurRadius: 24,
									offset: const Offset(0, 8),
								),
							],
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								const SizedBox(height: 10),
								Container(
									width: 38,
									height: 4,
									decoration: BoxDecoration(
										color: scheme.onSurface.withValues(alpha: 0.18),
										borderRadius: BorderRadius.circular(999),
									),
								),
								const SizedBox(height: 14),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 18),
									child: Row(
										children: [
											_avatar(e.ad_soyad),
											const SizedBox(width: 12),
											Expanded(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															e.ad_soyad.isEmpty ? '—' : e.ad_soyad,
															style: TextStyle(
																fontSize: 16,
																fontWeight: FontWeight.w800,
																color: scheme.onSurface,
																letterSpacing: -0.2,
															),
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
														),
														const SizedBox(height: 2),
														Text(
															_paketUrunAdi(e),
															style: TextStyle(
																fontSize: 12,
																fontWeight: FontWeight.w500,
																color: scheme.onSurface
																		.withValues(alpha: 0.55),
															),
															maxLines: 1,
															overflow: TextOverflow.ellipsis,
														),
													],
												),
											),
										],
									),
								),
								const SizedBox(height: 14),
								Divider(
										height: 1,
										color: scheme.onSurface.withValues(alpha: 0.08)),
								if (Yetki.varMi('gorusme.ekle_duzenle'))
									_sheetItem(
										icon: Icons.edit_outlined,
										label: 'Düzenle',
										color: scheme.primary,
										onTap: () {
											Navigator.pop(ctx);
											_openEdit(e);
										},
									),
								if (Yetki.varMi('gorusme.ekle_duzenle')) ...[
									_sheetItem(
										icon: Icons.check_circle_rounded,
										label: 'Satış Yapıldı',
										color: const Color(0xFF16A34A),
										onTap: () {
											Navigator.pop(ctx);
											_satisYapildi(e);
										},
									),
									_sheetItem(
										icon: Icons.cancel_rounded,
										label: 'Satış Yapılmadı',
										color: const Color(0xFFDC2626),
										onTap: () {
											Navigator.pop(ctx);
											_satisYapilmadi(e);
										},
									),
								],
								const SizedBox(height: 6),
							],
						),
					),
				);
			},
		);
	}

	Widget _sheetItem({
		required IconData icon,
		required String label,
		required Color color,
		required VoidCallback onTap,
	}) {
		final scheme = Theme.of(context).colorScheme;
		return InkWell(
			onTap: onTap,
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
				child: Row(
					children: [
						Container(
							width: 38,
							height: 38,
							decoration: BoxDecoration(
								color: color.withValues(alpha: 0.12),
								shape: BoxShape.circle,
							),
							child: Icon(icon, size: 19, color: color),
						),
						const SizedBox(width: 14),
						Expanded(
							child: Text(
								label,
								style: TextStyle(
									fontSize: 14.5,
									fontWeight: FontWeight.w700,
									color: scheme.onSurface,
								),
							),
						),
						Icon(Icons.chevron_right_rounded,
								color: scheme.onSurface.withValues(alpha: 0.30),
								size: 22),
					],
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Aksiyonlar (mevcut backend davranışını koruyor)
	// ────────────────────────────────────────────────────────────────────────
	void _openEdit(OnGorusme e) {
		Navigator.push(
			context,
			PageTransition(
				type: PageTransitionType.rightToLeft,
				duration: const Duration(milliseconds: 320),
				child: OnGorusmeDuzenle(
					isletmebilgi: widget.isletmebilgi,
					ongorusme: e,
					ongorusmedatasource: _ongorusmeDataGridSource,
				),
			),
		);
	}

	void _satisYapildi(OnGorusme e) {
		if (e.paket_id.isNotEmpty && e.paket_id != "null") {
			_ongorusmeDataGridSource.showPackagePopup(context, e.id);
		} else if (e.urun_id.isNotEmpty && e.urun_id != "null") {
			_ongorusmeDataGridSource.showProductPopup(context, e.id);
		}
	}

	void _satisYapilmadi(OnGorusme e) {
		showSatisYapilmamaNedeniDialog(
			context,
			e.id,
			_ongorusmeDataGridSource.currentPage.toString(),
			_ongorusmeDataGridSource.arama,
			(value) => _ongorusmeDataGridSource.fetchData(
				value["currentPage"] = "1",
				value["arama"] = "",
				value["showprogress"] = true,
			),
		);
	}

	void _showReasonDialog(OnGorusme e) {
		final scheme = Theme.of(context).colorScheme;
		showDialog(
			context: context,
			builder: (ctx) => Dialog(
				backgroundColor: Colors.transparent,
				child: Container(
					padding: const EdgeInsets.all(20),
					decoration: BoxDecoration(
						color: Colors.white,
						borderRadius: BorderRadius.circular(20),
						boxShadow: [
							BoxShadow(
								color: scheme.primary.withValues(alpha: 0.18),
								blurRadius: 22,
								offset: const Offset(0, 8),
							),
						],
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Container(
										width: 38,
										height: 38,
										decoration: BoxDecoration(
											color: const Color(0xFFDC2626)
													.withValues(alpha: 0.12),
											shape: BoxShape.circle,
										),
										child: const Icon(Icons.info_outline_rounded,
												color: Color(0xFFDC2626), size: 20),
									),
									const SizedBox(width: 10),
									Expanded(
										child: Text(
											'Satış Yapılmama Sebebi',
											style: TextStyle(
												fontSize: 16,
												fontWeight: FontWeight.w800,
												color: scheme.onSurface,
											),
										),
									),
								],
							),
							const SizedBox(height: 14),
							Text(
								e.satisyapilmadi_not.isEmpty
										? 'Sebep belirtilmemiş.'
										: e.satisyapilmadi_not,
								style: TextStyle(
									fontSize: 13.5,
									fontWeight: FontWeight.w500,
									color: scheme.onSurface.withValues(alpha: 0.75),
									height: 1.5,
								),
							),
							const SizedBox(height: 16),
							Align(
								alignment: Alignment.centerRight,
								child: PremiumGradientPill(
									icon: Icons.close_rounded,
									label: 'Kapat',
									onTap: () => Navigator.pop(ctx),
								),
							),
						],
					),
				),
			),
		);
	}

	// ────────────────────────────────────────────────────────────────────────
	// Yardımcılar
	// ────────────────────────────────────────────────────────────────────────
	String _initials(String name) {
		final parts = name.trim().split(RegExp(r'\s+'));
		if (parts.isEmpty || parts.first.isEmpty) return '?';
		if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
		return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
				.toUpperCase();
	}

	String _paketUrunAdi(OnGorusme e) {
		if (e.urun_id.isNotEmpty && e.urun_id != "null") {
			final ad = e.urun["urun_adi"]?.toString();
			if (ad != null && ad.isNotEmpty) return ad;
		}
		if (e.paket_id.isNotEmpty && e.paket_id != "null") {
			final ad = e.paket["paket_adi"]?.toString();
			if (ad != null && ad.isNotEmpty) return ad;
		}
		return 'Ön Görüşme';
	}

	String _formatTarihSaat(String tarih, String saat) {
		final t = tarih.isEmpty ? '' : tarih;
		final s = saat.isEmpty ? '' : saat;
		if (t.isNotEmpty && s.isNotEmpty) return '$t · $s';
		return t + s;
	}
}

class _FilterChipData {
	final String value;
	final String label;
	final IconData icon;
	final Color? color;
	const _FilterChipData(this.value, this.label, this.icon, {this.color});
}
