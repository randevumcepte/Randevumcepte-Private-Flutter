import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Backend/yetki.dart';
import 'package:randevu_sistem/Models/musteridanisanreferans.dart';
import 'package:randevu_sistem/Models/odalar.dart';
import 'package:randevu_sistem/Models/ongorusmeler.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/sehirler.dart';
import 'package:randevu_sistem/Frontend/lazyload.dart';

class OnGorusmeDuzenle extends StatefulWidget {
	final OnGorusmeDataSource ongorusmedatasource;
	final OnGorusme ongorusme;
	final dynamic isletmebilgi;
	const OnGorusmeDuzenle({
		Key? key,
		required this.ongorusmedatasource,
		required this.ongorusme,
		required this.isletmebilgi,
	}) : super(key: key);

	@override
	State<OnGorusmeDuzenle> createState() => _OnGorusmeDuzenleState();
}

class _OnGorusmeDuzenleState extends State<OnGorusmeDuzenle> {
	TimeOfDay _selectedTime = TimeOfDay.now();

	final GlobalKey<LazyDropdownState> _lazyDropdownKey = GlobalKey<LazyDropdownState>();
	MusteriDanisan? selectedMusteri;
	late List<Sehir> ongorusmesehir;
	Sehir? selectedongorusmesehir;

	final List<Referans> ongorusmereferans = [
		Referans(id: "", referans: "Yok"),
		Referans(id: "1", referans: "İnternet"),
		Referans(id: "2", referans: "Reklam"),
		Referans(id: "3", referans: "Instagram"),
		Referans(id: "4", referans: "Facebook"),
		Referans(id: "5", referans: "Tanıdık"),
	];
	Referans? selectedongorusmereferans;
	OnGorusmeNedeni? selectedongorusmesebep;
	Personel? selectedongorusmeyapan;
	// Takvim odaya gore ise (randevu_takvim_turu == 3) oda secimi gosterilir
	Oda? selectedongorusmeoda;
	late String seciliisletme;

	bool get _odaTakvim {
		final t = int.tryParse(
				widget.isletmebilgi["randevu_takvim_turu"]?.toString() ?? '0') ??
				0;
		return t == 3;
	}

	final TextEditingController ongorusmesebepcontroller = TextEditingController();
	final TextEditingController adsoyad = TextEditingController();
	final TextEditingController telefon = TextEditingController();
	// Personel "musteri.telefon_gor" yetkisi yoksa telefon maskelenir; save'de orijinal gonderilir
	String _telOrijinal = '';
	bool get _telGor => Yetki.varMi('musteri.telefon_gor');
	final TextEditingController meslek = TextEditingController();
	final TextEditingController ongorusmetarihi = TextEditingController();
	final TextEditingController ongorusmesaati = TextEditingController();
	final TextEditingController ongorusmeaciklama = TextEditingController();
	final TextEditingController ongorusmeyapancontroller = TextEditingController();
	final TextEditingController ongorusmeodacontroller = TextEditingController();

	late List<Personel> ongorusmeyapan;
	late List<OnGorusmeNedeni> ongorusmeneden;
	List<Oda> ongorusmeodalar = [];
	bool yukleniyor = true;

	String _selectedGender = '';

	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

	@override
	void initState() {
		super.initState();
		initialize();
	}

	Future<void> initialize() async {
		try {
			seciliisletme = (await secilisalonid())!;
			final isletmeVerileri = await isletmeVerileriGetir(
					seciliisletme, false, '', '', '', 0, 0);
			List<MusteriDanisan> musteridanisan =
					isletmeVerileri['musteriler'] ?? [];
			List<Personel> isletmepersonellerliste =
					isletmeVerileri['personeller'] ?? [];
			List<OnGorusmeNedeni> ongorusmenedeniliste =
					isletmeVerileri['onGorusmeNedeni'] ?? [];
			List<Sehir> sehirler = isletmeVerileri['sehirler'] ?? [];
			List<Oda> odalar = isletmeVerileri['odalar'] ?? [];

			if (!mounted) return;
			setState(() {
				ongorusmeyapan = isletmepersonellerliste;
				ongorusmesehir = sehirler;
				ongorusmeneden = ongorusmenedeniliste;
				ongorusmeodalar = odalar;

				// Oda secimi (takvim odaya gore ise mevcut oda onceden gelsin)
				if (widget.ongorusme.oda_id.isNotEmpty &&
						widget.ongorusme.oda_id != "null") {
					try {
						selectedongorusmeoda = odalar.firstWhere(
							(e) => e.id.toString() ==
									widget.ongorusme.oda_id.toString(),
						);
					} catch (_) {
						selectedongorusmeoda = null;
					}
				}

				// Müşteri seçimi
				if (widget.ongorusme.musteri["id"] != null) {
					try {
						selectedMusteri = musteridanisan.firstWhere(
							(e) => e.id.toString() ==
									widget.ongorusme.musteri["id"].toString(),
						);
					} catch (e) {
						selectedMusteri = null;
					}
				}

				// Referans seçimi
				try {
					selectedongorusmereferans = ongorusmereferans.firstWhere(
							(item) => item.id == (widget.ongorusme.musteri_tipi));
				} catch (_) {
					selectedongorusmereferans = ongorusmereferans
							.firstWhere((item) => item.id == "");
				}

				// Alanları doldur
				adsoyad.text =
						widget.ongorusme.ad_soyad != 'null' ? widget.ongorusme.ad_soyad : '';
				_telOrijinal = widget.ongorusme.cep_telefon != 'null'
						? widget.ongorusme.cep_telefon
						: '';
				telefon.text = _telGor ? _telOrijinal : Yetki.telefonGoster(_telOrijinal);
				meslek.text =
						widget.ongorusme.meslek != 'null' ? widget.ongorusme.meslek : '';
				ongorusmetarihi.text =
						widget.ongorusme.tarih != 'null' ? widget.ongorusme.tarih : '';
				ongorusmesaati.text =
						widget.ongorusme.saat != 'null' ? widget.ongorusme.saat : '';
				ongorusmeaciklama.text = widget.ongorusme.aciklama != 'null'
						? widget.ongorusme.aciklama
						: '';

				// Personel seçimi
				if (widget.ongorusme.personel["id"] != null) {
					try {
						selectedongorusmeyapan = isletmepersonellerliste.firstWhere(
							(e) => e.id.toString() ==
									widget.ongorusme.personel["id"].toString(),
						);
					} catch (_) {
						selectedongorusmeyapan = null;
					}
				}

				// Ön görüşme nedeni
				try {
					final sebepAdi = _ongorusmeSebebiGetir(widget.ongorusme);
					selectedongorusmesebep = ongorusmenedeniliste
							.firstWhere((e) => e.getPaketUrunAdi() == sebepAdi);
				} catch (_) {
					selectedongorusmesebep = null;
				}

				_selectedGender = _musteriDanisanCinsiyet(widget.ongorusme);

				if (widget.ongorusme.il_id.isNotEmpty) {
					try {
						selectedongorusmesehir = sehirler.firstWhere(
							(e) => e.id.toString() == widget.ongorusme.il_id.toString(),
						);
					} catch (_) {
						selectedongorusmesehir = null;
					}
				}

				if (widget.ongorusme.saat.isNotEmpty) {
					try {
						final parts = widget.ongorusme.saat.split(':');
						if (parts.length == 2) {
							_selectedTime = TimeOfDay(
								hour: int.parse(parts[0]),
								minute: int.parse(parts[1]),
							);
						}
					} catch (_) {}
				}

				yukleniyor = false;
			});
		} catch (e) {
			log('Initialize hatası: $e');
			if (!mounted) return;
			setState(() => yukleniyor = false);
		}
	}

