@setlocal

@echo off

rem ===========================================================================
rem  Qt 6.5 for Windows XP - STATIC library build script (x64)
rem  Difference vs onekey-build-x64.bat:
rem    - BUILD_SHARED_LIBS=OFF            -> static libraries (*.lib)
rem    - FEATURE_static_runtime=ON        -> link CRT statically (/MT)
rem    - FEATURE_cpp_winrt=OFF            -> no WinRT (Win8+)
rem  Difference vs onekey-build-x86-static.bat:
rem    - vcvarsall amd64 (not amd64_x86)
rem  Result goes to:  Output\Binaries\x64-static
rem  Stop point control: set QT_BUILD_UNTIL=<module> to build up to that module
rem ===========================================================================

set VisualStudioInstallerFolder="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if %PROCESSOR_ARCHITECTURE%==x86 set VisualStudioInstallerFolder="%ProgramFiles%\Microsoft Visual Studio\Installer"

pushd %VisualStudioInstallerFolder%
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VisualStudioInstallDir=%%i
)
popd

call "%VisualStudioInstallDir%\VC\Auxiliary\Build\vcvarsall.bat" amd64
set YYTHUNKS_INSTALL_DIR="%~dp0YY-Thunks"

set ObjectFolder="%~dp0Output\Objects\x64-static"
set BinaryFolder="%~dp0Output\Binaries\x64-static"

rem Bring VS-bundled CMake/Ninja into PATH
set "VS_CMAKE=%VisualStudioInstallDir%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
set "VS_NINJA=%VisualStudioInstallDir%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
set PATH=%VS_CMAKE%;%VS_NINJA%;%PATH%

rem Remove the output folder for a fresh compile.
rem rd /s /q %ObjectFolder%
rem rd /s /q %BinaryFolder%

mkdir %BinaryFolder% 2>nul

set PATH=%~dp0qtbase\bin;%PATH%

set CommonOptions=-G "Ninja Multi-Config" -DCMAKE_CONFIGURATION_TYPES=Release -DWindowsTargetPlatformMinVersion=5.1.2600.0 -DYYTHUNKS_TARGET_OS=WinXP -DBUILD_SHARED_LIBS=OFF -DFEATURE_static_runtime=ON -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF

mkdir %ObjectFolder%\qtbase 2>nul
pushd %ObjectFolder%\qtbase
cmake -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% -DFEATURE_sql=OFF -DFEATURE_optimize_size=ON -DINPUT_openssl=no -DFEATURE_schannel=ON -DINPUT_opengl=no -DFEATURE_dbus=OFF -DFEATURE_freetype=OFF -DFEATURE_system_freetype=OFF -DFEATURE_harfbuzz=OFF -DFEATURE_system_harfbuzz=OFF -DFEATURE_system_zlib=OFF -DFEATURE_cpp_winrt=OFF ../../../../qtbase
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtbase" goto :done

mkdir %ObjectFolder%\qtactiveqt 2>nul
pushd %ObjectFolder%\qtactiveqt
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtactiveqt
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtactiveqt" goto :done

mkdir %ObjectFolder%\qtsvg 2>nul
pushd %ObjectFolder%\qtsvg
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtsvg
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtsvg" goto :done

mkdir %ObjectFolder%\qtimageformats 2>nul
pushd %ObjectFolder%\qtimageformats
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtimageformats
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtimageformats" goto :done

mkdir %ObjectFolder%\qtshadertools 2>nul
pushd %ObjectFolder%\qtshadertools
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtshadertools
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtshadertools" goto :done

mkdir %ObjectFolder%\qtlanguageserver 2>nul
pushd %ObjectFolder%\qtlanguageserver
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtlanguageserver
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtlanguageserver" goto :done

mkdir %ObjectFolder%\qtdeclarative 2>nul
pushd %ObjectFolder%\qtdeclarative
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtdeclarative
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qtdeclarative" goto :done

mkdir %ObjectFolder%\qttools 2>nul
pushd %ObjectFolder%\qttools
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qttools
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

if /I "%QT_BUILD_UNTIL%"=="qttools" goto :done

mkdir %ObjectFolder%\qttranslations 2>nul
pushd %ObjectFolder%\qttranslations
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qttranslations
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

:done
@endlocal
