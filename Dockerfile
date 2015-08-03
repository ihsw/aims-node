FROM debian

EXPOSE 80

### ENVIRONMENT SETUP ###
# versioning
ENV WKHTMLTOX_VERSION 0.11.0_rc1-static-amd64

# importing apt-keys and sources
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
RUN echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' > /etc/apt/sources.list.d/logstash-forwarder.list

# apt-get install
RUN apt-get update && apt-get install -y nginx supervisor git logstash-forwarder wget curl bzip2 \
  php5-fpm php5-mysql php5-gd php5-cli php5-mcrypt \
  fontconfig xfonts-base xfonts-75dpi libxrender1 pdftk

# composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# wkhtmltopdf
RUN wget -P /tmp http://download.gna.org/wkhtmltopdf/obsolete/linux/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2 && \
	tar -C /usr/local/etc -xjf /tmp/wkhtmltopdf-${WKHTMLTOX_VERSION}.tar.bz2 && \
	ln -s /usr/local/etc/wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf

### APPLICATION CODE ###
# main aims app
ENV INSTALL_DIR /srv/aims
ADD ./app/repo.tgz $INSTALL_DIR
VOLUME $INSTALL_DIR/application/config
VOLUME $INSTALL_DIR/uploads
RUN cd $INSTALL_DIR && composer install

# hourly cronjob
RUN mkdir /srv/aims-interval
COPY ./app/aims-interval /srv/aims-interval
RUN cd /srv/aims-interval && composer install

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

### RUNNING IT OUT ###
CMD ["supervisord", "-n"]