	String _musteriDanisanCinsiyet(OnGorusme og) {
		if (og.cinsiyet == "0") return "kadin";
		if (og.cinsiyet == "1") return "erkek";
		return "";
	}

	String _ongorusmeSebebiGetir(OnGorusme og) {
		if (og.paket_id.isNotEmpty && og.paket_id != "null") {
			return "${og.paket["paket_adi"] ?? "Paket"} (Paket)";
		}
		if (og.urun_id.isNotEmpty && og.urun_id != "null") {
			return "${og.urun["urun_adi"] ?? "Ürün"} (Ürün)";
		}
		return "";
	}

	@override
	void dispose() {
		ongorusmesebepcontroller.dispose();
		adsoyad.dispose();
		telefon.dispose();
		meslek.dispose();
		ongorusmetarihi.dispose();
		ongorusmesaati.dispose();
		ongorusmeaciklama.dispose();
		ongorusmeyapancontroller.dispose();
		ongorusmeodacontroller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Scaffold(
			backgroundColor: Colors.white,
			resizeToAvoidBottomInset: true,
			body: PremiumGradientBg(
				child: SafeArea(
					bottom: false,
					child: yukleniyor
							? Center(child: CircularProgressIndicator(color: scheme.primary))
							: GestureDetector(
								onTap: () => FocusScope.of(context).unfocus(),
								child: Column(
									children: [
										_topBar(context),
										const SizedBox(height: 10),
										_header(context),
										const SizedBox(height: 12),
										Expanded(
											child: Form(
												key: _formKey,
												child: ListView(
													physics: const BouncingScrollPhysics(),
													padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
													children: [
														_formCard(context),
														const SizedBox(height: 16),
													],
												),
											),
										),
										_bottomBar(context),
									],
								),
							),
				),
			),
		);
	}

	// ───────────────────────────── Top Bar
	Widget _topBar(BuildContext context) {
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
									Icon(Icons.edit_note_rounded,
											size: 18, color: scheme.primary),
									const SizedBox(width: 6),
									Flexible(
										child: Text(
											'Ön Görüşme Düzenle',
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: TextStyle(
												fontSize: 13,
												fontWeight: FontWeight.w700,
												color: scheme.primary,
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

	// ───────────────────────────── Header
	Widget _header(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Ön Görüşme Düzenle',
						style: TextStyle(
							fontSize: 24,
							fontWeight: FontWeight.w800,
							letterSpacing: -0.5,
							color: scheme.onSurface,
							height: 1.1,
						),
					),
					const SizedBox(height: 3),
					Text(
						adsoyad.text.isNotEmpty ? adsoyad.text : 'Kayıt bilgilerini güncelleyin.',
						style: TextStyle(
							fontSize: 12,
							fontWeight: FontWeight.w500,
							color: scheme.onSurface.withValues(alpha: 0.55),
						),
					),
				],
			),
		);
	}

