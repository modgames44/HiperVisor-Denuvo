@echo off
setlocal EnableDelayedExpansion

:: ========================================
:: WINDOWS SECURITY FEATURES MANAGER v2.0
:: ========================================
:: Script para gestionar caracteristicas de seguridad de Windows
:: Permite ver estado y activar/desactivar:
:: - VBS (Virtualization-based Security)
:: - HVCI (Memory Integrity)
:: - Windows Hello Protection
:: - System Guard Secure Launch
:: - Credential Guard
:: - KVA Shadow (Meltdown Mitigation)
::
:: MEJORAS v2.0 (sin cambios de estructura):
:: [+] Verificacion de UEFI Lock antes de desactivar
:: [+] Desactiva solo lo que esta realmente activo
:: [+] KVA Shadow solo en CPUs vulnerables a Meltdown
:: [+] Restauracion fiel del Hypervisor
:: [+] Gestion de BitLocker antes de reiniciar
:: [+] Verificacion de VT-x/SVM en BIOS
:: ========================================

:: Elevar privilegios si es necesario
fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo Este script requiere privilegios de Administrador.
    echo.
    echo Se mostrara un aviso UAC. Por favor haz clic en "Si".
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: ========================================
:: CONFIGURACION DE COLORES ANSI
:: ========================================

for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "cGreen=%ESC%[92m"
set "cRed=%ESC%[91m"
set "cYellow=%ESC%[93m"
set "cCyan=%ESC%[96m"
set "cMagenta=%ESC%[95m"
set "cWhite=%ESC%[97m"
set "cReset=%ESC%[0m"

:: Verificar soporte de colores ANSI
set "_NCS=1"
for /f "tokens=3" %%A in ('reg query "HKCU\Console" /v VirtualTerminalLevel 2^>nul') do if "%%A"=="0x0" set "_NCS=0"
if "!_NCS!"=="0" (
    set "cGreen=" & set "cRed=" & set "cYellow=" & set "cCyan=" & set "cMagenta=" & set "cWhite=" & set "cReset="
)

:: ========================================
:: PROGRAMA PRINCIPAL
:: ========================================

call :check_admin
call :main_loop
exit /b

:: ========================================
:: BUCLE PRINCIPAL DEL MENU
:: ========================================

:main_loop
call :show_menu
choice /C:12340 /N /M ""
set "opt=!errorlevel!"
if "!opt!"=="1" call :show_status
if "!opt!"=="2" call :enable_all
if "!opt!"=="3" call :disable_all
if "!opt!"=="4" call :revert_changes
if "!opt!"=="5" (
    echo.
    echo  !cCyan!Hasta luego!!cReset!
    echo.
    exit /b
)
goto :main_loop

:: ========================================
:: FUNCIONES AUXILIARES
:: ========================================

:check_admin
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  !cRed!Este script requiere privilegios de Administrador.!cReset!
    echo  !cYellow!Por favor, ejecuta el script como Administrador.!cReset!
    echo.
    pause
    exit /b 1
)
exit /b

:show_title
cls
call :get_sysinfo
echo  !cMagenta!===============================================================!cReset!
echo  !cMagenta!   WINDOWS SECURITY FEATURES MANAGER  v2.0!cReset!
echo  !cMagenta!   Gestor de Caracteristicas de Seguridad de Windows!cReset!
echo  !cMagenta!===============================================================!cReset!
if defined winos (
    echo  !cCyan!  Sistema: !winos! ^| Build: !fullbuild! ^| !osarch!!cReset!
)
echo.
exit /b

:show_menu
call :show_title
echo  !cCyan!MENU PRINCIPAL!cReset!
echo  ----------------------------------
echo  [1] Ver Estado de Caracteristicas
echo  [2] Activar Todas las Caracteristicas
echo  [3] Desactivar Todas las Caracteristicas
echo  [4] Revertir Cambios
echo  [0] Salir
echo  ----------------------------------
echo.
set /p "=  Selecciona una opcion: " <nul
exit /b

:: ========================================
:: FUNCIONES DE VERIFICACION DE ESTADO
:: ========================================

