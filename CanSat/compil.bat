@echo off
REM ----------------------------------------------------------------------------
REM Define environment variables
REM
set DESIGN_NAME=cansat

set PROJECT_DIR=%CD%
set HDS_LIBS_DIR=%PROJECT_DIR%

set SIMULATION_DIR=%PROJECT_DIR%\Simulation
set SCRATCH_DIR=%PROJECT_DIR%\EDA

set MODELSIM_HOME=C:\questasim64_10.4b\win64

REM ----------------------------------------------------------------------------
REM Prepare scratch directory
REM
echo Preparing the work directory %SCRATCH_DIR%\%DESIGN_NAME%
rmdir /s /q "%SCRATCH_DIR%\%DESIGN_NAME%"
mkdir "%SCRATCH_DIR%\%DESIGN_NAME%"
copy %PROJECT_DIR%\Simulation\modelsim.ini "%SCRATCH_DIR%\%DESIGN_NAME%\"

REM ----------------------------------------------------------------------------
REM Delete intermediate files
REM
del /s %PROJECT_DIR%\*.bak %PROJECT_DIR%\*.lck %PROJECT_DIR%\.cache.dat

REM ----------------------------------------------------------------------------
REM Compile system
REM
REM pause

set modelsim_lib=common_test
mkdir "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%"
%MODELSIM_HOME%\vlib "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work"
%MODELSIM_HOME%\vmap %modelsim_lib% %SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work
set modelsim_compile=%MODELSIM_HOME%\vcom -work %modelsim_lib% -nologo -2002
set modelsim_compile_dir=%PROJECT_DIR%\%modelsim_lib%\hdl
%modelsim_compile% %modelsim_compile_dir%\testUtils_pkg.vhd
%modelsim_compile% %modelsim_compile_dir%\testUtils_pkg_body.vhd

set modelsim_lib=AhbLite
mkdir "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%"
%MODELSIM_HOME%\vlib "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work"
%MODELSIM_HOME%\vmap %modelsim_lib% %SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work
set modelsim_compile=%MODELSIM_HOME%\vcom -work %modelsim_lib% -nologo -2002
set modelsim_compile_dir=%PROJECT_DIR%\%modelsim_lib%\hdl
%modelsim_compile% %modelsim_compile_dir%\ahbLite_pkg.vhd
%modelsim_compile% %modelsim_compile_dir%\ahbLite_pkg_body.vhd

set modelsim_lib=AhbLiteComponents
mkdir "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%"
%MODELSIM_HOME%\vlib "%SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work"
%MODELSIM_HOME%\vmap %modelsim_lib% %SCRATCH_DIR%\%DESIGN_NAME%\%modelsim_lib%\work
set modelsim_compile=%MODELSIM_HOME%\vcom -work %modelsim_lib% -nologo -2002
set modelsim_compile_dir=%PROJECT_DIR%\%modelsim_lib%\hdl
%modelsim_compile% %modelsim_compile_dir%\ahbads1282_entity.vhg
%modelsim_compile% %modelsim_compile_dir%\ahbAds1281_RTL.vhd

pause