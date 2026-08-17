#!/usr/bin/env bash
# Streame les logs de l'iPhone. Filtre sur Vigie par défaut.
# Usage: ./logs.sh [motif]   ·   ./logs.sh --all pour tout voir
set -uo pipefail

command -v idevicesyslog >/dev/null || { echo "idevicesyslog absent (paquet libimobiledevice)" >&2; exit 1; }
idevice_id -l 2>/dev/null | grep -q . || { echo "aucun iPhone détecté" >&2; exit 1; }

if [ "${1:-}" = "--all" ]; then
    exec idevicesyslog
fi
exec idevicesyslog -m "${1:-Vigie}"
