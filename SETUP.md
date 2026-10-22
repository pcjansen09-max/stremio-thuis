# Handmatige setup

Als je dit zonder Claude Code wil opzetten. Alles handmatig, stap voor stap.

**Vereisten**: Mac met macOS 13+ (Apple Silicon aanbevolen), Homebrew geïnstalleerd, een iPhone/Android/laptop op hetzelfde WiFi-netwerk.

---

## 1. Stremio installeren

```bash
brew install --cask stremio
xattr -r -d com.apple.quarantine /Applications/Stremio.app
```

De `xattr`-regel is cruciaal. Zonder dat crasht Stremio stil bij opstart door macOS Gatekeeper.

## 2. Stremio openen

Open Stremio via Launchpad of:
```bash
open /Applications/Stremio.app
```

Als macOS alsnog zeurt ("ontwikkelaar niet gecontroleerd"):
- Systeeminstellingen → Privacy en beveiliging → scrol naar beneden → "Open toch" naast Stremio.

In Stremio: klik **Guest Login** onderaan. Je hoeft geen account te maken.

## 3. Torrentio-addon installeren

Open deze URL in je terminal:
```bash
open "stremio://torrentio.strem.fun/providers=yts,eztv,rarbg,1337x,thepiratebay,torrentgalaxy,magnetdl,horriblesubs,nyaasi%7Cqualityfilter=cam,scr,unknown%7Csort=qualitythensize/manifest.json"
```

Stremio opent een dialoogje. Klik **Install**.

## 4. Server tunen voor fullscreen-audio

```bash
curl -s -X POST http://127.0.0.1:11470/settings \
  -H "Content-Type: application/json" \
  -d '{"transcodeProfile":"videotoolbox","transcodeHardwareAccel":true,"proxyStreamsEnabled":true,"transcodeMaxWidth":1920,"transcodeConcurrency":2,"transcodeTrackConcurrency":2}'
```

Verwachte output: `{"success":true}`.

## 5. Stremio Web zelf hosten

```bash
mkdir -p ~/delta-work/stremio-thuis
cd ~/delta-work/stremio-thuis
curl -sL -o stremio-web.zip https://github.com/Stremio/stremio-web/releases/latest/download/stremio-web.zip
unzip -q -o stremio-web.zip -d web/
cd web/build
nohup python3 -m http.server 8080 --bind 0.0.0.0 > /tmp/stremio-web.log 2>&1 &
disown
```

Zoek het LAN-IP van je Mac op:
```bash
/sbin/ifconfig | awk '/inet /{if($2!~/^127\./ && $2~/^192\.|^10\.|^172\./){print $2;exit}}'
```

Noteer dat getal — bijvoorbeeld `192.168.2.72`.

## 6. Test vanaf een ander apparaat

Op je iPhone/Android op hetzelfde WiFi:
```
http://192.168.2.72:8080
```
(vervang IP met jouw mac-ip)

Je ziet Stremio Web. Klik **Guest Login**. Ga naar **Addons** (puzzelstukje) → als Torrentio niet in de lijst staat: plak deze URL bovenaan en klik Install:

```
https://torrentio.strem.fun/providers=yts,eztv,rarbg,1337x,thepiratebay,torrentgalaxy,magnetdl,horriblesubs,nyaasi|qualityfilter=cam,scr,unknown|sort=qualitythensize/manifest.json
```

Ga naar **Settings** (tandwiel) → **Streaming Server URL** → zet op `http://192.168.2.72:11470/` (jouw IP).

Zoek een film ("Inception"), klik, kies een **YTS**-stream met veel seeders, speel af.

## 7. Zet op beginscherm (iPhone/iPad)

In Safari → Share-icoon onderin → "Zet op beginscherm". Je hebt nu een app-icoontje.

## 8. Persistence (optioneel)

Zodat Stremio Web na reboot vanzelf opstart:

```bash
cp scripts/launchd/nl.deltadesign.stremio-web.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/nl.deltadesign.stremio-web.plist
```

En Stremio zelf: Systeeminstellingen → Algemeen → Login-items → + → Stremio.app toevoegen.

---

Klaar. Werkt alleen thuis. Mac moet aanstaan tijdens kijken. Zie `TROUBLESHOOTING.md` als iets niet werkt.
