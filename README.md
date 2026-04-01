# HyperVision v2.0
### Windows Security Features Manager
> Gestor interactivo de características de seguridad de Windows

---

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

## 👨‍💻 Autor

**ModGames44**
## 👨‍💻 Autor ModGames44

NOTA: DESCONECTAR INTERNET ANTES DE SEGUIR CON LOS PASOS

Desarrollado para control avanzado de seguridad en sistemas Windows.

📘 Tutorial de uso – Flujo correcto del programa
⚠️ Requisito obligatorio

Antes de usar el programa:

👉 Ejecutar siempre como Administrador

Si no se ejecuta con privilegios elevados:

❌ No podrá modificar el sistema
❌ Fallarán los cambios de seguridad
❌ El script no funcionará correctamente
🧠 Contexto importante

Las protecciones como:

VBS (Virtualization-Based Security)
HVCI / Integridad de memoria

usan virtualización para bloquear drivers no firmados o inseguros, evitando ataques a nivel kernel

👉 Por eso, cuando las desactivas:

Windows sigue bloqueando ciertos drivers hasta usar modo especial (F7)
🚀 Flujo correcto de uso
🔻 1. Desactivar protecciones

Usa:

👉 Opción 3 – Desactivar todas las características

Esto:

Desactiva VBS
Desactiva HVCI
Desactiva protecciones avanzadas
⚠️ 2. IMPORTANTE: Reinicio especial obligatorio

Después de usar la opción 3:

👉 Debes usar Opción 8 – Reinicio avanzado

¿Qué hace?
Ejecuta un doble reinicio automático
Te lleva directamente a:

👉 Startup Settings (pantalla negra)

🎯 3. En el menú avanzado

Cuando aparezca el menú:

👉 Presiona:

F7 → Deshabilitar uso obligatorio de controladores firmados
🧠 ¿Por qué es necesario?

Porque HVCI evita que drivers no firmados se carguen

👉 Sin F7:

Algunos drivers seguirán bloqueados
El cambio no será completo
🔁 Cómo revertir los cambios (volver a estado seguro)

Cuando quieras restaurar la seguridad:

✅ 1. Activar protecciones

👉 Usa:

Opción 2 – Activar todas las características

🔄 2. Reiniciar normalmente

👉 Luego usa:

Opción 7 – Reinicio normal

✔️ Resultado esperado

Después del reinicio:

VBS activo
HVCI activo (si no hay drivers incompatibles)
Sistema protegido nuevamente
⚠️ Notas importantes
Si HVCI no se activa:
👉 Hay drivers incompatibles que debes corregir
Desactivar estas protecciones:
👉 Reduce la seguridad del sistema
El modo F7 es temporal
👉 Solo dura esa sesión de arranque
🧾 Resumen rápido
Acción	Opción
Desactivar seguridad	3
Reinicio especial (F7)	8
Activar seguridad	2
Reinicio normal	7
💡 Recomendación final

Usa este flujo solo cuando sea necesario (drivers, pruebas, etc.)
y vuelve a activar las protecciones después.
