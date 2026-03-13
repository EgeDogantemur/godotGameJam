**ECHO**

Sprint Teknik Dökümanı

Godot 4.6.1 · GDScript · 2D · Agentic AI için Kaynak Döküman · v1.0

*\"Gölgen senden 1 saniye geride. Bu gecikme senin zayıflığın değil --- silahın.\"*

**0. Bu Dökümanı Nasıl Kullanmalısın**

Bu döküman GDD\'yi (ECHO Game Design Document) Godot 4.6.1 ile geliştirme için sprint bazlı teknik adımlara dönüştürmektedir. Agentic AI\'ın kaynak olarak kullanması için her sprint kendi içinde bağımsız ve uygulanabilir olarak tasarlanmıştır.

***Her sprint bir \'Tamamlanma Kriteri\' içerir. AI o kriteri karşılayan kodu üretip test etmeden bir sonraki sprint\'e geçmemelidir.***

**Godot 4 --- Unity Karşılıkları (GDD\'de Unity kullanılmıştı)**

|                    |                                           |                                      |
|--------------------|-------------------------------------------|--------------------------------------|
| **Unity / Genel**  | **Godot 4 Karşılığı**                     | **Not**                              |
| MonoBehaviour      | Node / extends Node2D                     | Her script bir Node\'u extend eder   |
| GameObject         | Node / Scene                              | Sahne = prefab mantığı               |
| FixedUpdate()      | \_physics_process(delta)                  | Fizik işlemleri burada               |
| Update()           | \_process(delta)                          | Görsel / input güncelleme            |
| Queue\<Vector2\>   | Array (ring index ile)                    | GDScript\'te Queue yok, Array kullan |
| Collision Layer    | collision_layer / collision_mask bit mask | Project Settings \> Layer Names      |
| Shader float param | ShaderMaterial set_shader_parameter()     | Godot 4 API                          |
| AudioMixer         | AudioBus + AudioServer                    | Bus layout ile volume control        |
| Time.timeScale     | Engine.time_scale                         | Tüm fizik + process etkilenir        |
| Prefab             | .tscn (Scene dosyası)                     | instantiate() ile sahneye eklenir    |
| ScriptableObject   | Resource (.tres)                          | Veri dosyaları için                  |

**1. Proje Yapısı ve Kurulum**

**1.1 Klasör Yapısı**

|                       |                                                    |
|-----------------------|----------------------------------------------------|
| **Klasör / Dosya**    | **Açıklama**                                       |
| res://scenes/         | Tüm .tscn sahneleri                                |
| res://scripts/        | Tüm .gd script dosyaları                           |
| res://assets/sprites/ | Karakter + çevre sprite\'ları                      |
| res://assets/shaders/ | desync.gdshader, outline.gdshader                  |
| res://assets/audio/   | Müzik loop\'ları + SFX                             |
| res://levels/         | level_1.tscn → level_6.tscn + boss.tscn            |
| res://autoload/       | GameState.gd, AudioManager.gd (Autoload/Singleton) |

**1.2 Proje Ayarları (Project Settings)**

**Physics → 2D**

- Default Gravity: 980

- Layer Names tanımla (sırasıyla): player_body, shadow_body, world, shadow_triggers, enemy_body, enemy_target

**Input Map**

- move_left → A / Sol Ok

- move_right → D / Sağ Ok

- jump → W / Yukarı Ok / Space

- desync → ui_accept (Space veya Gamepad A)

- (Not: jump ve desync ayrı action --- ikisi aynı tuşa bağlanmamalı)

**Autoload**

- GameState.gd → /autoload/GameState.gd (singleton)

- AudioManager.gd → /autoload/AudioManager.gd (singleton)

***Godot 4.6.1\'de \'ui_accept\' varsayılan olarak Space + Enter\'a bağlıdır. desync action\'ı için ayrı bir binding tanımla.***

**1.3 Collision Layer Mimarisi**

|           |                 |                              |                               |
|-----------|-----------------|------------------------------|-------------------------------|
| **Layer** | **İsim**        | **Üyeler**                   | **Çarpışır**                  |
| 1         | player_body     | Oyuncu CharacterBody2D       | world, enemy_body             |
| 2         | shadow_body     | Gölge Area2D                 | shadow_triggers, enemy_target |
| 3         | world           | TileMap, statik platformlar  | player_body                   |
| 4         | shadow_triggers | Baskı kapısı triggerları     | shadow_body                   |
| 5         | enemy_body      | Düşman CharacterBody2D       | player_body, world            |
| 6         | enemy_target    | Düşman hedef algılama Area2D | shadow_body, player_body      |

**1.4 State Machine Enum**

|           |                              |                          |                       |
|-----------|------------------------------|--------------------------|-----------------------|
| **State** | **Giriş Koşulu**             | **Çıkış Koşulu**         | **Godot Sinyal**      |
| SYNC      | Başlangıç / DESYNC biter     | ui_accept basılı tutulur | state_changed(SYNC)   |
| DESYNC    | ui_accept basılı + enerji\>0 | Bırakılır / enerji=0     | state_changed(DESYNC) |
| RESYNC    | DESYNC→SYNC geçişi           | 0.2 sn Timer biter       | resync_flash()        |
| DEAD      | Shadow overlap 2+ frame      | Checkpoint respawn       | player_died()         |

**1.5 Sprint Genel Bakış**

|            |                     |                                           |          |
|------------|---------------------|-------------------------------------------|----------|
| **Sprint** | **Odak**            | **Teslim Kriterleri**                     | **Süre** |
| S-0        | Proje iskelet       | Sahne yapısı, input map, autoload         | \~2 saat |
| S-1        | Karakter hareketi   | Koşma, zıplama, coyote, buffer            | \~3 saat |
| S-2        | Ring buffer + gölge | Gölge 60-frame gecikmeli takip            | \~3 saat |
| S-3        | DESYNC toggle       | State machine, enerji barı, shader param  | \~4 saat |
| S-4        | Baskı kapısı        | Shadow trigger → kapı açılır              | \~2 saat |
| S-5        | Düşman AI           | Seek/flee, gölge önceliği                 | \~3 saat |
| S-6        | Level 1--3          | Diegetic tutorial, Level 1--3 oynanabilir | \~4 saat |
| S-7        | Level 4--5 + Boss   | Decoy mekaniği, boss 3 faz                | \~5 saat |
| S-8        | Görsel + Ses polish | Shader, particles, ses zinciri            | \~4 saat |
| S-9        | Test + Submit       | Playtest, hitbox kalibrasyon, build       | \~4 saat |

**Sprint 0 --- Proje İskeleti (\~2 saat)**

***Tamamlanma Kriteri: Boş sahne açılıyor, input map çalışıyor, autoload yükleniyor. Hiç görsel yok.***

**S-0.1 Sahne Yapısını Oluştur**

1.  Godot\'ta yeni proje: ECHO_Game

2.  res://scenes/main.tscn → Node2D kökü, adı: Main

3.  res://scenes/player.tscn → CharacterBody2D kökü, adı: Player

4.  res://scenes/shadow.tscn → Area2D kökü, adı: Shadow

5.  res://scenes/level_1.tscn → Node2D, TileMap child ekle

6.  res://autoload/GameState.gd → extends Node, Autoload olarak kaydet

7.  res://autoload/AudioManager.gd → extends Node, Autoload olarak kaydet

**S-0.2 GameState.gd Başlangıcı**

\# res://autoload/GameState.gd

extends Node

enum State { SYNC, DESYNC, RESYNC, DEAD }

var current_state: State = State.SYNC

var desync_energy: float = 4.0 \# saniye cinsinden max

var desync_energy_max: float = 4.0

var checkpoint_pos: Vector2 = Vector2.ZERO

signal state_changed(new_state: State)

signal player_died()

signal resync_flash()

**S-0.3 Input Map Testi**

Project Settings \> Input Map\'e gir ve şu action\'ları tanımla:

- move_left, move_right, jump, desync

Test: \_process() içinde print(Input.is_action_pressed(\'desync\')) yazarak konsolda doğrula.

**Sprint 1 --- Karakter Hareketi (\~3 saat)**

***Tamamlanma Kriteri: Karakter düz zemin üzerinde koşuyor, zıplıyor, Coyote Time ve Input Buffer çalışıyor. Gölge yok henüz.***

**S-1.1 Player Sahnesi Kurulumu**

- Player.tscn yapısı:

<!-- -->

- CharacterBody2D (Player)

- └─ CollisionShape2D → CapsuleShape2D, Physics Layer: player_body (1)

- └─ Sprite2D → karakter sprite

- └─ AnimationPlayer → idle, run, jump, fall, death animasyonları

- └─ RayCast2D × 2 → sol/sağ kenar coyote check

**S-1.2 Player.gd --- Hareket Scripti**

\# res://scripts/Player.gd

extends CharacterBody2D

const SPEED = 220.0

const JUMP_FORCE = -520.0

const GRAVITY = 980.0

const COYOTE_TIME = 0.12 \# saniye

const JUMP_BUFFER = 0.10 \# saniye --- erken zıplama toleransı

var \_coyote_timer : float = 0.0

var \_jump_buffer : float = 0.0

var \_was_on_floor : bool = false

func \_physics_process(delta: float) -\> void:

\_apply_gravity(delta)

\_handle_coyote(delta)

\_handle_jump_buffer(delta)

\_handle_movement()

\_try_jump()

move_and_slide()

\_update_animation()

func \_apply_gravity(delta: float) -\> void:

if not is_on_floor():

velocity.y += GRAVITY \* delta

func \_handle_coyote(delta: float) -\> void:

if \_was_on_floor and not is_on_floor():

\_coyote_timer = COYOTE_TIME

elif is_on_floor():

\_coyote_timer = COYOTE_TIME \# sıfırlamak yerine dolu tut

else:

\_coyote_timer -= delta

\_was_on_floor = is_on_floor()

func \_handle_jump_buffer(delta: float) -\> void:

if Input.is_action_just_pressed(\'jump\'):

\_jump_buffer = JUMP_BUFFER

else:

\_jump_buffer -= delta

func \_handle_movement() -\> void:

var dir = Input.get_axis(\'move_left\', \'move_right\')

velocity.x = dir \* SPEED

func \_try_jump() -\> void:

var can_jump = is_on_floor() or \_coyote_timer \> 0.0

if \_jump_buffer \> 0.0 and can_jump:

velocity.y = JUMP_FORCE

\_coyote_timer = 0.0

\_jump_buffer = 0.0

func \_update_animation() -\> void:

if not is_on_floor():

\$AnimationPlayer.play(\'jump\' if velocity.y \< 0 else \'fall\')

elif abs(velocity.x) \> 10:

\$AnimationPlayer.play(\'run\')

else:

\$AnimationPlayer.play(\'idle\')

**S-1.3 Collision Layer Atama**

- Player CharacterBody2D → collision_layer = 1 (player_body), collision_mask = 4 (world)

- TileMap → collision_layer = 4 (world), collision_mask = 0

**S-1.4 Test Kontrol Listesi**

- Karakter sola/sağa koşuyor ✓

- Zıplama çalışıyor ✓

- Zeminden düştükten 0.12 sn sonra zıplayabiliyor (coyote) ✓

- Zıplama tuşunu 0.1 sn erken basınca yere değince zıplıyor (buffer) ✓

- Gravity uygulanıyor, yerçekimiyle düşüyor ✓

**Sprint 2 --- Ring Buffer ve Gölge Sistemi (\~3 saat)**

***Tamamlanma Kriteri: Gölge, oyuncunun hareketlerini tam 60 frame (\~1 sn) gecikmeli tekrarlıyor. Görsel ayrı, collision ayrı.***

**S-2.1 Ring Buffer --- Tasarım Kararı**

GDD\'deki Queue\<Vector2\> Unity konseptini Godot 4\'te Array + dairesel index ile uyguluyoruz. Boyut dinamik: SYNC=60, DESYNC=180 frame.

***Kritik: Buffer boyutu GameState.current_state\'e göre her frame güncellenir. DESYNC aktifken gölge 3 saniye geride kalır --- bu hem kapılar için fırsat hem ölüm riski.***

**S-2.2 ShadowTrail.gd --- Ring Buffer Scripti**

\# res://scripts/ShadowTrail.gd

\# Bu script Player node\'una eklenir, gölgeyi yönetir

extends Node

const BUFFER_SYNC = 60 \# 1 saniye @ 60fps

const BUFFER_DESYNC = 180 \# 3 saniye @ 60fps

var \_buffer: Array\[Dictionary\] = \[\]

var \_write_idx: int = 0

var \_buffer_size: int = BUFFER_SYNC

@onready var shadow_node: Node2D = \$\'../Shadow\' \# sahne köküne bağlı

@onready var player: CharacterBody2D = get_parent()

func \_ready() -\> void:

\# Buffer\'ı başlangıç pozisyonuyla doldur

\_buffer.resize(BUFFER_DESYNC)

for i in BUFFER_DESYNC:

\_buffer\[i\] = { \'pos\': player.global_position, \'flip\': false }

GameState.state_changed.connect(\_on_state_changed)

func \_physics_process(\_delta: float) -\> void:

\# 1. Mevcut frame\'i kaydet

\_buffer\[\_write_idx\] = {

\'pos\': player.global_position,

\'flip\': player.get_node(\'Sprite2D\').flip_h

}

\_write_idx = (\_write_idx + 1) % BUFFER_DESYNC

\# 2. Gölge pozisyonunu buffer_size kadar önceki frame\'den oku

var read_idx: int = (\_write_idx - \_buffer_size + BUFFER_DESYNC) % BUFFER_DESYNC

var data = \_buffer\[read_idx\]

shadow_node.global_position = data\[\'pos\'\]

shadow_node.get_node(\'Sprite2D\').flip_h = data\[\'flip\'\]

func \_on_state_changed(new_state: GameState.State) -\> void:

match new_state:

GameState.State.DESYNC:

\_buffer_size = BUFFER_DESYNC

\_:

\_buffer_size = BUFFER_SYNC

**S-2.3 Shadow Sahnesi Kurulumu**

- Shadow.tscn yapısı:

<!-- -->

- Area2D (Shadow)

- └─ CollisionShape2D → CapsuleShape2D (oyuncuyla aynı boyut × 0.5)

- └─ Sprite2D → oyuncuyla aynı sprite, modulate alpha = 0.45

- └─ ColorRect/Shader → gölge renk overlay

<!-- -->

- Shadow Area2D → collision_layer = 2 (shadow_body), collision_mask = 0

- Shadow CollisionShape2D boyutu: oyuncu collision\'ının %50\'si (adil hitbox prensibi)

**S-2.4 Kendi Gölgene Çarpma --- Ölüm Kontrolü**

\# Shadow.gd --- Area2D script

extends Area2D

var \_overlap_frames: int = 0

const GRACE_FRAMES: int = 2 \# 2 frame grace period

func \_physics_process(\_delta: float) -\> void:

var player = get_tree().get_first_node_in_group(\'player\')

if player == null: return

var dist = global_position.distance_to(player.global_position)

var threshold = 16.0 \# pixel --- hitbox yarıçapına göre ayarla

if dist \< threshold:

\_overlap_frames += 1

if \_overlap_frames \>= GRACE_FRAMES:

GameState.player_died.emit()

else:

\_overlap_frames = 0

**S-2.5 Test Kontrol Listesi**

- Gölge, oyuncunun tam 1 sn önceki hareketini izliyor ✓

- DESYNC aktifken (manuel test için geçici buton) gölge 3 sn geride ✓

- Gölge kendi sahnesi --- oyuncunun child\'ı değil ✓

- Üstüste gelince 2 frame sonra sinyal yayılıyor ✓

- Gölge sprite flip_h de gecikmeli yansıtılıyor ✓

**Sprint 3 --- DESYNC Toggle, Enerji ve Görsel (\~4 saat)**

***Tamamlanma Kriteri: Space ile DESYNC aktif olunca gölge 3 sn\'ye geçiyor, enerji barı tükeniyor, shader parametresi değişiyor.***

**S-3.1 GameState Enerji Sistemi**

\# GameState.gd --- enerji yönetimi eklentisi

const ENERGY_DRAIN_RATE = 1.0 / 4.0 \# 4 saniyede tüketim

const ENERGY_REGEN_RATE = 1.0 / 4.0 \# 4 saniyede dolum (SYNC)

const SYNC_POINT_BONUS = 0.50 \# sync point %50 anlık dolum

func \_process(delta: float) -\> void:

match current_state:

State.DESYNC:

desync_energy -= ENERGY_DRAIN_RATE \* delta \* desync_energy_max

if desync_energy \<= 0.0:

desync_energy = 0.0

\_set_state(State.RESYNC)

State.SYNC:

desync_energy = minf(desync_energy + ENERGY_REGEN_RATE \* delta \* desync_energy_max, desync_energy_max)

func \_set_state(new_state: State) -\> void:

current_state = new_state

state_changed.emit(new_state)

if new_state == State.RESYNC:

resync_flash.emit()

await get_tree().create_timer(0.2).timeout

\_set_state(State.SYNC)

func add_sync_point_energy() -\> void:

desync_energy = minf(desync_energy + desync_energy_max \* SYNC_POINT_BONUS, desync_energy_max)

**S-3.2 Player.gd --- DESYNC Input**

\# Player.\_physics_process() sonuna ekle:

func \_handle_desync_input() -\> void:

var pressing = Input.is_action_pressed(\'desync\')

match GameState.current_state:

GameState.State.SYNC:

if pressing and GameState.desync_energy \> 0.0:

GameState.\_set_state(GameState.State.DESYNC)

GameState.State.DESYNC:

if not pressing:

GameState.\_set_state(GameState.State.RESYNC)

**S-3.3 DESYNC Shader**

Tek bir shader tüm görsel DESYNC efektini kontrol eder. Shader parametresi 0.0 (SYNC) ile 1.0 (full DESYNC) arasında lerp edilir.

\# res://assets/shaders/desync.gdshader

shader_type canvas_item;

uniform float desync_amount : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {

vec2 uv = SCREEN_UV;

// Chromatic aberration

float offset = desync_amount \* 0.006;

vec4 col;

col.r = texture(SCREEN_TEXTURE, uv + vec2(offset, 0.0)).r;

col.g = texture(SCREEN_TEXTURE, uv).g;

col.b = texture(SCREEN_TEXTURE, uv - vec2(offset, 0.0)).b;

col.a = 1.0;

// Scan-line

float line = sin(uv.y \* 800.0) \* 0.04 \* desync_amount;

COLOR = col - vec4(line);

}

\# Player.gd --- shader parametresini güncelle

@onready var shader_mat: ShaderMaterial = \$Sprite2D.material

func \_on_state_changed(new_state: GameState.State) -\> void:

var target = 1.0 if new_state == GameState.State.DESYNC else 0.0

var tween = create_tween()

tween.tween_method(func(v): shader_mat.set_shader_parameter(\'desync_amount\', v),

shader_mat.get_shader_parameter(\'desync_amount\'),

target, 0.2)

**S-3.4 Enerji Barı UI**

\# res://scenes/ui/EnergyBar.tscn

\# TextureProgressBar node --- Autosize: 200x12

\# EnergyBar.gd

extends TextureProgressBar

func \_process(\_delta: float) -\> void:

value = GameState.desync_energy / GameState.desync_energy_max

\# Kırmızı pulse --- enerji düşükken

if GameState.desync_energy \< GameState.desync_energy_max \* 0.25:

modulate = Color(1, 0.3, 0.3, abs(sin(Time.get_ticks_msec() \* 0.005)))

else:

modulate = Color.WHITE

**S-3.5 Resync Flash**

\# Player.gd --- resync_flash sinyalini dinle

func \_ready() -\> void:

GameState.resync_flash.connect(\_on_resync_flash)

func \_on_resync_flash() -\> void:

var tween = create_tween()

tween.tween_property(\$Sprite2D, \'modulate\', Color(1,1,1,0), 0.05)

tween.tween_property(\$Sprite2D, \'modulate\', Color(1,1,1,1), 0.15)

**S-3.6 Test Kontrol Listesi**

- Space basılı tutunca DESYNC aktif, enerji barı tükeniyor ✓

- Enerji bitince otomatik SYNC\'e dönüş ✓

- Chromatic aberration + scan-line DESYNC\'te görünüyor ✓

- Resync flash 0.2 sn çalışıyor ✓

- Kırmızı pulse %25 altında aktif ✓

**Sprint 4 --- Baskı Kapısı Mekaniği (\~2 saat)**

***Tamamlanma Kriteri: Gölge baskı kapısı triggerına girince kapı açılıyor ve oyuncu içinden geçebiliyor.***

**S-4.1 PressureDoor.tscn Yapısı**

- PressureDoor.tscn:

<!-- -->

- Node2D (PressureDoor)

- └─ AnimatableBody2D (kapı bloğu) → Layer: world(3)

- └─ CollisionShape2D

- └─ Area2D (trigger bölgesi) → Layer: shadow_triggers(4), Mask: shadow_body(2)

- └─ CollisionShape2D

- └─ AnimationPlayer → \'open\', \'close\' animasyonları

**S-4.2 PressureDoor.gd**

\# res://scripts/PressureDoor.gd

extends Node2D

@onready var trigger: Area2D = \$TriggerArea

@onready var anim: AnimationPlayer = \$AnimationPlayer

var \_open: bool = false

func \_ready() -\> void:

trigger.body_entered.connect(\_on_shadow_enter)

trigger.body_exited.connect(\_on_shadow_exit)

func \_on_shadow_enter(body: Node2D) -\> void:

if body.is_in_group(\'shadow\') and not \_open:

\_open = true

anim.play(\'open\')

func \_on_shadow_exit(body: Node2D) -\> void:

if body.is_in_group(\'shadow\') and \_open:

\_open = false

anim.play(\'close\')

**S-4.3 Sync Point**

Baskı kapılarının yanına SyncPoint marker konulur. Gölge bu noktayı geçince enerji +%50.

\# SyncPoint.gd

extends Area2D

func \_ready() -\> void:

body_entered.connect(\_on_body_enter)

func \_on_body_enter(body: Node2D) -\> void:

if body.is_in_group(\'shadow\'):

GameState.add_sync_point_energy()

\# Opsiyonel: pulse animasyon oyna

**S-4.4 Test Kontrol Listesi**

- DESYNC aktifken gölge 3 sn sonra kapıya ulaşıyor, kapı açılıyor ✓

- Gölge triggerdan çıkınca kapı kapanıyor ✓

- Sync point gölge üzerinden geçince enerji +%50 ✓

- Kapı sadece shadow_body layer\'ı algılıyor, player_body değil ✓

**Sprint 5 --- Düşman AI (\~3 saat)**

***Tamamlanma Kriteri: Düşman SYNC\'te oyuncuyu takip eder, DESYNC\'te gölgeyi öncelikli hedef alır. Basit seek/flee, karmaşık davranış ağacı yok.***

**S-5.1 Enemy.tscn Yapısı**

- Enemy.tscn:

<!-- -->

- CharacterBody2D (Enemy) → Layer: enemy_body(5)

- └─ CollisionShape2D

- └─ Sprite2D

- └─ Area2D (DetectionArea) → Mask: player_body(1) + shadow_body(2)

- └─ CollisionShape2D (CircleShape, radius=200px)

- └─ NavigationAgent2D

**S-5.2 Enemy.gd**

\# res://scripts/Enemy.gd

extends CharacterBody2D

const SPEED = 120.0

const DETECT_RADIUS = 200.0

const GRAVITY = 980.0

enum EnemyState { PATROL, CHASE_PLAYER, CHASE_SHADOW }

var \_state: EnemyState = EnemyState.PATROL

var \_target: Node2D = null

@onready var detect: Area2D = \$DetectionArea

@onready var nav: NavigationAgent2D = \$NavigationAgent2D

func \_ready() -\> void:

detect.body_entered.connect(\_on_body_enter)

detect.body_exited.connect(\_on_body_exit)

GameState.state_changed.connect(\_on_game_state_changed)

func \_physics_process(delta: float) -\> void:

if not is_on_floor():

velocity.y += GRAVITY \* delta

\_update_target()

if \_target:

nav.target_position = \_target.global_position

var dir = nav.get_next_path_position() - global_position

velocity.x = sign(dir.x) \* SPEED

else:

velocity.x = move_toward(velocity.x, 0, SPEED)

move_and_slide()

func \_update_target() -\> void:

\# DESYNC aktifse gölge öncelikli

if GameState.current_state == GameState.State.DESYNC:

var shadow = get_tree().get_first_node_in_group(\'shadow\')

if shadow and global_position.distance_to(shadow.global_position) \< DETECT_RADIUS:

\_target = shadow

return

\# Yoksa oyuncu

var player = get_tree().get_first_node_in_group(\'player\')

if player and global_position.distance_to(player.global_position) \< DETECT_RADIUS:

\_target = player

else:

\_target = null

func \_on_game_state_changed(new_state: GameState.State) -\> void:

\# State değişince hedefi yeniden değerlendir

\_update_target()

**S-5.3 Decoy Kontrolü**

Düşman gölgeyi takip ederken oyuncu başka yoldan geçer --- Level 4\'ün temel mekaniği. Bu kod S-5.2\'de zaten kurulu. Ekstra logic gerekmez.

Teknik not: NavigationAgent2D için Navigation Region 2D sahneye eklenmiş olmalı. Basit bir dikdörtgen navigation mesh yeterli.

**S-5.4 Test Kontrol Listesi**

- SYNC\'te düşman oyuncuyu takip ediyor ✓

- DESYNC aktifken düşman gölgeye yöneliyor ✓

- Gölge triggerdan çıkınca düşman tekrar oyuncuya dönüyor ✓

- Düşman yerçekimiyle düşüyor, zemine çarpıyor ✓

**Sprint 6 --- Level 1--3 ve Diegetic Tutorial (\~4 saat)**

***Tamamlanma Kriteri: Level 1--3 baştan sona oynanabilir. Hiç UI metni yok, tüm öğretme fiziksel.***

**S-6.1 Level 1 --- The Signal**

Tasarım: Oyuncu gölgenin varlığını kendisi fark eder. Sıfır metin.

**Oda 1 --- Tanışma**

- Geniş, tamamen düz zemin. Herhangi bir engel yok.

- Oyuncu ilerlediğinde gölge 1 sn sonra aynı hareketi tekrarlıyor --- oyuncu kendi izini izliyor.

- DESYNC butonu bu odada devre dışı (GameState.desync_locked = true flag\'i).

**Oda 2 --- İlk Bariyer**

- Tek duvar. Sola git → dur → gölge geçsin → devam et. Başka çözüm yolu yok.

- Dar koridor: oyuncu zorla durmak zorunda.

**Oda 3 --- İlk Baskı Kapısı**

- Baskı kapısı yerleştirildi. Oyuncu SYNC\'te ilerliyor, gölge 1 sn sonra kapıya ulaşıyor, kapı geçici açılıyor.

- Bu oda geçildikten sonra: desync_locked = false → DESYNC butonu aktif.

**S-6.2 Level 2 --- Pressure**

DESYNC toggle\'ın ilk kullanıldığı bölüm. Enerji kısıtı bol --- hata toleransı yüksek.

- Baskı kapısı var ama SYNC\'te geçmek imkânsız (gölge kapıya yetişemiyor).

- Çözüm: DESYNC aktif edince gölge geride kalıyor → kapıya 3 sn sonra ulaşıyor → kapı açık kalıyor → oyuncu geçiyor.

- Sync point kapının hemen önüne yerleştirildi --- enerji yenileniyor.

**S-6.3 Level 3 --- The Blind Spot**

Işık + görünmez platform mekaniği. DESYNC\'te gölge ışıkta görünmez, bu görünmez platformları ortaya çıkarır.

- Karanlık bölge: normal ışık kaynakları platform kenarlarını gösteriyor.

- DESYNC aktifken: gölge ışıkta kaybolur → oyuncu gölgenin \'yok olduğu\' yeri görerek gizli platformu tespit eder.

- Teknik: DESYNC modunda gölge Sprite2D → modulate.a = 0 (görünmez). Sahneye invisible_platform grubu ekle.

\# InvisiblePlatform.gd --- DESYNC\'te visible

extends StaticBody2D

func \_ready() -\> void:

GameState.state_changed.connect(\_on_state_changed)

\$Sprite2D.visible = false

func \_on_state_changed(s: GameState.State) -\> void:

\$Sprite2D.visible = (s == GameState.State.DESYNC)

\# Collision her zaman aktif --- görünmez ama varlar

**S-6.4 LevelManager.gd**

\# res://autoload/LevelManager.gd

extends Node

var current_level: int = 1

const LEVELS = {

1: \'res://levels/level_1.tscn\',

2: \'res://levels/level_2.tscn\',

3: \'res://levels/level_3.tscn\',

4: \'res://levels/level_4.tscn\',

5: \'res://levels/level_5.tscn\',

6: \'res://levels/boss.tscn\'

}

func load_next_level() -\> void:

current_level += 1

if LEVELS.has(current_level):

get_tree().change_scene_to_file(LEVELS\[current_level\])

func respawn_player() -\> void:

\# Checkpoint pozisyonuna geri dön, GameState sıfırla

GameState.desync_energy = GameState.desync_energy_max

GameState.\_set_state(GameState.State.SYNC)

var player = get_tree().get_first_node_in_group(\'player\')

if player:

player.global_position = GameState.checkpoint_pos

**S-6.5 Test Kontrol Listesi**

- Level 1--3 baştan sona oynanabilir ✓

- Level 1\'de DESYNC butonu kilitli, Level 1 bitince açılıyor ✓

- Level 3 görünmez platform DESYNC\'te ortaya çıkıyor ✓

- Ölüm → checkpoint respawn çalışıyor ✓

- Level geçişi çalışıyor ✓

**Sprint 7 --- Level 4--5 ve Boss Arena (\~5 saat)**

***Tamamlanma Kriteri: Level 4 decoy mekaniği çalışıyor. Level 5 tüm mekanikleri zincirliyor. Boss 3 fazı tamamlanabilir.***

**S-7.1 Level 4 --- Decoy**

Epiphany level: gölge aktif araç olarak kullanılıyor.

- Düşman kapının önünde patrol yapıyor.

- DESYNC aktif edince gölge 3 sn geride giriyor → düşman gölgeye yöneliyor → oyuncu üstten veya alttan geçiyor.

- Checkpoint kapının ardına konuldu.

- Tasarım notu: Düşman ve kapı arasında yeterli mesafe bırak ki gölge \'yem\' görevini net görünsün.

**S-7.2 Level 5 --- Phase Corridor**

Tüm mekanikler kısa sürede peş peşe kullanılıyor.

- Bölüm 1: Baskı kapısı --- DESYNC + bekle

- Bölüm 2: Görünmez platform --- gölge rehberliği

- Bölüm 3: İki düşman + decoy --- gölge yem

- Bölüm 4: Hassas zamanlama --- gölge ile kapı + düşman aynı anda

**S-7.3 Boss --- The Conductor**

Boss üç fazda kurgulanmıştır. Faz geçişleri HP eşiklerine bağlıdır.

**Boss.gd --- Faz Yönetimi**

\# res://scripts/Boss.gd

extends CharacterBody2D

enum BossPhase { ONE, TWO, THREE }

var phase: BossPhase = BossPhase.ONE

var hp: float = 100.0

func take_damage(amount: float) -\> void:

hp -= amount

if hp \<= 66.0 and phase == BossPhase.ONE:

\_enter_phase(BossPhase.TWO)

elif hp \<= 33.0 and phase == BossPhase.TWO:

\_enter_phase(BossPhase.THREE)

elif hp \<= 0.0:

\_boss_defeated()

func \_enter_phase(new_phase: BossPhase) -\> void:

phase = new_phase

match phase:

BossPhase.TWO:

\# Gölge gecikmeyi 3s\'ye çıkar --- tüm oda DESYNC

\_force_arena_desync(true)

BossPhase.THREE:

\# Roles Reversed: boss SYNC\'te, oyuncu SYNC kalmak zorunda

\_force_arena_desync(false)

GameState.desync_locked = true \# DESYNC butonu kilitlendi

func \_force_arena_desync(active: bool) -\> void:

\# DESYNC görsel efekti tüm arenayı kaplar

var shader = get_tree().get_first_node_in_group(\'arena_shader\')

if shader:

shader.set_shader_parameter(\'desync_amount\', 1.0 if active else 0.0)

**Boss Faz Özeti**

- Faz 1: Standart platform arena. Boss karşıya atlar, oyuncu SYNC/DESYNC ile pozisyon alıyor.

- Faz 2: Boss gölgesini 3 sn uzatıyor. Arena DESYNC kirliliğiyle doluyor. Enerji hızlı tükeniyor.

- Faz 3 --- Roles Reversed: Boss oyuncunun gölgesini kontrol ediyor. DESYNC butonu kilitlendi. Oyuncu sadece SYNC\'te kalarak boss paternini okumalı.

**S-7.4 Test Kontrol Listesi**

- Level 4 decoy çalışıyor: düşman gölgeyi takip ederken oyuncu geçiyor ✓

- Level 5 tüm mekanikler zinciri çalışıyor ✓

- Boss Faz 1→2 HP %66\'da geçiyor ✓

- Boss Faz 2→3 HP %33\'te geçiyor, DESYNC kilitlendi ✓

- Boss öldürülünce oyun bitiş ekranına gidiyor ✓

**Sprint 8 --- Görsel, Ses ve Polish (\~4 saat)**

***Tamamlanma Kriteri: Screen shake, parçacık efektleri, ses zinciri hazır. DESYNC modu \'tatmin edici\' hissettiriyor.***

**S-8.1 Screen Shake**

\# res://autoload/CameraShake.gd

extends Node

@onready var cam: Camera2D = null \# assign in \_ready

func shake(intensity: float, duration: float) -\> void:

var tween = create_tween()

var end_time = Time.get_ticks_msec() / 1000.0 + duration

while Time.get_ticks_msec() / 1000.0 \< end_time:

if cam:

cam.offset = Vector2(randf_range(-intensity, intensity),

randf_range(-intensity, intensity))

await get_tree().process_frame

if cam:

cam.offset = Vector2.ZERO

\# Kullanım: CameraShake.shake(4.0, 0.2) \# ölüm anında

**S-8.2 Parçacık Efektleri**

- GPUParticles2D: shadow_dust --- gölge hareket ederken iz bırakıyor

- GPUParticles2D: resync_burst --- RESYNC anında patlama efekti

- GPUParticles2D: death_shatter --- oyuncu öldüğünde sprite parçalanıyor

- Tüm parçacıklar one_shot=true, emitting signal ile tetikleniyor

**S-8.3 Ses Zinciri --- Godot 4 AudioBus**

Godot 4\'te AudioServer + Bus layout ile ses yönetimi. WebGL kısıtı: Low/High-pass AudioEffect kullanma.

\# AudioManager.gd

extends Node

\# Bus layout: Master \> Music \> SFX

\# DESYNC efekti: Volume Ducking yöntemi

var \_music_bus_idx: int

const DESYNC_VOLUME_DB = -8.0

const SYNC_VOLUME_DB = 0.0

func \_ready() -\> void:

\_music_bus_idx = AudioServer.get_bus_index(\'Music\')

GameState.state_changed.connect(\_on_state_changed)

func \_on_state_changed(state: GameState.State) -\> void:

var target_db = DESYNC_VOLUME_DB if state == GameState.State.DESYNC else SYNC_VOLUME_DB

var tween = create_tween()

tween.tween_method(

func(v): AudioServer.set_bus_volume_db(\_music_bus_idx, v),

AudioServer.get_bus_volume_db(\_music_bus_idx),

target_db, 0.3

)

func play_sfx(sfx_path: String) -\> void:

var player = AudioStreamPlayer.new()

player.stream = load(sfx_path)

player.bus = \'SFX\'

add_child(player)

player.play()

player.finished.connect(player.queue_free)

**S-8.4 Outline Shader --- Etkileşimli Objeler**

\# res://assets/shaders/outline.gdshader

shader_type canvas_item;

uniform float outline_width: hint_range(0.0, 4.0) = 1.5;

uniform vec4 outline_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {

vec4 col = texture(TEXTURE, UV);

if (col.a \> 0.1) { COLOR = col; return; }

vec2 size = outline_width / vec2(textureSize(TEXTURE, 0));

float alpha = texture(TEXTURE, UV + vec2(size.x, 0)).a

\+ texture(TEXTURE, UV - vec2(size.x, 0)).a

\+ texture(TEXTURE, UV + vec2(0, size.y)).a

\+ texture(TEXTURE, UV - vec2(0, size.y)).a;

COLOR = outline_color \* clamp(alpha, 0.0, 1.0);

}

**S-8.5 Test Kontrol Listesi**

- Screen shake ölüm ve büyük çarpışmalarda aktif ✓

- Gölge iz parçacıkları görünüyor ✓

- DESYNC\'te müzik volume ducking çalışıyor ✓

- Outline shader baskı kapılarında görünüyor ✓

- Tüm ses efektleri WebGL\'de çalışıyor (Low/High-pass filtre YOK) ✓

**Sprint 9 --- Test, Kalibrasyon ve Submit (\~4 saat)**

***Tamamlanma Kriteri: Başka biri oyunu baştan sona bitirdi. Build hatasız export edildi.***

**S-9.1 Kalibrasyon Kontrol Listesi**

**Hitbox Kalibrasyonu**

- Karakter collision box: sprite\'ın görsel sınırlarının %50\'si

- Gölge collision box: karakter collision box\'ının %50\'si

- Baskı kapısı trigger: gölgenin tam ortasına gelince tetiklenecek büyüklükte

**Coyote ve Buffer Değerleri**

- COYOTE_TIME = 0.12 --- çok büyük hissettirirse 0.08\'e düşür

- JUMP_BUFFER = 0.10 --- çok affedici hissettirirse 0.06\'ya düşür

**DESYNC Dengesi**

- Gölge 1 sn gecikmesi: oyuncu bunu \'kasıtlı araç\' olarak kullanabiliyor mu?

- Enerji barı: 4 sn DESYNC yeterli mi, çok mu? --- playtest\'e göre ayarla

- Kendi gölgene çarpma: 2 frame grace yeterli mi? Haksız hissettiriyor mu?

**S-9.2 Godot 4 Web Build Adımları**

8.  Project \> Export \> Add: Web (HTML5)

9.  Export Template indir (Godot 4 Web export template)

10. Export path: res://build/echo.html

11. \'Dedicated Server\' kapalı olsun

12. Audio: \'Mix Rate\' 44100 olsun

13. Test: lokal olarak python -m http.server 8000 ile aç (SharedArrayBuffer gerekiyor)

14. itch.io\'ya yükle: \'This file will be played in the browser\' seçili olsun

***Son 1 saat tampon: WebGL build hataları burada çıkar. Özellikle SharedArrayBuffer CORS hatası sık görülür. itch.io\'da \'SharedArrayBuffer Support\' aktif etmeyi unutma.***

**S-9.3 Playtest Protokolü**

Başka biri (geliştirici olmayan) aşağıdaki soruları aklında tutarak oynasın:

- Level 1\'de gölgenin gecikmeli olduğunu UI olmadan anlıyor mu?

- Level 2\'de baskı kapısı mantığını çözüyor mu?

- DESYNC gecikmesini bir araç olarak kullanıyor mu yoksa sadece kurtulmaya mı çalışıyor?

- Kendi gölgesine çarpınca \'haksızlık\' hissediyor mu?

- Boss Faz 3\'ü anlamlı buluyor mu?

**S-9.4 Submit Kontrol Listesi**

- itch.io sayfası: başlık, kısa açıklama, kontroller

- Minimum 1 gameplay GIF (gölge gecikmesini gösteren)

- 2 screenshot (SYNC modu, DESYNC modu karşılaştırması)

- DESYNC jam sayfasına submission link eklendi

**Ek A --- Sık Karşılaşılan Godot 4 Sorunları**

|                                         |                             |                                                                                       |
|-----------------------------------------|-----------------------------|---------------------------------------------------------------------------------------|
| **Sorun**                               | **Sebep**                   | **Çözüm**                                                                             |
| Gölge titriyor                          | Buffer index hesabı         | BUFFER_DESYNC sabitini max boyut olarak kullan, \_write_idx her zaman bu modda dönsün |
| move_and_slide platform\'dan kaydırıyor | Collision normal            | floor_max_angle = 0.785 rad (45°)                                                     |
| Area2D sinyal çalışmıyor                | Layer/mask uyumsuz          | collision_layer ve collision_mask bit değerlerini Project Settings\'te kontrol et     |
| Shader parametresi çalışmıyor           | Material paylaşımı          | Material\'i unique yap: sağ tık \> Make Unique                                        |
| NavigationAgent2D yol bulamıyor         | Navigation Region eksik     | Sahneye NavigationRegion2D ekle, bake nav mesh                                        |
| WebGL\'de ses çıkmıyor                  | Autoplay policy             | İlk kullanıcı etkileşiminden sonra ses başlat (buton click)                           |
| Engine.time_scale animasyonu bozuyor    | AnimationPlayer etkileniyor | AnimationPlayer.process_callback = PHYSICS kullan                                     |
| Gölge oyuncuyu geçiyor                  | Buffer çok küçük            | BUFFER_SYNC\'i 60\'a sabitle, FPS düşükse delta bazlı interpolasyon ekle              |

**Ek B --- Performans ve Godot 4 Best Practices**

- Ring buffer için Array.resize() yerine başlangıçta sabit boyut tahsis et --- bellek parçalanmasını önler.

- get_tree().get_first_node_in_group() her frame çağrılmasın. \_ready()\'de referansı cache\'le.

- Shader parametresi güncellemesi: tween kullan, her frame set_shader_parameter() çağırma.

- Parçacıklar one_shot=true olsun ve finished sinyaliyle queue_free() çağrılsın.

- NavigationAgent2D: her frame target_position atama --- sadece hedef değişince güncelle.

- TileMap Physics Layer: Layer 3 (world) olarak ayarlanmalı, aksi halde karakter düşer.

- Autoload boyutu minimal tut --- sadece global state ve audio. Level logic sahnede kalmalı.

*ECHO · Sprint Teknik Dökümanı · Godot 4.6.1 · v1.0*
