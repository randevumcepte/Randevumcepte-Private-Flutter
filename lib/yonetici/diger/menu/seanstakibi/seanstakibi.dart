import 'package:flutter/material.dart';

class SeansTakibiYeni extends StatefulWidget {
  final dynamic isletmebilgi;
  const SeansTakibiYeni({Key? key, required this.isletmebilgi}) : super(key: key);

  @override
  State<SeansTakibiYeni> createState() => _SeansTakibiState();
}

class _SeansTakibiState extends State<SeansTakibiYeni> {
  List<SeansModel> _seanslar = [];

  @override
  void initState() {
    super.initState();
    _seanslar = [
      SeansModel(
        id: '1',
        paketAdi: 'G5 Masajı',
        toplamSeans: 16,
        kullanilan: 1,
        kalan: 15,
        kullanilmayan: 0,
        seansDurumlari: List.generate(16, (index) => index < 1 ? 'kullanildi' : 'kalan'),
      ),
      SeansModel(
        id: '2',
        paketAdi: 'Sırt Masajı',
        toplamSeans: 8,
        kullanilan: 3,
        kalan: 5,
        kullanilmayan: 0,
        seansDurumlari: List.generate(8, (index) => index < 3 ? 'kullanildi' : 'kalan'),
      ),
      SeansModel(
        id: '3',
        paketAdi: 'Full Body',
        toplamSeans: 12,
        kullanilan: 7,
        kalan: 5,
        kullanilmayan: 0,
        seansDurumlari: List.generate(12, (index) => index < 7 ? 'kullanildi' : 'kalan'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seans Takibi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
            onPressed: _yeniSeansEkle,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _seanslar.length,
        itemBuilder: (context, index) {
          return _buildKart(_seanslar[index]);
        },
      ),
    );
  }

  Widget _buildKart(SeansModel seans) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Hizmet adı ve seans sayısı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                seans.paketAdi,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${seans.toplamSeans} Seans',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Seans butonları - Küçük yuvarlaklar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(seans.toplamSeans, (index) {
              String durum = seans.seansDurumlari[index];
              return GestureDetector(
                onTap: () => _seansTiklandi(seans, index),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: durum == 'kullanildi'
                        ? Colors.green
                        : durum == 'kullanilmayan'
                        ? Colors.red
                        : Colors.transparent,
                    border: durum == 'kalan'
                        ? Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                    )
                        : null,
                  ),
                  child: durum == 'kullanildi'
                      ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                      : durum == 'kullanilmayan'
                      ? const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Alt istatistikler
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIstatistik(
                  label: 'Kullanıldı',
                  value: seans.kullanilan.toString(),
                  renk: Colors.green,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                ),
                _buildIstatistik(
                  label: 'Kalan',
                  value: seans.kalan.toString(),
                  renk: Colors.grey,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                ),
                _buildIstatistik(
                  label: 'Kullanılmadı',
                  value: seans.kullanilmayan.toString(),
                  renk: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistik({
    required String label,
    required String value,
    required Color renk,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _seansTiklandi(SeansModel seans, int index) {
    String durum = seans.seansDurumlari[index];

    if (durum == 'kullanildi') {
      // Kullanıldı ise kullanılmadı yap
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(seans.paketAdi),
          content: const Text('Bu seansı kullanılmadı olarak işaretlemek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  seans.seansDurumlari[index] = 'kullanilmayan';
                  seans.kullanilan--;
                  seans.kullanilmayan++;
                  seans.kalan = seans.toplamSeans - seans.kullanilan - seans.kullanilmayan;
                });
                Navigator.pop(context);
              },
              child: const Text('Evet', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else if (durum == 'kullanilmayan') {
      // Kullanılmadı ise kalan yap
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(seans.paketAdi),
          content: const Text('Bu seansı kullanılmadıdan kaldırmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  seans.seansDurumlari[index] = 'kalan';
                  seans.kullanilmayan--;
                  seans.kalan++;
                });
                Navigator.pop(context);
              },
              child: const Text('Evet', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    } else {
      // Kalan ise kullanıldı yap
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(seans.paketAdi),
          content: const Text('Bu seansı kullanıldı olarak işaretlemek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  seans.seansDurumlari[index] = 'kullanildi';
                  seans.kullanilan++;
                  seans.kalan--;
                });
                Navigator.pop(context);
              },
              child: const Text('Evet', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }
  }

  void _yeniSeansEkle() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController paketController = TextEditingController();
        final TextEditingController seansController = TextEditingController();

        return AlertDialog(
          title: const Text('Yeni Seans Paketi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paketController,
                decoration: const InputDecoration(
                  labelText: 'Paket Adı',
                  hintText: 'Örn: G5 Masajı',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seansController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Toplam Seans',
                  hintText: 'Seans sayısı',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (paketController.text.isNotEmpty &&
                    seansController.text.isNotEmpty) {
                  int toplam = int.tryParse(seansController.text) ?? 0;
                  setState(() {
                    _seanslar.add(SeansModel(
                      id: DateTime.now().toString(),
                      paketAdi: paketController.text,
                      toplamSeans: toplam,
                      kullanilan: 0,
                      kalan: toplam,
                      kullanilmayan: 0,
                      seansDurumlari: List.generate(toplam, (index) => 'kalan'),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}
class SeansModel {
  final String id;
  final String paketAdi;
  final int toplamSeans;
  int kullanilan;
  int kalan;
  int kullanilmayan;
  List<String> seansDurumlari; // 'kullanildi', 'kalan', 'kullanilmayan'

  SeansModel({
    required this.id,
    required this.paketAdi,
    required this.toplamSeans,
    required this.kullanilan,
    required this.kalan,
    required this.kullanilmayan,
    required this.seansDurumlari,
  });
}