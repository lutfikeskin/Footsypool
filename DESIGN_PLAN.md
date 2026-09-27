# Footsypool — Roguelike Geliştirme Planı

Bu belge, mevcut koddaki sorunların tespiti ve oyunun roguelike bir yapıya
oturtulması için izlenen planı anlatır. Kod değişiklikleri bu plana göre yapılır.

## 1. Tespit edilen sorunlar (özet)

| # | Sorun | Etki |
|---|-------|------|
| 1 | Yetenekler `total_score` eşiklerine bağlı; puan hızla şiştiği için 4 yeteneğin tamamı 2–5. roundlarda geliyor, sonrası boş | İlerleme hissi yok |
| 2 | Round başı uyarıları (`show_floating_help`) `kicker._process` tarafından bir sonraki karede siliniyor | Oyuncu hangi koşulun aktif olduğunu görmüyor |
| 3 | Safe Pass önizleme çizgisi bir takım arkadaşına değince harcanıyor (`get_hit` her kare çalışıyor) | Yetenek boşa gidiyor |
| 4 | Recovery Drill game over dalında çalışıyor | Yetenek etkisiz |
| 5 | Uzun şut cezası mouse–top mesafesine bakıyor; mouse'u yakın tutan kaçıyor. Ceza rastgele (±9°) | Exploit + zar atma hissi |
| 6 | `turns_without_progress` hiç tetiklenmiyor (`score` 0'a düşmüyor) | Ölü kod |
| 7 | Ghost Shot delip geçmiyor, Wet Grass sadece tween süresi, Overclock kozmetik, Banker gol puanına dokunmuyor, Chain Assist görünmez | Etiket ≠ kod |
| 8 | Ön koşulsuz havuz (silahsız Quick Reload), yığılmayan yetenekler, aşırı güçlü Bank Kill Carry | Anlamsız/dengesiz seçimler |
| 9 | Düşmanlar hiç temizlenmiyor, 3/5/6. roundlarda zorluk sıçramaları üst üste | Saha tıkanıyor |
| 10 | Boss'lar zayıf: Shifter sıradan spawn'dan farksız, Sniper birimi kozmetik, Blind önizleme yüzünden etkisiz, boss sonu ödül yok | Boss hissi yok |

## 2. Yeni run yapısı

```
Stage 1 (R1–R5)   Stage 2 (R6–R10)   Stage 3 (R11–R15)   Stage 4+ (sonsuz)
  Açık saha         Rastgele arena     Rastgele arena      Rastgele arena
  Hava: Açık        Hava: 1 etki       Hava: 1 etki        Hava: 2 etki
  R5: BOSS          R10: BOSS          R15: BOSS           her 5. round BOSS
```

- **Stage** = 5 round. Her stage'in kendi **arena düzeni** (engeller) ve **hava durumu** var.
- Stage başında düşmanlar sahadan çekilir (temiz başlangıç), takım kalır.
- Her stage'in 5. roundu **boss round**. Gol atmak = boss'u yenmek → +1 can ve nadir/epik yetenek seçimi.
- Round 15 sonunda "RUN COMPLETE" mesajı, oyun sonsuz modda devam eder.

## 3. Pace: yetenek ritmi

- Puan eşiği kaldırıldı. **Her 2 roundda bir** (R2, R4, R6 …) 3 seçenekli yetenek ekranı.
- Boss yenilince ekstra seçim (sadece rare/epic havuzu).
- Nadirlik: common / rare / epic. Ağırlıklar stage ilerledikçe nadire kayar.
- Yetenekler seviyeli (`max_level`) ve ön koşullu (`requires`).
- Stage 2'den itibaren seçeneklerden biri **Gamble** kartı olabilir: büyük güç + kalıcı lanet.

## 4. Denge

- **Can sistemi**: 1 yedek canla başlanır (görünür, "LIVES"). Hata = −1 can. 0 canda hata = game over. Maks 3 can.
- **Düşman sayısı hedefe göre**: her round `hedef − mevcut` kadar düşman gelir (en az 1). Öldürmek bir sonraki roundu **hafifletir** (eski kodda cezalandırıyordu).
  - Stage 1: `1 + round_index`, Stage s≥2: `2·s + round_in_stage`, üst sınır 14.
- **Rastgele sapma yok.** Bütün zorluk koşulları deterministik ve önizlemede görünür (rüzgar) ya da bilgiyi kısıtlar (sis). Doğru okuyan oyuncu her zaman kazanabilir.
- Bank Kill Carry → 3+ sekmeden sonra çalışır.
- Kısa şut gizli cezası kaldırıldı; Banker Instinct gol bonusu olarak açık.

## 5. Yetenek havuzu

Kaldırılanlar: Overclock Shot, Recovery Drill, Anchor Boots, Chain Assist, Pressure Shield (→ Extra Life), Single Relocate (→ round başına Playmaker).

| ID | Ad | Nadirlik | Seviye | Etki |
|----|----|----------|--------|------|
| ricochet_master | Ricochet Master | common | 3 | +1 maks sekme |
| scout | Scout | common | 2 | Önizleme +1 sekme, +%25 uzunluk (sisi kırar) |
| magnet_boots | Magnet Boots | common | 2 | Takım yakalama yarıçapı +%20 |
| tough_skin | Tough Skin | common | 1 | Double touch puanı yarılamaz |
| bounty | Bounty Hunter | common | 1 | Öldürme puanı ×2, her öldürme +1 çarpan |
| safe_pass | Safe Pass | common | 1 | Round başına ilk double-touch affedilir (düzeltildi) |
| weapon_system | Weapon System | rare | 1 | Round başına 1 taktik atış |
| quick_reload | Quick Reload | rare | 2 | +1 atış/round (Weapon gerekir) |
| relocate | Playmaker | rare | 1 | Round başına 1 takım arkadaşı taşı |
| ghost_shot | Ghost Shot | rare | 1 | Round başına ilk düşman delinir (gerçek pierce) |
| extra_life | Extra Life | rare | 2 | +1 can |
| wide_goal | Wide Goal | epic | 1 | Kale ağzı genişler |
| bank_kill | Bank Shot Hunter | epic | 1 | 3+ sekme sonrası düşmana çarpınca öldür ve devam et |
| banker | Banker Instinct | epic | 1 | 4+ sekmeli gollerde +%50 gol puanı |
| big_team | Deep Bench | epic | 1 | Her round +1 takım arkadaşı |
| greed | Greed (gamble) | epic | 1 | Gol puanı ×1.6, maks sekme −2 |
| glass_cannon | Glass Cannon (gamble) | epic | 1 | Weapon + 2 atış/round, can tavanı 1 |
| chaos | Chaos Pitch (gamble) | epic | 1 | Round başı +2 çarpan, her round +1 düşman |

## 6. Çeşitlilik: arena ve hava

**Arena düzenleri** (Stage 2'den itibaren, bir önceki tekrar etmez):
- `open` Açık saha
- `pillars` 3 direk — bank açıları değişir
- `bumpers` 2 açılı bar; **bumper** çarpması +1 ekstra çarpan
- `fortress` Kale önünde geniş bar — sadece bank şutu ile gol
- `islands` 4 küçük direk

Engeller `StaticBody2D`; mevcut raycast/reflect sistemi doğrudan çalışıyor.

**Hava** (Stage 2'den itibaren, Stage 4+ iki etki birlikte):
- `wet` Wet Grass: maks sekme −2
- `wind` Wind: her sekmeden sonra top rüzgar yönüne kayar, **önizlemede görünür**
- `fog` Fog: önizleme 2 sekme / kısa

Saha rengi hava durumuna göre tonlanır.

## 7. Boss'lar (rotasyon: Shifter → Keeper → Sniper → Blind)

| Boss | Mekanik | Karşı hamle |
|------|---------|-------------|
| Shifter | Boss birimi her sekmeden sonra yer değiştirir | Az sekmeli şut veya birimi öldür |
| Keeper | Kale ağzı iki direkle daralır, kaleci nişan alırken ağızda konumlanır | Bank şutu, Wide Goal, öldür |
| Sniper | Her şutunda bir takım arkadaşını vurur (min 2 kalır) | Sniper birimini öldür → durur |
| Blind | Nişan alırken sadece sen ve top görünür, önizleme 1 sekme | Scout, sahayı ezberle |

Boss birimi: büyük, kırmızı halkalı elit düşman; öldürülünce bonus puan ve mekanik biter. Gol = boss yenildi → +1 can + rare/epic seçim.

## 8. HUD

Sol üstte kalıcı durum şeridi:
```
LIVES: 2   Stage 2 · Pillars · Wind
Perks: Ricochet II · Weapon · Scout
Boss: Keeper
```
Stage ve boss başlangıçları mevcut `show_help` banner'ı ile duyurulur (tıklayana kadar kalır).

## 9. Simülasyonda bulunan ek buglar

`tests/sim_run.gd` headless olarak tam bir run oynatır (yerleştir → önizleme ile gol yolu ara → şut).
Çalıştırma: `godot --headless --path . -s tests/sim_run.gd`

| Bug | Belirti | Düzeltme |
|-----|---------|----------|
| Spawn yarışı | `next_level` sadece yedek oyuncuyu bekliyordu; rakipler hâlâ koşarken yerleştirme açılıyor, yeni gelen rakip topa daha yakın düşünce pas çalınıyordu | `Dude.moving` + `wait_for_dudes_settled()` |
| Boss spawn sırası | Boss yedek oyuncudan sonra spawn olunca `dudes.back()` boss oluyor, yerleştirme boss'u taşıyordu | Boss ve ekstra oyuncular önce, yedek oyuncu en son |
| Keep-out yanlış merkez | Spawn mesafesi topun *o anki* (kaledeki) konumuna bakıyordu; başlangıç bölgesi korunmuyordu | `spawn_keepout_ok()` topun başlangıç noktasına göre 230 px |
| Effects havuzu | Aynı karede 3+ pop → henüz `add_child` edilmemiş efekt `queue_free` ediliyor → "Moved child is in incorrect state" ve sonrasında segfault | `_Starter/Scripts/effects.gd`: eviction `call_deferred("queue_free")` |

## 10. Uygulama sırası

1. Bug düzeltmeleri (safe pass, pierce, floating help, exploit, ölü kod)
2. `RunData` (yetenek/hava/arena/boss tanımları) — veri odaklı
3. Can sistemi, round ritmi, düşman hedef sayısı
4. Yetenek havuzu ve efektleri
5. Arena engelleri (`Obstacle`) ve hava
6. Boss'lar
7. HUD
8. Headless Godot ile parse/boot doğrulaması
