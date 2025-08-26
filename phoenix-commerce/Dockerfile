FROM node:18-alpine

WORKDIR /app

# Copy root manifests
COPY package.json yarn.lock ./

# Install only production deps
RUN yarn install --frozen-lockfile --production

# Copy source code
COPY . .

# Build service
RUN npx tsc -p phoenix-commerce/tsconfig.json

EXPOSE 3002

CMD ["node", "phoenix-commerce/dist/index.js"]
