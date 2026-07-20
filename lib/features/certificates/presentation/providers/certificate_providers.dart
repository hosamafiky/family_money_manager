import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/certificate_repository.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _certHouseholdId = 'household-v1';

/// Invalidates certificate + account/ledger consumers after money operations.
void invalidateCertificateMoneyProviders(
  WidgetRef ref, {
  required String certificateId,
}) {
  ref.invalidate(certificateProgressProvider(certificateId));
  ref.invalidate(certificateDetailProvider(certificateId));
  ref.invalidate(certificatesProvider(_certHouseholdId));
  ref.invalidate(accountsProvider(_certHouseholdId));
  ref.invalidate(accountBalanceProvider);
  ref.invalidate(dashboardSummaryProvider(_certHouseholdId));
  ref.invalidate(accountFlowReportProvider);
  ref.invalidate(
    transactionListProvider((_certHouseholdId, const TransactionFilter())),
  );
}

/// Invalidates certificate consumers after lifecycle-only changes.
void invalidateCertificateLifecycleProviders(
  WidgetRef ref, {
  required String certificateId,
}) {
  ref.invalidate(certificateProgressProvider(certificateId));
  ref.invalidate(certificateDetailProvider(certificateId));
  ref.invalidate(certificatesProvider(_certHouseholdId));
}

// ── Repository ─────────────────────────────────────────────────────────────

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return DriftCertificateRepository(ref.watch(appDatabaseProvider));
});

// ── Use-case providers ─────────────────────────────────────────────────────

final createCertificateUseCaseProvider = Provider<CreateCertificateUseCase>((
  ref,
) {
  return CreateCertificateUseCase(
    certRepository: ref.watch(certificateRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final recordCertificateProfitUseCaseProvider =
    Provider<RecordCertificateProfitUseCase>((ref) {
      return RecordCertificateProfitUseCase(
        certRepository: ref.watch(certificateRepositoryProvider),
        accountRepository: ref.watch(accountRepositoryProvider),
      );
    });

final redeemCertificateUseCaseProvider = Provider<RedeemCertificateUseCase>((
  ref,
) {
  return RedeemCertificateUseCase(
    certRepository: ref.watch(certificateRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final archiveCertificateUseCaseProvider = Provider<ArchiveCertificateUseCase>((
  ref,
) {
  return ArchiveCertificateUseCase(ref.watch(certificateRepositoryProvider));
});

final restoreCertificateUseCaseProvider = Provider<RestoreCertificateUseCase>((
  ref,
) {
  return RestoreCertificateUseCase(ref.watch(certificateRepositoryProvider));
});

final getCertificateProgressUseCaseProvider =
    Provider<GetCertificateProgressUseCase>((ref) {
      return GetCertificateProgressUseCase(
        ref.watch(certificateRepositoryProvider),
      );
    });

final reverseCertificatePurchaseUseCaseProvider =
    Provider<ReverseCertificatePurchaseUseCase>((ref) {
      return ReverseCertificatePurchaseUseCase(
        ref.watch(certificateRepositoryProvider),
      );
    });

final reverseCertificateProfitUseCaseProvider =
    Provider<ReverseCertificateProfitUseCase>((ref) {
      return ReverseCertificateProfitUseCase(
        ref.watch(certificateRepositoryProvider),
      );
    });

final reviseCertificateDefinitionUseCaseProvider =
    Provider<ReviseCertificateDefinitionUseCase>((ref) {
      return ReviseCertificateDefinitionUseCase(
        ref.watch(certificateRepositoryProvider),
      );
    });

// ── Data providers ─────────────────────────────────────────────────────────

/// Lists certificates (active + redeemed by default) for a household.
final certificatesProvider =
    FutureProvider.family<AppResult<List<SavingsCertificate>>, String>((
      ref,
      householdId,
    ) {
      final repo = ref.watch(certificateRepositoryProvider);
      return repo.listCertificates(householdId: householdId);
    });

/// Full progress snapshot for a single certificate.
final certificateProgressProvider =
    FutureProvider.family<AppResult<CertificateProgress>, String>((
      ref,
      certificateId,
    ) {
      final useCase = ref.watch(getCertificateProgressUseCaseProvider);
      return useCase.execute(certificateId);
    });

/// Single certificate detail (raw entity without derived progress).
final certificateDetailProvider =
    FutureProvider.family<AppResult<SavingsCertificate?>, String>((
      ref,
      certificateId,
    ) {
      final repo = ref.watch(certificateRepositoryProvider);
      return repo.findById(certificateId);
    });
