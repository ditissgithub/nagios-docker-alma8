FROM almalinux/8-base:latest
LABEL maintainer="ditissgithub"

RUN yum install -y epel-release sudo
RUN yum install -y  httpd nagios nrpe

RUN systemctl enable nagios && systemctl enable httpd
RUN yum install -y gettext supervisor procps-ng initscripts


COPY ./httpd_initscripts /etc/init.d/httpd
COPY ./etc_nagios /nagios_conf
COPY ./supervisord.conf /etc/supervisord.conf


ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chmod +x /etc/init.d/httpd && \


EXPOSE 9001 5666 5667 5668

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

