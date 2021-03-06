#!/bin/bash
set -x

# Init the arguments
ADMIN_TOKEN=${ADMIN_TOKEN:-294a4c8a8a475f9b9836}
ADMIN_TENANT_NAME=${ADMIN_TENANT_NAME:-admin}
ADMIN_USER_NAME=${ADMIN_USERNAME:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-ADMIN_PASS}
ADMIN_EMAIL=${ADMIN_EMAIL:-${ADMIN_USER_NAME}@example.com}

OS_TOKEN=$ADMIN_TOKEN
OS_URL=${OS_AUTH_URL:-"http://${HOSTNAME}:35357/v3"}
OS_IDENTITY_API_VERSION=3

CONFIG_FILE=/etc/keystone/keystone.conf
SQL_SCRIPT=${SQL_SCRIPT:-/root/keystone.sql}

if env | grep -qi MYSQL_ROOT_PASSWORD && test -e $SQL_SCRIPT; then
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
    MYSQL_HOST=${MYSQL_HOST:-mysql}
    sed -i "s#^connection.*=.*#connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@${MYSQL_HOST}/keystone?charset=utf8#" $CONFIG_FILE
    # Before inserting the schema, testing MySQL availability
    until mysql -uroot -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST -e 'select 1'; do
    	>&2 echo "MySQL is unavailable - sleeping"
    	sleep 1
    done
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST <$SQL_SCRIPT
fi

rm -f $SQL_SCRIPT

# update keystone.conf
sed -i "s#^admin_token.*=.*#admin_token = $ADMIN_TOKEN#" $CONFIG_FILE

# Populate the Identity service database
keystone-manage db_sync
# Initialize Fernet keys
keystone-manage fernet_setup --keystone-user root --keystone-group root
mv /etc/keystone/default_catalog.templates /etc/keystone/default_catalog

export OS_TOKEN OS_URL OS_IDENTITY_API_VERSION

# Initialize account
keystone-manage bootstrap \
				--bootstrap-username ${ADMIN_USER_NAME} \
				--bootstrap-password ${ADMIN_PASSWORD} \
				--bootstrap-project-name ${ADMIN_TENANT_NAME} \
				--bootstrap-role-name admin \
				--bootstrap-service-name keystone \
				--bootstrap-region-id RegionOne \
				--bootstrap-admin-url http://${HOSTNAME}:35357 \
				--bootstrap-public-url http://${HOSTNAME}:5000 \
				--bootstrap-internal-url http://${HOSTNAME}:5000

unset OS_TOKEN OS_URL

# Write openrc to disk
cat >/opt/shared/openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=${ADMIN_TENANT_NAME}
export OS_USERNAME=${ADMIN_USER_NAME}
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_AUTH_URL=http://${HOSTNAME}:35357
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

cat /opt/shared/openrc

# reboot services
#pkill uwsgi
#sleep 5
uwsgi --http 0.0.0.0:5000 --wsgi-file $(which keystone-wsgi-public) &
sleep 5
uwsgi --http 0.0.0.0:35357 --wsgi-file $(which keystone-wsgi-admin)
