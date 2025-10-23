@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Diagnostico WSL <-> RSAD (Creado por Pascal)

rem === Ruta del informe: misma carpeta que el .bat ===
set "REPORT=%~dp0Diagnostico_WSL_RSAD_Pascal.txt"

set "OK=[OK]"
set "WARN=[ADVERTENCIA]"
set "BAD=[PROBLEMA]"
set /a BADCOUNT=0
set /a WARNCOUNT=0
set "PSTO=8"

> "%REPORT%" echo ==============================================
>>"%REPORT%" echo Diagnostico WSL ^<^> RSAD - Creado por Pascal
>>"%REPORT%" echo Fecha: %date%  Hora: %time%
>>"%REPORT%" echo Equipo: %COMPUTERNAME%  Usuario: %USERNAME%
>>"%REPORT%" echo Informe: %REPORT%
>>"%REPORT%" echo ==============================================

echo(
echo ===== Diagnostico WSL ^<^> RSAD - Creado por Pascal =====
echo (Se guardara un informe en "%REPORT%")
echo(

echo [1/9] Caracteristicas y servicios...
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue).State }; if(Wait-Job $j -Timeout %PSTO%) { Receive-Job $j } else { 'TIMEOUT' }" 2^>nul') do set "WSLFEATURE=%%A"
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue).State }; if(Wait-Job $j -Timeout %PSTO%) { Receive-Job $j } else { 'TIMEOUT' }" 2^>nul') do set "VMPFEATURE=%%A"
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $s=Get-Service -Name vmcompute -ErrorAction SilentlyContinue; if($s){$s.Status}else{'NotFound'} }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "VMCOMPUTE=%%A"
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $s=Get-Service -Name LxssManager -ErrorAction SilentlyContinue; if($s){$s.Status}else{'NotFound'} }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "LXSS=%%A"

set "HASWSL="
where wsl >nul 2>nul && set "HASWSL=1"
if defined HASWSL (
  for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { wsl --status ^| Select-String -Pattern 'Default Version' -SimpleMatch -ErrorAction SilentlyContinue }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "WSLSTATUS=%%A"
  for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { wsl --list --quiet -ErrorAction SilentlyContinue }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "HAVEDISTROS=1"
) else (
  set "WSLSTATUS=wsl.exe no encontrado"
)

echo [2/9] Red (adaptador WSL y ruta por defecto)...
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $a=Get-NetAdapter -Name 'vEthernet (WSL)' -ErrorAction SilentlyContinue; if($a){$a.Status}else{'NotFound'} }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "WSLNIC=%%A"
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $r=Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue ^| Sort-Object RouteMetric ^| Select-Object -First 1; if($r){$r.InterfaceAlias+'|'+$r.RouteMetric}else{'None'} }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do set "DEFROUTE=%%A"

echo [3/9] VPNs activas...
set "VPNLIST="
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $pat='vpn|tap|tun|anyconnect|globalprotect|pulse|forti|sonic|f5|juniper|checkpoint|wireguard|openvpn|zerotier|zscaler'; Get-NetAdapter -ErrorAction SilentlyContinue ^| Where-Object { $_.Status -eq 'Up' -and ( $_.Name -match $pat -or $_.InterfaceDescription -match $pat ) } ^| ForEach-Object { $_.Name } }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do (
  if not defined VPNLIST (set "VPNLIST=%%A") else set "VPNLIST=!VPNLIST!, %%A"
)

echo [4/9] Puertos tipicos (9080, 9443, 9060, 2809, 7777, 7001)...
set "PORTLINES="
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$j=Start-Job { $ports=9080,9443,9060,2809,7777,7001; $conns=Get-NetTCPConnection -State Listen -LocalPort $ports -ErrorAction SilentlyContinue; $conns ^| Sort-Object LocalPort -Unique ^| ForEach-Object { $p=Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; $name=if($p){$p.ProcessName}else{$_.OwningProcess}; '{0}|{1}|{2}' -f $_.LocalPort,$name,$_.OwningProcess } }; if(Wait-Job $j -Timeout %PSTO%){Receive-Job $j}else{'TIMEOUT'}" 2^>nul') do (
  if not defined PORTLINES (set "PORTLINES=%%A") else set "PORTLINES=!PORTLINES!#%%A"
)

echo [5/9] Docker/virtualizadores...
set "DOCKER="
for /f "delims=" %%A in ('tasklist 2^>nul ^| findstr /i docker') do set "DOCKER=1"

echo [6/9] PATH (herramientas Unix)...
set "PATHFLAGS="
echo %PATH% | findstr /i "Git\usr\bin" >nul && set "PATHFLAGS=Git\usr\bin"
echo %PATH% | findstr /i "msys64\usr\bin" >nul && if defined PATHFLAGS (set "PATHFLAGS=%PATHFLAGS%, msys64\usr\bin") else set "PATHFLAGS=msys64\usr\bin"
echo %PATH% | findstr /i "cygwin" >nul && if defined PATHFLAGS (set "PATHFLAGS=%PATHFLAGS%, Cygwin") else set "PATHFLAGS=Cygwin"

