#!/bin/bash
#set -vx

MenuAdd "Remove 'blacklist' files" "blacklistRemoveAll"

blacklistRemoveAll(){
	pushd "${WORKDIR}"
	sudo mount system.img system -o loop 2> /dev/null

	for f in `cat "${PLUGINS}/blacklist/blacklist.txt"`
	do
                if [[ $f =~ "^ *#" ]]
                then
                        continue
                fi
       		echo rm -f "Image/$f"  >>"${LOGFILE}"
        	sudo rm -f "Image/$f"  2>>"${LOGFILE}"
	done
	popd

        dialogOK "Partition system is cleaned"
}

