# ECHO - Proje Klasör Mimarisi

DESYNC Game Jam (48 Saat) için optimize edilmiş Godot Proje Mimarisi.
Ekip içi çakışmalar (merge conflict) yaşamamak ve organizasyonu hızlandırmak için dosyaları aşağıdaki düzene göre yerleştirin.

## Genel Kurallar
- **İngilizce İsimlendirme:** Tüm klasör, dosya, script ve node isimleri İngilizce (PascalCase veya snake_case) olmalıdır. (Örn: `PlayerController.cs`, `jump_sound.wav`, `Level_01.tscn` vb.)
- **Bölünmüş Çalışma Alanı:** Artistler `Assets` içerisinde, Programmer'lar `Scripts` ve `Core` içerisinde, Level Designer/Audio ise kendi ilgili sahnelerinde veya dosyalarında çalışmalıdır. 

## Klasör Yapısı ve Kullanım Amaçları

### 1. `Assets/`
Oyunun tüm görsel, işitsel ve UI ham materyalleri burada toplanır. *(Script veya Sahne barındırmaz)*
- `Audio/BGM/`: Arka plan müzikleri.
- `Audio/SFX/`: Ses efektleri (Zıplama, DESYNC toggle vb.).
- `Fonts/`: TTF, OTF veya WOFF font dosyaları.
- `Sprites/Characters/`: Oyuncu, gölge ve düşman sprite/spritesheet'leri.
- `Sprites/Environment/`: Tileset, arka plan (background) ve prop spriteları.
- `Sprites/UI/`: Butonlar, enerji barı ikonları.
- `Sprites/VFX/`: Glitch efekt textureları, ekran sarsıntısı maskeleri (varsa).

### 2. `Core/`
Oyunun temelini oluşturan, her sahneden bağımsız çalışan tekil (Singleton/Autoload) yapılar.
- Game Manager, Ses Yöneticisi (Audio Ducking sistemleri vb.).
- Gölge pozisyonunu tutan (Ring Buffer) scriptler ve veri yapıları.

### 3. `Scenes/`
Oyun içindeki Godot Sahneleri (.tscn).
- `Characters/`: Player.tscn, Shadow.tscn, Enemy.tscn.
- `Levels/`: The Signal (Lvl1), Pressure (Lvl2) ... The Conductor (Boss).
- `Objects/`: Etkileşimli objeler (Baskı kapısı, Işık alanı, Görünmez platform vb.).
- `UI/`: Ana menü, oyun içi HUD (Enerji barı vb.) sahneleri.

### 4. `Scripts/`
Sahnelerle birebir eşleşen klasör yapısıyla kod dosyaları (.gd veya .cs).
- *Örnek:* `Scenes/Characters/Player.tscn` dosyasının kodu `Scripts/Characters/PlayerController.cs` (veya .gd) olmalıdır.
- Kodlar objelerden ayrı tutularak daha hızlı bulunması hedeflenmiştir.

### 5. `Resources/`
Oyun içi paylaşımlı özel Godot Data (.tres) dosyaları.
- `Shaders/`: Godot shader kodları (Glitch, Outline, Chromatic Aberration).
- `Themes/`: UI (Buton stilleri, Paneller) temaları.

---
*Not: Bu README, agentic yapay zeka tarafından 48 saatlik Jam sürecini hızlandırmak amacıyla `ECHO_GDD.md` temel alınarak oluşturulmuştur. Başarılar!*
