@echo off

:: --------------------------------
:: Find Current Working Directory 
:: --------------------------------

SET DIR=%~dp0
ECHO Current Working Directory %DIR%

:: Strip trailing backslash 
set DIR1=%DIR:~0,-1%

::  ~dp does not work for regular environment variables:
::  set ParentDirectory=%Directory:~dp%  set ParentDirectory=%Directory:~dp%
::  ~dp only works for batch file parameters and loop indexes
  for %%d in (%DIR1%) do set PARENTDIR=%%~dpd


ECHO Parent Directory is %PARENTDIR%

SET ROOT=%PARENTDIR%source\openwarpgui\
ECHO Root Directory is %ROOT%

::---------------------------------------------------------------------------------------------------------------
:: Find Platform Architecture (32bit or 64bit)
::--------------------------------------------------------------------------------------------------------------

ECHO Checking Platform Architecture 
SET "flag="
if defined ProgramFiles(x86) (
    
    @echo Some 64-bit work
    SET "flag=64"
    SET CURL=%DIR%curl\x64
      
) else (
    
    @echo Some 32-bit work
    SET "flag=32"
    SET	CURL=%DIR%curl\x86
	ECHO "32-bit is not certified yet!"
	goto :endProcess
)
ECHO OS Architecture %FLAG%
ECHO CURL path is: %CURL%
ECHO Setting curl to PATH
SET "PATH=%PATH%;%CURL%"
ECHO path is %CURL%

:: -------------------------------------------------------------------------
:: Use 7Zip, (To extract other software during installation)
:: -------------------------------------------------------------------------
	ECHO "Setting Path for 7za"
	SET "PATH=%PATH%;%DIR%7za"
    ECHO Path is %DIR%7za
	ECHO 7Z is installed already 
	
	ECHO "Anaconda is installed already"
    SET "ANACONDA =C:\Users\hmankle\AppData\Local\Continuum\Anaconda\"
    SET "ANACONDASCRIPTS=C:\Anaconda\Scripts\"
	SET "PATH=%PATH%;%ANACONDA%;%ANACONDASCRIPTS%"
	:: Delete the installer 
	
::-----------------------------------
:: Download and Extract MINGW 4.8.1
::-----------------------------------
	:MinGw
	SET "MINGW_ROOT=C:\mingw\"
	:: IF C:\mingw64\ exists, Assume mingw is already installed 
		
	ECHO Extracting MINGW USING 7Z
	7za x x64-4.8.1-release-posix-sjlj-rev5.7z -oC:\
	)
			
	ECHO Setting Environment Variables
	SET "PATH=%PATH%;%MINGW_ROOT%bin;%MINGW_ROOT%lib"
	:: Deleting the downloaded file to avoid corruption case in next run
	DEL x64-4.8.1-release-posix-sjlj-rev5.7z /f

:: ----------------------------------
:: Making GFortran Build Folder (create an empty folder to create makefiles ! )
:: ----------------------------------
	:gfortranBuild
	CD %PARENTDIR%
	ECHO Creating new GFortran build folder 
	RMDIR source\NemohImproved\Nemoh\gFortranBuild /S /Q
	MKDIR source\NemohImproved\Nemoh\gFortranBuild
	
			
