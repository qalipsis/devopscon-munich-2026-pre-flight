@echo off
rem For PowerShell or cmd on Windows: runs preflight.ps1, which says how to start the pre-flight in Git Bash.
rem The bypass applies to this one PowerShell process only: Windows blocks .ps1 files by default.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0preflight.ps1"
exit /b %ERRORLEVEL%