:get_vbs_status
set "vbs_status=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity 2^>nul') do (
    if "%%A"=="0x1" set "vbs_status=1"
)
exit /b

:get_hvci_status
set "hvci_status=0"
for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning" 2^>nul') do (
    if "%%s"=="2" set "hvci_status=1"
)
if "!hvci_status!"=="0" (
    for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul') do (
        if "%%A"=="0x1" set "hvci_status=1"
    )
)
exit /b

:get_winhello_status
set "winhello_status=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "winhello_status=1"
)
exit /b

:get_sysguard_status
set "sysguard_status=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "sysguard_status=1"
)
exit /b

:get_credguard_status
set "credguard_status=0"
for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning" 2^>nul') do (
    if "%%s"=="1" set "credguard_status=1"
)
if "!credguard_status!"=="0" (
    for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags 2^>nul') do (
        if "%%A"=="0x2" set "credguard_status=1"
    )
)
exit /b

:get_kva_status
set "kva_status=1"
set "kva1=" & set "kva2="
for /f "tokens=3" %%A in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride 2^>nul') do set "kva1=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask 2^>nul') do set "kva2=%%A"
if "!kva1!"=="0x2" if "!kva2!"=="0x3" set "kva_status=0"
exit /b

:get_hypervisor_status
set "hyp_status=0"
set "hyp_bcd_value="
for /f "tokens=2" %%A in ('bcdedit /enum {current} 2^>nul ^| findstr /i "hypervisorlaunchtype"') do (
    set "hyp_bcd_value=%%A"
    if /i "%%A"=="Auto" set "hyp_status=1"
    if /i "%%A"=="On"   set "hyp_status=1"
)
:: [NUEVO] Si no hay entrada BCD explicita, verificar via WMI
:: Cubre Windows 11 donde el hipervisor corre sin entrada BCD
if "!hyp_status!"=="0" if not defined hyp_bcd_value (
    set "hypvbs=0" & set "hyphyp=0"
    for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).VirtualizationBasedSecurityStatus" 2^>nul') do (
        if "%%s"=="1" set "hypvbs=1"
        if "%%s"=="2" set "hypvbs=1"
    )
    for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent" 2^>nul') do (
        if /i "%%s"=="True" set "hyphyp=1"
    )
    if "!hypvbs!"=="1" if "!hyphyp!"=="1" set "hyp_status=1"
)
exit /b

:: ========================================
:: [NUEVO] VERIFICAR VT-x / AMD-SVM EN BIOS
:: ========================================

:check_vtx
set "vtx=0"
for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance -ClassName Win32_Processor).VirtualizationFirmwareEnabled" 2^>nul') do (
    if /i "%%s"=="True" set "vtx=1"
)
if "!vtx!"=="0" (
    for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent" 2^>nul') do (
        if /i "%%s"=="True" set "vtx=1"
    )
)
if "!vtx!"=="0" (
    echo.
    echo  !cYellow!ADVERTENCIA: Virtualizacion (VT-x/AMD-SVM) no detectada en BIOS.!cReset!
    echo  !cYellow!Algunas operaciones pueden fallar. Se recomienda habilitarla en la UEFI.!cReset!
    echo.
    choice /C:SN /N /M "  ^¿Deseas continuar de todas formas? (S/N): "
    if errorlevel 2 exit /b
)
exit /b

:: ========================================
:: [NUEVO] VERIFICAR UEFI LOCK
:: Salida: uefi_blocked=1 si hay bloqueo
:: ========================================

:check_uefi_lock
set "uefi_blocked=0"
set "vbslocked=" & set "hvcilocked=" & set "cglocked=" & set "mandatorylocked="
set "dgquery="
for /f "delims=" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /s 2^>nul') do set "dgquery=1"
if not defined dgquery exit /b
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked 2^>nul') do if "%%A"=="0x1" set "vbslocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked 2^>nul') do if "%%A"=="0x1" set "hvcilocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags 2^>nul') do if "%%A"=="0x1" set "cglocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Mandatory 2^>nul') do if "%%A"=="0x1" set "mandatorylocked=1"
if defined vbslocked      echo  !cRed![LOCK] VBS protegido por UEFI Lock. No puede desactivarse.!cReset! & set "uefi_blocked=1"
if defined hvcilocked     echo  !cRed![LOCK] HVCI protegido por UEFI Lock. No puede desactivarse.!cReset! & set "uefi_blocked=1"
if defined cglocked       echo  !cRed![LOCK] Credential Guard protegido por UEFI Lock.!cReset! & set "uefi_blocked=1"
if defined mandatorylocked echo  !cRed![LOCK] VBS/HVCI en modo Mandatory. No pueden desactivarse.!cReset! & set "uefi_blocked=1"
exit /b

