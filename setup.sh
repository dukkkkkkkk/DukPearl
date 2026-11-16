#!/usr/bin/env bash
# DukPearl guided setup: asks a few questions, writes .env, starts everything,
# then shows the Microsoft sign-in code.
set -euo pipefail
cd "$(dirname "$0")"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || fail "Docker is not installed. Get it from https://docs.docker.com/get-docker/"
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is missing. Update Docker, or install the compose plugin."
docker info >/dev/null 2>&1 || fail "Docker is installed but not running (or you lack permission). Start Docker and try again."

# Ask a question with a default; the answer lands in the variable named by $1.
ask() {
	local var=$1 prompt=$2 default=${3-} answer
	if [ -n "$default" ]; then read -r -p "$prompt [$default]: " answer || true
	else read -r -p "$prompt: " answer || true
	fi
	printf -v "$var" '%s' "${answer:-$default}"
}

# Set KEY=value in .env, replacing an existing (or commented-out) line.
set_env() {
	local key=$1 value=$2 tmp
	tmp=$(mktemp)
	awk -v k="$key" -v v="$value" '
		!done && $0 ~ "^#?[[:space:]]*" k "=" { print k "=" v; done = 1; next }
		{ print }
		END { if (!done) print k "=" v }
	' .env > "$tmp"
	cat "$tmp" > .env
	rm -f "$tmp"
}

write_env=yes
if [ -f .env ]; then
	ask reuse "Found an existing .env. Keep it as it is? (y/n)" "y"
	case "$reuse" in [nN]*) ;; *) write_env=no ;; esac
fi

if [ "$write_env" = yes ]; then
	[ -f .env ] || cp .env.example .env
	chmod 600 .env

	ask mc_host "Minecraft server to join (host or host:port)" "2b2t.org"
	mc_user=""
	until [[ "$mc_user" =~ ^[A-Za-z0-9_]{3,16}$ ]]; do
		ask mc_user "In-game name of the bot's Microsoft account"
		[[ "$mc_user" =~ ^[A-Za-z0-9_]{3,16}$ ]] || echo "  That is not a valid Minecraft name (3-16 letters, digits or _)."
	done
	ask mc_version "Minecraft version" "1.20.1"
	ask discord "Discord bot token (optional, press Enter to skip)"

	set_env MC_HOST "$mc_host"
	set_env MC_USERNAME "$mc_user"
	set_env MC_VERSION "$mc_version"
	[ -z "$discord" ] || set_env DISCORD_BOT_TOKEN "$discord"
	say "Saved your settings to .env"
fi

[ "${DUKPEARL_SKIP_START:-}" = 1 ] && exit 0

say "Building and starting DukPearl (the first build takes a few minutes)..."
docker compose up -d --build

port=$(grep -E '^PROXY_PORT=' .env | tail -1 | cut -d= -f2 || true)
cat <<MSG

DukPearl is starting.

  1. First run only: a Microsoft sign-in link and code appear in the log below.
     Open the link, enter the code, and sign in as the bot account.
  2. Then add a server in Minecraft with the address  localhost:${port:-25577}
     and join with the bot account (or whitelist others with /whitelist add <name>).

Showing the log now. Press Ctrl+C to stop watching; DukPearl keeps running.
  Stop:    docker compose down
  Update:  git pull && docker compose up -d --build

MSG
exec docker compose logs -f dukpearl
