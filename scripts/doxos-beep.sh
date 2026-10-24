#!/bin/bash
# ==============================================================================
# DOXos - 3-Beep Boot Notification
# "those who dare"
# ==============================================================================

WAV_PATH="/usr/share/sounds/doxos/doxos-beep.wav"

play_pc_speaker() {
    # Attempt PC speaker hardware beeps if driver is present
    modprobe pcspkr 2>/dev/null || true
    if command -v beep >/dev/null 2>&1; then
        beep -f 880 -l 80 -D 50 -r 3 2>/dev/null &
    else
        # Fallback to TTY bell
        for tty in /dev/tty0 /dev/console; do
            if [ -w "$tty" ]; then
                echo -en "\a" > "$tty" 2>/dev/null; sleep 0.08
                echo -en "\a" > "$tty" 2>/dev/null; sleep 0.08
                echo -en "\a" > "$tty" 2>/dev/null
                break
            fi
        done
    fi
}

play_audio() {
    # Try PipeWire / PulseAudio / ALSA players
    if [ -f "$WAV_PATH" ]; then
        if command -v pw-play >/dev/null 2>&1; then
            pw-play "$WAV_PATH" 2>/dev/null && return 0
        fi
        if command -v paplay >/dev/null 2>&1; then
            paplay "$WAV_PATH" 2>/dev/null && return 0
        fi
        if command -v aplay >/dev/null 2>&1; then
            aplay -q "$WAV_PATH" 2>/dev/null && return 0
        fi
    fi

    # Fallback synthesizer if no wav player succeeded: speaker-test tone burst
    if command -v speaker-test >/dev/null 2>&1; then
        for i in 1 2 3; do
            speaker-test -t sine -f 880 -l 1 >/dev/null 2>&1 &
            P=$!
            sleep 0.08
            kill -9 $P 2>/dev/null || true
            sleep 0.05
        done
        return 0
    fi
    return 1
}

# Run both in background to ensure notification sounds regardless of audio device
play_audio &
play_pc_speaker &
wait
exit 0
