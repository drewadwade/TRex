#!/bin/bash

### Author: Andrew Wade @drewadwade drewadwade.github.io
### Version: 1.0
### Written: 25 February 2019
### Last Revised: 19 October 2019

### TRex is a steganography workflow tool based on *NIX commands (file, strings, binwalk),
### analysis tools (stegoVeritas, stegocracker), and techniques (header fixes, PKZIP isolation)
### to streamline steganography image file analysis.
###
### USAGE: TRex filename [-q] [-r]
### -q runs stegcracker using the self-generated wordlist
### -r runs stegcracker using the rockyou wordlist
### -? or --help displays this usage information
### Results can be found in a directory named after the file inside the current working directory

### Reset the option variables
QUICK="0"
ROCK="0"
BRUTE="0"

### Get the filename from the input parameter
TARGET=$1

### If the filename does not exist or if a help option is added
if [[ $1 = "--help" ]] || [[ $1 = "-?" ]] || [[ $2 = "--help" ]] || [[ $2 = "-?" ]] || [[ $3 = "--help" ]] || [[ $3 = "-?" ]] || [[ ! -f $TARGET ]];
then
  echo "USAGE: TRex filename [-q] [-r]"
  echo "-q runs stegcracker using the self-generated wordlist"
  echo "-r runs stegcracker using the rockyou wordlist"
  echo "-? or --help displays this usage information"
  echo "Results can be found in the local directory named after the analysed file"
  echo "Requires: stegoVeritas available at github/bannsec/stegoVeritas"
  echo "          stegcracker available at github/Paradoxis/stegcracker"
  exit
fi

### Get the wordlist options from the input option(s)
if [[ $2 = "-q" ]] || [[ $3 = "-q" ]];
then
  QUICK="1"
fi
if [[ $2 = "-r" ]] || [[ $3 = "-r" ]];
then
  ROCK="1"
  if [[ ! -f /usr/share/wordlists/rockyou.txt ]];
  then
  	echo "The rockyou.txt wordlist was not found in /usr/share/wordlists/"
    echo "Make sure rockyou.txt is present and accessible and retry"
    exit
  fi
fi


### MAKE the output directory named after the target file without extension
FOLDER=`echo "$TARGET" | cut -d'.' -f1`
mkdir ./$FOLDER

### Run the file through file and append the output to the report file in the output folder
echo "Running file through file"
echo "######################################################################################" >> ./$FOLDER/report
echo "File type information" >> ./$FOLDER/report
echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
file $TARGET >> ./$FOLDER/report
echo "######################################################################################" >> ./$FOLDER/report
echo " " >> ./$FOLDER/report


### Check for EXIF data and append the output to the report file in the output folder
echo "Collecting EXIF information"
echo "######################################################################################" >> ./$FOLDER/report
echo "EXIF metadata information" >> ./$FOLDER/report
exiftool ./$TARGET >> ./$FOLDER/report
echo "######################################################################################" >> ./$FOLDER/report
echo " " >> ./$FOLDER/report


### If the file type identified by file is PNG, run the file through pngcheck and append the output
### to the report file in the output folder
if grep -q PNG "./$FOLDER/report";
then
    echo "PNG file type detected. Running pngcheck..."
   	echo "######################################################################################" >> ./$FOLDER/report
  	echo "PNG file information" >> ./$FOLDER/report
  	echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
  	pngcheck ./$TARGET >> ./$FOLDER/report
### If the pngcheck indicates a bad CRC check, replace the bad CRC with the expected CRC, save the
### resulting file as CRC_FIX.png, and append a note to the report file in the output folder.
	  if grep "CRC error" "./$FOLDER/report";
    then
       echo "Bad CRC check detected. Fixing..."
 		   echo "File CRC check failed" >> ./$FOLDER/report
       ### The following is a modified exerpt from the PNG Check & Repair Tool by sherlly
       ### The original code can be found at https://github.com/sherlly/PCRT
       python miniPCRT.py -i ./$TARGET -o ./$FOLDER/CRC_FIX.png
       echo "Bad CRC replaced with expected CRC and saved as ./$FOLDER/CRC_FIX.png" >> ./$FOLDER/report
    fi
  	echo "######################################################################################" >> ./$FOLDER/report
 		echo " " >> ./$FOLDER/report
