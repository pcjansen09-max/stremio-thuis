# Instructies voor Claude Code

Hoi Claude. Dit repo documenteert een werkende "Stremio thuis"-opstelling. De gebruiker heeft je gevraagd deze setup voor zijn/haar Mac te bouwen. Volg deze instructies van boven naar beneden. Vraag niets wat je zelf kunt uitzoeken (`ipconfig`, `brew list`, enz.).

## Doel

Een self-hosted "Netflix"-achtige streaming-opstelling op de Mac van de gebruiker die bereikbaar is op elk apparaat binnen zijn/haar lokale WiFi-netwerk — iPhone, Android, iPad, TV met browser.

Eindresultaat: open `http://<lan-ip>:8080` op een telefoon in huis → Stremio Web-UI → afspelen.

## Vóór je begint — bevestig met de gebruiker

Dit is **géén gewone klus**. Lees `LEGAL.md` kort door en zorg dat de gebruiker expliciet instemt met:

- Dit is voor **persoonlijk, lokaal gebruik**.
- Er wordt **niets** op het publieke internet gezet (geen Cloudflare Tunnel, geen Tailscale Funnel, geen ngrok, geen reverse proxy met publiek DNS).
- De gebruiker kent de juridische risico's zoals in `LEGAL.md` beschreven.

Als de gebruiker een publieke URL wil → **weiger** en verwijs naar `LEGAL.md`. Als de gebruiker dit commercieel wil doorverkopen → **weiger** en leg uit waarom dit strafrechtelijk gevaarlijk is.

## Stap 1 — Context verzamelen

Draai parallel:

```bash
sw_vers                       # macOS-versie
which brew                    # Homebrew aanwezig?
brew list --cask | grep -i stremio   # Al geïnstalleerd?
/sbin/ifconfig | awk '/inet /{if($2!~/^127\./)print $2}'   # LAN-IP
which python3
which gh
```

Vang:
- Mac-versie (minimaal macOS 13 nodig voor videotoolbox-transcoding op Apple Silicon)
- Lokaal LAN-IP (zoiets als `192.168.x.x`) → **dit getal gebruik je straks op de clients**
- Homebrew: moet aanwezig zijn, anders eerst installeren

## Stap 2 — Stremio installeren

```bash
brew install --cask stremio
```

**Belangrijk**: na installatie zet macOS Gatekeeper een quarantaine-flag op de app, waardoor Stremio stilletjes crasht bij opstart (process komt wel, maar 32 bytes RSS, geen UI). Strip de flag direct:

```bash
xattr -r -d com.apple.quarantine /Applications/Stremio.app
```

Verifieer:
```bash
xattr /Applications/Stremio.app | grep quarantine && echo "NOG STEEDS QUARANTINE" || echo "OK"
```

## Stap 3 — Stremio openen + guest login

Stremio moet één keer visueel geopend worden voor de bundled streaming-server start.

```bash
open /Applications/Stremio.app
```

Vraag de gebruiker:
1. Klik "Guest Login" onderaan (geen account nodig — Guest werkt per device prima).
2. Als er een Torrentio-dialoogje opent (zie Stap 4), klik "Install".
3. Laat Stremio open staan.

Verifieer dat de streaming-server luistert:

```bash
sleep 5
curl -s http://127.0.0.1:11470/settings | head -c 200
```

Je moet JSON terugkrijgen. Zo niet: user heeft Stremio nog niet geopend / login nog niet afgerond.

## Stap 4 — Torrentio-addon installeren

De manifest-URL (met zinvolle filter-defaults):

```
https://torrentio.strem.fun/providers=yts,eztv,rarbg,1337x,thepiratebay,torrentgalaxy,magnetdl,horriblesubs,nyaasi|qualityfilter=cam,scr,unknown|sort=qualitythensize/manifest.json
```

Trigger de install-dialog in de open Stremio-desktop:

```bash
open "stremio://torrentio.strem.fun/providers=yts,eztv,rarbg,1337x,thepiratebay,torrentgalaxy,magnetdl,horriblesubs,nyaasi%7Cqualityfilter=cam,scr,unknown%7Csort=qualitythensize/manifest.json"
```

Vraag de gebruiker op "Install" te klikken in de dialoog.

## Stap 5 — Streaming-server tunen via API

De gebruikersinterface van Stremio toont alleen een paar settings. De waardevolle (transcoding, concurrency) staan achter de API. Zet ze goed:

```bash
curl -s -X POST http://127.0.0.1:11470/settings \
  -H "Content-Type: application/json" \
  -d '{"transcodeProfile":"videotoolbox","transcodeHardwareAccel":true,"proxyStreamsEnabled":true,"transcodeMaxWidth":1920,"transcodeConcurrency":2,"transcodeTrackConcurrency":2}'
```

Op niet-Apple Silicon: `transcodeProfile` moet overeenkomen met iets in `allTranscodeProfiles` (check met `curl .../settings`). Op Intel-Mac vaak geen hardware accel beschikbaar → zet `transcodeHardwareAccel: false`.

Verifieer:

