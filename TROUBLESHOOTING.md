# Troubleshooting

Alle problemen die wij tegenkwamen tijdens het bouwen van deze setup, met de precieze oplossing. In volgorde van hoe we ze tegenkwamen.

---

## 1. Stremio start niet (geen UI, geen error)

**Symptoom**: `open /Applications/Stremio.app` → process verschijnt met 32 bytes RSS en 0 CPU, geen venster, geen crash-log. Repeateerbaar.

**Oorzaak**: macOS Gatekeeper's quarantaine-flag. Stremio is unsigned/not notarized voor Apple's smaak, de app launcht maar wordt direct door Gatekeeper gekilled.

**Diagnose**:
```bash
xattr /Applications/Stremio.app
# Als je 'com.apple.quarantine' ziet: dit is het.
```

**Fix**:
```bash
xattr -r -d com.apple.quarantine /Applications/Stremio.app
```

Daarna:
```bash
open /Applications/Stremio.app
```

Als het dán alsnog een "ongeverifieerde ontwikkelaar"-dialoog toont: Systeeminstellingen → Privacy en beveiliging → scrol onderaan → "Open toch".

---

## 2. "Streaming server offline" in Stremio Web

**Symptoom**: Film kiezen → "No streaming server" of "Server unavailable".

**Oorzaak**: De bundled streaming-server start pas als de Stremio-desktop-app volledig is opgestart én de gebruiker voorbij het login-scherm is.

**Diagnose**:
```bash
curl -s http://127.0.0.1:11470/settings | head -c 100
```
Als dit niks teruggeeft of connection refused: de server draait niet.

**Fix**:
1. Zorg dat Stremio-desktop open is (venster zichtbaar).
2. Login met Guest of je account, kom voorbij het login-scherm.
3. Wacht 5 seconden, test opnieuw.

Als het dan nog niet werkt: `pkill Stremio`, dan `open /Applications/Stremio.app` opnieuw.

---

## 3. Server luistert op 127.0.0.1 maar niet op LAN-IP

**Symptoom**: `curl http://127.0.0.1:11470/settings` werkt, maar `curl http://192.168.x.x:11470/settings` vanaf dezelfde Mac werkt niet, of iPhone kan er niet bij.

**Diagnose**:
```bash
/usr/sbin/lsof -nP -iTCP:11470 -sTCP:LISTEN
```
Je moet zien: `TCP *:11470 (LISTEN)`. Als er `127.0.0.1:11470` staat: alleen loopback.

In de praktijk luistert Stremio's server standaard op alle interfaces (`*:11470`). Als dat niet zo is op jouw Mac: firewall-regel of een IPv6-vs-IPv4-mismatch.

**Fix**:
- Check macOS firewall: Systeeminstellingen → Netwerk → Firewall → als aan, voeg Stremio toe aan de uitzonderingen.
- Soms luistert de server IPv6-only (`[::]:11470`). Op moderne iPhones + Macs werkt dat prima binnen één WiFi omdat ze beide IPv6 doen.

---

## 4. Login met account werkt niet ("unknown user")

**Symptoom**: Je probeert in te loggen op Stremio Web met je mailadres → "Unknown user".

**Oorzaak**: Je Stremio-account bestaat niet onder dat mailadres. Vaak omdat de desktop-login via Facebook ging (dan is er geen email+password-account) of onder een ander mailadres.

**Fix**:
- Probeer wachtwoord-reset via https://www.stremio.com/forgot-password met al je mailadressen.
- Of blijf gewoon in **Guest Login** op elk device. Je verliest alleen cross-device-sync van kijkgeschiedenis. Install Torrentio apart per device via de manifest-URL.

---

## 5. Geen geluid in fullscreen op iPhone Safari

**Symptoom**: Film speelt af met geluid in het web-venster, maar zodra je fullscreen aanzet valt het geluid weg. Beeld blijft wel.

**Oorzaak**: iOS Safari gebruikt twee verschillende spelers:
- **Inline** (in de pagina): software-decoder, speelt alles af inclusief AC3/EAC3.
- **Fullscreen**: iOS' native AVPlayer, kan AC3/EAC3 niet decoderen (Apple heeft geen AC3-licentie).

De meeste BluRay-rips hebben AC3- of EAC3-audio.

**Fixes (in volgorde van simpel naar grondig)**:

1. **Kies YTS/YIFY-streams**. Die gebruiken AAC-audio. Fullscreen + audio werkt altijd.

2. **Zet server-side transcoding aan** (one-time):
   ```bash
   curl -s -X POST http://127.0.0.1:11470/settings \
     -H "Content-Type: application/json" \
     -d '{"transcodeProfile":"videotoolbox","transcodeHardwareAccel":true,"proxyStreamsEnabled":true}'
   ```
   Daarna in Stremio Web: Settings → als er een "Use transcoding" of "External Player"-toggle staat, aanzetten.

3. **Open de web-UI op de TV zelf** (Samsung Tizen-browser kan AC3). TV-browser → `http://<mac-ip>:8080` → afspelen. Geen iPhone-issue meer.

