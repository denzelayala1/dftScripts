#!/bin/bash

sysName='In2Se3'
images='9' # WARNING: need to change nodes and cores in script below to match this number


homeDir=$(pwd)
strainDir=$(echo $homeDir/strain_ranges)
inputs=$(echo $homeDir/inputs)
nebStrainDir=$(echo $homeDir/../neb/strain_ranges)
cellOpDir=$(echo $homeDir/../cellOp)
ported_filesDir=$(echo $cellOpDir/ported_files)


if [ -d $homeDir/strain_ranges ];
then
	rm -r $homeDir/zz_old_strain_ranges
       mv $homeDir/strain_ranges $homeDir/zz_old_strain_ranges
	echo -e "\nWARNING: There was already directory named strain_ranges. It was moved to:\n\t $homeDir/zz_strain_ranges\n\t Make sure something you need wasn't deleted \n"
fi

if [ -d $homeDir/inputs ];
then
	rm -r $homeDir/zz_old_inputs
       mv $homeDir/inputs $homeDir/zz_old_inputs
	echo -e "\nWARNING: There was already directory named inputs. It was moved to:\n\t $homeDir/inputs\n\t Make sure something you need wasn't deleted \n"
fi

mkdir $homeDir/strain_ranges $homeDir/inputs

if [ ! -d $ported_filesDir ];
then
	echo -e "\n\tERROR! DIRECTORY: $ported_filesDir \n\tDOES NOT EXIST. This script requires POTCAR, INCAR, and KPOINTS to be in the \"cellOp/ported_files\" directory.\nAlso make sure this directory is parallel to cellOp. (i.e. cd \$this_directory/../cellOp works)\n"
       exit 2
fi

cp $ported_filesDir/INCAR $inputs/INCAR_TEMPLATE
cp $ported_filesDir/KPOINTS $inputs
cp $ported_filesDir/POTCAR $inputs
cp ~/.local/bin/run_16cores.dzvasp544 $inputs/run.dzvasp544_TEMPLATE

        ######################################
        ########  make INCAR Template ########
        ######################################

    ### doing Polarization Calculation ###
        file=$(echo $inputs/INCAR_TEMPLATE)

	 match='ENCUT'
        insert='ENCUT   = 450'
        sed -i "s/.*$match.*/$insert/" $file

        match='IBRION '
        insert='IBRION  = -1'
        sed -i "s/.*$match.*/$insert/" $file

        match='ISIF '
        insert='ISIF    = 2'
        sed -i "s/.*$match.*/$insert/" $file

        match='NSW  '
        insert='NSW     = 0'
        sed -i "s/.*$match.*/$insert/" $file

        match='KPAR '
        insert='KPAR    = 16'
        sed -i "s/.*$match.*/$insert/" $file

        match='NCORE '
        insert='NCORE   = 1'
        sed -i "s/.*$match.*/$insert/" $file

        insert='DIPOL = 0.5 0.5 0.2'
        echo $insert >> $file

        insert='LCALCPOL=.TRUE.'
        echo $insert >> $file

        
        ######################################
        ########  make Slurm Template ########
        ######################################

        file=$(echo $inputs/run.dzvasp544_TEMPLATE)

        match='#SBATCH --time'
        insert='#SBATCH --time=00:30:00'
        sed -i "s/.*$match.*/$insert/" $file

        match='##SBATCH --mem'
        insert='#SBATCH --mem=28000'
        sed -i "s/.*$match.*/$insert/" $file


        ##################################
        ########  loop and cp all ########
        ##################################

cd $nebStrainDir

for lat in *;
do
       if [ -d "$lat" ]; 
       then

              mkdir "$strainDir"/$lat
              latDir=$(echo "$strainDir"/$lat)
              nebLatDir=$(echo "$nebStrainDir"/$lat)

              k=$(bc <<< " $images + 1")

              cpFromDir=$(echo $nebLatDir)

              for ((m=0;m<=$k;m++));
              do

                     if [ $m -lt 10 ];
                     then
                            m=$(echo "0$m")
                     fi

                     mkdir $latDir/$m

                     cp $inputs/KPOINTS $latDir/$m/KPOINTS
                     cp $inputs/POTCAR $latDir/$m/POTCAR

                     cp $cpFromDir/$m/POSCAR $latDir/$m/POSCAR
                     prevDir=$(pwd)
                     cd $latDir/$m
                     reposition_poscar.sh
                     cd $prevDir
                            
                     echo SYSTEM    = $sysName polarization strain:$lat  img:$m >> $latDir/$m/INCAR
                     tail -n +2 $inputs/INCAR_TEMPLATE >> $latDir/$m/INCAR

                     cp $inputs/run.dzvasp544_TEMPLATE $latDir/$m/run.dzvasp544
                     file=$(echo $latDir/$m/run.dzvasp544)

                     match=$(echo --job-name)
                     insert=$(echo \#SBATCH --job-name=dayala_DFT_${sysName}_strain_${lat}_im_$m)
                     sed -i "s/.*$match.*/$insert/" $file
                     
                     if [ $m -eq $k ];
                     then
                            match=$(echo --mail-user)
                            insert="#SBATCH --mail-user=denzelay@buffalo.edu"
                            sed -i "s/.*$match.*/$insert/" $file
                     fi

                     cd $latDir/$m/
                     m=$(bc <<< "$m + 0")
                     sbatch run.dzvasp544 
              done

       fi 
       cd $nebStrainDir
done


