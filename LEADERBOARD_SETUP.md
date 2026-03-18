# Leaderboard Kurulumu

Bu projede oyun ici leaderboard arayuzu ve baglanti iskeleti hazirlandi.

## Neden GitHub yetmez

`GitHub Pages` statik barindirma saglar. Canli skor yazma/okuma icin tek basina yeterli degildir. Bu yuzden oyun ici leaderboard icin harici bir backend gerekir.

## Onerilen cozum

`SilentWolf`

- Godot odakli
- Ucretsiz
- Itch.io buildlerinde calisabiliyor
- Godot 4 destekli

## Yapman gerekenler

1. `silentwolf.com` uzerinden hesap ac.
2. Yeni bir oyun olustur.
3. `API Key` ve `Game ID` bilgilerini al.
4. SilentWolf Godot addon'unu indir.
5. Addon dosyalarini proje kokundeki `addons` klasorune cikar.
6. Godot icinde `Project Settings > Plugins` altindan SilentWolf pluginini aktif et.
7. `Project Settings > Autoload` altinda `SilentWolf.gd` singleton'inin yüklü oldugunu kontrol et.
8. `Core/LeaderboardConfig.gd` dosyasinda su alanlari doldur:

```gdscript
const API_KEY := "BURAYA_API_KEY"
const GAME_ID := "BURAYA_GAME_ID"
```

## Hazir gelen ozellikler

- `L` tusu ile oyun icinde leaderboard ac/kapat
- Ana menude `LEADERBOARD` butonu
- Oyuncu adi kaydetme
- Tamamlanan kosuyu sonradan gonderme
- En kisa sureyi en ustte gosterecek skor donusumu

## Not

Sistem su anda `en kisa sure = en yuksek skor` mantigiyla calisir. Bu sayede standart leaderboard sisteminde bile hizli bitiren oyuncu 1. siraya yerlesir.
