@echo off
setlocal EnableDelayedExpansion

:: ========================================
:: WINDOWS SECURITY FEATURES MANAGER v3.0
:: ========================================
:: Script para gestionar caracteristicas de seguridad de Windows
:: Permite ver estado y activar/desactivar:
:: - VBS (Virtualization-based Security)
:: - HVCI (Memory Integrity)
:: - Windows Hello Protection
:: - Enhanced Sign-in Security (SecureBiometrics)
:: - System Guard Secure Launch
:: - Credential Guard + Credential Guard Scenario
:: - KVA Shadow (Meltdown Mitigation)
:: - Windows Hypervisor
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

: ========================================
:: REDIRECCION SYSNATIVE
:: Evita problemas de redireccion de registro
:: en entornos WOW64 (procesos 32-bit en Windows 64-bit)
:: ========================================

set "re1="
set "_cmdf=%~f0"
for %%# in (%*) do (
    if /i "%%#"=="re1" set "re1=1"
)
if exist %SystemRoot%\Sysnative\cmd.exe if not defined re1 (
    setlocal EnableDelayedExpansion
    start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* re1"
    exit /b
)

:: ========================================
:: VARIABLES DE SISTEMA
:: ========================================

set "SysPath=%SystemRoot%\System32"
set "ps=%SysPath%\WindowsPowerShell\v1.0\powershell.exe"
set "psc=%ps% -nop -c"

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
set "cOrange=%ESC%[33m"
set "cReset=%ESC%[0m"

:: Verificar soporte de colores ANSI
set "_NCS=1"
for /f "tokens=3" %%A in ('reg query "HKCU\Console" /v VirtualTerminalLevel 2^>nul') do if "%%A"=="0x0" set "_NCS=0"
if "!_NCS!"=="0" (
    set "cGreen=" & set "cRed=" & set "cYellow=" & set "cCyan=" & set "cMagenta=" & set "cWhite=" & set "cOrange=" & set "cReset="
)

:: ========================================
:: VERSION DE WINDOWS
:: ========================================

