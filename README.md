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
| Second bot | Only asked with about 1 GB of RAM or more, in linux mode — see [Two bots](#two-bots) |

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

### Two bots

On a machine with about 1 GB of RAM or more, setup (in linux mode) asks whether to run a second bot. Say `yes` and give it its own Minecraft account and port (Enter for a random one). Both bots join the same server and share the database, Discord bot and settings.

`./launch` then starts both. Inside tmux the second bot gets its own pane below the first: switch panes with `Ctrl+B` then an arrow key, and stop each one with `Ctrl+C` in its pane. Each pane prints its own Microsoft sign-in code the first time, so sign in to each with the matching account. Outside tmux both share the terminal, with each line tagged by bot name.

To add or remove the second bot later, run `./launch --setup`. For a different server or site name on the second bot, set `BOT2_HOST` or `BOT2_LOCATION_NAME` in `.env`.

### Small servers (512 MB)

`./launch` turns on low-memory mode by itself when the machine has under about 1 GB of RAM. It:

- adds a 1 GB swap file if there is no swap, so installing and starting cannot run out of memory
- shrinks PostgreSQL's memory settings
- sets `MC_VIEW_DISTANCE=4` so the bot loads fewer chunks (raise it in `.env` if chambers further away are missed)
- runs the bot with Bun's compact memory mode

Before joining a server the whole stack uses roughly 170 MB (bot ~140, PostgreSQL ~20, Redis ~5). Memory grows once the bot is in game, mostly with view distance and how busy the area is. Use linux mode on a server this small; Docker mode needs more RAM. Leaving `DISCORD_BOT_TOKEN` unset saves a little more. To force the mode on or off, set `LAUNCH_LOWMEM=yes` or `no` in `.env`.

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
- **Discord**: players link their account with `/connect` and pull their pearl with `/load` — see below.

## Discord bot

DukPearl has a Discord bot built in; it only needs a token.

1. Open the [Discord Developer Portal](https://discord.com/developers/applications), click **New Application** and give it a name.
2. Go to **Bot**, click **Reset Token**, and copy the token. No other switches on that page need changing.
3. Run `./launch --setup` and paste the token at the Discord question (or put `DISCORD_BOT_TOKEN=...` in `.env`), then start DukPearl.
4. The log prints an **invite link**. Open it and add the bot to your server.

Players then use:

| Command | What it does |
| --- | --- |
| `/connect` | Gives a code to say in game (`!connect <code>`), linking their Minecraft account to their Discord account |
| `/load` | Pulls their pearl, for a linked account |

Slash commands can take a few minutes to show up the first time.

For notifications in a channel (pearl registered, totem popped, Sentry alerts), create a webhook under **Channel settings → Integrations → Webhooks** and give its URL at the webhook question, or set `DISCORD_WEBHOOK_URL` in `.env`. This works with or without the bot.

If you run several DukPearl bots, give them all the same token; they share the one Discord bot.

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
