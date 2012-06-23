conf = require "../conf"
control = require "control"

#MD5 of "indivo" is 3194fed403269ee73581b217de394c36

indivoDB = (server, callback) ->
  script = """#!/bin/sh
su postgres -c psql <<'EOF' > /dev/null
DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'indivo') THEN

      CREATE ROLE indivo LOGIN ENCRYPTED PASSWORD 'md53194fed403269ee73581b217de394c36' SUPERUSER;
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
