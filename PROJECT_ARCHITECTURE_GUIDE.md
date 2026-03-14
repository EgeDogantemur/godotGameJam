# Godot Game Jam - Project Architecture & Systems Guide

Bu doküman, projenin mevcut mimarisini, sistem mantıklarını, node ilişkilerini ve çarpışma (collision) katmanlarını yapay zeka asistanlarına veya yeni geliştiricilere öğretmek amacıyla hazırlanmıştır. Kodu değiştirmeden veya yeni sistem eklemeden önce bu dokümandaki kurallara kesinlikle uyulmalıdır.

## 1. Temel Mimari (Core Systems)

Proje, **Event Bus (Olay Veriyolu)** mimarisini kullanmaktadır. Sahneler arası doğrudan sinyal bağlantıları (spagetti kod) yerine, tüm oyunu ilgilendiren olaylar global bir Autoload üzerinden yönetilir.

- **`GameState.gd` (Autoload - Event Bus):**
  - Oyunun durumunu tutar.
  - Sinyalleri: `state_changed`, `player_died`, `gate_unlocked`, `button_activated`, `energy_cell_collected`.
  - Herhangi bir obje (örneğin buton) basıldığında direkt kapıyı aramak yerine `GameState.trigger_gate_unlock()` çağrısı yapar.
  - Bağımsız sahneler (LevelGoal, HUD vb.) `_ready()` fonksiyonlarında bu global sinyallere (`GameState.gate_unlocked.connect(...)`) abone olurlar. Böylece sahne tasarımından bağımsız, her yerde çalışan modüler bir yapı elde edilmiştir.

- **`UIManager.gd` (Autoload):**
  - Scene geçişlerini (`change_scene_to`), fade-in/fade-out animasyonlarını ve oyunun duraklatılmasını (Pause Menu) yönetir.

## 2. Collision Layers & Masks (Çarpışma Katmanları)

Parry ve etkileşim sistemlerinin donanımında katmanlar (Layers) kritik bir rol oynar. Özellikleri editörden değişse bile, kod güvenliği için asıl objelerin `_ready` fonksiyonlarında bu değerler **hardcode** edilmiştir (zorlanmıştır).

- **Layer 1 (Player_Body):** Sadece `Player` yer alır.
- **Layer 2 (Shadow_Body):** `Shadow` (Gölge) düşmanını barındırır.
- **Layer 3 (World):** `Floor`, `Wall` gibi statik platform objeleri bulunur.
- **Layer 4 (Shadow_Triggers / Hazards):** `BasePressurePlate` (Butonlar), `LevelGoal` (Kapı), `EnergyCell`, ve `ParrySpike` gibi etkileşim ve tehlike objeleri yer alır.

**Önemli Maske Kuralları:**
- `Player.gd` `_ready()` içinde `collision_layer = 1` değerini zorlar. Maskesi 3 ve 4'ü dinlemelidir (Zemin ve tehlikeler).
- `Shadow.gd` ve `ParrySpike.gd` `_ready()` içinde `collision_mask = 1` değerini zorlar. Çünkü oyuncuyu "get_overlapping_bodies()" kullanarak tespit edip öldürmek/parry mekaniğini tetiklemek zorundadırlar.

## 3. Parry (Savuşturma / Sıçrama) Sistemi

Oyunun en temel aksiyon mekaniği "Parry" (Savuşturma) sistemidir. Platform veya mermi fırlatmak yerine "Tehlikeye doğru zamanlamayla çarpma" şeklinde çalışır (Celeste / Hollow Knight tarzı Pogo/Parry).

- **Çalışma Mantığı:**
  1. Oyuncu **Space** (Evade) tuşuna basar.
  2. `Player.gd` içindeki `is_parrying` değişkeni 0.4 saniye (Parry Window) boyunca `true` olur.
  3. `Shadow` (Gölge düşman) veya `ParrySpike` (Statik diken) sürekli olarak kendi içlerindeki Area2D alanına giren "player" grubunu tarar.
  4. Eğer oyuncu alana girer ve o anda `is_parrying == true` ise: **BAŞARILI PARRY**.
  5. Eğer oyuncu alana girer ancak `is_parrying == false` ise: **ÖLÜM**.

