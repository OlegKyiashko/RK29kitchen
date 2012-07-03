#!/bin/bash

BASEDIR=`dirname $0`
pushd $BASEDIR >/dev/null
BASEDIR=$(pwd)
popd >/dev/null
PATH=$BASEDIR:$PATH

pngtopnm -plain $1 | ppmquant -plain 224  > $1.ppm
pnmtologoclut224 $1.ppm
