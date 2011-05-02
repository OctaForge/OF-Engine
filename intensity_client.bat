@echo off

if %PROCESSOR_ARCHITECTURE%==AMD64 (
    if exist bin\OF_Client_Windows-AMD64.exe (
        SET CCARCH=AMD64
        goto :run
    ) else (
        if exist bin\OF_Client_Windows-x86.exe (
            SET CCARCH=x86
            goto :run
        ) else (
            echo "No client executable found for %PROCESSOR_ARCHITECTURE%."
            echo "You can either compile it yourself (and if possible, send to developers)"
            echo "or wait until we get official binaries for %PROCESSOR_ARCHITECTURE%."
            goto :finish
        )
    )
) else (
    if exist bin\OF_Client_Windows-x86.exe (
        SET CCARCH=x86
        goto :run
    ) else (
        echo "No client executable found for %PROCESSOR_ARCHITECTURE%."
        echo "You can either compile it yourself (and if possible, send to developers)"
        echo "or wait until we get official binaries for %PROCESSOR_ARCHITECTURE%."
        goto :finish
    )
)

:run

SET OLD_PATH=%PATH%
SET PATH=src\windows\sdl_vcpp\lib;src\windows\sdl_image\lib;src\windows\sdl_mixer\lib;%PATH%

bin\OF_Client_Windows-%CCARCH%.exe "-q$HOME\OctaForge" -gWARNING -r %* > out_client 2>&1
echo "(If a problem occurred, look in out_client)"

:finish
pause

SET PATH=%OLD_PATH%
