#!/bin/bash

rm old/results/ -r
mv results/ old/
mkdir results/
mkdir results/data/
mkdir results/analysis/
mkdir results/plots

homeDir=$(pwd)
strainDir=$(echo $homeDir/strain_ranges)
resultsDir=$(echo $homeDir/results)
dataDir=$(echo $resultsDir/data)
analysisDir=$(echo $resultsDir/analysis)
plotsDir=$(echo $resultsDir/plots)

lattice=(0.980  0.985  0.990  0.995  1.00  1.005  1.010  1.015  1.020)
position=(up down)

printf "%-10.9s%5.5s  %10.9s  %10.9s  %10.9s   %10.9s\n" "Lattice" "Image" "Z   " "X   " "Y   " "Volume" | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt $analysisDir/tot_dipole_moment.txt >/dev/null

echo "-------------------------------------------------------------------------" | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt  $analysisDir/tot_dipole_moment.txt >/dev/null

printf "%-10.9s%5.5s  %10.9s  %10.9s  %10.9s   %10.9s\n" "Strain" "--" "(e-Ang)" "(e-Ang)" "(e-Ang)" "(Ang^3)" | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt  $analysisDir/tot_dipole_moment.txt >/dev/null

echo "-------------------------------------------------------------------------" | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt  $analysisDir/tot_dipole_moment.txt >/dev/null


for lat in "${lattice[@]}"
do

 latDir=$(echo "$strainDir"/"$lat")
 cd $latDir
 printf  "\t\t#######################\n\t\t######## %s ########\n\t\t#######################\n\n" "$lat">> $dataDir/postCalcErrors.txt
 printf  "\n#######################\n######## %s ########\n#######################\n\n" "$lat">> $dataDir/run_Time_Mem.txt
 printf  "\n#######################\n######## %s ########\n#######################\n\n" "$lat">> $dataDir/raw_polarization.txt


    for curDir in */ ;
    do
            
            cd $curDir
            image=$(echo $curDir |sed -E 's/\///')

############################
######## Get Errors ########
############################

            printf  "\n####################\n######## %s ########\n####################\n\n" "$image">> $dataDir/postCalcErrors.txt
            grep -E 'error|EEEE' log.out >> $dataDir/postCalcErrors.txt

################################
######## Get Time & Mem ########
################################            
            printf  "\t\t####################\n\t\t######## %s ########\n\t\t####################\n\n" "$image">> $dataDir/run_Time_Mem.txt
            grep -E 'Maximum memory used|Total CPU time used' OUTCAR >> $dataDir/run_Time_Mem.txt

#################################
######## Get Dipole Info ########
#################################
            
       ## RAW DATA ##
            printf  "\t\t####################\n\t\t######## %s ########\n\t\t####################\n\n" "$image">> $dataDir/raw_polarization.txt
            grep -E 'dipole moment' OUTCAR >> $dataDir/raw_polarization.txt

       ## X,Y,Z components ##
            
            printf "%-10.9s%5.5s  " "$lat" "$image" | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt >/dev/null
            grep 'Ionic dipole moment' OUTCAR | awk '{ printf ("%10.9s  %10.9s  %10.9s  ",$7, $5, $6) }' >> $dataDir/ionic_dipole_moment.txt
            grep 'electronic dipole moment' OUTCAR | awk '{ printf ("%10.9s  %10.9s  %10.9s  ",$8, $6, $7) }' >> $dataDir/electronic_dipole_moment.txt

############################
######## Get Volume ########
############################

            grep 'volume of' OUTCAR | tail -n 1 | awk '{ printf ("%10.9s \n", $5) }' | tee -a $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt >/dev/null
            
           cd $latDir
    done

done

cd $homeDir


##########################
######## Analysis ########
##########################

cd $analysisDir

### summing ionic and electronic contributions ###
paste $dataDir/ionic_dipole_moment.txt $dataDir/electronic_dipole_moment.txt | tail -n +5 | \
awk '{printf ("%-10.9s%5.5s  %10.9s  %10.9s  %10.9s   %10.9s\n", $1, $2, $3 + $9, $4 + $10, $5 + $11, $6 ) }' \
 >> $analysisDir/tot_dipole_moment.txt


### Converting to polarization ###

printf "%-6.6s%5.5s  %12.12s  %10.9s  %10.9s\n" "Strain" "Image" "Pz  " "Px  " "Py  " >> $analysisDir/polarization_data.txt 
echo "-------------------------------------------------------------------------" >> $analysisDir/polarization_data.txt 
printf "%-6.6s%5.5s  %12.12s  %10.9s  %10.9s\n" "  %" "--" "(C/m^2)" "(C/m^2)" "(C/m^2)" >> $analysisDir/polarization_data.txt 
echo "-------------------------------------------------------------------------" >> $analysisDir/polarization_data.txt 

tail -n +5 $analysisDir/tot_dipole_moment.txt | \
awk '{scale=16.021 / $6; strain= ($1 - 1)*100; printf ("%+1.1f%5.5s  %12.12s  %10.9s  %10.9s\n", strain, $2, $3*scale, $4*scale, $5*scale  ) }' \
 >> $analysisDir/polarization_data.txt

### make plot ready ###
cd $plotsDir

echo 'strain,pz,px,py,distortion,image' >> $plotsDir/polarization_plot.dat
tail -n +5 $analysisDir/polarization_data.txt | \
awk '{dis=($2-5)*20; printf ("%s,%2.10f,%s,%s,%s,%s\n", $1, $3, $4, $5, dis, $2 ) }' \
 >> $plotsDir/polarization_plot.dat



