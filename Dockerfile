FROM debian

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV WKHTMLTOX_VERSION 0.12.2.1_linux-jessie-amd64

RUN echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' > /etc/apt/sources.list.d/logstash-forwarder.list
RUN apt-get update && apt-get install -y nginx supervisor git logstash-forwarder wget \
  php5-fpm php5-mysql php5-gd php5-cli php5-mcrypt \
  fontconfig xfonts-base xfonts-75dpi libxrender1
RUN wget -P /tmp http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-${WKHTMLTOX_VERSION}.deb && \
	dpkg -i /tmp/wkhtmltox-${WKHTMLTOX_VERSION}.deb

EXPOSE 80

### APPLICATION CODE ###
ENV INSTALL_DIR /srv/aims
ADD ./app/repo.tgz $INSTALL_DIR
VOLUME $INSTALL_DIR/application/config
VOLUME $INSTALL_DIR/uploads

### SUPPORTIVE SERVICES ###
ENV FILES_DIR ./container/files

# path resolution 
ENV PATH /opt/logstash-forwarder/bin:$PATH

# supervisor setup
COPY $FILES_DIR/etc/supervisor/conf.d /etc/supervisor/conf.d

# php-fpm setup
RUN sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/fpm/php.ini

# nginx setup
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
ENV SITE_DEST /etc/nginx/sites-available/aims
COPY $FILES_DIR/$SITE_DEST $SITE_DEST
RUN ln -s $SITE_DEST /etc/nginx/sites-enabled/aims
RUN rm /etc/nginx/sites-enabled/default

# logstash-forwarder setup
COPY $FILES_DIR/etc/logstash-forwarder.json /etc/logstash-forwarder.json
COPY $FILES_DIR/etc/pki/tls/certs/logstash-forwarder.crt /etc/pki/tls/certs/logstash-forwarder.crt

# pdf setup
RUN ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
COPY $FILES_DIR/usr/bin/pdftk /usr/bin/pdftk

### RUNNING IT OUT ###
CMD ["supervisord", "-n"]