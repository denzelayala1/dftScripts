#!/bin/bash

sysName='CuInP2S6'
images='9' # WARNING: need to change nodes and cores in script below to match this number
type='dos' #either 'dos' or 'bands'
projection=true #do you want projections? boolean

homeDir=$(pwd)
strainDir=$(echo $homeDir/strain_ranges)
inputs=$(echo $homeDir/inputs)
if [ -d $homeDir/../scf ]

        scfStrainDir=$(echo $homeDir/../scf/strain_ranges)
elif [ -d $homeDir/../polarization ]
        scfStrainDir=$(echo $homeDir/../polarization/strain_ranges)
else
        echo -e "\n\tERROR! There is no scf or polarization directory to get CHGCAR from. Make sure directory exists"
        exit 2
fi
cellOpDir=$(echo $homeDir/../cellOp)
ported_filesDir=$(echo $cellOpDir/ported_files)


if [ -d $homeDir/strain_ranges ];
then
        rm -r $homeDir/zz_old_strain_ranges
       mv $homeDir/strain_ranges $homeDir/zz_old_strain_ranges
        echo -e "\nWARNING: There was already directory named strain_ranges. It was moved to:\n\t $homeDir/zz_strain_r
anges\n\t Make sure something you need wasn't deleted \n"
fi

if [ -d $homeDir/inputs ];
then
        rm -r $homeDir/zz_old_inputs
       mv $homeDir/inputs $homeDir/zz_old_inputs
        echo -e "\nWARNING: There was already directory named inputs. It was moved to:\n\t $homeDir/inputs\n\t Make su
re something you need wasn't deleted \n"
fi

mkdir $homeDir/strain_ranges $homeDir/inputs

if [ ! -d $ported_filesDir ];
then
        echo -e "\n\tERROR! DIRECTORY: $ported_filesDir \n\tDOES NOT EXIST. This script requires POTCAR, INCAR, and KP
OINTS to be in the \"cellOp/ported_files\" directory.\nAlso make sure this directory is parallel to cellOp. (i.e. cd \
$this_directory/../cellOp works)\n"
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

        match='ICHARG'
        insert='ICHARG   = 11'
        sed -i "s/.*$match.*/$insert/" $file

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
        insert='KPAR    = 4'
        sed -i "s/.*$match.*/$insert/" $file

        match='NCORE '
        insert='NCORE   = 4'
        sed -i "s/.*$match.*/$insert/" $file

        if [ $projection ];
        then 
            match='LORBIT '
            insert='LORBIT = 11'
            sed -i "s/.*$match.*/$insert/" $file
        fi

        if [ $type == 'dos'];
        then
            match='ISMEAR '
            insert='ISMEAR  = -5'
            sed -i "s/.*$match.*/$insert/" $file
            
            printf "%s/n%s/n%s" "EMIN = -15" "EMAX = 10" "NEDOS = 401" >> $file
        fi 

        ##############################################
        ########  make Bands KPOINTS Template ########
        ##############################################

        if [ $type == 'bands'];
        then
            kpath=$(printf "k-points along high symmetry lines
            60
            Line-mode
            Reciprocal
            0.00000000      0.50000000   0.00  #M
            0.00000000      0.00000000   0.00  #G

            0.000000000      0.000000000 0.00  #G
            0.33333333      0.33333333   0.00  #K

            0.33333333      0.33333333   0.00  #K
            0.00000000      0.50000000   0.00  #M

            ")

            printf "$kpath" > KPOINTS

            echo "band calculation band path given by: "
            printf "\n$kpath\n"
            echo "change the path in this run script if needed (line 112)."
        fi

        ######################################
        ########  make Slurm Template ########
        ######################################


        file=$(echo $inputs/run.dzvasp544_TEMPLATE)

        match='#SBATCH --time'
        insert='#SBATCH --time=00:20:00'
        sed -i "s/.*$match.*/$insert/" $file

        match='##SBATCH --mem'
        insert='#SBATCH --mem=14000'
        sed -i "s/.*$match.*/$insert/" $file


        ##################################
        ########  loop and cp all ########
        ##################################

cd $scfStrainDir

for lat in *;
do
       if [ -d "$lat" ];
       then

              mkdir "$strainDir"/$lat
              latDir=$(echo "$strainDir"/$lat)
              scfLatDir=$(echo "$scfStrainDir"/$lat)

              k=$(bc <<< " $images + 1")

              for ((m=0;m<=$k;m++));
              do

                     if [ $m -lt 10 ];
                     then
                            m=$(echo "0$m")
                    fi

                     mkdir $latDir/$m

                     cp $inputs/KPOINTS $latDir/$m/KPOINTS
                     cp $inputs/POTCAR $latDir/$m/POTCAR
                     cp $scfLatDir/$m/POSCAR $latDir/$m/POSCAR
                     cp $scfLatDir/$m/CHGCAR $latDir/$m/CHGCAR

                     echo SYSTEM    = $sysName $type strain:$lat  img:$m >> $latDir/$m/INCAR
                     tail -n +2 $inputs/INCAR_TEMPLATE >> $latDir/$m/INCAR

                     cp $inputs/run.dzvasp544_TEMPLATE $latDir/$m/run.dzvasp544
                     file=$(echo $latDir/$m/run.dzvasp544)

                     match=$(echo --job-name)
                     insert=$(echo \#SBATCH --job-name=dayala_DFT_${sysName}_${type}_strain_${lat}_im_$m)
                     sed -i "s/.*$match.*/$insert/" $file


                     if [ $m -eq $k ];
                     then
                            match=$(echo --mail-user)
                            insert="#SBATCH --mail-user=denzelay@buffalo.edu"
                            sed -i "s/.*$match.*/$insert/" $file
                     fi

                     cd $latDir/$m/
                     m=$(bc <<< "$m + 0")
                     #sbatch run.dzvasp544
              done

       fi
       cd $scfStrainDir
done


