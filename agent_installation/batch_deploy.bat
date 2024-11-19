@echo off

rem Set shared path name and executable file name.
set "Route=\\edr197.com\SysVol\edr197.com\Policies\{52F0E80C-A9CD-4438-BC55-BE4E3A6AC71B}\Machine\Scripts\Startup"
set "EDR_EXE=es_installer_edragent.sangfor.com_443_969939873.exe"

echo [%date:~0,10% %time:~0,8%] edr start install > %temp%\flag.log

rem Not modifiable.
set "ProcessFlag=edr_monitor.exe"
tasklist | findstr /IM %ProcessFlag%

if %errorlevel% == 0 (
	echo [%date:~0,10% %time:~0,8%] edr is installed already >> %temp%\flag.log
	exit /b 0
)
  
copy  /Y "%Route%\%EDR_EXE%"  %temp%\

start /MIN "" %temp%\%EDR_EXE% -Silence=Y

echo [%date:~0,10% %time:~0,8%] edr end install >> %temp%\flag.log
exit /b 0







