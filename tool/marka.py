#!/usr/bin/env python3
"""Marka (beyaz etiket) yonetimi: tek config -> markalar/<kod>/marka.json.

Kullanim (proje kokunden, tool/marka.sh uzerinden):
  tool/marka.sh liste                 Tanimli markalar (* = aktif)
  tool/marka.sh durum                 Aktif marka + uretilen dosyalar tutarli mi
  tool/marka.sh kontrol [kod]         marka.json + Firebase dosyalari dogru mu (hepsi ya da tek)
  tool/marka.sh yeni <kod>            Sablondan yeni marka klasoru (sonra marka.json'u doldur)
  tool/marka.sh tum                   Projede Firebase dosyasi olan TUM markalar
  tool/marka.sh gec <kod> [--hizli]   Markaya gec (--hizli: flutter clean / pod install yok)
                                      Klasor yoksa Firebase/ikon dosyalarini projeden bulup
                                      kendisi kurar; yalniz ad/surum/build/profil sorar.
                                      Kodun basi yeter: gec shemall -> shemallbeauty

Marka gecisi SADECE uretilen dosyalara yazar; kodda (lib/, packages/) ve
gradle/pbxproj'da marka degeri yoktur:
  android/marka.properties            paket, ad, surum, build   (git disi)
  ios/Flutter/Marka.xcconfig          bundle id, ad, surum, profil (git disi)
  assets/marka/aktif.json + logo.png  uygulama ici ad/logo (git disi)
  android/app/google-services.json, ios/Runner/GoogleService-Info.plist
  ikon + acilis gorseli (flutter_launcher_icons / flutter_native_splash)
"""
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARKALAR = os.path.join(KOK, 'markalar')
SABLON = '_sablon'

ZORUNLU = ['kod', 'ad', 'paket', 'surum', 'build', 'ikon', 'logo']

URETILEN = {
    'android': os.path.join(KOK, 'android', 'marka.properties'),
    'xcconfig': os.path.join(KOK, 'ios', 'Flutter', 'Marka.xcconfig'),
    'aktif': os.path.join(KOK, 'assets', 'marka', 'aktif.json'),
    'logo': os.path.join(KOK, 'assets', 'marka', 'logo.png'),
    'gs_android': os.path.join(KOK, 'android', 'app', 'google-services.json'),
    'gs_ios': os.path.join(KOK, 'ios', 'Runner', 'GoogleService-Info.plist'),
}


class Hata(Exception):
    pass


def yaz(msg=''):
    print(msg, flush=True)


def markalar():
    if not os.path.isdir(MARKALAR):
        return []
    return sorted(d for d in os.listdir(MARKALAR)
                  if not d.startswith(('_', '.')) and os.path.isfile(os.path.join(MARKALAR, d, 'marka.json')))


def dosya(kod, yol):
    """marka.json'daki yol: once markalar/<kod>/ icinde, yoksa proje kokunde."""
    if not yol:
        return None
    for aday in (os.path.join(MARKALAR, kod, yol), os.path.join(KOK, yol)):
        if os.path.isfile(aday):
            return aday
    return None


def oku(kod):
    p = os.path.join(MARKALAR, kod, 'marka.json')
    if not os.path.isfile(p):
        raise Hata(f'markalar/{kod}/marka.json yok. Liste: tool/marka.sh liste')
    with open(p, encoding='utf-8') as f:
        m = json.load(f)
    eksik = [k for k in ZORUNLU if str(m.get(k, '')).strip() == '']
    if eksik:
        raise Hata(f'{kod}: marka.json eksik alan(lar): {", ".join(eksik)}')
    if m['kod'] != kod:
        raise Hata(f'{kod}: marka.json "kod" ({m["kod"]}) klasor adiyla ayni olmali')
    if not re.fullmatch(r'[a-z][a-z0-9_]*', kod):
        raise Hata(f'{kod}: kod yalniz kucuk harf/rakam/_ (Turkce karakter yok)')
    if not re.fullmatch(r'\d+(\.\d+){1,2}', str(m['surum'])):
        raise Hata(f'{kod}: surum "1.2.3" biciminde olmali')
    if not str(m['build']).isdigit():
        raise Hata(f'{kod}: build tam sayi olmali')
    m.setdefault('ios_paket', m['paket'])
    m.setdefault('ios_profil', '')
    m.setdefault('splash', m['ikon'])
    m.setdefault('ikon_arka_plan_ios', '#FFFFFF')
    m.setdefault('splash_renk', '#ffffff')
    m.setdefault('softphone', False)
    return m


