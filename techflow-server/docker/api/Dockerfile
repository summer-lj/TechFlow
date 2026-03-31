FROM node:22-alpine AS base

RUN apk add --no-cache bash openssl netcat-openbsd

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
WORKDIR /workspace

RUN corepack enable

FROM base AS development

COPY docker/api/dev-entrypoint.sh /usr/local/bin/dev-entrypoint.sh
RUN chmod +x /usr/local/bin/dev-entrypoint.sh

ENTRYPOINT ["dev-entrypoint.sh"]
CMD ["pnpm", "--filter", "@backend/api", "start:dev"]

FROM base AS deps

COPY package.json pnpm-workspace.yaml tsconfig.base.json eslint.config.mjs prettier.config.mjs lint-staged.config.mjs ./
COPY pnpm-lock.yaml ./
COPY apps/api/package.json apps/api/package.json
COPY apps/api/nest-cli.json apps/api/nest-cli.json
COPY apps/api/tsconfig.json apps/api/tsconfig.json
COPY apps/api/tsconfig.build.json apps/api/tsconfig.build.json

RUN pnpm install --frozen-lockfile

FROM deps AS builder

COPY . .

RUN pnpm --filter @backend/api prisma:generate
RUN pnpm --filter @backend/api build

FROM base AS production

ENV NODE_ENV=production

COPY --from=deps /workspace/node_modules /workspace/node_modules
COPY --from=deps /workspace/apps/api/node_modules /workspace/apps/api/node_modules
COPY --from=builder /workspace/apps/api/dist /workspace/apps/api/dist
COPY --from=builder /workspace/apps/api/prisma /workspace/apps/api/prisma
COPY --from=builder /workspace/apps/api/package.json /workspace/apps/api/package.json
COPY --from=builder /workspace/package.json /workspace/package.json
COPY --from=builder /workspace/pnpm-workspace.yaml /workspace/pnpm-workspace.yaml
COPY docker/api/runtime-entrypoint.sh /usr/local/bin/runtime-entrypoint.sh

RUN chmod +x /usr/local/bin/runtime-entrypoint.sh

ENTRYPOINT ["runtime-entrypoint.sh"]
CMD ["pnpm", "--filter", "@backend/api", "start:prod"]
