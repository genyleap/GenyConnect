#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-squashfs-root}"

HELPER="$(find "${ROOT}" -type f -name GenyConnectTunHelper -print -quit)"
QT_CORE="$(find "${ROOT}" -name 'libQt6Core.so.6' -print -quit)"
if [[ -z "${HELPER}" || -z "${QT_CORE}" ]]; then
  echo "TUN helper or bundled Qt Core library is missing from ${ROOT}." >&2
  exit 1
fi

QT_LIB_DIR="$(dirname "${QT_CORE}")"
STAGE_DIR="$(mktemp -d)"
STAGED_HELPER="${STAGE_DIR}/GenyConnectTunHelper"
HELPER_PID=""

cleanup() {
  if [[ -n "${HELPER_PID}" ]]; then
    kill "${HELPER_PID}" 2>/dev/null || true
    wait "${HELPER_PID}" 2>/dev/null || true
  fi
  rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

# Copying the helper away from usr/bin deliberately breaks its $ORIGIN/../lib
# RUNPATH and reproduces the runtime staging used before pkexec elevation.
cp "${HELPER}" "${STAGED_HELPER}"
chmod +x "${STAGED_HELPER}"

if [[ -n "${GENYCONNECT_HELPER_TEST_PORT:-}" ]]; then
  PORT="${GENYCONNECT_HELPER_TEST_PORT}"
else
  PORT="$(python3 - <<'PY'
import socket

with socket.socket() as probe:
    probe.bind(("127.0.0.1", 0))
    print(probe.getsockname()[1])
PY
  )"
fi
TOKEN="genyconnect-helper-regression"

env -u APPDIR \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  LD_LIBRARY_PATH="${QT_LIB_DIR}" \
  "${STAGED_HELPER}" \
    --listen-port "${PORT}" \
    --token "${TOKEN}" \
    --idle-timeout-ms 30000 \
    >"${STAGE_DIR}/stdout.log" \
    2>"${STAGE_DIR}/stderr.log" &
HELPER_PID="$!"

connected=0
for _ in {1..50}; do
  if { exec 3<>"/dev/tcp/127.0.0.1/${PORT}"; } 2>/dev/null; then
    connected=1
    break
  fi
  if ! kill -0 "${HELPER_PID}" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ "${connected}" -ne 1 ]]; then
  echo "Staged TUN helper did not open its control port." >&2
  cat "${STAGE_DIR}/stderr.log" >&2
  exit 1
fi

printf '{"action":"ping","token":"%s"}\n' "${TOKEN}" >&3
IFS= read -r reply <&3
if [[ "${reply}" != *'"ok":true'* || "${reply}" != *'"message":"pong"'* ]]; then
  echo "Staged TUN helper returned an unexpected response: ${reply}" >&2
  exit 1
fi

echo "Staged TUN helper runtime validation passed."