set "winbuild=1"
for /f "tokens=2 delims=[]" %%G in ('ver') do (
    for /f "tokens=2,3,4 delims=. " %%H in ("%%~G") do set "winbuild=%%J"
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
powershell -nop -c "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=55;$W.Width=100;$B.Height=300;$B.Width=100;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}" >nul 2>&1
echo  !cMagenta!===============================================================!cReset!
echo  !cMagenta!   WINDOWS SECURITY FEATURES MANAGER  v3.0!cReset!
echo  !cMagenta!   Gestor de Caracteristicas de Seguridad de Windows!cReset!
echo  !cMagenta!===============================================================!cReset!
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
call :show_notes
echo.
set /p "=  Selecciona una opcion: " <nul
exit /b

:: ========================================
:: NOTAS INFORMATIVAS
:: ========================================

:show_notes
echo                !cYellow!ANTES DE CONTINUAR - LEE ESTO:!cReset!
echo  ----------------------------------------------------------------
echo.
echo  !cWhite! 1.!cReset! La virtualizacion de CPU debe estar habilitada en la BIOS.
echo     Algunas placas base la tienen activada por defecto.
echo.
echo  !cWhite! 2.!cReset! Ejecuta HyperVision y selecciona [3].
echo     Luego reinicia el equipo cuando se te indique.
echo.
echo  !cWhite! 3.!cReset! En el siguiente arranque presiona !cYellow!F7!cReset! cuando aparezca
echo     el menu de inicio avanzado para deshabilitar la firma de drivers.
echo     Esto permite cargar controladores no verificados en el sistema. 
echo     !cRed!(puede implicar riesgos de seguridad)!cReset!
echo.
echo  !cWhite! 4.!cReset! Ejecuta la aplicacion desde el acceso directo del escritorio.
echo     Mientras no reinicies el PC, otras aplicaciones compatibles tambien
echo     podran ejecutarse sin repetir todo el proceso.
echo.
echo  !cWhite! 5.!cReset! Si reinicias o apagas el equipo, deberas repetir:
echo     HyperVision -> reiniciar -> F7 -> ejecutar desde el acceso directo.
echo.
echo  !cWhite! 6.!cReset! Para revertir los cambios basta con ejecutar la opcion [4] Revertir Cambios.
echo     Las configuraciones modificadas volveran a su estado normal.
echo.
echo  !cWhite! 7.!cReset! !cYellow!REQUISITO - INTERNET:!cReset!
echo     !cRed! Desconectarse de internet durante el uso.!cReset!
echo     !cRed! Esto reduce posibles conexiones externas mientras las protecciones!cReset!
echo     !cRed! del sistema estan deshabilitadas.!cReset!
echo  ----------------------------------------------------------------
exit /b

:: ========================================
:: VERIFICACION DE VIRTUALIZACION EN BIOS
:: Detecta si VT-x o SVM estan habilitados.
:: Si no lo estan, VBS no puede funcionar
:: aunque se escriba en el registro.
:: ========================================

:check_vtx
set "vtx=0"
set "hvpresent=0"
for /f "delims=" %%s in ('powershell -nop -c "(gcim Win32_ComputerSystem).HypervisorPresent" 2^>nul') do (
    if /i "%%s"=="True" set "hvpresent=1"
)
for /f "delims=" %%s in ('powershell -nop -c "(Get-CimInstance -ClassName Win32_Processor).VirtualizationFirmwareEnabled" 2^>nul') do (
    if /i "%%s"=="True" set "vtx=1"
)
if "!hvpresent!"=="1" set "vtx=1"
exit /b

:: ========================================
:: VERIFICACION DSE
:: 0 = DSE desactivado  1 = Test Signing  2 = DSE activo
:: ========================================

:check_dse
set "dse="
for /f "delims=" %%A in ('%psc% "$t=Add-Type -PassThru -MemberDefinition '[DllImport(""ntdll.dll"")] public static extern uint NtQuerySystemInformation(int c,IntPtr b,uint s,out uint r);' -Name CI2 -Namespace w2; $p=[Runtime.InteropServices.Marshal]::AllocHGlobal(8); [Runtime.InteropServices.Marshal]::WriteInt32($p,8); $r=[uint32]0; $t::NtQuerySystemInformation(103,$p,8,[ref]$r)|Out-Null; $o=[uint32][Runtime.InteropServices.Marshal]::ReadInt32($p,4); if(-not($o -band 1)){0}elseif($o -band 2){1}else{2}" 2^>nul') do set "dse=%%A"
exit /b

:: ========================================
:: VERIFICACION DE UEFI LOCK
:: Si VBS o HVCI estan bloqueadas por UEFI,
:: los cambios en el registro no tendran
:: efecto. Se debe informar y omitir esa
:: caracteristica para evitar confusion.
:: ========================================

:check_uefi_locks
set "vbslocked="
set "hvcilocked="
set "cglocked="
set "mandatorylocked="
set "anylocked="
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked 2^>nul') do if "%%A"=="0x1" set "vbslocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked 2^>nul') do if "%%A"=="0x1" set "hvcilocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags 2^>nul') do if "%%A"=="0x1" set "cglocked=1"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Mandatory 2^>nul') do if "%%A"=="0x1" set "mandatorylocked=1"
if defined vbslocked set "anylocked=1"
if defined hvcilocked set "anylocked=1"
if defined cglocked set "anylocked=1"
exit /b

:: ========================================
:: DESBLOQUEO UEFI CON SECCONFIG.EFI
:: Parametro 1: loadoptions para bcdedit
:: ========================================

:setup_secconfig
set "secfailed="
set "secloadopts=%~1"

if not exist "%SystemRoot%\System32\SecConfig.efi" (
    echo  !cRed!SecConfig.efi no encontrado. No se puede desbloquear via UEFI.!cReset!
    set "secfailed=1"
    exit /b
)

