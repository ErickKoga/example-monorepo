ARG NODE_VERSION

# Base Stage
FROM node:${NODE_VERSION} AS base
LABEL stage=base
RUN corepack enable && \
  pnpm config set store-dir /tmp/cache/pnpm && \
  addgroup --system --gid 1001 runner && \
  adduser --system --uid 1001 runner
WORKDIR /app
COPY pnpm-lock.yaml ./pnpm-lock.yaml

# Builder Stage
FROM base AS builder
LABEL stage=builder
WORKDIR /app
RUN --mount=type=cache,target=/tmp/cache pnpm fetch
COPY . .
RUN --mount=type=cache,target=/tmp/cache \
  CI=1 pnpm install --no-optional && \
  pnpm db:generate && \
  pnpm build && \
  pnpm --filter=api --prod deploy ./deploy/api && \
  pnpm --filter=web --prod deploy ./deploy/web

# API Production Stage
FROM base AS api-runner
LABEL stage=api-runner
WORKDIR /app
COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/deploy/api/node_modules ./node_modules
USER runner
CMD [ "node", "dist/main.js" ]

# Web Production Stage
FROM base AS web-runner
LABEL stage=web-runner
WORKDIR /app
COPY --from=builder /app/apps/web/package.json ./package.json
COPY --from=builder /app/apps/web/.next ./.next
COPY --from=builder /app/deploy/web/node_modules ./node_modules
USER runner
CMD [ "pnpm", "start" ]