# ========================================
# WINDOWS SECURITY FEATURES MANAGER
# ========================================
# Script para gestionar caracteristicas de seguridad de Windows
# Permite ver estado y activar/desactivar:
# - VBS (Virtualization-based Security)
# - HVCI (Memory Integrity)
# - Windows Hello Protection
# - System Guard Secure Launch
# - Credential Guard
# - KVA Shadow (Meltdown Mitigation)
# ========================================

#Require -RunAsAdministrator

param()

# Colores
$colors = @{
    'Success'  = 'Green'
    'Error'    = 'Red'
    'Warning'  = 'Yellow'
    'Info'     = 'Cyan'
    'Title'    = 'Magenta'
}

# Variables globales
$script:LogFile = "$PSScriptRoot\Security-Log-$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# ========================================
# FUNCIONES AUXILIARES
# ========================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Type] $Message"
    Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction SilentlyContinue
    Write-Host $logMessage -ForegroundColor $colors[$Type]
}

function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Este script requiere privilegios de Administrador." -ForegroundColor Red
        Write-Host "Por favor, ejecuta PowerShell como Administrador." -ForegroundColor Yellow
        pause
        exit
    }
}

function Show-Title {
    Clear-Host
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "   WINDOWS SECURITY FEATURES MANAGER" -ForegroundColor Magenta
    Write-Host "   Gestor de Características de Seguridad de Windows" -ForegroundColor Magenta
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Show-Menu {
    Show-Title
    Write-Host "MENU PRINCIPAL" -ForegroundColor Cyan
    Write-Host "----------------------------------"
    Write-Host "[1] Ver Estado de Caracteristicas"
    Write-Host "[2] Activar Todas las Caracteristicas"
    Write-Host "[3] Desactivar Todas las Caracteristicas"
    Write-Host "[4] Configurar Caracteristica Individual"
    Write-Host "[5] Verificar y Reparar Configuracion"
    Write-Host "[6] Ver Log"
    Write-Host "[7] Reiniciar PC"
    Write-Host "[8] Reinicio Avanzado (F7 - Drivers sin firma)"
    Write-Host "[0] Salir"
    Write-Host "----------------------------------"
}

# ========================================
# FUNCIONES DE VERIFICACIÓN DE ESTADO
# ========================================

function Get-VBSStatus {
    $vbsReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name EnableVirtualizationBasedSecurity -ErrorAction SilentlyContinue
    return $vbsReg.EnableVirtualizationBasedSecurity -eq 1
}

function Get-HVCIStatus {
    $hvciReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name Enabled -ErrorAction SilentlyContinue
    return $hvciReg.Enabled -eq 1
}

function Get-WindowsHelloStatus {
    $whReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" -Name Enabled -ErrorAction SilentlyContinue
    return $whReg.Enabled -eq 1
}

function Get-SystemGuardStatus {
    $sgReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" -Name Enabled -ErrorAction SilentlyContinue
    return $sgReg.Enabled -eq 1
}

function Get-CredentialGuardStatus {
    $cgReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LsaCfgFlags -ErrorAction SilentlyContinue
    return $cgReg.LsaCfgFlags -eq 2
}

function Get-KVAShadowStatus {
    $kvaReg1 = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverride -ErrorAction SilentlyContinue
    $kvaReg2 = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverrideMask -ErrorAction SilentlyContinue
    
    # KVA Shadow está desactivado si ambos valores existen y son 2 y 3
    $disabled = ($kvaReg1.FeatureSettingsOverride -eq 2) -and ($kvaReg2.FeatureSettingsOverrideMask -eq 3)
    return -not $disabled
}

function Get-HypervisorStatus {
    try {
        $bcd = bcdedit /enum '{current}' 2>$null | Select-String "hypervisorlaunchtype" | Select-Object -First 1
        if ($bcd) {
            $hvType = $bcd -replace '.*hypervisorlaunchtype\s+' -replace '\s+$'
            return $hvType -in 'Auto', 'On'
        }
    } catch {}
    return $false
}

# ========================================
# FUNCIONES DE ACTIVACIÓN/DESACTIVACIÓN
# ========================================

function Enable-VBS {
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name EnableVirtualizationBasedSecurity -Value 1 -Type DWord -Force
        Write-Log "VBS activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar VBS: $_" "Error"
        return $false
    }
}

function Disable-VBS {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name EnableVirtualizationBasedSecurity -Value 0 -Type DWord -Force
        Write-Log "VBS desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar VBS: $_" "Error"
        return $false
    }
}

