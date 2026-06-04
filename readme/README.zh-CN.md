![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect 是一款现代化、跨平台的安全连接客户端，面向私有网络和加密通信而设计，重点关注性能、隐私和精确的流量管理。

它为安全网络和隧道引擎提供强大的编排层，强调可靠性、可观测性、运行透明度和用户体验，同时不依赖任何特定协议、技术或实现。

GenyConnect 正沿两个方向开发：面向个人用户和日常连接需求的 Community Edition，以及面向需要集中管理、网络策略、访问控制和大规模安全通信的组织的 Commercial & Enterprise Edition。

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

## 概述

GenyConnect 允许用户通过结构化服务器配置文件和可共享的配置链接建立并管理安全连接。

运行时配置会动态生成，连接生命周期会被显式监管，系统状态始终保持完全可观测。

该平台有意保持引擎无关，使不同隧道后端可以集成进来，而不改变用户工作流或预期行为。

GenyConnect 不局限于通用隧道工具。它的长期方向是成为智能连接层，用于管理对服务、私有基础设施、云资源以及需要稳定可靠通信的分布式团队的访问。

在 1.4 和 1.5 版本阶段，GenyConnect 预计将更成熟地面向更广泛的公共使用，并覆盖需要可靠连接的用户的大量需求。未来版本计划加入 Persian 和更多应用内语言。

第二代 GenyConnect 将更深入地面向商业和组织需求，包括访问管理、通信基础设施定制、网络韧性、降低对外部服务的依赖，以及在不同网络条件下保持稳定连接。未来版本还计划支持专用的 `gen.` 格式和 GenyConnect 自有通信架构，用于定义和管理私有网络与组织访问。

---

## 核心能力

- 清晰的运行可见性
  - 实时日志
  - 实时流量统计
  - 明确的连接状态报告

- 高性能执行
  - 轻量级运行时
  - 极低开销
  - 在持续负载下保持响应

- 确定性的生命周期管理
  - 可预测的启动
  - 干净关闭
  - 安全的重连逻辑

- 高级流量路由
  - 基于白名单的路由
  - 域名级 tunnel/direct/block 规则
  - 在支持的平台上按应用路由
  - 在支持的平台上按进程路由

- 灵活的隧道模式
  - 应用级代理
  - 完整系统隧道
  - 一致的控制界面

- LAN Sharing
  - 将 GenyConnect 管理的流量共享给本地网络中的其他设备
  - 支持游戏主机、智能电视、手机、平板、笔记本电脑和台式电脑等设备
  - 为受管理的网络环境提供高级共享控制

- 跨平台架构
  - 共享运行时核心
  - 桌面和移动适配器
  - 平台专属集成

---

## Power Mode

GenyConnect 包含一个感知平台能力的 Power Mode 系统，用于在持续工作负载下提升连接稳定性和运行时一致性。

Power Mode 有助于减少操作系统因激进省电、后台限速、空闲挂起和睡眠状态切换带来的干扰。

根据操作系统和运行时后端，Power Mode 可能会：

- 保持关键网络路径响应
- 减少意外断连
- 提升吞吐稳定性
- 优化长时间流量会话
- 降低高负载活动中的延迟尖峰
- 提升隧道运行时可靠性

Power Mode 的行为是自适应的，可能会因平台能力和操作系统限制而有所不同。

---

## 截图

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## 平台支持

GenyConnect 目前支持：

- macOS
- Windows
- Linux
- Android

iOS 支持正在积极开发中。

---

## 技术栈

- C++23
- Qt 6 / QML
- 跨平台原生运行时架构
- 多平台部署流水线
- 引擎无关的隧道后端集成

---

## 许可

GenyConnect Community Edition 根据 GNU General Public License 第 3 版或更高版本（GPL-3.0-or-later）授权。

商业许可可由 Genyleap Labs 单独提供，适用于：

- 专有部署
- 闭源再分发
- 企业集成
- white-label 产品
- App Store 分发
- 商业版本
- Pro 或 Enterprise 功能

除非另有明确说明，以下内容不受 GPL 许可覆盖，并保留 All Rights Reserved：

- GenyConnect 名称
- 标志
- 图标
- 截图
- 视觉设计
- 品牌资产
- 宣传图形
- UI 美术
- 视觉识别材料
- 营销资产

未经明确书面许可，分叉和再分发不得暗示获得 Genyleap Labs 背书或与其有关联。

完整许可详情请参阅 LICENSE 和 NOTICE 文件。

### 许可摘要

Community Edition 源代码：
- GPL-3.0-or-later

商业许可：
- 单独的专有商业许可

品牌和非代码资产：
- All Rights Reserved

---

## ❤️ 支持 GenyConnect

GenyConnect 是由 Genyleap Labs 独立开发的项目。

如果 GenyConnect 对你有帮助，你可以通过在 Base Network 上捐赠 $GENY 或 USDC 来支持其持续开发。

你的支持将用于：

- 持续开发
- 安全改进
- 桌面和移动平台支持
- 基础设施和测试
- 未来开源发布
- 长期生态增长

---

## 🌐 使用 $GENY 支持

通过捐赠 $GENY，你将同时支持 GenyConnect 开发和更广泛的 Geny 生态。

### Base Mainnet

GENY 代币合约：

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

开发者捐赠钱包：

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### 为 Genyleap 生态购买或兑换 $GENY

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 使用 USDC 支持

USDC 是直接支持开发的一种稳定而简单的方式。

### Base Mainnet

开发者捐赠钱包：

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## 捐赠说明

捐赠是用于支持 GenyConnect 开发的自愿贡献。

它们不代表：

- 投资
- 股权
- 所有权
- 收入分成
- 证券
- 金融产品
- 财务回报承诺

📢 在 Telegram 和 Farcaster 关注开发更新、公告和未来发布：

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

你的反馈和支持将帮助塑造 GenyConnect 以及更广泛 Genyleap 生态的未来。 🚀
