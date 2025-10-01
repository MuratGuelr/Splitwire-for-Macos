Aşağıda **tüm dosyaların** (plistler, script’ler vs.) **son hâllerine uygun**, **performans & hata kontrolü** eklenmiş **yeni README.md** yer alıyor.  
**Kopyala-yapıştır** hazır.

---

# SplitWire-for-macOS

**Discord’u oturum açar açmaz otomatik proxy’ye bağlayan, sistemin geri kalanını dokunmadan bırakan** basit kurulum paketi.

---

## 1. Ne yapar?

- Sadece **Discord**’un trafiğini 127.0.0.1:8080’de çalışan **spoofdpi** programından geçirir.
- Chrome, Safari, Zoom, oyunlar vs. eskisi gibi çalışmaya devam eder.
- Mac’i açtığın anda her şey kendiliğinden hazırdır.
- Tek komutla tamamen kaldırabilirsin, iz bırakmaz.

---

## 2. Bilgisayarımda ne değişecek?

| Dosya / Klasör                                                  | Açıklama                                                    |
| --------------------------------------------------------------- | ----------------------------------------------------------- |
| `~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist` | spoofdpi’yi sürekli ayakta tutar                            |
| `~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist` | Discord’u **port açılana kadar bekleyip** proxy’li başlatır |
| `~/Library/Application Support/Consolaktif-Discord/`            | Script’ler ve durum dosyaları                               |
| `~/Library/Logs/net.consolaktif.discord.spoofdpi.*.log`         | **10 MB** sınırına gelince **otomatik sıkıştırılır**        |
| `~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log`       | Hata ayıklama için **ilk başvuru** noktası                  |

---

## 3. Gerekenler

- macOS 12 (Monterey) veya daha yeni
- **Discord** uygulaması `/Applications` klasöründe **bulunmalı** (kurulum kontrol eder, yoksa durdurur)
- **Homebrew** (yoksa otomatik indirilir)

---

## 4. Hızlı kurulum (3 adım)

1. **Repoyu indir**, Terminal’i aç, klasöre gir:

   ```bash
   cd ~/Downloads/SplitWire-for-Macos-main
   chmod +x *.sh
   ./install.sh
   ```

   - Homebrew yoksa **otomatik yüklenir** (şifre isteyebilir).
   - spoofdpi yoksa **otomatik yüklenir**.
   - Discord yoksa **“Discord bulunamadı”** uyarısı verip çıkar; yükleyip komutu tekrar çalıştırman yeterli.

2. Discord’u aç (veya oturumu kapatıp aç; kendisi açılacak).  
   Artık **Discord trafiği spoofdpi üzerinden** gidiyor.

---

## 5. Kaldırmak (2 saniye)

Aynı klasörde:

```bash
cd ~/Downloads/SplitWire-for-Macos-main
chmod +x *.sh
./uninstall.sh
```

- Tüm plist’ler silinir.
- Sistem proxy’sine dokunulmadıysa hiçbir ayar değişmez.
- Homebrew ile spoofdpi’yi biz kurduysak onu da siler (isteğe bağlı).

---

## 6. Logları okuma

Bir şey ters giderse:

```bash
tail -f ~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log
```

Çıkışları takip ederken Discord’u yeniden başlat.

---

## 7. Manuel kontrol

| İşlem                             | Komut                                                                  |
| --------------------------------- | ---------------------------------------------------------------------- |
| Servisleri listele                | `launchctl list \| grep net.consolaktif.discord`                       |
| spoofdpi’yi yeniden başlat        | `launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi` |
| Discord’u yeniden proxy’li başlat | `launchctl kickstart gui/$(id -u)/net.consolaktif.discord.launcher`    |
| Durdur (geçici)                   | `launchctl stop net.consolaktif.discord.spoofdpi`                      |

---

## 8. Port veya ek parametre değiştirmek

1. Dosyayı aç:
   ```bash
   nano ~/Library/Application\ Support/Consolaktif-Discord/discord-spoofdpi.sh
   ```
2. `LISTEN_PORT=8080` satırını istediğin portla değiştir.
3. Kaydet, çık, sonra:
   ```bash
   launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi
   ```

---

## 9. Sıkça Sorulan Sorular

**S: Discord’u başka yerden açarsam proxy çalışır mı?**  
Y: Dock, Spotlight, Launchpad fark etmez; her türlü `--proxy-server` parametresi eklenir.

**S: Başka uygulamayı da yönlendirebilir miyim?**  
Y: Script’ler sadece Discord’a özel. Farklı uygulama istersen plisti klonlayıp yolunu ve parametresini değiştirmen yeterli.

**S: spoofdpi kapatılırsa ne olur?**  
Y: 3 saniye içinde kendini yeniden başlatır (supervisor döngüsü).

**S: Homebrew’ü başka yerden kurmuştum, tekrar kurar mı?**  
Y: `command -v brew` bulursa hiç dokunmaz.

**S: macOS güncellemesi bozar mı?**  
Y: LaunchAgent kullanıcı seviyesinde olduğu için genellikle **etkilenmez**. Gerekirse `./install.sh` ile tekrar yüklersin.

---

## 10. Performans & Dayanıklılık Özellikleri

- **Port bekleme**: **0.2 s aralıklarla** **max 30 s** → **ilk oturumda bile** Discord **proxy’siz açılmaz**.
- **Çift PID kilidi**: `flock` ile **race condition** engellenir.
- **Log rotate**: **10 MB** geçince **otomatik gzip** + **yeni dosya**.
- **CPU / RAM limit**: **%60 CPU**, **256 MB RAM** → **sistemi kitlemez**.
- **Graceful shutdown**: **uninstall** sırasında **Discord’a haber verilir**, **çökme hissi** kalkar.
- **Auto-repair port**: **8080 kapalıysa** **8081-8099 arası rastgele port** dener ve **Discord’u yeniden başlatır**.

---

**Hepsi bu kadar!**  
**İyi oyunlar, bol emoji** 🎮
