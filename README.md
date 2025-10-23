# Herramientas WSL ↔ RSAD (Windows) — diagnóstico y desinstalación

[![License: Unlicense](https://img.shields.io/badge/License-Unlicense-blue.svg)](LICENSE)
![OS: Windows 10/11](https://img.shields.io/badge/OS-Windows%2010/11-0078D6)
![Shell: Batch](https://img.shields.io/badge/Shell-Batchfile-555555)
![Status: Stable](https://img.shields.io/badge/Status-Stable-brightgreen)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

## ¿Qué es esto y por qué existe?

Algunos entornos corporativos que usan **IBM Rational Software Architect Designer (RSAD)** o servidores locales (WebSphere/Liberty, etc.) pueden tener **conflictos** cuando **WSL/Hyper-V** está activo: adaptador de red `vEthernet (WSL)`, cambios de rutas/DNS, colisiones de puertos, y choques con VPN/EDR.

Este repo trae dos utilidades:
1. **`diagnostico_wsl_rsad_pascal.bat`** — analiza tu equipo y **detecta** signos típicos de conflicto (sin cambiar nada).
2. **`desinstalar_wsl_completo.bat`** — hace una **desinstalación completa de WSL** (características, servicios, distros y restos), para dejar Windows “limpio” cuando soporte lo pida.

> **Nota**: siempre es preferible **hacer los cambios a mano** y entenderlos. Estas herramientas están pensadas para **ahorrar tiempo** en diagnóstico y, si hace falta, ejecutar una desinstalación controlada.

---

## ¿Para quién está pensado?

- Personas con Windows 10/11 que **no son técnicas** pero necesitan una guía clara.
- Soporte/IT que quiere **probar si WSL/Hyper-V está causando el problema**.
- Quien necesite **retirar WSL por completo** para descartar incompatibilidades.

---

## Archivos del repositorio

- `diagnostico_wsl_rsad_pascal.bat`  
  No hace cambios. Comprueba:
  - Estado de **WSL** y **Virtual Machine Platform**.
  - Servicios **LxssManager** y **vmcompute**.
  - Adaptador **vEthernet (WSL)**, **ruta por defecto** y presencia de **VPN**.
  - **Puertos** típicos de RSAD/WebSphere (9080, 9443, 9060, 2809, 7777, 7001).
  - Pistas de **Docker** y rutas “Unix” en el **PATH** (Git, MSYS2, Cygwin).

- `desinstalar_wsl_completo.bat`  
  Apaga WSL, **desregistra** todas las distros, **desinstala** paquetes relacionados (WSL/WSLg/distros Store), **deshabilita** características (WSL/Virtual Machine Platform), y borra restos de configuración. Requiere **ejecutar como Administrador** y **reiniciar**.

---

## Requisitos

- **Windows 10/11**.
- Para el desinstalador: abrir el `.bat` **como Administrador**.
- Conexión a Internet **no necesaria**.

---

## Uso rápido

### 1) Diagnóstico (recomendado primero)
1. Descarga y haz doble clic en `diagnostico_wsl_rsad_pascal.bat`.  
2. Se abrirá una ventana y generará un informe en tu **Escritorio** (o Documentos si el Escritorio está redirigido).  
3. El informe se abre automáticamente en el **Bloc de notas**.

**Interpretación del informe:**
- Las líneas comienzan con:
  - `[OK]` → todo bien.
  - `[ADVERTENCIA]` → algo a vigilar (no necesariamente un fallo).
  - `[PROBLEMA]` → conflicto que suele afectar a RSAD/servidores locales.

**Casos típicos:**
- `[PROBLEMA] La ruta por defecto pasa por WSL` → puede romper VPN/servidores de desarrollo.
- `[PROBLEMA] Puerto 9080 en uso…` → otro proceso ocupa el puerto que RSAD/websphere quiere.
- `[ADVERTENCIA] vEthernet (WSL) activo` → si no usas WSL ahora, desactívalo y prueba.
- `[ADVERTENCIA] Rutas Unix en PATH` → instaladores/scripts podrían llamar a herramientas “equivocadas”.

El script termina con:
- **0** → sin problemas ni advertencias.
- **1** → solo advertencias.
- **2** → hay al menos un problema.

### 2) Desinstalación completa de WSL (si te lo pide soporte o lo decides)
> ⚠️ **Esto borra TODAS tus distros WSL** (datos incluidos). Haz copia:  
> `wsl --export <Distro> C:\ruta\backup.tar`

1. Clic derecho en `desinstalar_wsl_completo.bat` → **Ejecutar como administrador**.  
2. Deja que termine y **reinicia** el equipo.  
3. (Opcional) Si más adelante quieres volver a usar WSL:
   - Activa características y reinstala desde Microsoft Store:
     - Abrir **PowerShell (Admin)**  
       `dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /featurename:VirtualMachinePlatform /All /NoRestart`  
     - Reiniciar y luego instalar tu distro.

---

## Preguntas frecuentes

**¿Necesito IBM RSAD para usar estas herramientas?**  
No. El diagnóstico busca **síntomas de conflicto** comunes aunque no tengas RSAD.

**¿Puedo perder datos?**  
El **diagnóstico no**. La **desinstalación sí** (elimina distros WSL). Exporta lo que necesites antes.

**¿Qué pasa si uso VPN corporativa?**  
Si la ruta por defecto va por `vEthernet (WSL)`, es frecuente perder conectividad hacia recursos corporativos. El informe lo marcará.

**¿Puedo revertir la desinstalación?**  
Sí, pero **reinstalarás WSL desde cero** y tendrás que **importar** tus copias de seguridad (`wsl --import`).

---

## Descargo de responsabilidad

- Este proyecto se ofrece **“tal cual está, sin actualizaciones ni mejoras”** y **bajo tu responsabilidad**.  
- Es **mejor realizar los cambios a mano** cuando sea posible y comprender su impacto.  
- Respeta siempre las **políticas de tu empresa** y solicita autorización de IT antes de usar la desinstalación.

---

## Licencia

Este proyecto está bajo **The Unlicense** (dominio público). Consulta el archivo [LICENSE](LICENSE).