set "freedrive="
for %%D in (S T U V W X Y Z) do (
    if not defined freedrive (
        if not exist %%D:\ set "freedrive=%%D:"
    )
)
if not defined freedrive (
    echo  !cRed!No hay letra de unidad libre ^(S-Z^) para montar la particion EFI.!cReset!
    echo  !cYellow!Desmonta alguna unidad con letra entre S y Z e intenta de nuevo.!cReset!
    set "secfailed=1"
    exit /b
)

mountvol !freedrive! /s >nul 2>&1 || set "secfailed=1"
copy "%SystemRoot%\System32\SecConfig.efi" "!freedrive!\EFI\Microsoft\Boot\SecConfig.efi" >nul 2>&1 || set "secfailed=1"

if not defined secfailed (
    bcdedit /delete {0cb3b571-2f2e-4343-a879-d86a476d7215} >nul 2>&1
    bcdedit /create {0cb3b571-2f2e-4343-a879-d86a476d7215} /d "DGOptOut" /application osloader >nul 2>&1 || set "secfailed=1"
    bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} path "\EFI\Microsoft\Boot\SecConfig.efi" >nul 2>&1 || set "secfailed=1"
    bcdedit /set {bootmgr} bootsequence {0cb3b571-2f2e-4343-a879-d86a476d7215} {current} >nul 2>&1 || set "secfailed=1"
    bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} loadoptions !secloadopts! >nul 2>&1 || set "secfailed=1"
    bcdedit /set {0cb3b571-2f2e-4343-a879-d86a476d7215} device partition=!freedrive! >nul 2>&1 || set "secfailed=1"
)

mountvol !freedrive! /d >nul 2>&1

if not defined secfailed (
    echo  !cGreen!UEFI lock sera eliminado en el proximo arranque via SecConfig.efi.!cReset!
    echo  !cYellow!Confirma el opt-out cuando aparezca el aviso durante el arranque.!cReset!
) else (
    echo  !cRed!No se pudo configurar SecConfig.efi. El UEFI lock no pudo eliminarse.!cReset!
)
exit /b

:: ========================================
:: VERIFICACION DE BITLOCKER
:: Si BitLocker esta activo y se entra al
:: menu de arranque avanzado sin suspenderlo,
:: Windows puede pedir la clave de
:: recuperacion al reiniciar.
:: ========================================

:check_bitlocker
set "blprotected=0"
for /f "delims=" %%s in ('powershell -nop -c "(Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus" 2^>nul') do (
    if "%%s"=="On" set "blprotected=1"
)
exit /b

:check_faceit
set "faceit_detected=0"
if exist "C:\Program Files\FACEIT AC\" set "faceit_detected=1"
exit /b

:suspend_bitlocker
call :check_bitlocker
if "!blprotected!"=="1" (
    echo.
    echo  !cOrange!BitLocker detectado. Suspendiendo proteccion por 2 reinicios...!cReset!
    manage-bde -protectors -disable %SystemDrive% -rebootcount 2 >nul 2>&1
    if errorlevel 1 (
        echo  !cRed!No se pudo suspender BitLocker. Abortando reinicio.!cReset!
        echo  !cYellow!Ejecuta la opcion [4] Revertir Cambios para restaurar el estado anterior.!cReset!
        echo.
        pause
        exit /b 1
    ) else (
        echo  !cGreen!BitLocker suspendido exitosamente. El cifrado sigue activo.!cReset!
    )
)
exit /b 0

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
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "hvci_status=1"
)
exit /b

:get_winhello_status
set "winhello_status=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "winhello_status=1"
)
exit /b

