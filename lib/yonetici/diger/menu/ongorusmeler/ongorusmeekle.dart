import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/secilipersonel.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/Models/musteri_danisanlar.dart';
import 'package:randevu_sistem/Models/ongorusmenedeni.dart';
import 'package:randevu_sistem/theme/premium_components.dart';

import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Models/musteridanisanreferans.dart';
import 'package:randevu_sistem/Models/personel.dart';
import 'package:randevu_sistem/Models/sehirler.dart';
import 'package:randevu_sistem/Frontend/lazyload.dart';

class YeniOnGorusme extends StatefulWidget {
	final OnGorusmeDataSource ongorusmedatasource;
	final dynamic isletmebilgi;
	final int kullanicirolu;
	const YeniOnGorusme({
		Key? key,
		required this.ongorusmedatasource,
		required this.isletmebilgi,
		required this.kullanicirolu,
	}) : super(key: key);

	@override
	State<YeniOnGorusme> createState() => _YeniOnGorusmeState();
}

class _YeniOnGorusmeState extends State<YeniOnGorusme> {
	TimeOfDay _selectedTime = TimeOfDay.now();

	late List<MusteriDanisan> musteri;
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
	late String seciliisletme;

	final TextEditingController ongorusmesebepcontroller = TextEditingController();
	final TextEditingController adsoyad = TextEditingController();
	final TextEditingController telefon = TextEditingController();
	final TextEditingController email = TextEditingController();
	final TextEditingController meslek = TextEditingController();
	final TextEditingController ongorusmetarihi = TextEditingController();
	final TextEditingController ongorusmesaati = TextEditingController();
	final TextEditingController ongorusmeaciklama = TextEditingController();
	final TextEditingController ongorusmeyapancontroller = TextEditingController();

	late List<Personel> ongorusmeyapan;
	late List<OnGorusmeNedeni> ongorusmeneden;
	Personel? selectedongorusmeyapan;
	bool yukleniyor = true;

	String _selectedGender = '';

	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final AutovalidateMode _autoValidate = AutovalidateMode.disabled;

	@override
	void initState() {
		super.initState();
		initialize();
	}

	Future<void> initialize() async {
		seciliisletme = (await secilisalonid())!;
		final isletmeVerileri = await isletmeVerileriGetir(seciliisletme, false, '', '', '', 0, 0);
		List<MusteriDanisan> musteridanisan = isletmeVerileri['musteriler'];
		List<Personel> isletmepersonellerliste = isletmeVerileri['personeller'];
		List<OnGorusmeNedeni> ongorusmenedeniliste = isletmeVerileri['onGorusmeNedeni'];
		List<Sehir> sehirler = isletmeVerileri['sehirler'];
		final secili = await seciliPersonelgetir(widget.isletmebilgi);
		if (!mounted) return;
		setState(() {
			musteri = musteridanisan;
			ongorusmeyapan = isletmepersonellerliste;
			ongorusmesehir = sehirler;
			ongorusmeneden = ongorusmenedeniliste;
			yukleniyor = false;
			selectedongorusmereferans =
					ongorusmereferans.firstWhere((item) => item.id == "");
			selectedongorusmeyapan = secili;
		});
	}

