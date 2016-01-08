FROM shimaore/freeswitch-with-sounds:2.2.11
MAINTAINER Stéphane Alnet <stephane@shimaore.net>
ENV NODE_ENV production
ENV SPOOL /opt/freeswitch/var/spool

USER root
RUN \
  mkdir -p /opt/gabby-potato/conf /opt/gabby-potato/log && \
  chown -R freeswitch.freeswitch /opt/gabby-potato/ && \
  apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    python-pkg-resources \
    supervisor \
  && \
# Install Node.js using `n`.
  git clone https://github.com/tj/n.git n.git && \
  cd n.git && \
  make install && \
  cd .. && \
  rm -rf n.git && \
  n 4.2.4 && \
  apt-get purge -y \
    ca-certificates \
    curl \
    git \
    make \
  && \
  apt-get autoremove -y && apt-get clean && \
  rm -rf /usr/share/man /var/log/lastlog /tmp/*

WORKDIR /opt/gabby-potato
USER freeswitch
COPY . /opt/gabby-potato/
RUN \
  npm install && \
  npm cache clean && \
  rm -rf \
    /home/freeswitch/.node-gyp \
    /opt/freeswitch/etc/freeswitch/* \
    /opt/freeswtch/include/freeswitch \
    /opt/freeswitch/share/freeswitch/fonts \
    /opt/freeswitch/htdocs && \
  mkdir -p ${SPOOL}/fax \
           ${SPOOL}/modem
CMD ["/opt/gabby-potato/supervisord.conf.sh"]
