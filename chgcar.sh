#!/bin/sh

FILE=scf/CHGCAR

if [ -f "$FILE" ]; then
	cp scf/CHGCAR bands/
	cp scf/CHGCAR DOS/

	echo "CHGCAR transfered from SCF"
else
	echo "CHGCAR does not exist"
fi