	@override
	void dispose() {
		ongorusmesebepcontroller.dispose();
		adsoyad.dispose();
		telefon.dispose();
		email.dispose();
		meslek.dispose();
		ongorusmetarihi.dispose();
		ongorusmesaati.dispose();
		ongorusmeaciklama.dispose();
		ongorusmeyapancontroller.dispose();
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
							? Center(
								child: CircularProgressIndicator(color: scheme.primary))
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
												autovalidateMode: _autoValidate,
												child: ListView(
													physics: const BouncingScrollPhysics(),
													padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
													children: [
														_musteriCard(context),
														const SizedBox(height: 14),
														_detayCard(context),
														const SizedBox(height: 14),
														_zamanCard(context),
														const SizedBox(height: 14),
														_aciklamaCard(context),
														const SizedBox(height: 18),
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
									Icon(Icons.handshake_outlined,
											size: 16, color: scheme.primary),
									const SizedBox(width: 6),
									Flexible(
										child: Text(
											'Yeni Ön Görüşme',
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

	// ───────────────────────────── Greeting
	Widget _header(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Yeni Ön Görüşme',
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
						'Müşteri bilgilerini doldurun, görüşmeyi planlayın.',
						style: TextStyle(
							fontSize: 12.5,
							fontWeight: FontWeight.w500,
							color: scheme.onSurface.withValues(alpha: 0.55),
						),
					),
				],
			),
		);
	}

	// ───────────────────────────── Müşteri Bilgileri Card
	Widget _musteriCard(BuildContext context) {
		return PremiumGlassCard(
			padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_sectionTitle('Müşteri Bilgileri', Icons.person_outline_rounded),
					const SizedBox(height: 14),
					_fieldLabel('Müşteri Seç'),
					_lazyDropdownWrap(),
					const SizedBox(height: 14),
					_fieldLabel('Ad Soyad'),
					_premiumTextField(
						controller: adsoyad,
						hint: 'Ad ve soyad',
						prefix: Icons.badge_outlined,
					),
					const SizedBox(height: 14),
					_fieldLabel('Telefon Numarası'),
					_premiumTextField(
						controller: telefon,
						hint: '5xx xxx xx xx',
						prefix: Icons.phone_outlined,
						keyboardType: TextInputType.phone,
					),
					const SizedBox(height: 14),
					_fieldLabel('E-mail'),
					_premiumTextField(
						controller: email,
						hint: 'ornek@mail.com',
						prefix: Icons.mail_outline_rounded,
						keyboardType: TextInputType.emailAddress,
					),
					const SizedBox(height: 16),
					_fieldLabel('Cinsiyet'),
					const SizedBox(height: 4),
					Row(
						children: [
							Expanded(child: _genderPill('kadin', 'Kadın', Icons.female_rounded)),
							const SizedBox(width: 10),
							Expanded(child: _genderPill('erkek', 'Erkek', Icons.male_rounded)),
						],
					),
				],
			),
		);
	}

	Widget _lazyDropdownWrap() {
		final scheme = Theme.of(context).colorScheme;
		return Container(
			height: 48,
			padding: const EdgeInsets.symmetric(horizontal: 10),
			decoration: BoxDecoration(
				color: scheme.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(14),
				border: Border.all(
					color: scheme.primary.withValues(alpha: 0.18),
					width: 1.2,
				),
			),
			child: LazyDropdown(
				salonId: seciliisletme,
				selectedItem: selectedMusteri,
				onChanged: (value) {
					if (value == null) return;
					setState(() {
						selectedMusteri = value;
						adsoyad.text = value.name;
						telefon.text = value.cep_telefon;
						log('email ' + value.email);
						email.text = value.email != 'null' ? value.email : '';
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
			borderRadius: BorderRadius.circular(14),
			child: InkWell(
				onTap: () => setState(() => _selectedGender = value),
				borderRadius: BorderRadius.circular(14),
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 220),
					curve: Curves.easeOut,
					padding: const EdgeInsets.symmetric(vertical: 12),
					decoration: BoxDecoration(
						gradient: selected
								? LinearGradient(
									colors: [scheme.primary, scheme.tertiary],
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
								)
								: null,
						color: selected ? null : scheme.primary.withValues(alpha: 0.05),
						borderRadius: BorderRadius.circular(14),
						border: Border.all(
							color: selected
									? Colors.transparent
									: scheme.primary.withValues(alpha: 0.18),
							width: 1.2,
						),
						boxShadow: selected
								? [
									BoxShadow(
										color: scheme.primary.withValues(alpha: 0.30),
										blurRadius: 14,
										offset: const Offset(0, 5),
									),
								]
								: null,
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								icon,
								size: 17,
								color: selected ? Colors.white : scheme.primary,
							),
							const SizedBox(width: 6),
							Text(
								label,
								style: TextStyle(
									fontSize: 13.5,
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

	// ───────────────────────────── Detay (referans/sebep/personel) Card
	Widget _detayCard(BuildContext context) {
		return PremiumGlassCard(
			padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_sectionTitle('Görüşme Detayları', Icons.assignment_outlined),
					const SizedBox(height: 14),
					_fieldLabel('Referans'),
					_premiumDropdown<Referans>(
						value: selectedongorusmereferans,
						items: ongorusmereferans
								.map((e) => DropdownMenuItem(value: e, child: Text(e.referans)))
								.toList(),
						hint: 'Referans seç',
						icon: Icons.share_outlined,
						onChanged: (v) => setState(() => selectedongorusmereferans = v),
					),
					const SizedBox(height: 14),
					_fieldLabel('Ön Görüşme Nedeni'),
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
					const SizedBox(height: 14),
					_fieldLabel('Görüşmeyi Yapan'),
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
						searchMatcher: (item, q) => item.personel_adi
								.toLowerCase()
								.contains(q.toLowerCase()),
						onChanged: (v) => setState(() => selectedongorusmeyapan = v),
					),
				],
			),
		);
	}

	// ───────────────────────────── Tarih/Saat Card
	Widget _zamanCard(BuildContext context) {
		return PremiumGlassCard(
			padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_sectionTitle('Tarih & Saat', Icons.event_available_outlined),
					const SizedBox(height: 14),
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_fieldLabel('Randevu Tarihi'),
										_premiumTextField(
											controller: ongorusmetarihi,
											hint: 'YYYY-AA-GG',
											prefix: Icons.calendar_month_outlined,
											readOnly: true,
											validator: (v) =>
													(v == null || v.isEmpty) ? 'Tarih seçiniz' : null,
											onTap: () async {
												final picked = await showDatePicker(
													context: context,
													initialDate: DateTime.now(),
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
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_fieldLabel('Randevu Saati'),
										_premiumTextField(
											controller: ongorusmesaati,
											hint: '--:--',
											prefix: Icons.access_time_rounded,
											readOnly: true,
											validator: (v) =>
													(v == null || v.isEmpty) ? 'Saat seçiniz' : null,
											onTap: () async {
												await _showModernTimePicker(context);
											},
										),
									],
								),
							),
						],
					),
				],
			),
		);
	}

	// ───────────────────────────── Açıklama Card
	Widget _aciklamaCard(BuildContext context) {
		return PremiumGlassCard(
			padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					_sectionTitle('Açıklama', Icons.notes_rounded),
					const SizedBox(height: 14),
					_premiumTextField(
						controller: ongorusmeaciklama,
						hint: 'Görüşmeye dair notlarınız…',
						prefix: null,
						maxLines: 3,
					),
				],
			),
		);
	}

	// ───────────────────────────── Bottom Save Bar
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
									onTap: _kaydet,
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
												Icon(Icons.check_rounded,
														size: 18, color: scheme.onPrimary),
												const SizedBox(width: 6),
												Text(
													'Kaydet',
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

	void _kaydet() {
		String urunid = "";
		String paketid = "";
		String hizmetid = '';
		final paketurun = selectedongorusmesebep?.getPaketUrunAdi() ?? "";
		if (paketurun.contains("Paket")) paketid = selectedongorusmesebep?.getId() ?? "";
		if (paketurun.contains("Ürün")) urunid = selectedongorusmesebep?.getId() ?? "";
		if (paketurun.contains('IsletmeHizmet')) hizmetid = selectedongorusmesebep?.getId() ?? '';
		widget.ongorusmedatasource.onGorusmeEkleGuncelle(
			"",
			selectedMusteri?.id ?? "",
			adsoyad.text,
			telefon.text,
			email.text,
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
		);
	}

	// ───────────────────────────── Premium UI helpers
	Widget _sectionTitle(String title, IconData icon) {
		final scheme = Theme.of(context).colorScheme;
		return Row(
			children: [
				Container(
					width: 32,
					height: 32,
					decoration: BoxDecoration(
						color: scheme.primary.withValues(alpha: 0.12),
						shape: BoxShape.circle,
					),
					child: Icon(icon, size: 17, color: scheme.primary),
				),
				const SizedBox(width: 10),
				Text(
					title,
					style: TextStyle(
						fontSize: 15,
						fontWeight: FontWeight.w800,
						letterSpacing: -0.2,
						color: scheme.onSurface,
					),
				),
			],
		);
	}

	Widget _fieldLabel(String label) {
		final scheme = Theme.of(context).colorScheme;
		return Padding(
			padding: const EdgeInsets.only(left: 2, bottom: 6),
			child: Text(
				label,
				style: TextStyle(
					fontSize: 12,
					fontWeight: FontWeight.w700,
					color: scheme.onSurface.withValues(alpha: 0.70),
					letterSpacing: 0.1,
				),
			),
		);
	}

	Widget _premiumTextField({
		required TextEditingController controller,
		required String hint,
		IconData? prefix,
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
				borderRadius: BorderRadius.circular(14),
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
					prefixIcon: prefix == null
							? null
							: Icon(prefix, color: scheme.primary, size: 19),
					hintText: hint,
					hintStyle: TextStyle(
						color: scheme.onSurface.withValues(alpha: 0.40),
						fontSize: 13.5,
						fontWeight: FontWeight.w500,
					),
					border: InputBorder.none,
					enabledBorder: InputBorder.none,
					focusedBorder: InputBorder.none,
					contentPadding: EdgeInsets.symmetric(
						horizontal: prefix == null ? 14 : 4,
						vertical: maxLines != null && maxLines > 1 ? 14 : 12,
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
			height: 48,
			decoration: BoxDecoration(
				color: scheme.primary.withValues(alpha: 0.05),
				borderRadius: BorderRadius.circular(14),
				border: Border.all(
					color: scheme.primary.withValues(alpha: 0.18),
					width: 1.2,
				),
			),
			padding: const EdgeInsets.symmetric(horizontal: 12),
			child: Row(
				children: [
					Icon(icon, size: 18, color: scheme.primary),
					const SizedBox(width: 8),
					Expanded(
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
									height: 46,
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
																	color: scheme.primary
																			.withValues(alpha: 0.20)),
														),
														enabledBorder: OutlineInputBorder(
															borderRadius: BorderRadius.circular(10),
															borderSide: BorderSide(
																	color: scheme.primary
																			.withValues(alpha: 0.20)),
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
					),
				],
			),
		);
	}

	// ───────────────────────────── Modern time picker (orijinalden korunmuş)
	Future<void> _showModernTimePicker(BuildContext context) async {
		TimeOfDay initialTime = _selectedTime;
		final result = await showModalBottomSheet(
			context: context,
			backgroundColor: Colors.transparent,
			isScrollControlled: true,
			builder: (context) => _buildModernTimePicker(initialTime),
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
													TimeOfDay(hour: selectedHour, minute: selectedMinute),
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
								margin: const EdgeInsets.symmetric(vertical: 16),
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
										fontSize: 44,
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
													setStateSheet(
															() => selectedMinute = _getMinuteFromIndex(index));
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
