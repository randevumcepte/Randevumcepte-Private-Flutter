import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'musteribilgileri/arsivdetay.dart';
import 'islemlerveseanslar.dart';
import 'musteriadisyonlari.dart';
import 'musteridetayrandevular.dart';
import 'musteribilgileri/musterisaglikbilgileri.dart';
import 'musteriduzenle.dart';

class MusteriDetaylari extends StatefulWidget {
	final MusteriDanisan md;
	final dynamic isletmebilgi;
	final int kullanicirolu;
	const MusteriDetaylari({
		Key? key,
		required this.md,
		required this.isletmebilgi,
		required this.kullanicirolu,
	}) : super(key: key);

	@override
	_MusteriDetaylariState createState() => _MusteriDetaylariState();
}

class _MusteriDetaylariState extends State<MusteriDetaylari>
		with TickerProviderStateMixin {
	Color get _primary => Theme.of(context).colorScheme.primary;
	Color get _primaryDark => Theme.of(context).colorScheme.primary.withValues(alpha: 0.85);

	late final TabController _mainTab;
	late final TabController _notTab;
	Future<List<Map<String, dynamic>>>? _randevularFuture;

	@override
	void initState() {
		super.initState();
		_mainTab = TabController(length: 2, vsync: this);
		_notTab = TabController(length: 2, vsync: this);
		_randevularFuture = _fetchRandevular();
	}

	@override
	void dispose() {
		_mainTab.dispose();
		_notTab.dispose();
		super.dispose();
	}

	Future<List<Map<String, dynamic>>> _fetchRandevular() async {
		try {
			final res = await http.get(
				Uri.parse('https://apptest.randevumcepte.com.tr/api/v1/musteri-randevulari/${widget.md.id}'),
			);
			if (res.statusCode == 200) {
				final data = jsonDecode(res.body);
				if (data is List) return data.cast<Map<String, dynamic>>();
			}
		} catch (_) {}
		return [];
	}

	String _safe(String? s) =>
			(s == null || s == 'null' || s.trim().isEmpty) ? '-' : s;

	String _referansText(String? id) {
		switch (id) {
			case '1':
				return 'İnternet';
			case '2':
				return 'Reklam';
			case '3':
				return 'Instagram';
			case '4':
				return 'Facebook';
			case '5':
				return 'Tanıdık';
			default:
				return 'Yok';
		}
	}

	String _cinsiyetText(String? c) {
		if (c == '0') return 'Kadın';
		if (c == '1') return 'Erkek';
		return 'Belirtilmemiş';
	}

	String _formatDate(String? raw) {
		if (raw == null || raw.isEmpty || raw == 'null') return '-';
		try {
			return DateFormat('dd.MM.yyyy').format(DateTime.parse(raw));
		} catch (_) {
			return raw;
		}
	}

	int get _randevuCount => int.tryParse(widget.md.randevu_sayisi) ?? 0;

	String _statusLabel() {
		if (_randevuCount == 0) return 'Pasif';
		if (_randevuCount >= 4) return 'Sadık';
		return 'Aktif';
	}

	Color _statusColor() {
		final s = _statusLabel();
		if (s == 'Pasif') return const Color(0xFF9E9E9E);
		if (s == 'Sadık') return const Color(0xFFFFA000);
		return const Color(0xFF43A047);
	}

	IconData _statusIcon() {
		final s = _statusLabel();
		if (s == 'Pasif') return Icons.pause_circle_filled;
		if (s == 'Sadık') return Icons.workspace_premium;
		return Icons.check_circle;
	}

	Future<void> _launch(String url) async {
		final uri = Uri.parse(url);
		try {
			await launchUrl(uri, mode: LaunchMode.externalApplication);
		} catch (_) {}
	}

	Future<bool> _canOpen(String url) async {
		try {
			return await canLaunchUrl(Uri.parse(url));
		} catch (_) {
			return false;
		}
	}

	Future<void> _onCallPressed() async {
		final tel = _localNumber();
		if (tel.isEmpty) return;

		final sipOptions = <_DialOption>[];
		if (await _canOpen('zoiper:$tel')) {
			sipOptions.add(_DialOption('Zoiper', Icons.phone_in_talk, 'zoiper:$tel'));
		}
		if (await _canOpen('zoiperpremium:$tel')) {
			sipOptions.add(_DialOption('Zoiper Premium', Icons.phone_in_talk, 'zoiperpremium:$tel'));
		}
		if (await _canOpen('bria:$tel')) {
			sipOptions.add(_DialOption('Bria', Icons.phone_in_talk, 'bria:$tel'));
		}
		if (await _canOpen('briax:$tel')) {
			sipOptions.add(_DialOption('Bria X', Icons.phone_in_talk, 'briax:$tel'));
		}

		if (sipOptions.isEmpty) {
			await _launch('tel:$tel');
			return;
		}

		if (sipOptions.length == 1) {
			await _launch(sipOptions.first.url);
			return;
		}

		if (!mounted) return;
		await showModalBottomSheet(
			context: context,
			showDragHandle: true,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (ctx) => SafeArea(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Padding(
							padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
							child: Align(
								alignment: Alignment.centerLeft,
								child: Text(
									'Aramayı hangi uygulamayla yapmak istersiniz?',
									style: TextStyle(
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
						...sipOptions.map(
							(o) => ListTile(
								leading: Icon(o.icon, color: _primary),
								title: Text(o.label),
								onTap: () {
									Navigator.pop(ctx);
									_launch(o.url);
								},
							),
						),
						const Divider(height: 1),
						ListTile(
							leading: Icon(Icons.call, color: Colors.grey.shade700),
							title: const Text('Telefon (varsayılan arayıcı)'),
							onTap: () {
								Navigator.pop(ctx);
								_launch('tel:${_localNumber()}');
							},
						),
						const SizedBox(height: 8),
					],
				),
			),
		);
	}

	String _waNumber() {
		var p = widget.md.cep_telefon;
		if (p.isEmpty || p == 'null') return '';
		p = p.replaceAll(RegExp(r'\D'), '');
		if (!p.startsWith('90')) {
			p = '90' + p.replaceFirst(RegExp(r'^0'), '');
		}
		return p;
	}

	// Tel/SMS/SIP için yerel format: 90/+90 atılır, başa 0 eklenir.
	String _localNumber() {
		var p = widget.md.cep_telefon;
		if (p.isEmpty || p == 'null') return '';
		p = p.replaceAll(RegExp(r'\D'), '');
		if (p.startsWith('90') && p.length >= 12) {
			p = p.substring(2);
		}
		if (!p.startsWith('0')) {
			p = '0' + p;
		}
		return p;
	}

	void _openDuzenle() {
		Navigator.push(
			context,
			MaterialPageRoute(
				builder: (_) => MusteriDuzenle(
					md: widget.md,
					isletmebilgi: widget.isletmebilgi,
					kullanicirolu: widget.kullanicirolu,
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			decoration: BoxDecoration(
				gradient: LinearGradient(
					begin: Alignment.topRight,
					end: Alignment.bottomLeft,
					colors: [
						Color.alphaBlend(
							scheme.primary.withValues(alpha: 0.32),
							Colors.white,
						),
						Color.alphaBlend(
							scheme.tertiary.withValues(alpha: 0.06),
							Colors.white,
						),
					],
				),
			),
			child: Scaffold(
				backgroundColor: Colors.transparent,
				body: SafeArea(
					bottom: false,
					child: NestedScrollView(
						headerSliverBuilder: (context, _) => [
							SliverToBoxAdapter(child: _buildTopBar()),
							SliverToBoxAdapter(child: _buildHero()),
							SliverToBoxAdapter(child: _buildQuickActions()),
							SliverToBoxAdapter(child: _buildStatsRow()),
							SliverToBoxAdapter(child: const SizedBox(height: 12)),
							SliverPersistentHeader(
								pinned: true,
								delegate: _StickyTabBarDelegate(
									TabBar(
										controller: _mainTab,
										labelColor: _primary,
										unselectedLabelColor: Colors.grey.shade600,
										indicatorColor: _primary,
										indicatorWeight: 3,
										labelStyle: const TextStyle(
											fontWeight: FontWeight.w700,
											fontSize: 14,
										),
										tabs: const [
											Tab(text: 'Genel'),
											Tab(text: 'Notlar'),
										],
									),
								),
							),
						],
						body: TabBarView(
							controller: _mainTab,
							children: [
								_buildGenelTab(),
								_buildNotlarTab(),
							],
						),
					),
				),
			),
		);
	}

	Widget _buildTopBar() {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
			child: Row(
				children: [
					IconButton(
						icon: Icon(Icons.arrow_back, color: scheme.onSurface),
						onPressed: () => Navigator.of(context).pop(),
					),
					Expanded(
						child: Text(
							'Müşteri Detayı',
							style: TextStyle(
								fontSize: 18,
								fontWeight: FontWeight.w800,
								color: scheme.onSurface,
								letterSpacing: -0.2,
							),
						),
					),
					if (Yetki.varMi('musteri.ekle_duzenle'))
						IconButton(
							icon: Icon(Icons.edit_outlined, color: scheme.onSurface),
							tooltip: 'Düzenle',
							onPressed: _openDuzenle,
						),
				],
			),
		);
	}

	Widget _buildHero() {
		final m = widget.md;
		final url = (m.profil_resim != null &&
				m.profil_resim != 'null' &&
				m.profil_resim!.isNotEmpty)
				? m.profil_resim!
				: null;
		return Container(
			margin: const EdgeInsets.symmetric(horizontal: 12),
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				gradient: LinearGradient(
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
					colors: [_primary, _primaryDark],
				),
				borderRadius: BorderRadius.circular(20),
				boxShadow: [
					BoxShadow(
						color: _primary.withValues(alpha: 0.25),
						blurRadius: 16,
						offset: const Offset(0, 6),
					),
				],
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						decoration: BoxDecoration(
							shape: BoxShape.circle,
							border: Border.all(color: Colors.white, width: 3),
						),
						child: CircleAvatar(
							radius: 38,
							backgroundColor: Colors.white24,
							backgroundImage: url != null ? NetworkImage(url) : null,
							child: url == null
									? const Icon(Icons.person,
											color: Colors.white, size: 40)
									: null,
						),
					),
					const SizedBox(width: 16),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									_safe(m.name),
									style: const TextStyle(
										color: Colors.white,
										fontSize: 20,
										fontWeight: FontWeight.w700,
									),
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
								const SizedBox(height: 6),
								Container(
									padding: const EdgeInsets.symmetric(
											horizontal: 10, vertical: 4),
									decoration: BoxDecoration(
										color: _statusColor(),
										borderRadius: BorderRadius.circular(20),
									),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Icon(_statusIcon(),
													color: Colors.white, size: 14),
											const SizedBox(width: 4),
											Text(
												_statusLabel(),
												style: const TextStyle(
													color: Colors.white,
													fontSize: 11,
													fontWeight: FontWeight.w600,
												),
											),
										],
									),
								),
								if (m.cep_telefon.isNotEmpty &&
										m.cep_telefon != 'null') ...[
									const SizedBox(height: 8),
									_heroChip(Icons.phone, Yetki.telefonGoster(m.cep_telefon)),
								],
								if (m.email.isNotEmpty && m.email != 'null') ...[
									const SizedBox(height: 4),
									_heroChip(Icons.mail_outline, m.email),
								],
							],
						),
					),
				],
			),
		);
	}

	Widget _heroChip(IconData icon, String text) {
		return Row(
			children: [
				Icon(icon, color: Colors.white70, size: 14),
				const SizedBox(width: 6),
				Expanded(
					child: Text(
						text,
						style: const TextStyle(color: Colors.white, fontSize: 13),
						overflow: TextOverflow.ellipsis,
					),
				),
			],
		);
	}

	Widget _buildQuickActions() {
		final tel = widget.md.cep_telefon;
		final hasTel = tel.isNotEmpty && tel != 'null';
		// Ara/Mesaj/WhatsApp ve SMS musteri.telefon_gor yetkisine ve pazarlama
		// yetkilerine bagimli. Yetki yoksa butonu hic gosterme.
		final telGor = Yetki.varMi('musteri.telefon_gor');
		final smsYet = Yetki.varMi('pazarlama.sms_gonder');
		final waYet = Yetki.varMi('pazarlama.whatsapp_gonder');
		final duzenleYet = Yetki.varMi('musteri.ekle_duzenle');
		final actions = <Widget>[];
		if (telGor) {
			actions.add(Expanded(
				child: _actionBtn(
					Icons.call,
					'Ara',
					const Color(0xFF43A047),
					enabled: hasTel,
					onTap: hasTel ? _onCallPressed : null,
				),
			));
		}
		if (telGor && smsYet) {
			if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
			actions.add(Expanded(
				child: _actionBtn(
					Icons.sms_outlined,
					'Mesaj',
					const Color(0xFF1E88E5),
					enabled: hasTel,
					onTap: hasTel ? () => _launch('sms:${_localNumber()}') : null,
				),
			));
		}
		if (telGor && waYet) {
			if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
			actions.add(Expanded(
				child: _actionBtn(
					Icons.chat_bubble_outline,
					'WhatsApp',
					const Color(0xFF25D366),
					enabled: hasTel,
					onTap: hasTel
							? () => _launch('https://wa.me/${_waNumber()}')
							: null,
				),
			));
		}
		if (duzenleYet) {
			if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
			actions.add(Expanded(
				child: _actionBtn(
					Icons.edit_outlined,
					'Düzenle',
					_primary,
					onTap: _openDuzenle,
				),
			));
		}
		if (actions.isEmpty) return const SizedBox.shrink();
		return Padding(
			padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
			child: Row(children: actions),
		);
	}

	Widget _actionBtn(
		IconData icon,
		String label,
		Color color, {
		bool enabled = true,
		VoidCallback? onTap,
	}) {
		return Material(
			color: Colors.white,
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				borderRadius: BorderRadius.circular(14),
				onTap: enabled ? onTap : null,
				child: Container(
					padding: const EdgeInsets.symmetric(vertical: 12),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(14),
						border: Border.all(color: Colors.grey.shade200),
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(
								icon,
								color: enabled ? color : Colors.grey.shade400,
								size: 22,
							),
							const SizedBox(height: 4),
							Text(
								label,
								style: TextStyle(
									fontSize: 11,
									color: enabled
											? Colors.black87
											: Colors.grey.shade400,
									fontWeight: FontWeight.w600,
								),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildStatsRow() {
		final m = widget.md;
		final randevu = _randevuCount.toString();
		final sonRandevu = _formatDate(m.son_randevu_tarihi);
		final uyelik = _formatDate(m.kayit_tarihi);
		return Padding(
			padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
			child: Row(
				children: [
					Expanded(
						child: _statCard(
							Icons.event,
							'Toplam Randevu',
							randevu,
						),
					),
					const SizedBox(width: 8),
					Expanded(
						child: _statCard(
							Icons.history,
							'Son Ziyaret',
							sonRandevu == '-' ? 'Yok' : sonRandevu,
						),
					),
					const SizedBox(width: 8),
					Expanded(
						child: _statCard(
							Icons.person_add_alt_1,
							'Üyelik',
							uyelik == '-' ? 'Yok' : uyelik,
						),
					),
				],
			),
		);
	}

	Widget _statCard(IconData icon, String label, String value) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: Colors.grey.shade200),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, color: _primary, size: 18),
					const SizedBox(height: 8),
					Text(
						value,
						style: const TextStyle(
								fontSize: 14, fontWeight: FontWeight.w700),
						maxLines: 1,
						overflow: TextOverflow.ellipsis,
					),
					const SizedBox(height: 2),
					Text(
						label,
						style: TextStyle(
							fontSize: 10,
							color: Colors.grey.shade600,
						),
					),
				],
			),
		);
	}

	Widget _buildGenelTab() {
		final m = widget.md;
		return ListView(
			key: const PageStorageKey('musteri_detay_genel'),
			padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
			children: [
				_buildSectionsGrid(),
				const SizedBox(height: 12),
				_sectionCard(
					'Kişisel Bilgiler',
					Icons.badge_outlined,
					[
						_kvSatir('ID', _safe(m.id)),
						_kvSatir('Ad Soyad', _safe(m.name)),
						_kvSatir('Telefon', Yetki.telefonGoster(_safe(m.cep_telefon))),
						_kvSatir('E-posta', _safe(m.email)),
						_kvSatir('Doğum Tarihi', _formatDate(m.dogum_tarihi)),
						_kvSatir('TC Kimlik No', _safe(m.tc_kimlik_no)),
						_kvSatir('Cinsiyet', _cinsiyetText(m.cinsiyet)),
						_kvSatir('Referans', _referansText(m.musteri_tipi)),
					],
				),
				const SizedBox(height: 12),
				_sectionCard(
					'Notlar',
					Icons.sticky_note_2_outlined,
					[
						Padding(
							padding: const EdgeInsets.symmetric(vertical: 4),
							child: Text(
								_safe(m.ozel_notlar),
								style: const TextStyle(height: 1.4, fontSize: 13),
							),
						),
					],
				),
			],
		);
	}

	Widget _buildSectionsGrid() {
		final items = <_ActionItem>[];
		if (Yetki.varMi('randevu.takvim_gor')) {
			items.add(_ActionItem(
				'Randevular',
				Icons.calendar_today_outlined,
				const Color(0xFF1E88E5),
				() => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => MusteriRandevulariMenu(
							kullanicirolu: widget.kullanicirolu,
							isletmebilgi: widget.isletmebilgi,
							md: widget.md,
						),
					),
				),
			));
		}
		if (Yetki.varMi('paket.seans_takip')) {
			items.add(_ActionItem(
				'Seanslar',
				Icons.spa_outlined,
				const Color(0xFF8E24AA),
				() => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => IslemlerveSeanslar(
							isletmebilgi: widget.isletmebilgi,
							kullanici: widget.md,
						),
					),
				),
			));
		}
		if (Yetki.varMi('form.olustur') || Yetki.varMi('form.gonder')) {
			items.add(_ActionItem(
				'Sözleşmeler',
				Icons.description_outlined,
				const Color(0xFF00897B),
				() => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => ArsivDetay(
							isletmebilgi: widget.isletmebilgi,
							md: widget.md,
						),
					),
				),
			));
		}
		if (Yetki.varMi('musteri.gecmis_satis_gor')) {
			items.add(_ActionItem(
				'Satışlar',
				Icons.shopping_bag_outlined,
				const Color(0xFFFB8C00),
				() => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => MusteriAdiayonlari(
							kullanicirolu: widget.kullanicirolu,
							isletmebilgi: widget.isletmebilgi,
							kullanici: widget.md,
						),
					),
				),
			));
		}
		items.add(_ActionItem(
			'Sağlık Bilgileri',
			Icons.health_and_safety_outlined,
			const Color(0xFFE53935),
			() => Navigator.push(
				context,
				MaterialPageRoute(
					builder: (_) => MusteriSaglikBilgileri(md: widget.md),
				),
			),
		));
		return LayoutBuilder(
			builder: (context, c) {
				final cols = c.maxWidth >= 700 ? 5 : (c.maxWidth >= 500 ? 4 : 3);
				return GridView.builder(
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					padding: EdgeInsets.zero,
					gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
						crossAxisCount: cols,
						mainAxisSpacing: 8,
						crossAxisSpacing: 8,
						childAspectRatio: 0.95,
					),
					itemCount: items.length,
					itemBuilder: (ctx, i) {
						final it = items[i];
						return Material(
							color: Colors.white,
							borderRadius: BorderRadius.circular(12),
							child: InkWell(
								onTap: it.onTap,
								borderRadius: BorderRadius.circular(12),
								child: Container(
									padding: const EdgeInsets.all(8),
									decoration: BoxDecoration(
										borderRadius: BorderRadius.circular(12),
										border: Border.all(color: Colors.grey.shade200),
									),
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Container(
												padding: const EdgeInsets.all(8),
												decoration: BoxDecoration(
													color: it.color.withOpacity(0.12),
													borderRadius: BorderRadius.circular(10),
												),
												child: Icon(it.icon, color: it.color, size: 20),
											),
											const SizedBox(height: 6),
											Text(
												it.label,
												textAlign: TextAlign.center,
												style: const TextStyle(
													fontWeight: FontWeight.w600,
													fontSize: 11,
													height: 1.2,
												),
												maxLines: 2,
												overflow: TextOverflow.ellipsis,
											),
										],
									),
								),
							),
						);
					},
				);
			},
		);
	}

	Widget _sectionCard(String title, IconData icon, List<Widget> children) {
		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: Colors.grey.shade200),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
						child: Row(
							children: [
								Icon(icon, color: _primary, size: 18),
								const SizedBox(width: 8),
								Text(
									title,
									style: const TextStyle(
										fontWeight: FontWeight.w700,
										fontSize: 14,
									),
								),
							],
						),
					),
					Divider(height: 1, color: Colors.grey.shade200),
					Padding(
						padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: children,
						),
					),
				],
			),
		);
	}

	Widget _kvSatir(String label, String value) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 6),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					SizedBox(
						width: 110,
						child: Text(
							label,
							style: TextStyle(
								color: Colors.grey.shade600,
								fontSize: 12,
							),
						),
					),
					Expanded(
						child: Text(
							value,
							style: const TextStyle(
									fontSize: 13, fontWeight: FontWeight.w500),
						),
					),
				],
			),
		);
	}

	Widget _buildNotlarTab() {
		return Column(
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
					child: Container(
						padding: const EdgeInsets.all(4),
						decoration: BoxDecoration(
							color: Colors.grey.shade200,
							borderRadius: BorderRadius.circular(12),
						),
						child: TabBar(
							controller: _notTab,
							indicator: BoxDecoration(
								color: Colors.white,
								borderRadius: BorderRadius.circular(10),
								boxShadow: [
									BoxShadow(
										color: Colors.black.withOpacity(0.05),
										blurRadius: 4,
									),
								],
							),
							indicatorSize: TabBarIndicatorSize.tab,
							labelColor: _primary,
							unselectedLabelColor: Colors.grey.shade700,
							labelStyle: const TextStyle(
									fontWeight: FontWeight.w600, fontSize: 13),
							dividerColor: Colors.transparent,
							splashBorderRadius: BorderRadius.circular(10),
							tabs: const [
								Tab(text: 'Müşteri Hareketleri'),
								Tab(text: 'İşlem Notları'),
							],
						),
					),
				),
				Expanded(
					child: FutureBuilder<List<Map<String, dynamic>>>(
						future: _randevularFuture,
						builder: (context, snap) {
							if (snap.connectionState != ConnectionState.done) {
								return Center(
										child: CircularProgressIndicator(
												color: _primary));
							}
							final randevular = snap.data ?? const [];
							return TabBarView(
								controller: _notTab,
								children: [
									_buildTimeline(randevular, 'personel_notu'),
									_buildTimeline(
											randevular, 'randevu_sonrasi_not'),
								],
							);
						},
					),
				),
			],
		);
	}

	Widget _buildTimeline(
			List<Map<String, dynamic>> randevular, String field) {
		if (randevular.isEmpty) {
			return ListView(
				padding: const EdgeInsets.all(20),
				children: [
					Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							color: Colors.amber.shade50,
							borderRadius: BorderRadius.circular(12),
							border: Border.all(color: Colors.amber.shade200),
						),
						child: Row(
							children: [
								Icon(Icons.info_outline,
										color: Colors.amber.shade800),
								const SizedBox(width: 8),
								Expanded(
									child: Text(
										'Bu müşteriye ait randevu veya işlem bulunamadı.',
										style: TextStyle(
												color: Colors.amber.shade900),
									),
								),
							],
						),
					),
				],
			);
		}
		final wide = MediaQuery.of(context).size.width >= 600;
		return ListView.builder(
			key: PageStorageKey('musteri_detay_$field'),
			padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
			itemCount: randevular.length,
			itemBuilder: (context, i) {
				final r = randevular[i];
				final tarih = _formatDate(r['tarih']?.toString());
				final hizmetler = (r['hizmetler'] as List?) ?? const [];
				final hizmetIsimleri = hizmetler
						.map((h) {
							final mm = h is Map ? h : const {};
							final nested = mm['hizmetler'];
							if (nested is Map && nested['hizmet_adi'] != null) {
								return nested['hizmet_adi'].toString();
							}
							if (mm['hizmet_adi'] != null) {
								return mm['hizmet_adi'].toString();
							}
							return '';
						})
						.where((s) => s.isNotEmpty)
						.toList();
				final raw = r[field]?.toString();
				final notText = (raw == null ||
						raw == 'null' ||
						raw.trim().isEmpty)
						? null
						: raw;
				final isLast = i == randevular.length - 1;
				return IntrinsicHeight(
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							SizedBox(
								width: 28,
								child: Column(
									children: [
										const SizedBox(height: 18),
										Container(
											width: 12,
											height: 12,
											decoration: BoxDecoration(
												color: _primary,
												shape: BoxShape.circle,
												border: Border.all(
														color: Colors.white,
														width: 2),
												boxShadow: [
													BoxShadow(
														color: _primary
																.withOpacity(0.4),
														blurRadius: 6,
													),
												],
											),
										),
										Expanded(
											child: Container(
												width: 2,
												color: isLast
														? Colors.transparent
														: Colors.grey.shade300,
											),
										),
									],
								),
							),
							Expanded(
								child: Container(
									margin: const EdgeInsets.only(bottom: 12),
									padding: const EdgeInsets.all(14),
									decoration: BoxDecoration(
										color: Colors.white,
										borderRadius: BorderRadius.circular(12),
										border: Border.all(
												color: Colors.grey.shade200),
									),
									child: Column(
										crossAxisAlignment:
												CrossAxisAlignment.start,
										children: [
											if (wide && hizmetIsimleri.isNotEmpty)
												Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Row(
															mainAxisSize: MainAxisSize.min,
															children: [
																Icon(Icons.event, size: 14, color: _primary),
																const SizedBox(width: 6),
																Text(
																	tarih,
																	style: const TextStyle(
																		fontWeight: FontWeight.w700,
																		fontSize: 13,
																	),
																),
															],
														),
														const SizedBox(width: 12),
														Expanded(
															child: Wrap(
																spacing: 6,
																runSpacing: 4,
																children: hizmetIsimleri
																		.map((h) => Container(
																					padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
																					decoration: BoxDecoration(
																						color: _primary.withValues(alpha: 0.10),
																						borderRadius: BorderRadius.circular(20),
																					),
																					child: Text(
																						h,
																						style: TextStyle(
																							fontSize: 11,
																							color: _primary,
																							fontWeight: FontWeight.w500,
																						),
																					),
																				))
																		.toList(),
															),
														),
													],


												)
											else ...[
												Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														Icon(Icons.event, size: 14, color: _primary),
														const SizedBox(width: 6),
														Text(
															tarih,
															style: const TextStyle(
																fontWeight: FontWeight.w700,
																fontSize: 13,
															),
														),
													],
												),
												if (hizmetIsimleri.isNotEmpty) ...[
													const SizedBox(height: 8),
													Wrap(
														spacing: 6,
														runSpacing: 4,
														children: hizmetIsimleri
																.map((h) => Container(
																			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
																			decoration: BoxDecoration(
																				color: _primary.withValues(alpha: 0.10),
																				borderRadius: BorderRadius.circular(20),
																			),
																			child: Text(
																				h,
																				style: TextStyle(
																					fontSize: 11,
																					color: _primary,
																					fontWeight: FontWeight.w500,
																				),
																			),
																		))
																.toList(),
													),
												],
											],
											const SizedBox(height: 10),
											Container(
												width: double.infinity,
												padding:
														const EdgeInsets.all(10),
												decoration: BoxDecoration(
													color: Colors.grey.shade50,
													borderRadius:
															BorderRadius.circular(
																	8),
												),
												child: Text(
													notText ??
															'Not eklenmemiş.',
													style: TextStyle(
														fontSize: 13,
														height: 1.4,
														color: notText == null
																? Colors.grey
																: Colors
																		.black87,
														fontStyle: notText == null
																? FontStyle
																		.italic
																: FontStyle
																		.normal,
													),
												),
											),
										],
									),
								),
							),
						],
					),
				);
			},
		);
	}

}

class _ActionItem {
	final String label;
	final IconData icon;
	final Color color;
	final VoidCallback onTap;
	_ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _DialOption {
	final String label;
	final IconData icon;
	final String url;
	_DialOption(this.label, this.icon, this.url);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
	final TabBar tabBar;
	_StickyTabBarDelegate(this.tabBar);

	@override
	double get minExtent => tabBar.preferredSize.height;
	@override
	double get maxExtent => tabBar.preferredSize.height;

	@override
	Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
		return Container(
			color: const Color(0xFFF5F6FA),
			child: tabBar,
		);
	}

	@override
	bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
			tabBar != oldDelegate.tabBar;
}
