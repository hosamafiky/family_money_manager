/// Protection policy for certificate principal.
///
/// **Rule:** certificate principal is protected money for as long as the
/// contractual term has not ended. Once maturity is reached the principal is
/// no longer protected — it is money the household must act on (redeem).
///
/// This protection is **derived, never persisted**. `financial_accounts.
/// is_protected` is immutable after creation (FINANCIAL_MODEL §21 /
/// [ClassificationImmutabilityError]), so a stored flag could not be flipped
/// when maturity arrives. The term boundary is therefore evaluated against the
/// clock on every read, exactly like [CertificateTermState].
///
/// Protection here is a *classification* concern (which bucket the money is
/// reported in). Withdrawal restriction is a separate, stronger gate already
/// enforced by INV-004A: certificate accounts are reachable only through
/// certificate-owned workflows, at the use-case, repository, and trigger levels.
library;

import 'package:family_money_manager/features/certificates/domain/certificate.dart';

abstract final class CertificatePrincipalProtection {
  const CertificatePrincipalProtection._();

  /// Whether principal in the given term state counts as protected money.
  ///
  /// Protected: [CertificateTermState.notStarted] (funded, term not begun) and
  /// [CertificateTermState.activeTerm] (inside the term).
  ///
  /// Not protected: [CertificateTermState.matured] and
  /// [CertificateTermState.overdueRedemption] — the term ended, so the
  /// principal is claimable and must surface as awaiting redemption rather than
  /// hide inside the protected total. [CertificateTermState.fullyRedeemed]
  /// holds no principal at all.
  static bool isProtectedInTermState(CertificateTermState state) =>
      state == CertificateTermState.notStarted ||
      state == CertificateTermState.activeTerm;

  /// Derives protection directly from certificate facts.
  ///
  /// [todayLocal] is a `yyyy-MM-dd` calendar date in the device local timezone
  /// — the same clock policy the dashboard and reports use (no household
  /// timezone in V1).
  static bool isProtectedOn({
    required CertificateLifecycle lifecycle,
    required String startDate,
    required String maturityDate,
    required String todayLocal,
    required int principalBalanceMinorUnits,
  }) {
    return isProtectedInTermState(
      CertificateTermState.derive(
        lifecycle: lifecycle,
        startDate: startDate,
        maturityDate: maturityDate,
        todayLocal: todayLocal,
        principalBalanceMinorUnits: principalBalanceMinorUnits,
      ),
    );
  }
}