fi


### If the file contains the PKZIP header, run the file through binwalk to identify the index of any
### PKZIP headers. These indices are added to an array called PKlist
echo "Running file through binwalk"
binwalk ./$TARGET > ./$FOLDER/binwalk_results
if grep "Zip" "./$FOLDER/binwalk_results";
then
 	echo "######################################################################################" >> ./$FOLDER/report
 	echo "Binwalk found one or more PKZIP headers" >> ./$FOLDER/report
	cat ./$FOLDER/binwalk_results >> ./$FOLDER/report
  echo "Possible PKZIP files saved as ./$FOLDER/PKZIPS/PKCHECK_[decimal offset].ZIP" >> ./$FOLDER/report
  echo "Isolating possible PKZIP files..."
  mkdir ./$FOLDER/PKZIPS
  PKLIST=($(grep "Zip" "./$FOLDER/binwalk_results" | cut -d' ' -f1 ))
  for i in ${PKLIST[@]};
    do dd if=./$TARGET bs=1 skip=$i of=./$FOLDER/PKZIPS/PKCHECK_$i.zip 1> /dev/null
  done
  echo "######################################################################################" >> ./$FOLDER/report
  echo " " >> ./$FOLDER/report
fi


### Run the file through stegoVeritas and save the folder of output files in the output folder
echo "Running file through stegoVeritas..."
echo "This may take a few minutes"
echo "######################################################################################" >> ./$FOLDER/report
echo "stegoVeritas LSB results are in the ./$FOLDER/results/ folder" >> ./$FOLDER/report
echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
mkdir ./$FOLDER/LSBresults
stegoveritas $TARGET >> ./$FOLDER/LSBresults/LSBreport
mv ./results/* ./$FOLDER/LSBresults/
rmdir ./results
echo "######################################################################################" >> ./$FOLDER/report
echo " " >> ./$FOLDER/report


### If the quick wordlist option was selected, create the quick wordlist using the filename, strings
### from the file, and base64 and base32 decoded versions of those strings, then run the file through
### stegcracker using that list and append any results to the report file in the output folder
if [[ $QUICK = '1' ]];
then
  echo "Building the quick wordlist"
 	echo ./$TARGET > ./$FOLDER/quick.txt
 	strings ./$TARGET >> ./$FOLDER/quick.txt
 	cat ./$FOLDER/quick.txt | base64 -d > ./$FOLDER/quick.tmp 2> /dev/null
 	cat ./$FOLDER/quick.txt | base32 -d >> ./$FOLDER/quick.tmp 2> /dev/null
 	cat ./$FOLDER/quick.tmp >> ./$FOLDER/quick.txt
  rm ./$FOLDER/quick.tmp
###  echo "password" > ./$FOLDER/quick.txt #####FOR TESTING ONLY#####
  echo "Running file through stegcracker using the quick wordlist"
 	echo "######################################################################################" >> ./$FOLDER/report
	echo "Quick wordlist is in the ./$TARGET folder" >> ./$FOLDER/report
	echo "TRex stegcracker results using the quick wordlist" >> ./$FOLDER/report
 	echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
 	stegcracker ./$TARGET ./$FOLDER/quick.txt >> ./$FOLDER/report 2> /dev/null
 	echo "######################################################################################" >> ./$FOLDER/report
 	echo " " >> ./$FOLDER/report
fi

### If the rockyou wordlist option was selected, check to see that the rockyou.txt wordlist is present
### in the expected /usr/share/wordlists/ folder, then run the file through stegcracker using that list
### and append any results to the report file in the output folder
if [[ $ROCK = "1" ]];
then
  echo "Running file through stegcracker using the rockyou.txt wordlist"
 	echo "######################################################################################" >> ./$FOLDER/report
	echo "TRex stegcracker results using rockyou.txt" >> ./$FOLDER/report
 	echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
 	stegcracker ./$TARGET /usr/share/wordlists/rockyou.txt >> ./$FOLDER/report 2> /dev/null
 	echo "######################################################################################" >> ./$FOLDER/report
 	echo " " >> ./$FOLDER/report
fi

echo "######################################################################################" >> ./$FOLDER/report
echo "END OF REPORT" >> ./$FOLDER/report
echo "######################################################################################" >> ./$FOLDER/report
