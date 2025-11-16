FROM node:18-alpine

WORKDIR /usr/src/app

ENV NODE_ENV=production

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY package*.json ./

RUN npm install --only=production && npm cache clean --force

COPY src ./src

USER appuser

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8001/health || exit 1

CMD ["node", "src/server.js"]
