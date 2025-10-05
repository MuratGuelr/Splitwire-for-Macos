## Olası Sorunlar (M1/M2 Apple Silicon) ve Çözümler

### 1) Xcode Komut Satırı Araçları (CLT) eksik uyarısı

- Belirti: Kurulum/çalıştırma sırasında “xcode-select …” veya derleme araçları eksik uyarısı.
- Neden: Apple Silicon sistemlerde bazı araçlar için CLT gerekir.
- Çözüm: `install.sh` artık otomatik kuruyor. Gerekirse elle: `xcode-select --install` ve kurulum tamamlanana kadar bekleyin.

### 2) Intel/Rosetta ikilileriyle karışıklık

- Belirti: `file $(command -v spoofdpi)` çıktısı arm64 göstermiyor veya komut yanlış prefix’ten geliyor.
- Neden: Terminal’i Rosetta altında açmak veya x86_64 Homebrew yolunun öne geçmesi.
- Çözüm: Terminal’i yerel (arm64) başlatın. `brew --prefix` → `/opt/homebrew` olmalı. `spoofdpi`yi ARM ile yeniden kurun:
  ```bash
  brew uninstall spoofdpi
  brew install spoofdpi
  file $(command -v spoofdpi)   # arm64 doğrula
  ```

### 3) Homebrew iki farklı prefix (arm64 ve x86_64) karışıklığı

- Belirti: `brew` komutu var ama paket bulunamıyor veya farklı dizinde kurulu.
- Neden: Apple Silicon’da `/opt/homebrew` (arm64), Intel’de `/usr/local` (x86_64) kullanılır.
- Çözüm: Betikler hem `/opt/homebrew` hem `/usr/local` yollarını destekler. `brew shellenv` çıktısını mevcut oturuma uygulayın.

### 4) `spoofdpi` bulunamadı / PATH sorunu

- Belirti: `discord-spoofdpi.sh` içinde “HATA: spoofdpi çalıştırılabilir dosyası bulunamadı.”
- Neden: `spoofdpi` Homebrew ile kurulmamış ya da PATH’e ekli değil.
- Çözüm: `brew install spoofdpi`. Gerekirse `launchd` plist içinde `PATH` anahtarı zaten `/opt/homebrew/bin:/usr/local/bin` içerir.

### 5) Proxy portu (8080) zaten kullanımda

- Belirti: Port bekleme sırasında zaman aşımı; Discord açılmıyor.
- Neden: 8080 başka bir servis tarafından kullanılıyor olabilir.
- Çözüm: `~/Library/Application Support/Consolaktif-Discord/discord-spoofdpi.sh` içindeki `LISTEN_PORT` değerini değiştirin ve servisi yeniden başlatın.

### 6) `launchd` servisleri yüklenemiyor (izinler/karantina)

- Belirti: Servisler görünmüyor veya hemen kapanıyor.
- Neden: Dosya izinleri yürütülebilir değil veya karantinada.
- Çözüm: Kurulum betiği `chmod +x` ve `xattr -d com.apple.quarantine` uygular. Manuel kontrol: `launchctl list | grep consolaktif` ve loglara bakın.

### 7) Discord uygulaması bulunamadı

- Belirti: `install.sh` “Discord bulunamadı” hatası verir.
- Neden: Discord `/Applications` içine kurulu değil.
- Çözüm: Discord’u indirip `/Applications` klasörüne taşıyın veya `./install-discord.sh` ile Homebrew üzerinden kurun.

### 8) Ağ politikaları / kurumsal kısıtlamalar

- Belirti: Proxy açık olsa da bağlantı kurulamıyor.
- Neden: Şirket profilleri (MDM), güvenlik yazılımları veya ağ filtreleri.
- Çözüm: Kendi ağınızda deneyin, farklı port deneyin, güvenlik yazılımı istisnası ekleyin.

### 9) Loglarda hata var ama GUI görünmüyor

- Belirti: Her şey sessizce başarısız oluyor.
- Çözüm: Hata logunu canlı izleyin:
  ```bash
  tail -f ~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log
  ```
  Ardından servisleri yeniden başlatın:
  ```bash
  launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi
  launchctl kickstart gui/$(id -u)/net.consolaktif.discord.launcher
  ```

### 10) macOS sürüm uyumsuzluğu

- Belirti: Daha eski macOS’ta bazı komutlar/parametreler yok.
- Çözüm: Proje macOS 12+ hedefli. Daha eski sürümlerde CLT/Rosetta/launchd davranışları değişebilir.
