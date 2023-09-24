ARG NODE_VERSION

# Web Base Stage
FROM node:${NODE_VERSION} AS base
LABEL stage=base
RUN corepack enable && \
  pnpm config set store-dir /tmp/cache/pnpm && \
  addgroup --system --gid 1001 web && \
  adduser --system --uid 1001 web
WORKDIR /app
COPY pnpm-lock.yaml ./pnpm-lock.yaml

# Web Builder Stage
FROM base AS builder
LABEL stage=builder
WORKDIR /app
RUN --mount=type=cache,target=/tmp/cache pnpm fetch
COPY . .
RUN --mount=type=cache,target=/tmp/cache \
  CI=1 pnpm install --no-optional && \
  pnpm --filter=web build && \
  pnpm --filter=web --prod deploy ./deploy/web

# Web Production Stage
FROM base AS runner
LABEL stage=runner
WORKDIR /app
COPY --from=builder /app/apps/web/package.json ./package.json
COPY --from=builder /app/apps/web/.next ./.next
COPY --from=builder /app/deploy/web/node_modules ./node_modules
USER web
CMD [ "pnpm", "start" ]