:get_secbio_status
set "secbio_status=0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "secbio_status=1"
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
set "cgrunning=0"
set "cgscenario=0"
for /f "delims=" %%s in ('%psc% "(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning" 2^>nul') do (
    if "%%s"=="1" set "cgrunning=1"
)
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled 2^>nul') do (
    if "%%A"=="0x1" set "cgscenario=1"
)
if "!cgrunning!"=="1" set "credguard_status=1"
if "!cgscenario!"=="1" set "credguard_status=1"
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
set "hyp_launchtype="
set "hypvbs="
set "hyphyp="
for /f "tokens=2" %%A in ('bcdedit /enum {current} 2^>nul ^| findstr /i "hypervisorlaunchtype"') do (
    set "hyp_launchtype=%%A"
    if /i "%%A"=="Auto" set "hyp_status=1"
    if /i "%%A"=="On"   set "hyp_status=1"
)
if not defined hyp_launchtype (
    for /f "delims=" %%s in ('%psc% "(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).VirtualizationBasedSecurityStatus" 2^>nul') do (
        if "%%s"=="1" set "hypvbs=1"
        if "%%s"=="2" set "hypvbs=1"
    )
    for /f "delims=" %%s in ('%psc% "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent" 2^>nul') do (
        if /i "%%s"=="True" set "hyphyp=1"
    )
    if defined hypvbs if defined hyphyp set "hyp_status=1"
)
exit /b

:: ========================================
:: MOSTRAR ESTADO
:: ========================================

:show_status
call :show_title
echo  !cCyan!ESTADO DE CARACTERISTICAS DE SEGURIDAD!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

:: Verificar FACEIT Anti-Cheat
call :check_faceit
if "!faceit_detected!"=="1" (
    echo  !cRed![ADVERTENCIA] FACEIT Anti-Cheat detectado.!cReset!
    echo  !cYellow!  Se conoce que bloquea la carga de drivers.!cReset!
    echo.
)

:: Verificar VT-x primero
call :check_vtx
if "!vtx!"=="0" (
    echo  !cRed![ADVERTENCIA] Virtualizacion ^(VT-x/SVM^) NO esta habilitada en BIOS.!cReset!
    echo  !cYellow!  VBS no puede funcionar sin habilitarla en BIOS/UEFI primero.!cReset!
    echo.
) else (
    echo  !cGreen!  Virtualizacion ^(VT-x/SVM^): Habilitada en BIOS!cReset!
    echo.
)

:: Verificar UEFI locks
call :check_uefi_locks
if defined vbslocked    echo  !cOrange!  [UEFI LOCK] VBS esta bloqueada por firmware. No puede modificarse por registro.!cReset!
if defined hvcilocked   echo  !cOrange!  [UEFI LOCK] HVCI esta bloqueada por firmware. No puede modificarse por registro.!cReset!
if defined cglocked     echo  !cOrange!  [UEFI LOCK] Credential Guard esta bloqueada por firmware.!cReset!
if defined mandatorylocked echo  !cOrange!  [UEFI LOCK] VBS/HVCI en modo obligatorio. No pueden desactivarse.!cReset!
if defined vbslocked echo.
if defined hvcilocked echo.
if defined cglocked echo.
if defined mandatorylocked echo.

:: Verificar BitLocker
call :check_bitlocker
if "!blprotected!"=="1" (
    echo  !cOrange!  BitLocker: ACTIVO en unidad del sistema!cReset!
    echo  !cYellow!  Se suspendera automaticamente al reiniciar en modo avanzado.!cReset!
    echo.
) else (
    echo  !cGreen!  BitLocker: No detectado!cReset!
    echo.
)

:: Verificar FACEIT Anti-Cheat
call :check_faceit
if "!faceit_detected!"=="1" (
    echo  !cRed!  FACEIT Anti-Cheat: DETECTADO!cReset!
    echo  !cYellow!  Advertencia: Bloquea la carga de drivers.!cReset!
    echo.
) else (
    echo  !cGreen!  FACEIT Anti-Cheat: No detectado!cReset!
    echo.
)

echo  !cCyan!----------------------------------------------------------!cReset!
echo.

call :get_vbs_status
call :print_status "VBS (Virtualization-based Security)" !vbs_status!

call :get_hvci_status
call :print_status "HVCI (Memory Integrity)" !hvci_status!

call :get_winhello_status
call :print_status "Windows Hello Protection" !winhello_status!

call :get_secbio_status
call :print_status "Enhanced Sign-in Security (SecureBiometrics)" !secbio_status!1

