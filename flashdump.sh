#!/bin/bash
#set -vx
BASEDIR=`basedir $0`
PATH=$BASEDIR/bin:$PATH
export PATH

sudo rkflashtool r 0 1 >parm
mkkrnlimg -r parm parameter
PARAMFILE="parameter"

MODEL=`grep MACHINE_MODEL ${PARAMFILE}|cut -d: -f2|tr -d "\n\r"`
PARTS=`grep CMDLINE ${PARAMFILE}|cut -d: -f3|tr -d "\n\r"`

PARTS=(${PARTS//,/ })

REGEX1="(0x[0-9a-fA-F]*)@(0x[0-9a-fA-F]*)\(([a-z]*)\)"

mkdir flashdump
for PART in "${PARTS[@]}"
do
	if [[ "${PART}" =~ ${REGEX1} ]]
	then
		ssize=${BASH_REMATCH[1]}
		sstart=${BASH_REMATCH[2]}
		sname=${BASH_REMATCH[3]}

		cmd=`printf "rkflashtool r 0x%08x 0x%08x " ${sstart} ${ssize}`
		sudo $cmd > flashdump/${sname}
	fi
done

