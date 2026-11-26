// Diğer > WhatsApp Sohbetleri
// Yönetici olmayan ama "WhatsApp sohbetlerini görsün" yetkisi açılmış personel için yalnız sohbetler
// (Bekleyen / Tümü / Personel yazdı). Yöneticiler tam WhatsApp Asistanı sayfasını kullanır (Sohbetler sekmesi aynı ekran).
// "Sohbete katılsın" yetkisi varsa sohbet ekranında mesaj kutusu çıkar; backend aynı yetkiyi uygular.

import 'package:randevu_sistem/dil/material.dart';

import 'wa_asistan_page.dart';
import 'wa_sohbetler_sekme.dart';
import 'wa_widgets.dart';

class WaSohbetMerkeziPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final String? salonId;
  final int? acilacakSohbetId;

  const WaSohbetMerkeziPage({super.key, required this.isletmebilgi, this.salonId, this.acilacakSohbetId});

  @override
  State<WaSohbetMerkeziPage> createState() => _WaSohbetMerkeziPageState();
}

class _WaSohbetMerkeziPageState extends State<WaSohbetMerkeziPage> {
  late final WaDurum _d;

  @override
  void initState() {
    super.initState();
    final sube = (widget.salonId != null && widget.salonId!.isNotEmpty) ? widget.salonId! : '${widget.isletmebilgi['id']}';
    _d = WaDurum(sube);
    _d.sohbetAc = _sohbetAc;
    _d.yetkiYukle();
    if (widget.acilacakSohbetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sohbetAc(widget.acilacakSohbetId!));
    }
  }

  @override
  void dispose() {
    _d.dispose();
    super.dispose();
  }

  Future<void> _sohbetAc(int id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WaSohbetDetay(d: _d, id: id)));
    _d.sohbetYenile.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(children: [
          Icon(Icons.forum_rounded, color: waYesil),
          SizedBox(width: 8),
          Flexible(child: Text('WhatsApp Sohbetleri', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18), overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: WaSohbetlerSekme(d: _d),
    );
  }
}