def kontrol_et(kod):
    """Hata listesi doner (bos = tamam)."""
    hatalar = []
    try:
        m = oku(kod)
    except Hata as e:
        return [str(e)]
    for alan in ('ikon', 'splash', 'logo'):
        if not dosya(kod, m[alan]):
            hatalar.append(f'{alan} dosyasi bulunamadi: {m[alan]}')
    gs = os.path.join(MARKALAR, kod, 'google-services.json')
    if not os.path.isfile(gs):
        hatalar.append('google-services.json yok (Firebase Console > Android uygulamasi)')
    else:
        try:
            with open(gs, encoding='utf-8') as f:
                paketler = {c['client_info']['android_client_info']['package_name']
                            for c in json.load(f).get('client', [])}
            if m['paket'] not in paketler:
                hatalar.append(f'google-services.json icinde {m["paket"]} yok')
        except Exception as e:  # noqa: BLE001
            hatalar.append(f'google-services.json okunamadi: {e}')
    gi = os.path.join(MARKALAR, kod, 'GoogleService-Info.plist')
    if not os.path.isfile(gi):
        hatalar.append('GoogleService-Info.plist yok (Firebase Console > iOS uygulamasi)')
    else:
        try:
            with open(gi, 'rb') as f:
                bid = plistlib.load(f).get('BUNDLE_ID')
            if bid != m['ios_paket']:
                hatalar.append(f'GoogleService-Info.plist BUNDLE_ID {bid} != {m["ios_paket"]}')
        except Exception as e:  # noqa: BLE001
            hatalar.append(f'GoogleService-Info.plist okunamadi: {e}')
    if not m['ios_profil']:
        hatalar.append('ios_profil bos (App Store provisioning profile adi; iOS release imzasi icin)')
    return hatalar


def aktif_kod():
    try:
        with open(URETILEN['aktif'], encoding='utf-8') as f:
            return json.load(f).get('kod')
    except Exception:  # noqa: BLE001
        return None


def calistir(komut, **kw):
    yaz('  $ ' + ' '.join(komut))
    r = subprocess.run(komut, cwd=kw.pop('cwd', KOK), **kw)
    if r.returncode != 0:
        raise Hata(f'komut basarisiz ({r.returncode}): {" ".join(komut)}')


def git_kod_degisti():
    """lib/, packages/, assets/dil marka gecisinde DEGISMEMELI."""
    r = subprocess.run(['git', '-c', 'core.quotepath=false', 'status', '--porcelain', '--',
                        'lib', 'packages', 'assets/dil'],
                       cwd=KOK, capture_output=True, text=True)
    return r.stdout.strip()


