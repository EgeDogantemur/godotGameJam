**ECHO**

Game Design Document

DESYNC Game Jam · 48 Saat · 2D Action-Puzzle Platformer · v1.0

*\"Gölgen senden 1 saniye geride. Bu gecikme senin zayıflığın değil --- silahın.\"*

**1. Oyun Genel Bakışı**

**1.1 Fikir Seçimi ve Gerekçesi**

Bu GDD, üç kaynaktan gelen en güçlü unsurları tek bir core verb etrafında birleştirerek oluşturulmuştur:

- Fikirler.pdf Fikir 6: Oyuncunun gördüğü ile oynadığı zamansal olarak senkronize değil.

- Fikirler.pdf Fikir 3: Karakterin görsel bozulması mekanikle örtüşüyor, senkronize alet ile düzeltiliyor.

- Teknik Döküman §5 --- Temporal Shadow Desync: Gölgenin karakteri 1--2 saniye gecikmeli takip etmesi bulmaca yapısının temeli.

***Seçilmeyen fikirler neden dışarıda? Fikir 1a (iki karakter sistemi) ve Fikir 4 (çoklu ekran yönetimi) 48 saatlik scope\'u aşar. Bu GDD tek karakter, tek viewport, tek core verb üzerine kuruludur.***

**1.2 Oyun Özeti**

ECHO, 2D action-puzzle platformer türünde bir oyundur. Oyuncunun fiziksel formu gerçek zamanlı hareket ederken, gölgesi aynı hareketleri tam 1 saniye gecikmeli tekrarlar. Bu gecikme --- \'desync\' --- hem oyunun en büyük engeli hem de tek silahıdır.

**1.3 Tek Cümlelik Çekirdek**

***Gölgen seni 1 saniye geride takip ediyor; bunu kasıtlı kullanarak dünyayı manipüle et --- ama kendi gölgene çarparsan ölürsün.***

**1.4 Hızlı Referans**

