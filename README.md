# HyperVision
### Windows Security Features Manager
> Gestor interactivo de características de seguridad de Windows

<img width="820" height="913" alt="Captura de pantalla 2026-04-01 084732" src="https://github.com/user-attachments/assets/3b8b9bef-8ab9-4c48-9948-8a81ebc10226" />

---
<img width="820" height="910" alt="image" src="https://github.com/user-attachments/assets/2f618738-88ca-40d2-aec2-0511adcea926" />


## ¿Qué es HyperVision?

**HyperVision** es un script interactivo de línea de comandos que permite ver el estado, activar y desactivar las protecciones de seguridad basadas en virtualización de Windows, con verificaciones previas que evitan cambios inútiles o situaciones problemáticas al reiniciar.

Está pensado para usuarios que necesitan gestionar estas configuraciones de forma controlada, con la posibilidad de revertir cualquier cambio al estado original del sistema.

---

## 🔐 Características gestionadas

| Característica | Descripción |
|---|---|
| **VBS** (Virtualization-Based Security) | Aislamiento de memoria crítica mediante el hypervisor |
| **HVCI / Memory Integrity** | Protección del kernel contra drivers no confiables |
| **Windows Hello Protection** | Protección de autenticación biométrica y PIN |
| **System Guard Secure Launch** | Verificación de integridad del sistema en el arranque |
| **Credential Guard** | Aislamiento de credenciales del sistema |
| **KVA Shadow** | Mitigación de la vulnerabilidad Meltdown |
| **Windows Hypervisor** | Control del hipervisor de Windows |

---

## 🧠 ¿Qué es VBS y HVCI?

**VBS (Virtualization-Based Security)** usa el hypervisor de Windows para crear una región de memoria aislada donde se ejecutan componentes críticos del sistema, protegiendo credenciales y procesos incluso si el sistema es comprometido.

**HVCI (Memory Integrity)** se apoya en VBS para validar que solo drivers y código de confianza puedan ejecutarse en el kernel, bloqueando la inyección de código malicioso en tiempo de ejecución.

Juntos, reducen significativamente la superficie de ataque frente a malware avanzado y ataques a nivel kernel.

---

## 📋 Funcionalidades del menú

### 🔍 1. Ver estado del sistema
Muestra el estado actual de todas las protecciones, incluyendo:
- Si la virtualización está habilitada en BIOS
- Si alguna característica tiene UEFI Lock activo
- Si BitLocker está activo en la unidad del sistema

### ✅ 2. Activar todas las características
Habilita todas las protecciones disponibles. Advierte si VT-x no está activo en BIOS antes de proceder.

### ⚠️ 3. Desactivar todas las características
Desactiva todas las protecciones con confirmación previa. Incluye:
- Detección y omisión de características con UEFI Lock
- Suspensión automática de BitLocker antes del reinicio avanzado
- Arranque directo en Startup Settings para desactivar la firma de controladores (F7)

### 🔁 4. Revertir cambios
Restaura **únicamente** las características que el propio script desactivó, respetando el estado original del sistema. No activa características que ya estaban desactivadas antes de ejecutar el script.

---

## 🛡️ Verificaciones de seguridad integradas

HyperVision realiza las siguientes comprobaciones automáticas antes de aplicar cambios:

- **VT-x / SVM en BIOS** — Detecta si la virtualización está habilitada en el firmware. Sin ella, activar VBS desde el registro no tiene efecto.
- **UEFI Lock** — Identifica si VBS, HVCI o Credential Guard están bloqueadas por firmware. Las omite en lugar de escribir cambios inútiles en el registro.
- **BitLocker** — Si está activo, lo suspende automáticamente por dos ciclos de arranque para evitar que Windows solicite la clave de recuperación al entrar al menú avanzado.
- **HypervisorLaunchType exacto** — Al revertir, restaura el valor original del hypervisor en lugar de asumir siempre `auto`.

---

## ⚙️ Requisitos

- Windows 10 / Windows 11
- CPU con virtualización habilitada en BIOS (Intel VT-x / AMD-V)
- PowerShell disponible en el sistema
- **⚠️ Ejecutar como Administrador (obligatorio)**

---

## ❗ Advertencias

- Algunos cambios requieren reinicio para aplicarse
- Desactivar las protecciones reduce la seguridad del sistema
- HVCI puede no activarse si existen drivers incompatibles instalados
- Se recomienda **desconectarse de internet** mientras las protecciones están deshabilitadas

---

## 📌 Notas técnicas

