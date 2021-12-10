FROM openresty/openresty:xenial

RUN apt-get update \
    && apt-get install -y \
       git \
    && mkdir /src \
    && cd /src \
    && git config --global url."https://".insteadOf git:// \
    && luarocks install xml2lua 1.4-3 \
    && rm -Rf /src
COPY ./nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY ./src /lua/src/
COPY ./spec/manifests /media
EXPOSE 8080
