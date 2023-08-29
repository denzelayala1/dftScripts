#include <algorithm>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <iterator>
#include <limits>

void getKptsAndBands(int* kpts, int* bands, std::string str);
void rearangeData(std::vector<std::string> &vec, std::ifstream &file, std::ofstream &output, int nKpts, int nBands);

int main(int argc, char* argv[]) {
    std::string inName = "PEBS_SUM.dat";
    std::string outName = "REV_" + inName;
    std::string inDir = "./";
    std::string outDir = "./";
    bool verbose = false;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: " << argv[0] << " [options]\n";
            std::cout << "Options:\n";
            std::cout << "-d, --output-dir=DIR_OUT    specify a directory to store output in\n";
            std::cout << "-i, --input-dir=DIR_IN      specify the directory of the input\n";
            std::cout << "-h, --help                  show brief help\n";
            std::cout << "-n, --input=INPUT           specify name of input file\n";
            std::cout << "-o, --output=OUTPUT         specify name of output\n";
            std::cout << "-v, --verbose               Verbose print statements\n"; 
            return 0;
        }
        else if (arg.find("-n") == 0 ) {

            inName = argv[i + 1];
            std::cout << "Input file name: " << inName << "\n";
        }
        else if (arg.find("-o") == 0 ) {
            outName = argv[i + 1];
            std::cout << "Output file name: " << outName << "\n";
        }
        else if (arg.find("-i") == 0 ) {
            inDir = argv[i + 1];
        }
        else if (arg.find("-d") == 0 ) {
            outDir = argv[i + 1];
        }
        else if (arg.find("-v") == 0 ) {
            verbose = true;
        }
        else if (arg.find("--input=") == 0) {
            inName = arg.substr(arg.find('=') + 1);
            std::cout << "Input file name: " << inName << "\n";
        }
        else if (arg.find("--output=") == 0) {
            outName = arg.substr(arg.find('=') + 1);
            std::cout << "Output file name: " << outName << "\n";
        }
        else if (arg.find("--input-dir=") == 0) {
            inDir = arg.substr(arg.find('=') + 1);
        }
        else if (arg.find("--output-dir=") == 0) {
            outDir = arg.substr(arg.find('=') + 1);
        }
        else if (arg.find("--verbose") == 0 ) {
            verbose = true;
        }
    }

    int NKPTS = -1, NBANDS = -1;
    std::string line;
    std::string strKptsAndNBands = "# NKPTS & NBANDS:";
    std::string dirAndFile = inDir + inName;
    std::string dirAndOut = outDir + outName;
    std::ifstream inputFile;
    std::ofstream outputFile;
    inputFile.open(dirAndFile);
    outputFile.open(dirAndOut);


    if(inputFile.is_open()){
        std::printf("Input File \"%s\" exists\n", dirAndFile.c_str());
        std::getline(inputFile, line);
        line.erase(remove(line.begin(),line.end(), '#'));
        outputFile << line << "\n";
    }else{
        std::printf("ERROR Input File \"%s\" DOES NOT EXIST\n\n", dirAndFile.c_str());
        exit(0);
    }

    while(getline(inputFile,line) ){

        if( line.find(strKptsAndNBands) != std::string::npos ){
            getKptsAndBands(&NKPTS, &NBANDS, line);
            if(verbose){
            std::printf("NKPTS: %d\tNBANDS: %d\n", NKPTS, NBANDS );
            }
            break;
        }   

    }
    
    //NKPTS = 10;
    //NBANDS = 7;
    std::vector<std::string>  values;
    values.reserve( (NBANDS + 1) * NKPTS + 2);

    // Process the data
    rearangeData(values, inputFile, outputFile,NKPTS, NBANDS);
    std::printf("Done!\nData Printed to \"%s\"\n", outName.c_str());

    inputFile.close();
    outputFile.close();
    return 0;
}


void getKptsAndBands(int* kpts, int* bands, std::string str) {
    std::regex integerRegex("\\b(\\d+)\\b"); // Regular expression to match integers
    std::smatch match;

    int count = 0; // Keep track of the number of matches
    
    // Find and store the first two integers
    while (std::regex_search(str, match, integerRegex) && count < 2) {
        if (count == 0) {
            *kpts = std::stoi(match[1].str());
        } else if (count == 1) {
            *bands = std::stoi(match[1].str());
        }
        str = match.suffix(); // Move to the next part of the string
        count++;
    }
}


void rearangeData(std::vector<std::string> &vec, std::ifstream &file, std::ofstream &output, int nKpts, int nBands){

    std::string line;
    int lineNum;
    
    if (!file){
        std::printf("ERROR File not found.");
        exit(0);
    }

        // READ in all data into vector of vectors
    file.seekg(std::ios::beg);
    while (getline(file, line)){
        vec.push_back(line);
    }

    for ( int bnd = 0; bnd < nBands; bnd++ ){

        if ( bnd % 2 ){ // if odd
            for(int kpt=nKpts; kpt > 0; kpt--){
                lineNum = bnd + (nBands + 1) * (kpt - 1) + 3;
                output << vec[lineNum] << "\n";
            }
            output << "\n";
        }
        else{//if even
            for(int kpt=1; kpt <= nKpts; kpt++){
                lineNum = bnd + (nBands + 1) * (kpt - 1) + 3;
                output << vec[lineNum] << "\n";
            }
            output << "\n";

        }
    }   

}
