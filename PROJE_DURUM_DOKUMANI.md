# gatesjam26 / ECHO — Proje Durum ve Sistem Dokümanı

**Son Güncelleme:** 15 Mart 2025  
**Motor:** Godot 4.6 (Forward Plus)  
**Proje Türü:** 2D Action-Puzzle Platformer (DESYNC Game Jam)

---

## 1. Proje Özeti

**gatesjam26** (kod adı: ECHO), DESYNC Game Jam teması için geliştirilmiş bir 2D platformer oyundur. Temel mekanik: Oyuncunun gölgesi hareketlerini yaklaşık 1 saniye gecikmeli tekrarlar. Bu gecikme hem engel hem de çözüm aracı olarak kullanılır.

**Ana Slogan:** *"Gölgen senden 1 saniye geride. Bu gecikme senin zayıflığın değil — silahın."*

---

## 2. Proje Yapısı

```
godotGameJam/
├── Assets/                    # Görsel, ses ve shader varlıkları
│   ├── Sprites/
│   │   ├── Characters/         # geik (oyuncu), shadowgeik (gölge) animasyonları
│   │   └── Environment/       # Zemin, arka plan, prop'lar
│   └── Shaders/               # danger_pulse, scanline
├── Core/                      # Singleton / Autoload sistemleri
│   ├── GameState.gd           # Oyun durumu, DESYNC enerjisi
│   ├── AudioManager.gd/tscn   # Ses yönetimi
│   └── AuidoBerk/             # SFX dosyaları (yürüme, dash, parry, buton)
├── Scenes/
│   ├── Characters/            # Player.tscn, Shadow.tscn
│   ├── Objects/               # Butonlar, platformlar, spike, hedef vb.
│   ├── UI/                    # MainMenu, UIManager, HUD, TutorialPopup
│   ├── VFX/                   # Shockwave
│   └── [1-9] level*.tscn      # Seviye sahneleri
├── Scripts/
│   ├── Characters/            # Player, Shadow, ShadowTrail, PlayerCamera
│   ├── Objects/               # BaseButton, MovingPlatform, ParrySpike, vb.
│   ├── UI/                    # UIManager, HUD, MainMenu, Tutorial
│   └── VFX/                   # Shockwave
├── DOCS GDD and TECH/         # GDD ve teknik dokümanlar
├── project.godot
└── ECHO_GDD.md
```

---

## 3. Autoload (Global) Sistemler

| Autoload | Dosya | Açıklama |
|----------|-------|----------|
| **GameState** | `Core/GameState.gd` | Oyun durumu makinesi, DESYNC enerjisi, checkpoint |
| **UIManager** | `Scenes/UI/UIManager.tscn` | Pause, ayarlar, restart, menü yönetimi |
| **AudioManager** | `Core/AudioManager.tscn` | Müzik ve SFX havuzları |

---

## 4. Core Sistemler

### 4.1 GameState

**Dosya:** `Core/GameState.gd`

**Durumlar:**
- `SYNC` — Normal mod, gölge oyuncuyla üst üste
- `DESYNC` — Gecikme uzatılmış (Space basılı), enerji tüketir
- `RESYNC` — DESYNC → SYNC geçişi (0.2 sn flash)
- `DEAD` — Oyuncu öldü

**Değişkenler:**
- `desync_energy` / `desync_energy_max` — Maks 4 saniye DESYNC
- `checkpoint_pos` — Checkpoint konumu
- `dash_unlocked` — Dash kilidi (Level 6+ otomatik açılır)

**Sinyaller:**
- `state_changed(new_state)`
- `player_died()`
- `resync_flash()`
- `gate_unlocked()`
- `button_activated(button_name)`
- `dash_unlocked_changed(is_unlocked)`

**Not:** DESYNC toggle (Space basılı tutma) ve enerji tüketimi GameState'te tanımlı, ancak **Player.gd içinde DESYNC input işlenmiyor**. GDD'deki DESYNC mekaniği (1s → 3s gecikme) şu an **uygulanmamış**; gölge gecikmesi sabit ~60 frame (ShadowTrail).

### 4.2 AudioManager

**Dosya:** `Core/AudioManager.gd` + `Core/AudioManager.tscn`

