import 'package:flutter/material.dart';

import 'sms_yonetimi_state.dart';
import 'tabs/sms_ayarlari_tab.dart';
import 'tabs/sms_kara_liste_tab.dart';
import 'tabs/sms_raporlari_tab.dart';

class SmsYonetimiPage extends StatefulWidget {
  final dynamic isletmebilgi;
  final int kullanicirolu;
  const SmsYonetimiPage({
    Key? key,
    required this.isletmebilgi,
    required this.kullanicirolu,
  }) : super(key: key);

  @override
  State<SmsYonetimiPage> createState() => _SmsYonetimiPageState();
}

class _SmsYonetimiPageState extends State<SmsYonetimiPage> {
  late SmsYonetimiController _state;

  @override
  void initState() {
    super.initState();
    final salonId = widget.isletmebilgi['id'].toString();
    _state = SmsYonetimiController(salonId: salonId);
    _state.yukle();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        // SMS Ayarları sekmesi: web'de role_id=1 (işletme sahibi/admin) görüyor.
        // Mobilde kullanicirolu==1 aynı kişiyi temsil eder; ek olarak server
        // tarafından dönen isAdmin de fallback olarak kullanılır.
        final ayarlarTabGoster =
            widget.kullanicirolu == 1 || _state.isAdmin;
        final tabBaslik = <String>[
          'SMS Raporları',
          if (ayarlarTabGoster) 'SMS Ayarları',
          'Kara Liste',
        ];
        final tabIcerik = <Widget>[
          SmsRaporlariTab(state: _state),
          if (ayarlarTabGoster) SmsAyarlariTab(state: _state),
          SmsKaraListeTab(state: _state),
        ];

        return DefaultTabController(
          length: tabBaslik.length,
          child: Scaffold(
            backgroundColor: Color(0xFFF7F7FB),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              foregroundColor: Colors.black,
              title: Text('SMS Yönetimi',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(child: _bakiyeRozeti()),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    isScrollable: true,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey.shade700,
                    indicatorColor: Colors.deepPurple,
                    tabs: tabBaslik.map((b) => Tab(text: b)).toList(),
                  ),
                ),
              ),
            ),
            body: _state.yukleniyor
                ? Center(child: CircularProgressIndicator())
                : (_state.hata != null
                    ? _hataKutusu(_state.hata!)
                    : Column(
                        children: [
                          _yasalUyari(),
                          Expanded(
                            child: TabBarView(children: tabIcerik),
                          ),
                        ],
                      )),
          ),
        );
      },
    );
  }

  /// Sağ üstteki bakiye rozeti.
  /// VoiceTelekom (yeni_sms=1) TL kredi bakiyesi döner; Efetech (eski) SMS adedi döner.
  /// Kafa karışıklığını önlemek için sağlayıcıya göre uygun etiket gösteriyoruz.
  Widget _bakiyeRozeti() {
    final yeniSms = _state.yeniSms;
    final miktar = _state.kalanSms;
    final IconData ikon =
        yeniSms ? Icons.account_balance_wallet : Icons.email_outlined;
    final String etiket = yeniSms ? 'Bakiye' : 'Kalan SMS';
    String deger;
    if (yeniSms) {
      // TL kredi: ondalıklı olabilir, 2 hane ile göster
      deger = '${miktar.toStringAsFixed(2)} ₺';
    } else {
      deger = '${miktar.toInt()} adet';
    }
    return Tooltip(
      message: yeniSms
          ? 'VoiceTelekom TL kredi bakiyeniz'
          : 'Efetech kalan SMS adediniz',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 16, color: Colors.orange.shade800),
          SizedBox(width: 6),
          Text(
            '$etiket: $deger',
            style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold),
          ),
        ]),
      ),
    );
  }

  Widget _yasalUyari() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade800, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'SMS gönderimlerinin tüm yasal/cezai yükümlülüğü size aittir. '
              'Ticari amaçlı gönderimlerde alıcılarınızı İYS\'ye kayıt etmeli '
              've gerekli izinleri almış olmalısınız.',
              style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hataKutusu(String mesaj) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 36),
            SizedBox(height: 12),
            Text('SMS Yönetimi yüklenirken hata oluştu',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(mesaj,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _state.yukle(),
              icon: Icon(Icons.refresh),
              label: Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