	// ───────────────────────────── Single Unified Form Card
	Widget _formCard(BuildContext context) {
		return PremiumGlassCard(
			padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_rowLabel('Müşteri', Icons.person_search_rounded,
							trailing: _addMusteriBtn()),
					const SizedBox(height: 6),
					_lazyDropdownWrap(),
					const SizedBox(height: 12),
					_rowLabel('Ad Soyad', Icons.badge_outlined),
					const SizedBox(height: 6),
					_premiumTextField(controller: adsoyad, hint: 'Ad ve soyad'),
					const SizedBox(height: 12),
					_rowLabel('Telefon', Icons.phone_outlined),
					const SizedBox(height: 6),
					_premiumTextField(
						controller: telefon,
						hint: '5xx xxx xx xx',
						keyboardType: TextInputType.phone,
						readOnly: !_telGor,
					),
					const SizedBox(height: 12),
					_rowLabel('Cinsiyet', Icons.wc_outlined),
					const SizedBox(height: 6),
					Row(
						children: [
							Expanded(child: _genderPill('kadin', 'Kadın', Icons.female_rounded)),
							const SizedBox(width: 10),
							Expanded(child: _genderPill('erkek', 'Erkek', Icons.male_rounded)),
						],
					),
					const SizedBox(height: 12),
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_rowLabel('Tarih', Icons.calendar_month_outlined),
										const SizedBox(height: 6),
										_premiumTextField(
											controller: ongorusmetarihi,
											hint: 'YYYY-AA-GG',
											readOnly: true,
											validator: (v) =>
													(v == null || v.isEmpty) ? 'Tarih' : null,
											onTap: () async {
												final picked = await showDatePicker(
													context: context,
													initialDate: DateTime.tryParse(
															ongorusmetarihi.text) ??
															DateTime.now(),
													firstDate: DateTime(1950),
													lastDate: DateTime(2100),
												);
												if (picked != null) {
													setState(() {
														ongorusmetarihi.text =
																DateFormat('yyyy-MM-dd').format(picked);
													});
												}
											},
										),
									],
								),
							),
							const SizedBox(width: 10),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_rowLabel('Saat', Icons.access_time_rounded),
										const SizedBox(height: 6),
										_premiumTextField(
											controller: ongorusmesaati,
											hint: '--:--',
											readOnly: true,
											validator: (v) =>
													(v == null || v.isEmpty) ? 'Saat' : null,
											onTap: () => _showModernTimePicker(context),
										),
									],
								),
							),
						],
					),
					const SizedBox(height: 12),
					_rowLabel('Ön Görüşme Nedeni', Icons.inventory_2_outlined),
					const SizedBox(height: 6),
					_premiumDropdown<OnGorusmeNedeni>(
						value: selectedongorusmesebep,
						items: ongorusmeneden
								.map((e) => DropdownMenuItem(
											value: e,
											child: Text(
												e.getPaketUrunAdi(),
												overflow: TextOverflow.ellipsis,
												maxLines: 1,
											),
										))
								.toList(),
						hint: 'Sebep seç',
						icon: Icons.inventory_2_outlined,
						searchController: ongorusmesebepcontroller,
						searchMatcher: (item, q) => item.getPaketUrunAdi()
								.toLowerCase()
								.contains(q.toLowerCase()),
						onChanged: (v) => setState(() => selectedongorusmesebep = v),
					),
					const SizedBox(height: 12),
					_rowLabel('Referans', Icons.share_outlined),
					const SizedBox(height: 6),
					_premiumDropdown<Referans>(
						value: selectedongorusmereferans,
						items: ongorusmereferans
								.map((e) => DropdownMenuItem(value: e, child: Text(e.referans)))
								.toList(),
						hint: 'Referans seç',
						icon: Icons.share_outlined,
						onChanged: (v) => setState(() => selectedongorusmereferans = v),
					),
					const SizedBox(height: 12),
					_rowLabel('Görüşmeyi Yapan', Icons.person_pin_outlined),
					const SizedBox(height: 6),
					_premiumDropdown<Personel>(
						value: selectedongorusmeyapan,
						items: ongorusmeyapan
								.map((e) => DropdownMenuItem(
											value: e,
											child: Text(
												e.personel_adi,
												overflow: TextOverflow.ellipsis,
												maxLines: 1,
											),
										))
								.toList(),
						hint: 'Personel seç',
						icon: Icons.person_pin_outlined,
						searchController: ongorusmeyapancontroller,
						searchMatcher: (item, q) =>
								item.personel_adi.toLowerCase().contains(q.toLowerCase()),
						onChanged: (v) => setState(() => selectedongorusmeyapan = v),
					),
					if (_odaTakvim) ...[
						const SizedBox(height: 12),
						_rowLabel('Oda', Icons.meeting_room_outlined),
						const SizedBox(height: 6),
						_premiumDropdown<Oda>(
							value: selectedongorusmeoda,
							items: ongorusmeodalar
									.map((e) => DropdownMenuItem(
												value: e,
												child: Text(
													e.oda_adi,
													overflow: TextOverflow.ellipsis,
													maxLines: 1,
												),
											))
									.toList(),
							hint: ongorusmeodalar.isEmpty
									? 'Sistemde oda bulunmamaktadır'
									: 'Oda seç',
							icon: Icons.meeting_room_outlined,
							searchController: ongorusmeodacontroller,
							searchMatcher: (item, q) =>
									item.oda_adi.toLowerCase().contains(q.toLowerCase()),
							onChanged: (v) => setState(() => selectedongorusmeoda = v),
						),
					],
					const SizedBox(height: 12),
					_rowLabel('Açıklama', Icons.notes_rounded),
					const SizedBox(height: 6),
					_premiumTextField(
						controller: ongorusmeaciklama,
						hint: 'Notlar (opsiyonel)',
						maxLines: 2,
					),
				],
			),
		);
	}

	Widget _addMusteriBtn() {
		final scheme = Theme.of(context).colorScheme;
		return InkWell(
			onTap: _openYeniMusteriSheet,
			borderRadius: BorderRadius.circular(999),
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
				decoration: BoxDecoration(
					gradient: LinearGradient(
						colors: [scheme.primary, scheme.tertiary],
						begin: Alignment.topLeft,
						end: Alignment.bottomRight,
					),
					borderRadius: BorderRadius.circular(999),
					boxShadow: [
						BoxShadow(
							color: scheme.primary.withValues(alpha: 0.30),
							blurRadius: 10,
							offset: const Offset(0, 3),
						),
					],
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(Icons.person_add_alt_1_rounded,
								size: 14, color: scheme.onPrimary),
						const SizedBox(width: 4),
						Text(
							'Yeni',
							style: TextStyle(
								fontSize: 11,
								fontWeight: FontWeight.w800,
								color: scheme.onPrimary,
							),
						),
					],
				),
			),
		);
	}

	Widget _lazyDropdownWrap() {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			height: 46,
			padding: const EdgeInsets.symmetric(horizontal: 10),
			decoration: BoxDecoration(
				color: scheme.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(
					color: scheme.primary.withValues(alpha: 0.18),
					width: 1.2,
				),
			),
			child: LazyDropdown(
				key: _lazyDropdownKey,
				salonId: seciliisletme,
				selectedItem: selectedMusteri,
				onChanged: (value) {
					if (value == null) return;
					setState(() {
						selectedMusteri = value;
						adsoyad.text = value.name;
						_telOrijinal = value.cep_telefon;
						telefon.text = _telGor ? _telOrijinal : Yetki.telefonGoster(_telOrijinal);
						if (value.cinsiyet == "0") _selectedGender = "kadin";
						if (value.cinsiyet == "1") _selectedGender = "erkek";
						if (value.il_id != "null") {
							selectedongorusmesehir = ongorusmesehir
									.firstWhere((item) => item.id == value.il_id);
						}
						if (value.musteri_tipi != "null") {
							selectedongorusmereferans = ongorusmereferans
									.firstWhere((item) => item.id == value.musteri_tipi);
						}
						if (value.meslek != "null") meslek.text = value.meslek;
					});
				},
			),
		);
	}

	Widget _genderPill(String value, String label, IconData icon) {
		final scheme = Theme.of(context).colorScheme;
		final selected = _selectedGender == value;
		return Material(
			color: Colors.transparent,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				onTap: () => setState(() => _selectedGender = value),
				borderRadius: BorderRadius.circular(12),
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 200),
					curve: Curves.easeOut,
					padding: const EdgeInsets.symmetric(vertical: 10),
					decoration: BoxDecoration(
						gradient: selected
								? LinearGradient(
									colors: [scheme.primary, scheme.tertiary],
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
								)
								: null,
						color: selected ? null : scheme.primary.withValues(alpha: 0.05),
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: selected
									? Colors.transparent
									: scheme.primary.withValues(alpha: 0.18),
							width: 1.2,
						),
						boxShadow: selected
								? [
									BoxShadow(
										color: scheme.primary.withValues(alpha: 0.28),
										blurRadius: 12,
										offset: const Offset(0, 4),
									),
								]
								: null,
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(icon, size: 16, color: selected ? Colors.white : scheme.primary),
							const SizedBox(width: 6),
							Text(
								label,
								style: TextStyle(
									fontSize: 13,
									fontWeight: FontWeight.w700,
									color: selected ? Colors.white : scheme.onSurface,
								),
							),
						],
					),
				),
			),
		);
	}

	Widget _rowLabel(String label, IconData icon, {Widget? trailing}) {
		final scheme = Theme.of(context).colorScheme;
		return Row(
			children: [
				Icon(icon, size: 14, color: scheme.primary.withValues(alpha: 0.85)),
				const SizedBox(width: 5),
				Expanded(
					child: Text(
						label,
						style: TextStyle(
							fontSize: 12,
							fontWeight: FontWeight.w700,
							color: scheme.onSurface.withValues(alpha: 0.72),
							letterSpacing: 0.1,
						),
					),
				),
				if (trailing != null) trailing,
			],
		);
	}

	Widget _premiumTextField({
		required TextEditingController controller,
		required String hint,
		TextInputType? keyboardType,
		bool readOnly = false,
		int? maxLines,
		VoidCallback? onTap,
		String? Function(String?)? validator,
	}) {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			decoration: BoxDecoration(
				color: scheme.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(
					color: scheme.primary.withValues(alpha: 0.18),
					width: 1.2,
				),
			),
			child: TextFormField(
				controller: controller,
				keyboardType: keyboardType,
				readOnly: readOnly,
				maxLines: maxLines ?? 1,
				onTap: onTap,
				validator: validator,
				style: TextStyle(
					fontSize: 14,
					fontWeight: FontWeight.w600,
					color: scheme.onSurface,
				),
				decoration: InputDecoration(
					hintText: hint,
					hintStyle: TextStyle(
						color: scheme.onSurface.withValues(alpha: 0.40),
						fontSize: 13.5,
						fontWeight: FontWeight.w500,
					),
					border: InputBorder.none,
					enabledBorder: InputBorder.none,
					focusedBorder: InputBorder.none,
					errorStyle: const TextStyle(height: 0, fontSize: 0),
					contentPadding: EdgeInsets.symmetric(
						horizontal: 14,
						vertical: maxLines != null && maxLines > 1 ? 12 : 11,
					),
				),
			),
		);
	}

	Widget _premiumDropdown<T>({
		required T? value,
		required List<DropdownMenuItem<T>> items,
		required String hint,
		required IconData icon,
		required ValueChanged<T?> onChanged,
		TextEditingController? searchController,
		bool Function(T, String)? searchMatcher,
	}) {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			height: 46,
			decoration: BoxDecoration(
				color: scheme.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(
					color: scheme.primary.withValues(alpha: 0.18),
					width: 1.2,
				),
			),
			padding: const EdgeInsets.symmetric(horizontal: 12),
			child: DropdownButtonHideUnderline(
				child: DropdownButton2<T>(
					isExpanded: true,
					hint: Text(
						hint,
						style: TextStyle(
							fontSize: 13.5,
							color: scheme.onSurface.withValues(alpha: 0.45),
							fontWeight: FontWeight.w500,
						),
					),
					items: items,
					value: value,
					onChanged: onChanged,
					iconStyleData: IconStyleData(
						icon: Icon(Icons.keyboard_arrow_down_rounded,
								color: scheme.primary, size: 22),
					),
					style: TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.w600,
						color: scheme.onSurface,
					),
					buttonStyleData: const ButtonStyleData(
						padding: EdgeInsets.zero,
						height: 44,
					),
					dropdownStyleData: DropdownStyleData(
						maxHeight: 280,
						decoration: BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.circular(16),
							boxShadow: [
								BoxShadow(
									color: scheme.primary.withValues(alpha: 0.16),
									blurRadius: 22,
									offset: const Offset(0, 8),
								),
							],
						),
						offset: const Offset(0, -4),
					),
					menuItemStyleData: const MenuItemStyleData(
						height: 44,
						padding: EdgeInsets.symmetric(horizontal: 14),
					),
					dropdownSearchData: searchController == null
							? null
							: DropdownSearchData(
								searchController: searchController,
								searchInnerWidgetHeight: 50,
								searchInnerWidget: Container(
									height: 50,
									padding: const EdgeInsets.only(
											top: 8, bottom: 4, right: 8, left: 8),
									child: TextFormField(
										expands: true,
										maxLines: null,
										controller: searchController,
										decoration: InputDecoration(
											isDense: true,
											prefixIcon: Icon(Icons.search_rounded,
													color: scheme.primary, size: 18),
											contentPadding: const EdgeInsets.symmetric(
													horizontal: 10, vertical: 8),
											hintText: 'Ara…',
											hintStyle: const TextStyle(fontSize: 12),
											border: OutlineInputBorder(
												borderRadius: BorderRadius.circular(10),
												borderSide: BorderSide(
														color:
																scheme.primary.withValues(alpha: 0.20)),
											),
											enabledBorder: OutlineInputBorder(
												borderRadius: BorderRadius.circular(10),
												borderSide: BorderSide(
														color:
																scheme.primary.withValues(alpha: 0.20)),
											),
										),
									),
								),
								searchMatchFn: (item, q) =>
										searchMatcher!(item.value as T, q),
							),
					onMenuStateChange: (isOpen) {
						if (!isOpen) searchController?.clear();
					},
				),
			),
		);
	}

	// ───────────────────────────── Bottom Bar (Güncelle)
	Widget _bottomBar(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return SafeArea(
			top: false,
			child: Container(
				margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
				padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(20),
					boxShadow: [
						BoxShadow(
							color: scheme.primary.withValues(alpha: 0.14),
							blurRadius: 22,
							offset: const Offset(0, 6),
						),
					],
				),
				child: Row(
					children: [
						Expanded(
							child: TextButton(
								onPressed: () => Navigator.of(context).pop(),
								style: TextButton.styleFrom(
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(14),
									),
								),
								child: Text(
									'Vazgeç',
									style: TextStyle(
										fontSize: 14.5,
										fontWeight: FontWeight.w700,
										color: scheme.onSurface.withValues(alpha: 0.65),
									),
								),
							),
						),
						const SizedBox(width: 6),
						Expanded(
							flex: 2,
							child: Material(
								color: Colors.transparent,
								borderRadius: BorderRadius.circular(14),
								child: InkWell(
									onTap: _saveOnGorusme,
									borderRadius: BorderRadius.circular(14),
									child: Container(
										padding: const EdgeInsets.symmetric(vertical: 14),
										decoration: BoxDecoration(
											gradient: LinearGradient(
												colors: [scheme.primary, scheme.tertiary],
												begin: Alignment.topLeft,
												end: Alignment.bottomRight,
											),
											borderRadius: BorderRadius.circular(14),
											boxShadow: [
												BoxShadow(
													color: scheme.primary.withValues(alpha: 0.32),
													blurRadius: 16,
													offset: const Offset(0, 6),
												),
											],
										),
										child: Row(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												Icon(Icons.save_rounded,
														size: 18, color: scheme.onPrimary),
												const SizedBox(width: 6),
												Text(
													'Güncelle',
													style: TextStyle(
														color: scheme.onPrimary,
														fontSize: 14.5,
														fontWeight: FontWeight.w800,
														letterSpacing: 0.2,
													),
												),
											],
										),
									),
								),
							),
						),
					],
				),
			),
		);
	}

	void _saveOnGorusme() {
		// Takvim odaya gore ise oda secimi zorunlu
		if (_odaTakvim && selectedongorusmeoda == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Lütfen oda seçiniz.'),
					backgroundColor: Colors.red,
					duration: Duration(seconds: 2),
				),
			);
			return;
		}
		String urunid = "";
		String paketid = "";
		String hizmetid = '';
		final paketurun = selectedongorusmesebep?.getPaketUrunAdi() ?? "";
		if (paketurun.contains("Paket")) {
			paketid = selectedongorusmesebep?.getId() ?? "";
		} else if (paketurun.contains("Ürün")) {
			urunid = selectedongorusmesebep?.getId() ?? "";
		} else if (paketurun.contains('IsletmeHizmet')) {
			hizmetid = selectedongorusmesebep?.getId() ?? '';
		}
		widget.ongorusmedatasource.onGorusmeEkleGuncelle(
			widget.ongorusme.id.toString(),
			selectedMusteri?.id ?? "",
			adsoyad.text,
			_telGor ? telefon.text : _telOrijinal,
			"", // email kaldirildi
			_selectedGender,
			context,
			seciliisletme,
			selectedongorusmesehir?.id ?? "",
			selectedongorusmereferans?.id ?? "",
			meslek.text,
			urunid,
			paketid,
			ongorusmetarihi.text,
			ongorusmesaati.text,
			ongorusmeaciklama.text,
			selectedongorusmeyapan?.id ?? "",
			"",
			hizmetid,
			oda_id: selectedongorusmeoda?.id ?? "",
		);
	}

	// ───────────────────────────── Quick Müşteri Ekle (bottom sheet)
	void _openYeniMusteriSheet() {
		final scheme = Theme.of(context).colorScheme;
		final TextEditingController qAd = TextEditingController(text: adsoyad.text);
		final TextEditingController qTel = TextEditingController(text: telefon.text);
		String qGender = _selectedGender;
		bool kaydediliyor = false;
		String? hataMsg;

		showModalBottomSheet(
			context: context,
			backgroundColor: Colors.transparent,
			isScrollControlled: true,
			builder: (ctx) {
				return Padding(
					padding:
							EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
					child: StatefulBuilder(
						builder: (ctx, setSheet) {
							return Container(
								margin: const EdgeInsets.all(12),
								padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
								decoration: BoxDecoration(
									color: Colors.white,
									borderRadius: BorderRadius.circular(24),
									boxShadow: [
										BoxShadow(
											color: scheme.primary.withValues(alpha: 0.20),
											blurRadius: 28,
											offset: const Offset(0, 10),
										),
									],
								),
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Center(
											child: Container(
												width: 38,
												height: 4,
												decoration: BoxDecoration(
													color: scheme.onSurface.withValues(alpha: 0.18),
													borderRadius: BorderRadius.circular(999),
												),
											),
										),
										const SizedBox(height: 14),
										Row(
											children: [
												Container(
													width: 38,
													height: 38,
													decoration: BoxDecoration(
														gradient: LinearGradient(
															colors: [scheme.primary, scheme.tertiary],
															begin: Alignment.topLeft,
															end: Alignment.bottomRight,
														),
														shape: BoxShape.circle,
													),
													child: Icon(Icons.person_add_alt_1_rounded,
															color: scheme.onPrimary, size: 20),
												),
												const SizedBox(width: 10),
												Expanded(
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															Text(
																'Hızlı Müşteri Ekle',
																style: TextStyle(
																	fontSize: 16,
																	fontWeight: FontWeight.w800,
																	color: scheme.onSurface,
																),
															),
															Text(
																'Sadece ad ve telefon yeterli.',
																style: TextStyle(
																	fontSize: 11.5,
																	fontWeight: FontWeight.w500,
																	color: scheme.onSurface
																			.withValues(alpha: 0.55),
																),
															),
														],
													),
												),
											],
										),
										const SizedBox(height: 16),
										_sheetField('Ad Soyad', qAd, 'Ad ve soyad',
												onChanged: (_) {
													if (hataMsg != null) {
														setSheet(() => hataMsg = null);
													}
												}),
										const SizedBox(height: 10),
										_sheetField('Telefon', qTel, '5xx xxx xx xx',
												kbType: TextInputType.phone,
												onChanged: (_) {
													if (hataMsg != null) {
														setSheet(() => hataMsg = null);
													}
												}),
										if (hataMsg != null) ...[
											const SizedBox(height: 10),
											_inlineError(hataMsg!),
										],
										const SizedBox(height: 12),
										Row(
											children: [
												Expanded(
													child: _sheetGender('kadin', 'Kadın',
															Icons.female_rounded, qGender, (v) {
														setSheet(() => qGender = v);
													}),
												),
												const SizedBox(width: 10),
												Expanded(
													child: _sheetGender('erkek', 'Erkek',
															Icons.male_rounded, qGender, (v) {
														setSheet(() => qGender = v);
													}),
												),
											],
										),
										const SizedBox(height: 16),
										Row(
											children: [
												Expanded(
													child: TextButton(
														onPressed: kaydediliyor
																? null
																: () => Navigator.pop(ctx),
														style: TextButton.styleFrom(
															padding: const EdgeInsets.symmetric(vertical: 13),
															shape: RoundedRectangleBorder(
																borderRadius: BorderRadius.circular(12),
															),
														),
														child: Text(
															'Vazgeç',
															style: TextStyle(
																fontSize: 14,
																fontWeight: FontWeight.w700,
																color: scheme.onSurface
																		.withValues(alpha: 0.65),
															),
														),
													),
												),
												const SizedBox(width: 8),
												Expanded(
													flex: 2,
													child: Material(
														color: Colors.transparent,
														borderRadius: BorderRadius.circular(12),
														child: InkWell(
															onTap: kaydediliyor
																	? null
																	: () async {
																		if (qAd.text.trim().isEmpty ||
																				qTel.text.trim().isEmpty) {
																			setSheet(() => hataMsg =
																					'Ad ve telefon zorunlu.');
																			return;
																		}
																		setSheet(() {
																			kaydediliyor = true;
																			hataMsg = null;
																		});
																		final sonuc = await _hizliMusteriEkle(
																			qAd.text.trim(),
																			qTel.text.trim(),
																			qGender,
																		);
																		if (!mounted) return;
																		if (sonuc.musteri != null) {
																			final m = sonuc.musteri!;
																			setState(() {
																				selectedMusteri = m;
																				adsoyad.text = m.name;
																				_telOrijinal = m.cep_telefon;
																				telefon.text = _telGor ? _telOrijinal : Yetki.telefonGoster(_telOrijinal);
																				if (qGender.isNotEmpty) {
																					_selectedGender = qGender;
																				}
																			});
																			Navigator.pop(ctx);
																			ScaffoldMessenger.of(context)
																					.showSnackBar(
																				const SnackBar(
																					content: Text(
																							'✓ Müşteri eklendi ve seçildi.'),
																					duration:
																							Duration(seconds: 2),
																				),
																			);
																		} else {
																			setSheet(() {
																				kaydediliyor = false;
																				hataMsg = sonuc.hata ??
																						'Bilinmeyen hata';
																			});
																		}
																	},
															borderRadius: BorderRadius.circular(12),
															child: Container(
																padding: const EdgeInsets.symmetric(vertical: 13),
																decoration: BoxDecoration(
																	gradient: LinearGradient(
																		colors: [scheme.primary, scheme.tertiary],
																		begin: Alignment.topLeft,
																		end: Alignment.bottomRight,
																	),
																	borderRadius: BorderRadius.circular(12),
																),
																child: Row(
																	mainAxisAlignment: MainAxisAlignment.center,
																	children: [
																		if (kaydediliyor)
																			SizedBox(
																				width: 16,
																				height: 16,
																				child: CircularProgressIndicator(
																					strokeWidth: 2,
																					color: scheme.onPrimary,
																				),
																			)
																		else
																			Icon(Icons.check_rounded,
																					size: 18,
																					color: scheme.onPrimary),
																		const SizedBox(width: 6),
																		Text(
																			kaydediliyor ? 'Kaydediliyor…' : 'Ekle',
																			style: TextStyle(
																				color: scheme.onPrimary,
																				fontSize: 14,
																				fontWeight: FontWeight.w800,
																			),
																		),
																	],
																),
															),
														),
													),
												),
											],
										),
									],
								),
							);
						},
					),
				);
			},
		);
	}

	Widget _sheetField(String label, TextEditingController controller, String hint,
			{TextInputType? kbType, ValueChanged<String>? onChanged}) {
		final scheme = Theme.of(context).colorScheme;
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Padding(
					padding: const EdgeInsets.only(left: 2, bottom: 4),
					child: Text(
						label,
						style: TextStyle(
							fontSize: 11.5,
							fontWeight: FontWeight.w700,
							color: scheme.onSurface.withValues(alpha: 0.72),
						),
					),
				),
				Container(
					decoration: BoxDecoration(
						color: scheme.primary.withValues(alpha: 0.05),
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: scheme.primary.withValues(alpha: 0.18),
							width: 1.2,
						),
					),
					child: TextField(
						controller: controller,
						keyboardType: kbType,
						onChanged: onChanged,
						style: TextStyle(
							fontSize: 14,
							fontWeight: FontWeight.w600,
							color: scheme.onSurface,
						),
						decoration: InputDecoration(
							hintText: hint,
							hintStyle: TextStyle(
								color: scheme.onSurface.withValues(alpha: 0.40),
								fontSize: 13.5,
							),
							border: InputBorder.none,
							enabledBorder: InputBorder.none,
							focusedBorder: InputBorder.none,
							contentPadding: const EdgeInsets.symmetric(
									horizontal: 14, vertical: 11),
						),
					),
				),
			],
		);
	}

	Widget _inlineError(String msg) {
		const errColor = Color(0xFFDC2626);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: errColor.withValues(alpha: 0.10),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: errColor.withValues(alpha: 0.40), width: 1.2),
			),
			child: Row(
				children: [
					const Icon(Icons.error_outline_rounded, color: errColor, size: 18),
					const SizedBox(width: 8),
					Expanded(
						child: Text(
							msg,
							style: const TextStyle(
								fontSize: 12.5,
								fontWeight: FontWeight.w700,
								color: errColor,
								height: 1.3,
							),
						),
					),
				],
			),
		);
	}

	Widget _sheetGender(String value, String label, IconData icon, String current,
			ValueChanged<String> onTap) {
		final scheme = Theme.of(context).colorScheme;
		final selected = current == value;
		return Material(
			color: Colors.transparent,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				onTap: () => onTap(value),
				borderRadius: BorderRadius.circular(12),
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 200),
					padding: const EdgeInsets.symmetric(vertical: 10),
					decoration: BoxDecoration(
						gradient: selected
								? LinearGradient(
									colors: [scheme.primary, scheme.tertiary],
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
								)
								: null,
						color: selected ? null : scheme.primary.withValues(alpha: 0.05),
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: selected
									? Colors.transparent
									: scheme.primary.withValues(alpha: 0.18),
							width: 1.2,
						),
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(icon, size: 15, color: selected ? Colors.white : scheme.primary),
							const SizedBox(width: 5),
							Text(
								label,
								style: TextStyle(
									fontSize: 12.5,
									fontWeight: FontWeight.w700,
									color: selected ? Colors.white : scheme.onSurface,
								),
							),
						],
					),
				),
			),
		);
	}

	Future<({MusteriDanisan? musteri, String? hata})> _hizliMusteriEkle(
		String ad,
		String tel,
		String cinsiyet,
	) async {
		final cinsiyetCode =
				cinsiyet == 'kadin' ? '0' : (cinsiyet == 'erkek' ? '1' : '');
		try {
			final response = await http.post(
				Uri.parse(
					'https://app.randevumcepte.com.tr/api/v1/musteriekleguncelle/$seciliisletme',
				),
				headers: {'Content-Type': 'application/json'},
				body: jsonEncode({
					'ad_soyad': ad,
					'telefon': tel,
					'email': '',
					'dogum_tarihi': '',
					'cinsiyet': cinsiyetCode,
					'musteri_tipi': '',
					'ozel_notlar': '',
				}),
			);
			if (response.statusCode != 200 && response.statusCode != 201) {
				return (musteri: null, hata: 'Hata kodu: ${response.statusCode}');
			}
			if (response.body.trim().isEmpty) {
				return (musteri: null, hata: 'Sunucudan boş yanıt geldi.');
			}
			final decoded = json.decode(response.body);
			if (decoded is Map &&
					decoded.containsKey('status') &&
					decoded['status'] == 'warning') {
				final mesaj =
						decoded['mesaj']?.toString() ?? 'Bu numara zaten kayıtlı';
				return (musteri: null, hata: mesaj);
			}
			return (
				musteri: MusteriDanisan.fromJson(decoded as Map<String, dynamic>),
				hata: null,
			);
		} catch (e, st) {
			log('hizli musteri ekle hata: $e\n$st');
			return (musteri: null, hata: 'Müşteri eklenemedi: $e');
		}
	}

	// ───────────────────────────── Modern time picker
	Future<void> _showModernTimePicker(BuildContext context) async {
		final result = await showModalBottomSheet(
			context: context,
			backgroundColor: Colors.transparent,
			isScrollControlled: true,
			builder: (context) => _buildModernTimePicker(_selectedTime),
		);
		if (result == null) return;
		if (result is TimeOfDay) {
			setState(() {
				_selectedTime = result;
				ongorusmesaati.text =
						'${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
			});
		}
	}

	Widget _buildModernTimePicker(TimeOfDay initialTime) {
		final scheme = Theme.of(context).colorScheme;
		int selectedHour = initialTime.hour;
		int selectedMinute = _getNearestQuarterMinute(initialTime.minute);
		return StatefulBuilder(
			builder: (context, setStateSheet) {
				return Container(
					height: MediaQuery.of(context).size.height * 0.55,
					decoration: const BoxDecoration(
						color: Colors.white,
						borderRadius: BorderRadius.only(
							topLeft: Radius.circular(28),
							topRight: Radius.circular(28),
						),
					),
					child: Column(
						children: [
							const SizedBox(height: 10),
							Container(
								width: 38,
								height: 4,
								decoration: BoxDecoration(
									color: Colors.black.withValues(alpha: 0.18),
									borderRadius: BorderRadius.circular(999),
								),
							),
							const SizedBox(height: 12),
							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 16),
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										TextButton(
											onPressed: () => Navigator.of(context).pop(),
											child: Text(
												'İptal',
												style: TextStyle(
													color: scheme.onSurface.withValues(alpha: 0.60),
													fontSize: 14.5,
													fontWeight: FontWeight.w600,
												),
											),
										),
										Text(
											'Saat Seç',
											style: TextStyle(
												fontSize: 16,
												fontWeight: FontWeight.w800,
												color: scheme.onSurface,
											),
										),
										TextButton(
											onPressed: () {
												Navigator.of(context).pop(
													TimeOfDay(
															hour: selectedHour, minute: selectedMinute),
												);
											},
											child: Text(
												'Tamam',
												style: TextStyle(
													color: scheme.primary,
													fontSize: 14.5,
													fontWeight: FontWeight.w800,
												),
											),
										),
									],
								),
							),
							Container(
								margin: const EdgeInsets.symmetric(vertical: 14),
								padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
								decoration: BoxDecoration(
									gradient: LinearGradient(
										colors: [
											scheme.primary.withValues(alpha: 0.12),
											scheme.tertiary.withValues(alpha: 0.12),
										],
										begin: Alignment.topLeft,
										end: Alignment.bottomRight,
									),
									borderRadius: BorderRadius.circular(20),
								),
								child: Text(
									'${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
									style: TextStyle(
										fontSize: 42,
										fontWeight: FontWeight.w800,
										letterSpacing: -1,
										color: scheme.primary,
									),
								),
							),
							Expanded(
								child: Row(
									children: [
										Expanded(
											child: ListWheelScrollView(
												itemExtent: 50,
												perspective: 0.005,
												diameterRatio: 1.5,
												physics: const FixedExtentScrollPhysics(),
												onSelectedItemChanged: (index) {
													setStateSheet(() => selectedHour = index);
												},
												children: List.generate(24, (hour) {
													final isSelected = hour == selectedHour;
													return Center(
														child: Text(
															hour.toString().padLeft(2, '0'),
															style: TextStyle(
																fontSize: isSelected ? 24 : 18,
																fontWeight: isSelected
																		? FontWeight.w800
																		: FontWeight.w500,
																color: isSelected
																		? scheme.primary
																		: scheme.onSurface
																				.withValues(alpha: 0.45),
															),
														),
													);
												}),
											),
										),
										Expanded(
											child: ListWheelScrollView(
												itemExtent: 50,
												perspective: 0.005,
												diameterRatio: 1.5,
												physics: const FixedExtentScrollPhysics(),
												onSelectedItemChanged: (index) {
													setStateSheet(() =>
															selectedMinute = _getMinuteFromIndex(index));
												},
												children: List.generate(4, (index) {
													final minute = _getMinuteFromIndex(index);
													final isSelected = minute == selectedMinute;
													return Center(
														child: Text(
															minute.toString().padLeft(2, '0'),
															style: TextStyle(
																fontSize: isSelected ? 24 : 18,
																fontWeight: isSelected
																		? FontWeight.w800
																		: FontWeight.w500,
																color: isSelected
																		? scheme.primary
																		: scheme.onSurface
																				.withValues(alpha: 0.45),
															),
														),
													);
												}),
											),
										),
									],
								),
							),
						],
					),
				);
			},
		);
	}

	int _getMinuteFromIndex(int index) {
		switch (index) {
			case 0:
				return 0;
			case 1:
				return 15;
			case 2:
				return 30;
			case 3:
				return 45;
			default:
				return 0;
		}
	}

	int _getNearestQuarterMinute(int minute) {
		if (minute < 8) return 0;
		if (minute < 23) return 15;
		if (minute < 38) return 30;
		if (minute < 53) return 45;
		return 0;
	}
}
