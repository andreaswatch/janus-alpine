FROM alpine:latest

LABEL maintainer="Laurent Klock <klockla@hotmail.com>"
LABEL description="Janus WebRTC Alpine image" 

RUN echo "**** install build packages ****" && \
	apk add --no-cache --virtual=build-dependencies --upgrade \
	autoconf \
	automake \
	cmake \
	curl-dev \
	doxygen \
	fakeroot \
	ffmpeg-dev \
	fftw-dev \
	gengetopt \
	g++ \
	gcc \
	git \
	glib-dev \
	graphviz \
	gtk-doc \
	jansson-dev \
	jpeg-dev \
	libpng-dev \
	libtool \
	make \
	mpg123-dev \
	libconfig-dev \
	libogg-dev \
	libmicrohttpd-dev \
	libsrtp-dev \
	libwebsockets-dev \
	lua5.3-dev \
	openjpeg-dev \
	openssl-dev \
	opus-dev \
	pkgconf \
	python3-dev \
	sudo \
	zlib-dev

RUN git clone https://github.com/sctplab/usrsctp && cd usrsctp && ./bootstrap \
	&& ./configure CFLAGS="-Wno-error=cpp" --prefix=/usr && make && sudo make install

RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git/ && cd libnice \
	&& ./autogen.sh && ./configure --prefix=/usr CFLAGS="-Wno-error=format -Wno-error=cast-align" \
        && make && sudo make install

# Janus WebRTC Installation

RUN mkdir -p /usr/src/janus /var/janus/log /var/janus/data /var/janus/html

RUN cd /usr/src/janus && wget https://github.com/meetecho/janus-gateway/archive/v0.9.2.tar.gz

RUN cd /usr/src/janus && tar -xzf v0.9.2.tar.gz && cd janus-gateway-0.9.2 && \
	cp -r /usr/src/janus/janus-gateway-0.9.2/html/* /var/janus/html

RUN cd /usr/src/janus/janus-gateway-0.9.2 && sh autogen.sh && \
#	./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt --enable-docs && \
	./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt && \
	make && make install && make configs && \
	rm -rf /usr/src/janus

EXPOSE 8880
EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 10000-10200/udp

RUN apk add nginx supervisor

COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY conf/janus.plugin.videoroom.jcfg /var/janus/etc/janus/janus.plugin.videoroom.jcfg

# Configure supervisord
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Let supervisord start nginx
CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf && /var/janus/bin/janus --nat-1-1=${DOCKER_IP} -r 10000-10200
