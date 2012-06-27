conf = require "../conf"
control = require "control"

indivoDB = (server, callback) ->
  script = """#!/bin/sh
cat << EOF >> /etc/postgresql/9.1/main/pg_hba.conf
#Added for M-CM Indivo X Server Configuration
local   all             all                                     md5
EOF
service postgresql restart
su postgres -c psql <<'EOF'
DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'indivo') THEN

      CREATE ROLE indivo LOGIN PASSWORD 'indivo' SUPERUSER;
   END IF;
END
$body$
EOF
su postgres -c 'dropdb indivo' 2>/dev/null || /bin/true
su postgres -c 'createdb -O indivo indivo'
"""
  server.script script, true, callback

control.task "indivoDB", "Create the Indivo PostgreSQL Database", (server) ->
  indivoDB server, (error) ->
    throw error if error

module.exports = {indivoDB}