:: ========================================
:: [NUEVO] VERIFICAR SI CPU ES VULNERABLE A MELTDOWN
:: Salida: kva_required=1 si aplica desactivar KVA
:: ========================================

:check_kva_required
set "kva_required=0"
for /f "delims=" %%s in ('powershell -nop -c "$d=Add-Type -MemberDefinition '[DllImport(\"ntdll.dll\")] public static extern int NtQuerySystemInformation(uint a,IntPtr b,uint c,IntPtr d);' -Name n -Namespace w -PassThru;$p=[Runtime.InteropServices.Marshal]::AllocHGlobal(4);$r=[Runtime.InteropServices.Marshal]::AllocHGlobal(4);$ret=$d::NtQuerySystemInformation(196,$p,4,$r);if($ret -eq 0){$f=[uint32][Runtime.InteropServices.Marshal]::ReadInt32($p);if(($f -band 0x01)-ne 0 -or (($f -band 0x20)-ne 0 -and ($f -band 0x10)-ne 0)){Write-Output 1}else{Write-Output 0}}else{Write-Output 0}" 2^>nul') do (
    if "%%s"=="1" set "kva_required=1"
)
exit /b

:: ========================================
:: [NUEVO] VERIFICAR Y SUSPENDER BITLOCKER
:: Parametro %~1 = reinicios a suspender (1 o 2)
:: Salida: bl_ok=1 si ok, bl_ok=0 si fallo
:: ========================================

:check_bitlocker
set "bl_ok=1"
set "blprotected=0"
set "bl_reboots=%~1"
if "!bl_reboots!"=="" set "bl_reboots=1"
for /f "delims=" %%s in ('powershell -nop -c "(Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus" 2^>nul') do (
    if "%%s"=="On" set "blprotected=1"
)
if "!blprotected!"=="1" (
    echo.
    echo  !cYellow!BitLocker detectado. Suspendiendo por !bl_reboots! reinicio(s)...!cReset!
    manage-bde -protectors -disable %SystemDrive% -rebootcount !bl_reboots! >nul 2>&1
    if errorlevel 1 (
        echo  !cRed!No se pudo suspender BitLocker. Reinicio cancelado por seguridad.!cReset!
        set "bl_ok=0"
    ) else (
        echo  !cGreen!BitLocker suspendido correctamente. El cifrado sigue activo.!cReset!
    )
)
exit /b

:: ========================================
:: [NUEVO] INFORMACION DEL SISTEMA OPERATIVO
:: Popula: winos, fullbuild, osarch
:: ========================================

:get_sysinfo
set "winbuild=0"
for /f "tokens=2 delims=[]" %%G in ('ver') do (
    for /f "tokens=2,3,4 delims=. " %%H in ("%%~G") do set "winbuild=%%J"
)
set "osarch="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE 2^>nul') do set "osarch=%%b"
set "fullbuild="
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if not "%%j"=="" (
    set "fullbuild=%%i.%%j"
) else (
    set "UBR="
    for /f "tokens=3" %%G in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v UBR 2^>nul') do set /a "UBR=%%G"
    for /f "skip=2 tokens=3,4 delims=. " %%G in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx 2^>nul') do (
        if defined UBR (set "fullbuild=%%G.!UBR!") else (set "fullbuild=%%G.%%H")
    )
)
set "winos="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winos=%%b"
if !winbuild! GEQ 22000 set "winos=!winos:Windows 10=Windows 11!"
exit /b

:: ========================================
:: [NUEVO] VERIFICAR SMART APP CONTROL
:: Solo aplica en Windows 11 build 22621+
:: ========================================

:check_smart_app_control
set "sacstate="
if !winbuild! GEQ 22621 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState 2^>nul') do set "sacstate=%%a"
)
if defined sacstate (
    if "!sacstate!"=="0x1" (
        echo.
        echo  !cYellow!Smart App Control esta ACTIVO en este sistema.!cReset!
        echo  !cYellow!Puede bloquear ciertas aplicaciones. Considera desactivarlo en Seguridad de Windows.!cReset!
        echo.
    )
    if "!sacstate!"=="0x2" (
        echo.
        echo  !cYellow!Smart App Control esta en modo EVALUACION.!cReset!
        echo  !cYellow!Puede activarse automaticamente. Se recomienda desactivarlo en Seguridad de Windows.!cReset!
        echo.
    )
)
exit /b

