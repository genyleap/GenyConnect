![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect es un cliente moderno y multiplataforma de conectividad segura para redes privadas y comunicaciones cifradas, creado con un fuerte enfoque en rendimiento, privacidad y gestión precisa del tráfico.

Proporciona una potente capa de orquestación para motores de red segura y tunelización, con énfasis en fiabilidad, observabilidad, transparencia operativa y experiencia de usuario, sin depender de ningún protocolo, tecnología o implementación específica.

GenyConnect se desarrolla en dos direcciones: una Community Edition para usuarios individuales y necesidades cotidianas de conectividad, y una Commercial & Enterprise Edition diseñada para organizaciones que requieren gestión centralizada, políticas de red, control de acceso y comunicaciones seguras a gran escala.

<p align="left">
  <a href="https://en.cppreference.com/w/cpp/23">
    <img
      alt="C++23"
      src="https://img.shields.io/badge/C%2B%2B-23-00599C?style=for-the-badge&logo=cplusplus"
    />
  </a>

  <a href="https://cmake.org/">
    <img
    alt="CMake 4.2+"
    src="https://img.shields.io/badge/CMake-4.2%2B-00599C?style=for-the-badge&logo=cmake"
    />
  </a>

  <a href="https://www.qt.io/">
    <img
      alt="Qt 6"
      src="https://img.shields.io/badge/Qt-6-41CD52?style=for-the-badge&logo=qt"
    />
  </a>

  <a href="../LICENSE">
    <img
      alt="License GPL-3.0-or-later"
      src="https://img.shields.io/badge/License-GPL--3.0--or--later-8E44AD?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/actions">
    <img
      alt="Build Passing"
      src="https://img.shields.io/badge/Build-Passing-27AE60?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/pulls">
    <img
      alt="PRs Welcome"
      src="https://img.shields.io/badge/PRs-Welcome-F39C12?style=for-the-badge"
    />
  </a>
</p>


---

## Descripción general

GenyConnect permite establecer y gestionar conexiones seguras mediante perfiles de servidor estructurados y enlaces de configuración compartibles.

Las configuraciones de runtime se generan dinámicamente, los ciclos de vida de conexión se supervisan de forma explícita y el estado del sistema permanece siempre completamente observable.

La plataforma es intencionadamente engine-agnostic, lo que permite integrar distintos backends de tunelización sin cambiar los flujos de usuario ni el comportamiento esperado.

GenyConnect no se limita a un caso de uso genérico de tunelización. Su dirección a largo plazo es convertirse en una capa inteligente de conectividad para gestionar el acceso a servicios, infraestructura privada, recursos cloud y equipos distribuidos que necesitan comunicación estable y fiable.

En el rango de versiones 1.4 y 1.5, se espera que GenyConnect madure para un uso público más amplio y cubra una parte sustancial de las necesidades de usuarios que requieren conexiones confiables. En futuras versiones también se planea añadir Persian y más idiomas dentro de la aplicación.

La segunda generación de GenyConnect se centrará más profundamente en necesidades comerciales y organizativas, incluyendo gestión de acceso, personalización de infraestructura de comunicación, resiliencia de red, reducción de dependencia de servicios externos y estabilidad de conexión bajo distintas condiciones de red. También se planea que futuras versiones soporten el formato dedicado `gen.` y la arquitectura de comunicación propia de GenyConnect para definir y gestionar redes privadas y accesos organizativos.

---

## Capacidades clave

- Visibilidad operativa clara
  - registros en vivo
  - estadísticas de tráfico en tiempo real
  - informes explícitos del estado de conexión

- Ejecución de alto rendimiento
  - runtime ligero
  - sobrecarga mínima
  - respuesta ágil bajo cargas sostenidas

- Gestión determinista del ciclo de vida
  - inicio predecible
  - apagado limpio
  - lógica segura de reconexión

- Enrutamiento avanzado de tráfico
  - enrutamiento basado en whitelist
  - reglas tunnel/direct/block a nivel de dominio
  - enrutamiento por aplicación cuando esté soportado
  - enrutamiento por proceso cuando esté soportado

- Modos de tunelización flexibles
  - proxy a nivel de aplicación
  - tunelización completa del sistema
  - superficie de control coherente

- LAN Sharing
  - compartir el tráfico gestionado por GenyConnect con otros dispositivos de la red local
  - soportar consolas de videojuegos, televisores inteligentes, teléfonos, tabletas, portátiles y equipos de escritorio
  - controles avanzados de compartición para entornos de red gestionados

- Arquitectura multiplataforma
  - runtime core compartido
  - adaptadores desktop y mobile
  - integraciones específicas de plataforma

---

## Power Mode

GenyConnect incluye un sistema Power Mode consciente de la plataforma, diseñado para mejorar la estabilidad de conexión y la consistencia del runtime durante cargas sostenidas.

Power Mode ayuda a reducir la interferencia del sistema operativo causada por ahorro de energía agresivo, limitación en segundo plano, suspensión por inactividad y transiciones a estados de reposo.

Según el sistema operativo y el runtime backend, Power Mode puede:

- mantener receptivas las rutas de red críticas
- reducir desconexiones inesperadas
- mejorar la consistencia del rendimiento
- optimizar sesiones largas de tráfico
- minimizar picos de latencia durante actividad intensa
- mejorar la fiabilidad del runtime durante la tunelización

El comportamiento de Power Mode es adaptativo y puede variar según las capacidades de la plataforma y las restricciones del sistema operativo.

---

## Capturas de pantalla

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Compatibilidad de plataformas

GenyConnect actualmente soporta:

- macOS
- Windows
- Linux
- Android

La compatibilidad con iOS está en desarrollo activo.

---

## Stack tecnológico

- C++23
- Qt 6 / QML
- Arquitectura runtime nativa multiplataforma
- Pipelines de despliegue multiplataforma
- Integración de backend de tunelización engine-agnostic

---

## Licenciamiento

GenyConnect Community Edition está licenciado bajo GNU General Public License versión 3 o posterior (GPL-3.0-or-later).

Las licencias comerciales están disponibles por separado a través de Genyleap Labs para:

- despliegues propietarios
- redistribución closed-source
- integraciones empresariales
- productos white-label
- distribución en App Store
- ediciones comerciales
- funciones Pro o Enterprise

Salvo que se indique explícitamente lo contrario, lo siguiente NO está cubierto por la licencia GPL y permanece All Rights Reserved:

- nombre GenyConnect
- logotipos
- iconos
- capturas de pantalla
- diseño visual
- activos de marca
- gráficos promocionales
- arte de UI
- materiales de identidad visual
- activos de marketing

Los forks y redistribuciones no pueden implicar respaldo de Genyleap Labs ni afiliación con ella sin permiso explícito por escrito.

Consulte los archivos LICENSE y NOTICE para ver los detalles completos de licencia.

### Resumen de licencia

Código fuente de Community Edition:
- GPL-3.0-or-later

Licencia comercial:
- Licencia comercial propietaria separada

Activos de marca y no relacionados con código:
- All Rights Reserved

---

## ❤️ Apoya GenyConnect

GenyConnect es un proyecto desarrollado de forma independiente por Genyleap Labs.

Si GenyConnect te ayuda, puedes apoyar su desarrollo continuo donando con $GENY o USDC en Base Network.

Tu apoyo ayuda a financiar:

- desarrollo continuo
- mejoras de seguridad
- soporte para plataformas desktop y mobile
- infraestructura y pruebas
- futuras versiones open-source
- crecimiento a largo plazo del ecosistema

---

## 🌐 Apoya con $GENY

Al donar con $GENY, apoyas tanto el desarrollo de GenyConnect como el ecosistema Geny más amplio.

### Base Mainnet

Contrato del token GENY:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Billetera de donaciones para desarrollador:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Comprar o intercambiar $GENY para el ecosistema Genyleap

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 Apoya con USDC

USDC es una forma estable y sencilla de apoyar directamente el desarrollo.

### Base Mainnet

Billetera de donaciones para desarrollador:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Aviso sobre donaciones

Las donaciones son contribuciones voluntarias para apoyar el desarrollo de GenyConnect.

No representan:

- inversión
- capital
- propiedad
- participación en ingresos
- valores
- productos financieros
- promesas de retorno financiero

📢 Sigue las actualizaciones de desarrollo, anuncios y futuros lanzamientos en Telegram y Farcaster:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Tus comentarios y apoyo ayudan a dar forma al futuro de GenyConnect y del ecosistema Genyleap más amplio. 🚀
