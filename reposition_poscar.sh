#!/bin/bash

echo -e "922\n15\n" | vaspkit > tmp.txt
rm tmp.txt
mv POSCAR old.POSCAR
mv POSCAR_REV POSCAR

atoms=$(head -n +7 POSCAR | tail -n -1 | awk '{for(i=1;i<=NF;i++) t+=$i; print t; t=0}')
endLine=$(bc <<< "$atoms + 8" )

min_x=$(head -n +$endLine POSCAR | tail -n +9 | awk 'NR == 1 { min = $1} NR > 1 && $1 < min { min = $1} END{print min}')
min_y=$(head -n +$endLine POSCAR | tail -n +9 | awk 'NR == 1 { min = $2} NR > 1 && $2 < min { min = $2} END{print min}')
min_z=$(head -n +$endLine POSCAR | tail -n +9 | awk 'NR == 1 { min = $3} NR > 1 && $3 < min { min = $3} END{print min}')


head -n +8 POSCAR > POSCAR_REV
tail -n +9 POSCAR | awk -v minx=$min_x -v miny=$min_y -v minz=$min_z '{x=0.1-minx +$1; y=0.1-miny+ $2; z=$3+0.3-minz;  printf ("   % 1.16f   % 1.16f    % 1.16f    %s\n", x, y, z, $4 ) }' >> POSCAR_REV

mv POSCAR_REV POSCAR