:show_status
call :show_title
echo  !cCyan!ESTADO DE CARACTERISTICAS DE SEGURIDAD!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

call :get_vbs_status
call :print_status "VBS (Virtualization-based Security)" !vbs_status!

call :get_hvci_status
call :print_status "HVCI (Memory Integrity)" !hvci_status!

call :get_winhello_status
call :print_status "Windows Hello Protection" !winhello_status!

call :get_sysguard_status
call :print_status "System Guard Secure Launch" !sysguard_status!

call :get_credguard_status
call :print_status "Credential Guard" !credguard_status!

call :get_kva_status
call :print_status "KVA Shadow (Meltdown Mitigation)" !kva_status!

call :get_hypervisor_status
call :print_status "Windows Hypervisor" !hyp_status!

:: [NUEVO] Mostrar estado de UEFI Lock en pantalla de estado
echo  !cWhite!UEFI Lock / Mandatory Mode!cReset!
set "any_lock=0"
set "vbslocked=" & set "hvcilocked=" & set "mandatorylocked="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked 2^>nul') do if "%%A"=="0x1" set "vbslocked=1" & set "any_lock=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked 2^>nul') do if "%%A"=="0x1" set "hvcilocked=1" & set "any_lock=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Mandatory 2^>nul') do if "%%A"=="0x1" set "mandatorylocked=1" & set "any_lock=1"
if "!any_lock!"=="1" (
    if defined vbslocked       echo      !cRed![!] VBS protegido por UEFI Lock!cReset!
    if defined hvcilocked      echo      !cRed![!] HVCI protegido por UEFI Lock!cReset!
    if defined mandatorylocked echo      !cRed![!] VBS/HVCI en modo Mandatory!cReset!
) else (
    echo      Estado: !cGreen![+] Sin bloqueos UEFI detectados!cReset!
)
echo.

echo  !cCyan!==========================================================!cReset!
echo.
pause
exit /b

:print_status
:: %~1 = nombre, %2 = estado (1=activo, 0=inactivo)
echo  !cWhite!%~1!cReset!
if "%2"=="1" (
    echo      Estado: !cGreen![+] ACTIVO!cReset!
) else (
    echo      Estado: !cRed![-] INACTIVO!cReset!
)
echo.
exit /b

:: ========================================
:: ACTIVAR TODAS LAS CARACTERISTICAS
:: ========================================

:enable_all
call :show_title
echo  !cYellow!ACTIVANDO TODAS LAS CARACTERISTICAS...!cReset!
echo.

set /p "=  Activando VBS...                        " <nul
call :enable_vbs

set /p "=  Activando HVCI...                       " <nul
call :enable_hvci

set /p "=  Activando Windows Hello...              " <nul
call :enable_winhello

set /p "=  Activando System Guard...               " <nul
call :enable_sysguard

set /p "=  Activando Credential Guard...           " <nul
call :enable_credguard

set /p "=  Activando KVA Shadow...                 " <nul
call :enable_kva

set /p "=  Activando Hypervisor...                 " <nul
call :enable_hypervisor

echo.
echo  !cYellow!NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios.!cReset!
echo.
choice /C:SN /N /M "  ^¿Deseas reiniciar el equipo ahora? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Reinicio cancelado. Recuerda reiniciar mas tarde.!cReset!
    echo.
    pause
    exit /b
)
:: [NUEVO] Verificar BitLocker antes de reiniciar
call :check_bitlocker 1
if "!bl_ok!"=="0" (
    echo.
    echo  !cYellow!Reinicio cancelado. Resuelve BitLocker y reinicia manualmente.!cReset!
    echo.
    pause
    exit /b
)
echo.
echo  !cCyan!Reiniciando...!cReset!
shutdown /r /t 0
exit /b

