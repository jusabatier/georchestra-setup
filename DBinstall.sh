#!/bin/bash

set -ex

apt-get -y install postgresql-$POSTGRES_VERSION postgresql-$POSTGRES_VERSION-postgis-$POSTGIS_VERSION postgis

sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '$SERVER_IP'/g" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sed -i -e "s/#password_encryption = on/password_encryption = on/g" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf

echo "host 	all 			all 			all						md5" >> /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf

service postgresql restart

echo "postgres:$POSTGRES_PASSWORD" | chpasswd

sudo -u postgres psql -U postgres -w -c "alter user postgres with password '$POSTGRES_PASSWORD';"

sudo -u postgres createdb -E UTF8 -U postgres template_postgis
sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/$POSTGRES_VERSION/contrib/postgis-$POSTGIS_VERSION/postgis.sql
sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/$POSTGRES_VERSION/contrib/postgis-$POSTGIS_VERSION/postgis_comments.sql
sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/$POSTGRES_VERSION/contrib/postgis-$POSTGIS_VERSION/spatial_ref_sys.sql

sudo -u postgres createdb -E UTF8 -T template_postgis georchestra
sudo -u postgres psql -d georchestra -c "CREATE USER \"www-data\" WITH PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON DATABASE georchestra TO "www-data";'

sudo -u postgres psql -d georchestra -c "CREATE USER geonetwork WITH PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres psql -d georchestra -c 'CREATE SCHEMA geonetwork;'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA geonetwork TO "geonetwork";'

wget --no-check-certificate https://raw.github.com/georchestra/georchestra/14.06/mapfishapp/database.sql -O /tmp/mapfishapp.sql
sudo -u postgres psql -d georchestra -f /tmp/mapfishapp.sql
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA mapfishapp TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mapfishapp TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mapfishapp TO "www-data";'

wget --no-check-certificate https://raw.github.com/georchestra/georchestra/14.06/ldapadmin/database.sql -O /tmp/ldapadmin.sql
sudo -u postgres psql -d georchestra -f /tmp/ldapadmin.sql
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA ldapadmin TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ldapadmin TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ldapadmin TO "www-data";'

sudo -u postgres psql -d georchestra -c 'GRANT SELECT ON public.spatial_ref_sys to "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT SELECT,INSERT,DELETE ON public.geometry_columns to "www-data";'
wget --no-check-certificate https://raw.github.com/georchestra/geofence/georchestra/doc/setup/sql/002_create_schema_postgres.sql -O /tmp/geofence.sql
sudo -u postgres psql -d georchestra -f /tmp/geofence.sql
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA geofence TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA geofence TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA geofence TO "www-data";'

wget --no-check-certificate https://raw.github.com/georchestra/georchestra/14.06/downloadform/database.sql -O /tmp/downloadform.sql
sudo -u postgres psql -d georchestra -f /tmp/downloadform.sql
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA downloadform TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA downloadform TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA downloadform TO "www-data";'

wget --no-check-certificate https://raw.github.com/georchestra/georchestra/14.06/ogc-server-statistics/database.sql -O /tmp/ogcstatistics.sql
sudo -u postgres psql -d georchestra -f /tmp/ogcstatistics.sql
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON SCHEMA ogcstatistics TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ogcstatistics TO "www-data";'
sudo -u postgres psql -d georchestra -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ogcstatistics TO "www-data";'