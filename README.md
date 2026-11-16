# DukPearl

**A self-hosted Minecraft stasis chamber proxy.**

DukPearl keeps a bot account online at your stasis chambers and pulls players' pearls on request, from in-game chat (`!load`) or Discord. You can also join through it with your own client to play as the bot. It comes with in-game holograms, a Discord bot, multi-bot clustering over Redis, and pearl storage in Postgres.

DukPearl is a fork of [StasisProxy](https://github.com/StasisCo/StasisProxy) by StasisCo, with a simpler setup.

## Quick start

For a Debian or Ubuntu machine or VPS. You need a Minecraft (Microsoft) account for the bot.

```bash
git clone https://github.com/dukkkkkkkk/DukPearl.git
```

```bash
tmux
```

```bash
cd DukPearl
```

```bash
./launch
```

The first run asks a few questions — press Enter to take the default:

| Question | Answer |
| --- | --- |
| Is this a VPS? | `yes` shows your server's public address and opens the port in `ufw` if it is on |
| linux or docker | `linux` runs directly on the machine; `docker` runs everything in containers |
| Server, bot name, version | Where the bot joins and which account it plays on |
| Port | Enter picks a random free one |

It then installs what is missing (Bun, PostgreSQL, Redis — it uses `sudo` if you are not root), and starts the bot.

**First run only:** a Microsoft link and a code are printed. Open the link, enter the code, and sign in as the bot account. The login is remembered after that.

Then join the address it printed (`your-ip:port`) in Minecraft with the bot account.

| What | How |
| --- | --- |
| Leave it running | Detach from tmux: `Ctrl+B` then `D` |
| Come back to it | `tmux attach` |
| Stop | `Ctrl+C` |
| Start again | `./launch` |
| Change your answers | `./launch --setup`, or edit `.env` |
| Update | `git pull`, then `./launch` |

## Settings

Everything is in `.env` — see [`.env.example`](./.env.example) for the full list with explanations. After changing it, stop DukPearl and run `./launch` again.

| Variable | Default | What it does |
| --- | --- | --- |
| `MC_HOST` | *required* | Server the bot joins, `host` or `host:port` |
| `MC_USERNAME` | *required* | In-game name of the bot's account |
| `MC_VERSION` | `1.20.1` | Minecraft protocol version |
| `PROXY_PORT` | set by `./launch` | Port you connect your own client to |
| `DISCORD_BOT_TOKEN` | off | Enables the Discord `/load` and `/connect` commands |
| `DISCORD_WEBHOOK_URL` | off | Posts pearl and alert notifications to a channel |
| `STASIS_LOCATION_NAME` | `base` | Names players use in chat, e.g. `!load base` |
| `STASIS_SITE_MAX` | `3` | Max pearls per player at this site |
| `STASIS_USER_MAX` | `-1` | Max pearls per player across sites sharing a name |
| `HOLOGRAM_RENDERER` | `body` | `head`, `body`, `text` or `off` |

Bot behaviour (auto-eat, auto-totem, kill aura, …) lives in [`config.yml`](./config.yml). Each module can be turned off with `enabled: false`.

## Using it

- **Players** throw a pearl into a stasis chamber near the bot; it is registered to them automatically. They whisper or say `!load` to be pulled back, and `!pearls` to see how many they have.
- **You** join the address `./launch` printed with the bot account to control it. While connected, `/whitelist add <name>` lets another account join the proxy too, and `/stasis` and `/hologram` manage chambers and holograms.
- **Discord**: set `DISCORD_BOT_TOKEN`, invite the bot to your server, and players can link their account with `/connect` and use `/load`.

## Troubleshooting

- **No sign-in code appears** — the login is already saved. To sign in as a different account, delete the saved login (`rm -rf ~/.minecraft/nmp-cache` in linux mode, `docker compose down -v` in docker mode — that one also deletes stored pearls) and launch again.
- **"You are not whitelisted on this proxy"** — join with the bot's own account, or have it run `/whitelist add <name>`.
- **Can't connect** — check DukPearl is still running (`tmux attach`), that your VPS provider's firewall allows the port, and that the bot has finished joining the server (on 2b2t it waits in the queue first).
- **Port already in use** — run `./launch --setup` and press Enter at the port question for a new random one.

## Development

Needs [Bun](https://bun.sh), plus a Postgres and Redis you point `DATABASE_URL` and `REDIS_URL` at in `.env`.

```bash
bun install && bun run generate
```

```bash
bun start
```

`bun run lint` and `bun test` check the code.

## License

[LGPL-2.1](./LICENSE), the same as the upstream StasisProxy project.