4. **Infuse-app** vanuit de NL App Store. Decodeert AC3 native. Stream-URL kopiëren uit Stremio Web, in Infuse plakken. €0 voor URL-playback, €15 lifetime voor volledige features.

---

## 6. Stremio Web (web.stremio.com) weigert te verbinden met je LAN-server

**Symptoom**: Je gaat naar https://web.stremio.com, probeert streaming-server op `http://192.168.x.x:11470` in te stellen → werkt niet, speelt niks af.

**Oorzaak**: Mixed content. `web.stremio.com` is HTTPS, jouw server is HTTP. Safari/Chrome blokkeren.

**Fix**: Niet web.stremio.com gebruiken. In plaats daarvan de pre-built Stremio Web zelf hosten op je Mac over HTTP (`http://192.168.x.x:8080`), zodat de hele keten HTTP is. Zie `SETUP.md` stap 5.

---

## 7. iOS Safari laadt wel maar vraagt dan om "https"

**Symptoom**: `http://192.168.x.x:8080` → Safari toont pagina als "niet-privé" of weigert cookies / login.

**Oorzaak**: Safari's strikte security over HTTP op niet-localhost origins.

**Fix**: Guest Login werkt zonder cookies. Accepteer de "niet-privé"-waarschuwing. Alternatief: zet een self-signed cert op de web-server (overkill voor dit doel).

---

## 8. Chromecast-knop in Stremio Web doet niks op iPhone

**Symptoom**: In Stremio Web zie je een cast-icoon, maar klikken erop doet niks op iOS Safari.

**Oorzaak**: Apple blokkeert op OS-niveau alle Google Cast SDK's in Safari (politiek, niet technisch). Dit kan niet gefixt worden.

**Fix**: Casting via alternatieve routes:
- **AirPlay** werkt wel vanuit Safari (icoontje in native video-controls bij afspelen).
- **Mac → cast naar TV**: open de film in Stremio Desktop op je Mac, gebruik daar de ingebouwde cast-knop. Werkt wel.
- **Direct op TV**: open `http://<mac-ip>:8080` in de TV-browser. Geen cast nodig.

---

## 9. Launchd persistence werkt niet

**Symptoom**: Je probeert `launchctl load ~/Library/LaunchAgents/nl.deltadesign.stremio-web.plist` en krijgt een error, of de job start niet na reboot.

**Oorzaak (indien door Claude Code uitgevoerd)**: Sommige Claude Code sandboxes blokkeren launchd-ingrepen als "Unauthorized Persistence". Niet aan de plist te wijten.

**Fix**: Draai de command handmatig in Terminal:
```bash
launchctl load ~/Library/LaunchAgents/nl.deltadesign.stremio-web.plist
launchctl list | grep stremio-web   # moet de job tonen
```

Als het nog niet werkt: check `/tmp/stremio-web.log` voor errors (bijvoorbeeld "address already in use" → eerst `pkill -f "http.server 8080"`).

---

## 10. "No streams found" voor een film

**Symptoom**: Je kiest een film, de streams-lijst is leeg of toont alleen één dubieuze bron.

**Oorzaak**: Torrentio niet geïnstalleerd op dit specifieke device, óf de film is zo obscuur dat er geen seeders zijn.

**Fix**:
- Verifieer: Addons → zie je Torrentio? Zo niet, installeren via de manifest-URL (zie SETUP stap 3 of de URL in CLAUDE.md).
- Voor obscure films: probeer de originele titel i.p.v. Nederlandse vertaling, of accepteer dat sommige dingen niet beschikbaar zijn zonder Real-Debrid.

---

## 11. Stream laadt eindeloos / buffert constant

**Symptoom**: Film laadt niet, of hapert elke paar seconden.

**Oorzaken (in volgorde van waarschijnlijkheid)**:
1. Weinig seeders op de torrent (zie 👥-getal in de stream-lijst — minimaal 20 wil je).
2. WiFi te traag (iPhone < 50 Mbps = geen 4K).
3. Mac te traag (oude Intel-Mac, geen hardware transcoding).

**Fix**:
- Kies een andere stream met meer seeders.
- Verlaag kwaliteit: 1080p i.p.v. 4K.
- Check `curl -s http://127.0.0.1:11470/settings | python3 -c "import json,sys;v=json.load(sys.stdin)['values'];print(v['btDownloadSpeedHardLimit'])"` — als dit laag staat (default 3.5 MB/s), verhoog via de API.

---

## 12. "Permission denied" voor xattr of brew

**Symptoom**: `xattr: [Errno 1] Operation not permitted` of brew-permission-fouten.

**Fix**: `sudo` ervoor plakken, of Mac herstarten en opnieuw proberen. Als dat niet werkt: System Integrity Protection op recovery-level kan dingen blokkeren — in de regel geen probleem op standaard macOS.

---

Nieuwe fout tegengekomen? Voeg hem toe als sectie 13+, zodat de volgende Claude Code hem direct oplost.