function Enable-HVCI {
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name Enabled -Value 1 -Type DWord -Force
        Write-Log "HVCI activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar HVCI: $_" "Error"
        return $false
    }
}

function Disable-HVCI {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name Enabled -Value 0 -Type DWord -Force
        Write-Log "HVCI desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar HVCI: $_" "Error"
        return $false
    }
}

function Enable-WindowsHello {
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" -Name Enabled -Value 1 -Type DWord -Force
        Write-Log "Windows Hello Protection activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar Windows Hello: $_" "Error"
        return $false
    }
}

function Disable-WindowsHello {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" -Name Enabled -Value 0 -Type DWord -Force
        Write-Log "Windows Hello Protection desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar Windows Hello: $_" "Error"
        return $false
    }
}

function Enable-SystemGuard {
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" -Name Enabled -Value 1 -Type DWord -Force
        Write-Log "System Guard Secure Launch activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar System Guard: $_" "Error"
        return $false
    }
}

function Disable-SystemGuard {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" -Name Enabled -Value 0 -Type DWord -Force
        Write-Log "System Guard Secure Launch desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar System Guard: $_" "Error"
        return $false
    }
}

function Enable-CredentialGuard {
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LsaCfgFlags -Value 2 -Type DWord -Force
        
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name LsaCfgFlags -Value 2 -Type DWord -Force
        
        Write-Log "Credential Guard activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar Credential Guard: $_" "Error"
        return $false
    }
}

function Disable-CredentialGuard {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LsaCfgFlags -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name LsaCfgFlags -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Log "Credential Guard desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar Credential Guard: $_" "Error"
        return $false
    }
}

function Enable-KVAShadow {
    try {
        New-Item -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Force -ErrorAction SilentlyContinue | Out-Null
        # Eliminar los valores de override para restaurar KVA Shadow
        Remove-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverride -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverrideMask -Force -ErrorAction SilentlyContinue
        Write-Log "KVA Shadow (Meltdown Mitigation) activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar KVA Shadow: $_" "Error"
        return $false
    }
}

function Disable-KVAShadow {
    try {
        New-Item -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverride -Value 2 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverrideMask -Value 3 -Type DWord -Force
        Write-Log "KVA Shadow (Meltdown Mitigation) desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar KVA Shadow: $_" "Error"
        return $false
    }
}

function Enable-Hypervisor {
    try {
        bcdedit /set hypervisorlaunchtype auto 2>$null
        Write-Log "Windows Hypervisor activado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al activar Hypervisor: $_" "Error"
        return $false
    }
}

function Disable-Hypervisor {
    try {
        bcdedit /set hypervisorlaunchtype off 2>$null
        Write-Log "Windows Hypervisor desactivado exitosamente" "Success"
        return $true
    } catch {
        Write-Log "Error al desactivar Hypervisor: $_" "Error"
        return $false
    }
}

# ========================================
# FUNCIONES DE VISUALIZACIÓN
# ========================================

function Show-Status {
    Show-Title
    Write-Host "ESTADO DE CARACTERISTICAS DE SEGURIDAD" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $features = @(
        @{Name = "VBS (Virtualization-based Security)"; Status = Get-VBSStatus},
        @{Name = "HVCI (Memory Integrity)"; Status = Get-HVCIStatus},
        @{Name = "Windows Hello Protection"; Status = Get-WindowsHelloStatus},
        @{Name = "System Guard Secure Launch"; Status = Get-SystemGuardStatus},
        @{Name = "Credential Guard"; Status = Get-CredentialGuardStatus},
        @{Name = "KVA Shadow (Meltdown Mitigation)"; Status = Get-KVAShadowStatus},
        @{Name = "Windows Hypervisor"; Status = Get-HypervisorStatus}
    )
    
    foreach ($feature in $features) {
        $statusText = if ($feature.Status) { "[+] ACTIVO" } else { "[-] INACTIVO" }
        $statusColor = if ($feature.Status) { "Green" } else { "Red" }
        Write-Host "$($feature.Name)" -ForegroundColor White
        Write-Host "    Estado: " -NoNewline
        Write-Host $statusText -ForegroundColor $statusColor
        Write-Host ""
    }
    
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Estado de caracteristicas consultado" "Info"
    pause
}

