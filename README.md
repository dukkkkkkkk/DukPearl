# DukPearl

**A self-hosted Minecraft stasis chamber proxy.**

DukPearl keeps a bot account online at your stasis chambers and pulls players' pearls on request, from in-game chat (`!load`) or Discord. You can also join through it with your own client to play as the bot. It comes with in-game holograms, a Discord bot, multi-bot clustering over Redis, and pearl storage in Postgres.

DukPearl is a fork of [StasisProxy](https://github.com/StasisCo/StasisProxy) by StasisCo, with a simpler setup.

## Quick start

You need [Docker](https://docs.docker.com/get-docker/) and a Minecraft (Microsoft) account for the bot. That's it — Postgres and Redis are started for you.

```bash
git clone https://github.com/dukkkkkkkk/DukPearl.git
```

```bash
cd DukPearl
```

```bash
./setup.sh
```

The script asks for the server and the bot's in-game name, starts everything, and shows the log.

**First run only:** the log prints a Microsoft link and a code. Open the link, enter the code, and sign in as the bot account. The login is remembered after that.

Then add a server in Minecraft with the address `localhost:25577` and join with the bot account.

### Windows, or without the script

Copy `.env.example` to `.env`, set `MC_HOST` and `MC_USERNAME` in it, then run:

```bash
docker compose up -d --build
```

```bash
docker compose logs -f dukpearl
```

## Everyday commands

| What | Command |
| --- | --- |
| Watch the log | `docker compose logs -f dukpearl` |
| Stop | `docker compose down` |
| Start again | `docker compose up -d` |
| Update | `git pull && docker compose up -d --build` |
| Restart after editing `config.yml` | `docker compose restart dukpearl` |
| Wipe everything (pearls, logins) | `docker compose down -v` |

## Settings

Everything in `.env` — see [`.env.example`](./.env.example) for the full list with explanations. After changing it, run `docker compose up -d`.

| Variable | Default | What it does |
| --- | --- | --- |
| `MC_HOST` | *required* | Server the bot joins, `host` or `host:port` |
| `MC_USERNAME` | *required* | In-game name of the bot's account |
| `MC_VERSION` | `1.20.1` | Minecraft protocol version |
| `PROXY_PORT` | `25577` | Port you connect your own client to |
| `DISCORD_BOT_TOKEN` | off | Enables the Discord `/load` and `/connect` commands |
| `DISCORD_WEBHOOK_URL` | off | Posts pearl and alert notifications to a channel |
| `STASIS_LOCATION_NAME` | `base` | Names players use in chat, e.g. `!load base` |
| `STASIS_SITE_MAX` | `3` | Max pearls per player at this site |
| `STASIS_USER_MAX` | `-1` | Max pearls per player across sites sharing a name |
| `HOLOGRAM_RENDERER` | `body` | `head`, `body`, `text` or `off` |

Bot behaviour (auto-eat, auto-totem, kill aura, …) lives in [`config.yml`](./config.yml). Each module can be turned off with `enabled: false`.

## Using it

- **Players** throw a pearl into a stasis chamber near the bot; it is registered to them automatically. They whisper or say `!load` to be pulled back, and `!pearls` to see how many they have.
- **You** join `localhost:25577` with the bot account to control it. While connected, `/whitelist add <name>` lets another account join the proxy too, and `/stasis` and `/hologram` manage chambers and holograms.
- **Discord**: set `DISCORD_BOT_TOKEN`, invite the bot to your server, and players can link their account with `/connect` and use `/load`.

## Troubleshooting

- **`env file .env not found`** — run `./setup.sh`, or copy `.env.example` to `.env`.
- **No sign-in code in the log** — the login is already saved. To sign in as a different account, run `docker compose down -v` (this also deletes stored pearls) and start again.
- **"You are not whitelisted on this proxy"** — join with the bot's own account, or have it run `/whitelist add <name>`.
- **Can't connect to `localhost:25577`** — check `docker compose ps` shows `dukpearl` running, and that the bot has finished joining the server (on 2b2t it waits in the queue first).
- **Port already in use** — set `PROXY_PORT` in `.env` to another port.

## Development

Needs [Bun](https://bun.sh), plus a Postgres and Redis you point `DATABASE_URL` and `REDIS_URL` at.

```bash
bun install && bun run generate
```

```bash
bun start
```

`bun run lint` and `bun test` check the code.

## License

[LGPL-2.1](./LICENSE), the same as the upstream StasisProxy project.
