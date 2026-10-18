@setlocal

@echo off

set VisualStudioInstallerFolder="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if %PROCESSOR_ARCHITECTURE%==x86 set VisualStudioInstallerFolder="%ProgramFiles%\Microsoft Visual Studio\Installer"

pushd %VisualStudioInstallerFolder%
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VisualStudioInstallDir=%%i
)
popd

call "%VisualStudioInstallDir%\VC\Auxiliary\Build\vcvarsall.bat" amd64_arm64
set YYTHUNKS_INSTALL_DIR="%~dp0YY-Thunks"
set ObjectFolder="%~dp0Output\Objects\arm64"
set BinaryFolder="%~dp0Output\Binaries\arm64"

rem Remove the output folder for a fresh compile.
rem rd /s /q %ObjectFolder%
rem rd /s /q %BinaryFolder%

mkdir %BinaryFolder%

set "PATH=%~dp0qtbase\bin;%PATH%"

rem CROSS-COMPILE REQUIREMENTS (x64 host -> ARM64 target).
rem ARM64 is cross-compiled here, so CMake must be told so explicitly:
rem   - CMAKE_SYSTEM_PROCESSOR=ARM64  -> sets CMAKE_CROSSCOMPILING=TRUE, so Qt
rem     reuses host tools instead of trying to build+run ARM64 syncqt.
rem   - QT_HOST_PATH                  -> host tools (syncqt/moc/rcc) from a
rem     previously built x64 install (onekey-build-x64.bat / -static.bat).
rem Without these the configure step fails with
rem   "syncqt.cpp failed for module QtZlib" (with an empty error message).
set "QT_HOST_PATH=%~dp0Output\Binaries\x64"
if not exist "%QT_HOST_PATH%\bin\syncqt.exe" set "QT_HOST_PATH=%~dp0Output\Binaries\x64-static"
set "QT_HOST_PATH_CMAKE_DIR=%QT_HOST_PATH:/=%/lib/cmake"
set "QT_HOST_PATH_CMAKE_DIR=%QT_HOST_PATH_CMAKE_DIR:\=/%"

set CommonOptions=-G "Ninja Multi-Config" -DCMAKE_CONFIGURATION_TYPES=Release;Debug -DCMAKE_SYSTEM_PROCESSOR=ARM64 -DWindowsTargetPlatformMinVersion=10.0.16299.0 -DBUILD_SHARED_LIBS=ON -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH="%QT_HOST_PATH%" -DQT_HOST_PATH_CMAKE_DIR="%QT_HOST_PATH_CMAKE_DIR%"

mkdir %ObjectFolder%\qtbase
pushd %ObjectFolder%\qtbase
cmake -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions%  -DFEATURE_sql=OFF -DFEATURE_optimize_size=ON -DINPUT_openssl=no -DFEATURE_schannel=ON -DINPUT_opengl=no -DFEATURE_dbus=OFF -DFEATURE_freetype=OFF -DFEATURE_system_freetype=OFF -DFEATURE_harfbuzz=OFF -DFEATURE_system_harfbuzz=OFF -DFEATURE_system_zlib=OFF ../../../../qtbase
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtactiveqt
pushd %ObjectFolder%\qtactiveqt
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtactiveqt
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtsvg
pushd %ObjectFolder%\qtsvg
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtsvg
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtimageformats
pushd %ObjectFolder%\qtimageformats
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtimageformats
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtshadertools
pushd %ObjectFolder%\qtshadertools
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtshadertools
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtlanguageserver
pushd %ObjectFolder%\qtlanguageserver
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtlanguageserver
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qtdeclarative
pushd %ObjectFolder%\qtdeclarative
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qtdeclarative
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qttools
pushd %ObjectFolder%\qttools
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qttools
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

mkdir %ObjectFolder%\qttranslations
pushd %ObjectFolder%\qttranslations
cmake -DCMAKE_PREFIX_PATH=%BinaryFolder% -DCMAKE_INSTALL_PREFIX=%BinaryFolder% %CommonOptions% ../../../../qttranslations
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
cmake --build . --parallel
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
ninja install
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

@endlocal