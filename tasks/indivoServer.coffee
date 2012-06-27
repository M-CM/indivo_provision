conf = require "../conf"
control = require "control"

indivoServer = (server, callback) ->
  script = """#!/bin/sh -e
cd /tmp
SERVER_DIST_URL="#{conf.indivo.serverDistURL}"
ARCHIVE=$(basename "${SERVER_DIST_URL}")
BASE="#{conf.indivo.installPrefix}"
if [ ! -f "${ARCHIVE}" ]; then #@BUG temp dev optimization
  curl --silent --remote-name "${SERVER_DIST_URL}"
fi
if [ -d "${BASE}" ]; then
  mv "${BASE}" "${BASE}.old.$$"
fi
mkdir -p "${BASE}"
tar xzf "${ARCHIVE}" -C "${BASE}"
#rm "${ARCHIVE}" #@BUG temp dev optimization
cd "${BASE}/indivo_server"
cp settings.py.default settings.py
cat << EOF >> settings.py
########## BEGIN M-CM CUSTOMIZATION ##########
#Everything above this should be a clean copy of the settings.py.default file
#From here down are just what is customized for M-CM's particular installation
ADMINS = ('Christy Collins', 'christy@m-cm.net')

# Make this unique, and don't share it with anybody.
SECRET_KEY = 'M-CMDEVELOPMENT-INDIVO-SECRET-KEY'

# URL prefix (where indivo_server will be accessible from the web)
SITE_URL_PREFIX = "http://#{server.address}"

# Storage Settings
DATABASES = {
    'default':{
        'ENGINE':'django.db.backends.postgresql_psycopg2', # '.postgresql_psycopg2', '.mysql', or '.oracle'
        'NAME':'indivo',
        'USER':'indivo',
        'PASSWORD':'indivo',
        'HOST':'127.0.0.1', # Set to empty string for localhost.
        'PORT':'', # Set to empty string for default.
        },
}
EOF

cat << EOF > utils/indivo_data.xml
<bootstrap>
  <auth_systems>
    <auth_system short_name='auth_system_example' internal_p='False' />
  </auth_systems>
  <accounts>
    <account email='christy@m-cm.net'>
      <full_name>Christy Collins</full_name>
      <contact_email>christy@m-cm.net</contact_email>
      <username>christycollins</username>
      <password>password</password>
      <records>
      </records>
    </account>
  </accounts>
  <status_names>
    <status id='1' name='active' />
    <status id='2' name='void' />
    <status id='3' name='archived' />
  </status_names>
  <document_schemas>
    <document_schema type='http://indivo.org/vocab/xml/documents#Contact' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Demographics' />
    <document_schema type='http://indivo.org/vocab/documentrels#answers' />
    <document_schema type='http://indivo.org/vocab/documentrels#annotation' />
    <document_schema type='http://indivo.org/vocab/documentrels#interpretation' />
    <document_schema type='http://indivo.org/vocab/documentrels#followup' />
    <document_schema type='http://indivo.org/vocab/documentrels#attachment' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Survey' />
    <document_schema type='http://indivo.org/vocab/xml/documents#SurveyAnswers' />
    <document_schema type='http://indivo.org/vocab/xml/documents#UserPreferences' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Allergy' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Annotation' />
    <document_schema type='http://indivo.org/vocab/xml/documents#AsthmaActionPlan' />
    <document_schema type='http://indivo.org/vocab/xml/documents#SimpleClinicalNote' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Equipment' />
    <document_schema type='http://indivo.org/vocab/xml/documents#HBA1C' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Immunization' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Lab' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Medication' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Problem' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Procedure' />
    <document_schema type='http://indivo.org/vocab/xml/documents#SchoolForm' />
    <document_schema type='http://indivo.org/vocab/xml/documents#SimpleClinicalNote' />
    <document_schema type='http://indivo.org/vocab/xml/documents#VitalSign' />
    <document_schema type='http://indivo.org/vocab/xml/documents#EncryptedDocument' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Genotype' />
    <document_schema type='http://indivo.org/vocab/xml/documents#Models' />
  </document_schemas>
</bootstrap>
EOF
echo yes | python utils/reset.py
"""
  server.script script, true, callback

control.task "indivoServer", "Install the Indivo Server Software", (server) ->
  indivoServer server, (error) ->
    throw error if error

module.exports = {indivoServer}
