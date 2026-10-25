@echo off
cd /d "%~dp0"
echo Starting LS Arena from: %CD%
echo Keep this window open. Startup messages will remain visible if the server exits.
echo.
samp-server.exe
echo.
echo The server process has stopped. Read the message above for the cause.
pause