**Özellikler:**
- Müzik: `play_menu_music()`, `play_game_music()`, `stop_music()`
- UI SFX: `play_ui_hover()`, `play_ui_click()`, `play_pause_toggle()`
- Oyuncu SFX: `play_jump()`, `play_dash()`, `play_parry()`, `play_death()`
- Dünya SFX: `play_button_press()`, `play_button_release()`, `play_gate_unlock()`, `play_gate_enter()`, `play_pickup()`, `play_bounce()`
- SFX ve UI için ayrı havuzlar; pitch varyasyonu ile tekrarlar azaltılmış

---

## 5. Karakter Sistemleri

### 5.1 Player (Oyuncu)

**Dosya:** `Scripts/Characters/Player.gd`  
**Sahne:** `Scenes/Characters/Player.tscn`  
**Grup:** `player`  
**Collision Layer:** 1 (player_body)

**Hareket:**
- Hız: 220 px/s
- Zıplama: 520 px/s
- Yerçekimi: 980
- Coyote Time: 0.12 s
- Jump Buffer: 0.10 s

**Dash (Sadece Havada):**
- Hız: 600 px/s, süre: 0.15 s, cooldown: 0.5 s
- **Parry başarılı olunca** bir kez kazanılır (`_has_dash_charge`)
- Level 6+ otomatik açık

**Parry (Evade — X tuşu):**
- Startup: 2 frame
- Aktif pencere: 0.15 s
- Başarılı parry: Dikey fırlatma (750 px/s), dash şarjı, hit freeze, zoom, shake, shockwave, slow-mo
- Parry animasyonu gölge trail history'sine eklenir; gölge o noktaya geldiğinde parry animasyonu oynar

**Proximity Glow:**
- Tehlike (gölge/spike) yakınında sarı daire çizer
- `hazard` grubundaki nesneler 150 px içindeyse glow aktif

**Animasyonlar:** idle, walk, jump, parry

### 5.2 Shadow (Gölge)

**Dosya:** `Scripts/Characters/Shadow.gd`  
**Sahne:** `Scenes/Characters/Shadow.tscn`  
**Grup:** `hazard`  
**Collision Layer:** 2 (shadow_body)  
**Collision Mask:** 1 (player_body)

**Davranış:**
- Oyuncunun geçmiş pozisyonlarını ShadowTrail üzerinden takip eder
- Oyuncuya dokunursa ölüm (0.1 s coyote)
- Parry ACTIVE penceresinde dokunursa `execute_parry_launch()` tetiklenir
- Spawn sonrası 1 saniye dokunulmazlık
- Parry sonrası 0.5 s dokunulmazlık

**Animasyonlar:** idle, walk, jump, parry, parried (override)

### 5.3 ShadowTrail

**Dosya:** `Scripts/Characters/ShadowTrail.gd`

**Mantık:**
- Oyuncunun pozisyon, flip ve animasyon bilgisini `history` dizisine kaydeder
- Varsayılan: 60 frame gecikme (~1 s @ 60 FPS)
- Parry sırasında tüketim hızı yavaşlar (0.15)
- Gölge geride kaldığında hızlanır (catchup_speed: 3.0)
- Gölgeye pozisyon ve animasyon bilgisini `apply_follow_visual_state()` ile iletir

### 5.4 PlayerCamera

**Dosya:** `Scripts/Characters/PlayerCamera.gd`

**Özellikler:**
- Look-ahead: Hareket yönüne göre offset (x: 120, y: 80)
- Düşüşte kamera aşağı, zıplamada yukarı kayar
- Idle'da baktığı yöne göre offset
- Yumuşak takip (smooth_speed: 8.0)

---

## 6. Nesne (Object) Sistemleri

### 6.1 BaseButton (Baskı Plakası)

**Dosya:** `Scripts/Objects/BaseButton.gd`  
**Class:** `BasePressurePlate`

**Tipler:**
- `BOTH` — Hem oyuncu hem gölge basabilir
- `PLAYER_ONLY` — Sadece oyuncu
- `SHADOW_ONLY` — Sadece gölge

**Davranış:**
- Basılınca `button_pressed` sinyali, `target_platform` aktif
- Platform yoksa `GameState.trigger_gate_unlock()` çağrılır
- Görsel: HeartFlower, PollenParticles animasyonları

### 6.2 MovingPlatform

**Dosya:** `Scripts/Objects/MovingPlatform.gd`  
**Class:** `MovingPlatform`

