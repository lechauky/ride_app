FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 5001 5002 6001 6002

CMD ["node", "start_all.js"]