def gec(kod, hizli=False):
    hatalar = kontrol_et(kod)
    if hatalar:
        raise Hata(f'{kod} gecilemez:\n  - ' + '\n  - '.join(hatalar))
    m = oku(kod)
    once = git_kod_degisti()
    yaz(f'== {m["ad"]} ({kod}) -> {m["paket"]}  surum {m["surum"]}+{m["build"]}')

    # 1) Uretilen config dosyalari
    with open(URETILEN['android'], 'w', encoding='utf-8') as f:
        f.write('# tool/marka.sh uretir; elle duzenleme -> markalar/%s/marka.json\n' % kod)
        for k in ('kod', 'paket', 'ad', 'surum', 'build'):
            # Properties: \ ve satir sonu kacisi
            v = str(m[k]).replace('\\', '\\\\').replace('\n', ' ')
            f.write(f'{k}={v}\n')

    def xc(v):
        return str(v).replace('\n', ' ').replace('$', '')
    with open(URETILEN['xcconfig'], 'w', encoding='utf-8') as f:
        f.write(f'// tool/marka.sh uretir; elle duzenleme -> markalar/{kod}/marka.json\n')
        f.write(f'PRODUCT_BUNDLE_IDENTIFIER = {xc(m["ios_paket"])}\n')
        f.write(f'MARKA_AD = {xc(m["ad"])}\n')
        f.write(f'MARKA_KOD = {xc(kod)[:15]}\n')
        f.write(f'FLUTTER_BUILD_NAME = {xc(m["surum"])}\n')
        f.write(f'FLUTTER_BUILD_NUMBER = {xc(m["build"])}\n')
        f.write('PROVISIONING_PROFILE_SPECIFIER =\n')
        f.write(f'PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*] = {xc(m["ios_profil"])}\n')

    os.makedirs(os.path.dirname(URETILEN['aktif']), exist_ok=True)
    shutil.copyfile(dosya(kod, m['logo']), URETILEN['logo'])
    with open(URETILEN['aktif'], 'w', encoding='utf-8') as f:
        json.dump({'kod': kod, 'ad': m['ad'], 'logo': 'assets/marka/logo.png'}, f, ensure_ascii=False, indent=2)

    shutil.copyfile(os.path.join(MARKALAR, kod, 'google-services.json'), URETILEN['gs_android'])
    shutil.copyfile(os.path.join(MARKALAR, kod, 'GoogleService-Info.plist'), URETILEN['gs_ios'])
    yaz('  config + Firebase dosyalari yazildi')

    # 2) Ikon + acilis gorseli
    with tempfile.TemporaryDirectory() as td:
        ikon = os.path.join(td, 'ikon.yaml')
        with open(ikon, 'w', encoding='utf-8') as f:
            f.write('flutter_launcher_icons:\n'
                    '  android: "launcher_icon"\n'
                    '  ios: true\n'
                    f'  image_path: "{dosya(kod, m["ikon"])}"\n'
                    '  remove_alpha_ios: true\n'
                    f'  background_color_ios: "{m["ikon_arka_plan_ios"]}"\n')
        splash = os.path.join(td, 'splash.yaml')
        with open(splash, 'w', encoding='utf-8') as f:
            f.write('flutter_native_splash:\n'
                    f'  color: "{m["splash_renk"]}"\n'
                    f'  image: "{dosya(kod, m["splash"])}"\n'
                    '  android: true\n'
                    '  ios: true\n'
                    '  web: false\n')
        calistir(['dart', 'run', 'flutter_launcher_icons', '-f', ikon])
        calistir(['dart', 'run', 'flutter_native_splash:create', f'--path={splash}'])

    # 3) Softphone (markaya gore ac/kapat; pub get'i kendisi yapar)
    sp = 'ac' if m['softphone'] else 'kapat'
    calistir(['bash', 'tool/softphone.sh', sp, '--pod-yok'])

    # 4) Temiz derleme (eski markanin ikonu/onbellegi kalmasin)
    if not hizli:
        calistir(['flutter', 'clean'])
        calistir(['flutter', 'pub', 'get'])
        if sys.platform == 'darwin' and os.path.isfile(os.path.join(KOK, 'ios', 'Podfile')):
            calistir(['pod', 'install'], cwd=os.path.join(KOK, 'ios'))

    sonra = git_kod_degisti()
    yaz()
    yaz(f'TAMAM: aktif marka {m["ad"]} ({kod}). Softphone: {"ACIK" if m["softphone"] else "KAPALI"}.')
    if sonra != once:
        yaz('UYARI: marka gecisi sirasinda kod dosyalari degisti (olmamali):')
        yaz(sonra)
        return 2
    return 0


