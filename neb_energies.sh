#!/bin/sh


export tmp_k=$(grep 'IMAGES =' INCAR | awk '{ print $3 }')
export k=$(bc <<< "$tmp_k + 1")
mkdir outTMP
cp 0* outTMP -r
cd outTMP

for i in *; do
    if [ -d "$i" ]; then

	# calculate actual lattice spaceing used
	j=$(bc <<< "scale=2; $i / $k")

	# print the latice spacing column with a tab character after
	printf "$i%s\t$j%s\t" >> ../NEB_energyCalcs_${k}_steps.txt

	cd "$i"/
	# get the total energy from OUTCAR and reduce the characters to the number values
	cat OUTCAR | grep 'free  energy   TOTEN  =' >> tmpENRG
	tail -1 tmpENRG |\
	sed 's/  free  energy   TOTEN  =       //' |\
	sed 's/ eV//' >> ../../NEB_energyCalcs_${k}_steps.txt

	cd ../

    fi
done
cd ../
rm -r outTMP/
echo "All Calcs Done!!!"
