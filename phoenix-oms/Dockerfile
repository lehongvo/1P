FROM node:18-alpine

WORKDIR /app

# Copy root manifests
COPY package.json yarn.lock ./

# Install only production deps
RUN yarn install --frozen-lockfile --production

# Copy source code
COPY . .

# Build service
RUN npx tsc -p phoenix-oms/tsconfig.json

EXPOSE 3001

CMD ["node", "phoenix-oms/dist/index.js"]