:: ---------------------------------------------------------------------------
:: Copy Blas and Lapack from install_script folder to bundled/simulations/libs
:: ---------------------------------------------------------------------------
	
	ECHO Copying BlAS and LAPACK to MinGW/libs
	copy %PARENTDIR%install_script\dlls\libblas.dll %MINGW_ROOT%lib% 
	copy %PARENTDIR%install_script\dlls\liblapack.dll %MINGW_ROOT%lib% 
	
	ECHO Copying 19 necessary Dlls inside Anaconda\Dlls
	xcopy /Y /s %PARENTDIR%install_script\dlls C:\Users\hmankle\AppData\Local\Continuum\Anaconda\DLLs
	
	IF NOT EXIST %MINGW_ROOT%\lib\libnemoh.dll (
	ECHO libnemoh.dll was not copied in the last step so copying it from repo
	copy %PARENTDIR%install_script\dlls\libnemoh.dll C:\Users\hmankle\AppData\Local\Continuum\Anaconda\DLLs
	copy %PARENTDIR%install_script\dlls\libnemoh.dll.a C:\Users\hmankle\AppData\Local\Continuum\Anaconda\DLLs
	copy %PARENTDIR%install_script\dlls\libnemoh.dll C:\Users\hmankle\AppData\Local\Continuum\Anaconda\libs
	copy %PARENTDIR%install_script\dlls\libnemoh.dll.a C:\Users\hmankle\AppData\Local\Continuum\Anaconda\libs
	copy %PARENTDIR%install_script\dlls\libnemoh.dll %MINGW_ROOT%\lib
	copy %PARENTDIR%install_script\dlls\libnemoh.dll.a %MINGW_ROOT%\lib
	)

	CD %PARENTDIR%source\NemohImproved\Nemoh\	
	

:: -----------------------------------------------
:: Build libnemoh.dll and libnemoh.dll.a 
:: -----------------------------------------------
	cmake -DCMAKE_Fortran_COMPILER="gfortran" "%PARENTDIR%source\NemohImproved\Nemoh" -G "MinGW Makefiles"
	mingw32-make
	CD %PARENTDIR%
	
	:: to build these dlls again delete CMakeCache.txt file

:: --------------------------------------------------------------------
:: Copy libnemoh.dll to Anaconda/Dlls, Anaconda/Libs and MinGW/libs	
:: --------------------------------------------------------------------
	ECHO Copying libnemoh.dll to Anaconda\Dlls
	echo %ANACONDA%\DLLs
	copy %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll C:\Users\hmankle\AppData\Local\Continuum\Anaconda\DLLs
	copy %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll.a C:\Users\hmankle\AppData\Local\Continuum\Anaconda\DLLs
	
	ECHO Copying libnemoh.dll to %Anaconda%\libs
	copy /Y %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll C:\Users\hmankle\AppData\Local\Continuum\Anaconda\libs
	copy /Y %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll.a C:\Users\hmankle\AppData\Local\Continuum\Anaconda\libs
	
	ECHO Copying libnemoh.dll to Anaconda
	copy %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll %MINGW_ROOT%\lib
	copy %PARENTDIR%source\NemohImproved\Nemoh\libnemoh.dll.a %MINGW_ROOT%\lib
	
	CD %PARENTDIR%install_script
	
:: ------------------------------------------------
:: Installing VCREDIST x64 , it installs MSVSCRT10.DLL
:: ---------------------------------------------
::	%PARENTDIR%install_script\vsredistributable12\vcredist_x64.exe	
	
:: ----------------------------------------
:: Installing Python libraries using pip
:: -----------------------------------------

	ECHO Installing required python libraries using pip
	ECHO %ROOT%
	ECHO %ANACONDA%\Scripts\pip
		
	
::	pip install -r %ROOT%requirements.txt
::	pip install --upgrade numpy

	::---- for Automated Test 2 (Bemio-Wamit)
::	pip install %DIR%numpy-1.9.2+mkl-cp27-none-win_amd64.whl
::	pip install progressbar
	
	
:: --------------------------------
:: Building Solver Fortran 
:: -------------------------------

	ECHO Building setup.py 
	ECHO %ROOT%

	ECHO %PARENTDIR%source\openwarpgui\nemoh
	CD %PARENTDIR%source\openwarpgui\nemoh

	python setup.py cleanall
	python setup.py build_ext --inplace
	CD %PARENTDIR%install_script

	ECHO "OpenWarp Installation Steps are complete !"
	ECHO "Execute run.bat for GUI and testscript.bat for CLI tests !"

:: ------------------------------
:: Execute UI
:: ------------------------------
	:: ECHO "RUNNING OPENWARP"
	::CD %ROOT%
	::python main.py
	
	
:endProcess
ECHO "Ending Process !"	