function Show-IndividualConfig {
    Show-Title
    Write-Host "CONFIGURAR CARACTERISTICA INDIVIDUAL" -ForegroundColor Cyan
    Write-Host "----------------------------------"
    Write-Host "[1] VBS (Virtualization-based Security)"
    Write-Host "[2] HVCI (Memory Integrity)"
    Write-Host "[3] Windows Hello Protection"
    Write-Host "[4] System Guard Secure Launch"
    Write-Host "[5] Credential Guard"
    Write-Host "[6] KVA Shadow (Meltdown Mitigation)"
    Write-Host "[7] Windows Hypervisor"
    Write-Host "[0] Volver al Menu Principal"
    Write-Host "----------------------------------"
    $choice = Read-Host "Selecciona una opcion"
    
    switch ($choice) {
        "1" { ConfigureFeature -FeatureName "VBS" -EnableFunc ${function:Enable-VBS} -DisableFunc ${function:Disable-VBS} -StatusFunc ${function:Get-VBSStatus} }
        "2" { ConfigureFeature -FeatureName "HVCI" -EnableFunc ${function:Enable-HVCI} -DisableFunc ${function:Disable-HVCI} -StatusFunc ${function:Get-HVCIStatus} }
        "3" { ConfigureFeature -FeatureName "Windows Hello Protection" -EnableFunc ${function:Enable-WindowsHello} -DisableFunc ${function:Disable-WindowsHello} -StatusFunc ${function:Get-WindowsHelloStatus} }
        "4" { ConfigureFeature -FeatureName "System Guard" -EnableFunc ${function:Enable-SystemGuard} -DisableFunc ${function:Disable-SystemGuard} -StatusFunc ${function:Get-SystemGuardStatus} }
        "5" { ConfigureFeature -FeatureName "Credential Guard" -EnableFunc ${function:Enable-CredentialGuard} -DisableFunc ${function:Disable-CredentialGuard} -StatusFunc ${function:Get-CredentialGuardStatus} }
        "6" { ConfigureFeature -FeatureName "KVA Shadow" -EnableFunc ${function:Enable-KVAShadow} -DisableFunc ${function:Disable-KVAShadow} -StatusFunc ${function:Get-KVAShadowStatus} }
        "7" { ConfigureFeature -FeatureName "Windows Hypervisor" -EnableFunc ${function:Enable-Hypervisor} -DisableFunc ${function:Disable-Hypervisor} -StatusFunc ${function:Get-HypervisorStatus} }
        "0" { return }
        default { Write-Host "Opción inválida" -ForegroundColor Red; pause }
    }
}

function ConfigureFeature {
    param(
        [string]$FeatureName,
        [scriptblock]$EnableFunc,
        [scriptblock]$DisableFunc,
        [scriptblock]$StatusFunc
    )
    
    Show-Title
    $currentStatus = & $StatusFunc
    $statusText = if ($currentStatus) { "ACTIVO" } else { "INACTIVO" }
    $statusColor = if ($currentStatus) { "Green" } else { "Red" }
    
    Write-Host "Configurando: $FeatureName" -ForegroundColor Cyan
    Write-Host "Estado Actual: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
    Write-Host ""
    Write-Host "[1] Activar"
    Write-Host "[2] Desactivar"
    Write-Host "[0] Volver"
    Write-Host "----------------------------------"
    $option = Read-Host "Selecciona una opcion"
    
    switch ($option) {
        "1" {
            Write-Host "Activando $FeatureName..." -ForegroundColor Yellow
            & $EnableFunc
            pause
        }
        "2" {
            Write-Host "Desactivando $FeatureName..." -ForegroundColor Yellow
            & $DisableFunc
            pause
        }
        "0" { return }
        default { Write-Host "Opcion invalida" -ForegroundColor Red; pause }
    }
}

function Enable-AllFeatures {
    Show-Title
    Write-Host "ACTIVANDO TODAS LAS CARACTERISTICAS..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Activando VBS..." -NoNewline
    if (Enable-VBS) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando HVCI..." -NoNewline
    if (Enable-HVCI) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando Windows Hello..." -NoNewline
    if (Enable-WindowsHello) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando System Guard..." -NoNewline
    if (Enable-SystemGuard) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando Credential Guard..." -NoNewline
    if (Enable-CredentialGuard) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando KVA Shadow..." -NoNewline
    if (Enable-KVAShadow) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Activando Hypervisor..." -NoNewline
    if (Enable-Hypervisor) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host ""
    Write-Host "NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios." -ForegroundColor Yellow
    Write-Log "Todas las caracteristicas han sido activadas" "Info"
    pause
}