def yeni(kod):
    if not re.fullmatch(r'[a-z][a-z0-9_]*', kod):
        raise Hata('kod yalniz kucuk harf/rakam/_ olmali (or. senailbeauty)')
    hedef = os.path.join(MARKALAR, kod)
    if os.path.exists(hedef):
        raise Hata(f'markalar/{kod} zaten var')
    shutil.copytree(os.path.join(MARKALAR, SABLON), hedef)
    p = os.path.join(hedef, 'marka.json')
    with open(p, encoding='utf-8') as f:
        m = json.load(f)
    m['kod'] = kod
    m['paket'] = f'com.randevumcepte.{kod}'
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=2)
        f.write('\n')
    eski_plist = os.path.join(KOK, 'ios', 'Runner', f'GoogleService-Info.plist-{kod}.plist')
    if os.path.isfile(eski_plist):
        shutil.copyfile(eski_plist, os.path.join(hedef, 'GoogleService-Info.plist'))
        yaz(f'  eski ios/Runner/GoogleService-Info.plist-{kod}.plist kopyalandi')
    yaz(f'markalar/{kod}/ olusturuldu. Simdi:')
    yaz('  1) marka.json: ad, surum, build, ios_profil, ikon/logo/splash yollari')
    yaz('  2) google-services.json + GoogleService-Info.plist (Firebase Console)')
    yaz(f'  3) tool/marka.sh kontrol {kod}  ->  tool/marka.sh gec {kod}')
    return 0


PAKET_ON = 'com.randevumcepte.'
GORSEL_UZ = ('.png', '.jpg', '.jpeg')


def _gs_paketler(yol):
    try:
        with open(yol, encoding='utf-8') as f:
            return {c['client_info']['android_client_info']['package_name']
                    for c in json.load(f).get('client', [])}
    except Exception:  # noqa: BLE001
        return set()


def _gs_adaylari():
    """Projedeki tum google-services json'lari (android/app + markalar/*)."""
    d = os.path.join(KOK, 'android', 'app')
    adaylar = [os.path.join(d, f) for f in sorted(os.listdir(d))
               if f.startswith('google-services') and f.endswith('.json')]
    for k in markalar():
        p = os.path.join(MARKALAR, k, 'google-services.json')
        if os.path.isfile(p):
            adaylar.append(p)
    return adaylar


def _plist_adaylari():
    """(etiket, bytes): ios/Runner'daki plist'ler + git'te olup silinmisler + markalar/*."""
    sonuc = []
    d = os.path.join(KOK, 'ios', 'Runner')
    gorulen = set()
    for f in sorted(os.listdir(d)):
        if f.startswith('GoogleService-Info.plist'):
            with open(os.path.join(d, f), 'rb') as fh:
                sonuc.append((f'ios/Runner/{f}', fh.read()))
            gorulen.add(f)
    r = subprocess.run(['git', '-c', 'core.quotepath=false', 'ls-tree', '--name-only', 'HEAD', 'ios/Runner/'],
                       cwd=KOK, capture_output=True, text=True)
    for yol in r.stdout.splitlines():
        ad = os.path.basename(yol)
        if ad.startswith('GoogleService-Info.plist') and ad not in gorulen:
            g = subprocess.run(['git', 'show', f'HEAD:{yol}'], cwd=KOK, capture_output=True)
            if g.returncode == 0:
                sonuc.append((f'git:{yol}', g.stdout))
    for k in markalar():
        p = os.path.join(MARKALAR, k, 'GoogleService-Info.plist')
        if os.path.isfile(p):
            with open(p, 'rb') as fh:
                sonuc.append((f'markalar/{k}/GoogleService-Info.plist', fh.read()))
    return sonuc


def _plist_bid(veri):
    try:
        return plistlib.loads(veri).get('BUNDLE_ID')
    except Exception:  # noqa: BLE001
        return None


def bilinen_paketler():
    """Firebase dosyalarinda gecen tum com.randevumcepte.* kodlari."""
    kodlar = set()
    for p in _gs_adaylari():
        kodlar |= {x[len(PAKET_ON):] for x in _gs_paketler(p) if x.startswith(PAKET_ON)}
    for _, v in _plist_adaylari():
        b = _plist_bid(v) or ''
        if b.startswith(PAKET_ON):
            kodlar.add(b[len(PAKET_ON):])
    return {k for k in kodlar if re.fullmatch(r'[a-z][a-z0-9_]*', k)}


