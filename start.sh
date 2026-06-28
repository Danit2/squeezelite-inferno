#!/bin/sh
set -eu

: "${LMS_SERVER:=127.0.0.1}"
: "${LMS_PORT:=9000}"
: "${PLAYER_NAME:=Dante-Mono}"
: "${PLAYER_MAC:=02:00:00:00:10:01}"
: "${OUTPUT_DEVICE:=dante}"
: "${SAMPLE_RATE:=48000}"
: "${ALSA_PARAMS:=80:4:32:0:0}"
: "${CLOCK_SOCKET:=/tmp/usrvclock.sock}"
: "${WAIT_FOR_CLOCK:=true}"

# Inferno Defaults aus Player-Werten ableiten,
# falls sie nicht explizit per Docker gesetzt wurden.
MAC_HEX="$(echo "${PLAYER_MAC}" | tr -d ':' | tr '[:lower:]' '[:upper:]')"
MAC_LAST4="$(echo "${MAC_HEX}" | sed 's/.*\(....\)$/\1/')"
DERIVED_PROCESS_ID="$(printf "%d" "0x${MAC_LAST4}")"

export INFERNO_NAME="${INFERNO_NAME:-${PLAYER_NAME}}"
export INFERNO_SAMPLE_RATE="${INFERNO_SAMPLE_RATE:-${SAMPLE_RATE}}"
export INFERNO_TX_CHANNELS="${INFERNO_TX_CHANNELS:-1}"
export INFERNO_RX_CHANNELS="${INFERNO_RX_CHANNELS:-0}"
export INFERNO_DEVICE_ID="${INFERNO_DEVICE_ID:-0000${MAC_HEX}}"
export INFERNO_PROCESS_ID="${INFERNO_PROCESS_ID:-${DERIVED_PROCESS_ID}}"
export INFERNO_CLOCK_PATH="${INFERNO_CLOCK_PATH:-${CLOCK_SOCKET}}"
export INFERNO_TX_LATENCY_NS="${INFERNO_TX_LATENCY_NS:-10000000}"
export INFERNO_RX_LATENCY_NS="${INFERNO_RX_LATENCY_NS:-10000000}"

echo "Player Name: ${PLAYER_NAME}"
echo "Player MAC: ${PLAYER_MAC}"
echo "LMS Server: ${LMS_SERVER}:${LMS_PORT}"
echo "ALSA Output: ${OUTPUT_DEVICE}"
echo "Inferno Name: ${INFERNO_NAME}"
echo "Inferno TX Channels: ${INFERNO_TX_CHANNELS}"
echo "Inferno RX Channels: ${INFERNO_RX_CHANNELS}"
echo "Inferno Device ID: ${INFERNO_DEVICE_ID}"
echo "Inferno Process ID: ${INFERNO_PROCESS_ID}"
echo "Inferno ALT Port: ${INFERNO_ALT_PORT:-not set}"
echo "Inferno Bind IP/Interface: ${INFERNO_BIND_IP:-not set}"
echo "Clock Socket: ${INFERNO_CLOCK_PATH}"

if [ "${WAIT_FOR_CLOCK}" = "true" ]; then
    echo "Warte auf Clock-Socket: ${INFERNO_CLOCK_PATH}"

    while [ ! -e "${INFERNO_CLOCK_PATH}" ]; do
        sleep 1
    done

    echo "Clock-Socket gefunden."
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
