ARG BUILD_IMAGE
FROM ${BUILD_IMAGE}

RUN ping google.com -c 4
RUN cat /etc/resolv.conf && echo "nameserver 172.20.0.10" > /etc/resolv.conf
RUN ping google.com -c 4
LABEL build="temp"
WORKDIR /app

ADD package*.json ./
ADD tests tests

RUN npm install
RUN npm test