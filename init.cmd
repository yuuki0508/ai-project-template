@echo off
rem Windows で init.sh をダブルクリック起動するためのラッパー。
rem Git for Windows（Git Bash）が必要。
setlocal
set BASH=
if exist "%ProgramFiles%\Git\bin\bash.exe" set BASH=%ProgramFiles%\Git\bin\bash.exe
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set BASH=%ProgramFiles(x86)%\Git\bin\bash.exe
if "%BASH%"=="" (
  echo Git Bash が見つかりません。https://gitforwindows.org からインストールしてください。
  pause
  exit /b 1
)
"%BASH%" -lc "cd \"$(cygpath '%~dp0')\" && ./init.sh"
pause
