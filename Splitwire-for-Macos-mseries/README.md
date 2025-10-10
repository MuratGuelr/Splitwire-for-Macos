# 🚀 SplitWire for macOS

> **Discord'u macOS'te sadece kendi proxy'si üzerinden çalıştıran, sistemin geri kalanını hiç etkilemeyen akıllı bir araç.**

[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-blue.svg)](https://www.apple.com/macos)
[![Architecture](https://img.shields.io/badge/Architecture-Intel%20%7C%20Apple%20Silicon-green.svg)](https://www.apple.com/mac)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Nasıl Çalışır](#-nasıl-çalışır)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Hızlı Kurulum](#-hızlı-kurulum)
- [Kullanım](#-kullanım)
- [Kaldırma](#-kaldırma)
- [Sorun Giderme](#-sorun-giderme)
- [SSS](#-sss)
- [Destek](#-destek)

---

## ✨ Özellikler

### 🎯 Temel Özellikler

- **Seçici Yönlendirme**: Sadece Discord trafiğini proxy'den geçirir
- **Sistem Bütünlüğü**: Safari, Chrome, Zoom ve diğer uygulamalar normal çalışır
- **Otomatik Başlatma**: Mac açıldığında servisler otomatik devreye girer
- **Kolay Yönetim**: Masaüstü kontrol paneli ile tek tıkla başlat/durdur
- **Temiz Kaldırma**: Tek komutla tüm bileşenler silinebilir

### 🛡️ Güvenlik & Performans

- **Kaynak Sınırlaması**: %60 CPU ve 256 MB RAM limiti
- **Otomatik Log Yönetimi**: 10 MB'ı geçen loglar otomatik sıkıştırılır
- **Akıllı Port Yönetimi**: 8080 doluysa 8081-8099 arası otomatik port seçimi
- **Hata Toleransı**: Proxy kapanırsa 3 saniye içinde yeniden başlatılır

### 📊 Kullanıcı Dostu

- Görsel kontrol paneli (GUI)
- Detaylı log görüntüleyici
- Canlı hata izleme
- Debug sistem bilgileri toplama aracı

---

## 🔧 Nasıl Çalışır?

SplitWire, macOS'in **LaunchAgents** sistemini kullanarak iki servis çalıştırır:

### 1️⃣ **spoofdpi Proxy Servisi**

```
~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist
```

- **spoofdpi** aracını arka planda sürekli çalıştırır
- Varsayılan olarak `127.0.0.1:8080` adresinde dinler
- Kapanırsa otomatik yeniden başlatılır
- Log dosyaları: `~/Library/Logs/ConsolAktifSplitWireLog/`

### 2️⃣ **Discord Başlatıcı Servisi**

```
~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist
```

- Discord'u proxy parametresi ile başlatır
- Port hazır olana kadar bekler (45 saniye timeout)
- `--proxy-server="http://127.0.0.1:8080"` parametresi ekler

### 📁 Kurulum Dosyaları

| Dosya / Klasör                                       | Açıklama                     |
| ---------------------------------------------------- | ---------------------------- |
| `~/Library/Application Support/Consolaktif-Discord/` | Script'ler ve kontrol paneli |
| `~/Library/LaunchAgents/*.plist`                     | LaunchAgent tanımları        |
| `~/Library/Logs/ConsolAktifSplitWireLog/`            | Çalışma ve hata logları      |
| `~/Desktop/SplitWire Kontrol`                        | Kontrol paneli kısayolu      |
| `~/Desktop/SplitWire Loglar`                         | Log görüntüleyici kısayolu   |

---

## 💻 Sistem Gereksinimleri

### Minimum Gereksinimler

- **İşletim Sistemi**: macOS 12 (Monterey) veya üstü
- **Mimari**: Intel (x86_64) veya Apple Silicon (M1/M2/M3/M4)
- **Discord**: `/Applications/Discord.app` içinde kurulu olmalı
- **Homebrew**: Otomatik kurulur (yoksa)

### Otomatik Kurulan Bağımlılıklar

- Homebrew (yoksa)
- spoofdpi (Homebrew üzerinden)
- Xcode Command Line Tools (M serisi için, yoksa)

---

## 🚀 Hızlı Kurulum

### Adım 1: Projeyi İndirin

```bash
# GitHub'dan indirin ve klasöre girin
cd ~/Downloads/SplitWire-for-Macos-main
```

### Adım 2: Discord Kontrolü ve Kurulumu

> ⚠️ **ÖNEMLİ:** Discord kurulu değilse önce onu kurmalısınız!

#### Discord Kurulu mu Kontrol Edin:

```bash
# Discord'un varlığını kontrol et
ls -la /Applications/Discord.app
```

#### 🟢 **Discord Yoksa - Apple Silicon (M Serisi) için:**

```bash
cd Splitwire-for-Macos-mseries
chmod +x *.sh
./install-discord.sh
```

> 💡 **İpucu:** `install-discord.sh` scripti Discord'u Homebrew üzerinden `/Applications` klasörüne otomatik kurar ve doğrular.

### Adım 3: SplitWire Kurulumu

#### 🟢 **Apple Silicon (M Serisi) için:**

```bash
cd Splitwire-for-Macos-mseries
chmod +x *.sh
./install.sh
```

> **Not**: Kurulum sırasında şifreniz istenebilir (Homebrew kurulumu için).

---

## 🎮 Kullanım

### Kontrol Paneli ile Yönetim

Kurulum tamamlandığında masaüstünüzde **"SplitWire Kontrol"** kısayolu oluşur.

**Başlatma:**

1. "SplitWire Kontrol" kısayoluna çift tıklayın
2. Açılan pencerede **"Başlat"** düğmesine basın
3. Discord otomatik olarak proxy ile açılacak

**Durdurma:**

1. "SplitWire Kontrol" kısayoluna çift tıklayın
2. **"Durdur"** düğmesine basın
3. Servisler durdurulacak ve Discord kapanacak

### Terminal ile Yönetim

```bash
# Servis durumunu kontrol et
~/Library/Application\ Support/Consolaktif-Discord/control.sh status

# Servisleri başlat
~/Library/Application\ Support/Consolaktif-Discord/control.sh start

# Servisleri durdur
~/Library/Application\ Support/Consolaktif-Discord/control.sh stop
```

### Log Görüntüleme

#### GUI ile (Önerilen):

```bash
# Masaüstünden "SplitWire Loglar" kısayoluna çift tıklayın
```

Seçenekler:

- **Finder'da Aç**: Log klasörünü Finder'da açar
- **Son Hatalar**: Son 200 hata satırını TextEdit'te gösterir
- **Canlı Hata Logları**: Canlı log akışını Terminal'de izler

#### Terminal ile:

```bash
# Hata loglarını canlı izle
tail -f ~/Library/Logs/ConsolAktifSplitWireLog/net.consolaktif.discord.spoofdpi.err.log

# Çıktı loglarını canlı izle
tail -f ~/Library/Logs/ConsolAktifSplitWireLog/net.consolaktif.discord.spoofdpi.out.log

# Son 50 satırı görüntüle
tail -n 50 ~/Library/Logs/ConsolAktifSplitWireLog/net.consolaktif.discord.spoofdpi.err.log
```

---

## 🗑️ Kaldırma

### Hızlı Kaldırma

#### Apple Silicon:

```bash
cd ~/Downloads/SplitWire-for-Macos-main/Splitwire-for-Macos-mseries
./uninstall.sh
```

### Kaldırma Seçenekleri

Kaldırma sırasında size sorulacak:

1. **Destek dosyaları silinsin mi?**

   - Evet: Tüm loglar ve script'ler silinir
   - Hayır: Sadece servisler kaldırılır

2. **spoofdpi paketi kaldırılsın mı?**
   - Evet: Homebrew'dan spoofdpi silinir
   - Hayır: spoofdpi sistemde kalır

### Tam Otomatik Kaldırma

```bash
# Tüm sorulara "evet" cevabı ver
./uninstall.sh --yes --full
```

### Discord'u Kaldırma (Opsiyonel)

#### Apple Silicon:

```bash
./remove-discord.sh
```

---

## 🔍 Sorun Giderme

### Debug Bilgileri Toplama

Sorun yaşıyorsanız önce debug bilgilerini toplayın:

```bash
~/Library/Application\ Support/Consolaktif-Discord/debug-system.sh
```

Bu komut şunları kontrol eder:

- ✅ Mac mimari ve işletim sistemi bilgileri
- ✅ Homebrew kurulumu ve konumu
- ✅ spoofdpi binary durumu
- ✅ Discord kurulumu
- ✅ LaunchAgent dosyaları
- ✅ Servis durumları
- ✅ Port kullanımı
- ✅ Log dosyaları

### Yaygın Sorunlar ve Çözümleri

#### 🔴 **Proxy başlamıyor**

```bash
# spoofdpi'yi yeniden kur
brew reinstall spoofdpi

# Servisi yeniden başlat
launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi
```

#### 🔴 **Port 8080 kullanımda**

Port dosyasını düzenleyin:

```bash
nano ~/Library/Application\ Support/Consolaktif-Discord/discord-spoofdpi.sh
# LISTEN_PORT=8080 satırını değiştirin (örn: 8081)
```

#### 🔴 **Discord açılmıyor**

```bash
# Mevcut Discord'u kapat
pkill -x Discord

# Servisleri yeniden yükle
launchctl unload ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist
launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist
```

#### 🔴 **Homebrew bulunamıyor (M serisi)**

```bash
# Homebrew'u PATH'e ekle
eval "$(/opt/homebrew/bin/brew shellenv)"

# Terminal'i kapatıp tekrar açın
```

### Manuel Kontroller

| İşlem                      | Komut                                                                  |
| -------------------------- | ---------------------------------------------------------------------- |
| Servisleri listele         | `launchctl list \| grep net.consolaktif.discord`                       |
| spoofdpi'yi yeniden başlat | `launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi` |
| Discord'u yeniden başlat   | `launchctl kickstart gui/$(id -u)/net.consolaktif.discord.launcher`    |
| Proxy'yi geçici durdur     | `launchctl stop net.consolaktif.discord.spoofdpi`                      |
| Port kontrolü              | `lsof -i :8080`                                                        |

---

## ❓ SSS

<details>
<summary><strong>Discord'u Dock'tan açarsam yine proxy ile mi çalışır?</strong></summary>

✅ **Evet!** Launcher servisi, Discord'un her açılışında otomatik olarak `--proxy-server` parametresini ekler. Dock, Spotlight veya herhangi bir yöntemle açsanız proxy aktif olur.

</details>

<details>
<summary><strong>Başka uygulamaları da proxy'den geçirebilir miyim?</strong></summary>

⚠️ Bu kurulum özellikle Discord için optimize edilmiştir. Ancak `launcher.plist` dosyasını kopyalayıp düzenleyerek diğer uygulamalar için de kullanabilirsiniz:

```bash
# Örnek: Slack için
cp ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist \
   ~/Library/LaunchAgents/net.consolaktif.slack.launcher.plist

# Dosyayı düzenleyip Discord yerine Slack yazın
```

</details>

<details>
<summary><strong>spoofdpi kapanırsa ne olur?</strong></summary>

🔄 LaunchAgent `KeepAlive` özelliği sayesinde 3 saniye içinde otomatik yeniden başlatılır. Sistem her zaman proxy'nin aktif olmasını sağlar.

</details>

<details>
<summary><strong>macOS güncellemesi sonrası bozulur mu?</strong></summary>

✅ **Genellikle hayır.** LaunchAgents kullanıcı seviyesinde çalıştığı için sistem güncellemeleri etkilemez. Sorun yaşarsanız `./install.sh` komutunu tekrar çalıştırmanız yeterli.

</details>

<details>
<summary><strong>M1/M2/M3/M4 Mac'lerde çalışıyor mu?</strong></summary>

✅ **Evet!** Tüm Apple Silicon (M1/M2/M3/M4) ve Intel Mac'lerde test edilmiştir. M serisi için özel olarak optimize edilmiş versiyon mevcuttur.

</details>

<details>
<summary><strong>Homebrew zaten kurulu, tekrar kurar mı?</strong></summary>

❌ **Hayır.** Kurulum scripti önce Homebrew'un varlığını kontrol eder. Kuruluysa hiç dokunmaz.

</details>

<details>
<summary><strong>Discord'u nasıl tamamen normal haline döndürürüm?</strong></summary>

Servisleri durdurun:

```bash
~/Library/Application\ Support/Consolaktif-Discord/control.sh stop
```

veya masaüstündeki "SplitWire Kontrol" ile "Durdur" butonuna basın.

</details>

<details>
<summary><strong>Loglar çok yer kaplıyor, temizleyebilir miyim?</strong></summary>

✅ **Evet!**

- Masaüstünden "SplitWire Loglar" → "Logları Temizle"
- veya manuel: `rm -f ~/Library/Logs/ConsolAktifSplitWireLog/*`

Log rotation özelliği sayesinde 10 MB üstü loglar otomatik sıkıştırılır.

</details>

<details>
<summary><strong>Port numarasını nasıl değiştirebilirim?</strong></summary>

```bash
# Script dosyasını düzenle
nano ~/Library/Application\ Support/Consolaktif-Discord/discord-spoofdpi.sh

# LISTEN_PORT=8080 satırını değiştir (örn: LISTEN_PORT=8081)

# Servisi yeniden başlat
launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi
```

</details>

<details>
<summary><strong>Discord güncellenirse ne olur?</strong></summary>

✅ Hiçbir şey! SplitWire Discord'un sistem dosyalarına dokunmaz, sadece başlatma parametrelerini değiştirir. Güncellemeler normal şekilde çalışır.

</details>

---

## 🎯 Performans & Dayanıklılık

### Kaynak Yönetimi

- **CPU Sınırı**: %60 (sistem kitlenmesini önler)
- **RAM Sınırı**: 256 MB
- **Otomatik Yeniden Başlatma**: 3 saniye içinde

### Log Yönetimi

- **Otomatik Rotasyon**: 10 MB üstü loglar gzip ile sıkıştırılır
- **Uyarı Sistemi**: Toplam 50 MB geçerse bildirim gönderilir
- **Kolay Temizlik**: GUI veya tek komutla tüm loglar temizlenebilir

### Bağlantı Güvenilirliği

- **Port Bekleme**: Discord başlamadan önce 45 saniye port kontrolü
- **Akıllı Port Seçimi**: 8080-8099 arası ilk boş port otomatik seçilir
- **Graceful Shutdown**: Kaldırma sırasında Discord düzgünce kapatılır

---

## 💖 Destek

### Bağış ve Sponsorluk

Bu proje tamamen ücretsizdir ve açık kaynaklıdır. Çalışmalarımı desteklemek isterseniz:

**GitHub Sponsor:**

[![Sponsor](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/MuratGuelr)

**Patreon:**

[![Patreon](https://img.shields.io/badge/MuratGuelr-purple?logo=patreon&label=Patreon)](https://www.patreon.com/posts/splitwire-for-v1-140359525)

### Projeye Katkı

⭐ **GitHub'da yıldız bırakın!** Bu projenin daha fazla kişiye ulaşmasına yardımcı olur.

🐛 **Hata bildirin:** [Issues](https://github.com/MuratGuelr/SplitWire-for-macOS/issues)

💡 **Öneri gönderin:** [Discussions](https://github.com/MuratGuelr/SplitWire-for-macOS/discussions)

---

## 📄 Lisans

```
Copyright © 2025 ConsolAktif

MIT License ile lisanslanmıştır.
Detaylar için LICENSE dosyasına bakın.
```

---

## ⚖️ Sorumluluk Reddi

> [!IMPORTANT] > **Bu yazılım eğitim amaçlı oluşturulmuştur.**

- ✅ Kodlama eğitimi ve kişisel kullanım için tasarlanmıştır
- ❌ Ticari kullanım için uygun değildir
- ⚠️ Geliştirici, kullanımdan doğabilecek zararlardan sorumlu değildir
- 📚 Kullanıcılar bu yazılımı kendi sorumlulukları altında kullanırlar
- 🔍 Discord'un seçilme sebebi, DPI kısıtlaması olan bir uygulama üzerinde test edilmesi gerekliliğidir
- ⚖️ Yasal düzenlemelere uygun kullanım kullanıcının sorumluluğundadır

**Yasal Uyarı:** Bu programın kullanımından doğan her türlü yasal sorumluluk kullanıcıya aittir. Uygulama yalnızca eğitim ve araştırma amaçları ile geliştirilmiştir.

---

<div align="center">

**🚀 Artık Discord her açıldığında otomatik olarak proxy üzerinden çalışacak!**

Made with ❤️ by [ConsolAktif](https://github.com/MuratGuelr)

</div>
