#!/usr/bin/env bash
# Stremio Thuis - automatische installer
# Lees LEGAL.md voor je dit runt.

set -eu

C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_RESET='\033[0m'

info()  { echo -e "${C_GREEN}▸${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
err()   { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
pause() { echo -e "${C_YELLOW}⏸${C_RESET} $*"; read -r -p "   Druk ENTER om door te gaan..."; }

INSTALL_DIR="$HOME/delta-work/stremio-thuis"
WEB_PORT=8080
SRV_PORT=11470

# ---------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------

info "Pre-flight checks..."
command -v brew >/dev/null || { err "Homebrew niet gevonden. Installeer eerst: https://brew.sh"; exit 1; }
command -v python3 >/dev/null || { err "python3 niet gevonden."; exit 1; }

LAN_IP="$(/sbin/ifconfig 2>/dev/null | awk '/inet /{if($2~/^(192\.168\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.)/){print $2;exit}}')"
if [[ -z "${LAN_IP:-}" ]]; then
  err "Kon geen lokaal LAN-IP vinden. Zorg dat je verbonden bent met je WiFi."
  exit 1
fi
info "LAN-IP gedetecteerd: $LAN_IP"

# ---------------------------------------------------------------------
# Stap 1: Stremio installeren
# ---------------------------------------------------------------------

if [[ -d /Applications/Stremio.app ]]; then
  info "Stremio al geïnstalleerd — skip brew install."
else
  info "Stremio installeren via Homebrew..."
  brew install --cask stremio
fi

# ---------------------------------------------------------------------
# Stap 2: Gatekeeper quarantine strippen
# ---------------------------------------------------------------------

if xattr /Applications/Stremio.app 2>/dev/null | grep -q quarantine; then
  info "Gatekeeper-quarantine verwijderen van Stremio.app..."
  xattr -r -d com.apple.quarantine /Applications/Stremio.app
fi

# ---------------------------------------------------------------------
# Stap 3: Stremio openen (handmatig)
# ---------------------------------------------------------------------

if ! curl -s --max-time 2 "http://127.0.0.1:$SRV_PORT/settings" >/dev/null; then
  info "Stremio openen..."
  open /Applications/Stremio.app
  pause "Klik 'Guest Login' in Stremio onderaan het inlogscherm. Laat Stremio open staan."

  for i in {1..10}; do
    if curl -s --max-time 2 "http://127.0.0.1:$SRV_PORT/settings" >/dev/null; then
      info "Streaming-server is up."
      break
    fi
    sleep 1
  done
fi

if ! curl -s --max-time 2 "http://127.0.0.1:$SRV_PORT/settings" >/dev/null; then
  err "Stremio streaming-server luistert niet op poort $SRV_PORT."
  err "Open Stremio handmatig, kom voorbij de login (Guest), en run dit script opnieuw."
  exit 1
fi

# ---------------------------------------------------------------------
# Stap 4: Torrentio-addon installeren
# ---------------------------------------------------------------------

info "Torrentio-addon dialoog triggeren in Stremio..."
open "stremio://torrentio.strem.fun/providers=yts,eztv,rarbg,1337x,thepiratebay,torrentgalaxy,magnetdl,horriblesubs,nyaasi%7Cqualityfilter=cam,scr,unknown%7Csort=qualitythensize/manifest.json"
pause "Klik in Stremio op 'Install' in het dialoogje. Daarna doorgaan."

# ---------------------------------------------------------------------
# Stap 5: Server tunen
# ---------------------------------------------------------------------

info "Transcoding + concurrency aanzetten via server-API..."
TRANSCODE_PROFILES=$(curl -s "http://127.0.0.1:$SRV_PORT/settings" | python3 -c "import json,sys;print(','.join(json.load(sys.stdin)['values'].get('allTranscodeProfiles',[])))")
if [[ "$TRANSCODE_PROFILES" == *"videotoolbox"* ]]; then
  PROFILE="videotoolbox"
  HWACCEL="true"
elif [[ -n "$TRANSCODE_PROFILES" ]]; then
  PROFILE="${TRANSCODE_PROFILES%%,*}"
  HWACCEL="false"
  warn "Geen videotoolbox beschikbaar, gebruik '$PROFILE' zonder hardware-accel."
else
  PROFILE="null"
  HWACCEL="false"
  warn "Geen transcode-profiles beschikbaar; transcoding wordt uitgeschakeld."
fi

if [[ "$PROFILE" == "null" ]]; then
  curl -s -X POST "http://127.0.0.1:$SRV_PORT/settings" \
    -H "Content-Type: application/json" \
    -d "{\"proxyStreamsEnabled\":true,\"transcodeConcurrency\":2,\"transcodeTrackConcurrency\":2}" >/dev/null
else
  curl -s -X POST "http://127.0.0.1:$SRV_PORT/settings" \
    -H "Content-Type: application/json" \
    -d "{\"transcodeProfile\":\"$PROFILE\",\"transcodeHardwareAccel\":$HWACCEL,\"proxyStreamsEnabled\":true,\"transcodeMaxWidth\":1920,\"transcodeConcurrency\":2,\"transcodeTrackConcurrency\":2}" >/dev/null
fi
info "Server-config bijgewerkt."

# ---------------------------------------------------------------------
# Stap 6: Stremio Web zelf hosten
# ---------------------------------------------------------------------

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [[ ! -f web/build/index.html ]]; then
  info "Stremio Web pre-built downloaden..."
  LATEST_URL=$(curl -sL https://api.github.com/repos/Stremio/stremio-web/releases/latest | python3 -c "import json,sys;[print(a['browser_download_url']) for a in json.load(sys.stdin)['assets'] if a['name'].endswith('.zip')]" | head -1)
  if [[ -z "$LATEST_URL" ]]; then
    err "Kon geen Stremio Web release-asset vinden."
    exit 1
  fi
  curl -sL -o stremio-web.zip "$LATEST_URL"
  unzip -q -o stremio-web.zip -d web/
  rm stremio-web.zip
fi

info "Stremio Web webserver starten op poort $WEB_PORT..."
pkill -f "http.server $WEB_PORT" 2>/dev/null || true
sleep 1
cd web/build
nohup python3 -m http.server "$WEB_PORT" --bind 0.0.0.0 > /tmp/stremio-web.log 2>&1 &
disown
sleep 2

if ! curl -sI --max-time 3 "http://127.0.0.1:$WEB_PORT/" | head -1 | grep -q "200"; then
  err "Web-UI start niet. Zie /tmp/stremio-web.log."
  exit 1
fi

# ---------------------------------------------------------------------
# Klaar
# ---------------------------------------------------------------------

cat <<EOF

${C_GREEN}✓ Installatie klaar.${C_RESET}

Open op elk apparaat in je huis (zelfde WiFi als deze Mac):

   ${C_YELLOW}http://${LAN_IP}:${WEB_PORT}${C_RESET}

Daar: Guest Login → eventueel Torrentio installeren via de addon-pagina.
In Settings → Streaming Server URL: ${C_YELLOW}http://${LAN_IP}:${SRV_PORT}/${C_RESET}

Tips:
- Werkt alleen thuis op dit WiFi.
- Laat Stremio desktop en Terminal open; of volg README.md voor permanente launchd-setup.
- iOS Safari fullscreen zonder geluid? Kies een YTS-release. Zie TROUBLESHOOTING.md.

Veel plezier.
EOF
