#!/usr/bin/env bash
# DukPearl installer for a Debian/Ubuntu VPS — no Docker.
# Installs Bun, PostgreSQL and Redis, asks a few questions, and runs DukPearl
# as a system service that starts on boot. Safe to run again after `git pull`.
set -euo pipefail
cd "$(dirname "$0")"
DIR=$(pwd)
SVC_USER=dukpearl
SVC_HOME=/var/lib/dukpearl

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
# Run a command silently; show its output only if it fails.
quiet() { local out; out=$("$@" 2>&1) || { printf '%s\n' "$out" >&2; fail "That step failed (see above)."; }; }
as_svc() { runuser -u "$SVC_USER" -- env HOME="$SVC_HOME" "$@"; }

[ "$(id -u)" = 0 ] || fail "Run this as root:  sudo ./install.sh"
command -v apt-get >/dev/null 2>&1 || fail "This installer supports Debian and Ubuntu. On other systems use Docker: ./setup.sh"
command -v systemctl >/dev/null 2>&1 || fail "systemd is required. On other systems use Docker: ./setup.sh"

# ─── Packages ────────────────────────────────────────────────────────────────

say "Installing PostgreSQL, Redis and tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl git unzip postgresql redis-server >/dev/null
systemctl enable --now postgresql redis-server >/dev/null 2>&1

if [ ! -x /usr/local/bin/bun ]; then
	say "Installing Bun..."
	curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash >/dev/null 2>&1 \
		|| fail "Could not install Bun. See https://bun.sh/docs/installation"
fi

# ─── Service user ────────────────────────────────────────────────────────────

id "$SVC_USER" >/dev/null 2>&1 || useradd --system --create-home --home-dir "$SVC_HOME" --shell /usr/sbin/nologin "$SVC_USER"
mkdir -p "$SVC_HOME/minecraft"
chown -R "$SVC_USER:$SVC_USER" "$SVC_HOME" "$DIR"
as_svc test -r "$DIR/package.json" 2>/dev/null \
	|| fail "The '$SVC_USER' service user cannot read $DIR (folders under /root are private). Move this folder to /opt/dukpearl and run the installer again."
git config --system --get-all safe.directory 2>/dev/null | grep -qxF "$DIR" || git config --system --add safe.directory "$DIR"

# ─── Settings ────────────────────────────────────────────────────────────────

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

get_env() { grep -E "^$1=" .env 2>/dev/null | tail -1 | cut -d= -f2- || true; }

if [ ! -f .env ] || [ -z "$(get_env MC_USERNAME)" ] || [ "$(get_env MC_USERNAME)" = YourBotAccount ]; then
	[ -f .env ] || cp .env.example .env
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
else
	say "Keeping the settings already in .env"
fi

# ─── Database ────────────────────────────────────────────────────────────────

if [ -z "$(get_env DATABASE_URL)" ]; then
	say "Creating the database..."
	db_pass=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')
	pg() { runuser -u postgres -- psql -v ON_ERROR_STOP=1 -qtAc "$1"; }
	if [ "$(pg "SELECT 1 FROM pg_roles WHERE rolname='dukpearl'")" = 1 ]; then
		pg "ALTER ROLE dukpearl LOGIN PASSWORD '$db_pass'"
	else
		pg "CREATE ROLE dukpearl LOGIN PASSWORD '$db_pass'"
	fi
	[ "$(pg "SELECT 1 FROM pg_database WHERE datname='dukpearl'")" = 1 ] || pg "CREATE DATABASE dukpearl OWNER dukpearl"
	set_env DATABASE_URL "postgresql://dukpearl:$db_pass@127.0.0.1:5432/dukpearl"
fi
[ -n "$(get_env REDIS_URL)" ] || set_env REDIS_URL "redis://127.0.0.1:6379"
[ -n "$(get_env MC_PROFILE)" ] || set_env MC_PROFILE "$SVC_HOME/minecraft"
chown "$SVC_USER:$SVC_USER" .env
chmod 600 .env

# ─── App ─────────────────────────────────────────────────────────────────────

say "Installing dependencies (this can take a minute)..."
quiet as_svc /usr/local/bin/bun install --frozen-lockfile
quiet as_svc /usr/local/bin/bun run generate

cat > /etc/systemd/system/dukpearl.service <<UNIT
[Unit]
Description=DukPearl Minecraft stasis proxy
After=network-online.target postgresql.service redis-server.service
Wants=network-online.target postgresql.service redis-server.service

[Service]
User=$SVC_USER
WorkingDirectory=$DIR
Environment=HOME=$SVC_HOME
ExecStart=/usr/local/bin/bun start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable dukpearl >/dev/null 2>&1
systemctl restart dukpearl

port=$(get_env PROXY_PORT)
cat <<MSG

DukPearl is running as a service and will start on boot.

  1. First run only: a Microsoft sign-in link and code appear in the log below.
     Open the link, enter the code, and sign in as the bot account.
  2. Then add a server in Minecraft with the address  <this server's IP>:${port:-25577}
     and join with the bot account. If you use a firewall, open that port:
       ufw allow ${port:-25577}/tcp

Showing the log now. Press Ctrl+C to stop watching; DukPearl keeps running.
  Log:      journalctl -u dukpearl -f
  Restart:  systemctl restart dukpearl
  Stop:     systemctl stop dukpearl
  Update:   git pull && ./install.sh

MSG
[ "${DUKPEARL_NO_LOGS:-}" = 1 ] || exec journalctl -u dukpearl -f -n 50
