// OTOMATIK URETILIR — elle duzenleme, `tool/softphone.sh ac|kapat` kullan.
// Durum: KAPALI (rc_softphone paketi pubspec'te yok, native paket girmez).
import 'softphone.dart';

Softphone softphoneOlustur() => const KapaliSoftphone();
