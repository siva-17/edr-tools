@echo off
setlocal enabledelayedexpansion

%1 start "" mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit

rem -----------------------------------------------
rem  Update virus database mgr iplist
rem -----------------------------------------------
set "g_mgr_iplist=0.0.0.0"

set "g_public_ini=public.ini"
set "g_public_ini_bak=public_bak.ini"
set "g_epsMonitorService=edr_monitor"
set "g_szAgentExeName=edr_agent.exe"
set _szservicePath=
set g_expansionRet=

set "g_restart_bat=restart.bat"

rem -----------------------------------------------
rem  Get the random folder names from eaio_apphome.ini
rem -----------------------------------------------
set "ini_file=C:\Program Files\sangfor\EAIO\eaio_apphome.ini"
set "app_home_folder="
set "app_home_x86_folder="

for /f "tokens=1,2 delims== " %%i in ('findstr /i "app_home =" "!ini_file!"') do (
    if "%%i"=="app_home" set "app_home_folder=%%j"
    if "%%i"=="app_home_x86" set "app_home_x86_folder=%%j"
)

if not defined app_home_folder (
    echo "Failed to retrieve app_home folder from !ini_file!"
) else (
    rem Construct the full path to the crash_config.cfg for app_home
    set "delete_file=C:\Program Files\sangfor\EAIO\!app_home_folder!\bin\crash_config.cfg"
    rem Delete the file if it exists
    if exist "!delete_file!" (
        del /f /q "!delete_file!"
        echo "Deleted: !delete_file!"
    ) else (
        echo "File not found: !delete_file!"
    )
)

if not defined app_home_x86_folder (
    echo "Failed to retrieve app_home_x86 folder from !ini_file!"
) else (
    rem Construct the full path to the crash_config.cfg for app_home_x86
    set "delete_file_x86=C:\Program Files\sangfor\EAIO\!app_home_x86_folder!\bin\crash_config.cfg"
    rem Delete the file if it exists
    if exist "!delete_file_x86!" (
        del /f /q "!delete_file_x86!"
        echo "Deleted: !delete_file_x86!"
    ) else (
        echo "File not found: !delete_file_x86!"
    )
)

sc query !g_epsMonitorService! |  findstr /I !g_epsMonitorService!  2>&1 >nul
if "!errorlevel!"=="0" (
	for /f "tokens=3,* delims= " %%i in ('sc qc "!g_epsMonitorService!" ^| findstr /I "BINARY_PATH_NAME" 2^>nul') do (
		set "_szservicePath=%%~i %%j"
	)
) else (
	echo "error %errorlevel%"
)

if exist "!_szservicePath!" (
	echo "info" "find epspath %_szservicePath% successfully"
	call:deal_public_ini "!_szservicePath!"
) else (
	echo "not find epspath %_szservicePath%"
)

exit 0

:deal_public_ini
rem -----------------------------------------------
rem Handles the public.ini file, create it if it does not exist, replace it if it exists
rem 
rem 
rem -----------------------------------------------
set "_path=%~dp1"
set "_path=!_path!\.."

call:expansion_valid_path "!_path!"
set "_path=!g_expansionRet!"
set "config_path=!_path!\config"

if not exist "!config_path!" (
	exit /b 0
)

set "_file=!config_path!\!g_public_ini!"
set "_file_bak=!config_path!\!g_public_ini_bak!"

if not exist "!_file!"  (
	(echo [config]
	 echo iplist = !g_mgr_iplist!
	)> !_file!
	
	exit /b 0
)

(for /f "delims=" %%i in ('type "!_file!"') do (
		set "str1=%%i"
		if "!str1:iplist = !" neq "%%i" (
			echo iplist = !g_mgr_iplist!
		) else (  
			echo,%%i 
		)
))> !_file_bak!

cd !config_path!
move /y !g_public_ini_bak! !g_public_ini!

call:stop_eps_agent

exit /b 0

goto :eof

:expansion_valid_path
rem -----------------------------------------------
rem Convert string to legal path
rem 
rem 
rem -----------------------------------------------
set "_path=%~f1"
set "g_expansionRet=!_path!"

exit /b 0

goto :eof

:stop_eps_agent
rem -----------------------------------------------
rem Disable eps_agent
rem 
rem 
rem -----------------------------------------------

taskkill /F /IM !g_szAgentExeName!

exit /b 0

goto :eof