|            |                                                      |
|------------|------------------------------------------------------|
| **Alan**   | **Detay**                                            |
| Oyun Adı   | ECHO                                                 |
| Tür        | 2D Action-Puzzle Platformer                          |
| Tema       | DESYNC                                               |
| Core Verb  | Gecikmeli gölgeyle senkronize olmak / kasıtlı bozmak |
| Engine     | Unity 2D (C#) --- WebGL build hedefi                 |
| Jam Süresi | 48 saat · Feature Lock: Saat 24                      |
| Platform   | PC + Web (itch.io)                                   |
| Ekip       | 2--3 kişi (Programmer · Artist · Audio/Generalist)   |
| Süre       | 10--15 dakika · 6 bölüm + boss                       |

**2. Core Mekanikler**

**2.1 Gölge Gecikme Sistemi (Temporal Echo)**

Oyunun tüm mekanik derinliği şu basit mimari karardan doğar: her karede oyuncunun pozisyonu bir ring buffer\'a kaydedilir. Gölge, bu buffer\'dan tam 60 frame (1 saniye / 60 FPS) önceki pozisyonu okur ve oraya render edilir.

- Gölge oyuncunun tüm hareketlerini (koşma, zıplama, düşme) 1 sn gecikmeli olarak aynıyla tekrarlar.

- Gölgenin ayrı bir collision layer\'ı vardır (Layer 2). Sadece belirli \'DESYNC-aktif\' engeller bu layer\'ı algılar.

- Oyuncu gölgesiyle aynı tile\'a girerse: ölüm. Bu, oyunun tek \'gotcha\' mekanizmasıdır.

**2.2 DESYNC Toggle**

Varsayılan gecikme 1 saniyedir. DESYNC modunda oyuncu bu gecikmeyi 3 saniyeye uzatır --- bu, daha büyük kapılar açar, gölgeyi daha uzun süre yem olarak kullanır, ama enerji tüketir ve ölüm riskini artırır.

- Kontrol: \[Space\] basılı tut → DESYNC aktif (gecikme 1s → 3s)

- Enerji barı: maks 4 saniye DESYNC. Enerji biterken kırmızı pulse, tam bitince zorla SYNC.

- SYNC\'e dönüşte 0.2 saniye \'resync flash\' --- hem görsel onay hem de öğrenme sinyali.

- Enerji dolumu: SYNC modunda saniyede %25, gölge bir \'sync point\' üzerine geçince +%50 anlık.

**2.3 SYNC / DESYNC Karşılaştırma Tablosu**

|                |                                |                                           |
|----------------|--------------------------------|-------------------------------------------|
| **Parametre**  | **SYNC --- Gölge Üstüste**     | **DESYNC --- Gölge Geride**               |
| Baskı Kapıları | Gölge basmaz → kapı kapalı     | Gölge 1s sonra basar → kapı geçici açılır |
| Işık Geçişleri | Işık fiziksel formu takip eder | Gölge ışıkta görünmez → görünmez platform |
| Düşmanlar      | Fiziksel forma saldırır        | Gölgeyi takip eder → tuzak veya yem       |
| Görsel         | Karakter temiz, gölge altında  | Chromatic aberration + scan-line glitch   |
| Ses            | Müzik temiz, senkron           | Low-fi distortion, reverb kuyruğu         |
| Enerji         | Dolum --- pasif rejenerasyon   | Tüketim --- maks 4 saniye ayrışma         |

**2.4 Kindness in Code --- Celeste Felsefesi**

Oyun zorlu ama haksız hissettirmemeli. Aşağıdaki parametreler oyun psikolojisine göre kalibre edilmiştir:

- Coyote Time: Oyuncu zeminden düştükten 0.12 saniye sonra hâlâ zıplayabilir.

- Input Buffer: Zıplama ve DESYNC toggle 0.1 saniye önceden basılabilir.

- Adil Hitbox: Hem fiziksel form hem gölge için collision box, görselin %50\'si kadardır (Teknik Döküman §3).

- Gölge Çarpışma Grace: Gölge oyuncuyla aynı kareye tam girdiği anda değil, 2 frame içinde kalmaya devam ederse ölüm tetiklenir.

**2.5 Görsel Dil --- İki Mod Ayrımı**

**SYNC Modu**

- Karakter: temiz, parlak, keskin kenarlı silüet

- Gölge: hafif saydam, karakter altında yumuşak forma

- Renk paleti: soğuk mavi-teal dominant

- Ses: temiz, senkron ritim

**DESYNC Modu**

- Karakter etrafında chromatic aberration (kırmızı/mavi fraksiyon ayrışması)

- Gölge artan opacity ile belirginleşir, kırmızımsı glow

- Scan-line filtresi --- dünya \'bozuk sinyal\' görünümü alır

- Ses: Volume Ducking yöntemiyle distortion efekti (WebGL uyumlu --- teknik döküman §4)

Prodüksiyon notu: Tüm DESYNC görsel efektleri tek bir shader parametresiyle (float \_DesyncAmount) kontrol edilir. Ayrı asset seti yok --- sadece shader lerp.

**3. Level Tasarımı**

**3.1 Genel Yapı**

Dökümanların \'one core interaction\' prensibine uygun olarak oyun, tek mekaniği katman katman öğreten 6 seviyeden oluşur. Her seviye yeni bir \'twist\' ekler ama yeni bir kontrol şeması getirmez.

|         |                |                                               |                                        |
|---------|----------------|-----------------------------------------------|----------------------------------------|
| **Lvl** | **İsim**       | **Öğretilen Mekanik**                         | **DESYNC Kullanımı**                   |
| 1       | The Signal     | Gölge hareketi gözlemleme, gecikmeyi hissetme | Yok --- tanışma                        |
| 2       | Pressure       | Gölge ile baskı kapısı açma                   | Kısa (\~1 sn), enerji bol              |
| 3       | The Blind Spot | Işık + görünmez platform keşfi                | Orta, yön kontrolü kritik              |
| 4       | Decoy          | Düşmanı gölgeyle kandırma                     | Aktif --- gölge yem olarak kullanılır  |
| 5       | Phase Corridor | Tüm mekanikler zincir halinde                 | Hassas zamanlama + combo               |
| BOSS    | The Conductor  | Patron kendi DESYNC\'ini üretiyor             | Roles Reversed --- oyuncu SYNC kalmalı |

**3.2 Level 1 --- The Signal (Diegetic Tutorial)**

İlk seviye, oyuncuya hiç UI metni göstermeden gölge gecikmesini öğretir. Tasarım prensibi: \'göster, söyleme\' (Teknik Döküman §3 --- Boş Oda Deneyi).

1.  İlk oda: geniş, boş, flat zemin. Oyuncu ilerlediğinde gölgesini fark eder.

2.  İkinci oda: tek bir engel, geçmek için sola git-dur-gölge geçsin bekle. Çözüm yolu tek.

3.  Üçüncü oda: ilk baskı kapısı. Gölge kapı üzerinden geçince kapı açılır, oyuncu senkronda girer.

Bu oda geçilmeden DESYNC butonu aktif olmaz --- oyuncu önce SYNC\'i kavramak zorundadır.

**3.3 Level 4 --- Decoy (Stratejik Doruk)**

Bu seviye, gecikmeli gölgenin pasif bir engel değil aktif bir araç olduğunu öğreten \'epiphany level\'dır. Süreç:

4.  Oyuncu bir odaya girer, çıkış kilitli ve düşman kapının önünde.

5.  DESYNC aktif edince gölge sahaya geçikmeyle girer --- düşman gölgeye yönelir.

6.  Oyuncu fiziksel formla farklı yoldan çıkışa ulaşır, gölge yem görevi görür.

Teknik not: Düşman AI sadece seek/flee --- hedef seçimi collision layer filtresiyle (gölge öncelikli) yapılır. Karmaşık davranış ağacı yok.

**3.4 Boss --- The Conductor**

Boss arena oyunun tüm mekaniklerini sentezer. \'The Conductor\' adlı boss, kendi DESYNC\'ini üretir --- gölgesi karakter yerine oyuncuya saldırır.

- Faz 1: Normal arena. Oyuncu standart SYNC/DESYNC döngüsüyle ilerler.

- Faz 2: Boss gölgesini 3 saniyeye uzatır --- tüm oda DESYNC kirliliğiyle dolar.

- Faz 3 (Roles Reversed): Boss oyuncunun gölgesini kontrol eder. Oyuncu SYNC\'te kalmak zorundadır.

Game Jam Blueprint \'GMTK Roles Reversed\' analizinden doğrudan ilham: son fazda mekanik yük tamamen ters döner, oyuncu daha önce kullandığı avantajın kurbanı olur.

**4. Teknik Mimari**

**4.1 Gölge Ring Buffer**

Tüm temporal desync mekaniğinin kalbindeki veri yapısı:

Queue\<Vector2\> positionBuffer = new Queue\<Vector2\>(); // 60 frame @ 60fps

// Her FixedUpdate\'te: buffer.Enqueue(transform.position);

// Buffer.Count \> bufferSize ise: shadowPos = buffer.Dequeue();

- Buffer boyutu: 60 (1 sn SYNC) ile 180 (3 sn DESYNC) arasında lerp edilir.

- Gölge ayrı bir GameObject --- fiziksel formun çocuğu değil, sahne köküne bağlı.

- Gölgenin SpriteRenderer\'ı ayrı, renk ve alpha shader parametresiyle yönetilir.

**4.2 Collision Layer Mimarisi**

Teknik dökümanın gölge ayrışması prensibini referans alan katmanlı çarpışma sistemi:

- Layer 1 (Physical): Oyuncu fiziksel formu. Tüm statik engeller bu layerı algılar.

- Layer 2 (Shadow): Gölge. Sadece \'DESYNC-active\' olarak işaretlenen kapılar/triggerlar algılar.

- Layer 3 (Enemy): Düşmanlar. DESYNC modunda gölgeyi (Layer 2) öncelikli hedef alır.

- Self-collision kuralı: Layer 1 + Layer 2 çakışma = ölüm. Sadece 2 frame grace period ile.

**4.3 State Machine**

Karakter davranışının tümü 4-state\'li bir enum üzerinde yönetilir:

|                |                                             |                                       |
|----------------|---------------------------------------------|---------------------------------------|
| **State**      | **Giriş Koşulu**                            | **Çıkış Koşulu**                      |
| SYNC (Normal)  | Başlangıç / DESYNC sona erince              | Hold \[Space\] → DESYNC başlar        |
| DESYNC (Aktif) | \[Space\] basılı tutulur                    | \[Space\] bırakılır veya enerji biter |
| RESYNC (Geçiş) | DESYNC → SYNC geçişinde                     | 0.2 sn flash animasyon → SYNC         |
| DEAD           | Gölge fiziksel forma çarpar (kendi gölgesi) | Checkpoint\'e respawn                 |

**4.4 WebGL Build Uyarıları**

Teknik dökümanın §4 uyarıları doğrultusunda:

- Low-Pass / High-Pass filtre kullanma --- WebGL tarayıcı katmanında hata verir.

- DESYNC ses efekti için Volume Ducking yöntemi: AudioMixer.SetFloat(\"masterVolume\", -8f).

- Reverb ve pitch-shift AudioMixer chain üzerinden --- Web Audio API uyumlu.

- Build öncesi 1 saat tampon: son saat WebGL export ve hata ayıklama için ayrılır (Teknik Döküman §1).

**5. Production Planı**

**5.1 48 Saat Takvimi**

|           |                 |                                                                                              |
|-----------|-----------------|----------------------------------------------------------------------------------------------|
| **Zaman** | **Faz**         | **Teslim Edilen**                                                                            |
| 00--04    | Prototip        | Karakter hareket eder. Gölge 1 sn gecikmeli kopyayı takip eder. Collision çalışıyor.         |
| 04--10    | Core Loop       | DESYNC toggle + enerji çubuğu. Baskı kapısı mekaniği. Lvl 1--2 oynanabilir.                  |
| 10--18    | Content         | Lvl 3--5 tamamlandı. Outline shader. Glitch görsel efekti. Düşman AI (basit seek/flee).      |
| 18--24    | 🔒 FEATURE LOCK | Saat 24\'te tüm yeni mekanik girişi DONDURULUR. Sadece bug, polish, ses.                     |
| 24--36    | Polish          | Screen shake, hit flash, particle. Ses efektleri. Volume ducking (WebGL uyumlu). Boss arena. |
| 36--44    | Test            | Playtest --- başka biri oynasın. Hitbox %50 küçültme. Coyote time kalibrasyonu.              |
| 44--48    | Submit          | WebGL build. 1 saat tampon (build hataları için). itch.io sayfası. GIF + screenshots.        |

**5.2 Ekip Rolleri**

- Programmer: Ring buffer, state machine, collision layer sistemi, shader parametresi

- Artist: Karakter sprite (12 frame), gölge overlay, glitch shader, 2 tileset

- Audio / Generalist: Müzik loop, DESYNC ses zinciri, level design, playtesting

**5.3 MoSCoW Listesi**

Teknik Döküman §1\'in MoSCoW metoduna uygun kapsam yönetimi:

**Must Have**

- Gölge ring buffer ve 1 sn gecikme --- tatmin edici hissettirmeli

- DESYNC toggle + enerji barı

- Baskı kapısı mekaniği

- Level 1--3 tamamlanabilir hâlde

- Ses + beat senkronizasyonu

**Should Have**

- Düşman \'decoy\' mekaniği (Level 4)

- Glitch shader (DESYNC görsel)

- Level 5 ve boss arena

**Could Have**

- Perfect resync animasyonu

- Checkpoint sistem

- Minimal diyalog / atmosfer metni

**Won\'t Have (48 saatte)**

- İkinci oynanabilir karakter (Fikir 1a / 2 --- sonraki proje)

- Çoklu ekran sistemi (Fikir 4 --- sonraki proje)

- Soft-body fizik (Teknik Döküman §2 --- farklı proje için saklı)

**6. Tasarım Prensipleri**

**6.1 Referans Matrisi**

|                   |                                                   |                                        |
|-------------------|---------------------------------------------------|----------------------------------------|
| **Prensip**       | **Uygulama**                                      | **Kaynak**                             |
| Boş Oda Deneyi    | Gölge gecikmesi boş sahnede test edilmeli         | Teknik Döküman §3 + Game Jam Blueprint |
| Diegetic Tutorial | Lvl 1 tamamen SYNC, UI metni yok                  | Celeste Classic analizi                |
| Adil Hitbox       | Gölge ve fiziksel form hitbox\'ı görselin %50\'si | Teknik Döküman §3                      |
| Visual Affordance | Etkileşimli objelere Outline Shader               | Teknik Döküman §3                      |
| Roles Reversed    | Boss fazında oyuncu/düşman mantığı yer değiştirir | GMTK analizi (Game Jam Blueprint)      |
| Kindness in Code  | Coyote Time + Input Buffer her aksiyon için       | Celeste Classic analizi                |

**6.2 Risk Analizi**

|                                               |            |                                                                                                           |
|-----------------------------------------------|------------|-----------------------------------------------------------------------------------------------------------|
| **Risk**                                      | **Seviye** | **Çözüm**                                                                                                 |
| Gölge gecikmesi hissiz / sinir bozucu         | YÜKSEK     | Toy phase zorunlu: boş odada sadece gecikme toggle\'ı test et --- tatmin edici hissettirmeden devam etme. |
| WebGL ses filtresi hatası                     | ORTA       | Teknik döküman uyarısı: Low/High-pass filtre YOK. Volume Ducking yöntemi kullan.                          |
| Gölge kendi gölgesine çarpar --- ölüm hatası  | ORTA       | Ayrı collision layer: fiziksel form layer 1, gölge layer 2. Sadece belirli engeller layer 2\'yi algılar.  |
| Scope creep --- ikinci karakter ekleme isteği | YÜKSEK     | Fikirler.pdf Fikir 1 cazip ama 48 saate sığmaz. Feature lock saat 24\'te mutlak.                          |
| Soft-body fizik instabilite                   | DÜŞÜK      | Bu GDD\'de soft-body YOK. Teknik dökümanın soft-body bölümü sonraki proje için saklı.                     |
| Donanım ısınması                              | DÜŞÜK      | Teknik döküman hatırlatması: GitHub repo zorunlu, harici soğutma hazırla.                                 |

**7. Post-Jam Potansiyeli**

Bu GDD kasıtlı olarak sınırlı tutulmuştur. Jam versiyonu kanıtlanırsa genişleme yolları:

- Fikirler.pdf Fikir 1a entegrasyonu: İkinci karakter eklenerek asimetrik co-op modu. Teknik Döküman\'ın iki karakter anlatı altyapısı bu aşamada devreye alınır.

- Fikirler.pdf Fikir 4: Çoklu ekran / viewport sistemi. Ring buffer mimarisi buna hazır --- sadece ikinci kamera ve UI katmanı gerekir.

- Teknik Döküman §2 --- Visual-Physics Desync: Gölgenin mesh renderer\'ından fizik collider\'ını ayırma. Jam versiyonunda gerek yok, ama post-jam boss tasarımını zenginleştirir.

- Fikirler.pdf Fikir 5: Mekanik dinamikleşme (her N zıplamada double jump) --- progression sistemi olarak eklenebilir.

**8. Kaynak ve İlham Matrisi**

Bu GDD üç birincil kaynağın sentezinden oluşmuştur:

- Game Jam Success Analysis Blueprint --- Celeste Classic, Superhot, Baba Is You, Titan Souls, GMTK analizleri

- Yapay Zeka Destekli Game Jam Rehberi --- Temporal Shadow Desync, Collision Layer mimarisi, WebGL kısıtlamaları, MoSCoW metodu

- Fikirler.pdf --- Fikir 3 (görsel bozulma/düzeltme), Fikir 6 (zamansal desync), Fikir 4 ve 1a (post-jam yol haritası)

*ECHO · Game Design Document · v1.0 · DESYNC Game Jam*
