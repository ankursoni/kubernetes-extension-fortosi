ARG BUILD_IMAGE
FROM ${BUILD_IMAGE}
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf
LABEL build="temp"
WORKDIR /app

ADD package*.json ./
ADD tests tests

RUN npm install
RUN npm test