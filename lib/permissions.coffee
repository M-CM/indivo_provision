permissions = (owner) ->
  """chown -R #{owner} .
chmod -R 440 .
find . -type d -print0 | xargs -0 chmod 550
"""

module.exports = permissions
