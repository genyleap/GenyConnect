![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect est un client de connectivité sécurisé, moderne et multiplateforme pour les réseaux privés et les communications chiffrées, conçu avec un fort accent sur les performances, la confidentialité et la gestion précise du trafic.

Il fournit une puissante couche d’orchestration pour les moteurs de réseau sécurisé et de tunneling, en mettant l’accent sur la fiabilité, l’observabilité, la transparence opérationnelle et l’expérience utilisateur, tout en restant indépendant de tout protocole, technologie ou implémentation spécifique.

GenyConnect est développé dans deux directions : une Community Edition pour les utilisateurs individuels et les besoins de connectivité quotidiens, et une Commercial & Enterprise Edition destinée aux organisations qui nécessitent une gestion centralisée, des politiques réseau, un contrôle d’accès et des communications sécurisées à grande échelle.

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

## Vue d’ensemble

GenyConnect permet aux utilisateurs d’établir et de gérer des connexions sécurisées au moyen de profils de serveur structurés et de liens de configuration partageables.

Les configurations d’exécution sont générées dynamiquement, les cycles de vie des connexions sont supervisés explicitement et l’état du système reste entièrement observable à tout moment.

La plateforme est volontairement engine-agnostic, ce qui permet d’intégrer différents backends de tunneling sans modifier les flux utilisateur ni le comportement attendu.

GenyConnect ne se limite pas à un cas d’usage générique de tunneling. Son orientation à long terme est de devenir une couche de connectivité intelligente pour gérer l’accès aux services, aux infrastructures privées, aux ressources cloud et aux équipes distribuées qui nécessitent une communication stable et fiable.

Autour des versions 1.4 et 1.5, GenyConnect devrait atteindre une maturité plus large pour l’usage public et couvrir une part importante des besoins des utilisateurs qui exigent des connexions fiables. Les futures versions prévoient aussi l’ajout du Persian et d’autres langues dans l’application.

La deuxième génération de GenyConnect se concentrera davantage sur les besoins commerciaux et organisationnels, notamment la gestion des accès, la personnalisation de l’infrastructure de communication, la résilience réseau, la réduction de la dépendance aux services externes et la stabilité de la connectivité dans des conditions réseau variables. Les futures versions prévoient également la prise en charge du format dédié `gen.` et de l’architecture de communication propre à GenyConnect pour définir et gérer les réseaux privés et les accès organisationnels.

---

## Fonctionnalités clés

- Visibilité opérationnelle claire
  - journaux en direct
  - statistiques de trafic en temps réel
  - rapports explicites sur l’état de connexion

- Exécution haute performance
  - runtime léger
  - surcharge minimale
  - réactivité sous charges prolongées

- Gestion déterministe du cycle de vie
  - démarrage prévisible
  - arrêt propre
  - logique de reconnexion sûre

- Routage avancé du trafic
  - routage basé sur whitelist
  - règles tunnel/direct/block au niveau du domaine
  - routage par application lorsque pris en charge
  - routage par processus lorsque pris en charge

- Modes de tunneling flexibles
  - proxy au niveau applicatif
  - tunneling complet du système
  - surface de contrôle cohérente

- LAN Sharing
  - partager le trafic géré par GenyConnect avec d’autres appareils du réseau local
  - prendre en charge les consoles de jeu, téléviseurs connectés, téléphones, tablettes, ordinateurs portables et ordinateurs de bureau
  - contrôles avancés de partage pour les environnements réseau administrés

- Architecture multiplateforme
  - runtime core partagé
  - adaptateurs desktop et mobile
  - intégrations propres aux plateformes

---

## Power Mode

GenyConnect inclut un système Power Mode conscient de la plateforme, conçu pour améliorer la stabilité des connexions et la cohérence du runtime lors de charges prolongées.

Power Mode aide à réduire les interférences du système d’exploitation dues aux politiques agressives d’économie d’énergie, au throttling en arrière-plan, à la suspension en inactivité et aux transitions vers le sommeil.

Selon le système d’exploitation et le runtime backend, Power Mode peut :

- maintenir la réactivité des chemins réseau critiques
- réduire les déconnexions inattendues
- améliorer la régularité du débit
- optimiser les longues sessions de trafic
- minimiser les pics de latence en forte activité
- améliorer la fiabilité du runtime pendant le tunneling

Le comportement de Power Mode est adaptatif et peut varier selon les capacités de la plateforme et les restrictions du système d’exploitation.

---

## Captures d’écran

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Prise en charge des plateformes

GenyConnect prend actuellement en charge :

- macOS
- Windows
- Linux
- Android

La prise en charge d’iOS est en développement actif.

---

## Pile technologique

- C++23
- Qt 6 / QML
- Architecture runtime native multiplateforme
- Pipelines de déploiement multi-plateformes
- Intégration de backend de tunneling engine-agnostic

---

## Licences

GenyConnect Community Edition est sous licence GNU General Public License version 3 ou ultérieure (GPL-3.0-or-later).

Des licences commerciales sont disponibles séparément auprès de Genyleap Labs pour :

- déploiements propriétaires
- redistribution closed-source
- intégrations d’entreprise
- produits white-label
- distribution App Store
- éditions commerciales
- fonctionnalités Pro ou Enterprise

Sauf indication explicite contraire, les éléments suivants ne sont PAS couverts par la licence GPL et restent All Rights Reserved :

- nom GenyConnect
- logos
- icônes
- captures d’écran
- design visuel
- actifs de marque
- graphiques promotionnels
- illustrations UI
- éléments d’identité visuelle
- actifs marketing

Les forks et redistributions ne peuvent pas suggérer une approbation ou une affiliation avec Genyleap Labs sans autorisation écrite explicite.

Consultez les fichiers LICENSE et NOTICE pour les détails complets de licence.

### Résumé de la licence

Code source Community Edition :
- GPL-3.0-or-later

Licence commerciale :
- Licence commerciale propriétaire séparée

Actifs de marque et hors code :
- All Rights Reserved

---

## ❤️ Soutenir GenyConnect

GenyConnect est un projet développé indépendamment par Genyleap Labs.

Si GenyConnect vous est utile, vous pouvez soutenir son développement continu en donnant en $GENY ou en USDC sur Base Network.

Votre soutien aide à financer :

- développement continu
- améliorations de sécurité
- prise en charge desktop et mobile
- infrastructure et tests
- futures versions open-source
- croissance à long terme de l’écosystème

---

## 🌐 Soutenir avec $GENY

En donnant en $GENY, vous soutenez à la fois le développement de GenyConnect et l’écosystème Geny au sens large.

### Base Mainnet

Contrat du token GENY :

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Portefeuille de don développeur :

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Acheter ou échanger $GENY pour l’écosystème Genyleap

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 Soutenir avec USDC

USDC est un moyen stable et simple de soutenir directement le développement.

### Base Mainnet

Portefeuille de don développeur :

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Avis relatif aux dons

Les dons sont des contributions volontaires destinées à soutenir le développement de GenyConnect.

Ils ne représentent pas :

- investissement
- capital
- propriété
- partage de revenus
- titres financiers
- produits financiers
- promesse de rendement financier

📢 Suivez les mises à jour de développement, les annonces et les futures versions sur Telegram et Farcaster :

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Vos retours et votre soutien contribuent à façonner l’avenir de GenyConnect et de l’écosystème Genyleap au sens large. 🚀
