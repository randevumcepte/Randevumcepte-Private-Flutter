// Uygulama geneli ozellik bayraklari.
//
// SIP softphone burada DEGIL: o bir bayrak degil, ayri bir paket
// (packages/rc_softphone). Acmak/kapatmak icin: `tool/softphone.sh ac|kapat`.

// Sesli Asistan (Patron Asistani + Sesli Randevu). Kapali iken home
// ekranindaki "Asistan" FAB gizlenir, MIC/Speech permission istenmez.
const bool kAsistanEnabled = false;

// Cagri Merkezi menusu (Diger > Cagri Merkezi). CDR raporu + arama listesi
// + randevu takvimi gosterir; dis arama Bria Mobile ile yapilir. Markada
// santral/dahili kullanilmayacaksa false yap.
const bool kCagriMerkeziEnabled = true;
