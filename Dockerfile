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
	nginx \
	libconfig-dev \
	libogg-dev \
	libmicrohttpd-dev \
	libnice \
	libnice-dev \
	libwebsockets-dev \
	lua5.3-dev \
	openjpeg-dev \
	openssl-dev \
	opus-dev \
	pkgconf \
	python3-dev \
	sudo \
	supervisor \
	zlib-dev

RUN git clone https://github.com/sctplab/usrsctp && cd usrsctp && ./bootstrap \
	&& ./configure CFLAGS="-Wno-error=cpp" --prefix=/usr && make && sudo make install && rm -fr /usrsctp

RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz \
        && tar xfv v2.3.0.tar.gz  && cd libsrtp-2.3.0 \
        && ./configure --prefix=/usr --enable-openssl \
        && make shared_library && sudo make install && rm -fr /libsrtp-2.3.0 && rm -f /v2.3.0.tar.gz

# Janus WebRTC Installation

RUN mkdir -p /usr/src/janus /var/janus/log /var/janus/data /var/janus/html \
	&& cd /usr/src/janus && wget https://github.com/meetecho/janus-gateway/archive/v0.10.7.tar.gz \
	&& tar -xzf v0.10.7.tar.gz && cd janus-gateway-0.10.7 \
	&& cp -r /usr/src/janus/janus-gateway-0.10.7/html/* /var/janus/html \
	&& sh autogen.sh \
	&& ./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt \
	&& make && make install && make configs \
	&& rm -rf /usr/src/janus 

EXPOSE 8880
EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 10000-10200/udp

COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY conf/janus.plugin.videoroom.jcfg /var/janus/etc/janus/janus.plugin.videoroom.jcfg
COPY conf/janus.transport.http.jcfg /var/janus/etc/janus/janus.transport.http.jcfg

# Configure supervisord
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Let supervisord start nginx
CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf && /var/janus/bin/janus --nat-1-1=${DOCKER_IP} -r 10000-10200
