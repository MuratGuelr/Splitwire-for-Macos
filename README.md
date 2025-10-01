# SplitWire-for-macOS

**Discord’u macOS’te sadece kendi Proxy’si üzerinden çalıştıran, sistemin geri kalanını hiç etkilemeyen küçük bir araç.**

---

## 1. Ne yapar?

- Sadece **Discord**’un bağlantılarını **spoofdpi proxy** (127.0.0.1:8080) üzerinden geçirir.
- Safari, Chrome, Zoom, oyunlar ve tüm diğer uygulamalar aynı şekilde çalışmaya devam eder.
- Mac açıldığında servisler otomatik devreye girer, Discord hazır bekler.
- Tek komutla tamamen kaldırılabilir.

---

## 2. Bilgisayarımda ne değişecek?

| Dosya / Klasör                                                  | Açıklama                                                      |
| --------------------------------------------------------------- | ------------------------------------------------------------- |
| `~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist` | spoofdpi’yi arka planda sürekli çalıştırır                    |
| `~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist` | Discord’u **proxy port açılana kadar bekleyip** öyle başlatır |
| `~/Library/Application Support/Consolaktif-Discord/`            | Script’ler ve kontrol paneli buraya kopyalanır                |
| `~/Library/Logs/net.consolaktif.discord.spoofdpi.*.log`         | Çalışma logları, 10 MB’ı geçerse otomatik sıkıştırılır (gzip) |
| `~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log`       | Hata logları, ilk bakılacak yer                               |
| Masaüstü: `SplitWire Kontrol`                                   | Discord’u Proxy ile **Başlat / Durdur** paneli                |

---

## 3. Gerekenler

- macOS 12 (Monterey) veya üstü
- `/Applications/Discord.app` içinde **Discord** kurulu olmalı
- Homebrew (yoksa kurulum sırasında otomatik yüklenir)

---

## 4. Eğer **Discord’un yoksa**

Terminal’de:

```bash
cd ~/Downloads/SplitWire-for-Macos-main
chmod +x *.sh
./install-discord.sh
```

---

## 5. Hızlı Kurulum (3 adım)

1. Terminal’de indirdiğin klasöre gir:

   ```bash
   cd ~/Downloads/SplitWire-for-Macos-main
   chmod +x *.sh
   ./install.sh
   ```

   - Homebrew yoksa otomatik kurar (şifre sorabilir).
   - spoofdpi yoksa otomatik kurar.
   - Discord yoksa hata verir → `install-discord.sh` ile yükleyip tekrar çalıştırabilirsin.

2. Kurulum bitince masaüstünde **SplitWire Kontrol** kısayolu çıkar.
   Buradan Proxy’yi **Başlat/Durdur** yapabilirsin.

3. Discord’u aç → artık trafiği **spoofdpi** üzerinden gidiyor.

---

## 6. Kaldırma (2 saniye)

Aynı klasörde:

```bash
cd ~/Downloads/SplitWire-for-Macos-main
chmod +x *.sh
./uninstall.sh
```

- Tüm plist’ler kaldırılır.
- Masaüstündeki kısayol silinir.
- İstersen loglar ve destek dosyaları da silinir.
- İstersen Homebrew üzerinden kurulan **spoofdpi** paketi de kaldırılır.

---

## 7. Logları Görüntüleme

Bir hata alırsan:

```bash
tail -f ~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log
```

Logu izlerken Discord’u tekrar başlatabilirsin.

---

## 8. Manuel Kontroller

| İşlem                             | Komut                                                                  |
| --------------------------------- | ---------------------------------------------------------------------- |
| Servisleri listele                | `launchctl list \| grep net.consolaktif.discord`                       |
| spoofdpi’yi yeniden başlat        | `launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi` |
| Discord’u yeniden proxy’li başlat | `launchctl kickstart gui/$(id -u)/net.consolaktif.discord.launcher`    |
| Geçici durdur                     | `launchctl stop net.consolaktif.discord.spoofdpi`                      |

---

## 9. Port veya Parametre Değiştirmek

1. Script dosyasını aç:

   ```bash
   nano ~/Library/Application\ Support/Consolaktif-Discord/discord-spoofdpi.sh
   ```

2. Şu satırı değiştir:

   ```
   LISTEN_PORT=8080
   ```

   → istediğin port numarasını yaz.

3. Servisi yeniden başlat:

   ```bash
   launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi
   ```

---

## 10. SSS (Sıkça Sorulan Sorular)

**❓ Discord’u Dock veya Spotlight’tan açarsam yine proxy ile mi çalışır?**
✅ Evet, her açılışta `--proxy-server` parametresi otomatik eklenir.

**❓ Başka uygulamaları da yönlendirebilir miyim?**
⚠️ Bu kurulum sadece Discord’a özel. Ama plist dosyasını kopyalayıp ayarlarsan diğer uygulamalara da yapabilirsin.

**❓ spoofdpi kapanırsa ne olur?**
🔄 3 saniye içinde launchd yeniden başlatır.

**❓ Homebrew zaten kurulu, tekrar kurar mı?**
❌ Hayır. `brew` komutunu bulursa hiç dokunmaz.

**❓ macOS güncellemesi sonrası bozulur mu?**
Genellikle hayır. Çünkü `LaunchAgents` kullanıcı seviyesinde. Bozulursa `./install.sh` tekrar çalıştırman yeterli.

---

## 11. Performans & Dayanıklılık Özellikleri

- **Port Bekleme**: Discord başlatılmadan önce 30 saniye boyunca port hazır olana kadar beklenir.
- **Log Rotate**: 10 MB dolunca log otomatik sıkıştırılır.
- **CPU / RAM Limit**: %60 CPU ve 256 MB RAM sınırı → sistem kitlenmez.
- **Graceful Uninstall**: Kaldırma sırasında Discord düzgünce kapatılır.
- **Otomatik Port Değişimi**: 8080 doluysa 8081–8099 arası rastgele port denenir.

---

🎉 Hepsi bu kadar!
Artık **Discord her açıldığında Proxy üzerinden** çalışacak.

---