- **Başarılı Parry Sonuçları (Game Feel / Juice):**
  - `Player.execute_parry_launch()` tetiklenir.
  - Oyuncu çok şiddetli bir şekilde zıplatılır (`parry_launch_force`). İçeride matematik eksiye (y-up) çevrildiği için inspector'a pozitif (örn: 800) girilir.
  - **Hit-Stop (Freeze):** Oyun 0.12 saniye tamamen durur (Vuruş hissi).
  - **Ekran Sarsıntısı (Camera Shake):** PlayerCamera.gd üzerinden offset değerleriyle rastgele titreme verilir.
  - **Sert Zoom (Punch):** Kamera çok şiddetli ve hızlı bir şekilde (0.65x) karaktere yakınlaşır (`Tween.TRANS_BACK`) ve sonra normal haline (`Vector2.ONE`) döner.
  - **Parry Flash:** Ekran anlık beyaz bir ışık ile kaplanıp söner (`CanvasLayer` ve `ColorRect` yaratılıp yok edilir).
  - **Invincibility (Dokunulmazlık):** `Shadow.gd` ve `ParrySpike.gd` içinde `_cooldown_timer = 0.5` saniyelik bir gecikme başlar. Fırlatılan oyuncunun o salise tekrar obje ile temasta kalıp ölmesini engeller.

- **Zaman Yavaşlaması (Lokal Slow-Mo):**
  - Parry penceresi açıldığında oyunun ana zamanı (`Engine.time_scale`) KESİNLİKLE yavaşlatılmaz (Çünkü bu oyuncuyu da yavaşlatır).
  - Bunun yerine `ShadowTrail.gd` içindeki `_set_target_speed(0.15)` komutu devreye girer. Yani sadece takip eden gölge %15 hızda yavaş çekimde hareket eder. Oyuncu %100 hızla parry şansını yakalamak için pozisyon alır.

## 4. Karakter & Kamera Mantığı

- **`Player.gd`:** CharacterBody2D. `Coyote Time` ve `Jump Buffer` implante edilmiştir, bu sayede zıplama hissiyatı çok daha profesyonel ve affedicidir.
- **`PlayerCamera.gd`:** Player altındaki Camera2D düğümüne bağlı özel script.
  - **Smoothness:** Alt-pixel takip yumuşatması.
  - **Look-Ahead:** Karakter sağa giderken kamera ekranın sağını ("bakış açısını" - Look Ahead X) daha çok gösterir. Karakter hızla aşağı düşüyorken kamera da aşağı ("Look Ahead Y") yönelerek nereye düşeceğinizi gösterir.

## 5. Etkileşim Objeleri

Tüm etkileşimli objeler sadece "içine girildiği" veya "Area2D sinyali ile temas olduğu" zaman aktifleşir.

- **`BasePressurePlate` (Butonlar):**
  - Tipi vardır (Sadece Oyuncu, Sadece Gölge, Veya İkisi Birden).
  - İçine giren objenin grubuna ("player" veya "shadow") bakar.
  - Basıldığında `GameState.trigger_gate_unlock()` yayınlar (Event Bus).
  - Birden fazla objenin butonun üstünde durması durumu `_occupants` sayacı ile takip edilir.

- **`LevelGoal` (Kapı):**
  - Normalde kilitlidir (`locked = true`). Kilitliyken simsiyah ve işlevsizdir.
  - `_ready()` içerisinde GameState'in `gate_unlocked` sinyaline abone olur. Sinyal gelince Tween animasyonuyla büyür, aydınlanır ve işlevsel hale gelir.
  - Aktif kapıya değen oyuncu bir sonraki sahneye geçer (`UIManager.change_scene_to`).

- **`EnergyCell.gd`:**
  - Havada duran, sinüs dalgası (`sin()`) ile yüzen toplanabilir objelerdir.
  - Oyuncu değdiğinde toplanır, UI'a yansıtılır ve kaybolur.

## Geliştirici / Asistan Notları
1. **"Player algılanmıyor / Parry çalışmıyor" hatası:** %99 ihtimalle sahnede Player'ın `collision_layer=1` ayarının elle bozulmasından veya Area2D maskelerinin kaybolmasından kaynaklanır. O yüzden `_ready()` içindeki mask zorlamalarını (hardcode katman atamaları) `Shadow` ve `Player` için kaldırmayın.
2. **Tween çökme hatası (`common_parent is null`):** Bir Node henüz `SceneTree` içine fiziksel olarak eklenmeden veya `call_deferred` ile eklenecekken onu `Tween` işlemine sokmaya çalıştığınızda Godot motoru çöker. Objeleri `add_child()` ile anında ekleyip ardından `tween` yaratın.
3. **Ölüp Başa Dönme:** Çoğu sahnede `UIManager.change_scene_to` veya `get_tree().reload_current_scene()` kullanılır. Öldüğümüzde state `DEAD` olur, fader kararır ve sahne kendini reload edip `SYNC` haline geri döner.
