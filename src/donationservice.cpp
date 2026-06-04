module;
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonObject>
#include <QJsonArray>
#include <QLatin1StringView>
#include <QRegularExpression>
#include <QStringList>
#include <QStringView>
#include <QVariantList>
#include <QVariantMap>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

#include <array>

module genyconnect.backend.donationservice;

namespace {
    
inline constexpr QLatin1StringView kDonationBaseChainName   {"Base Mainnet"};
inline constexpr QLatin1StringView kDonationReceiverWallet  {"0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589"};
inline constexpr QLatin1StringView kDonationGenyContract    {"0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B"};
inline constexpr QLatin1StringView kDonationUsdcContract    {"0x833589fCD6EDB6E08f4c7C32D4f71b54bdA02913"};

constexpr int kDonationBaseChainId = 8453;
constexpr int kDonationGenyDecimals = 18;
constexpr int kDonationUsdcDecimals = 6;

inline constexpr QLatin1StringView kDonationBaseScanBaseUrl     {"https://basescan.org"};
inline constexpr QLatin1StringView kDonationUniswapBaseUrl      {"https://app.uniswap.org/swap?chain=base&outputCurrency="};
inline constexpr QLatin1StringView kDonationWhitePaperUrl       {"https://github.com/genyleap/white-paper"};
inline constexpr QLatin1StringView kDonationTokenRepoUrl        {"https://github.com/genyleap/geny-token"};
inline constexpr QLatin1StringView kUint256MaxDec               {"115792089237316195423570985008687907853269984665640564039457584007913129639935"};
inline constexpr QLatin1StringView kRecommendedDonationToken    {"GENY"};

#if defined(Q_OS_ANDROID)
inline constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
#endif

struct DonationTokenDefinition {
    QLatin1StringView symbol;
    QLatin1StringView displayName;
    QLatin1StringView contract;
    int decimals;
    bool recommended;
    std::array<QLatin1StringView, 4> presetAmounts;
    QLatin1StringView encouragement;
};

inline constexpr std::array<DonationTokenDefinition, 2> kDonationTokens {{
    DonationTokenDefinition {
        QLatin1StringView("GENY"),
        QLatin1StringView("GENY Token"),
        kDonationGenyContract,
        kDonationGenyDecimals,
        true,
        {QLatin1StringView("250"),
         QLatin1StringView("1000"),
         QLatin1StringView("5000"),
         QLatin1StringView("10000")},
        QLatin1StringView("Best for long-term GenyConnect support.")
    },
    DonationTokenDefinition {
        QLatin1StringView("USDC"),
        QLatin1StringView("USDC"),
        kDonationUsdcContract,
        kDonationUsdcDecimals,
        false,
        {QLatin1StringView("5"),
         QLatin1StringView("10"),
         QLatin1StringView("25"),
         QLatin1StringView("50")},
        QLatin1StringView("Stable support on Base.")
    }
}};

/**
 * @brief Find a token definition by user-facing symbol.
 */
const DonationTokenDefinition* findDonationToken(QStringView symbol)
{
    const QString normalized = symbol.toString().trimmed().toUpper();
    for (const auto& token : kDonationTokens) {
        if (normalized == token.symbol) {
            return &token;
        }
    }
    return nullptr;
}

/**
 * @brief Remove redundant leading zeroes while preserving a single zero.
 */
QString stripLeadingZeros(QStringView value)
{
    int i = 0;
    while (i < value.size() - 1 && value.at(i) == QLatin1Char('0')) {
        ++i;
    }
    return value.sliced(i).toString();
}

/**
 * @brief Check whether a decimal string fits inside an unsigned 256-bit value.
 */
bool isUint256Decimal(QStringView value)
{
    const QString normalized = stripLeadingZeros(value);
    if (normalized.size() < kUint256MaxDec.size()) {
        return true;
    }
    if (normalized.size() > kUint256MaxDec.size()) {
        return false;
    }
    return normalized.compare(kUint256MaxDec) <= 0;
}

/**
 * @brief Convert a human token amount into integer base units.
 */
bool parseTokenAmountToBaseUnits(QStringView rawAmount, int decimals, QString *baseUnits, QString *errorText)
{
    if (!baseUnits || !errorText) {
        return false;
    }
    *baseUnits = QString();
    *errorText = QString();

    const QString input = rawAmount.toString().trimmed();
    if (input.isEmpty()) {
        *errorText = QStringLiteral("Enter a donation amount.");
        return false;
    }

    static const QRegularExpression numberPattern(
        QStringLiteral("^([0-9]+)(?:\\.([0-9]+))?$"));
    const QRegularExpressionMatch match = numberPattern.match(input);
    if (!match.hasMatch()) {
        *errorText = QStringLiteral("Amount must be a valid positive number.");
        return false;
    }

    QString integerPart = match.captured(1);
    QString fractionPart = match.captured(2);
    if (fractionPart.size() > decimals) {
        *errorText = QStringLiteral("Too many decimal places for selected token.");
        return false;
    }

    if (fractionPart.size() < decimals) {
        fractionPart += QString(decimals - fractionPart.size(), QChar('0'));
    }

    integerPart = stripLeadingZeros(integerPart);
    QString merged = stripLeadingZeros(integerPart + fractionPart);
    if (merged == QLatin1StringView("0")) {
        *errorText = QStringLiteral("Amount must be greater than zero.");
        return false;
    }

    if (!isUint256Decimal(merged)) {
        *errorText = QStringLiteral("Amount is too large.");
        return false;
    }

    *baseUnits = merged;
    return true;
}

QString donationUniswapUrl(const DonationTokenDefinition& token)
{
    return QString(kDonationUniswapBaseUrl) + QString(token.contract);
}

} // namespace

