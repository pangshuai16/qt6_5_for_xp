@echo off
rem ===========================================================================
rem  Detached runner for the ARM64 static build.
rem  Used via Windows Task Scheduler (schtasks) so the build is not killed when
rem  the parent shell/agent session exits. All output goes to a single log.
rem ===========================================================================
setlocal

cd /d "%~dp0"

set "LOGFILE=%~dp0build-arm64-static.log"

echo ===== BUILD STARTED %DATE% %TIME% ===== > "%LOGFILE%"
call "%~dp0onekey-build-arm64-static.bat" >> "%LOGFILE%" 2>&1
set "RC=%ERRORLEVEL%"
echo ===== BUILD FINISHED %DATE% %TIME% EXITCODE=%RC% ===== >> "%LOGFILE%"
echo %RC% > "%~dp0build-arm64-static.exitcode"

endlocal
exit /b %RC%
