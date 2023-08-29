#!/bin/sh



k=$(head -n 3 POSCAR  | tail -n 1 | cut -c5-22)
name=$(head -n 1 POSCAR | sed -r 's/\s+//g')

cd lattice_calculations/

for i in *; do
    if [ -d "$i" ]; then

	# calculate actual lattice spaceing used
	j=$(bc <<< "scale=3; $k * $i / 1")

	# print the latice spacing column with a tab character after
	printf "$i%s\t$j%s\t" >> energyCalcs_${name}.txt

	cd "$i"/
	# get the total energy from OUTCAR and reduce the characters to the number values
	cat OUTCAR | grep 'free  energy   TOTEN  =' >> tmpENRG
	tail -1 tmpENRG |\
	sed 's/  free  energy   TOTEN  =       //' |\
	sed 's/ eV//' >> ../energyCalcs_${name}.txt

	rm WAVECAR
	rm run.dzvasp544
	cd ../

    fi
done

echo "All Calcs Done!!!"