echo [7/9] Informacion de Windows...
for /f "tokens=*" %%A in ('ver') do set "WINVER=%%A"

rem ==== Normalizar valores vacios para asegurar salida ====
if not defined WSLFEATURE set "WSLFEATURE=desconocido"
if not defined VMPFEATURE set "VMPFEATURE=desconocido"
if not defined VMCOMPUTE set "VMCOMPUTE=desconocido"
if not defined LXSS set "LXSS=desconocido"
if not defined WSLSTATUS set "WSLSTATUS=desconocido"
if not defined WSLNIC set "WSLNIC=desconocido"
if not defined DEFROUTE set "DEFROUTE=desconocido"
if not defined WINVER set "WINVER=desconocido"

echo [8/9] Escribiendo resultados detallados...

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Sistema
>>"%REPORT%" echo(Windows: %WINVER%

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Caracteristicas y servicios

rem ---- Construir mensajes sin usar bloques con echos ----
if /i "%WSLFEATURE%"=="Enabled" (
  set "MSG_WSL_CON=WSL: Habilitado"
  set "MSG_WSL_CONSOLA=%WARN% WSL habilitado."
) else (
  set "MSG_WSL_CON=WSL: %WSLFEATURE%"
  set "MSG_WSL_CONSOLA=%OK% WSL deshabilitado o no disponible (%WSLFEATURE%)."
)

if /i "%VMPFEATURE%"=="Enabled" (
  set "MSG_VMP=Virtual Machine Platform: Habilitado"
  set "MSG_VMP_CONSOLA=%WARN% Virtual Machine Platform habilitada."
) else (
  set "MSG_VMP=Virtual Machine Platform: %VMPFEATURE%"
  set "MSG_VMP_CONSOLA=%OK% Virtual Machine Platform deshabilitada o no disponible (%VMPFEATURE%)."
)

if /i "%VMCOMPUTE%"=="Running" (
  set "MSG_VMCOMPUTE=Servicio vmcompute: Running"
  set "MSG_VMCOMPUTE_CONSOLA=%WARN% Servicio vmcompute en ejecucion."
) else if /i "%VMCOMPUTE%"=="NotFound" (
  set "MSG_VMCOMPUTE=Servicio vmcompute: No instalado"
  set "MSG_VMCOMPUTE_CONSOLA=%OK% vmcompute no instalado."
) else (
  set "MSG_VMCOMPUTE=Servicio vmcompute: %VMCOMPUTE%"
  set "MSG_VMCOMPUTE_CONSOLA=%OK% vmcompute no esta ejecutandose (%VMCOMPUTE%)."
)

if /i "%LXSS%"=="Running" (
  set "MSG_LXSS=Servicio LxssManager: Running"
  set "MSG_LXSS_CONSOLA=%WARN% Servicio LxssManager en ejecucion."
) else if /i "%LXSS%"=="NotFound" (
  set "MSG_LXSS=Servicio LxssManager: No instalado"
  set "MSG_LXSS_CONSOLA=%OK% LxssManager no instalado."
) else (
  set "MSG_LXSS=Servicio LxssManager: %LXSS%"
  set "MSG_LXSS_CONSOLA=%OK% LxssManager no esta ejecutandose (%LXSS%)."
)

echo(!MSG_WSL_CONSOLA!
echo(!MSG_VMP_CONSOLA!
echo(!MSG_VMCOMPUTE_CONSOLA!
echo(!MSG_LXSS_CONSOLA!

>>"%REPORT%" echo(!MSG_WSL_CON!
>>"%REPORT%" echo(!MSG_VMP!
>>"%REPORT%" echo(!MSG_VMCOMPUTE!
>>"%REPORT%" echo(!MSG_LXSS!

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Estado de WSL
if defined HASWSL (>>"%REPORT%" echo(Binario wsl.exe: presente) else (>>"%REPORT%" echo(Binario wsl.exe: no encontrado)
if defined HAVEDISTROS (
  echo(%WARN% Distros WSL detectadas.
  >>"%REPORT%" echo(Distros: presentes
) else (
  echo(%OK% No se detectan distros WSL.
  >>"%REPORT%" echo(Distros: no
)
>>"%REPORT%" echo(Detalle: %WSLSTATUS%

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Red

if /i "%WSLNIC%"=="Up" (
  set "MSG_NIC=vEthernet (WSL): Activo"
  set "MSG_NIC_CONSOLA=%WARN% Adaptador vEthernet (WSL) activo."
) else if /i "%WSLNIC%"=="NotFound" (
  set "MSG_NIC=vEthernet (WSL): No encontrado"
  set "MSG_NIC_CONSOLA=%OK% No se encontro vEthernet (WSL)."
) else (
  set "MSG_NIC=vEthernet (WSL): %WSLNIC%"
  set "MSG_NIC_CONSOLA=%OK% vEthernet (WSL): %WSLNIC%"
)

echo(!MSG_NIC_CONSOLA!
>>"%REPORT%" echo(!MSG_NIC!

set "DEF_MSG=Ruta por defecto: %DEFROUTE%"
if /i not "%DEFROUTE%"=="None" if /i not "%DEFROUTE%"=="TIMEOUT" if /i not "%DEFROUTE%"=="desconocido" (
  for /f "tokens=1,2 delims=|" %%I in ("%DEFROUTE%") do (
    set "DEFIF=%%I"
    set "DEFMET=%%J"
  )
  set "DEF_MSG=Ruta por defecto: !DEFIF! [Metrica !DEFMET!]"
  echo(!DEFIF! | findstr /i "vEthernet (WSL)" >nul && (
    set "DEF_ALERT=%BAD% La ruta por defecto pasa por WSL; puede romper VPN/servidores."
    set /a BADCOUNT+=1
  )
)
if defined DEF_ALERT echo(!DEF_ALERT!
>>"%REPORT%" echo(!DEF_MSG!

>>"%REPORT%" echo(
>>"%REPORT%" echo ## VPN
if defined VPNLIST (
  echo(%WARN% VPN/Adaptadores activos: %VPNLIST%
  >>"%REPORT%" echo(Activas: %VPNLIST%
  set /a WARNCOUNT+=1
) else (
  echo(%OK% No se detectaron VPN activas.
  >>"%REPORT%" echo(Activas: no
)

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Puertos tipicos RSAD/WebSphere
if defined PORTLINES if /i not "%PORTLINES%"=="TIMEOUT" (
  for %%L in (%PORTLINES:#= %) do (
    for /f "tokens=1,2,3 delims=|" %%P in ("%%~L") do (
      echo(%BAD% Puerto %%P en uso por %%Q (PID %%R)
      >>"%REPORT%" echo(Puerto %%P ocupado por %%Q (PID %%R)
      set /a BADCOUNT+=1
    )
  )
) else (
  echo(%OK% Puertos 9080, 9443, 9060, 2809, 7777, 7001 libres o TIMEOUT.
  >>"%REPORT%" echo(Libres (o TIMEOUT en consulta)
)

>>"%REPORT%" echo(
>>"%REPORT%" echo ## Otros
if defined DOCKER (
  echo(%WARN% Docker detectado.
  >>"%REPORT%" echo(Docker: detectado
  set /a WARNCOUNT+=1
) else (
  echo(%OK% Docker no detectado.
  >>"%REPORT%" echo(Docker: no
)
if defined PATHFLAGS (
  echo(%WARN% Rutas Unix en PATH: %PATHFLAGS%
  >>"%REPORT%" echo(PATH con Unix: %PATHFLAGS%
  set /a WARNCOUNT+=1
) else (
  echo(%OK% PATH sin rutas Unix problematicas.
  >>"%REPORT%" echo(PATH: sin hallazgos
)

echo [9/9] Resumen final...
echo(
echo Resumen:
if %BADCOUNT% gtr 0 (echo %BAD% Conflictos criticos: %BADCOUNT%) else (echo %OK% Sin conflictos criticos.)
if %WARNCOUNT% gtr 0 (echo %WARN% Advertencias: %WARNCOUNT%) else (echo %OK% Sin advertencias.)
if %BADCOUNT% equ 0 if %WARNCOUNT% equ 0 (
  echo %OK% No se detectaron problemas.
  >>"%REPORT%" echo(**No se detectaron problemas.**
) else (
  >>"%REPORT%" echo(Resumen -> Criticos: %BADCOUNT% ; Advertencias: %WARNCOUNT%
)

>>"%REPORT%" echo(---
>>"%REPORT%" echo(Sugerencias:
>>"%REPORT%" echo(- Si la ruta por defecto apunta a vEthernet ^(WSL^), desactiva WSL/Hyper-V y prueba de nuevo.
>>"%REPORT%" echo(- Cierra Docker si usas VPN corporativa o hay puertos ocupados.
>>"%REPORT%" echo(- Evita herramientas Unix en PATH por delante de System32 en instalaciones/uso de RSAD.

echo(
echo Informe guardado en: "%REPORT%"
start "" notepad "%REPORT%"
echo(
echo (Pulsa una tecla para cerrar)
pause >nul

if %BADCOUNT% gtr 0 (exit /b 2) else if %WARNCOUNT% gtr 0 (exit /b 1) else exit /b 0