call :get_sysguard_status
call :print_status "System Guard Secure Launch" !sysguard_status!

call :get_credguard_status
call :print_status "Credential Guard" !credguard_status!

call :get_kva_status
call :print_status "KVA Shadow (Meltdown Mitigation)" !kva_status!

call :get_hypervisor_status
call :print_status "Windows Hypervisor" !hyp_status!

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

:: Verificar FACEIT Anti-Cheat
call :check_faceit
if "!faceit_detected!"=="1" (
    echo  !cRed![ADVERTENCIA] FACEIT Anti-Cheat detectado.!cReset!
    echo  !cRed!Se conoce que bloquea la carga de drivers.!cReset!
    echo  !cYellow!Desinstala FACEIT AC antes de continuar.!cReset!
    echo.
    pause
    exit /b
)

:: Advertir si VT-x no esta habilitado en BIOS
call :check_vtx
if "!vtx!"=="0" (
    echo  !cRed![ADVERTENCIA] Virtualizacion ^(VT-x/SVM^) NO esta habilitada en BIOS.!cReset!
    echo  !cYellow!  Activar VBS desde el registro no tendra efecto hasta habilitarla en BIOS/UEFI.!cReset!
    echo.
    choice /C:SN /N /M "  ^¿Deseas continuar de todas formas? (S/N): "
    if errorlevel 2 (
        echo.
        echo  !cYellow!Operacion cancelada.!cReset!
        echo.
        pause
        exit /b
    )
    echo.
)

set /p "=  Activando VBS...                        " <nul
call :enable_vbs

set /p "=  Activando HVCI...                       " <nul
call :enable_hvci

set /p "=  Activando Windows Hello...              " <nul
call :enable_winhello

set /p "=  Activando Enhanced Sign-in Security...  " <nul
call :enable_secbio

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
echo.
echo  !cCyan!Reiniciando...!cReset!
shutdown /r /t 0
exit /b0: FACEIT Anti-Cheat ---
call :check_faceit
if "!faceit_detected!"=="1" (
    echo  !cRed![ADVERTENCIA] FACEIT Anti-Cheat detectado.!cReset!
    echo  !cRed!Se conoce que bloquea la carga de drivers.!cReset!
    echo  !cYellow!Desinstala FACEIT AC antes de continuar.!cReset!
    echo.
    pause
    exit /b
)

:: --- Verificacion 

:: ========================================
:: DESACTIVAR TODAS LAS CARACTERISTICAS
:: ========================================

:disable_all
call :show_title
echo  !cYellow!DESACTIVANDO TODAS LAS CARACTERISTICAS...!cReset!
echo.

:: --- Verificacion 1: VT-x en BIOS ---
call :check_vtx
if "!vtx!"=="0" (
    echo  !cOrange![INFO] Virtualizacion ^(VT-x/SVM^) no detectada en BIOS.!cReset!
    echo  !cYellow!  Es posible que VBS ya no este activo.!cReset!
    echo.
)

:: Verificacion DSE
call :check_dse

:: Verificacion UEFI Locks
call :check_uefi_locks

:: Advertencia y consentimiento si hay UEFI locks
if defined anylocked (
    set "uefiagreed="
    reg query "HKLM\SOFTWARE\ManageVBS" /v UEFILockAgreed >nul 2>&1
    if "!errorlevel!"=="0" set "uefiagreed=1"
    if not defined uefiagreed (
        echo  !cRed!Una o mas caracteristicas estan protegidas por UEFI lock.!cReset!
        echo  !cYellow!  Solo procede en dispositivos personales.!cReset!
        echo  !cYellow!  No continuar en equipos de trabajo, escuela o gestionados.!cReset!
        echo.
        choice /C:SN /N /M "  ^¿Deseas continuar? (S/N): "
        if errorlevel 2 (
            echo.
            echo  !cYellow!Operacion cancelada.!cReset!
            echo.
            pause
            exit /b
        )
        reg add "HKLM\SOFTWARE\ManageVBS" /v UEFILockAgreed /t REG_DWORD /d 1 /f >nul 2>&1
        echo.
    )
)

