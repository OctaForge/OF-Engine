@echo off

if %PROCESSOR_ARCHITECTURE%==AMD64 (
    if exist bin\CC_Client_Windows-AMD64.exe (
        SET CCARCH=AMD64
        goto :run
    ) else (
        if exist bin\CC_Client_Windows-x86.exe (
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
    if exist bin\CC_Client_Windows-x86.exe (
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

if %PROCESSOR_ARCHITECTURE%==AMD64 (
    if %CCARCH%==x86 (
	    FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY "HKLM\Software\Wow6432Node\Python\PythonCore\2.6\InstallPath"') DO SET PYVER=%%B
	) else (
	    FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY "HKLM\Software\Python\PythonCore\2.6\InstallPath"') DO SET PYVER=%%B
	)
) else (
    FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY "HKLM\Software\Python\PythonCore\2.6\InstallPath"') DO SET PYVER=%%B
)

SET OLD_PATH=%PATH%
SET PATH=%PYVER%;src\windows\sdl_vcpp\lib;src\windows\sdl_image\lib;src\windows\sdl_mixer\lib;%PATH%

SET OLD_PYTHONHOME=%PYTHONHOME%
SET PYTHONHOME=%PYVER%\lib;%PYVER%\DLLs;%PYTHONHOME%

SET OLD_PYTHONPATH=%PYTHONPATH%
SET PYTHONHOME=%PYVER%\lib;%PYVER%\DLLs;%PYTHONHOME%

bin\CC_Client_Windows-%CCARCH%.exe %* -r > out_client 2>&1

echo "(If a problem occurred, look in out_client)"

:finish
pause

SET PATH=%OLD_PATH%
SET PYTHONHOME=%OLD_PYTHONHOME%
SET PYTHONPATH=%OLD_PYTHONPATH%