def _gorsel_bul(kod, icon):
    """images/ icinde kod'a en uygun gorsel: <kod>icon.png, yoksa kod'un en uzun on eki
    (shemallbeauty -> shemallicon.png). icon=False ise logo (<kod>.png)."""
    d = os.path.join(KOK, 'images')
    if not os.path.isdir(d):
        return None
    en_iyi, uzunluk = None, 0
    for f in os.listdir(d):
        kok, uz = os.path.splitext(f)
        if uz.lower() not in GORSEL_UZ:
            continue
        kok = kok.lower()
        if icon:
            if not kok.endswith('icon'):
                continue
            kok = kok[:-4]
        elif kok.endswith('icon'):
            continue
        if len(kok) >= 3 and kod.startswith(kok) and len(kok) > uzunluk:
            en_iyi, uzunluk = os.path.join('images', f), len(kok)
    return en_iyi


def _sor(soru, varsayilan):
    if not sys.stdin.isatty():
        return varsayilan
    c = input(f'  {soru} [{varsayilan}]: ').strip()
    return c or varsayilan


def otomatik_olustur(kod):
    """markalar/<kod> yoksa projedeki dosyalardan kurar; yalniz ad/surum/build/profil sorar."""
    paket = PAKET_ON + kod
    gs = next((p for p in _gs_adaylari() if paket in _gs_paketler(p)), None)
    pl = next(((e, v) for e, v in _plist_adaylari() if _plist_bid(v) == paket), None)
    logo = _gorsel_bul(kod, icon=False)
    ikon = _gorsel_bul(kod, icon=True) or logo
    logo = logo or ikon
    eksik = []
    if not gs:
        eksik.append(f'Android Firebase: hicbir google-services*.json icinde {paket} yok')
    if not pl:
        eksik.append(f'iOS Firebase: BUNDLE_ID {paket} olan GoogleService-Info.plist yok')
    if not ikon:
        eksik.append(f'ikon/logo: images/ icinde {kod}icon.png ya da {kod}.png yok')
    if eksik:
        raise Hata(f'{kod} otomatik kurulamadi (dosyayi projeye koyup tekrar dene):\n  - '
                   + '\n  - '.join(eksik))
    yaz(f'markalar/{kod} yok -> projeden otomatik kuruluyor:')
    yaz(f'  Android Firebase : {os.path.relpath(gs, KOK)}')
    yaz(f'  iOS Firebase     : {pl[0]}')
    yaz(f'  ikon / logo      : {ikon} / {logo}')
    m = {
        'kod': kod,
        'ad': _sor('Uygulama adi', kod.capitalize()),
        'paket': paket,
        'surum': _sor('Surum', '1.0.0'),
        'build': int(_sor('Build no', '1')),
        'ios_profil': _sor('iOS provisioning profil adi (bilmiyorsan Enter)', ''),
        'ikon': ikon,
        'logo': logo,
        'splash': logo,
        'ikon_arka_plan_ios': '#FFFFFF',
        'splash_renk': '#ffffff',
        'softphone': _sor('Softphone (e/h)', 'h').lower().startswith('e'),
    }
    hedef = os.path.join(MARKALAR, kod)
    os.makedirs(hedef)
    shutil.copyfile(gs, os.path.join(hedef, 'google-services.json'))
    with open(os.path.join(hedef, 'GoogleService-Info.plist'), 'wb') as f:
        f.write(pl[1])
    with open(os.path.join(hedef, 'marka.json'), 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=2)
        f.write('\n')
    yaz(f'  markalar/{kod}/marka.json yazildi (sonra elle de degistirebilirsin)')


