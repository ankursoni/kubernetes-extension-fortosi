ARG BUILD_IMAGE
FROM ${BUILD_IMAGE}
LABEL build="temp"
WORKDIR /app

ADD package*.json ./
ADD tests tests

RUN npm install
RUN npm test