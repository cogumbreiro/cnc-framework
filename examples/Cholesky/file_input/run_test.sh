#!/bin/bash

# OSX calls the md5 checksum utility 'md5' instead of 'md5sum'
if [ $(uname) = Darwin ]; then
    MD5BIN=md5
else
    MD5BIN=md5sum
fi

# Guess XSTG_ROOT and UCNC_ROOT if they're not already set
export XSTG_ROOT="${XSTG_ROOT-${PWD%/xstg/*}/xstg}"
export UCNC_ROOT="${UCNC_ROOT-${XSTG_ROOT}/apps/hll/cnc}"

# Sanity check on the above paths
if ! [ -f "${UCNC_ROOT}/bin/ucnc_t" ]; then
    echo "ERROR: Failed to find UCNC_ROOT (looking in '${UCNC_ROOT}')"
    exit 1
fi

# Run the translator if needed
[ -d "cnc_support" ] || "${UCNC_ROOT}/bin/ucnc_t"

# Build
make install || exit 1

INPATH="$PWD/inputs"

# Download the input if the user doesn't have an inputs directory
if ! [ -d "$INPATH" ]; then
    mkdir $INPATH
    M2000="$XSTG_ROOT/apps/apps/cholesky/datasets/cholesky2000.tgz"
    if [ -f "$M2000" ]; then
        tar -C "$INPATH" -xzf "$M2000" m_2000.in
    else
        IN_URL=https://raw.githubusercontent.com/habanero-rice/cnc-ocr/9144a5a0f702e844d1b7c78cfe1deef9ae8e9186/examples/choleskyFactorization/inputs/m_2000.in
        curl --compressed -k $IN_URL > $INPATH/m_2000.in
    fi
fi

CNC_TYPE=`readlink Makefile`
CNC_TYPE="${CNC_TYPE#Makefile.}"
CNC_TYPE="${CNC_TYPE:-x86}"

# The md5 checksum of the expected output for the 2000x2000 input matrix
CHKSUM="18ad5f78c6076b565970dd3fe82172c8  ./install/${CNC_TYPE}/Cholesky.out"

make run WORKLOAD_ARGS="2000 ${TILE:-125} $INPATH/m_2000.in" && echo $CHKSUM | $MD5BIN -c -

