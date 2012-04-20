#!/bin/bash
#set -vx

MenuAdd "Remove 'blacklist' files" "blacklistRemoveAll"

blacklistRemoveAll(){
	pushd "${WORKDIR}/Image"
	sudo mount system.img system -o loop 2> /dev/null
        d=`pwd`
	for f in `cat "${PLUGINS}/blacklist/blacklist.txt"|grep -v "^ *#"`
	do
       		echo rm -f "$d/$f"  >>"${LOGFILE}"
        	sudo rm -f "$d/$f"  2>>"${LOGFILE}"
	done
	popd

        echo "Partition system is cleaned"
}

