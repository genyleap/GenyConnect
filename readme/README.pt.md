![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect é um cliente moderno e multiplataforma de conectividade segura para redes privadas e comunicações criptografadas, desenvolvido com forte foco em desempenho, privacidade e gerenciamento preciso de tráfego.

Ele fornece uma poderosa camada de orquestração para mecanismos de rede segura e tunelamento, enfatizando confiabilidade, observabilidade, transparência operacional e experiência do usuário, sem depender de qualquer protocolo, tecnologia ou implementação específica.

GenyConnect está sendo desenvolvido em duas direções: uma Community Edition para usuários individuais e necessidades cotidianas de conectividade, e uma Commercial & Enterprise Edition para organizações que exigem gerenciamento centralizado, políticas de rede, controle de acesso e comunicações seguras em grande escala.

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

## Visão geral

GenyConnect permite que usuários estabeleçam e gerenciem conexões seguras por meio de perfis de servidor estruturados e links de configuração compartilháveis.

As configurações de runtime são geradas dinamicamente, os ciclos de vida das conexões são supervisionados explicitamente e o estado do sistema permanece totalmente observável em todos os momentos.

A plataforma é intencionalmente engine-agnostic, permitindo integrar diferentes backends de tunelamento sem alterar os fluxos de usuário ou o comportamento esperado.

GenyConnect não se limita a um caso genérico de tunelamento. Sua direção de longo prazo é ser uma camada inteligente de conectividade para gerenciar acesso a serviços, infraestrutura privada, recursos em nuvem e equipes distribuídas que exigem comunicação estável e confiável.

Na faixa das versões 1.4 e 1.5, espera-se que GenyConnect amadureça para uso público mais amplo e cubra uma parte substancial das necessidades de usuários que exigem conexões confiáveis. Versões futuras também planejam adicionar Persian e outros idiomas dentro do aplicativo.

A segunda geração do GenyConnect terá foco mais profundo em necessidades comerciais e organizacionais, incluindo gerenciamento de acesso, personalização da infraestrutura de comunicação, resiliência de rede, redução da dependência de serviços externos e estabilidade da conectividade sob diferentes condições de rede. Versões futuras também devem oferecer suporte ao formato dedicado `gen.` e à arquitetura de comunicação própria do GenyConnect para definir e gerenciar redes privadas e acessos organizacionais.

---

## Principais recursos

- Visibilidade operacional clara
  - logs ao vivo
  - estatísticas de tráfego em tempo real
  - relatórios explícitos de estado da conexão

- Execução de alto desempenho
  - runtime leve
  - sobrecarga mínima
  - responsivo sob cargas sustentadas

- Gerenciamento determinístico do ciclo de vida
  - inicialização previsível
  - encerramento limpo
  - lógica segura de reconexão

- Roteamento avançado de tráfego
  - roteamento baseado em whitelist
  - regras tunnel/direct/block no nível de domínio
  - roteamento por aplicativo onde houver suporte
  - roteamento por processo onde houver suporte

- Modos flexíveis de tunelamento
  - proxy no nível do aplicativo
  - tunelamento completo do sistema
  - superfície de controle consistente

- LAN Sharing
  - compartilhar o tráfego gerenciado pelo GenyConnect com outros dispositivos na rede local
  - oferecer suporte a consoles de jogos, smart TVs, telefones, tablets, notebooks e computadores desktop
  - controles avançados de compartilhamento para ambientes de rede gerenciados

- Arquitetura multiplataforma
  - runtime core compartilhado
  - adaptadores desktop e mobile
  - integrações específicas de plataforma

---

## Power Mode

GenyConnect inclui um sistema Power Mode sensível à plataforma, projetado para melhorar a estabilidade da conexão e a consistência do runtime durante cargas sustentadas.

Power Mode ajuda a reduzir interferências do sistema operacional causadas por economia de energia agressiva, limitação em segundo plano, suspensão por inatividade e transições para estados de sono.

Dependendo do sistema operacional e do runtime backend, Power Mode pode:

- manter caminhos críticos de rede responsivos
- reduzir desconexões inesperadas
- melhorar a consistência da vazão
- otimizar sessões longas de tráfego
- minimizar picos de latência durante atividade intensa
- melhorar a confiabilidade do runtime durante o tunelamento

O comportamento do Power Mode é adaptativo e pode variar conforme os recursos da plataforma e as restrições do sistema operacional.

---

## Capturas de tela

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## Suporte de plataforma

GenyConnect atualmente oferece suporte a:

- macOS
- Windows
- Linux
- Android

O suporte a iOS está em desenvolvimento ativo.

---

## Stack de tecnologia

- C++23
- Qt 6 / QML
- Arquitetura runtime nativa multiplataforma
- Pipelines de implantação multiplataforma
- Integração de backend de tunelamento engine-agnostic

---

## Licenciamento

GenyConnect Community Edition é licenciado sob a GNU General Public License versão 3 ou posterior (GPL-3.0-or-later).

Licenciamento comercial está disponível separadamente pela Genyleap Labs para:

- implantações proprietárias
- redistribuição closed-source
- integrações empresariais
- produtos white-label
- distribuição na App Store
- edições comerciais
- recursos Pro ou Enterprise

Salvo indicação explícita em contrário, os itens a seguir NÃO são cobertos pela licença GPL e permanecem All Rights Reserved:

- nome GenyConnect
- logotipos
- ícones
- capturas de tela
- design visual
- ativos de marca
- gráficos promocionais
- UI artwork
- materiais de identidade visual
- ativos de marketing

Forks e redistribuições não podem sugerir endosso ou afiliação com a Genyleap Labs sem permissão explícita por escrito.

Consulte os arquivos LICENSE e NOTICE para obter todos os detalhes de licenciamento.

### Resumo da licença

Código-fonte da Community Edition:
- GPL-3.0-or-later

Licenciamento comercial:
- Licença comercial proprietária separada

Ativos de marca e não relacionados a código:
- All Rights Reserved

---

## ❤️ Apoie o GenyConnect

GenyConnect é um projeto desenvolvido de forma independente pela Genyleap Labs.

Se o GenyConnect ajuda você, é possível apoiar seu desenvolvimento contínuo doando com $GENY ou USDC na Base Network.

Seu apoio ajuda a financiar:

- desenvolvimento contínuo
- melhorias de segurança
- suporte a plataformas desktop e mobile
- infraestrutura e testes
- futuras versões open-source
- crescimento de longo prazo do ecossistema

---

## 🌐 Apoie com $GENY

Ao doar com $GENY, você apoia tanto o desenvolvimento do GenyConnect quanto o ecossistema Geny mais amplo.

### Base Mainnet

Contrato do token GENY:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

Carteira de doação para desenvolvedor:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Compre ou troque $GENY para o ecossistema Genyleap

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 Apoie com USDC

USDC é uma forma estável e simples de apoiar diretamente o desenvolvimento.

### Base Mainnet

Carteira de doação para desenvolvedor:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## Aviso sobre doações

Doações são contribuições voluntárias para apoiar o desenvolvimento do GenyConnect.

Elas não representam:

- investimento
- participação societária
- propriedade
- compartilhamento de receita
- valores mobiliários
- produtos financeiros
- promessas de retorno financeiro

📢 Acompanhe atualizações de desenvolvimento, anúncios e futuros lançamentos no Telegram e Farcaster:

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

Seu feedback e apoio ajudam a moldar o futuro do GenyConnect e do ecossistema Genyleap mais amplo. 🚀
