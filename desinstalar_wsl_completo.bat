@echo off
setlocal EnableExtensions EnableDelayedExpansion

wsl --shutdown 2>nul
for /f "delims=" %%D in ('wsl --list --all --quiet 2^>nul') do wsl --unregister "%%D"
wsl --uninstall 2>nul

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers *WindowsSubsystemForLinux* ^| ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers *WSLg* ^| ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers ^| Where-Object { $_.Name -match 'Ubuntu|Debian|SUSE|openSUSE|Kali|Alpine|Pengwin|Oracle|Rocky|Fedora|CentOS|Alma|Mariner|Arch|Manjaro|Parrot' } ^| ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }"

sc stop LxssManager 1>nul 2>nul

dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /NoRestart
dism /online /disable-feature /featurename:VirtualMachinePlatform /NoRestart

del /q "%USERPROFILE%\.wslconfig" 2>nul
rmdir /s /q "%ProgramData%\wsl" 2>nul
rmdir /s /q "%LOCALAPPDATA%\lxss" 2>nul

for %%P in (*Ubuntu* *Debian* *SUSE* *openSUSE* *Kali* *Alpine* *Pengwin* *Oracle* *Rocky* *Fedora* *CentOS* *Alma* *Mariner* *Arch* *Manjaro* *Parrot*) do (
  for /d %%F in ("%LOCALAPPDATA%\Packages\%%P") do rmdir /s /q "%%F"
)

exit /b
