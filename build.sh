#!/usr/bin/env bash
# Compile Vigie et produit xtool/Vigie.ipa (non signé).
set -euo pipefail

cd "$(dirname "$0")"

. "$HOME/.local/share/swiftly/env.sh"
export LD_LIBRARY_PATH="$HOME/.local/lib:${LD_LIBRARY_PATH:-}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '\033[36m▸\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!\033[0m %s\n' "$1" >&2; }
die() { printf '\033[31m✗\033[0m %s\n' "$1" >&2; exit 1; }

command -v xtool >/dev/null || die "xtool introuvable dans le PATH"
swift sdk list 2>/dev/null | grep -q darwin || die "SDK Darwin non installé — voir README §5"

# L'Info.plist effectif est généré, jamais suivi : `Info.template.plist` porte
# des adresses d'exemple, et les vraies vivent dans `.env.local` (non suivi).
# Sans `.env.local`, le build reste valide — l'adresse se saisit alors dans les
# Réglages de l'application.
generer_plist() {
    local tunnel="https://vigie.example.com" lan="http://vigie.local:8766"
    if [ -f .env.local ]; then
        # shellcheck disable=SC1091
        . ./.env.local
        tunnel="${VIGIE_TUNNEL:-$tunnel}"
        lan="${VIGIE_LAN:-$lan}"
    else
        warn "pas de .env.local — adresses d'exemple embarquées (voir .env.example)"
    fi
    mkdir -p .build
    python3 - "$tunnel" "$lan" <<'SUBST' || die "génération de l'Info.plist impossible"
import pathlib, sys
tunnel, lan = sys.argv[1], sys.argv[2]
s = pathlib.Path("Info.template.plist").read_text()
s = s.replace("https://vigie.example.com", tunnel).replace("http://vigie.local:8766", lan)
pathlib.Path(".build/Info.plist").write_text(s)
SUBST
}

generer_plist

log "Compilation ($(swift --version 2>/dev/null | head -1))"
xtool dev build --ipa "$@" || die "échec de la compilation"

IPA="xtool/Vigie.ipa"
[ -f "$IPA" ] || die "IPA non produit"
log "IPA prêt : $(pwd)/$IPA ($(du -h "$IPA" | cut -f1))"
