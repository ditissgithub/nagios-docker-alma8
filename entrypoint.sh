#!/bin/bash

if [ -f /root/CONFIGURED ] ||  [[ -f /etc/nagios/CONFIGURED  ]]; then
    mv /nagiosdata.NEEDINIT /nagiosdata.orig
    echo "Starting supervisord..."
    exec /usr/bin/supervisord -c /etc/supervisord.conf

elif [ ! -f /etc/nagios/CONFIGURED ]; then

    cp -r /nagiosdata.NEEDINIT /nagiosdata
    mv /nagiosdata.NEEDINIT /nagiosdata.orig

    # Check if required environment variables are set
    required_vars=( ROOT_PASSWD NAGIOS_USER NAGIOS_USER_PASSWD PORT Master_IP Host_IP compute_g_name hm_g_name gpu_g_name master_g_name login_g_name management_g_name )

    for var in "${required_vars[@]}"; do
       if [ -z "${!var}" ]; then
         echo "Error: Environment variable $var is not set." >&2
         exit 1
      fi
    done

    # Replace the default HTTP port in the Apache configuration
    if [[ -n "$PORT" ]]; then
      sed -i -e "s|Listen 80|Listen $PORT|g" /etc/httpd/conf/httpd.conf
      echo "Apache configuration updated to listen on port $PORT."
    else
      echo "PORT environment variable is not set. Using the default configuration."
    fi

    echo "root:${ROOT_PASSWD}" | chpasswd

    mkdir /etc/nagios/conf.d/
    htpasswd -s -b -c /etc/nagios/newpasswd.users ${NAGIOS_USER} '${NAGIOS_USER_PASSWD}'

    cp -r /etc/nagios/nagios.cfg /etc/nagios/nagios.cfg.orig
    sed -i '/#cfg_dir=\/etc\/nagios\/routers/a cfg_dir=\/etc\/nagios\/conf.d' /etc/nagios/nagios.cfg

    cp -r /etc/httpd/conf.d/nagios.conf /etc/httpd/conf.d/nagios.conf.orig
    sed -i 's|AuthUserFile /etc/nagios/passwd|AuthUserFile /etc/nagios/newpasswd.users|g' /etc/httpd/conf.d/nagios.conf


    envsubst < /nagios_conf/services.cfg.template > /etc/nagios/conf.d/services.cfg
    envsubst < /nagios_conf/nrpe.cfg.template > /etc/nagios/nrpe.cfg
    cp -r /nagios_conf/commands.cfg /etc/nagios/conf.d/

    touch /root/CONFIGURED
    CONFIGURED_FILE="/etc/nagios/CONFIGURED"
    touch "$CONFIGURED_FILE"  && echo ${Host_IP} >> /etc/nagios/CONFIGURED
    echo "Starting supervisord..."
    exec /usr/bin/supervisord -c /etc/supervisord.conf

fi
