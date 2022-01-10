# Starts with python:3.7.1-alpine and then installs most of python:2.7.15-alpine on top
# to allows us to choose Python versions at runtime via: python2, python3, pip2, pip3, etc.
FROM python:3.7.1-alpine

ENV PYTHON_VERSION 2.7.15

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.1
ENV PATH="/root/bin/:${PATH}"
# ENV TERM=xterm-256color

RUN set -ex
RUN apk update
RUN apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl \
		tar \
		xz \
		git \
		gcc \
		python-dev \
		python3-dev

RUN wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" 

RUN export GNUPGHOME="$(mktemp -d)"

RUN mkdir -p /usr/src/python
RUN tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz
RUN rm python.tar.xz

RUN set -ex \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl \
		tar \
		xz \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& apk add --no-cache --virtual .build-deps  \
		bzip2-dev \
		gcc \
		gdbm-dev \
		libc-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		zlib-dev \
# add build deps before removing fetch deps in case there's overlap
	&& apk del .fetch-deps \
	\
	&& cd /usr/src/python \
	&& ./configure \
		--enable-shared \
		--enable-unicode=ucs4 \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	\
		&& wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/pip/2.7/get-pip.py' \
		&& python2 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" \
		&& rm /tmp/get-pip.py \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a -name test -o -name tests \) \
			-o \
			\( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		\) -exec rm -rf '{}' + \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .python-rundeps $runDeps \
	&& apk del .build-deps \
	&& rm -rf /usr/src/python ~/.cache

RUN ls -Fla /usr/local/bin/p* \
    && which python  && python -V \
    && which python2 && python2 -V \
    && which python3 && python3 -V \
    && which pip     && pip -V \
    && which pip2    && pip2 -V \
    && which pip3    && pip3 -V

RUN apk update
RUN apk add git
RUN apk add gcc
RUN apk add python-dev
RUN apk add python3-dev
RUN apk add musl-dev

RUN pip install --upgrade pip

RUN wget -O /tmp/pre-commit-install.py 'https://pre-commit.com/install-local.py' \
	&& python3 /tmp/pre-commit-install.py \
	&& rm -rf /tmp/pre-commit-install.py

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"


CMD ["python2"]
