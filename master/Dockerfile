FROM docker.io/amd64/almalinux:9 AS builder

RUN \
        dnf -y update && \
        dnf -y install epel-release dnf-plugins-core && \
        dnf config-manager --set-enabled crb

RUN dnf -y install \
        autoconf \
        automake \
        cargo \
        cbindgen \
        diffutils \
        elfutils-libelf-devel \
        file \
        file-devel \
        gcc \
        gcc-c++ \
        git \
        hiredis-devel \
        jansson-devel \
        jq \
        lua-devel \
        libbpf-devel \
        libtool \
        libyaml-devel \
        libnfnetlink-devel \
        libnetfilter_queue-devel \
        libnet-devel \
        libcap-ng-devel \
        libevent-devel \
        libmaxminddb-devel \
        libpcap-devel \
        libprelude-devel \
        libtool \
        lz4-devel \
        make \
        nspr-devel \
        nss-devel \
        nss-softokn-devel \
        pcre2-devel \
        pkgconfig \
        python3-devel \
        python3-yaml \
        rust \
        which \
        zlib-devel

RUN if [ "$(arch)" = "x86_64" ]; then \
       dnf -y install hyperscan-devel; \
fi

ARG VERSION

WORKDIR /src

RUN if [ "${VERSION}" = "master" ]; then \
	git clone https://github.com/vyzigold/suricata.git suricata-${VERSION}; \
	git clone https://github.com/OISF/libhtp.git suricata-${VERSION}/libhtp; \
        (cd suricata-${VERSION}/suricata-update && \
		curl -L https://github.com/OISF/suricata-update/archive/master.tar.gz | tar zxf - --strip-components=1); \
	(cd suricata-${VERSION} && ./autogen.sh); \
else \
	curl -OL https://www.openinfosecfoundation.org/download/suricata-${VERSION}.tar.gz; \
	tar zxf suricata-${VERSION}.tar.gz; \
fi #redo

WORKDIR /src/suricata-${VERSION}

ARG CONFIGURE_ARGS

RUN ./configure \
        --prefix=/usr \
        --disable-shared \
        --disable-gccmarch-native \
        --enable-lua \
        --enable-nfqueue \
        --enable-hiredis \
        --enable-geoip \
        --enable-ebpf \
        ${CONFIGURE_ARGS}

ARG CORES=2

RUN make -j "${CORES}"

RUN make install install-conf DESTDIR=/fakeroot

RUN make install-library install-headers DESTDIR=/fakeroot

# Something about the Docker mounts won't let us copy /var/run in the
# next stage.
RUN rm -rf /fakeroot/var

FROM docker.io/almalinux/amd64:9-base AS runner

RUN \
        dnf -y update && \
        dnf -y install epel-release && \
        dnf -y install \
        cronie \
        elfutils-libelf \
        file \
        findutils \
        iptables-nft \
        hiredis \
        iproute \
        jansson \
        lua-libs \
        libbpf \
        libyaml \
        libnfnetlink \
        libnetfilter_queue \
        libnet \
        libcap-ng \
        libevent \
        libmaxminddb \
        libpcap \
        libprelude \
        logrotate \
        lz4 \
        net-tools \
        nss \
        vim \
        rsyslog \
        git \
        gcc \
        gcc-c++ \
        iputils \
        dnf-plugins-core \
        netcat \
        nss-softokn \
        pcre2 \
        procps-ng \
        python3 \
        python3-yaml \
        python3-pip \
        python3-devel \
		python3-psycopg2 \
        tcpdump \
        docker \
        which \
        zlib && \
        if [ "$(arch)" = "x86_64" ]; then dnf -y install hyperscan; fi && \
        dnf clean all && \
        find /etc/logrotate.d -type f -not -name suricata -delete


## use docker instead of podman
#RUN dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
#RUN sed s/\$releasever/37/g /etc/yum.repos.d/docker-ce.repo > /etc/yum.repos.d/docker-ce.repo2
#RUN mv /etc/yum.repos.d/docker-ce.repo2 /etc/yum.repos.d/docker-ce.repo
#RUN dnf -y update
#RUN curl -OL "https://kojihub.stream.centos.org/kojifiles/packages/libcgroup/0.42.2/5.el9/x86_64/libcgroup-0.42.2-5.el9.x86_64.rpm"
#RUN yum localinstall -y libcgroup-0.42.2-5.el9.x86_64.rpm
#RUN dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#RUN --security=insecure dockerd
#RUN sleep 10

RUN podman pull docker.io/vyzigold/kali:latest

COPY --from=builder /fakeroot /

# Create the directories that didn't get copied from the previous stage.
RUN mkdir -p /var/log/suricata /var/run/suricata /var/lib/suricata


#RUN suricata-update update-sources && \
#        suricata-update enable-source oisf/trafficid && \
#        suricata-update --no-test --no-reload && \
#        /usr/bin/suricata -V

RUN suricata-update enable-source oisf/trafficid && \
        /usr/bin/suricata -V

COPY /update.yaml /etc/suricata/update.yaml
COPY /suricata.logrotate /etc/logrotate.d/suricata

RUN useradd --system --create-home suricata && \
        chown -R suricata:suricata /etc/suricata && \
        chown -R suricata:suricata /var/log/suricata && \
        chown -R suricata:suricata /var/lib/suricata && \
        chown -R suricata:suricata /var/run/suricata && \
        cp -a /etc/suricata /etc/suricata.dist && \
        chmod 600 /etc/logrotate.d/suricata

VOLUME /var/log/suricata
VOLUME /var/lib/suricata
VOLUME /etc/suricata
VOLUME /var/lib/docker

RUN pip install scapy twisted service_identity psutil psycopg2-binary pycrypto requests impacket paramiko netifaces docker

COPY /docker-entrypoint.sh /
COPY /suricata.yaml /
COPY /suricata.rules /
COPY /start.sh /

RUN git clone https://github.com/vyzigold/honeypots
RUN git clone https://github.com/vyzigold/attack_replay
RUN git clone https://github.com/vyzigold/dp

ENTRYPOINT ["/docker-entrypoint.sh"]