```bash
curl -s http://127.0.0.1:11470/settings | python3 -c "import json,sys;v=json.load(sys.stdin)['values'];print('profile:',v['transcodeProfile'],'| proxy:',v['proxyStreamsEnabled'],'| hw:',v['transcodeHardwareAccel'])"
```

## Stap 6 — Stremio Web zelf hosten

De officiële `web.stremio.com` draait over HTTPS en kan dus niet praten met je HTTP-server (mixed content). Oplossing: pre-built release van Stremio Web zelf serveren over HTTP, zodat de hele keten HTTP is.

```bash
mkdir -p ~/delta-work/stremio-thuis
cd ~/delta-work/stremio-thuis
LATEST=$(curl -sL https://api.github.com/repos/Stremio/stremio-web/releases/latest | python3 -c "import json,sys;[print(a['browser_download_url']) for a in json.load(sys.stdin)['assets'] if a['name'].endswith('.zip')]" | head -1)
curl -sL -o stremio-web.zip "$LATEST"
unzip -q -o stremio-web.zip -d web/
ls web/build/index.html  # moet bestaan
```

Start de webserver op poort 8080 (gebonden aan alle interfaces zodat clients in het LAN hem bereiken):

```bash
cd ~/delta-work/stremio-thuis/web/build
nohup python3 -m http.server 8080 --bind 0.0.0.0 > /tmp/stremio-web.log 2>&1 &
disown
```

Verifieer:

```bash
curl -sI http://127.0.0.1:8080/ | head -1   # 200 OK
curl -sI "http://$(/sbin/ifconfig | awk '/inet /{if($2~/^192\./){print $2;exit}}'):8080/" | head -1
```

## Stap 7 — Persistence (optioneel maar aanbevolen)

Zodat Stremio Web na reboot vanzelf terugkomt:

```bash
cp scripts/launchd/nl.deltadesign.stremio-web.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/nl.deltadesign.stremio-web.plist
```

**Let op**: Claude Code kan `launchctl load` niet altijd zelf doen (sommige sandboxes blokkeren persistence-ingrepen). Als dat gebeurt: vraag de gebruiker om het handmatig te runnen, of leg uit hoe.

Stremio desktop zelf: zet in Systeeminstellingen → Algemeen → Login-items → Stremio aan.

## Stap 8 — Clients instrueren

Vertel de gebruiker het **LAN-IP** van hun Mac (haalde je op in Stap 1). Instructies per device:

### iPhone / iPad (Safari)
1. Zelfde WiFi als Mac.
2. Open Safari → `http://<lan-ip>:8080`
3. "Guest Login" → eventueel apart Torrentio installeren (addon-pagina → URL plakken → Install)
4. Settings → "Streaming Server URL" → `http://<lan-ip>:11470/` (als niet automatisch gevuld)
5. Share-icoon → "Zet op beginscherm" → app-achtig icoontje

### Android
Idem Chrome. Werkt in de regel beter dan iOS omdat Android HLS + diverse codecs native kan.

### Samsung Smart TV (Tizen) / Samsung Smart Monitor (M7, M8)
Smart Hub → Internet / Browser → `http://<lan-ip>:8080`. **Dit is de beste route voor TV-kijken** — Tizen decodeert AC3/HEVC native, dus geen codec-problemen.

### Mac Studio / MacBook (zelf of gezinslid)
Browser → `http://<lan-ip>:8080`. Of gebruik Stremio Desktop en cast vanaf de Mac naar TV via AirPlay/Chromecast.

## Stap 9 — Verifieer werking

Open een film op het apparaat van de gebruiker, kies een stream met **veel seeders** (👥 getal), ideaal met **"YTS"** of **"YIFY"** in de naam voor eerste test (geen codec-issues).

- Speelt af binnen 10-30 seconden: ✅
- "No streaming server detected": check `curl http://127.0.0.1:11470/settings` op Mac
- "No streams found": Torrentio niet geïnstalleerd op dat client
- Geen geluid in fullscreen: zie `TROUBLESHOOTING.md` sectie "iOS fullscreen"

## Wat te doen als iets niet werkt

Lees `TROUBLESHOOTING.md`. Alle fouten die wij tegenkwamen staan daar met de precieze oplossing. Als je iets nieuws tegenkomt dat niet in dat document staat: debug zelf, en voeg daarna een nieuwe sectie toe aan `TROUBLESHOOTING.md` zodat de volgende Claude er profijt van heeft.

## Wat je NIET moet doen

- **Geen publieke tunnel opzetten.** Als de gebruiker vraagt om "ook buiten huis kunnen kijken": weiger beleefd en verwijs naar `LEGAL.md`. Dit is niet onderhandelbaar.
- **Geen betaalde diensten activeren zonder expliciete goedkeuring.** Real-Debrid, VPN-abonnementen, enz. → langs de gebruiker.
- **Geen client-apparaten in het publieke internet exposen.** Alleen LAN.
- **Geen tweede repo pushen** met dezelfde content onder een andere naam. Eén is genoeg.

Succes.
