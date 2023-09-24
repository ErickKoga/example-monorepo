ARG NODE_VERSION

# API Base Stage
FROM node:${NODE_VERSION} AS base
LABEL stage=base
RUN corepack enable && \
  pnpm config set store-dir /tmp/cache/pnpm && \
  addgroup --system --gid 1001 api && \
  adduser --system --uid 1001 api
WORKDIR /app
COPY pnpm-lock.yaml ./pnpm-lock.yaml

# API Builder Stage
FROM base AS builder
LABEL stage=builder
WORKDIR /app
RUN --mount=type=cache,target=/tmp/cache pnpm fetch
COPY . .
RUN --mount=type=cache,target=/tmp/cache \
  CI=1 pnpm install --no-optional && \
  pnpm --filter=api build && \
  pnpm --filter=api --prod deploy ./deploy/api

# API Production Stage
FROM base AS runner
LABEL stage=runner
WORKDIR /app
COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/deploy/api/node_modules ./node_modules
USER api
CMD [ "node", "dist/main.js" ]
