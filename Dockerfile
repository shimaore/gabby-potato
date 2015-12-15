FROM shimaore/freeswitch:2.1.2
MAINTAINER Stéphane Alnet <stephane@shimaore.net>
ENV NODE_ENV production

USER root
RUN \
  mkdir -p /opt/gabby-potato/{conf,log} && \
  chown -R freeswitch.freeswitch /opt/gabby-potato/ && \
  apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
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
  n 4.2.3 && \
  apt-get purge -y \
    build-essential \
    ca-certificates \
    cpp-5 \
    gcc-5 \
    curl \
    git \
    make \
  && \
  apt-get autoremove -y && apt-get clean

WORKDIR /opt/gabby-potato
USER freeswitch
COPY . /opt/gabby-potato/
RUN \
  npm install && \
  npm cache clean
CMD ["npm start"]