QVariantList DonationService::walletTargets(QStringView transferUrl, QStringView swapUrl)
{
    QVariantList targets;
#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject transferObject = QJniObject::fromString(transferUrl.toString().trimmed());
        const QJniObject swapObject = QJniObject::fromString(swapUrl.toString().trimmed());
        const QJniObject jsonObject = QJniObject::callStaticObjectMethod(
            kAndroidRuntimeBridgeClass,
            "discoverWalletTargets",
            "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
            transferObject.object<jstring>(),
            swapObject.object<jstring>());
        const QString jsonText = jsonObject.toString();
        const QJsonDocument document = QJsonDocument::fromJson(jsonText.toUtf8());
        if (document.isArray()) {
            for (const QJsonValue& value : document.array()) {
                if (value.isObject()) {
                    targets.append(value.toObject().toVariantMap());
                }
            }
        }
    }
#else
    Q_UNUSED(transferUrl);
    Q_UNUSED(swapUrl);
#endif

    if (targets.isEmpty()) {
        QVariantMap row;
        row.insert(QStringLiteral("id"), QStringLiteral("system"));
        row.insert(QStringLiteral("label"), QStringLiteral("Any Compatible Wallet"));
        row.insert(QStringLiteral("mode"), QStringLiteral("chooser"));
        row.insert(QStringLiteral("packageName"), QString());
        targets.append(row);
    }

    return targets;
}

QVariantMap DonationService::config()
{
    QVariantMap config;
    config.insert(QStringLiteral("networkName"), QString(kDonationBaseChainName));
    config.insert(QStringLiteral("chainId"), kDonationBaseChainId);
    config.insert(QStringLiteral("receiverWallet"), QString(kDonationReceiverWallet));
    config.insert(QStringLiteral("baseScanBaseUrl"), QString(kDonationBaseScanBaseUrl));
    config.insert(QStringLiteral("uniswapBaseUrl"), QString(kDonationUniswapBaseUrl));
    config.insert(QStringLiteral("receiverBaseScanUrl"),
                  QStringLiteral("%1/address/%2").arg(QString(kDonationBaseScanBaseUrl), QString(kDonationReceiverWallet)));
    config.insert(QStringLiteral("whitePaperUrl"), QString(kDonationWhitePaperUrl));
    config.insert(QStringLiteral("tokenRepoUrl"), QString(kDonationTokenRepoUrl));
    config.insert(QStringLiteral("recommendedToken"), QString(kRecommendedDonationToken));
    config.insert(QStringLiteral("noticeText"),
                  QStringLiteral("Donations are voluntary contributions to support GenyConnect development. They do not represent an investment, equity, ownership, revenue share, or a promise of financial return."));
    return config;
}

