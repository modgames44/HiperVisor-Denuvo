@echo off
setlocal EnableDelayedExpansion

:: ========================================
:: WINDOWS SECURITY FEATURES MANAGER v3.3
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
:: NUEVO: Sistema de respaldo de configuracion original
:: NUEVO: Deteccion de Smart App Control
:: NUEVO: Advertencia de Windows Hello
:: NUEVO: BitLocker inteligente (1 o 2 reinicios)
:: NUEVO: Deteccion multiple de Anti-Cheats (FACEIT, EAC, BattlEye, Vanguard)
:: NUEVO: Informacion detallada del Sistema Operativo
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
:: REDIRECCION SYSNATIVE
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
set "cRedHL=%ESC%[41;97m"
set "cBlueHL=%ESC%[44;97m"
set "cGreyHL=%ESC%[100;97m"
set "cReset=%ESC%[0m"

:: Verificar soporte de colores ANSI
set "_NCS=1"
for /f "tokens=3" %%A in ('reg query "HKCU\Console" /v VirtualTerminalLevel 2^>nul') do if "%%A"=="0x0" set "_NCS=0"
if "!_NCS!"=="0" (
    set "cGreen=" & set "cRed=" & set "cYellow=" & set "cCyan=" & set "cMagenta=" & set "cWhite=" & set "cOrange=" & set "cRedHL=" & set "cBlueHL=" & set "cGreyHL=" & set "cReset="
)

:: ========================================
:: INFORMACION DETALLADA DEL SISTEMA (NUEVO)
:: ========================================

call :dk_sysinfo

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
choice /C:1234560 /N /M ""
set "opt=!errorlevel!"
if "!opt!"=="1" call :show_status
if "!opt!"=="2" call :disable_all
if "!opt!"=="3" call :revert_changes
if "!opt!"=="4" call :backup_config
if "!opt!"=="5" call :enable_all
if "!opt!"=="6" call :customize_features
if "!opt!"=="7" (
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
echo  !cMagenta!   WINDOWS SECURITY FEATURES MANAGER  v3.2!cReset!
echo  !cMagenta!   Gestor de Caracteristicas de Seguridad de Windows!cReset!
echo  !cMagenta!===============================================================!cReset!
echo.
exit /b

:show_menu
call :show_title
echo  !cCyan!MENU PRINCIPAL!cReset!
echo  ----------------------------------
echo  [1] Ver Estado
echo  [2] Desactivar Todo (para juegos/software)
echo  [3] Revertir Cambios
echo  [4] Guardar Backup (opcional)
echo  [5] Activar Todo (maxima seguridad)
echo  [6] Personalizar Caracteristicas (avanzado)
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
echo  !cRedHL! 2.!cReset! !cRedHL!Desactiva Windows Hello (PIN, huella o reconocimiento facial)!cReset!
echo     !cRedHL!antes de continuar. Si no lo haces, tendras que configurarlo de nuevo.!cReset!
echo.
echo  !cWhite! 3.!cReset! Selecciona [2] Desactivar Todo para jugar/usar software.
echo     Luego reinicia el equipo cuando se te indique.
echo.
echo  !cWhite! 4.!cReset! En el siguiente arranque presiona !cYellow!F7!cReset! cuando aparezca
echo     el menu de inicio avanzado para deshabilitar la firma de drivers.
echo     Esto permite cargar controladores no verificados en el sistema. 
echo     !cRed!(puede implicar riesgos de seguridad)!cReset!
echo.
echo  !cWhite! 5.!cReset! Ejecuta la aplicacion desde el acceso directo del escritorio.
echo     Mientras no reinicies el PC, otras aplicaciones compatibles tambien
echo     podran ejecutarse sin repetir todo el proceso.
echo.
echo  !cWhite! 6.!cReset! Si reinicias o apagas el equipo, deberas repetir:
echo     script -> [2] Desactivar -> reiniciar -> F7 -> ejecutar.
echo.
echo  !cWhite! 7.!cReset! Para volver a tu configuracion normal, usa [3] Revertir Cambios.
echo     Las configuraciones modificadas volveran a su estado anterior.
echo.
echo  !cWhite! 8.!cReset! !cYellow!REQUISITO - INTERNET:!cReset!
echo     !cRed! Desconectarse de internet durante el uso.!cReset!
echo     !cRed! Esto reduce posibles conexiones externas mientras las protecciones!cReset!
echo     !cRed! del sistema estan deshabilitadas.!cReset!
echo.
echo  !cWhite! 9.!cReset! !cGreen!Guardar Backup (opcional):!cReset!
echo     Si quieres guardar una configuracion especifica para restaurar siempre,
echo     usa [4] antes de hacer cambios. El backup se guarda en HKLM\SOFTWARE\ManageVBS\Backup
echo.
echo  !cRedHL!10.!cReset! !cRedHL!ANTI-CHEATS DETECTADOS:!cReset!
echo     !cRedHL!FACEIT, EasyAntiCheat, BattlEye, Riot Vanguard, EAC!cReset!
echo     !cRedHL!Si alguno esta instalado, el script no continuara.!cReset!
echo  ----------------------------------------------------------------
exit /b

:: ========================================
:: INFORMACION DETALLADA DEL SISTEMA (NUEVO)
:: ========================================

:dk_sysinfo
set winbuild=1
for /f "tokens=2 delims=[]" %%G in ('ver') do (
    for /f "tokens=2,3,4 delims=. " %%H in ("%%~G") do (
        set "winbuild=%%J"
    )
)

call :dk_reflection

set d1=!ref! $meth = $TypeBuilder.DefinePInvokeMethod('BrandingFormatString', 'winbrand.dll', 'Public, Static', 1, [String], @([String]), 1, 3);
set d1=!d1! $meth.SetImplementationFlags(128); $TypeBuilder.CreateType()::BrandingFormatString('%%WINDOWS_LONG%%') -replace [string][char]0xa9, '' -replace [string][char]0xae, '' -replace [string][char]0x2122, ''

set winos=
for /f "delims=" %%s in ('"%psc% %d1%"') do if not errorlevel 1 set "winos=%%s"
echo "!winos!" | find /i "Windows" >nul 2>&1 || (
    for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winos=%%b"
    if !winbuild! GEQ 22000 set "winos=!winos:Windows 10=Windows 11!"
)

set "osarch="
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE 2^>nul') do set "osarch=%%b"

set "fullbuild="
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if not "%%j"=="" (
    set "fullbuild=%%i.%%j"
) else (
    set "UBR="
    for /f "tokens=3" %%G in ('"reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v UBR" 2^>nul') do if not errorlevel 1 set /a "UBR=%%G"
    for /f "skip=2 tokens=3,4 delims=. " %%G in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx 2^>nul') do (
        if defined UBR (set "fullbuild=%%G.!UBR!") else (set "fullbuild=%%G.%%H")
    )
)
exit /b