:: Modo obligatorio
if defined mandatorylocked (
    echo  !cYellow!VBS/HVCI en modo obligatorio. Intentando desactivar...!cReset!
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Mandatory /t REG_DWORD /d 0 /f >nul 2>&1
    if errorlevel 1 (
        echo  !cRed!No se pudo desactivar el modo obligatorio. Abortando.!cReset!
        echo.
        pause
        exit /b
    )
    echo  !cGreen!Modo obligatorio desactivado.!cReset!
    echo.
)

:: --- Confirmacion ---
choice /C:SN /N /M "  ^!Estas seguro? Esto desactivara TODAS las protecciones de seguridad. (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Operacion cancelada!cReset!
    echo.
    pause
    exit /b
)
echo.

set "anythingdisabled="
set "haderror=0"

:: --- Desbloqueo UEFI via SecConfig.efi ---

if defined vbslocked (
    echo  !cYellow!VBS tiene UEFI lock. Intentando desbloquear via SecConfig.efi...!cReset!
    reg add "HKLM\SOFTWARE\ManageVBS" /v VBSLocked /t REG_DWORD /d 1 /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
    call :setup_secconfig "DISABLE-LSA-ISO,DISABLE-VBS"
    if defined secfailed (
        reg delete "HKLM\SOFTWARE\ManageVBS" /v VBSLocked /f >nul 2>&1
        echo  !cRed!VBS UEFI lock no pudo eliminarse. Abortando.!cReset!
        echo.
        pause
        exit /b
    )
    echo.
)

if defined hvcilocked (
    echo  !cYellow!HVCI tiene UEFI lock. Intentando desbloquear via SecConfig.efi...!cReset!
    reg add "HKLM\SOFTWARE\ManageVBS" /v HVCILocked /t REG_DWORD /d 1 /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /f >nul 2>&1
    call :setup_secconfig "DISABLE-LSA-ISO,DISABLE-VBS"
    if defined secfailed (
        reg delete "HKLM\SOFTWARE\ManageVBS" /v HVCILocked /f >nul 2>&1
        echo  !cRed!HVCI UEFI lock no pudo eliminarse. Abortando.!cReset!
        echo.
        pause
        exit /b
    )
    echo.
)

if defined cglocked (
    echo  !cYellow!Credential Guard tiene UEFI lock. Intentando desbloquear via SecConfig.efi...!cReset!
    reg add "HKLM\SOFTWARE\ManageVBS" /v CGLocked /t REG_DWORD /d 1 /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    call :setup_secconfig "DISABLE-LSA-ISO"
    if defined secfailed (
        reg delete "HKLM\SOFTWARE\ManageVBS" /v CGLocked /f >nul 2>&1
        echo  !cRed!Credential Guard UEFI lock no pudo eliminarse. Abortando.!cReset!
        echo.
        pause
        exit /b
    )
    echo.
)
:: --- Guardar estado previo para poder revertir ---
:: Se guarda el HypervisorLaunchType exacto (no se asume "auto")
call :get_vbs_status
if "!vbs_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v VBS /t REG_DWORD /d 1 /f >nul 2>&1

call :get_hvci_status
if "!hvci_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v HVCI /t REG_DWORD /d 1 /f >nul 2>&1

call :get_winhello_status
if "!winhello_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v WindowsHello /t REG_DWORD /d 1 /f >nul 2>&1

call :get_secbio_status
if "!secbio_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS" /v SecureBiometrics /t REG_DWORD /d 1 /f >nul 2>&1
    for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios" /v SecureBiometrics 2^>nul') do (
        if "%%A"=="0x1" reg add "HKLM\SOFTWARE\ManageVBS" /v SecureBiometricsScenario /t REG_DWORD /d 1 /f >nul 2>&1
    )
)
call :get_sysguard_status
if "!sysguard_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v SystemGuard /t REG_DWORD /d 1 /f >nul 2>&1

