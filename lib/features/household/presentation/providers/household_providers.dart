import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/household/application/household_use_cases.dart';
import 'package:family_money_manager/features/household/data/drift_household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftHouseholdRepository(db);
});

final listMembersUseCaseProvider = Provider((ref) {
  return ListMembersUseCase(ref.watch(householdRepositoryProvider));
});

final addMemberUseCaseProvider = Provider((ref) {
  return AddMemberUseCase(ref.watch(householdRepositoryProvider));
});

final renameMemberUseCaseProvider = Provider((ref) {
  return RenameMemberUseCase(ref.watch(householdRepositoryProvider));
});

final archiveMemberUseCaseProvider = Provider((ref) {
  return ArchiveMemberUseCase(ref.watch(householdRepositoryProvider));
});

final householdMembersProvider = FutureProvider.family<AppResult<List<HouseholdMember>>, String>((
  ref,
  householdId,
) {
  final useCase = ref.watch(listMembersUseCaseProvider);
  return useCase.execute(householdId);
});
