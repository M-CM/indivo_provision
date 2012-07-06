permissions = (owner, fileMode="440", dirMode="550") ->
  """chown -R #{owner} .
chmod -R #{fileMode} .
find . -type d -print0 | xargs -0 chmod #{dirMode}
"""

module.exports = permissions
