#!/bin/sh

# make array of lattice constant values

homeDir=$(pwd)

reposition_poscar.sh

rdyStatus=$(vaspkit -task 108 | grep -i 'error')

if [ -z "$rdyStatus" ]
then


      echo "Starting Series"
        lattice=(0.980 0.985 0.990 0.995 1.00 1.005 1.010 1.015 1.020 )


        # make directory where everything will be run and stored
        mkdir lattice_calculations
        latDir=$(echo $homeDir/lattice_calculations)
        cd $latDir

        # iterate over the array values
        for i in "${lattice[@]}"

        do

        # create a new directory and copy in files needed for a run
        mkdir "$i"
        workDIR=$(echo $latDir/$i)
        cd $workDIR

        cp $homeDir/POTCAR $workDIR
        cp $homeDir/INCAR $workDIR
        cp $homeDir/KPOINTS $workDIR
        cp $homeDir/POSCAR $workDIR/COPY
        cp /user/denzelay/.local/bin/run_16cores.dzvasp544 $workDIR

        # extract the size of the vacuum and make sure
        # that it is constant for all lattice sizes
        # base_vac is the zz component
        # meanwhile the xz and yz components are not scaled
        base_vac=$(awk 'FNR == 5 {print $3}' COPY)
        scaled_vac=$(bc <<< "scale=16;$base_vac/$i")
        xz_yz=$(awk 'FNR == 5 {printf ("    %18s    %17s", $1 , $2)}' COPY)


        # create POSCAR with the lattice constant of this given loop
        head -1 COPY >> POSCAR

        printf ""$i"\n" >> POSCAR
        awk 'FNR==3 ,FNR==4' COPY >> POSCAR
        printf "    %s" $xz_yz >> POSCAR
        printf "    "$scaled_vac"\n" >> POSCAR
        tail --lines=+6 COPY >> POSCAR

        rm COPY

        # submit and run individual calculation and wait for output
        printf "lattice:  "$i"\t" >> $homeDir/jobID_2_lattice.txt
        sbatch run_16cores.dzvasp544 | tee -a $homeDir/jobID_2_lattice.txt
        cd $latDir

        done

         cd $homeDir
        echo "All Calculations Submitted!!!"
else
        echo "$rdyStatus"

        # create POTCAR based on the POSCAR
        vaspkit -task 103
fi




