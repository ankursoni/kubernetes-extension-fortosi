ARG BUILD_IMAGE
FROM ${BUILD_IMAGE}

RUN apt update && apt full-upgrade -y && apt install iputils-ping
RUN ping google.com
RUN echo "nameserver 172.20.0.10" > /etc/resolv.conf
RUN ping google.com
LABEL build="temp"
WORKDIR /app

ADD package*.json ./
ADD tests tests

RUN npm install
RUN npm test