call :get_credguard_status
if "!credguard_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard /t REG_DWORD /d 1 /f >nul 2>&1

call :get_kva_status
if "!kva_status!"=="1" reg add "HKLM\SOFTWARE\ManageVBS" /v KVAShadow /t REG_DWORD /d 1 /f >nul 2>&1

:: Guardar el valor exacto de HypervisorLaunchType antes de desactivar
call :get_hypervisor_status
if "!hyp_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS" /v Hypervisor /t REG_DWORD /d 1 /f >nul 2>&1
    if not "!hyp_launchtype!"=="" (
        reg add "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType /t REG_SZ /d "!hyp_launchtype!" /f >nul 2>&1
    )
)

:: --- Desactivar caracteristicas (respetando UEFI locks) ---

if not defined vbslocked (
    set /p "=  Desactivando VBS...                     " <nul
    call :disable_vbs
) else (
    echo  !cOrange!  Omitiendo VBS ^(UEFI Lock^)...              [SKIP]!cReset!
)

if not defined hvcilocked (
    set /p "=  Desactivando HVCI...                    " <nul
    call :disable_hvci
) else (
    echo  !cOrange!  Omitiendo HVCI ^(UEFI Lock^)...             [SKIP]!cReset!
)

set /p "=  Desactivando Windows Hello...           " <nul
call :disable_winhello

set /p "=  Desactivando Enhanced Sign-in Security. " <nul
call :disable_secbio
if not errorlevel 1 set "anythingdisabled=1"

set /p "=  Desactivando System Guard...            " <nul
call :disable_sysguard

if not defined cglocked (
    set /p "=  Desactivando Credential Guard...        " <nul
    call :disable_credguard
) else (
    echo  !cOrange!  Omitiendo Credential Guard ^(UEFI Lock^)... [SKIP]!cReset!
)

set /p "=  Desactivando KVA Shadow...              " <nul
call :disable_kva

set /p "=  Desactivando Hypervisor...              " <nul
call :disable_hypervisor

echo.
echo  !cYellow!NOTA: El sistema reiniciara en el menu de opciones avanzadas.!cReset!
echo  !cCyan!  Desde ahi selecciona la opcion 7: Deshabilitar firma obligatoria de controladores.!cReset!
echo.
choice /C:SN /N /M "  ^¿Deseas reiniciar ahora en modo avanzado (F7)? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Reinicio cancelado. Recuerda reiniciar mas tarde.!cReset!
    echo.
    pause
    exit /b
)

:: --- Suspender BitLocker antes de reiniciar en modo avanzado ---
call :suspend_bitlocker
if errorlevel 1 exit /b

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

:: ========================================
:: REVERTIR CAMBIOS
:: ========================================

:revert_changes
call :show_title
echo  !cCyan!REVERTIR CAMBIOS!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

call :check_dse

set "mvbs_hasvalues=0"
for /f %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" 2^>nul ^| findstr /i "REG_" ^| findstr /vi "UEFILockAgreed"') do set "mvbs_hasvalues=1"
if "!mvbs_hasvalues!"=="0" if not "!dse!"=="0" (
    echo  !cYellow!No hay cambios previos registrados para revertir.!cReset!
    echo.
    pause
    exit /b
)

echo  !cYellow!Restaurando solo las caracteristicas que fueron desactivadas por este script...!cReset!
echo.
set "haderror=0"

:: Revertir UEFI Locks
set "revert_vbslocked="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v VBSLocked 2^>nul') do set "revert_vbslocked=%%A"
if "!revert_vbslocked!"=="0x1" (
    set /p "=  Restaurando VBS UEFI Lock...            " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v VBSLocked /f >nul 2>&1)
)

set "revert_hvcilocked="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v HVCILocked 2^>nul') do set "revert_hvcilocked=%%A"
if "!revert_hvcilocked!"=="0x1" (
    set /p "=  Restaurando HVCI UEFI Lock...           " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v HVCILocked /f >nul 2>&1)
)