:: This is used to build the PowerShell reflection code that calls BrandingFormatString from winbrand.dll to get the Windows product name

:dk_reflection
set ref=$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1);
set ref=%ref% $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False);
set ref=%ref% $TypeBuilder = $ModuleBuilder.DefineType(0);
exit /b

:: ========================================
:: DETECCION MULTIPLE DE ANTI-CHEATS (CORREGIDO)
:: ========================================

:check_anticheat
set "anticheat_detected=0"
set "anticheat_name="

:: Solo detectar si la carpeta existe Y tiene archivos (para evitar falsos positivos)
if exist "C:\Program Files\FACEIT AC\*" (
    set "anticheat_detected=1"
    set "anticheat_name=FACEIT AC"
)
if exist "C:\Program Files\EasyAntiCheat\*" (
    set "anticheat_detected=1"
    set "anticheat_name=EasyAntiCheat"
)
if exist "C:\Program Files\EasyAntiCheat_EOS\*" (
    set "anticheat_detected=1"
    set "anticheat_name=EasyAntiCheat EOS"
)
if exist "C:\Program Files\BattlEye\*" (
    set "anticheat_detected=1"
    set "anticheat_name=BattlEye"
)
if exist "C:\Program Files\Riot Vanguard\*" (
    set "anticheat_detected=1"
    set "anticheat_name=Riot Vanguard"
)
if exist "C:\Program Files\EAC\*" (
    set "anticheat_detected=1"
    set "anticheat_name=EasyAntiCheat"
)

:: Verificar tambien en Program Files (x86) para sistemas de 64 bits
if exist "C:\Program Files (x86)\FACEIT AC\*" (
    set "anticheat_detected=1"
    set "anticheat_name=FACEIT AC"
)
if exist "C:\Program Files (x86)\EasyAntiCheat\*" (
    set "anticheat_detected=1"
    set "anticheat_name=EasyAntiCheat"
)
if exist "C:\Program Files (x86)\BattlEye\*" (
    set "anticheat_detected=1"
    set "anticheat_name=BattlEye"
)
if exist "C:\Program Files (x86)\Riot Vanguard\*" (
    set "anticheat_detected=1"
    set "anticheat_name=Riot Vanguard"
)

