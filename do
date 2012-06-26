#!/bin/sh -e
cd $(dirname "${0}")
NODE_PATH="./node/bin/node"
NPM_PATH=$(dirname "${NODE_PATH}")/npm
COFFEE_PATH="./node_modules/.bin/coffee"

install_node() {
  local VERSION="${1-latest}"
  local DIST="http://nodejs.org/dist/${VERSION}"
  local ARCHIVE=$(curl --silent ${DIST}/ | egrep '[0-9]\.tar\.gz' | \
      sed -e 's/\.gz.*/.gz/' -e 's/.*node/node/')
  echo "Installing Node.js version ${ARCHIVE}"
  curl --silent --remote-name "${DIST}/${ARCHIVE}"
  tar xzf "${ARCHIVE}"
  rm "${ARCHIVE}"
  local DIR=$(echo "${ARCHIVE}" | sed 's/\.tar\.gz//')
  cd "${DIR}"
  ./configure --prefix=$(dirname $(pwd))/node
  make install
  cd ..
  mv "${DIR}" node
  #@todo delete node source we don't need
  #The fact that node/bin/npm is a symlink is a PITA
}

ensure_node() {
  local TARGET_VERSION=$(python ./util/print_node_version.py package.json)
  if [ -x "${NODE_PATH}" ]; then
    local INSTALLED_VERSION=$("${NODE_PATH}" --version)
    if [ "${INSTALLED_VERSION}" == "${TARGET_VERSION}" ]; then
      #all good
      return 0
    else
      echo "node.js version ${INSTALLED_VERSION} installed, but we need version ${TARGET_VERSION}. Installing..."
      mv node node.old.$$
    fi
  else
    echo "node.js not installed in ${NODE_PATH}, installing..."
  fi
  install_node "${TARGET_VERSION}"
}

ensure_coffee() {
  ensure_node
  if [ ! -x "${COFFEE_PATH}" ]; then
    "${NPM_PATH}" install
  fi
}

case "${1}" in
  setup)
    ensure_coffee
    echo "Prerequisites are installed and ready"
  ;;
  *)
    ensure_coffee
    "${COFFEE_PATH}" makitso.coffee "${@}"
  ;;
esac