set "revert_cglocked="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v CGLocked 2^>nul') do set "revert_cglocked=%%A"
if "!revert_cglocked!"=="0x1" (
    set /p "=  Restaurando Credential Guard UEFI Lock. " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v CGLocked /f >nul 2>&1)
)

:: Revertir Hypervisor al valor exacto previo
set "revert_hyp="
set "revert_hyptype="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v Hypervisor 2^>nul') do set "revert_hyp=%%A"
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType 2^>nul') do set "revert_hyptype=%%B"
if "!revert_hyp!"=="0x1" (
    set /p "=  Restaurando Hypervisor...               " <nul
    if "!revert_hyptype!"=="" (
        bcdedit /deletevalue {current} hypervisorlaunchtype >nul 2>&1
        cmd /c exit 0
    ) else (
        bcdedit /set hypervisorlaunchtype !revert_hyptype! >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (
        echo !cGreen![OK]!cReset!
        reg delete "HKLM\SOFTWARE\ManageVBS" /v Hypervisor /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\ManageVBS" /v HypervisorLaunchType /f >nul 2>&1
    )
)

:: Revertir VBS con RequirePlatformSecurityFeatures
set "revert_vbs="
set "revert_rpsf="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v VBS 2^>nul') do set "revert_vbs=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v RequirePlatformSecurityFeatures 2^>nul') do set "revert_rpsf=%%A"
if "!revert_vbs!"=="0x1" (
    set /p "=  Restaurando VBS...                      " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
    if defined revert_rpsf reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d !revert_rpsf! /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (
        echo !cGreen![OK]!cReset!
        reg delete "HKLM\SOFTWARE\ManageVBS" /v VBS /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\ManageVBS" /v RequirePlatformSecurityFeatures /f >nul 2>&1
    )
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

:: Revertir Enhanced Sign-in Security
set "revert_sb="
set "revert_sbscenario="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v SecureBiometrics 2^>nul') do set "revert_sb=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v SecureBiometricsScenario 2^>nul') do set "revert_sbscenario=%%A"
if "!revert_sb!"=="0x1" (
    set /p "=  Restaurando Enhanced Sign-in Security.. " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v SecureBiometrics /f >nul 2>&1)
)
if "!revert_sbscenario!"=="0x1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios" /v SecureBiometrics /t REG_DWORD /d 1 /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\ManageVBS" /v SecureBiometricsScenario /f >nul 2>&1
)

:: Revertir System Guard
set "revert_sg="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v SystemGuard 2^>nul') do set "revert_sg=%%A"
if "!revert_sg!"=="0x1" (
    set /p "=  Restaurando System Guard...             " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v SystemGuard /f >nul 2>&1)
)

:: Revertir Credential Guard LSA + Scenario
set "revert_cg="
set "revert_cgscenario="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard 2^>nul') do set "revert_cg=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" /v CredentialGuardScenario 2^>nul') do set "revert_cgscenario=%%A"
if "!revert_cg!"=="0x1" (
    set /p "=  Restaurando Credential Guard...         " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
    reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags >nul 2>&1
    if "!errorlevel!"=="0" reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v CredentialGuard /f >nul 2>&1)
)
if "!revert_cgscenario!"=="0x1" (
    set /p "=  Restaurando Credential Guard Scenario.. " <nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset! & reg delete "HKLM\SOFTWARE\ManageVBS" /v CredentialGuardScenario /f >nul 2>&1)
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

:: Limpiar ManageVBS si no quedan entradas (excepto UEFILockAgreed)
set "mvbs_remaining=0"
for /f %%A in ('reg query "HKLM\SOFTWARE\ManageVBS" 2^>nul ^| findstr /i "REG_" ^| findstr /vi "UEFILockAgreed"') do set "mvbs_remaining=1"
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

:enable_secbio
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_sysguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:enable_credguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
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

:disable_secbio
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios" /v SecureBiometrics /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_sysguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (echo !cRed![FAIL]!cReset!) else (echo !cGreen![OK]!cReset!)
exit /b

:disable_credguard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
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