- `marker_a` ↔ `marker_b` arasında X ekseninde hareket
- `is_active` true olunca hareket eder (BaseButton ile tetiklenir)
- `return_to_start`: Aktif değilken başlangıca döner

### 6.3 MovingButton

**Dosya:** `Scripts/Objects/MovingButton.gd`  
**Class:** `MovingButton` (BasePressurePlate'den türetilir)

- Basılıyken `marker_a` ↔ `marker_b` arasında hareket eder

### 6.4 ParrySpike (Parry Dikenleri)

**Dosya:** `Scripts/Objects/ParrySpike.gd`  
**Grup:** `hazard`

- Oyuncu dokunursa ölüm (0.1 s coyote)
- Parry ACTIVE penceresinde dokunursa parry başarılı, fırlatma + feedback (flash, rotasyon)
- Nefes alma animasyonu (scale pulse)

### 6.5 Shadow (Gölge — Hazard)

- Yukarıda **5.2 Shadow** bölümünde açıklandı.

### 6.6 KillZone

**Dosya:** `Scripts/Objects/KillZone.gd`

- Oyuncu girerse `GameState.trigger_player_death()` veya sahne yeniden yüklenir
- Genelde boşluğa düşme alanlarında kullanılır

### 6.7 LevelGoal (Kapı / Hedef)

**Dosya:** `Scripts/Objects/LevelGoal.gd`  
**Class:** `LevelGoal`

- `locked: true` ise `gate_unlocked` sinyaliyle açılır
- Açıkken oyuncu girerse `next_level_path` sahnesine geçilir
- Görsel: Kapı sprite, göz glow animasyonu

### 6.8 EnergyCell (Sync Point)

**Dosya:** `Scripts/Objects/EnergyCell.gd`

- Oyuncu topladığında `GameState.add_sync_point_energy()` (+%50)
- Pickup SFX, parçacık, sonra `queue_free()`

### 6.9 BouncyMushroom

**Dosya:** `Scripts/Objects/BouncyMushroom.gd`

- Oyuncuyu yatay yönde zıplatır (520 px/s)
- `only_bounce_from_above`: Sadece üstten gelince
- Squash-stretch animasyonu

---

## 7. UI Sistemleri

### 7.1 UIManager (Ana UI)

**Dosya:** `Scripts/UI/UIManager.gd`  
**Sahne:** `Scenes/UI/UIManager.tscn`

**Bileşenler:**
- Pause menüsü (Resume, Settings, Main Menu)
- Settings menüsü (Master ses, Glitch/scanline slider)
- Restart paneli (ölüm sonrası)
- Dash label (DASH READY / DASH: —)
- Proximity overlay (danger_pulse shader)
- Scanline overlay

**Davranış:**
- `ui_cancel` (ESC) ile pause
- Restart panelinde Z ile yeniden başlat
- Level 6+ dash otomatik açık
- Proximity: Tehlikeye yakınlığa göre shader güncellenir

### 7.2 MainMenu

**Dosya:** `Scripts/UI/MainMenu.gd`  
**Sahne:** `Scenes/UI/MainMenu.tscn`

- Play → `1 Level.tscn`
- Settings → UIManager üzerinden ayarlar
- Quit → Oyun kapanır
- Göz aç/kapa animasyonu (Play hover)

### 7.3 HUD

**Dosya:** `Scripts/UI/HUD.gd`  
**Sahne:** `Scenes/UI/HUD.tscn`

- Sync bar (desync_energy gösterimi) — **UIManager kullanılıyorsa HUD muhtemelen devre dışı**
- Dash label
- Restart paneli

**Not:** UIManager autoload olduğu için HUD sahnesi ayrı kullanılmıyor olabilir; level sahnelerinde UIManager instance'ı kontrol edilmeli.

### 7.4 TutorialPopup & TutorialTrigger

**TutorialTrigger:** Oyuncu alana girince VideoStream oynatır  
**TutorialPopup:** Video oynatır, Z veya Skip ile kapatır  
**show_once:** Aynı trigger aynı oturumda tekrar tetiklenmez (static `global_triggered_videos`)

---

## 8. VFX ve Shader'lar

### 8.1 Shockwave

**Dosya:** `Scripts/VFX/Shockwave.gd`  
**Sahne:** `Scenes/VFX/Shockwave.tscn`

- Parry başarılı olunca oyuncu pozisyonunda spawn
- Yayılan daire, kalınlık ve alpha azalır, sonra `queue_free`

### 8.2 danger_pulse.gdshader

- `proximity` (0–1): Tehlikeye yakınlık
- Vignette + pulse ile kırmızı kenar efekti

### 8.3 scanline.gdshader

- Yatay scanline çizgileri
- `opacity`, `line_count`, `scroll_speed` parametreleri
- Ayarlardan Glitch slider ile kontrol

---

## 9. Fizik Katmanları (Physics Layers)

| Layer | İsim | Kullanım |
|-------|------|----------|
| 1 | player_body | Oyuncu |
| 2 | shadow_body | Gölge |
| 3 | world | Dünya / zemin |
| 4 | shadow_triggers | Gölge tetikleyicileri |
| 5 | enemy_body | Düşman (henüz kullanılmıyor) |
| 6 | enemy_target | Düşman hedefi (henüz kullanılmıyor) |

---

## 10. Kontroller (Input Map)

| Action | Varsayılan Tuş |
|--------|----------------|
| move_left | Sol Ok |
| move_right | Sağ Ok |
| jump | Z |
| desync | Space *(şu an Player'da kullanılmıyor)* |
| evade | X (Parry) |
| dash | C |
| move_down | S / Aşağı Ok |

---

## 11. Seviye Akışı

| Seviye | Dosya | Sonraki |
|--------|-------|---------|
| 1 | 1 Level.tscn | 3 level .tscn |
| 2 | 2 Level.tscn | 3 level .tscn |
| 3 | 3 level .tscn | 4 level.tscn |
| 4 | 4 level.tscn | 5 level .tscn |
| 5 | 5 level .tscn | 6 level.tscn |
| 6 | 6 level.tscn | 7 level.tscn |
| 7 | 7 level.tscn | 8 level.tscn |
| 8 | 8 level.tscn | 6 level.tscn *(geri dönüş)* |
| 9 | 9 level u.tscn | 6 level.tscn |

**Test sahneleri:** emirantestscene, EgeTestScene

---

## 12. Mevcut Durum Özeti

### Tamamlanan Sistemler
- Oyuncu hareketi (koşma, zıplama, coyote, jump buffer)
- Gölge gecikmeli takip (ShadowTrail, ~1 s)
- Parry mekaniği (spike ve gölgeye karşı)
- Dash (parry sonrası, havada)
- Baskı plakaları, hareketli platformlar, kapılar
- Ölüm, restart, checkpoint reset
- Ses yönetimi
- Pause, ayarlar, ana menü
- Proximity glow, danger pulse, scanline
- Tutorial video tetikleyicileri

### Eksik / Kısmen Uygulanan
- **DESYNC toggle:** GDD'de Space ile 1s→3s gecikme uzatma tanımlı; **Player.gd'de yok**
- **DESYNC enerji tüketimi:** GameState'te var ama tetikleyen input yok
- **Sync bar / HUD:** GameState desync_energy kullanıyor; UIManager'da sync bar yok, HUD ayrı
- **Düşmanlar:** Layer'lar tanımlı, script yok
- **Boss (The Conductor):** GDD'de planlanmış, uygulanmamış

### Bilinen Farklar (GDD vs Kod)
- GDD: Space ile DESYNC toggle, 3 saniye gecikme
- Kod: Gölge gecikmesi sabit ~60 frame, DESYNC input işlenmiyor
- GDD: Enerji barı, sync point'ler
- Kod: EnergyCell pickup var, ama DESYNC kullanılmadığı için enerji barı anlamlı değil

---

## 13. Önerilen Sonraki Adımlar

1. **DESYNC entegrasyonu:** Player.gd'de `desync` action dinlenip GameState'e bağlanmalı; ShadowTrail buffer boyutu SYNC/DESYNC'a göre 60/180 frame olarak ayarlanmalı.
2. **UIManager sync bar:** Enerji çubuğu UIManager'a eklenip GameState ile senkronize edilmeli.
3. **Seviye akışı:** 1→2→3 sırası ve 8. seviye sonrası akış netleştirilmeli.
4. **Düşman / Boss:** GDD'deki enemy ve boss mekanikleri uygulanabilir.

---

*Bu doküman proje kod tabanının incelenmesiyle oluşturulmuştur.*