:: Si se detectó algún anti-cheat, mostrar advertencia pero NO salir automáticamente
if "!anticheat_detected!"=="1" (
    echo.
    echo  !cRedHL!----------------------------------------------------!cReset!
    echo  !cRedHL!  ADVERTENCIA: Anti-Cheat detectado: !anticheat_name!!cReset!
    echo  !cRedHL!----------------------------------------------------!cReset!
    echo  !cYellow!  Los anti-cheats pueden bloquear controladores sin firma.!cReset!
    echo  !cYellow!  Si experimentas problemas, desinstala el anti-cheat.!cReset!
    echo.
    choice /C:SN /N /M "  ^¿Deseas continuar de todas formas? (S/N): "
    if errorlevel 2 (
        echo.
        echo  !cYellow!Operacion cancelada.!cReset!
        echo.
        pause
        exit /b
    )
)
exit /b

:: ========================================
:: VERIFICACION DE VIRTUALIZACION EN BIOS
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
:: ========================================

:check_dse
set "dse="
for /f "delims=" %%A in ('%psc% "$t=Add-Type -PassThru -MemberDefinition '[DllImport(""ntdll.dll"")] public static extern uint NtQuerySystemInformation(int c,IntPtr b,uint s,out uint r);' -Name CI2 -Namespace w2; $p=[Runtime.InteropServices.Marshal]::AllocHGlobal(8); [Runtime.InteropServices.Marshal]::WriteInt32($p,8); $r=[uint32]0; $t::NtQuerySystemInformation(103,$p,8,[ref]$r)|Out-Null; $o=[uint32][Runtime.InteropServices.Marshal]::ReadInt32($p,4); if(-not($o -band 1)){0}elseif($o -band 2){1}else{2}" 2^>nul') do set "dse=%%A"
exit /b

:: ========================================
:: VERIFICACION DE SMART APP CONTROL
:: ========================================

:check_sac
set "sacstate="
set "sac_message="
if !winbuild! GEQ 22621 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState 2^>nul') do (
        set "sacstate=%%a"
    )
)
if defined sacstate (
    if "!sacstate!"=="0x1" set "sac_message=!cYellow![ACTIVADO]!cReset! Smart App Control esta activado. Puede bloquear aplicaciones."
    if "!sacstate!"=="0x2" set "sac_message=!cYellow![EVALUACION]!cReset! Smart App Control esta en modo evaluacion. Puede activarse solo."
)
exit /b

:: ========================================
:: VERIFICACION DE UEFI LOCK
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
:: VERIFICACION DE BITLOCKER
:: ========================================

:check_bitlocker
set "blprotected=0"
for /f "delims=" %%s in ('powershell -nop -c "(Get-BitLockerVolume -MountPoint $env:SystemDrive).ProtectionStatus" 2^>nul') do (
    if "%%s"=="On" set "blprotected=1"
)
exit /b

:: ========================================
:: SUSPENDER BITLOCKER INTELIGENTE
:: ========================================

:suspend_bitlocker_smart
call :check_bitlocker
if "!blprotected!"=="1" (
    set "reboot_count=%~1"
    if "!reboot_count!"=="" set "reboot_count=1"
    echo.
    echo  !cOrange!BitLocker detectado. Suspendiendo proteccion por !reboot_count! reinicio(s)...!cReset!
    manage-bde -protectors -disable %SystemDrive% -rebootcount !reboot_count! >nul 2>&1
    if errorlevel 1 (
        echo  !cRed!No se pudo suspender BitLocker. Abortando.!cReset!
        echo  !cYellow!Ejecuta la opcion [3] Revertir Cambios para restaurar el estado anterior.!cReset!
        echo.
        pause
        exit /b 1
    ) else (
        echo  !cGreen!BitLocker suspendido exitosamente. El cifrado sigue activo.!cReset!
    )
)
exit /b 0

:: ========================================
:: RESPALDAR CONFIGURACION ACTUAL
:: ========================================

:backup_config
call :show_title
echo  !cCyan!GUARDAR BACKUP (OPCIONAL)!cReset!
echo  !cCyan!==========================================================!cReset!
echo.
echo  !cYellow!Guardando el estado actual de las caracteristicas de seguridad...!cReset!
echo.

:: Crear clave de respaldo
reg add "HKLM\SOFTWARE\ManageVBS\Backup" /f >nul 2>&1

:: Variables para contar respaldos
set "backup_count=0"

:: Respaldo VBS
call :get_vbs_status
if "!vbs_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v VBS /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! VBS activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v VBS /t REG_DWORD /d 0 /f >nul 2>&1
    echo   !cYellow![INFO]!cReset! VBS inactivo - se guarda estado 0
)

:: Respaldo RequirePlatformSecurityFeatures
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures 2^>nul') do (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v RequirePlatformSecurityFeatures /t REG_SZ /d "%%A" /f >nul 2>&1
    echo   !cGreen![OK]!cReset! RequirePlatformSecurityFeatures respaldado
)

