#!/bin/sh
# export DB_CID=$(docker run --detach --env MYSQL_ROOT_PASSWORD=ch2demo mysql:5.7)
# export MAILER_CID=$(docker run --detach dockerinaction/ch2_mailer)
# CLIENT_ID=dockerinaction ./start-wp-for-client.sh
if [ ! -n "$CLIENT_ID" ]; then
    echo "Client ID not set"
    exit 1
fi

WP_CID=$(docker create \
--link $DB_CID:mysql \
--name wp_$CLIENT_ID \
--publish 80:80 \
--read-only --volume /run/apache2 --tmpfs /tmp/ \
--env WORDPRESS_DB_NAME=$CLIENT_ID \
--read-only wordpress:5.0.0-php7.2-apache
)
docker start $WP_CID

AGENT_CID=$(docker create \
--name agent_$CLIENT_ID \
--link $WP_CID:insideweb \
--link $MAILER_CID:insidemailer \
dockerinaction/ch2_agent
)

docker start $AGENT_CID