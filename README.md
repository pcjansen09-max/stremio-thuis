# Stremio Thuis

Je eigen "Netflix" op je Mac, bereikbaar vanaf iedere telefoon, tablet of TV in je huis — via het lokale WiFi-netwerk. Geen cloud, geen publieke URL, geen abonnement.

Deze repo documenteert een werkende opzet die ik samen met Claude Code op mijn Mac Studio heb gebouwd. Je kunt het handmatig volgen (`SETUP.md`), of dit repo doorgeven aan **jouw** Claude Code via `CLAUDE.md` zodat die het grotendeels voor je bouwt.

---

## Wat het is

```
┌────────────────────────────────────┐
│  Mac (thuis, altijd aan)           │
│   • Stremio Desktop                │
│   • Torrentio-addon                │
│   • Streaming-server (poort 11470) │
│   • Web-UI (poort 8080)            │
└──────────────┬─────────────────────┘
               │ lokaal WiFi
               ↓
┌────────────────────────────────────┐
│  iPhone / iPad / Android / TV      │
│   • Opent http://<mac-ip>:8080     │
│   • Netflix-achtige UI             │
│   • Speelt af via de Mac           │
└────────────────────────────────────┘
```

- **De Mac** doet al het zware werk: torrents binnentrekken, transmuxen/transcoden, serveren.
- **De clients** krijgen gewoon een HTTP-videostream. Werken op elk apparaat met een browser.
- **Niks publiek online.** Alleen bereikbaar binnen je eigen WiFi-netwerk.

---

## Wat werkt (en wat niet)

### Werkt

- Mac Studio / Mac mini / MacBook als server (Apple Silicon aanbevolen — hardware-transcoding via VideoToolbox).
- iPhone-browser (Safari) als client op hetzelfde WiFi.
- Android-browser als client.
- Samsung Smart TV (Tizen) via de ingebouwde browser (`Smart Hub → Internet`).
- Meerdere apparaten tegelijk (3+ streams simultaan is prima op moderne Macs).
- 1080p-afspelen stabiel. 4K ook, mits WiFi snel genoeg (minimaal 50 Mbps per 4K-stream).
- Nederlandse ondertitels via de OpenSubtitles-addon (zit standaard in Stremio).

### Werkt niet of met beperkingen

- **Buitenshuis kijken**: niet. Dit is bewust lokaal. Zie [Veiligheid](#veiligheid--legaliteit) voor waarom dit géén publieke URL moet worden.
- **Stremio iOS-app**: sinds 2024 niet in de Nederlandse App Store. Daarom gebruiken we Safari met de self-hosted Web-UI.
- **iOS Safari fullscreen + AC3/EAC3-audio**: iOS' native fullscreen-speler kan AC3 niet decoderen. Oplossingen:
  - Kies **YTS/YIFY**-releases (AAC-audio, werkt altijd).
  - Of speel af op de Mac en AirPlay naar TV.
  - Of open de Web-UI direct in de Samsung TV-browser.
- **Chromecast vanaf iOS Safari**: Apple blokkeert dit op systeemniveau. AirPlay werkt wel.
- **Surround sound via iPhone-AirPlay**: wordt gereduceerd tot stereo omdat iPhone decodeert. Voor echt surround: Mac → AirPlay → TV, of TV-browser direct.

---

## Snelstart

1. Kloon dit repo op je Mac.
2. Lees `SETUP.md` voor handmatige stappen, **óf** geef `CLAUDE.md` aan je Claude Code: `/init` in deze map en Claude pakt het op.
3. Open na afloop `http://<ip-van-je-mac>:8080` op elke client in je huis.

```
git clone https://github.com/pcjansen09-max/stremio-thuis.git
cd stremio-thuis
./scripts/install.sh
```

---

## Veiligheid & legaliteit

Deze setup is bedoeld voor **persoonlijk gebruik binnen je eigen huis**, met content waar jij rechten voor hebt of toegang toe. Lees de volledige disclaimer in `LEGAL.md` voor je iets installeert.

Belangrijke punten:
- Niets op het internet publiceren. Deze setup luistert op je LAN, niet op het publieke internet. **Houd dat zo.**
- Geen commercieel gebruik. Dit is een thuis-opstelling voor je eigen gezin. Een "€6/maand streamingdienst" ervan maken is een regelrechte piraterij-onderneming en in Nederland strafbaar (gevangenisstraffen tot 3 jaar + boetes, zie `LEGAL.md`).
- Geen tunnel (Cloudflare / Tailscale Funnel / ngrok) richting het publieke internet. Zodra je dat doet word je in de wet een **operator** en loopt het risicoprofiel van ~0% naar reëel.

Zie `LEGAL.md` voor de volledige uitleg.

---

## Hoe deze opzet tot stand kwam

Deze repo is het resultaat van een sessie waarin veel fout ging voor het klopte. De fouten + oplossingen staan in `TROUBLESHOOTING.md` — handig voor als jij er ook tegenaan loopt.

Highlights:
- Stremio geïnstalleerd via Homebrew → macOS Gatekeeper hield de app silently tegen → `xattr`-strip loste op.
- Stremio Web niet in de officiële App Store (NL) → zelf hosten op poort 8080.
- iOS Safari fullscreen = geen audio bij AC3-rips → transcoding aanzetten + YTS-streams aanbevelen.
- Launchd-persistence stuitte op mijn eigen veiligheidsclassifier → handmatige launchd-load vereist.

---

## Repo-inhoud

| Bestand | Wat erin staat |
|---------|----------------|
| `README.md` | Dit bestand |
| `CLAUDE.md` | Instructies voor Claude Code om de setup voor jou te bouwen |
| `SETUP.md` | Handmatige stap-voor-stap-handleiding |
| `TROUBLESHOOTING.md` | Problemen die we tegenkwamen + oplossingen |
| `LEGAL.md` | Juridische disclaimer en risicoprofiel |
| `scripts/install.sh` | Automatische installer (brew + stremio + web-UI + server-config) |
| `scripts/configure-server.sh` | Zet transcoding + concurrency goed via de Stremio-server-API |
| `scripts/launchd/nl.deltadesign.stremio-web.plist` | Launchd-job om Stremio Web-UI na reboot te starten |
| `docs/architecture.md` | Architectuurdiagram + hoe de componenten praten |

---

## Credits

- [Stremio](https://www.stremio.com) — de mediaplayer en addon-ecosysteem die dit mogelijk maakt.
- [Stremio Web](https://github.com/Stremio/stremio-web) — open-source webclient (AGPL-3.0).
- [Torrentio](https://torrentio.strem.fun) — community-addon voor stream-discovery.

---

## Licentie

MIT voor de scripts en documentatie in dit repo. Stremio en Stremio Web hebben hun eigen licenties — zie hun repo's.
