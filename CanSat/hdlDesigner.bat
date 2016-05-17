@echo off
REM ----------------------------------------------------------------------------
REM Define environment variables
REM
set DESIGN_NAME=cansat

set HDS_PROJECT_DIR=%CD%
set HDS_LIBS_DIR=%HDS_PROJECT_DIR%
set ISE_WORK_DIR=Board\ise

set SIMULATION_DIR=%HDS_PROJECT_DIR:\=/%/Simulation
set SCRATCH_DIR=%USERPROFILE:C:\Documents and Settings=D:\Temp\EDA%

set HDS_LIBS=%HDS_PROJECT_DIR%\Prefs\hds.hdp
set HDS_USER_HOME=%HDS_PROJECT_DIR%\Prefs\hds_user
set HDS_TEAM_HOME=%HDS_PROJECT_DIR%\Prefs\hds_team

set HDS_HOME=C:\eda\HDS
set MODELSIM_HOME=C:\eda\Modelsim
set ISE_HOME=C:\eda\Xilinx\ISE_DS

REM ----------------------------------------------------------------------------
REM Prepare scratch directory
REM
rmdir /S /Q "%SCRATCH_DIR%\%DESIGN_NAME%"
mkdir "%SCRATCH_DIR%\%DESIGN_NAME%"
xcopy /S /I /Q %HDS_PROJECT_DIR%\%ISE_WORK_DIR% "%SCRATCH_DIR%\%DESIGN_NAME%\%ISE_WORK_DIR%"

REM ----------------------------------------------------------------------------
REM Delete intermediate files
REM
del /s %HDS_PROJECT_DIR%\*.bak %HDS_PROJECT_DIR%\*.lck %HDS_PROJECT_DIR%\.cache.dat

REM ----------------------------------------------------------------------------
REM Launch Application
REM
%windir%\system32\cmd.exe /c start %HDS_HOME%\bin\hdldesigner.exe

REM ----------------------------------------------------------------------------
REM Copy files back from the scratch directory
REM
REM pause
REM copy %SCRATCH_DIR%\Kart\Board\actel\designer\impl1\FPGA_motorControl.pdb %HDS_PROJECT_DIR%\Board\actel\
