FROM oven/bun:1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Copy dependency manifest and lockfile, then install
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Copy prisma schema and config, then generate the client
COPY prisma ./prisma/
COPY prisma.config.ts ./
RUN bun run generate

# Copy remaining source (the IRC wire schemas live in src/schema — plain
# source, no private dependency; see src/schema/irc/README.md).
# This includes .git when it exists, so the build can report its commit;
# a ZIP download without .git builds fine and reports "unknown".
COPY . .

# Optional: IRC presence credentials (only used when IRC_HOST is set)
ARG IRC_CLIENT_ID
ARG IRC_CLIENT_SECRET
ENV IRC_CLIENT_ID=$IRC_CLIENT_ID
ENV IRC_CLIENT_SECRET=$IRC_CLIENT_SECRET

# Minecraft proxy + HTTP API
EXPOSE 25577
EXPOSE 3000

CMD ["bun", "start"]
