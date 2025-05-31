FROM node:lts-alpine3.22
WORKDIR /app
COPY . .
EXPOSE 3000
COPY package*.json ./
ENTRYPOINT start npm
