#!/bin/sh

node=`which node 2>&1`
ret=$?
if [ $ret -ne 0 ] || ! [ -x $node ]; then
  echo "npm cannot be installed without nodejs." >&2
  echo "Install node first, and then try again." >&2
  exit $ret
fi

TMP="${TMPDIR}"
if [ "x$TMP" = "x" ]; then
  TMP="/tmp"
fi
TMP="${TMP}/npm.$$"
rm -rf "$TMP" || true
mkdir "$TMP"
if [ $? -ne 0 ]; then
  echo "failed to mkdir $TMP" >&2
  exit 1
fi

BACK="$PWD"
tar="${TAR}"
if [ -z "$tar" ]; then
  # sniff for gtar/gegrep
  # use which, but don't trust it very much.
  tar=`which gtar 2>&1`
  if [ $? -ne 0 ] || ! [ -x $tar ]; then
    tar=tar
  fi
fi

egrep=`which gegrep 2>&1`
if [ $? -ne 0 ] || ! [ -x $egrep ]; then
  egrep=egrep
fi

node_version=`node --version 2>&1`
if echo $node_version | $egrep -qE "^0\.([01]\..+|2\.[0-2]$)"; then
  echo "You need node v0.2.3 or higher to run this program." >&2
  exit $ret
fi

make=`which gmake 2>&1`
if [ $? -ne 0 ] || ! [ -x $make ]; then
  make=`which make 2>&1`
  if [ $? -ne 0 ] || ! [ -x $make ]; then
    make=NOMAKE
    echo "Installing without make. This may fail." >&2
  fi
fi

url=`curl http://registry.npmjs.org/npm/latest \
      | $egrep -o 'tarball":"[^"]+' \
      | $egrep -o 'http://.*'`
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to get tarball url" >&2
  exit $ret
fi

cd "$TMP" \
  && curl -L "$url" | $tar -xzf - \
  && cd * \
  && (if ! [ "$make" = "NOMAKE" ]; then
        $make uninstall dev
      else
        $node cli.js install .
      fi) \
  && cd "$BACK" \
  && rm -rf "$TMP" \
  && echo "It worked"
ret=$?
if [ $ret -ne 0 ]; then
  echo "It failed" >&2
fi
exit $ret
