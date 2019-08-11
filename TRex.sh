#!/bin/bash

### Author: Andrew Wade @drewadwade drewadwade.github.io
### Version: 1.0
### Written: 25 February 2019
### Revised:

### TRex is a steganography workflow tool based on existing *NIX commands (file, strings,
### binwalk), analysis tools (stegoVeritas, stegocracker), and techniques (header fixes, PKZIP
### isolation) to streamline steganography image files.
###
### USAGE: TRex filename [-q] [-r] [-b]
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
if [[ $* = "--help" ]] || [[ $* = "-?" ]] || [[ ! -f $TARGET ]]
then
  echo "USAGE: TRex filename [-q] [-r]"
  echo "-q runs stegcracker using the self-generated wordlist"
  echo "-r runs stegcracker using the rockyou wordlist"
  echo "-? or --help displays this usage information"
  echo "Results can be found in the local directory named after the analysed file"
  echo "Requires stegoVeritas available at github/bannsec/stegoVeritas"
  exit
fi

### Get the wordlist options from the input option(s)
if [[ $* = "-q" ]]
then
  $QUICK="1"
fi
if [[ $* = "-r" ]]
then
  $ROCK="1"
fi

### MAKE the output directory named after the target file without extension
FOLDER=`echo "$TARGET" | cut -d'.' -f1`
mkdir ./$FOLDER
#WORKING
### Run the file through stegoVeritas and save the folder of output files in the output folder
#echo "Running file through stegoVeritas..."
#echo "######################################################################################" >> ./$FOLDER/report
#echo "stegoVeritas LSB results are in the ./$FOLDER/results/ folder" >> ./$FOLDER/report
#echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
#mkdir ./$FOLDER/results
#stegoveritas $TARGET >> ./$FOLDER/results/LSBreport
#mv ./results/* ./$FOLDER/results/
#rmdir ./results
#echo "######################################################################################" >> ./$FOLDER/report
#echo " " >> ./$FOLDER/report


### Run the file through file and append the output to the report file in the output folder
echo "Running file through file"
echo "######################################################################################" >> ./$FOLDER/report
echo "File type information" >> ./$FOLDER/report
echo "--------------------------------------------------------------------------------------" >> ./$FOLDER/report
file $TARGET >> ./$FOLDER/report
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
# IF cat ./$TARGET contains 504B0304
# 	echo "######################################################################################" >> #./$FOLDER/report
# 	echo "Binwalk found one or more PKZIP headers" >> ./$FOLDER/report
#	binwalk ./$TARGET >> ./$FOLDER/report
#	binwalk ./$TARGET | grep POSITION OF EACH 504B0304 >> $PKlist
# 	echo "" >> ./$FOLDER/report
#	echo BIT POSITION IMMEDIATELY AFTER END >> $PKlist
#	PKcount = cat $PKlist | wc

### For each stretch from one PKZIP header to the next or to the end of the file, isolate that section
### and save it as a new ZIP file called PKCHECK_[starting header#]_[ending header#] (e.g. PKCHECK_1_2)
# 	PKS1=0
# 	WHILE PKS1 < PKcount-1
#		PKS2=PKS1+1
#		WHILE PKS2 < PKcount
#			DO
#				CUT FROM PKlist[PKS1] to PKlist[PKS2] (not inclusive of PKlist[PKS2])
#				SAVE AS PKCHECK_$PKS1_$PKS2
#				PKS2+=1
#			DONE
#		PKS1+=1


### If the quick wordlist option was selected, create the quick wordlist using the filename, strings
### from the file, and base64 and base32 decoded versions of those strings, then run the file through
### stegcracker using that list and append any results to the report file in the output folder
# IF quick == TRUE
# 	CREATE quick.txt wordlist file
# 	echo name > ./$FOLDER/quick.txt
# 	strings $TARGET >> ./$FOLDER/quick.txt
# 	cat ./$FOLDER/quick.txt | base64 -d > ./$FOLDER/quick.tmp
# 	cat ./$FOLDER/quick.tmp >> ./$FOLDER/quick.txt
# 	cat ./$FOLDER/quick.txt | base32 -d > ./$FOLDER/quick.tmp
# 	cat ./$FOLDER/quick.tmp >> ./$FOLDER/quick.txt
# 	echo "######################################################################################" >> #./$FOLDER/report
#	echo "Quick wordlist is in the ./$name folder" >> ./$FOLDER/report
# 	echo "######################################################################################" >> #./$FOLDER/report
# 	echo " " >> ./$FOLDER/report
# 	echo "######################################################################################" >> #./$FOLDER/report
#	echo "TRex stegcracker results using the quick wordlist" >> ./$FOLDER/report
# 	echo "--------------------------------------------------------------------------------------" >> #./$FOLDER/report
# 	stegcracker $$TARGET ./$FOLDER/testwords & >> ./name.report 2> /dev/null
# 	echo "######################################################################################" >> #./$FOLDER/report
# 	echo " " >> ./$FOLDER/report

### If the rockyou wordlist option was selected, check to see that the rockyou.txt wordlist is present
### in the expected /usr/share/wordlists/ folder, then run the file through stegcracker using that list
### and append any results to the report file in the output folder
# IF rock == TRUE and /usr/share/wordlists/rockyou.txt -e
# 	echo "######################################################################################" >> #./$FOLDER/report
#	echo "TRex stegcracker results using rockyou.txt"
# 	echo "--------------------------------------------------------------------------------------" >> #./$FOLDER/report
# 	stegcracker $$TARGET /usr/share/wordlists/rockyou.txt & >> ./name.report 2> #/dev/null
# 	echo "######################################################################################" >> #./$FOLDER/report
# 	echo " " >> ./$FOLDER/report
# ELIF rock == TRUE and ! /usr/share/wordlists/rockyou.txt -e
# 	echo "######################################################################################" >> #./$FOLDER/report
#	echo "The rockyou.txt wordlist was not found in /usr/share/wordlists/"
# 	echo "######################################################################################" >> #./$FOLDER/report
# 	echo " " >> ./$FOLDER/report
