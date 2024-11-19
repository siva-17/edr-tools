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