def kod_coz(kod):
    """Klasor varsa o; yoksa Firebase'deki kodlardan tam ya da tek on-ek eslesmesi
    (or. 'shemall' -> shemallbeauty)."""
    kod = kod.lower().strip()
    if os.path.isfile(os.path.join(MARKALAR, kod, 'marka.json')):
        return kod
    for k in markalar():  # klasor var ama farkli adla (or. senail -> senailbeauty)
        if k.startswith(kod):
            return k
    bilinen = bilinen_paketler()
    if kod in bilinen:
        return kod
    aday = sorted(k for k in bilinen if k.startswith(kod) or kod.startswith(k))
    if len(aday) == 1:
        return aday[0]
    if aday:
        raise Hata(f'"{kod}" birden fazla markaya uyuyor: {", ".join(aday)}')
    raise Hata(f'"{kod}" bulunamadi. Bilinen markalar: tool/marka.sh tum')


def main(arg):
    komut = arg[0] if arg else 'durum'
    if komut == 'liste':
        a = aktif_kod()
        for k in markalar():
            try:
                m = oku(k)
                yaz(f'{"*" if k == a else " "} {k:<22} {m["ad"]:<32} {m["paket"]}  {m["surum"]}+{m["build"]}')
            except Hata as e:
                yaz(f'! {k:<22} HATALI: {e}')
        return 0
    if komut == 'durum':
        a = aktif_kod()
        if not a:
            yaz('Aktif marka YOK (assets/marka/aktif.json uretilmemis) -> tool/marka.sh gec <kod>')
            return 1
        yaz(f'Aktif marka: {a}')
        eksik = [k for k, p in URETILEN.items() if not os.path.isfile(p)]
        if eksik:
            yaz('EKSIK uretilen dosya: ' + ', '.join(eksik) + f' -> tool/marka.sh gec {a}')
            return 1
        with open(URETILEN['android'], encoding='utf-8') as f:
            props = dict(l.rstrip('\n').split('=', 1) for l in f if '=' in l and not l.startswith('#'))
        with open(URETILEN['gs_ios'], 'rb') as f:
            bid = plistlib.load(f).get('BUNDLE_ID')
        try:
            m = oku(a)
        except Hata as e:
            yaz(str(e))
            return 1
        sorun = []
        if props.get('paket') != m['paket']:
            sorun.append(f'android/marka.properties paket {props.get("paket")} != {m["paket"]}')
        if bid != m['ios_paket']:
            sorun.append(f'ios GoogleService-Info.plist {bid} != {m["ios_paket"]}')
        if props.get('surum') != str(m['surum']) or props.get('build') != str(m['build']):
            sorun.append('surum/build marka.json ile ayni degil (marka.json degisti mi?)')
        for s in sorun:
            yaz('  UYUMSUZ: ' + s)
        if sorun:
            yaz(f'-> tool/marka.sh gec {a}')
            return 1
        yaz('  uretilen dosyalar marka.json ile tutarli')
        return 0
    if komut == 'kontrol':
        hedefler = arg[1:] or markalar()
        kotu = 0
        for k in hedefler:
            h = kontrol_et(k)
            yaz(f'{"OK " if not h else "HATA"} {k}')
            for x in h:
                yaz('     - ' + x)
            kotu += bool(h)
        return 1 if kotu else 0
    if komut == 'yeni' and len(arg) == 2:
        return yeni(arg[1])
    if komut == 'tum':
        hazir = set(markalar())
        for k in sorted(bilinen_paketler() | hazir):
            yaz(f'{"hazir " if k in hazir else "      "} {k}')
        yaz('\n"hazir" olmayanlar da gecilebilir: tool/marka.sh gec <kod> (klasoru kendisi kurar)')
        return 0
    if komut == 'gec' and len(arg) >= 2:
        kod = kod_coz(arg[1])
        if not os.path.isdir(os.path.join(MARKALAR, kod)):
            otomatik_olustur(kod)
        return gec(kod, hizli='--hizli' in arg[2:])
    yaz(__doc__)
    return 1


if __name__ == '__main__':
    try:
        sys.exit(main(sys.argv[1:]))
    except Hata as e:
        yaz(f'HATA: {e}')
        sys.exit(1)
