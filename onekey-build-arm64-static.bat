@setlocal

@echo off

rem ===========================================================================
rem  Qt 6.5 - STATIC library build script (ARM64)
rem
rem  Derived from onekey-build-arm64.bat (the dynamic ARM64 script). Only the
rem  differences listed below are intentional; everything else (module list,
rem  feature switches, output layout) is kept identical so that the ARM64 build
rem  stays environment-consistent with the x86/x64 builds produced from this
rem  same repository. That consistency is what keeps multi-arch Qt deployments
rem  free of cross-architecture feature/ABI surprises.
rem
rem  DIFF vs onekey-build-arm64.bat:
rem    - BUILD_SHARED_LIBS=OFF           -> static libraries (*.lib)
rem    - FEATURE_static_runtime=ON       -> static CRT (/MT)
rem    - CMAKE_CONFIGURATION_TYPES=Release (dynamic script builds Release;Debug)
rem    - WindowsTargetPlatformMinVersion=10.0.16299.0
rem        Windows 10 1709 = first ARM64 desktop release. ARM64 has NO XP /
rem        Vista / Win7 / Win8, so XP-style compatibility must not be requested.
rem    - Output goes to Output\Objects\arm64-static + Output\Binaries\arm64-static
rem
rem  CROSS-COMPILE REQUIREMENTS (x64 host -> ARM64 target). Without these three
rem  the configure step fails, so they are not optional:
rem    - CMAKE_SYSTEM_PROCESSOR=ARM64  makes CMake set CMAKE_CROSSCOMPILING=TRUE.
rem      Leave it out and CMake treats the build as native, so Qt sets
rem      QT_WILL_BUILD_TOOLS=TRUE, builds syncqt with the ARM64 compiler and then
rem      tries to execute that ARM64 exe on the x64 host -> configure dies with
rem      "syncqt.cpp failed for module QtZlib" and an EMPTY error message.
rem    - QT_HOST_PATH                   host tools (syncqt/moc/rcc) + Qt6 CMake
rem      configs, taken from a previously built x64 static install. Build
rem      onekey-build-x64-static.bat first.
rem    - QT_HOST_PATH_CMAKE_DIR         must use forward slashes, otherwise CMake
rem      fails with "Invalid character escape '\c'".
rem
rem  YY-Thunks: arm64 uses objs/arm64/YY_Thunks_for_Win10.obj if vendored, and is
rem  skipped otherwise (Windows 10+ ARM64 already has every API Qt needs). The XP
rem  layer (/subsystem:windows,5.0x) is never applied to ARM64.
rem
rem  Stop point control: set QT_BUILD_UNTIL=<module> to build up to that module
rem  (inclusive) and stop, e.g. QT_BUILD_UNTIL=qtsvg
rem ===========================================================================

set VisualStudioInstallerFolder="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if %PROCESSOR_ARCHITECTURE%==x86 set VisualStudioInstallerFolder="%ProgramFiles%\Microsoft Visual Studio\Installer"

pushd %VisualStudioInstallerFolder%
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.ARM64 -property installationPath`) do (
  set VisualStudioInstallDir=%%i
)
popd

if not defined VisualStudioInstallDir (
  echo [ERROR] ARM64 build tools are not installed.
  echo Install component "Microsoft.VisualStudio.Component.VC.Tools.ARM64"
  echo via the Visual Studio Installer, then re-run this script.
  exit /B 1
)

call "%VisualStudioInstallDir%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

set YYTHUNKS_INSTALL_DIR="%~dp0YY-Thunks"
set ObjectFolder="%~dp0Output\Objects\arm64-static"
set BinaryFolder="%~dp0Output\Binaries\arm64-static"

rem Bring VS-bundled CMake/Ninja into PATH (same as onekey-build-*-static.bat).
set "VS_CMAKE=%VisualStudioInstallDir%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
set "VS_NINJA=%VisualStudioInstallDir%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
set "PATH=%VS_CMAKE%;%VS_NINJA%;%PATH%"

rem Remove the output folder for a fresh compile.
rem rd /s /q %ObjectFolder%
rem rd /s /q %BinaryFolder%

mkdir %BinaryFolder% 2>nul

set "PATH=%~dp0qtbase\bin;%PATH%"

rem Pre-built x64 static Qt, used as the host-tool source for cross-compiling.
set "QT_HOST_PATH=%~dp0Output\Binaries\x64-static"
set "QT_HOST_PATH_CMAKE_DIR=%QT_HOST_PATH:/=%/lib/cmake"
set "QT_HOST_PATH_CMAKE_DIR=%QT_HOST_PATH_CMAKE_DIR:\=/%"

if not exist "%QT_HOST_PATH%\bin\syncqt.exe" (
  echo [ERROR] Host Qt not found at %QT_HOST_PATH%
  echo Build it first: onekey-build-x64-static.bat
  echo ^(ARM64 is cross-compiled and needs the x64 host tools syncqt/moc/rcc.^)
  exit /B 1
)

set CommonOptions=-G "Ninja Multi-Config" -DCMAKE_CONFIGURATION_TYPES=Release -DCMAKE_SYSTEM_PROCESSOR=ARM64 -DWindowsTargetPlatformMinVersion=10.0.16299.0 -DBUILD_SHARED_LIBS=OFF -DFEATURE_static_runtime=ON -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH="%QT_HOST_PATH%" -DQT_HOST_PATH_CMAKE_DIR="%QT_HOST_PATH_CMAKE_DIR%"

mkdir %ObjectFolder%\qtbase 2>nul
pushd %ObjectFolder%\qtbase
cmake -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions%  -DFEATURE_sql=OFF -DFEATURE_optimize_size=ON -DINPUT_openssl=no -DFEATURE_schannel=ON -DINPUT_opengl=no -DFEATURE_dbus=OFF -DFEATURE_freetype=OFF -DFEATURE_system_freetype=OFF -DFEATURE_harfbuzz=OFF -DFEATURE_system_harfbuzz=OFF -DFEATURE_system_zlib=OFF ../../../../qtbase
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
