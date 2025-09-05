FROM node:18-alpine

WORKDIR /app

# Copy root manifests
COPY package.json yarn.lock ./

# Install all deps (including dev deps for build)
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build service
RUN yarn add typescript && npx tsc -p phoenix-oms/tsconfig.json

EXPOSE 3001

CMD ["node", "phoenix-oms/dist/index.js"]