:: ========================================
:: DESACTIVAR TODAS LAS CARACTERISTICAS
:: ========================================

:disable_all
call :show_title
echo  !cYellow!DESACTIVANDO TODAS LAS CARACTERISTICAS...!cReset!
echo.

:: [NUEVO] Verificar VT-x en BIOS
call :check_vtx

:: [NUEVO] Verificar UEFI Lock antes de proceder
echo  !cCyan!Verificando bloqueos UEFI...!cReset!
call :check_uefi_lock
if "!uefi_blocked!"=="1" (
    echo.
    echo  !cRed!No es posible continuar. Resuelve el bloqueo UEFI antes de usar esta opcion.!cReset!
    echo.
    pause
    exit /b
)
echo  !cGreen!Sin bloqueos UEFI detectados.!cReset!
echo.

choice /C:SN /N /M "  ^!Estas seguro? Esto desactivara TODAS las protecciones de seguridad. (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Operacion cancelada!cReset!
    echo.
    pause
    exit /b
)
echo.

:: [NUEVO] Guardar valor exacto de hypervisorlaunchtype para restauracion fiel
set "hyp_bcd_saved="
for /f "tokens=2" %%A in ('bcdedit /enum {current} 2^>nul ^| findstr /i "hypervisorlaunchtype"') do set "hyp_bcd_saved=%%A"

:: Guardar estado previo antes de desactivar (para poder revertir)
call :get_vbs_status
if "!vbs_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v VBS /t REG_DWORD /d 1 /f >nul 2>&1

call :get_hvci_status
if "!hvci_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v HVCI /t REG_DWORD /d 1 /f >nul 2>&1

call :get_winhello_status
if "!winhello_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v WindowsHello /t REG_DWORD /d 1 /f >nul 2>&1

call :get_sysguard_status
if "!sysguard_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v SystemGuard /t REG_DWORD /d 1 /f >nul 2>&1

call :get_credguard_status
if "!credguard_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard /t REG_DWORD /d 1 /f >nul 2>&1

call :get_kva_status
if "!kva_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v KVAShadow /t REG_DWORD /d 1 /f >nul 2>&1

call :get_hypervisor_status
if "!hyp_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS" /v Hypervisor /t REG_DWORD /d 1 /f >nul 2>&1
    :: [NUEVO] Guardar el valor exacto de BCD para restauracion fiel
    if defined hyp_bcd_saved (
        reg add "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType /t REG_SZ /d "!hyp_bcd_saved!" /f >nul 2>&1
    )
)

:: [NUEVO] Desactivar solo lo que esta activo (condicional)
call :get_vbs_status
if "!vbs_status!"=="1" (
    set /p "=  Desactivando VBS...                     " <nul
    call :disable_vbs
) else (
    echo  !cYellow!  VBS ya estaba inactivo. Omitido.!cReset!
)

call :get_hvci_status
if "!hvci_status!"=="1" (
    set /p "=  Desactivando HVCI...                    " <nul
    call :disable_hvci
) else (
    echo  !cYellow!  HVCI ya estaba inactivo. Omitido.!cReset!
)

call :get_winhello_status
if "!winhello_status!"=="1" (
    set /p "=  Desactivando Windows Hello...           " <nul
    call :disable_winhello
) else (
    echo  !cYellow!  Windows Hello ya estaba inactivo. Omitido.!cReset!
)

call :get_sysguard_status
if "!sysguard_status!"=="1" (
    set /p "=  Desactivando System Guard...            " <nul
    call :disable_sysguard
) else (
    echo  !cYellow!  System Guard ya estaba inactivo. Omitido.!cReset!
)

call :get_credguard_status
if "!credguard_status!"=="1" (
    set /p "=  Desactivando Credential Guard...        " <nul
    call :disable_credguard
) else (
    echo  !cYellow!  Credential Guard ya estaba inactivo. Omitido.!cReset!
)

