/// ISO 4217 currency codes supported by the application.
///
/// V1 supports EGP as the primary household currency.
/// Additional currencies are defined for future multi-currency support (V2).
///
/// INVARIANT: Cross-currency arithmetic is prohibited in V1.
/// All accounts in a V1 household share the same currency code (EGP by default).
///
/// Do NOT assume every currency has two fraction digits.
/// [minorUnitScale] defines how many decimal places exist:
/// - 0 for JPY (no decimals)
/// - 2 for EGP, USD, EUR, GBP
/// - 3 for KWD, BHD, OMR
enum Currency {
  /// Egyptian Pound. Primary V1 household currency. 1 EGP = 100 piasters.
  egp(code: 'EGP', minorUnitScale: 2),

  /// US Dollar. 1 USD = 100 cents.
  usd(code: 'USD', minorUnitScale: 2),

  /// Euro. 1 EUR = 100 cents.
  eur(code: 'EUR', minorUnitScale: 2),

  /// British Pound Sterling. 1 GBP = 100 pence.
  gbp(code: 'GBP', minorUnitScale: 2),

  /// Saudi Riyal. 1 SAR = 100 halalas.
  sar(code: 'SAR', minorUnitScale: 2),

  /// UAE Dirham. 1 AED = 100 fils.
  aed(code: 'AED', minorUnitScale: 2),

  /// Japanese Yen. No minor units; 1 JPY = 1 unit.
  jpy(code: 'JPY', minorUnitScale: 0),

  /// Kuwaiti Dinar. 1 KWD = 1000 fils.
  kwd(code: 'KWD', minorUnitScale: 3),

  /// Bahraini Dinar. 1 BHD = 1000 fils.
  bhd(code: 'BHD', minorUnitScale: 3),

  /// Omani Rial. 1 OMR = 1000 baisa.
  omr(code: 'OMR', minorUnitScale: 3);

  const Currency({required this.code, required this.minorUnitScale});

  /// ISO 4217 three-letter code, always uppercase.
  final String code;

  /// Number of decimal places in the major unit.
  /// Example: EGP has 2 (piasters), JPY has 0, KWD has 3 (fils).
  final int minorUnitScale;

  /// Resolves a [Currency] from an ISO 4217 [code] string.
  ///
  /// Throws [ArgumentError] for unsupported or malformed codes.
  /// Codes are matched case-insensitively.
  static Currency fromCode(String code) {
    final normalised = code.trim().toUpperCase();
    for (final c in Currency.values) {
      if (c.code == normalised) return c;
    }
    throw ArgumentError.value(code, 'code', 'Unsupported or malformed currency code');
  }

  /// Returns true when [code] represents a known supported currency.
  static bool isSupported(String code) {
    final normalised = code.trim().toUpperCase();
    return Currency.values.any((c) => c.code == normalised);
  }

  @override
  String toString() => code;
}
