# Architectuur

## Componenten

```
┌─────────────────────────────────────────────────────────────┐
│                      MAC (altijd aan)                       │
│                                                             │
│  ┌─────────────────┐      ┌──────────────────────────────┐  │
│  │ Stremio Desktop │ ◄──► │  Streaming-server (bundled)  │  │
│  │  (venster UI)   │      │  Node.js, poort 11470 (HTTP) │  │
│  │                 │      │                 12470 (HTTPS)│  │
│  └─────────────────┘      │  • torrent-client            │  │
│                           │  • ffmpeg transcoder         │  │
│                           │  • HLS-outputter             │  │
│                           └──────────────┬───────────────┘  │
│                                          │                  │
│                           ┌──────────────┴───────────────┐  │
│                           │  Python http.server          │  │
│                           │  poort 8080 (HTTP)           │  │
│                           │  serveert pre-built          │  │
│                           │  Stremio Web (statisch)      │  │
│                           └──────────────┬───────────────┘  │
└──────────────────────────────────────────┼──────────────────┘
                                           │ LAN (WiFi/eth)
      ┌────────────────────────────────────┼─────────────────────────────┐
      │                                    │                             │
      ▼                                    ▼                             ▼
┌───────────┐                      ┌──────────────┐             ┌────────────────┐
│  iPhone   │                      │   Android    │             │  Samsung TV    │
│  Safari   │                      │   Chrome     │             │  Tizen Browser │
└─────┬─────┘                      └──────┬───────┘             └────────┬───────┘
      │                                    │                             │
      │  1. Load http://<ip>:8080          │                             │
      │  2. Addons & streams via API       │                             │
      │  3. Play URL = http://<ip>:11470/...                             │
      │                                                                  │
```

## Dataflow bij afspelen

1. **Client opent web-UI**: `GET http://<ip>:8080/` → Mac serveert Stremio Web (statisch).
2. **Metadata-fetch**: client haalt titels/posters bij **Cinemeta** (`v3-cinemeta.strem.io`) via de client zelf (gaat niet via Mac). Dit is TMDB-data.
3. **Stream-discovery**: client vraagt streams bij **Torrentio** (`torrentio.strem.fun`). Client → Torrentio API → lijst van magnet-links en embed-bronnen.
4. **Play-click**: client stuurt magnet-link naar Mac's streaming-server (`http://<ip>:11470/<endpoint>`).
5. **Mac trekt torrent binnen**: BitTorrent peer-exchange, downloadt stukjes naar lokale cache.
6. **Mac transmuxt/transcodeet**: ffmpeg zet torrent-chunks om in HLS-segmenten of een directe MP4-pseudo-stream.
7. **Client speelt**: HLS- of MP4-stream via HTTP naar client, native HTML5-video.

## Poorten overzicht

| Poort | Service              | Bind    | Doel                                     |
|-------|----------------------|---------|------------------------------------------|
| 11470 | Stremio HTTP server  | `*`     | Video + torrent-control + API            |
| 12470 | Stremio HTTPS server | `*`     | Idem, met self-signed cert               |
| 8080  | Python http.server   | `*`     | Statische Stremio Web-UI                 |

Firewall: open 8080 en 11470 inkomend voor je LAN (standaard al open op macOS).

## Caching

Standaard-cache is 2 GB in `~/Library/Application Support/stremio-server/stremio-cache/`. Films worden tijdens kijken daar neergezet; na afloop opgeruimd (of blijft, afhankelijk van `cacheSize`-setting). Verhoog naar 10 GB als je veel vooruitspoelt in grote films:

```bash
curl -X POST http://127.0.0.1:11470/settings \
  -H "Content-Type: application/json" \
  -d '{"cacheSize":10737418240}'
```

## Waarom Python's http.server (geen nginx/Caddy)

Omdat we statische bestanden serveren en Python al in macOS zit. Nul configuratie, nul dependencies. Voor meer verkeer (10+ clients) zou je naar Caddy of nginx moeten, maar voor huishoudgebruik is dit prima.

## Waarom poort 8080 en niet 80

Poorten onder 1024 vragen root-privileges op macOS. 8080 is de standaard voor "HTTP voor developers". De clients moeten dus `:8080` typen; ongemakkelijk maar niet dramatisch.

Alternatief: `pfctl` rule om 80 → 8080 door te zetten. Overkill.

## Externe afhankelijkheden

Deze setup leunt op drie externe diensten die buiten jouw Mac draaien:

- **Cinemeta** (`v3-cinemeta.strem.io`) — TMDB-metadata, officieel Stremio-project
- **Torrentio** (`torrentio.strem.fun`) — community-addon, geen officiële link met Stremio
- **TorrServer en BitTorrent trackers** — publieke infrastructuur

Val een van deze uit → betreffend deel werkt niet. Daarom werkt de setup niet 100% offline; metadata en stream-discovery vragen internet. Alleen het **afspelen** zelf is LAN-only.
