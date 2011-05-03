@echo off
bin_win\OF_Client_Windows-x86.exe "-q$HOME\My Games\OctaForge" -gWARNING -r %*
echo "To save the output, add     > out_client 2>&1"
pause