:: [NUEVO] KVA Shadow solo si la CPU es vulnerable a Meltdown
call :check_kva_required
if "!kva_required!"=="1" (
    call :get_kva_status
    if "!kva_status!"=="1" (
        set /p "=  Desactivando KVA Shadow...              " <nul
        call :disable_kva
    ) else (
        echo  !cYellow!  KVA Shadow ya estaba desactivado. Omitido.!cReset!
    )
) else (
    echo  !cCyan!  KVA Shadow: CPU no vulnerable a Meltdown. No se modifica.!cReset!
)

call :get_hypervisor_status
if "!hyp_status!"=="1" (
    set /p "=  Desactivando Hypervisor...              " <nul
    call :disable_hypervisor
) else (
    echo  !cYellow!  Hypervisor ya estaba inactivo. Omitido.!cReset!
)

echo.
echo  !cYellow!NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios.!cReset!
echo.
:: [NUEVO] Verificar Smart App Control (Windows 11 build 22621+)
call :check_smart_app_control
echo  !cCyan!El sistema reiniciara directamente en el menu de opciones avanzadas.!cReset!
echo  !cCyan!Desde ahi podras seleccionar la opcion 7: Deshabilitar la firma obligatoria de controladores.!cReset!
echo.
choice /C:SN /N /M "  ^¿Deseas reiniciar ahora en modo avanzado (F7)? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Reinicio cancelado. Recuerda reiniciar mas tarde.!cReset!
    echo.
    pause
    exit /b
)
:: [NUEVO] Verificar BitLocker antes de reiniciar
call :check_bitlocker 1
if "!bl_ok!"=="0" (
    echo.
    echo  !cYellow!Reinicio cancelado. Resuelve BitLocker y reinicia manualmente.!cReset!
    echo.
    pause
    exit /b
)
:: [NUEVO] Doble reinicio para Credential Guard en Windows 10
:: En W10 se necesitan 2 boots para desactivar CG completamente
if "!credguard_status!"=="1" if !winbuild! LEQ 19045 (
    echo.
    echo  !cYellow!Credential Guard en Windows 10 requiere dos reinicios.!cReset!
    echo  !cYellow!El segundo reinicio se programara automaticamente.!cReset!
    call :check_bitlocker 2
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "HV_Reboot2" /t REG_SZ /d "bcdedit /set {current} onetimeadvancedoptions on" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "HV_Reboot3" /t REG_SZ /d "shutdown /r /t 5" /f >nul 2>&1
)
bcdedit /set {current} onetimeadvancedoptions on >nul 2>&1
if errorlevel 1 (
    echo.
    echo  !cRed!Error al configurar el reinicio avanzado.!cReset!
    echo.
    pause
    exit /b
)
echo.
echo  !cGreen!Reiniciando hacia el menu avanzado...!cReset!
ping -n 3 127.0.0.1 >nul
shutdown /r /t 0
exit /b

:: ========================================
:: REVERTIR CAMBIOS
:: ========================================

:revert_changes
call :show_title
echo  !cCyan!REVERTIR CAMBIOS!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

:: Verificar si hay cambios guardados
set "mvbs_hasvalues=0"
for /f "skip=2" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" 2^>nul') do set "mvbs_hasvalues=1"
if "!mvbs_hasvalues!"=="0" (
    echo  !cYellow!No hay cambios previos registrados.!cReset!
    echo  !cYellow!Ejecuta primero la opcion [3] Desactivar Todas las Caracteristicas.!cReset!
    echo.
    pause
    exit /b
)

echo  !cYellow!Restaurando solo las caracteristicas que fueron desactivadas por este script...!cReset!
echo.
set "haderror=0"

:: Revertir VBS
set "revert_vbs="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v VBS 2^>nul') do set "revert_vbs=%%A"
if "!revert_vbs!"=="0x1" (
    set /p "=  Restaurando VBS...                      " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v VBS /f >nul 2>&1)
)

:: Revertir HVCI
set "revert_hvci="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v HVCI 2^>nul') do set "revert_hvci=%%A"
if "!revert_hvci!"=="0x1" (
    set /p "=  Restaurando HVCI...                     " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v HVCI /f >nul 2>&1)
)

