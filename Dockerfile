Dockerfile
FROM ubuntu:14.04
MAINTAINER ctwj <908504609@qq.com>

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install vim curl nginx memcached supervisor php5-cli php5-fpm php5-dev php5-mysql php5-curl php5-intl php5-mcrypt php5-memcache -y

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir -p /var/www/html/public
RUN mkdir -p /var/www/html/log
RUN touch /var/www/html/log/access.log
RUN touch /var/www/html/log/error.log
RUN chown -R www-data:www-data /var/www/html

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY cert.key /etc/nginx/cert.key
COPY cert.pem /etc/nginx/cert.pem

EXPOSE 22 443
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
supervisord.conf
[supervisord]
nodaemon=true
loglevel=debug

[program:memcache]
command=/usr/bin/memcached -u root -m 64
user=root

[program:nginx]
command=/usr/sbin/nginx
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
user=root
autostart=true

[program:php-fpm]
command=/usr/sbin/php5-fpm -c /etc/php5/fpm
user=root
autostart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
