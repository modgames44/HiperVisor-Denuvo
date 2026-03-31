# HiperVisor-Denuvo
# 🛡️ Windows Security Features Manager

Herramienta en PowerShell para gestionar, reparar y controlar las principales características de seguridad avanzadas de Windows.
<img width="975" height="510" alt="Captura de pantalla 2026-03-24 100928" src="https://github.com/user-attachments/assets/dfefe26a-a042-4c5d-97a3-b8e42a0637b7" />
---

<img width="977" height="509" alt="Captura de pantalla 2026-03-29 130206" src="https://github.com/user-attachments/assets/c1cd701d-6e7a-4d5a-8867-5547b255700f" />

<img width="973" height="507" alt="Captura de pantalla 2026-03-31 082239" src="https://github.com/user-attachments/assets/741fe2a5-eecb-445f-9132-aff09d20c635" />


## 🚀 Descripción

**Windows Security Features Manager** es un script interactivo que permite:

- Ver el estado de seguridad del sistema
- Activar / desactivar protecciones avanzadas
- Reparar configuraciones dañadas
- Reiniciar el sistema en modos específicos (incluyendo modo avanzado F7)

Está diseñado especialmente para escenarios donde:
- Se han modificado configuraciones de seguridad (ej: bypass de VBS)
- HVCI / Memory Integrity no se activa correctamente
- Existen conflictos con drivers o configuraciones del sistema

---

## 🔐 Características gestionadas

El programa permite controlar:

- ✅ VBS (Virtualization-Based Security)
- ✅ HVCI / Memory Integrity
- ✅ Windows Hello Protection
- ✅ System Guard Secure Launch
- ✅ Credential Guard
- ✅ KVA Shadow (Meltdown Mitigation)
- ✅ Windows Hypervisor

---

## 🧠 ¿Qué es VBS y HVCI?

- **VBS (Virtualization-Based Security)** usa el hypervisor de Windows para crear una región de memoria aislada donde se ejecutan componentes críticos del sistema. :contentReference[oaicite:0]{index=0}  
- Esto protege credenciales y procesos incluso si el sistema es comprometido. :contentReference[oaicite:1]{index=1}  
- **HVCI (Memory Integrity)** asegura que solo drivers y código confiable puedan ejecutarse en el kernel. :contentReference[oaicite:2]{index=2}  

👉 En conjunto, reducen significativamente ataques a nivel kernel y malware avanzado.

---

## 📋 Funcionalidades principales

### 🔍 1. Ver estado del sistema
Muestra el estado actual de todas las protecciones.

---

### ⚙️ 2. Activar todas las características
Habilita automáticamente todas las protecciones disponibles.

---

### ⚠️ 3. Desactivar todas las características
Desactiva todas las protecciones (uso bajo tu responsabilidad).

---

### 🧩 4. Configuración individual
Permite activar/desactivar cada feature manualmente.

---

### 🛠️ 5. Verificar y reparar configuración
Intenta restaurar configuraciones de seguridad dañadas o incompletas.

---

### 📄 6. Ver log
Muestra el registro de acciones realizadas por el script.

---

### 🔁 7. Reinicio normal
Reinicia el sistema inmediatamente.

---

### 🔥 8. Reinicio avanzado (modo F7)

- Realiza un **doble reinicio automático**
- Entra directamente en:
  👉 *Startup Settings*
- Permite usar:
  👉 **F7 → Deshabilitar firma de controladores**

✔️ No deja cambios permanentes en el sistema

---

## ⚙️ Requisitos

- Windows 10 / Windows 11
- CPU compatible con virtualización (Intel VT-x / AMD-V)
- PowerShell
- ⚠️ **EJECUTAR COMO ADMINISTRADOR (OBLIGATORIO)**

---

## ❗ IMPORTANTE

Este script realiza cambios en:

- Registro de Windows
- Configuración de arranque (BCD)
- Políticas de seguridad

👉 Ejecutarlo sin privilegios de administrador causará errores o fallos.

---

## 🔐 Seguridad

El script:

✔️ No instala software  
✔️ No modifica archivos del sistema  
✔️ Solo cambia configuraciones internas de Windows  

---

## ⚠️ Advertencias

- Algunos cambios requieren reinicio
- HVCI puede no activarse si existen drivers incompatibles
- Desactivar protecciones reduce la seguridad del sistema

---

## 🧪 Casos de uso

- Reparar VBS/HVCI después de modificaciones
- Diagnóstico de seguridad en Windows
- Preparar entorno para pruebas (drivers, bypass, etc.)
- Restaurar configuración segura del sistema

---

## 📌 Notas técnicas

- VBS utiliza el hypervisor para aislar memoria crítica del sistema
- HVCI valida drivers en tiempo de ejecución
- Credential Guard protege credenciales del sistema
- El modo F7 permite cargar drivers sin firma temporalmente

---

## 📄 Licencia

Uso libre bajo tu responsabilidad.

---

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