:: Revertir Windows Hello
set "revert_wh="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v WindowsHello 2^>nul') do set "revert_wh=%%A"
if "!revert_wh!"=="0x1" (
    set /p "=  Restaurando Windows Hello...            " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v WindowsHello /f >nul 2>&1)
)

:: Revertir System Guard
set "revert_sg="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v SystemGuard 2^>nul') do set "revert_sg=%%A"
if "!revert_sg!"=="0x1" (
    set /p "=  Restaurando System Guard...             " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v SystemGuard /f >nul 2>&1)
)

:: Revertir Credential Guard
set "revert_cg="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard 2^>nul') do set "revert_cg=%%A"
if "!revert_cg!"=="0x1" (
    set /p "=  Restaurando Credential Guard...         " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard /f >nul 2>&1)
)

:: Revertir KVA Shadow
set "revert_kva="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v KVAShadow 2^>nul') do set "revert_kva=%%A"
if "!revert_kva!"=="0x1" (
    set /p "=  Restaurando KVA Shadow...               " <nul
    reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /f >nul 2>&1
    reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /f >nul 2>&1
    echo !cGreen![OK]!cReset!
    reg delete "HKLM\SOFTWARE\ManageVBS" /v KVAShadow /f >nul 2>&1
)

:: [NUEVO] Revertir Hypervisor con restauracion fiel del valor original
set "revert_hyp="
set "revert_hyptype="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v Hypervisor 2^>nul') do set "revert_hyp=%%A"
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType 2^>nul') do set "revert_hyptype=%%B"
if "!revert_hyp!"=="0x1" (
    set /p "=  Restaurando Hypervisor...               " <nul
    if "!revert_hyptype!"=="" (
        bcdedit /deletevalue {current} hypervisorlaunchtype >nul 2>&1
    ) else (
        bcdedit /set hypervisorlaunchtype !revert_hyptype! >nul 2>&1
    )
    if errorlevel 1 (
        echo !cRed![FAIL]!cReset!
        set "haderror=1"
    ) else (
        echo !cGreen![OK]!cReset!
        reg delete "HKLM\SOFTWARE\ManageVBS" /v Hypervisor /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType /f >nul 2>&1
    )
)

:: Limpiar clave ManageVBS si no quedan entradas pendientes
set "mvbs_remaining=0"
for /f "skip=2" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" 2^>nul') do set "mvbs_remaining=1"
if "!mvbs_remaining!"=="0" reg delete "HKLM\SOFTWARE\ManageVBS" /f >nul 2>&1

echo.
if "!haderror!"=="1" (
    echo  !cRed!Algunos cambios no pudieron revertirse. Intenta ejecutar el script nuevamente.!cReset!
) else (
    echo  !cGreen!Todos los cambios fueron revertidos exitosamente.!cReset!
)
echo.
echo  !cYellow!NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios.!cReset!
echo.
choice /C:SN /N /M "  ^¿Deseas reiniciar el equipo ahora? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Reinicio cancelado. Recuerda reiniciar mas tarde.!cReset!
    echo.
    pause
    exit /b
)
:: [NUEVO] Verificar BitLocker antes de reiniciar
call :check_bitlocker 1
if "!bl_ok!"=="0" (
    echo.
    echo  !cYellow!Reinicio cancelado. Resuelve BitLocker y reinicia manualmente.!cReset!
    echo.
    pause
    exit /b
)
echo.
echo  !cCyan!Reiniciando...!cReset!
shutdown /r /t 0
exit /b

:: ========================================
:: ACTIVAR FEATURES INDIVIDUALES
:: ========================================

:enable_vbs
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_hvci
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_winhello
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_sysguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_credguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_kva
reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /f >nul 2>&1
echo !cGreen![OK]!cReset!
exit /b

:enable_hypervisor
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:: ========================================
:: DESACTIVAR FEATURES INDIVIDUALES
:: ========================================

:disable_vbs
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_hvci
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_winhello
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_sysguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_credguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_kva
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_hypervisor
bcdedit /set hypervisorlaunchtype off >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b