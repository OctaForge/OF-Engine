@echo off
bin_win\OF_Server_Windows-x86.exe "-q$HOME\My Games\OctaForge" -gWARNING %*
echo "To save the output, add     > out_server 2>&1"