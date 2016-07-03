FROM evild/alpine-php:7.0.8

ARG DOKUWIKI_VERSION=2016-06-26
ARG MD5_CHECKSUM=a4b8ae00ce94e42d4ef52dd8f4ad30fe

RUN apk add --no-cache --virtual .build-deps \
                autoconf gcc libc-dev make \
                libpng-dev libjpeg-turbo-dev \
        && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd mysqli opcache \
        && find /usr/local/lib/php/extensions -name '*.a' -delete \
        && find /usr/local/lib/php/extensions -name '*.so' -exec strip --strip-all '{}' \; \
        && runDeps="$( \
                scanelf --needed --nobanner --recursive \
                        /usr/local/lib/php/extensions \
                        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                        | sort -u \
                        | xargs -r apk info --installed \
                        | sort -u \
        )" \
        && apk add --virtual .phpext-rundeps $runDeps \
        && apk del .build-deps

RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini


VOLUME /var/www/html

RUN curl -o wordpress.tar.gz -SL http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz \
        && echo "$MD5_CHECKSUM  dokuwiki-$DOKUWIKI_VERSION.tgz" | md5sum -c - \
        && tar xzf "dokuwiki-$DOKUWIKI_VERSION.tgz" -C /usr/src/ \
        && rm dokuwiki-$DOKUWIKI_VERSION.tgz
        && chown -R www-data:www-data /usr/src/wordpress

ADD root /