QVariantList DonationService::tokenOptions()
{
    QVariantList rows;
    for (const auto& token : kDonationTokens) {
        QVariantMap row;
        row.insert(QStringLiteral("symbol"), QString(token.symbol));
        row.insert(QStringLiteral("displayName"), QString(token.displayName));
        row.insert(QStringLiteral("contract"), QString(token.contract));
        row.insert(QStringLiteral("decimals"), token.decimals);
        row.insert(QStringLiteral("recommended"), token.recommended);
        row.insert(QStringLiteral("message"), QString(token.encouragement));
        QVariantList presets;
        for (const auto& preset : token.presetAmounts) {
            presets.append(QString(preset));
        }
        row.insert(QStringLiteral("presetAmounts"), presets);
        row.insert(QStringLiteral("baseScanUrl"),
                   QStringLiteral("%1/token/%2").arg(QString(kDonationBaseScanBaseUrl), QString(token.contract)));
        row.insert(QStringLiteral("uniswapUrl"), donationUniswapUrl(token));
        row.insert(QStringLiteral("priceUrl"),
                   QStringLiteral("https://api.geckoterminal.com/api/v2/simple/networks/base/token_price/%1")
                       .arg(QString(token.contract)));
        rows.append(row);
    }
    return rows;
}

QVariantMap DonationService::buildPayload(QStringView tokenSymbol, QStringView amountText)
{
    QVariantMap payload;
    payload.insert(QStringLiteral("ok"), false);

    const DonationTokenDefinition *token = findDonationToken(tokenSymbol);
    if (!token) {
        payload.insert(QStringLiteral("error"), QStringLiteral("Unsupported donation token selected."));
        return payload;
    }

    QString baseUnits;
    QString parseError;
    if (!parseTokenAmountToBaseUnits(amountText, token->decimals, &baseUnits, &parseError)) {
        payload.insert(QStringLiteral("error"), parseError);
        return payload;
    }

    const QString tokenContract = QString(token->contract);
    const QString receiverWallet = QString(kDonationReceiverWallet);
    const QString displayAmount = amountText.toString().trimmed();
    const QString deepLink = QStringLiteral("ethereum:%1@%2/transfer?address=%3&uint256=%4")
                                 .arg(tokenContract,
                                      QString::number(kDonationBaseChainId),
                                      receiverWallet,
                                      baseUnits);

    payload.insert(QStringLiteral("ok"), true);
    payload.insert(QStringLiteral("tokenSymbol"), QString(token->symbol));
    payload.insert(QStringLiteral("tokenContract"), tokenContract);
    payload.insert(QStringLiteral("tokenDecimals"), token->decimals);
    payload.insert(QStringLiteral("networkName"), QString(kDonationBaseChainName));
    payload.insert(QStringLiteral("chainId"), kDonationBaseChainId);
    payload.insert(QStringLiteral("receiverWallet"), receiverWallet);
    payload.insert(QStringLiteral("displayAmount"), displayAmount);
    payload.insert(QStringLiteral("amountBaseUnits"), baseUnits);
    payload.insert(QStringLiteral("deepLink"), deepLink);
    payload.insert(QStringLiteral("receiverBaseScanUrl"),
                   QStringLiteral("%1/address/%2").arg(QString(kDonationBaseScanBaseUrl), receiverWallet));
    payload.insert(QStringLiteral("tokenBaseScanUrl"),
                   QStringLiteral("%1/token/%2").arg(QString(kDonationBaseScanBaseUrl), tokenContract));
    payload.insert(QStringLiteral("uniswapUrl"), donationUniswapUrl(*token));
    return payload;
}