- El script guarda el estado previo en `HKLM\SOFTWARE\ManageVBS` antes de realizar cambios
- La clave se elimina automáticamente una vez que todos los cambios son revertidos exitosamente
- No instala software, no modifica archivos del sistema, solo cambia configuraciones internas de Windows y el BCD

---

## 📄 Licencia

Uso libre bajo tu responsabilidad.

---


## 👨‍💻 Autor ModGames44

NOTA: DESCONECTAR INTERNET ANTES DE SEGUIR CON LOS PASOS

Desarrollado para control avanzado de seguridad en sistemas Windows.

# 📘 Tutorial de uso — HyperVision v2.0

> ⚠️ **DESCONECTA INTERNET ANTES DE SEGUIR CON LOS PASOS**

---

## ⚠️ Requisito obligatorio

**Ejecutar siempre como Administrador.**

Sin privilegios elevados el script no podrá modificar el registro, el BCD ni las políticas de seguridad del sistema, y fallará al intentar aplicar cualquier cambio.

---

## 🧠 Contexto importante

Protecciones como **VBS** y **HVCI** usan la virtualización del procesador para aislar memoria crítica del sistema y bloquear drivers no firmados o inseguros, evitando ataques a nivel kernel.

Cuando las desactivas, Windows puede seguir bloqueando ciertos drivers hasta que se use el **modo especial F7** en el arranque. Por eso la opción **[3]** incluye un reinicio directo al menú avanzado.

---

## 🔍 Antes de hacer cualquier cambio — Opción 1

Usa siempre **[1] Ver Estado** primero. Te mostrará:

- Si la virtualización está habilitada en tu BIOS
- Si alguna protección tiene **UEFI Lock** activo (en ese caso no puede desactivarse por registro)
- Si **BitLocker** está activo (el script lo maneja automáticamente, pero es útil saberlo)
- El estado actual de cada protección

---

## 🔻 Desactivar protecciones — Opción 3

Usa **[3] Desactivar Todas las Características** cuando necesites operar con drivers o configuraciones que entran en conflicto con VBS/HVCI.

**¿Qué hace el script automáticamente?**
- Guarda el estado actual de cada protección para poder revertirlo después
- Omite las características con UEFI Lock en lugar de escribir cambios inútiles
- Suspende BitLocker si está activo, para evitar que pida clave de recuperación al reiniciar
- Configura el arranque para entrar directamente a **Startup Settings**

**Al reiniciar, cuando aparezca el menú:**
> 👉 Presiona **F7 → Deshabilitar uso obligatorio de controladores firmados**

Esto es necesario porque HVCI puede seguir bloqueando drivers aunque esté desactivado por registro, hasta que se complete el arranque con firma deshabilitada.

---

## ✅ Restaurar protecciones — Opción 2 o Opción 4

Cuando quieras volver al estado seguro tienes dos caminos:

### Opción 2 — Activar todas las características
Enciende **todas** las protecciones sin importar cuál estaba activa antes. Útil si quieres partir desde un estado máximo de seguridad.

### Opción 4 — Revertir cambios
Restaura **únicamente** lo que el script desactivó, respetando el estado original del sistema. Si alguna protección ya estaba desactivada antes de ejecutar el script, esta opción no la toca.

> 💡 **Recomendación:** usa **[4] Revertir** si quieres volver exactamente al estado en que estaba tu sistema antes. Usa **[2] Activar Todo** solo si quieres asegurarte de que todo está encendido.

Después de cualquiera de las dos opciones, reinicia el equipo cuando el script lo indique para aplicar los cambios.

---

## 🧾 Resumen rápido

| Acción | Opción |
|---|---|
| Ver estado del sistema | **[1]** |
| Activar todas las protecciones | **[2]** |
| Desactivar todas las protecciones + reinicio F7 | **[3]** |
| Revertir solo los cambios del script | **[4]** |

---

## ⚠️ Notas importantes

- El modo F7 es **temporal** — solo dura esa sesión de arranque
- Si HVCI no se reactiva después de usar **[2]** o **[4]**, es probable que haya drivers incompatibles instalados en el sistema
- Desactivar estas protecciones **reduce la seguridad del equipo** — vuelve a activarlas cuando ya no las necesites desactivadas
- Mantén el **internet desconectado** mientras las protecciones están inhabilitadas

---

## 💡 Recomendación final

Usa este flujo solo cuando sea estrictamente necesario y vuelve a activar las protecciones una vez que hayas terminado.
