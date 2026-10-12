#! /usr/bin/env bash
# android-webcam.sh — manage Android-as-webcam via scrcpy + v4l2loopback
#
# Usage:
#   android-webcam.sh status [--node /dev/video10]
#   android-webcam.sh ensure-module [--node /dev/video10]
#   android-webcam.sh start [--facing back|front] [--size WxH] [--node /dev/video10]
#   android-webcam.sh stop [--node /dev/video10]
#   android-webcam.sh toggle [--facing ...] [--size ...] [--node ...]
#
# status prints key=value lines: active, module, device, pid
# Exit codes: 0 ok, 2 missing dependency, 3 need sudo setup (NEED_SETUP),
#             4 start failed (e.g. no device connected)

set -u

NODE="/dev/video10"
FACING="back"
SIZE="1920x1080"
CMD="status"

while [[ $# -gt 0 ]]; do
  case "$1" in
  start | stop | status | toggle | ensure-module)
    CMD="$1"
    shift
    ;;
  --facing)
    FACING="${2:-back}"
    shift 2
    ;;
  --size)
    SIZE="${2:-1920x1080}"
    shift 2
    ;;
  --node)
    NODE="${2:-/dev/video10}"
    shift 2
    ;;
  *) shift ;;
  esac
done

# Derive video_nr from node name (/dev/video10 -> 10), fallback to 10
NR="$(basename "$NODE" | grep -o '[0-9]*$' || true)"
[[ -z "$NR" ]] && NR="10"

is_active() { pgrep -f "[s]crcpy.*v4l2-sink=${NODE}" >/dev/null 2>&1; }
has_module() { lsmod 2>/dev/null | grep -q "^v4l2loopback"; }
has_device() { [[ -e "$NODE" ]]; }

active_pid() { pgrep -f "[s]crcpy.*v4l2-sink=${NODE}" 2>/dev/null | head -n 1; }

# Load module without ever prompting for a password.
# Uses `sudo -n` (non-interactive). If that fails, the user must run
# scripts/setup-v4l2loopback-nopasswd.sh once — we never store passwords.
ensure_module() {
  if has_module && has_device; then
    return 0
  fi
  if sudo -n modprobe v4l2loopback "video_nr=${NR}" 'card_label=Android Webcam' exclusive_caps=1 2>/dev/null; then
    sleep 0.5
    has_device && return 0
  fi
  echo "NEED_SETUP"
  return 3
}

cmd_status() {
  local active="false" module="false" device="false" pid=""
  is_active && active="true"
  has_module && module="true"
  has_device && device="true"
  pid="$(active_pid || true)"
  echo "active=${active}"
  echo "module=${module}"
  echo "device=${device}"
  echo "pid=${pid}"
  echo "node=${NODE}"
}

cmd_start() {
  if ! command -v scrcpy >/dev/null 2>&1; then
    echo "MISSING_SCRCPY"
    return 2
  fi
  ensure_module || return 3
  if is_active; then
    echo "ALREADY_ACTIVE"
    return 0
  fi
  # Torch is always on (fixed), no playback window, no audio.
  setsid scrcpy --video-source=camera --camera-facing="$FACING" \
    --camera-size="$SIZE" --v4l2-sink="$NODE" \
    --no-playback --no-audio --camera-torch \
    >/dev/null 2>&1 </dev/null &
  sleep 1.5
  if is_active; then
    echo "STARTED"
    return 0
  fi
  echo "START_FAILED"
  return 4
}

cmd_stop() {
  if ! is_active; then
    echo "ALREADY_STOPPED"
    return 0
  fi
  pkill -f "scrcpy.*v4l2-sink=${NODE}" 2>/dev/null || true
  sleep 0.5
  if is_active; then
    pkill -9 -f "scrcpy.*v4l2-sink=${NODE}" 2>/dev/null || true
    sleep 0.5
  fi
  is_active && {
    echo "STOP_FAILED"
    return 4
  }
  echo "STOPPED"
  return 0
}

case "$CMD" in
status) cmd_status ;;
ensure-module) ensure_module ;;
start) cmd_start ;;
stop) cmd_stop ;;
toggle) if is_active; then cmd_stop; else cmd_start; fi ;;
esac
