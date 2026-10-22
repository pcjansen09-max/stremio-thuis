#!/usr/bin/env bash
# Zet Stremio streaming-server op de juiste settings voor LAN-afspelen.
# Draai dit nadat Stremio desktop is geopend en de server luistert.

set -eu
SRV="http://127.0.0.1:11470"

# Check of server bereikbaar is
if ! curl -s --max-time 3 "$SRV/settings" >/dev/null; then
  echo "Stremio streaming-server niet bereikbaar op $SRV. Open Stremio desktop eerst."
  exit 1
fi

# Pak beschikbare transcode-profile
PROFILE=$(curl -s "$SRV/settings" | python3 -c "import json,sys;p=json.load(sys.stdin)['values'].get('allTranscodeProfiles',[]);print(p[0] if p else '')")
HWACCEL="false"
[[ "$PROFILE" == "videotoolbox" ]] && HWACCEL="true"

if [[ -z "$PROFILE" ]]; then
  PAYLOAD='{"proxyStreamsEnabled":true,"transcodeConcurrency":2,"transcodeTrackConcurrency":2}'
else
  PAYLOAD=$(cat <<JSON
{
  "transcodeProfile": "$PROFILE",
  "transcodeHardwareAccel": $HWACCEL,
  "proxyStreamsEnabled": true,
  "transcodeMaxWidth": 1920,
  "transcodeConcurrency": 2,
  "transcodeTrackConcurrency": 2
}
JSON
)
fi

echo "Toe te passen:"
echo "$PAYLOAD"
echo ""

RESULT=$(curl -s -X POST "$SRV/settings" -H "Content-Type: application/json" -d "$PAYLOAD")
echo "Server-respons: $RESULT"

echo ""
echo "Huidige stand:"
curl -s "$SRV/settings" | python3 -c "
import json,sys
v = json.load(sys.stdin)['values']
for k in ['transcodeProfile','transcodeHardwareAccel','proxyStreamsEnabled','transcodeMaxWidth','transcodeConcurrency','transcodeTrackConcurrency']:
    print(f'  {k}: {v.get(k)}')
"
