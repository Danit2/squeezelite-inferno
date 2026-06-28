# squeezelite-inferno

One Docker container provides one Squeezelite player and one Inferno Dante transmitter.

## Concept

```text
Lyrion Music Server
        ↓
Squeezelite
        ↓
ALSA mono downmix
        ↓
Inferno ALSA plugin
        ↓
Dante TX, 1 channel
