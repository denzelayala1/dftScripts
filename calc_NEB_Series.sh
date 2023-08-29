#!/bin/sh

sysName='In2Se3'
images='9' # WARNING: need to change nodes and cores in script below to match this number
initial_state='left'
final_state='right'



homeDir=$(pwd)
cellOpDir=$(echo $homeDir/../cellOp)
portedDir=$(echo $homeDir/../cellOp/ported_files)
strainDir=$(echo $homeDir/strain_ranges)
inputs=$(echo $homeDir/inputFiles)

rm -r inputFiles strain_ranges
mkdir inputFiles strain_ranges

cp ~/.local/bin/run_16cores.dzvasp544 $inputs/run_NEB.dzvasp544_TEMPLATE
cp $portedDir/INCAR $inputs/INCAR_TEMPLATE
cp $portedDir/KPOINTS $inputs
cp $portedDir/POTCAR $inputs

        ######################################
        ########  make INCAR Template ########
        ######################################

    ### doing Nudged Elastic Band Calculation 
        file=$(echo "$inputs"/INCAR_TEMPLATE)
        
		match='ENCUT'
        insert='ENCUT   = 450'
        sed -i "s/.*$match.*/$insert/" $file

		match='IBRION '
        insert='IBRION  = 1    #  quasi-Newton (variable metric) ionic relaxation'
        sed -i "s/.*$match.*/$insert/" $file

		match='ISIF '
        insert='ISIF    = 2    # atomic relax only '
        sed -i "s/.*$match.*/$insert/" $file

		match='KPAR'
        insert='KPAR    = 3'
        sed -i "s/.*$match.*/$insert/" $file

		printf "\nIMAGES = %s\nSPRING = -5\n\n" "$images" >> $inputs/INCAR_TEMPLATE


        ######################################
        ########  make Slurm Template ########
        ######################################


        file=$(echo "$inputs/run_NEB.dzvasp544_TEMPLATE")

        match='--time'
        insert='#SBATCH --time=08:00:00'
        sed -i "s/.*$match.*/$insert/" $file

		match='--nodes'
        insert='#SBATCH --nodes=4'
        sed -i "s/.*$match.*/$insert/" $file

		match='--ntasks-per-node'
        insert='#SBATCH --ntasks-per-node=27'
        sed -i "s/.*$match.*/$insert/" $file

		match='--mem'
        insert='#SBATCH --mem=40000'
        sed -i "s/.*$match.*/$insert/" $file

		match='--mail-user='
        insert='#SBATCH --mail-user=denzelay@buffalo.edu'
        sed -i "s/.*$match.*/$insert/" $file

cd $cellOpDir

for dir in *;
do 
if [ -d "$dir" ]; then

	echo -e "\tvariable dir is: $dir"
	checkDir=$(echo $cellOpDir/$dir	)
	cd $checkDir

	if [ ! -d $checkDir/lattice_calculations ];
  	then
    	cd $cellOpDir
        continue
    	fi

	if [ "$dir" == "initial_state" ];
	then
		echo -e "\tvariable dir is: $dir\n\tShould be initial_state"
		p=$(echo $initial_state)
	elif [ "$dir" == "final_state" ];
	then
		echo -e "\tvariable dir is: $dir\n\tShould be final_state"
		p=$(echo $final_state)
	else
		echo -e "\n\nERROR: WARNING DIRECTORIES NOT PROPERLY NAMED \nCHECK TO MAKE SURE THERE IS AN \"initial_state\" AND \"final_state\" DIRECTORY\n\n"
		exit 2
	fi

	seriesDir=$(echo $checkDir/lattice_calculations)
	cd $seriesDir

	for i in *;
	do

		if [ ! -d $strainDir/"$i" ];
		then
			mkdir $strainDir/"$i"
		fi

		cpFromDir=$(echo $seriesDir/$i)
		latDir=$(echo $strainDir/"$i")
		cd "$latDir"

		if [ "$p" == "$final_state" ];
		then

			cp $cpFromDir/OUTCAR $latDir/OUTCAR_"$p"
			cp $cpFromDir/CONTCAR $latDir/POSCAR
			cd "$latDir"
			reposition_poscar.sh
			mv $latDir/POSCAR $latDir/POSCAR_"$p"
			sed -i "1s/.*/${sysName}_${i}_${p}/" $latDir/POSCAR_"$p"

		elif [ "$p" == "$initial_state" ];
		then

			cp "$inputs"/POTCAR $latDir/
			cp "$inputs"/KPOINTS $latDir/

			cp $cpFromDir/OUTCAR $latDir/OUTCAR_"$p"
			cp $cpFromDir/CONTCAR $latDir/POSCAR
			cd "$latDir"
			reposition_poscar.sh
			mv $latDir/POSCAR $latDir/POSCAR_"$p"
			sed -i "1s/.*/${sysName}_${i}_${p}/" $latDir/POSCAR_"$p"

			cp "$inputs"/INCAR_TEMPLATE $latDir/INCAR
			cp "$inputs"/run_NEB.dzvasp544_TEMPLATE $latDir/run_NEB.dzvasp544
		
			file=$(echo "$latDir/INCAR")

			match='SYSTEM'
			insert=$(echo "SYSTEM    = $sysName NEB $i strain $initial_state to $final_state")
			sed -i "s/.*$match.*/$insert/" $file


			file=$(echo "$latDir/run_NEB.dzvasp544")
			match='--job-name'
			insert=$(echo "#SBATCH --job-name=dayala_NEB_"$sysName"_"$i"_"$images"_steps")
			sed -i "s/.*$match.*/$insert/" $file

		else
			echo -e "ERROR: WARNING VARIABLE MISLABELED\n\n CHECK SHELL SCRIPT FOR \"initial_state\" AND \"final_state\" NAMES \n\n"
			exit 8
		fi

		if [ -e $latDir/POSCAR_"$initial_state" ] && [ -e $latDir/POSCAR_"$final_state" ];
		then
			
			cd $latDir

			echo -e "505\nPOSCAR_"$initial_state" POSCAR_"$final_state" "$images"\n" | vaspkit >> vk.out 

			maxDir=$(bc <<< "$images + 1" )
			cp $latDir/OUTCAR_$initial_state $latDir/00/OUTCAR
			if [ $maxDir -lt 10 ];
			then
				$maxDir=$(echo "0$maxDir")
			fi
			cp $latDir/OUTCAR_$final_state $latDir/$maxDir/OUTCAR

			printf "$i job reached:\t"
			#sbatch run_NEB.dzvasp544
		fi

		cd $cellOpDir
	done	
fi
done


