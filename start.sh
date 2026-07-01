#!/bin/sh
set -eu

: "${TZ:=Europe/Zurich}"

: "${LMS_SERVER:=127.0.0.1}"
: "${LMS_PORT:=3483}"

: "${PLAYER_NAME:=Player1}"
: "${PLAYER_MAC:=02:00:00:00:10:01}"
: "${OUTPUT_DEVICE:=dante}"
: "${ALSA_PARAMS:=80:4:32:0:0}"

# Alte und neue Variablennamen unterstützen
DANTE_NAME="${DANTE_NAME:-${INFERNO_NAME:-${PLAYER_NAME}}}"
BIND_IP="${BIND_IP:-${INFERNO_BIND_IP:-}}"
SAMPLE_RATE="${SAMPLE_RATE:-${INFERNO_SAMPLE_RATE:-48000}}"
TX_CHANNELS="${TX_CHANNELS:-${INFERNO_TX_CHANNELS:-1}}"
RX_CHANNELS="${RX_CHANNELS:-${INFERNO_RX_CHANNELS:-0}}"
PROCESS_ID="${PROCESS_ID:-${INFERNO_PROCESS_ID:-1}}"
ALT_PORT="${ALT_PORT:-${INFERNO_ALT_PORT:-14000}}"
CLOCK_PATH="${CLOCK_PATH:-${INFERNO_CLOCK_PATH:-${CLOCK_SOCKET:-/shared/usrvclock}}}"
TMPDIR="${TMPDIR:-/shared/tmp_${PROCESS_ID}}"
CLOCK_STARTUP_DELAY="${CLOCK_STARTUP_DELAY:-20}"
TX_LATENCY_NS="${TX_LATENCY_NS:-${INFERNO_TX_LATENCY_NS:-10000000}}"
RX_LATENCY_NS="${RX_LATENCY_NS:-${INFERNO_RX_LATENCY_NS:-10000000}}"
DEVICE_ID="${DEVICE_ID:-${INFERNO_DEVICE_ID:-}}"
WAIT_FOR_CLOCK="${WAIT_FOR_CLOCK:-true}"

if [ -z "${BIND_IP}" ]; then
    echo "FEHLER: BIND_IP oder INFERNO_BIND_IP ist nicht gesetzt."
    exit 1
fi

DEVICE_ID_LINE=""
if [ -n "${DEVICE_ID}" ]; then
    DEVICE_ID_LINE="    DEVICE_ID \"${DEVICE_ID}\""
fi

echo "Erzeuge /etc/asound.conf..."
cat > /etc/asound.conf <<EOF
pcm.dante {
    type plug
    slave.pcm "dante_mono"

    hint {
        show on
        description "Mono Dante output via Inferno"
    }
}

pcm.dante_mono {
    type route
    slave.pcm "inferno_raw"
    slave.channels 1

    # Stereo L/R zu Mono mischen
    ttable.0.0 0.5
    ttable.1.0 0.5
}

pcm.inferno_raw {
    type inferno

    NAME "${DANTE_NAME}"
    SAMPLE_RATE "${SAMPLE_RATE}"

    TX_CHANNELS ${TX_CHANNELS}
    RX_CHANNELS ${RX_CHANNELS}

    BIND_IP "${BIND_IP}"
${DEVICE_ID_LINE}
    PROCESS_ID ${PROCESS_ID}
    ALT_PORT ${ALT_PORT}

    CLOCK_PATH "${CLOCK_PATH}"

    TX_LATENCY_NS ${TX_LATENCY_NS}
    RX_LATENCY_NS ${RX_LATENCY_NS}

    hint {
        show on
        description "Raw Inferno Dante PCM"
    }
}
EOF

echo "Verwendete /etc/asound.conf:"
cat /etc/asound.conf

echo "Player Name: ${PLAYER_NAME}"
echo "Player MAC: ${PLAYER_MAC}"
echo "LMS Server: ${LMS_SERVER}:${LMS_PORT}"
echo "Dante Name: ${DANTE_NAME}"
echo "Bind IP/Interface: ${BIND_IP}"
echo "TX Channels: ${TX_CHANNELS}"
echo "RX Channels: ${RX_CHANNELS}"
echo "Process ID: ${PROCESS_ID}"
echo "ALT Port: ${ALT_PORT}"
echo "Clock Path: ${CLOCK_PATH}"

mkdir -p "${TMPDIR}"
rm -f "${TMPDIR}"/usrvclock-client.* 2>/dev/null || true

if [ "${WAIT_FOR_CLOCK}" = "true" ]; then

 echo "Warte auf Clock-Socket: ${CLOCK_PATH}"

 while [ ! -S "${CLOCK_PATH}" ]; do

  echo "warte auf ${CLOCK_PATH}..."

  sleep 1

 done

 echo "Clock-Socket gefunden: ${CLOCK_PATH}"

 ls -la "${CLOCK_PATH}" || true

 echo "Warte ${CLOCK_STARTUP_DELAY}s auf PTP-Sync..."

 sleep "${CLOCK_STARTUP_DELAY}"

fi

exec squeezelite \
    -s "${LMS_SERVER}:${LMS_PORT}" \
    -n "${PLAYER_NAME}" \
    -m "${PLAYER_MAC}" \
    -o "${OUTPUT_DEVICE}" \
    -r "${SAMPLE_RATE}" \
    -a "${ALSA_PARAMS}" \
    -p 45 \
    -d all=info
