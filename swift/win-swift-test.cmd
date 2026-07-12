@echo off
REM ---------------------------------------------------------------------------
REM Build + test HRVCore on Windows (incl. Windows on ARM64).
REM Sets up the VS ARM64 developer env, puts the Swift toolchain on PATH, and
REM points SDKROOT at the Swift Windows SDK (winget's silent install leaves it
REM unset -- that is what causes "unable to load standard library").
REM
REM Prerequisites (one-time):
REM   winget install Swift.Toolchain
REM   winget install Microsoft.VisualStudio.2022.BuildTools --override ^
REM     "--quiet --add Microsoft.VisualStudio.Workload.VCTools ^
REM      --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 ^
REM      --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
REM
REM Usage:  swift\win-swift-test.cmd            (runs `swift test`)
REM         swift\win-swift-test.cmd build      (any swift subcommand + args)
REM ---------------------------------------------------------------------------
setlocal
set "SWIFT_VER=6.3.3"

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VSPATH=%%i"
call "%VSPATH%\VC\Auxiliary\Build\vcvarsall.bat" arm64

set "SWIFT=%LOCALAPPDATA%\Programs\Swift"
set "PATH=%SWIFT%\Toolchains\%SWIFT_VER%+Asserts\usr\bin;%SWIFT%\Runtimes\%SWIFT_VER%\usr\bin;%PATH%"
set "SDKROOT=%SWIFT%\Platforms\%SWIFT_VER%\Windows.platform\Developer\SDKs\Windows.sdk"

cd /d "%~dp0"
if "%~1"=="" (
    swift test
) else (
    swift %*
)
