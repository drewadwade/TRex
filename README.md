# TRex
A steganography image-muncher (well, workflow tool)

TRex is a steganography workflow tool based on *NIX commands (file, strings, binwalk), analysis tools (stegoVeritas, stegocracker), and techniques (header fixes, PKZIP isolation) to streamline steganography image file analysi.

USAGE: TRex filename [-q] [-r]

  -q runs stegcracker using the quick self-generated wordlist (from filename and strings output)

  -r runs stegcracker using the rockyou wordlist

  -? or --help displays this usage information

  Results can be found in the local directory named after the analysed file

  Requires: stegoVeritas available at github/bannsec/stegoVeritas

            stegcracker available at github/Paradoxis/stegcracker
            
PROCESS: 
Creates an output directory named after the target file without extension

Runs the file through file

Checks for EXIF data

If the file type identified by file is PNG, runs the file through pngcheck

If the pngcheck indicates a bad CRC check, replaces the bad CRC with the expected CRC

If the file contains the PKZIP header, runs the file through binwalk to identify the index of any PKZIP headers. 

Isolates possible PKZIP files from binwalk indices

Runs the file through stegoVeritas LSB analysis

If the quick wordlist option was selected, creates the quick wordlist using the filename, strings from the file, and base64 and base32 decoded versions of those strings, then runs the file through stegcracker

If the rockyou wordlist option was selected, checks to see that the rockyou.txt wordlist is present in the expected /usr/share/wordlists/ folder, then runs the file through stegcracker
