@echo off
set OF_EXECPREFIX=OF_Client_Windows
set OF_EXECUTABLE=UNKNOWN

if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
    if exist bin_win64\%OF_EXECPREFIX%-x64.exe (
        set OF_EXECUTABLE=bin_win64\%OF_EXECPREFIX%-x64.exe
	) else (
        set OF_EXECUTABLE=bin_win32\%OF_EXECPREFIX%-x86.exe
	)
) else (
    set OF_EXECUTABLE=bin_win32\%OF_EXECPREFIX%-x86.exe
)

if exist %OF_EXECUTABLE% (
    %OF_EXECUTABLE% "-q$HOME\My Games\OctaForge" -gWARNING %*
    echo "To save the output, add: > out_client 2>&1"
) else (
    echo "There is no OF binary that matches your computer."
    echo "Either build it yourself, or make a feature request."
)
pause