:: Respaldo HVCI
call :get_hvci_status
if "!hvci_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v HVCI /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! HVCI activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v HVCI /t REG_DWORD /d 0 /f >nul 2>&1
    echo   !cYellow![INFO]!cReset! HVCI inactivo - se guarda estado 0
)

:: Respaldo Windows Hello
call :get_winhello_status
if "!winhello_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v WindowsHello /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! Windows Hello activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v WindowsHello /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo SecureBiometrics
call :get_secbio_status
if "!secbio_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v SecureBiometrics /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! SecureBiometrics activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v SecureBiometrics /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo System Guard
call :get_sysguard_status
if "!sysguard_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v SystemGuard /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! System Guard activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v SystemGuard /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo Credential Guard
call :get_credguard_status
if "!credguard_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v CredentialGuard /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! Credential Guard activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v CredentialGuard /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo KVA Shadow
call :get_kva_status
if "!kva_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v KVAShadow /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! KVA Shadow activo - respaldado
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v KVAShadow /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo Hypervisor
call :get_hypervisor_status
if "!hyp_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v Hypervisor /t REG_DWORD /d 1 /f >nul 2>&1
    set /a backup_count+=1
    echo   !cGreen![OK]!cReset! Hypervisor activo - respaldado
    if not "!hyp_launchtype!"=="" (
        reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v HypervisorLaunchType /t REG_SZ /d "!hyp_launchtype!" /f >nul 2>&1
        echo   !cGreen![OK]!cReset! HypervisorLaunchType=!hyp_launchtype! respaldado
    )
) else (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v Hypervisor /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Respaldo UEFI locks
call :check_uefi_locks
if defined vbslocked (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v VBSLocked /t REG_DWORD /d 1 /f >nul 2>&1
    echo   !cGreen![OK]!cReset! VBS UEFI Lock detectado - respaldado
)
if defined hvcilocked (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v HVCILocked /t REG_DWORD /d 1 /f >nul 2>&1
    echo   !cGreen![OK]!cReset! HVCI UEFI Lock detectado - respaldado
)
if defined cglocked (
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v CGLocked /t REG_DWORD /d 1 /f >nul 2>&1
    echo   !cGreen![OK]!cReset! Credential Guard UEFI Lock detectado - respaldado
)

:: Guardar fecha y hora del respaldo
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "backup_date=%%a/%%b/%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "backup_time=%%a:%%b"
reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v BackupDate /t REG_SZ /d "!backup_date! !backup_time!" /f >nul 2>&1

echo.
echo  !cGreen!==========================================================!cReset!
echo  !cGreen!BACKUP GUARDADO EXITOSAMENTE!cReset!
echo  !cGreen!==========================================================!cReset!
echo.
echo  !cWhite!Caracteristicas respaldadas: !cCyan!!backup_count! activas!cReset!
echo  !cWhite!Ubicacion del respaldo: !cYellow!HKLM\SOFTWARE\ManageVBS\Backup!cReset!
echo  !cWhite!Fecha del respaldo: !cYellow!!backup_date! !backup_time!!cReset!
echo.
echo  !cCyan!Para restaurar este respaldo, usa la opcion [3] Revertir Cambios!cReset!
echo.
pause
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
:: MOSTRAR ESTADO (CON INFORMACION DEL SISTEMA)
:: ========================================

:show_status
call :show_title
echo  !cCyan!SISTEMA OPERATIVO!cReset!
echo  !cCyan!==========================================================!cReset!
echo  !cWhite!  Version: !cGreen!!winos!!cReset!
echo  !cWhite!  Build:   !cGreen!!fullbuild!!cReset!
echo  !cWhite!  Arquitectura: !cGreen!!osarch!!cReset!
echo.
echo  !cCyan!ESTADO DE CARACTERISTICAS DE SEGURIDAD!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

:: Verificar Anti-Cheats
call :check_anticheat
if "!anticheat_detected!"=="1" (
    echo  !cRedHL![ADVERTENCIA] ANTI-CHEAT DETECTADO: !anticheat_name!!cReset!
    echo  !cRedHL!  Se conoce que bloquean la carga de drivers sin firma.!cReset!
    echo  !cRedHL!  Desinstalalo antes de usar la opcion [2] Desactivar Todo.!cReset!
    echo.
)

:: Verificar Smart App Control
call :check_sac
if defined sac_message (
    echo  !sac_message!
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

:: Verificar existencia de respaldo
set "backup_exists=0"
reg query "HKLM\SOFTWARE\ManageVBS\Backup" >nul 2>&1
if "!errorlevel!"=="0" set "backup_exists=1"
if "!backup_exists!"=="1" (
    echo  !cGreen!  [RESPALDO] Existe un respaldo guardado en el sistema!cReset!
    for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\Backup" /v BackupDate 2^>nul') do (
        echo  !cWhite!    Fecha del respaldo: !cCyan!%%A!cReset!
    )
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
call :print_status "Enhanced Sign-in Security (SecureBiometrics)" !secbio_status!

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
:: ACTIVAR TODAS LAS CARACTERISTICAS (MAXIMA SEGURIDAD)
:: ========================================

:enable_all
call :show_title
echo  !cYellow!ACTIVANDO MODO MAXIMA SEGURIDAD...!cReset!
echo.

:: Verificar Anti-Cheats
call :check_anticheat
if "!anticheat_detected!"=="1" (
    echo  !cRedHL![ADVERTENCIA] ANTI-CHEAT DETECTADO: !anticheat_name!!cReset!
    echo  !cRedHL!  Se conoce que bloquean la carga de drivers sin firma.!cReset!
    echo  !cRedHL!  Desinstalalo antes de continuar.!cReset!
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
choice /C:SN /N /M "  ¿Deseas reiniciar el equipo ahora? (S/N): "
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
:: DESACTIVAR TODAS LAS CARACTERISTICAS (CORREGIDA)
:: ========================================

:disable_all
call :show_title
echo  !cYellow!DESACTIVANDO MODO COMPATIBILIDAD (para juegos/software)...!cReset!
echo.

:: --- Verificacion Anti-Cheats ---
call :check_anticheat

:: --- Verificacion VT-x ---
call :check_vtx
if "!vtx!"=="0" (
    echo  !cOrange![INFO] Virtualizacion ^(VT-x/SVM^) no detectada en BIOS.!cReset!
    echo  !cYellow!  Es posible que VBS ya no este activo.!cReset!
    echo.
)

:: Verificaciones adicionales
call :check_dse
call :check_uefi_locks

:: UEFI locks
if defined anylocked (
    set "uefiagreed="
    reg query "HKLM\SOFTWARE\ManageVBS" /v UEFILockAgreed >nul 2>&1
    if "!errorlevel!"=="0" set "uefiagreed=1"
    if not defined uefiagreed (
        echo  !cRed!Una o mas caracteristicas estan protegidas por UEFI lock.!cReset!
        echo  !cYellow!  Solo procede en dispositivos personales.!cReset!
        echo  !cYellow!  No continuar en equipos de trabajo, escuela o gestionados.!cReset!
        echo.
        choice /C:SN /N /M "  ¿Deseas continuar? (S/N): "
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

:: --- Confirmacion final ---
echo.
echo  !cRedHL!ATENCION! Esto desactivara las siguientes caracteristicas:!cReset!
echo  !cYellow!  - VBS (Virtualization-based Security)!cReset!
echo  !cYellow!  - HVCI (Memory Integrity)!cReset!
echo  !cYellow!  - Windows Hello Protection!cReset!
echo  !cYellow!  - Enhanced Sign-in Security!cReset!
echo  !cYellow!  - System Guard Secure Launch!cReset!
echo  !cYellow!  - Credential Guard!cReset!
echo  !cYellow!  - KVA Shadow!cReset!
echo  !cYellow!  - Windows Hypervisor!cReset!
echo.
choice /C:SN /N /M "  Estas seguro de continuar? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Operacion cancelada!cReset!
    echo.
    pause
    exit /b
)
echo.

set "haderror=0"

:: --- Desbloqueo UEFI via SecConfig.efi ---
if defined vbslocked (
    echo  !cYellow!VBS tiene UEFI lock. Intentando desbloquear...!cReset!
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
    echo  !cYellow!HVCI tiene UEFI lock. Intentando desbloquear...!cReset!
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
    echo  !cYellow!Credential Guard tiene UEFI lock. Intentando desbloquear...!cReset!
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

:: --- GUARDAR BACKUP AUTOMATICO ---
echo.
echo  !cYellow!Guardando estado actual de la configuracion...!cReset!

:: Crear backup en Working (para revertir cambios)
call :backup_config_internal

:: También crear un backup permanente en Backup si no existe
set "has_backup=0"
reg query "HKLM\SOFTWARE\ManageVBS\Backup" >nul 2>&1
if "!errorlevel!"=="0" set "has_backup=1"

if "!has_backup!"=="0" (
    echo  !cGreen!Creando respaldo permanente de la configuracion actual...!cReset!
    reg copy "HKLM\SOFTWARE\ManageVBS\Working" "HKLM\SOFTWARE\ManageVBS\Backup" /f >nul 2>&1
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "backup_date=%%a/%%b/%%c"
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "backup_time=%%a:%%b"
    reg add "HKLM\SOFTWARE\ManageVBS\Backup" /v BackupDate /t REG_SZ /d "!backup_date! !backup_time!" /f >nul 2>&1
    echo  !cGreen!Respaldo guardado en HKLM\SOFTWARE\ManageVBS\Backup!cReset!
) else (
    echo  !cGreen!Usando respaldo existente en HKLM\SOFTWARE\ManageVBS\Backup!cReset!
)

:: Guardar valores exactos de HypervisorLaunchType en Working
call :get_hypervisor_status
if "!hyp_status!"=="1" (
    reg add "HKLM\SOFTWARE\ManageVBS\Working" /v Hypervisor /t REG_DWORD /d 1 /f >nul 2>&1
    if not "!hyp_launchtype!"=="" (
        reg add "HKLM\SOFTWARE\ManageVBS\Working" /v HypervisorLaunchType /t REG_SZ /d "!hyp_launchtype!" /f >nul 2>&1
    )
)

:: --- Desactivar caracteristicas ---
echo.
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
echo  !cYellow!NOTA: El sistema reiniciara en modo avanzado. Presiona F7.!cReset!
echo.
choice /C:SN /N /M "  ^¿Reiniciar ahora? (S/N): "
if errorlevel 2 (
    echo.
    echo  !cYellow!Reinicio cancelado.!cReset!
    echo.
    pause
    exit /b
)

:: --- Suspender BitLocker inteligente ---
set "reboot_needed=1"
if "!cgrunning!"=="1" if !winbuild! LEQ 19045 set "reboot_needed=2"

call :suspend_bitlocker_smart !reboot_needed!
if errorlevel 1 exit /b

bcdedit /set {current} onetimeadvancedoptions on >nul 2>&1

if "!reboot_needed!"=="2" (
    echo  !cBlueHL!Credential Guard activo en Windows 10. Se requieren dos reinicios.!cReset!
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "VBSAdvancedOptions" /t REG_SZ /d "bcdedit /set {current} onetimeadvancedoptions on" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "VBSSecondReboot" /t REG_SZ /d "shutdown /r /t 0" /f >nul 2>&1
)

echo.
echo  !cGreen!Reiniciando...!cReset!
shutdown /r /t 0
exit /b

:: ========================================
:: RESPALDO INTERNO
:: ========================================

:backup_config_internal
reg add "HKLM\SOFTWARE\ManageVBS\Working" /f >nul 2>&1

call :get_vbs_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v VBS /t REG_DWORD /d !vbs_status! /f >nul 2>&1

call :get_hvci_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v HVCI /t REG_DWORD /d !hvci_status! /f >nul 2>&1

call :get_winhello_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v WindowsHello /t REG_DWORD /d !winhello_status! /f >nul 2>&1

call :get_secbio_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v SecureBiometrics /t REG_DWORD /d !secbio_status! /f >nul 2>&1

call :get_sysguard_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v SystemGuard /t REG_DWORD /d !sysguard_status! /f >nul 2>&1

call :get_credguard_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v CredentialGuard /t REG_DWORD /d !credguard_status! /f >nul 2>&1

call :get_kva_status
reg add "HKLM\SOFTWARE\ManageVBS\Working" /v KVAShadow /t REG_DWORD /d !kva_status! /f >nul 2>&1

exit /b

:: ========================================
:: REVERTIR CAMBIOS
:: ========================================

:revert_changes
call :show_title
echo  !cCyan!REVERTIR CAMBIOS!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

call :check_dse

set "has_backup=0"
set "has_working=0"
reg query "HKLM\SOFTWARE\ManageVBS\Backup" >nul 2>&1
if "!errorlevel!"=="0" set "has_backup=1"
reg query "HKLM\SOFTWARE\ManageVBS\Working" >nul 2>&1
if "!errorlevel!"=="0" set "has_working=1"

if "!has_backup!"=="0" if "!has_working!"=="0" (
    echo  !cYellow!No hay respaldo ni cambios previos registrados para revertir.!cReset!
    echo.
    pause
    exit /b
)

if "!has_backup!"=="1" (
    echo  !cGreen!Usando respaldo completo guardado para restaurar configuracion...!cReset!
    set "restore_from=Backup"
) else (
    echo  !cGreen!Usando registro de cambios previos para restaurar...!cReset!
    set "restore_from=Working"
)

echo  !cYellow!Restaurando caracteristicas desde !restore_from!...!cReset!
echo.
set "haderror=0"

:: Revertir VBS
set "revert_vbs="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v VBS 2^>nul') do set "revert_vbs=%%A"
if defined revert_vbs (
    set /p "=  Restaurando VBS...                      " <nul
    if "!revert_vbs!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir RequirePlatformSecurityFeatures
set "revert_rpsf="
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v RequirePlatformSecurityFeatures 2^>nul') do set "revert_rpsf=%%B"
if defined revert_rpsf (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d !revert_rpsf! /f >nul 2>&1
)

:: Revertir HVCI
set "revert_hvci="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v HVCI 2^>nul') do set "revert_hvci=%%A"
if defined revert_hvci (
    set /p "=  Restaurando HVCI...                     " <nul
    if "!revert_hvci!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir Windows Hello
set "revert_wh="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v WindowsHello 2^>nul') do set "revert_wh=%%A"
if defined revert_wh (
    set /p "=  Restaurando Windows Hello...            " <nul
    if "!revert_wh!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir SecureBiometrics
set "revert_sb="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v SecureBiometrics 2^>nul') do set "revert_sb=%%A"
if defined revert_sb (
    set /p "=  Restaurando Enhanced Sign-in Security.. " <nul
    if "!revert_sb!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir System Guard
set "revert_sg="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v SystemGuard 2^>nul') do set "revert_sg=%%A"
if defined revert_sg (
    set /p "=  Restaurando System Guard...             " <nul
    if "!revert_sg!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir Credential Guard
set "revert_cg="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v CredentialGuard 2^>nul') do set "revert_cg=%%A"
if defined revert_cg (
    set /p "=  Restaurando Credential Guard...         " <nul
    if "!revert_cg!"=="0x1" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

:: Revertir KVA Shadow
set "revert_kva="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v KVAShadow 2^>nul') do set "revert_kva=%%A"
if defined revert_kva (
    set /p "=  Restaurando KVA Shadow...               " <nul
    if "!revert_kva!"=="0x1" (
        reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /f >nul 2>&1
        reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /f >nul 2>&1
    ) else (
        reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 2 /f >nul 2>&1
        reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
    )
    echo !cGreen![OK]!cReset!
)

:: Revertir Hypervisor
set "revert_hyp="
set "revert_hyptype="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v Hypervisor 2^>nul') do set "revert_hyp=%%A"
for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\ManageVBS\!restore_from!" /v HypervisorLaunchType 2^>nul') do set "revert_hyptype=%%B"
if defined revert_hyp (
    set /p "=  Restaurando Hypervisor...               " <nul
    if "!revert_hyp!"=="0x1" (
        if "!revert_hyptype!"=="" (
            bcdedit /deletevalue {current} hypervisorlaunchtype >nul 2>&1
        ) else (
            bcdedit /set hypervisorlaunchtype !revert_hyptype! >nul 2>&1
        )
    ) else (
        bcdedit /set hypervisorlaunchtype off >nul 2>&1
    )
    if errorlevel 1 (echo !cRed![FAIL]!cReset! & set "haderror=1") else (echo !cGreen![OK]!cReset!)
)

reg delete "HKLM\SOFTWARE\ManageVBS\Working" /f >nul 2>&1

if "!has_backup!"=="1" (
    echo.
    echo  !cYellow!Existe un respaldo guardado en HKLM\SOFTWARE\ManageVBS\Backup!cReset!
    choice /C:SN /N /M "  ^¿Deseas conservar el respaldo para futuras restauraciones? (S/N): "
    if errorlevel 2 (
        reg delete "HKLM\SOFTWARE\ManageVBS\Backup" /f >nul 2>&1
        echo  !cGreen!Respaldo eliminado.!cReset!
    ) else (
        echo  !cGreen!Respaldo conservado.!cReset!
    )
)

echo.
if "!haderror!"=="1" (
    echo  !cRed!Algunos cambios no pudieron revertirse. Intenta ejecutar el script nuevamente.!cReset!
) else (
    echo  !cGreen!Todos los cambios fueron revertidos exitosamente.!cReset!
)
echo.
echo  !cYellow!NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios.!cReset!
echo.
choice /C:SN /N /M "  ¿Deseas reiniciar el equipo ahora? (S/N): "
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
:: DESBLOQUEO UEFI CON SECCONFIG.EFI
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

:: ========================================
:: PERSONALIZAR CARACTERISTICAS (ACTIVAR/DESACTIVAR INDIVIDUAL)
:: ========================================

:customize_features
:customize_loop
call :show_title
echo  !cCyan!PERSONALIZAR CARACTERISTICAS DE SEGURIDAD!cReset!
echo  !cCyan!==========================================================!cReset!
echo.

:: Obtener estados actuales
call :get_vbs_status
call :get_hvci_status
call :get_winhello_status
call :get_secbio_status
call :get_sysguard_status
call :get_credguard_status
call :get_kva_status
call :get_hypervisor_status

echo  !cWhite![1]!cReset! VBS (Virtualization-based Security)           !cCyan![!cReset!!vbs_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![2]!cReset! HVCI (Memory Integrity)                       !cCyan![!cReset!!hvci_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![3]!cReset! Windows Hello Protection                      !cCyan![!cReset!!winhello_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![4]!cReset! Enhanced Sign-in Security (SecureBiometrics)  !cCyan![!cReset!!secbio_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![5]!cReset! System Guard Secure Launch                    !cCyan![!cReset!!sysguard_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![6]!cReset! Credential Guard                              !cCyan![!cReset!!credguard_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![7]!cReset! KVA Shadow (Meltdown Mitigation)              !cCyan![!cReset!!kva_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo  !cWhite![8]!cReset! Windows Hypervisor                            !cCyan![!cReset!!hyp_status! == 1? !cGreen!ACTIVO!cReset! : !cRed!INACTIVO!cReset!!cCyan!]!cReset!
echo.
echo  !cWhite![0]!cReset! Volver al menu principal
echo.
choice /C:123456780 /N /M "  Selecciona una caracteristica: "
set "opt_cust=!errorlevel!"

if "!opt_cust!"=="1" goto :cust_vbs
if "!opt_cust!"=="2" goto :cust_hvci
if "!opt_cust!"=="3" goto :cust_winhello
if "!opt_cust!"=="4" goto :cust_secbio
if "!opt_cust!"=="5" goto :cust_sysguard
if "!opt_cust!"=="6" goto :cust_credguard
if "!opt_cust!"=="7" goto :cust_kva
if "!opt_cust!"=="8" goto :cust_hypervisor
if "!opt_cust!"=="9" goto :show_menu  :: Opcion 0
goto :show_menu

:cust_vbs
cls
echo.
echo  !cCyan!VBS (Virtualization-based Security)!cReset!
echo  Estado actual: !vbs_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_vbs
    echo  !cYellow!VBS desactivado. Se recomienda reiniciar para aplicar cambios.!cReset!
) else if errorlevel 1 (
    call :enable_vbs
    echo  !cYellow!VBS activado. Se recomienda reiniciar para aplicar cambios.!cReset!
)
pause
goto :customize_loop

:cust_hvci
cls
echo.
echo  !cCyan!HVCI (Memory Integrity)!cReset!
echo  Estado actual: !hvci_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_hvci
    echo  !cYellow!HVCI desactivado. Se recomienda reiniciar para aplicar cambios.!cReset!
) else if errorlevel 1 (
    call :enable_hvci
    echo  !cYellow!HVCI activado. Se recomienda reiniciar para aplicar cambios.!cReset!
)
pause
goto :customize_loop

:cust_winhello
cls
echo.
echo  !cCyan!Windows Hello Protection!cReset!
echo  Estado actual: !winhello_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_winhello
    echo  !cYellow!Windows Hello Protection desactivada. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_winhello
    echo  !cYellow!Windows Hello Protection activada. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop

:cust_secbio
cls
echo.
echo  !cCyan!Enhanced Sign-in Security (SecureBiometrics)!cReset!
echo  Estado actual: !secbio_status! == 1? ACTIVO : INACTIVO
echo.
echo  !cYellow!NOTA: Esta caracteristica requiere hardware compatible.!cReset!
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_secbio
    echo  !cYellow!SecureBiometrics desactivado. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_secbio
    echo  !cYellow!SecureBiometrics activado. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop

:cust_sysguard
cls
echo.
echo  !cCyan!System Guard Secure Launch!cReset!
echo  Estado actual: !sysguard_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_sysguard
    echo  !cYellow!System Guard desactivado. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_sysguard
    echo  !cYellow!System Guard activado. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop

:cust_credguard
cls
echo.
echo  !cCyan!Credential Guard!cReset!
echo  Estado actual: !credguard_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_credguard
    echo  !cYellow!Credential Guard desactivado. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_credguard
    echo  !cYellow!Credential Guard activado. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop

:cust_kva
cls
echo.
echo  !cCyan!KVA Shadow (Meltdown Mitigation)!cReset!
echo  Estado actual: !kva_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_kva
    echo  !cYellow!KVA Shadow desactivado. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_kva
    echo  !cYellow!KVA Shadow activado. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop

:cust_hypervisor
cls
echo.
echo  !cCyan!Windows Hypervisor!cReset!
echo  Estado actual: !hyp_status! == 1? ACTIVO : INACTIVO
echo.
echo  [1] Activar
echo  [2] Desactivar
echo  [0] Cancelar
choice /C:120 /N /M "  Selecciona: "
if errorlevel 3 goto :customize_loop
if errorlevel 2 (
    call :disable_hypervisor
    echo  !cYellow!Hypervisor desactivado. Se recomienda reiniciar.!cReset!
) else if errorlevel 1 (
    call :enable_hypervisor
    echo  !cYellow!Hypervisor activado. Se recomienda reiniciar.!cReset!
)
pause
goto :customize_loop