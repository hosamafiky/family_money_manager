/// Household cardinality constraint tests (Phase 3A.1 §3).
///
/// Tests the DB-level triggers that enforce:
/// - At most one active primary_user per household.
/// - At most one active spouse per household.
/// - household_members must reference an existing household.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async => db.close());

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<void> insertMember({
    required String id,
    required String householdId,
    required String role,
    bool isArchived = false,
  }) => db.customStatement(
    'INSERT INTO household_members '
    '(id, household_id, display_name, role, created_at, updated_at, is_archived) '
    "VALUES ('$id', '$householdId', 'Name $id', '$role', "
    "'2024-01-01', '2024-01-01', ${isArchived ? 1 : 0})",
  );

  group('Primary user cardinality', () {
    test(
      'two active primary_users in one household → SqliteException',
      () async {
        await insertHousehold('hh-card-1');
        await insertMember(
          id: 'member-pu-1',
          householdId: 'hh-card-1',
          role: 'primary_user',
        );

        await expectLater(
          insertMember(
            id: 'member-pu-2',
            householdId: 'hh-card-1',
            role: 'primary_user',
          ),
          throwsA(anything),
        );
      },
    );

    test(
      'primary_user in household A + primary_user in household B → both allowed',
      () async {
        await insertHousehold('hh-card-2a');
        await insertHousehold('hh-card-2b');

        await insertMember(
          id: 'member-pu-a',
          householdId: 'hh-card-2a',
          role: 'primary_user',
        );
        // Should succeed in a different household.
        await expectLater(
          insertMember(
            id: 'member-pu-b',
            householdId: 'hh-card-2b',
            role: 'primary_user',
          ),
          completes,
        );
      },
    );
  });

  group('Spouse cardinality', () {
    test('two active spouses in one household → SqliteException', () async {
      await insertHousehold('hh-card-3');
      await insertMember(
        id: 'member-sp-1',
        householdId: 'hh-card-3',
        role: 'spouse',
      );

      await expectLater(
        insertMember(
          id: 'member-sp-2',
          householdId: 'hh-card-3',
          role: 'spouse',
        ),
        throwsA(anything),
      );
    });

    test('archived spouse + new active spouse → allowed', () async {
      await insertHousehold('hh-card-4');
      await insertMember(
        id: 'member-sp-arch',
        householdId: 'hh-card-4',
        role: 'spouse',
        isArchived: true,
      );

      // Archived spouse + new active → allowed (is_archived = 0 check).
      await expectLater(
        insertMember(
          id: 'member-sp-new',
          householdId: 'hh-card-4',
          role: 'spouse',
        ),
        completes,
      );
    });

    test('two children in the same household → allowed', () async {
      await insertHousehold('hh-card-5');
      await insertMember(
        id: 'child-1',
        householdId: 'hh-card-5',
        role: 'child',
      );
      await expectLater(
        insertMember(id: 'child-2', householdId: 'hh-card-5', role: 'child'),
        completes,
      );
    });
  });

  group('Cross-household FK enforcement', () {
    test(
      'member with non-existent household_id → SqliteException from trigger',
      () async {
        await expectLater(
          insertMember(
            id: 'member-orphan',
            householdId: 'hh-does-not-exist',
            role: 'child',
          ),
          throwsA(anything),
        );
      },
    );
  });

  group('Read after valid inserts', () {
    test('valid members are readable after insertion', () async {
      await insertHousehold('hh-card-6');
      await insertMember(
        id: 'pu-6',
        householdId: 'hh-card-6',
        role: 'primary_user',
      );
      await insertMember(id: 'sp-6', householdId: 'hh-card-6', role: 'spouse');
      await insertMember(id: 'ch-6', householdId: 'hh-card-6', role: 'child');

      final rows = await db
          .customSelect(
            "SELECT id FROM household_members WHERE household_id = 'hh-card-6'",
          )
          .get();
      expect(rows.length, 3);
    });
  });
}
