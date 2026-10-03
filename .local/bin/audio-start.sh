#!/bin/sh

# Wait up to 60 seconds for a PipeWire port matching $1
wait_for() {
  for i in $(seq 1 60); do
    pw-link -io 2>/dev/null | grep -q "$1" && return 0
    sleep 1
  done
  return 1
}

# 1. OpenWave first, so its mic node exists
openwave --hide &
wait_for "openwave_fx"

# 2. Carla with the saved chain (Wine plugins load slowly)
pw-jack carla --no-gui "/mnt/seagate/!! Drivers - Importante/!! cachy/carla/brutal.carxp" &
wait_for "Carla:audio-in1"

# 3. Restore the links
qpwgraph --minimized --activate "$HOME/.config/qpwgraph/patchbay.qpwgraph" &

# 4. Make the processed mic the default input
sleep 3
pactl set-default-source elgato_wave3_vst2

pactl set-source-mute alsa_input.usb-Elgato_Systems_Elgato_Wave_3_BS01K1A00047-00.mono-fallback 1
