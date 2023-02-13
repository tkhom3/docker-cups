FROM alpine:3.17.2

# Add edge branch for cups-pdf
RUN echo -e "http://nl.alpinelinux.org/alpine/edge/testing\nhttp://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories 

RUN apk update && apk add --no-cache \
	cups=2.4.2-r0 \
	cups-dev=2.4.2-r0 \
	cups-libs=2.4.2-r0 \
	cups-pdf=3.0.1-r1 \
	cups-client=2.4.2-r0 \
	cups-filters=1.28.15-r0 \
	avahi=0.8-r6 \
	inotify-tools \
	python3=3.10.6-r1 \
	python3-dev=3.10.6-r1 \
	py3-pip=22.1.1-r0 \
	build-base=0.5-r3 \
	wget=1.21.3-r1 \
	rsync=3.2.5-r0

COPY requirements.txt /

RUN pip3 install -r requirements.txt && \
    rm -rf /tmp/pip_build_root/

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
COPY root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

HEALTHCHECK CMD curl --fail http://localhost:631 || exit 1 