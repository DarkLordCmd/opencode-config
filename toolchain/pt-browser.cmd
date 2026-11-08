@echo off
rem Dedicated test browser profile. Never the operator's main profile.
rem Usage: pt-browser.cmd [url]
set THORIUM=%LOCALAPPDATA%\Thorium\Application\thorium.exe
set PROFILE=E:\pintest\browser\profile
if not exist "%PROFILE%" mkdir "%PROFILE%"
start "" "%THORIUM%" --user-data-dir="%PROFILE%" --remote-debugging-port=9222 --no-first-run --no-default-browser-check %*