function Disable-AllFeatures {
    Show-Title
    Write-Host "DESACTIVANDO TODAS LAS CARACTERISTICAS..." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Estoy seguro? Esto desactivara TODAS las protecciones de seguridad. (s/n)"
    if ($confirm -ne 's') {
        Write-Host "Operacion cancelada" -ForegroundColor Yellow
        pause
        return
    }
    
    Write-Host "Desactivando VBS..." -NoNewline
    if (Disable-VBS) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando HVCI..." -NoNewline
    if (Disable-HVCI) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando Windows Hello..." -NoNewline
    if (Disable-WindowsHello) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando System Guard..." -NoNewline
    if (Disable-SystemGuard) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando Credential Guard..." -NoNewline
    if (Disable-CredentialGuard) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando KVA Shadow..." -NoNewline
    if (Disable-KVAShadow) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host "Desactivando Hypervisor..." -NoNewline
    if (Disable-Hypervisor) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FAIL]" -ForegroundColor Red }
    
    Write-Host ""
    Write-Host "NOTA: Es posible que sea necesario reiniciar el sistema para aplicar los cambios." -ForegroundColor Yellow
    Write-Log "Todas las caracteristicas han sido desactivadas" "Warning"
    pause
}

function Show-Log {
    Show-Title
    Write-Host "REGISTRO DE ACTIVIDADES" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $script:LogFile) {
        Get-Content -Path $script:LogFile | ForEach-Object {
            if ($_ -match '\[Error\]') {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -match '\[Success\]') {
                Write-Host $_ -ForegroundColor Green
            } elseif ($_ -match '\[Warning\]') {
                Write-Host $_ -ForegroundColor Yellow
            } else {
                Write-Host $_
            }
        }
    } else {
        Write-Host "No hay registro aún." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    pause
}

function Restart-Normal {
    Show-Title
    Write-Host "REINICIO DEL SISTEMA" -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-Host "¿Deseas reiniciar el equipo ahora? (s/n)"
    if ($confirm -ne 's') {
        Write-Host "Operacion cancelada" -ForegroundColor Yellow
        Start-Sleep 1
        return
    }

    Write-Log "Reinicio normal ejecutado" "Info"
    Write-Host "Reiniciando..." -ForegroundColor Cyan

    shutdown /r /t 0
}

function Restart-Advanced {
    Show-Title
    Write-Host "REINICIO AVANZADO (MODO DIRECTO F7)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "El sistema realizara un reinicio doble automatico." -ForegroundColor Cyan
    Write-Host "En el segundo arranque entraras DIRECTAMENTE al menu F7." -ForegroundColor Cyan
    Write-Host ""

    $confirm = Read-Host "¿Deseas continuar? (s/n)"
    if ($confirm -ne 's') {
        Write-Host "Operacion cancelada" -ForegroundColor Yellow
        Start-Sleep 1
        return
    }

    try {
        # Programar comandos para el siguiente inicio
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
            /v "ADVBOOT1" `
            /t REG_SZ `
            /d "bcdedit /set {current} onetimeadvancedoptions on" `
            /f | Out-Null

        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
            /v "ADVBOOT2" `
            /t REG_SZ `
            /d "shutdown /r /t 0" `
            /f | Out-Null

        Write-Log "Reinicio avanzado programado (doble reboot)" "Warning"

        Write-Host ""
        Write-Host "Primer reinicio..." -ForegroundColor Green
        Write-Host "NO presiones nada, el sistema se reiniciara automaticamente otra vez." -ForegroundColor Yellow

        Start-Sleep 2
        shutdown /r /t 0
    }
    catch {
        Write-Log "Error en reinicio avanzado: $_" "Error"
        Write-Host "Error al configurar reinicio avanzado" -ForegroundColor Red
        pause
    }

}
# ========================================
# PROGRAMA PRINCIPAL
# ========================================

function Main {
    Check-Admin
    
    do {
        Show-Menu
        $mainChoice = Read-Host "Selecciona una opción"
        
        switch ($mainChoice) {
            "1" { Show-Status }
            "2" { Enable-AllFeatures }
            "3" { Disable-AllFeatures }
            "4" { Show-IndividualConfig }
            "5" {
                Show-Title
                Write-Host "Ejecutando verificacion y reparacion..." -ForegroundColor Yellow
                Enable-AllFeatures
            }
            "6" { Show-Log }
            "7" { Restart-Normal }
            "8" { Restart-Advanced }
            "0" {
                Write-Host "Hasta luego!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "Opcion invalida" -ForegroundColor Red
                pause
            }
        }
    } while ($true)
}

# Iniciar programa
Main
