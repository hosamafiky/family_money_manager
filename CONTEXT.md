 ▐▛███▜▌   Claude Code v2.1.220
▝▜█████▛▘  Opus 5 · Claude Max
  ▘▘ ▝▝    ~/Desktop/family_money_manager


❯ Attached is CONTEXT.md — a handoff summary from a previous conversation. Read 
  it fully before responding.                                                   
                                                                                
  Treat it as authoritative background: the goals, decisions, and constraints   
  in it are already settled, so don't re-litigate them or ask me to re-explain  
  what's already there. Anything it doesn't cover, ask me about rather than     
  assuming.                                                                     
                                                                                
  Reply with a short confirmation of (a) what you understand the goal to be,    
  (b) where things currently stand, and (c) what you think the next step is —   
  then wait for me before doing any work.                                       

⏺ I don't see CONTEXT.md attached — no file content came through with your
  message.

  Could you either re-attach it or tell me the path (e.g. ./CONTEXT.md) so I can
  read it? I haven't read or done anything yet.

✻ Worked for 6s

❯ Read ./context.md at the project root before doing anything else. It's a      
  handoff summary from a previous session.                                      
                                                                                
  Treat it as authoritative background — the goals, decisions, and constraints  
  in it are already settled, so don't re-litigate them or ask me to re-explain  
  what's in there. If something isn't covered, ask me rather than assuming.     
                                                                                
  Reply with a short confirmation of (a) the goal, (b) where things stand, and  
  (c) what you think the next step is — then wait for me before making changes. 

  Searched for 2 patterns, read 1 file, listed 1 directory, ran 1 shell command (ctrl+o to expand)

❯ continue                                                                      

  Ran 1 shell command (ctrl+o to expand)

⏺ Read context.md (5,482 lines) plus verified the current repo state against it.

  (a) Goal — Implement the design_handoff_family_money_manager/ redesign into
  this Flutter app as real architecture, not ported HTML: design tokens in the
  theme layer, shared presentation components, adaptive layouts, feature screens
  on the existing Riverpod/go_router/Drift stack. Arabic RTL first, English LTR
  second, existing financial behavior preserved, no duplicated styling or
  amount-formatting logic, tests alongside. Executed as the phased plan from D6
  §04 (phases 0–9), reporting per phase.

  (b) Where things stand

  - Phases 0–5 complete. Tokens (3 new colour roles, AppTextRoles.forLocale,
  bundled Archivo + IBM Plex Sans Arabic), colour/shape literals, typography,
  components, list tiles.
  - Phase 6 complete for the query work and the two dashboard money regions.
  - Phase 7 complete. Expense form at B1/B2 (numpad-first, printed defaults,
  full-bleed chip row), all three reviews on the read-back +
  persistent-AppInlineNotice pattern, expense_submission.dart as the single
  write path, zero failure snackbars left in lib/features/transactions/.
  Deferred as polish: repeat tiles, tappable meta line, utility key column,
  budget preview on review, retiring the /transactions/new chooser, porting the
  pad to income/transfer forms.
  - Phase 8 in flight. The v19→v20 reversal_reason migration landed and is
  committed (app_database.dart:149 is 20, migration test present). The
  transcript cuts off mid-debug: an earlier migration step rebuilds operations
  from the current Drift definition, so the column already exists when the new
  step runs — the fix in progress was making the ALTER idempotent directly
  rather than gating it on a deferred customSelect. Still not done in phase 8:
  the /transactions/:operationId/reverse route (absent), detail screens as root
  pushes (parentNavigatorKey appears 0 times in app_router.dart), and the
  list/detail/reversal UI itself.
  - Snackbars still remain in 6 files outside transactions (goals ×3, accounts,
  budgets, household) — phase 8/9 screens.
  - Tree is clean on design/redesign-phases-0-2. Two pre-existing test failures
  were the standing baseline.
  - Two decisions of yours are still open, and phase 8 touches both: the
  certificate-principal double classification between protectedBalances and
  heldByReason, and the spouse-wallet exclusion from the headline balance. Also
  unresolved: expense scope defaulting to personal in code vs household in the
  spec — left alone deliberately as a financial-behaviour change.

  (c) Next step I'd take — Confirm the v19→v20 migration is actually green (run
  the migration test + full suite) since the transcript ends mid-fix, then
  finish phase 8: the reverse route, root-push detail screens, and the reversal
  explainer/detail UI. But I'd want your two outstanding decisions first — they
  surface on account and transaction detail, which is exactly what phase 8
  rebuilds.

  Waiting on you before touching anything.

✻ Cogitated for 27s

❯ go ahead                                                                      

  Searched for 1 pattern, read 1 file, ran 3 shell commands (ctrl+o to expand)

⏺ Now the router — the two structural changes phase 8 needs.

  Searched for 6 patterns, read 5 files, listed 2 directories, ran 2 shell commands (ctrl+o to expand)

⏺ Background command "Full suite baseline" completed (exit code 0)

⏺ While that runs, the reversal spec:

  Searched for 2 patterns, read 1 file, listed 1 directory, ran 10 shell commands (ctrl+o to expand)
⏺ Background command "Identify failing tests" completed (exit code 0)

⏺ All three share the same shape. Writing the shared helper:

⏺ Write(test/helpers/historical_table_shape.dart)
  ⎿  Wrote 67 lines to test/helpers/historical_table_shape.dart
       1 /// Removes columns that did not exist yet from a materialized h
       2 /// schema file.
       4 /// The `true_schema_v*` helpers build their table shapes by dum
       5 /// `CREATE TABLE` DDL from a *current* [AppDatabase] probe. Tha
       6 /// only sound while no column has been added to a pre-existing 
         table since the
         nt asserts
         xture claiming
          and the
         olumn.
     … +78 lines (ctrl+o to expand)

⏺ Now wire it into the three helpers:

  Read 1 file (ctrl+o to expand)

⏺ Update(test/helpers/true_schema_v18.dart)
  ⎿  Added 1 line
      47    for (final row in tableRows) {
      48      raw.execute(row.read<String>('sql'));
      49    }
      50 +  stripColumnsNewerThan(raw, 18);                              
      51    for (final stmt in _splitSqlStatements(objectsSql)) {
      52      raw.execute(stmt);
      53    }

⏺ Update(test/helpers/true_schema_v18.dart)
  ⎿  Added 2 lines
      24  import 'package:path/path.dart' as p;
      25  import 'package:sqlite3/sqlite3.dart' as sqlite3;
      26  
      27 +import 'historical_table_shape.dart';                          
      28 +                                                               
      29  /// Materializes a true schema-18 database file without 6B.1.1 
          triggers.
      30  Future<String> materializeTrueSchemaV18File() async {
      31    final dir = await Directory.systemTemp.createTemp('fmm_true_v
          18_');

  Read 1 file (ctrl+o to expand)

⏺ Update(test/helpers/true_schema_v12.dart)
  ⎿  Added 1 line
      40    for (final row in tableRows) {
      41      raw.execute(row.read<String>('sql'));
      42    }
      43 +  stripColumnsNewerThan(raw, 12);                              
      44    for (final stmt in _splitSqlStatements(objectsSql)) {
      45      raw.execute(stmt);
      46    }

  Ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Update(test/helpers/true_schema_v12.dart)
  ⎿  Added 3 lines, removed 2 lines
       9  
      10  /// Builds a physical SQLite file at schema version 12 from his
          torical DDL.
      11  ///
      12 -/// Tables come from Drift's current CREATE TABLE statements (c
         -olumns unchanged                                               
      13 -/// across v12→v14). Triggers/indexes come from                
      12 +/// Tables come from Drift's current CREATE TABLE statements, w
         +ith columns                                                    
      13 +/// added after v12 stripped back off by [stripColumnsNewerThan
         +].                                                             
      14 +/// Triggers/indexes come from                                 
      15  /// `test/fixtures/schema_v12_objects.sql` extracted from commi
          t `3124346`
      16  /// onCreate — v13+ objects are never created then deleted.
      17  Future<String> materializeTrueSchemaV12File() async {

  Ran 1 shell command (ctrl+o to expand)

⏺ Update(test/helpers/true_schema_v16.dart)
  ⎿  Added 2 lines, removed 1 line
      10  /// Builds a physical SQLite file at schema version 16 from his
          torical DDL.
      11  ///
      12  /// Tables come from Drift's current CREATE TABLE statements (e
          xcluding
      13 -/// Phase 6A certificate tables). Triggers/indexes come from   
      13 +/// Phase 6A certificate tables), with columns added after v16 
         +stripped back                                                  
      14 +/// off by [stripColumnsNewerThan]. Triggers/indexes come from 
      15  /// `test/fixtures/schema_v16_objects.sql` extracted from commi
          t `86736ca`
      16  /// onCreate — certificate objects are never created then delet
          ed.
      17  Future<String> materializeTrueSchemaV16File() async {

⏺ Update(test/helpers/true_schema_v18.dart)
  ⎿  Added 3 lines, removed 2 lines
       8  /// - Fixture: `test/fixtures/schema_v18_objects.sql` — trigger
          s/indexes
       9  ///   dumped from `AppDatabase.forTesting()` onCreate at that c
          ommit
      10  ///   (100 objects; eligibility triggers absent).
      11 -/// - Tables: Drift CREATE TABLE DDL from the *current* probe (
         -table shapes                                                   
      12 -///   were unchanged 18→19; only eligibility triggers were adde
         -d).                                                            
      11 +/// - Tables: Drift CREATE TABLE DDL from the *current* probe, 
         +with columns                                                   
      12 +///   added after v18 stripped back off by [stripColumnsNewerTh
         +an]. Only                                                      
      13 +///   eligibility triggers were added 18→19; `reversal_reason` 
         +arrived at v20.                                                
      14  ///
      15  /// This is **not** “open schema 19 then delete triggers”. The 
          two Phase
      16  /// 6B.1.1 eligibility triggers are never created on the materi
          alized file;

  Ran 3 shell commands (ctrl+o to expand)

⏺ Update(test/database/certificates/phase_6a3_migration_restart_test.dart)
  ⎿  Added 3 lines, removed 1 line
      140        (await db.customSelect('PRAGMA user_version').get()).fir
           st.read<int>(
      141          'user_version',
      142        ),
      143 -      19,                                                     
      143 +      // The current version, not a literal: the claim under t
          +est is that a                                                 
      144 +      // reopen finishes the upgrade, which stays true as vers
          +ions are added.                                               
      145 +      db.schemaVersion,                                       
      146      );
      147  
      148      Future<int> objectCount(String type, String name) async =>

⏺ Update(test/database/certificates/certificate_true_migration_v16_to_latest_tes
        t.dart)
  ⎿  Added 4 lines, removed 2 lines
      204        );
      205        stuck.close();
      206  
      207 -      // Reopening with AppDatabase completes onUpgrade from 1
          -6 → 19.                                                       
      207 +      // Reopening with AppDatabase completes onUpgrade from 1
          +6 to current.                                                 
      208        final db = AppDatabase.forFile(path);
      209        addTearDown(db.close);
      210        expect(
      211          (await db.customSelect('PRAGMA user_version').get()).f
           irst.read<int>(
      212            'user_version',
      213          ),
      214 -        19,                                                   
      214 +        // The current version, not a literal: the claim under
          + test is that a                                               
      215 +        // reopen finishes the upgrade, which stays true as ve
          +rsions are added.                                             
      216 +        db.schemaVersion,                                     
      217        );
      218        // createTable IF path: table already existed; triggers 
           must still install.
      219        expect(

  Searched for 2 patterns, ran 3 shell commands (ctrl+o to expand)
⏺ Now the data layer. Persist the reason and expose it end-to-end:

⏺ Update(lib/features/ledger/data/drift_ledger_repository.dart)
  ⎿  Added 6 lines
      843                  params.reason ??
      844                      'Reversal of operation ${params.originalOp
           erationId}',
      845                ),
      846 +              // Stored separately from [description] because 
          +a reason is an                                                
      847 +              // audit field, not a summary: the detail screen
          + prints it as                                                 
      848 +              // "why", and a caller must be able to tell a re
          +corded reason                                                 
      849 +              // from a generated fallback. Only ever set on t
          +he reversal row,                                              
      850 +              // so the original operation stays untouched (IN
          +V-002).                                                       
      851 +              reversalReason: Value(params.reason),           
      852                sourceAccountId: Value(original.destinationAccou
           ntId),
      853                destinationAccountId: Value(original.sourceAccou
           ntId),
      854                idempotencyKey: Value(params.reversalOperationId
           ),

  Ran 1 shell command (ctrl+o to expand)

⏺ Update(lib/features/ledger/data/ledger_write_support.dart)
  ⎿  Added 1 line
      262      receiptPath: row.receiptPath,
      263      isReversed: row.isReversed,
      264      reversedBy: row.reversedBy,
      265 +    reversalReason: row.reversalReason,                       
      266      createdBy: row.createdBy,
      267      createdAt: row.createdAt,
      268      updatedAt: row.updatedAt,

⏺ Update(lib/features/ledger/domain/operation.dart)
  ⎿  Added 1 line
      36      this.tags = const [],
      37      this.receiptPath,
      38      this.reversedBy,
      39 +    this.reversalReason,                                       
      40    });
      41  
      42    /// Stable client-generated UUID. Used as the idempotency key
          .
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Update(lib/features/ledger/domain/operation.dart)
  ⎿  Added 12 lines
       91    /// The [id] of the reversal [Operation] that cancelled this
            one.
       92    final String? reversedBy;
       93  
       94 +  /// Why this reversal was recorded. Set only on reversal ope
          +rations.                                                      
       95 +  ///                                                         
       96 +  /// Distinct from [description], which every operation type 
          +carries as a                                                  
       97 +  /// summary. A reason is an audit field: it is required when
          + a reversal is                                                
       98 +  /// recorded through the app, it is shown verbatim to anyone
          + who opens the                                                
       99 +  /// entry, and — like every other column but [isReversed] an
          +d [reversedBy] —                                              
      100 +  /// it can never be edited afterwards.                      
      101 +  ///                                                         
      102 +  /// Null on non-reversal operations, and on reversals writte
          +n before                                                      
      103 +  /// schema 20.                                              
      104 +  final String? reversalReason;                               
      105 +                                                              
      106    final String createdBy;
      107  
      108    /// System UTC timestamp of creation. Matches [recordedAt] o
           n first write.

⏺ Update(lib/features/ledger/domain/operation.dart)
  ⎿  Added 9 lines
      627    final String householdId;
      628    final String effectiveDate;
      629    final String createdBy;
      630 +                                                              
      631 +  /// Why the operation is being reversed.                    
      632 +  ///                                                         
      633 +  /// Persisted to `operations.reversal_reason` on the reversa
          +l row and shown                                               
      634 +  /// verbatim wherever the reversal appears. Nullable here ra
          +ther than                                                     
      635 +  /// required because the ledger is also reversed by internal
          + flows that have                                              
      636 +  /// no user-supplied reason; a reversal a *person* initiates
          + must carry one,                                              
      637 +  /// and that rule belongs to `ReverseTransactionUseCase`, wh
          +ich is the only                                               
      638 +  /// path the UI may take.                                   
      639    final String? reason;
      640  }

⏺ Now the use case. Let me check AppResult and the transaction query repository
  first:

  Ran 2 shell commands (ctrl+o to expand)

⏺ Now the use case:

⏺ Write(lib/features/transactions/application/reverse_transaction_use_case.dart)
  ⎿  Wrote 127 lines to lib/features/transactions/application/reverse_trans
     action_use_case.dart
      1 import 'package:family_money_manager/core/application/app_result.
      2 import 'package:family_money_manager/features/ledger/data/ledger_
        repository.dart';
      3 import 'package:family_money_manager/features/ledger/domain/opera
      4 
      5 /// The longest a reversal reason may be.
      7 /// Long enough for a sentence explaining what went wrong, short 
        enough that it
      8 /// renders on one detail row without truncation becoming the nor
      9 const int maxReversalReasonLength = 280;
     … +142 lines (ctrl+o to expand)

  Searched for 1 pattern (ctrl+o to expand)
  ⎿  Found 3 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Update(lib/features/transactions/application/reverse_transaction_use_case.dart
        )
  ⎿  Added 1 line
      1  import 'package:family_money_manager/core/application/app_result
         .dart';
      2  import 'package:family_money_manager/features/ledger/data/ledger
         _repository.dart';
      3 +import 'package:family_money_manager/features/ledger/domain/chil
        +d_withdrawal_audit.dart';                                       
      4  import 'package:family_money_manager/features/ledger/domain/oper
         ation.dart';
      5  
      6  /// The longest a reversal reason may be.

  Searched for 2 patterns, ran 2 shell commands (ctrl+o to expand)

⏺ Update(lib/features/transactions/application/reverse_transaction_use_case.dart
        )
  ⎿  Added 3 lines, removed 1 line
       96      } on DuplicateReversalError {
       97        // The original already carries a reversal. Distinct fro
           m the id conflict
       98        // above, and the screen says so — an operation is rever
           sed once.
       99 -      return const AppDuplicateConflict(messageKey: 'errorAlre
          -adyReversed');                                                
       99 +      return const AppDuplicateConflict(                      
      100 +        messageKey: 'errorOperationAlreadyReversed',          
      101 +      );                                                      
      102      } on MissingProtectedWithdrawalAuditError {
      103        // Reversing an operation whose reversal would debit a p
           rotected account
      104        // needs the protected-withdrawal flow, which this use c
           ase does not

  Searched for 2 patterns, ran 6 shell commands (ctrl+o to expand)

⏺ Now the router — the reverse route and root-push detail:

⏺ Update(lib/app/app_router.dart)
  ⎿  Added 11 lines
      57  /// the same [StatefulShellRoute] page identity — avoiding dupl
          icate Navigator
      58  /// page keys when stacking shell destinations via `push`.
      59  abstract final class AppRouter {
      60 +  /// Navigator that owns full-screen detail and correction rou
         +tes.                                                           
      61 +  ///                                                          
      62 +  /// Detail screens are pushed above the shell rather than ins
         +ide a branch.                                                  
      63 +  /// Without this, opening an account from Home switches the v
         +isible tab to                                                  
      64 +  /// More and discards Home's scroll position — the destinatio
         +n decides which                                                
      65 +  /// tab you are on, which is backwards. Above the shell there
         + is no bottom                                                  
      66 +  /// navigation on a detail screen, and popping returns to whe
         +rever you came                                                 
      67 +  /// from with its state intact.                              
      68 +  static final rootNavigatorKey = GlobalKey<NavigatorState>(); 
      69 +                                                               
      70    static GoRouter create(WidgetRef ref) {
      71      return GoRouter(
      72 +      navigatorKey: rootNavigatorKey,                          
      73        initialLocation: '/dashboard',
      74        debugLogDiagnostics: false,
      75        errorBuilder: (context, state) => AppErrorScreen(error: s
          tate.error),

⏺ Update(lib/app/app_router.dart)
  ⎿  Added 14 lines
      157                          ),
      158                        ],
      159                      ),
      160 +                    // Declared after 'new' deliberately: go_r
          +outer matches                                                 
      161 +                    // siblings in order, and ':operationId' w
          +ould otherwise                                                
      162 +                    // swallow '/transactions/new' as an opera
          +tion id.                                                      
      163                      GoRoute(
      164                        path: ':operationId',
      165 +                      parentNavigatorKey: rootNavigatorKey,   
      166                        builder: (context, state) => Transaction
           DetailScreen(
      167                          operationId: state.pathParameters['ope
           rationId']!,
      168                        ),
      169 +                      routes: [                               
      170 +                        GoRoute(                              
      171 +                          path: 'reverse',                    
      172 +                          parentNavigatorKey: rootNavigatorKey
          +,                                                             
      173 +                          builder: (context, state) => Reverse
          +TransactionScreen(                                            
      174 +                            operationId:                      
      175 +                                state.pathParameters['operatio
          +nId']!,                                                       
      176 +                          ),                                  
      177 +                        ),                                    
      178 +                      ],                                      
      179                      ),
      180                    ],
      181                  ),

⏺ Update(lib/app/app_router.dart)
  ⎿  Added 1 line
      338                      ),
      339                      GoRoute(
      340                        path: ':accountId',
      341 +                      parentNavigatorKey: rootNavigatorKey,   
      342                        builder: (context, state) => AccountDeta
           ilScreen(
      343                          accountId: state.pathParameters['accou
           ntId']!,
      344                        ),

  Read 1 file, ran 7 shell commands (ctrl+o to expand)
⏺ Now the reversal screen:

⏺ Write(lib/features/transactions/presentation/reverse_transaction_screen.dart)
  ⎿  Wrote 341 lines to
     lib/features/transactions/presentation/reverse_transaction_screen.dart
       1 /// The append-only correction.
       3 /// The one screen in the product where the UI has to teach the 
         data model
       4 /// rather than hide it: there is no edit and no delete, so a mi
       5 /// by adding an opposing entry that points at the original, and
          both stay
         ded* — before,
       7 /// after, and the net — instead of asking "are you sure".
       8 library;
      10 import 'package:family_money_manager/app/app_theme.dart';
     … +382 lines (ctrl+o to expand)

⏺ Now the providers and router import:

⏺ Update(lib/features/transactions/presentation/providers/transaction_providers.
        dart)
  ⎿  Added 8 lines
      61    );
      62  });
      63  
      64 +final reverseTransactionUseCaseProvider = Provider<ReverseTrans
         +actionUseCase>((                                               
      65 +  ref,                                                         
      66 +) {                                                            
      67 +  return ReverseTransactionUseCase(                            
      68 +    ledgerRepository: ref.watch(ledgerRepositoryProvider),     
      69 +  );                                                           
      70 +});                                                            
      71 +                                                               
      72  final getTransactionHistoryUseCaseProvider =
      73      Provider<GetTransactionHistoryUseCase>((ref) {
      74        return GetTransactionHistoryUseCase(
  ⎿  Found 8 new diagnostic issues in 1 file (ctrl+o to expand)

  Ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 10 new diagnostic issues in 2 files (ctrl+o to expand)

⏺ Update(lib/features/transactions/presentation/reverse_transaction_screen.dart)
  ⎿  Added 1 line, removed 1 line
      86      return AppScreenScaffold(
      87        title: Text(l10n.reversalSheetTitle),
      88        body: detailAsync.when(
      89 -        loading: () => AppLoadingState(label: l10n.loadingLabel
         -),                                                             
      89 +        loading: () => AppLoadingState(message: l10n.loadingLab
         +el),                                                           
      90          error: (_, _) => AppErrorState(message: l10n.errorGener
          ic),
      91          data: (summary) {
      92            if (summary == null) return AppErrorState(message: l1
          0n.errorGeneric);

⏺ Update(lib/features/transactions/presentation/reverse_transaction_screen.dart)
  ⎿  Added 4 lines, removed 5 lines
      160            // Back to the list, where the counter-entry appears
            above the
      161            // original and both stay visible.
      162            context.go('/transactions');
      163 -        case AppNotFound():                                   
      164 -          setState(() => _failure = l10n.errorGeneric);       
      163          case AppInsufficientFunds():
      164            setState(() => _failure = l10n.errorInsufficientFund
           s);
      167 -        case AppValidationFailure(:final messageKey) ||       
      168 -            AppDuplicateConflict(:final messageKey):          
      165 +        case AppValidationFailure(:final messageKey):         
      166            setState(() => _failure = resolveMessageKey(l10n, me
           ssageKey));
      170 -        default:                                              
      167 +        case AppDuplicateConflict(:final messageKey):         
      168 +          setState(() => _failure = resolveMessageKey(l10n, me
          +ssageKey));                                                   
      169 +        case AppResult<String>():                             
      170            setState(() => _failure = l10n.errorGeneric);
      171        }
      172      } finally {

⏺ Update(lib/features/transactions/presentation/reverse_transaction_screen.dart)
  ⎿  User rejected      lib/features/transactions/presentation/reverse_transacti
     update to          on_screen.dart

✻ Churned for 14m 44s

❯ re-ask for the last update                                                    
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Re-requesting the same edit — this is the analyzer's use_null_aware_elements
  lint on line 302 of reverse_transaction_screen.dart, replacing the if-guarded
  set element with the null-aware marker:

⏺ Update(lib/features/transactions/presentation/reverse_transaction_screen.dart)
  ⎿  Added 1 line, removed 1 line
      299                children: [
      300                  FilterChipGroup<ReversalReasonPreset>(
      301                    options: ReversalReasonPreset.values,
      302 -                  selected: {if (_selectedPreset != null) _sel
          -ectedPreset!},                                                
      302 +                  selected: {?_selectedPreset},               
      303                    labelOf: (preset) => reversalReasonPresetLab
           el(l10n, preset),
      304                    onChanged: (selection) {
      305                      final preset = selection.firstOrNull;

⏺ Now the router import, then analyze:

⏺ Update(lib/app/app_router.dart)
  ⎿  Added 1 line
      39  import 'package:family_money_manager/features/transactions/pres
          entation/expense_review_screen.dart';
      40  import 'package:family_money_manager/features/transactions/pres
          entation/income_form_screen.dart';
      41  import 'package:family_money_manager/features/transactions/pres
          entation/income_review_screen.dart';
      42 +import 'package:family_money_manager/features/transactions/pres
         +entation/reverse_transaction_screen.dart';                     
      43  import 'package:family_money_manager/features/transactions/pres
          entation/transaction_detail_screen.dart';
      44  import 'package:family_money_manager/features/transactions/pres
          entation/transactions_screen.dart';
      45  import 'package:family_money_manager/features/transactions/pres
          entation/transfer_form_screen.dart';

  Ran 1 shell command (ctrl+o to expand)

⏺ Analyzer clean. Now the transaction detail screen needs the entry point to the
  reversal — plus its D1/D2 rebuild:

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)

⏺ Write(lib/features/transactions/presentation/transaction_detail_screen.dart)
  ⎿  Added 176 lines, removed 98 lines
       1 +/// A single operation, and the append-only correction that can
         + follow it.                                                    
       2 +///                                                            
       3 +/// There is no edit and no delete on this screen, and rather t
         +han hiding that,                                               
       4 +/// the screen names it: a mistake is fixed by adding a reversi
         +ng entry that                                                  
       5 +/// points at this one, and both stay in the ledger. The user l
         +earns the data                                                 
       6 +/// model by reading their own transaction.                    
       7 +library;                                                       
       8 +                                                               
       9 +import 'package:family_money_manager/app/app_theme.dart';      
      10 +import 'package:family_money_manager/core/financial/ledger_enum
         +s.dart';                                                       
      11  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
      12  import 'package:family_money_manager/core/localization/enum_lab
          el_helpers.dart';
      13 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
      14  import 'package:family_money_manager/core/presentation/theme/ap
          p_theme_extensions.dart';
      15  import 'package:family_money_manager/features/transactions/doma
          in/transaction_summary.dart';
      16  import 'package:family_money_manager/features/transactions/pres
          entation/category_label_helper.dart';
      17  import 'package:family_money_manager/features/transactions/pres
          entation/providers/transaction_providers.dart';
      18  import 'package:flutter/material.dart';
      19  import 'package:flutter_riverpod/flutter_riverpod.dart';
      20 +import 'package:go_router/go_router.dart';                     
      21  
      22  const _householdId = 'household-v1';
      23  
     ...
      34        transactionDetailProvider((operationId, _householdId)),
      35      );
      36  
      25 -    return Scaffold(                                           
      26 -      appBar: AppBar(title: Text(l10n.transactionDetailTitle)),
      37 +    return AppScreenScaffold(                                  
      38 +      title: Text(l10n.transactionDetailTitle),                
      39        body: detailAsync.when(
      28 -        loading: () => Center(child: Text(l10n.loadingLabel)), 
      29 -        error: (_, _) => Center(child: Text(l10n.errorGeneric))
         -,                                                              
      40 +        loading: () => AppLoadingState(message: l10n.loadingLab
         +el),                                                           
      41 +        error: (_, _) => AppErrorState(message: l10n.errorGener
         +ic),                                                           
      42          data: (summary) {
      31 -          if (summary == null) {                               
      32 -            return Center(child: Text(l10n.errorGeneric));     
      33 -          }                                                    
      43 +          if (summary == null) return AppErrorState(message: l1
         +0n.errorGeneric);                                              
      44            return _DetailBody(summary: summary);
      45          },
      46        ),
      47 +      bottomBar: detailAsync.maybeWhen(                        
      48 +        data: (summary) {                                      
      49 +          if (summary == null) return null;                    
      50 +          // An operation is reversed once. The slot states why
         + the action is                                                 
      51 +          // gone rather than silently dropping it, so the abse
         +nce is                                                         
      52 +          // explained rather than mysterious.                 
      53 +          if (summary.operation.isReversed) {                  
      54 +            return AppBottomActionBar(                         
      55 +              child: AppInlineNotice(                          
      56 +                message: l10n.detailAlreadyReversedNoAction,   
      57 +                tone: AppNoticeTone.info,                      
      58 +              ),                                               
      59 +            );                                                 
      60 +          }                                                    
      61 +          return AppBottomActionBar(                           
      62 +            child: SecondaryActionButton(                      
      63 +              label: l10n.detailAddReversalAction,             
      64 +              onPressed: () =>                                 
      65 +                  context.push('/transactions/$operationId/reve
         +rse'),                                                         
      66 +            ),                                                 
      67 +          );                                                   
      68 +        },                                                     
      69 +        orElse: () => null,                                    
      70 +      ),                                                       
      71      );
      72    }
      73  }
     ...
       80    @override
       81    Widget build(BuildContext context) {
       82      final l10n = AppLocalizations.of(context);
       83 +    final colors = context.financialColors;                   
       84      final op = summary.operation;
       85  
       51 -    return ListView(                                          
       52 -      padding: const EdgeInsets.all(16),                      
       53 -      children: [                                             
       54 -        Card(                                                 
       55 -          child: Padding(                                     
       56 -            padding: const EdgeInsets.all(16),                
       86 +    final direction = switch (op.type) {                      
       87 +      OperationType.income => FinancialAmountDirection.inflow,
       88 +      OperationType.transfer => FinancialAmountDirection.inter
          +nal,                                                          
       89 +      _ => FinancialAmountDirection.outflow,                  
       90 +    };                                                        
       91 +    // A reversed operation's amount goes quiet rather than ke
          +eping its class                                               
       92 +    // colour: its effect on every balance is now zero, and co
          +louring it as                                                 
       93 +    // live money would contradict the banner directly above i
          +t.                                                            
       94 +    final tone = op.isReversed                                
       95 +        ? FinancialAmountTone.muted                           
       96 +        : switch (op.type) {                                  
       97 +            OperationType.income => FinancialAmountTone.income
          +,                                                             
       98 +            OperationType.transfer => FinancialAmountTone.tran
          +sfer,                                                         
       99 +            _ => FinancialAmountTone.expense,                 
      100 +          };                                                  
      101 +                                                              
      102 +    return ResponsiveContentContainer(                        
      103 +      child: ListView(                                        
      104 +        padding: const EdgeInsetsDirectional.only(            
      105 +          top: AppTheme.space16,                              
      106 +          bottom: AppTheme.space32,                           
      107 +        ),                                                    
      108 +        children: [                                           
      109 +          if (op.isReversed) ...[                             
      110 +            Padding(                                          
      111 +              padding: const EdgeInsets.symmetric(            
      112 +                horizontal: AppTheme.space16,                 
      113 +              ),                                              
      114 +              child: AppInlineNotice(                         
      115 +                message: l10n.detailReversedBannerBody(op.upda
          +tedAt),                                                       
      116 +                tone: AppNoticeTone.info,                     
      117 +                icon: Icons.undo,                             
      118 +              ),                                              
      119 +            ),                                                
      120 +            const SizedBox(height: AppTheme.space16),         
      121 +          ],                                                  
      122 +          Padding(                                            
      123 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
      124              child: Column(
      125                crossAxisAlignment: CrossAxisAlignment.start,
      126                children: [
       60 -                Row(                                          
      127 +                Wrap(                                         
      128 +                  spacing: AppTheme.space8,                   
      129 +                  runSpacing: AppTheme.space8,                
      130 +                  crossAxisAlignment: WrapCrossAlignment.cente
          +r,                                                            
      131                    children: [
      132                      Text(
      133                        operationTypeLabel(l10n, op.type),
       64 -                      style: Theme.of(context).textTheme.title
          -Medium?.copyWith(                                             
       65 -                        fontWeight: FontWeight.bold,          
       66 -                      ),                                      
      134 +                      style: context.textRoles.cardTitle,     
      135                      ),
       68 -                    const SizedBox(width: 8),                 
       69 -                    if (op.isReversed)                        
       70 -                      Container(                              
       71 -                        padding: const EdgeInsets.symmetric(  
       72 -                          horizontal: 6,                      
       73 -                          vertical: 2,                        
       74 -                        ),                                    
       75 -                        decoration: BoxDecoration(            
       76 -                          color: context.financialColors.secon
          -darySurface,                                                  
       77 -                          borderRadius: BorderRadius.circular(
          -4),                                                           
       78 -                        ),                                    
       79 -                        child: Text(                          
       80 -                          l10n.transactionReversed,           
       81 -                          style: Theme.of(context).textTheme.l
          -abelSmall                                                     
       82 -                              ?.copyWith(                     
       83 -                                color: context.financialColors
          -.secondaryText,                                               
       84 -                              ),                              
       85 -                        ),                                    
       86 -                      ),                                      
      136 +                    StatusBadge(                              
      137 +                      label: op.isReversed                    
      138 +                          ? l10n.transactionReversed          
      139 +                          : l10n.detailStatusPosted,          
      140 +                      foreground: op.isReversed               
      141 +                          ? colors.secondaryText              
      142 +                          : colors.success,                   
      143 +                    ),                                        
      144                    ],
      145                  ),
       89 -                const SizedBox(height: 12),                   
       90 -                Text(                                         
       91 -                  '${op.totalAmountMinorUnits} ${op.currencyCo
          -de}',                                                         
       92 -                  style: Theme.of(context).textTheme.headlineM
          -edium,                                                        
      146 +                const SizedBox(height: AppTheme.space12),     
      147 +                // Was previously rendered as raw minor units 
          +— 382.50 EGP                                                  
      148 +                // printed as "38250 EGP". The one component t
          +hat turns a                                                   
      149 +                // number into pixels owns the scale, the sign
          +, the bidi                                                    
      150 +                // isolation and the screen-reader phrasing.  
      151 +                FinancialAmountText(                          
      152 +                  minorUnits: op.totalAmountMinorUnits,       
      153 +                  currencyCode: op.currencyCode,              
      154 +                  tone: tone,                                 
      155 +                  direction: direction,                       
      156 +                  size: FinancialAmountSize.display,          
      157 +                  isStruckThrough: op.isReversed,             
      158                  ),
      159                ],
      160              ),
      161            ),
       97 -        ),                                                    
       98 -        const SizedBox(height: 12),                           
       99 -        _infoTile(context, l10n.fieldEffectiveDate, op.effecti
          -veDate),                                                      
      100 -        if (summary.categoryCode != null)                     
      101 -          _infoTile(                                          
      102 -            context,                                          
      103 -            l10n.fieldCategory,                               
      104 -            categoryLabelFromCode(l10n, summary.categoryCode!)
          -,                                                             
      162 +          const SizedBox(height: AppTheme.space24),           
      163 +          AppReviewSection(                                   
      164 +            title: l10n.detailsLabel,                         
      165 +            rows: [                                           
      166 +              AppReviewRowData(                               
      167 +                label: l10n.fieldEffectiveDate,               
      168 +                value: op.effectiveDate,                      
      169 +              ),                                              
      170 +              if (summary.categoryCode case final String code)
      171 +                AppReviewRowData(                             
      172 +                  label: l10n.fieldCategory,                  
      173 +                  value: categoryLabelFromCode(l10n, code),   
      174 +                ),                                            
      175 +              if (op.sourceAccountId case final String id)    
      176 +                AppReviewRowData(label: l10n.fieldSourceAccoun
          +t, value: id),                                                
      177 +              if (op.destinationAccountId case final String id
          +)                                                             
      178 +                AppReviewRowData(                             
      179 +                  label: l10n.fieldDestinationAccount,        
      180 +                  value: id,                                  
      181 +                ),                                            
      182 +              if (summary.spenderMemberId case final String id
          +)                                                             
      183 +                AppReviewRowData(label: l10n.fieldSpender, val
          +ue: id),                                                      
      184 +              if (summary.beneficiaryMemberId case final Strin
          +g id)                                                         
      185 +                AppReviewRowData(label: l10n.fieldBeneficiary,
          + value: id),                                                  
      186 +              if (summary.scope case final scope?)            
      187 +                AppReviewRowData(                             
      188 +                  label: l10n.fieldScope,                     
      189 +                  value: expenseScopeLabel(l10n, scope),      
      190 +                ),                                            
      191 +              AppReviewRowData(                               
      192 +                label: l10n.fieldRecurring,                   
      193 +                value: summary.isRecurring                    
      194 +                    ? l10n.recurringYes                       
      195 +                    : l10n.recurringOneTime,                  
      196 +              ),                                              
      197 +              if (summary.note case final String note)        
      198 +                AppReviewRowData(label: l10n.fieldNote, value:
          + note),                                                       
      199 +              // The reversal's own reason, shown wherever the
          + reversal is                                                  
      200 +              // opened. This is the audit value of an append-
          +only correction:                                              
      201 +              // "reversed" says nothing, "entered twice" says
          + everything.                                                  
      202 +              if (op.reversalReason case final String reason) 
      203 +                AppReviewRowData(label: l10n.reversalReasonLab
          +el, value: reason),                                           
      204 +            ],                                                
      205            ),
      106 -        if (op.sourceAccountId != null)                       
      107 -          _infoTile(context, l10n.fieldSourceAccount, op.sourc
          -eAccountId!),                                                 
      108 -        if (op.destinationAccountId != null)                  
      109 -          _infoTile(                                          
      110 -            context,                                          
      111 -            l10n.fieldDestinationAccount,                     
      112 -            op.destinationAccountId!,                         
      113 -          ),                                                  
      114 -        if (summary.spenderMemberId != null)                  
      115 -          _infoTile(context, l10n.fieldSpender, summary.spende
          -rMemberId!),                                                  
      116 -        if (summary.beneficiaryMemberId != null)              
      117 -          _infoTile(                                          
      118 -            context,                                          
      119 -            l10n.fieldBeneficiary,                            
      120 -            summary.beneficiaryMemberId!,                     
      121 -          ),                                                  
      122 -        if (summary.scope != null)                            
      123 -          _infoTile(                                          
      124 -            context,                                          
      125 -            l10n.fieldScope,                                  
      126 -            expenseScopeLabel(l10n, summary.scope!),          
      127 -          ),                                                  
      128 -        _infoTile(                                            
      129 -          context,                                            
      130 -          l10n.fieldRecurring,                                
      131 -          summary.isRecurring ? l10n.recurringYes : l10n.recur
          -ringOneTime,                                                  
      132 -        ),                                                    
      133 -        if (summary.note != null)                             
      134 -          _infoTile(context, l10n.fieldNote, summary.note!),  
      135 -      ],                                                      
      136 -    );                                                        
      137 -  }                                                           
      138 -                                                              
      139 -  Widget _infoTile(BuildContext context, String label, String 
          -value) {                                                      
      140 -    return Padding(                                           
      141 -      padding: const EdgeInsets.symmetric(vertical: 6),       
      142 -      child: Row(                                             
      143 -        crossAxisAlignment: CrossAxisAlignment.start,         
      144 -        children: [                                           
      145 -          SizedBox(                                           
      146 -            width: 150,                                       
      206 +          const SizedBox(height: AppTheme.space24),           
      207 +          Padding(                                            
      208 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
      209              child: Text(
      148 -              label,                                          
      149 -              style: Theme.of(context).textTheme.bodyMedium?.c
          -opyWith(                                                      
      150 -                color: Theme.of(context).colorScheme.outline, 
      210 +              l10n.detailRecordedAt(op.recordedAt.toIso8601Str
          +ing()),                                                       
      211 +              style: context.textRoles.supportingMeta.copyWith
          +(                                                             
      212 +                color: colors.secondaryText,                  
      213                ),
      214              ),
      215            ),
      154 -          Expanded(                                           
      155 -            child: Text(                                      
      156 -              value,                                          
      157 -              style: Theme.of(                                
      158 -                context,                                      
      159 -              ).textTheme.bodyMedium?.copyWith(fontWeight: Fon
          -tWeight.w600),                                                
      216 +          const SizedBox(height: AppTheme.space24),           
      217 +          // The append-only explainer. Permanent, not conditi
          +onal: it is how                                               
      218 +          // the screen answers "where is edit" before the use
          +r goes looking.                                               
      219 +          Padding(                                            
      220 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
      221 +            child: Column(                                    
      222 +              crossAxisAlignment: CrossAxisAlignment.start,   
      223 +              children: [                                     
      224 +                Text(                                         
      225 +                  l10n.detailNoEditNoDeleteTitle,             
      226 +                  style: context.textRoles.sectionTitle,      
      227 +                ),                                            
      228 +                const SizedBox(height: AppTheme.space8),      
      229 +                Text(                                         
      230 +                  op.isReversed                               
      231 +                      ? l10n.detailEntriesStillInLedgerNote   
      232 +                      : l10n.detailNoEditNoDeleteBody,        
      233 +                  style: context.textRoles.body.copyWith(     
      234 +                    color: colors.secondaryText,              
      235 +                  ),                                          
      236 +                ),                                            
      237 +              ],                                              
      238              ),
      239            ),
      240          ],

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)
  ⎿  Found 2 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now tests for the new behaviour:

  Ran 1 shell command (ctrl+o to expand)
⏺ Write(test/unit/features/transactions/reverse_transaction_use_case_test.dart)
  ⎿  Wrote 189 lines to
     test/unit/features/transactions/reverse_transaction_use_case_test.dart
       1 /// The one path a user-initiated reversal takes into the ledger
       2 ///
         n ledger must
       4 /// say why. The repository will reverse without a reason becaus
       5 /// flows need that; this use case is what makes the reason non-
       6 /// what turns every low-level failure into something a screen c
       7 library;
       8 
         .dart';
         _repository.dart';
     … +204 lines (ctrl+o to expand)

  Ran 1 shell command (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Update(test/unit/features/transactions/reverse_transaction_use_case_test.dart)
  ⎿  Added 5 lines, removed 1 line
      16  import '../../../helpers/fake_ledger_repository.dart';
      17  
      18  /// A fake that records what it was asked to do and can be told
           to fail.
      19 -final class _RecordingLedgerRepository extends FakeLedgerReposi
         -tory {                                                         
      19 +///                                                            
      20 +/// Only [reverseOperation] is implemented. Every other member 
         +throws through                                                 
      21 +/// [noSuchMethod], so a use case that reaches for anything els
         +e fails loudly                                                 
      22 +/// instead of silently receiving an empty result.             
      23 +final class _RecordingLedgerRepository implements LedgerReposit
         +ory {                                                          
      24    final List<ReverseOperationParams> reversals = [];
      25  
      26    IdempotentOperationResult result = IdempotentOperationResult.
          created;

  Ran 1 shell command (ctrl+o to expand)

⏺ 14/14. Now a DB test proving the reason actually persists, and a widget test
  for the screen:

  Ran 3 shell commands (ctrl+o to expand)

⏺ Write(test/database/reversal_reason_persistence_db_test.dart)
  ⎿  Wrote 151 lines to
     test/database/reversal_reason_persistence_db_test.dart
       1 /// The reversal reason survives the round trip, and cannot be e
       2 ///
         roves it is
       4 /// actually written, read back on the domain object, kept off t
       5 /// and frozen by the append-only guard — which together are wha
       6 /// reason an audit field rather than a form value that happens 
       7 library;
       8 
         dart';
         s.dart';
     … +163 lines (ctrl+o to expand)

  Searched for 1 pattern, ran 6 shell commands (ctrl+o to expand)
  ⎿  Found 2 new diagnostic issues in 1 file (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Update(test/database/reversal_reason_persistence_db_test.dart)
  ⎿  Added 1 line, removed 1 line
      61        ),
      62      );
      63      await ledgerRepo.recordIncome(
      64 -      const RecordIncomeParams(                                
      64 +      RecordIncomeParams(                                      
      65          operationId: 'op-fund',
      66          householdId: _householdId,
      67          destinationAccountId: 'acc-reason',

⏺ Now the widget test for the reversal screen:

  Ran 3 shell commands (ctrl+o to expand)

⏺ Write(test/widget/features/transactions/reverse_transaction_screen_test.dart)
  ⎿  Wrote 270 lines to
     test/widget/features/transactions/reverse_transaction_screen_test.dart
       1 /// The reversal screen.
       3 /// What is being asserted is the teaching, not the plumbing: th
         e screen shows
          not submit
         he missing
       6 /// action instead of hiding it, and a failed write stays on scr
       7 library;
       8 
         .dart';
         dart';
     … +303 lines (ctrl+o to expand)

  Ran 3 shell commands (ctrl+o to expand)

⏺ Update(test/widget/features/transactions/reverse_transaction_screen_test.dart)
  ⎿  Added 3 lines
      173      tester,
      174    ) async {
      175      await tester.pumpWidget(_buildApp(summary: _summary()));
      176 +    // Twice: the operation resolves on the first frame, the a
          +ccount name it                                                
      177 +    // is labelled with on the second.                        
      178      await tester.pump();
      179 +    await tester.pump();                                      
      180  
      181      final l10n = _l10n(tester);
      182      expect(

  Ran 1 shell command (ctrl+o to expand)

⏺ All 8 pass. Now a detail-screen test covering the amount fix and the route
  entry point:

⏺ Write(test/widget/features/transactions/transaction_detail_screen_test.dart)
  ⎿  Wrote 185 lines to
     test/widget/features/transactions/transaction_detail_screen_test.dart
       1 /// Transaction detail.
       3 /// Two claims are under test. The amount is money, not a raw in
         teger — this
         een answers
       5 /// "where is edit" out loud: the append-only explainer is perma
       6 /// reversal is offered once, and an already-reversed operation 
         says why the
       8 library;
       9 
         .dart';
     … +203 lines (ctrl+o to expand)

  Ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Analyzer clean across the whole project. Full suite:

  Ran 2 shell commands (ctrl+o to expand)

⏺ Implemented

  Fixed the six migration regressions that the committed v19→v20 change had left
  behind. The true_schema_v{12,16,18} helpers build their table shapes by
  dumping CREATE TABLE DDL from a current database probe, so every "historical"
  fixture already carried reversal_reason and the migration under test died on a
  duplicate column. Fixed in the fixtures, not by making the production ALTER
  tolerant — a v19 database in the field genuinely lacks the column, and a
  fixture that has it is lying. New test/helpers/historical_table_shape.dart
  strips post-version columns from the freshly created tables; add an entry
  there whenever a migration calls addColumn. Two further failures were
  hardcoded 19 assertions, now db.schemaVersion.

  The reversal write path. reversal_reason is now actually written (nothing
  wrote it before), exposed on Operation, and kept off the original — a reason
  belongs to the correction. New ReverseTransactionUseCase is the only path the
  UI may take: it requires a non-empty reason, trims it, caps it at 280, and
  maps every low-level error to a renderable AppResult. The repository stays
  reason-optional because internal flows reverse without one.

  /transactions/:operationId/reverse, plus a rootNavigatorKey so transaction and
  account detail push above the shell — opening an account from Home no longer
  switches the tab to More and discards Home's scroll.

  ReverseTransactionScreen (D3): what will be added rather than "are you sure",
  before/after rows, the net stated as 0.00, four preset reasons that seed an
  editable field, destructive confirm, persistent inline failure.
  TransactionDetailScreen rebuilt around the append-only explainer with the
  reversal entry point; its amount now goes through FinancialAmountText — it was
  printing 382.50 EGP as 38250 EGP.

  38 new ARB keys in both locales (symmetric, 575 each), five registered in
  resolveMessageKey.

  Validation

  - flutter analyze — No issues found (whole project)
  - dart format --set-exit-if-changed lib test — clean, 338 files
  - flutter test — +1822 −2, from a baseline of +1785 −8

  The two remaining failures are the ones the handoff already recorded as
  pre-existing: budget_creation_screen_test "Currency dropdown present", and
  certificate_principal_protection_test INV-015. Neither is touched by this
  work.

  37 new tests: 14 use-case, 4 DB persistence (including that a recorded reason
  cannot be edited afterwards), 8 reversal screen, 5 detail screen, plus the
  repaired migration tests.

  Notes

  - Scope boundary I drew: root-push applied to transaction and account detail
  only — the two screens phase 8 touches. Budgets/goals/certificates detail
  routes still switch tabs; that's the navigation phase, where the shell/back
  tests get rewritten together. Flagging it because the app is inconsistent
  until then.
  - Not yet done in phase 8: the D1/D2 double-entry rows and the numbered
  lineage chain need an entriesForOperation query that doesn't exist, plus
  member/account name joins — the detail screen still prints raw UUIDs for
  accounts and members. The C1–C6 list is untouched. Both are the next chunk.
  - Your two decisions are still open and phase 8 has now put both on screen:
  the certificate-principal double classification, and the spouse-wallet
  exclusion from the headline balance.

✻ Churned for 9m 37s
❯ go ahead                                                                      

  Searched for 1 pattern, read 1 file, ran 3 shell commands (ctrl+o to expand)

⏺ Now the read model:

⏺ Write(lib/features/transactions/domain/transaction_detail.dart)
  ⎿  Wrote 110 lines to
     lib/features/transactions/domain/transaction_detail.dart
       1 import 'package:family_money_manager/core/financial/ledger_enums
       2 import 'package:family_money_manager/features/transactions/domai
       3 import 'package:meta/meta.dart';
       4 
         med.
       7 /// [TransactionSummary] carries account and member *ids*; a det
       8 /// to render "ةيصخش ةيدقن ةظفحم", not a UUID. Resolving that in
          the query is
         d one they
          join instead
     … +120 lines (ctrl+o to expand)

⏺ Update(lib/features/transactions/data/transaction_query_repository.dart)
  ⎿  Added 12 lines
      31      required String householdId,
      32    });
      33  
      34 +  /// Returns [operationDetail] plus its ledger lines, resolved
         + names, and the                                                
      35 +  /// other half of its reversal pair when it has one.         
      36 +  ///                                                          
      37 +  /// Separate from [operationDetail] because it costs three mo
         +re joins: list                                                 
      38 +  /// callers that only need the summary should not pay for the
         +m.                                                             
      39 +  ///                                                          
      40 +  /// Returns `null` when no matching operation exists in [hous
         +eholdId].                                                      
      41 +  Future<TransactionDetail?> operationDetailWithLedger({       
      42 +    required String operationId,                               
      43 +    required String householdId,                               
      44 +  });                                                          
      45 +                                                               
      46    /// Computes a spouse-wallet summary for a given date range.
      47    ///
      48    /// - [totalFunded]: sum of all transferIn credits to the spo
          use account.

⏺ Update(lib/features/transactions/data/transaction_query_repository.dart)
  ⎿  Added 1 line
      1 +import 'package:family_money_manager/features/transactions/domai
        +n/transaction_detail.dart';                                     
      2  import 'package:family_money_manager/features/transactions/domai
         n/transaction_filter.dart';
      3  import 'package:family_money_manager/features/transactions/domai
         n/transaction_summary.dart';
      4  import 'package:meta/meta.dart';

⏺ Now the Drift implementation:

⏺ Update(lib/features/transactions/data/drift_transaction_query_repository.dart)
  ⎿  Added 210 lines
      149      return rows.isEmpty ? null : _rowToSummary(rows.first);
      150    }
      151  
      152 +  // ── operationDetailWithLedger ────────────────────────────
          +──────────────────                                            
      153 +                                                              
      154 +  @override                                                   
      155 +  Future<TransactionDetail?> operationDetailWithLedger({      
      156 +    required String operationId,                              
      157 +    required String householdId,                              
      158 +  }) async {                                                  
      159 +    final summary = await operationDetail(                    
      160 +      operationId: operationId,                               
      161 +      householdId: householdId,                               
      162 +    );                                                        
      163 +    if (summary == null) return null;                         
      164 +                                                              
      165 +    final op = summary.operation;                             
      166 +                                                              
      167 +    // Debits before credits, then a stable tiebreak. The doub
          +le entry reads                                                
      168 +    // as a pair, and a pair that reorders between rebuilds is
          + unreadable.                                                  
      169 +    final entryRows = await _db                               
      170 +        .customSelect(                                        
      171 +          '''                                                 
      172 +      SELECT                                                  
      173 +        le.id, le.direction, le.account_id, le.amount_minor_un
          +its,                                                          
      174 +        le.currency_code, le.entry_type,                      
      175 +        fa.name AS account_name                               
      176 +      FROM ledger_entries le                                  
      177 +      LEFT JOIN financial_accounts fa                         
      178 +        ON fa.id = le.account_id AND fa.household_id = le.hous
          +ehold_id                                                      
      179 +      WHERE le.operation_id = ? AND le.household_id = ?       
      180 +      ORDER BY CASE le.direction WHEN 'debit' THEN 0 ELSE 1 EN
          +D, le.id                                                      
      181 +    ''',                                                      
      182 +          variables: [                                        
      183 +            Variable.withString(operationId),                 
      184 +            Variable.withString(householdId),                 
      185 +          ],                                                  
      186 +        )                                                     
      187 +        .get();                                               
      188 +                                                              
      189 +    final ledgerLines = entryRows                             
      190 +        .map(                                                 
      191 +          (row) => OperationLedgerLine(                       
      192 +            entryId: row.read<String>('id'),                  
      193 +            direction: LedgerDirection.fromCode(row.read<Strin
          +g>('direction')),                                             
      194 +            accountId: row.read<String>('account_id'),        
      195 +            // Falls back to the id rather than to blank: a na
          +meless row reads                                              
      196 +            // as a rendering bug, an id reads as a missing ac
          +count.                                                        
      197 +            accountName:                                      
      198 +                row.readNullable<String>('account_name') ??   
      199 +                row.read<String>('account_id'),               
      200 +            amountMinorUnits: row.read<int>('amount_minor_unit
          +s'),                                                          
      201 +            currencyCode: row.read<String>('currency_code'),  
      202 +            entryType: LedgerEntryType.fromCode(row.read<Strin
          +g>('entry_type')),                                            
      203 +          ),                                                  
      204 +        )                                                     
      205 +        .toList();                                            
      206 +                                                              
      207 +    final accountNames = await _accountNames(householdId, {   
      208 +      ?op.sourceAccountId,                                    
      209 +      ?op.destinationAccountId,                               
      210 +    });                                                       
      211 +    final memberNames = await _memberNames(householdId, {     
      212 +      ?summary.spenderMemberId,                               
      213 +      ?summary.beneficiaryMemberId,                           
      214 +      op.createdBy,                                           
      215 +    });                                                       
      216 +                                                              
      217 +    return TransactionDetail(                                 
      218 +      summary: summary,                                       
      219 +      ledgerLines: ledgerLines,                               
      220 +      sourceAccountName: accountNames[op.sourceAccountId],    
      221 +      destinationAccountName: accountNames[op.destinationAccou
          +ntId],                                                        
      222 +      spenderName: memberNames[summary.spenderMemberId],      
      223 +      beneficiaryName: memberNames[summary.beneficiaryMemberId
          +],                                                            
      224 +      createdByName: memberNames[op.createdBy],               
      225 +      counterpart: await _counterpart(summary, householdId),  
      226 +    );                                                        
      227 +  }                                                           
      228 +                                                              
      229 +  /// The other half of a reversal pair, from whichever side i
          +s being viewed.                                               
      230 +  Future<ReversalCounterpart?> _counterpart(                  
      231 +    TransactionSummary summary,                               
      232 +    String householdId,                                       
      233 +  ) async {                                                   
      234 +    final op = summary.operation;                             
      235 +                                                              
      236 +    // Viewing the original: `reversedBy` names the correction
          + directly.                                                    
      237 +    // Viewing the reversal: nothing points forward, so the or
          +iginal is found                                               
      238 +    // by the link the reversal's own row carries back.       
      239 +    final (counterpartId, isReversingEntry) = switch (op) {   
      240 +      Operation(reversedBy: final String id) => (id, true),   
      241 +      Operation(type: OperationType.reversal) => (            
      242 +        await _originalOf(op.id, householdId),                
      243 +        false,                                                
      244 +      ),                                                      
      245 +      _ => (null, false),                                     
      246 +    };                                                        
      247 +    if (counterpartId == null) return null;                   
      248 +                                                              
      249 +    final rows = await _db                                    
      250 +        .customSelect(                                        
      251 +          '''                                                 
      252 +      SELECT                                                  
      253 +        o.id, o.effective_date, o.total_amount_minor_units, o.
          +currency_code,                                                
      254 +        o.reversal_reason, o.created_by,                      
      255 +        hm.display_name AS author_name                        
      256 +      FROM operations o                                       
      257 +      LEFT JOIN household_members hm                          
      258 +        ON hm.id = o.created_by AND hm.household_id = o.househ
          +old_id                                                        
      259 +      WHERE o.id = ? AND o.household_id = ?                   
      260 +      LIMIT 1                                                 
      261 +    ''',                                                      
      262 +          variables: [                                        
      263 +            Variable.withString(counterpartId),               
      264 +            Variable.withString(householdId),                 
      265 +          ],                                                  
      266 +        )                                                     
      267 +        .get();                                               
      268 +    if (rows.isEmpty) return null;                            
      269 +                                                              
      270 +    final row = rows.first;                                   
      271 +    // The reason lives on the reversing entry, so it is read 
          +from whichever                                                
      272 +    // of the two rows that is.                               
      273 +    final reason = isReversingEntry                           
      274 +        ? row.readNullable<String>('reversal_reason')         
      275 +        : op.reversalReason;                                  
      276 +                                                              
      277 +    return ReversalCounterpart(                               
      278 +      operationId: row.read<String>('id'),                    
      279 +      effectiveDate: row.read<String>('effective_date'),      
      280 +      totalAmountMinorUnits: row.read<int>('total_amount_minor
          +_units'),                                                     
      281 +      currencyCode: row.read<String>('currency_code'),        
      282 +      isReversingEntry: isReversingEntry,                     
      283 +      reason: reason,                                         
      284 +      authorName: row.readNullable<String>('author_name'),    
      285 +    );                                                        
      286 +  }                                                           
      287 +                                                              
      288 +  /// The operation a reversal answers, via the entry-level ba
          +ck link.                                                      
      289 +  ///                                                         
      290 +  /// `operations` carries no forward pointer from a reversal 
          +to its original —                                             
      291 +  /// only `ledger_entries.reversal_of_entry_id` does — so the
          + walk is entry →                                              
      292 +  /// original entry → its operation.                         
      293 +  Future<String?> _originalOf(String reversalId, String househ
          +oldId) async {                                                
      294 +    final rows = await _db                                    
      295 +        .customSelect(                                        
      296 +          '''                                                 
      297 +      SELECT original.operation_id AS original_operation_id   
      298 +      FROM ledger_entries rev                                 
      299 +      JOIN ledger_entries original ON original.id = rev.revers
          +al_of_entry_id                                                
      300 +      WHERE rev.operation_id = ? AND rev.household_id = ?     
      301 +        AND rev.reversal_of_entry_id IS NOT NULL              
      302 +      LIMIT 1                                                 
      303 +    ''',                                                      
      304 +          variables: [                                        
      305 +            Variable.withString(reversalId),                  
      306 +            Variable.withString(householdId),                 
      307 +          ],                                                  
      308 +        )                                                     
      309 +        .get();                                               
      310 +    return rows.isEmpty                                       
      311 +        ? null                                                
      312 +        : rows.first.read<String>('original_operation_id');   
      313 +  }                                                           
      314 +                                                              
      315 +  Future<Map<String, String>> _accountNames(                  
      316 +    String householdId,                                       
      317 +    Set<String> ids,                                          
      318 +  ) => _namesById(                                            
      319 +    ids: ids,                                                 
      320 +    householdId: householdId,                                 
      321 +    table: 'financial_accounts',                              
      322 +    nameColumn: 'name',                                       
      323 +  );                                                          
      324 +                                                              
      325 +  Future<Map<String, String>> _memberNames(                   
      326 +    String householdId,                                       
      327 +    Set<String> ids,                                          
      328 +  ) => _namesById(                                            
      329 +    ids: ids,                                                 
      330 +    householdId: householdId,                                 
      331 +    table: 'household_members',                               
      332 +    nameColumn: 'display_name',                               
      333 +  );                                                          
      334 +                                                              
      335 +  /// One `IN` query per table rather than one query per id.  
      336 +  ///                                                         
      337 +  /// [table] and [nameColumn] are literals from this file, ne
          +ver caller input.                                             
      338 +  Future<Map<String, String>> _namesById({                    
      339 +    required Set<String> ids,                                 
      340 +    required String householdId,                              
      341 +    required String table,                                    
      342 +    required String nameColumn,                               
      343 +  }) async {                                                  
      344 +    if (ids.isEmpty) return const {};                         
      345 +    final placeholders = List.filled(ids.length, '?').join(', 
          +');                                                           
      346 +    final rows = await _db                                    
      347 +        .customSelect(                                        
      348 +          'SELECT id, $nameColumn AS resolved_name FROM $table
          + '                                                            
      349 +          'WHERE household_id = ? AND id IN ($placeholders)', 
      350 +          variables: [                                        
      351 +            Variable.withString(householdId),                 
      352 +            ...ids.map(Variable.withString),                  
      353 +          ],                                                  
      354 +        )                                                     
      355 +        .get();                                               
      356 +    return {                                                  
      357 +      for (final row in rows)                                 
      358 +        row.read<String>('id'): row.read<String>('resolved_nam
          +e'),                                                          
      359 +    };                                                        
      360 +  }                                                           
      361 +                                                              
      362    // ── spouseWalletSummary ──────────────────────────────────
           ──────────────────
      363  
      364    @override

  Ran 1 shell command (ctrl+o to expand)

⏺ Now the provider, and a DB test proving the joins:

⏺ Update(lib/features/transactions/presentation/providers/transaction_providers.
        dart)
  ⎿  Added 15 lines
      108        );
      109      });
      110  
      111 +/// The detail screen's read: the operation, its ledger lines,
          + resolved names,                                              
      112 +/// and the other half of its reversal pair.                  
      113 +///                                                           
      114 +/// Kept separate from [transactionDetailProvider] so list cal
          +lers, which only                                              
      115 +/// need the summary, do not pay for the extra joins.         
      116 +final transactionDetailWithLedgerProvider =                   
      117 +    FutureProvider.family<TransactionDetail?, (String, String)
          +>((ref, args) {                                               
      118 +      final (operationId, householdId) = args;                
      119 +      final repo = ref.watch(transactionQueryRepositoryProvide
          +r);                                                           
      120 +      return repo.operationDetailWithLedger(                  
      121 +        operationId: operationId,                             
      122 +        householdId: householdId,                             
      123 +      );                                                      
      124 +    });                                                       
      125 +                                                              
      126  // ── Spouse wallet summary provider ─────────────────────────
           ───────────────────
      127  
      128  typedef SpouseWalletArgs = ({

  Ran 1 shell command (ctrl+o to expand)

⏺ Now the DB test for the query:

⏺ Write(test/database/transaction_detail_with_ledger_db_test.dart)
  ⎿  Wrote 231 lines to
     test/database/transaction_detail_with_ledger_db_test.dart
       1 /// The detail query: ledger lines, resolved names, and the reve
       2 ///
         and had no way
       4 /// to show the two sides of a double entry at all. These tests 
       5 /// that fix both, and the walk between the halves of a reversal
       6 /// what makes an append-only ledger navigable rather than merel
       7 library;
       8 
         dart';
         s.dart';
     … +246 lines (ctrl+o to expand)

  Ran 1 shell command (ctrl+o to expand)

⏺ The DB test caught a real gap — the query repo's mapper never read the new
  column:

  Searched for 1 pattern, ran 2 shell commands (ctrl+o to expand)

⏺ Now rebuild the detail screen on the richer read — the D1 ledger rows and the
  D2 chain:

  Ran 1 shell command (ctrl+o to expand)

⏺ Write(lib/features/transactions/presentation/transaction_detail_screen.dart)
  ⎿  Added 209 lines, removed 51 lines
       1 -/// A single operation, and the append-only correction that can
         - follow it.                                                    
       1 +/// A single operation, its real double entry, and the append-o
         +nly correction                                                 
       2 +/// that can follow it.                                        
       3  ///
       4  /// There is no edit and no delete on this screen, and rather t
          han hiding that,
       5  /// the screen names it: a mistake is fixed by adding a reversi
          ng entry that
       5 -/// points at this one, and both stay in the ledger. The user l
         -earns the data                                                 
       6 -/// model by reading their own transaction.                    
       6 +/// points at this one, and both stay in the ledger. Showing th
         +e debit and the                                                
       7 +/// credit is what makes "balances are derived, never stored" l
         +egible — the                                                   
       8 +/// user learns the data model by reading their own transaction
         +.                                                              
       9  library;
      10  
      11  import 'package:family_money_manager/app/app_theme.dart';
     ...
      14  import 'package:family_money_manager/core/localization/enum_lab
          el_helpers.dart';
      15  import 'package:family_money_manager/core/presentation/componen
          ts/components.dart';
      16  import 'package:family_money_manager/core/presentation/theme/ap
          p_theme_extensions.dart';
      15 -import 'package:family_money_manager/features/transactions/doma
         -in/transaction_summary.dart';                                  
      17 +import 'package:family_money_manager/features/transactions/doma
         +in/transaction_detail.dart';                                   
      18  import 'package:family_money_manager/features/transactions/pres
          entation/category_label_helper.dart';
      19  import 'package:family_money_manager/features/transactions/pres
          entation/providers/transaction_providers.dart';
      20  import 'package:flutter/material.dart';
     ...
      23  
      24  const _householdId = 'household-v1';
      25  
      24 -/// Shows full detail for a single operation with context metad
         -ata.                                                           
      26 +/// Shows full detail for a single operation with its ledger en
         +tries.                                                         
      27  class TransactionDetailScreen extends ConsumerWidget {
      28    const TransactionDetailScreen({required this.operationId, sup
          er.key});
      29  
     ...
      33    Widget build(BuildContext context, WidgetRef ref) {
      34      final l10n = AppLocalizations.of(context);
      35      final detailAsync = ref.watch(
      34 -      transactionDetailProvider((operationId, _householdId)),  
      36 +      transactionDetailWithLedgerProvider((operationId, _househ
         +oldId)),                                                       
      37      );
      38  
      39      return AppScreenScaffold(
     ...
      41        body: detailAsync.when(
      42          loading: () => AppLoadingState(message: l10n.loadingLab
          el),
      43          error: (_, _) => AppErrorState(message: l10n.errorGener
          ic),
      42 -        data: (summary) {                                      
      43 -          if (summary == null) return AppErrorState(message: l1
         -0n.errorGeneric);                                              
      44 -          return _DetailBody(summary: summary);                
      44 +        data: (detail) {                                       
      45 +          if (detail == null) return AppErrorState(message: l10
         +n.errorGeneric);                                               
      46 +          return _DetailBody(detail: detail);                  
      47          },
      48        ),
      49        bottomBar: detailAsync.maybeWhen(
      48 -        data: (summary) {                                      
      49 -          if (summary == null) return null;                    
      50 +        data: (detail) {                                       
      51 +          if (detail == null) return null;                     
      52            // An operation is reversed once. The slot states why
           the action is
      53            // gone rather than silently dropping it, so the abse
          nce is
      54            // explained rather than mysterious.
      53 -          if (summary.operation.isReversed) {                  
      55 +          if (detail.isNeutralised) {                          
      56              return AppBottomActionBar(
      57                child: AppInlineNotice(
      58                  message: l10n.detailAlreadyReversedNoAction,
     ...
       75  }
       76  
       77  class _DetailBody extends StatelessWidget {
       76 -  const _DetailBody({required this.summary});                 
       78 +  const _DetailBody({required this.detail});                  
       79  
       78 -  final TransactionSummary summary;                           
       80 +  final TransactionDetail detail;                             
       81  
       82    @override
       83    Widget build(BuildContext context) {
       84      final l10n = AppLocalizations.of(context);
       85      final colors = context.financialColors;
       86 +    final summary = detail.summary;                           
       87      final op = summary.operation;
       88 +    final isReversedOriginal = op.isReversed;                 
       89  
       90      final direction = switch (op.type) {
       91        OperationType.income => FinancialAmountDirection.inflow,
       92        OperationType.transfer => FinancialAmountDirection.inter
           nal,
       93 +      OperationType.reversal => FinancialAmountDirection.inflo
          +w,                                                            
       94        _ => FinancialAmountDirection.outflow,
       95      };
       91 -    // A reversed operation's amount goes quiet rather than ke
          -eping its class                                               
       92 -    // colour: its effect on every balance is now zero, and co
          -louring it as                                                 
       93 -    // live money would contradict the banner directly above i
          -t.                                                            
       94 -    final tone = op.isReversed                                
       96 +    // A neutralised operation's amount goes quiet rather than
          + keeping its                                                  
       97 +    // class colour: its effect on every balance is now zero, 
          +and colouring it                                              
       98 +    // as live money would contradict the banner directly abov
          +e it.                                                         
       99 +    final tone = detail.isNeutralised                         
      100          ? FinancialAmountTone.muted
      101          : switch (op.type) {
      102              OperationType.income => FinancialAmountTone.income
           ,
     ...
      111            bottom: AppTheme.space32,
      112          ),
      113          children: [
      109 -          if (op.isReversed) ...[                             
      110 -            Padding(                                          
      111 -              padding: const EdgeInsets.symmetric(horizontal: 
          -AppTheme.space16),                                            
      112 -              child: AppInlineNotice(                         
      114 +          if (isReversedOriginal) ...[                        
      115 +            _horizontal(                                      
      116 +              AppInlineNotice(                                
      117                  message: l10n.detailReversedBannerBody(op.upda
           tedAt),
      118                  tone: AppNoticeTone.info,
      119                  icon: Icons.undo,
     ...
      121              ),
      122              const SizedBox(height: AppTheme.space16),
      123            ],
      120 -          Padding(                                            
      121 -            padding: const EdgeInsets.symmetric(horizontal: Ap
          -pTheme.space16),                                              
      122 -            child: Column(                                    
      124 +          _horizontal(                                        
      125 +            Column(                                           
      126                crossAxisAlignment: CrossAxisAlignment.start,
      127                children: [
      128                  Wrap(
     ...
      135                        style: context.textRoles.cardTitle,
      136                      ),
      137                      StatusBadge(
      135 -                      label: op.isReversed                    
      138 +                      label: isReversedOriginal               
      139                            ? l10n.transactionReversed
      140                            : l10n.detailStatusPosted,
      138 -                      foreground: op.isReversed               
      141 +                      foreground: isReversedOriginal          
      142                            ? colors.secondaryText
      143                            : colors.success,
      144                      ),
      145                    ],
      146                  ),
      147                  const SizedBox(height: AppTheme.space12),
      145 -                // Was previously rendered as raw minor units 
          -— 382.50 EGP                                                  
      146 -                // printed as "38250 EGP". The one component t
          -hat turns a                                                   
      147 -                // number into pixels owns the scale, the sign
          -, the bidi                                                    
      148 -                // isolation and the screen-reader phrasing.  
      148 +                // The one component that turns a number into 
          +pixels owns the                                               
      149 +                // scale, the sign, the bidi isolation and the
          + phrasing. This                                               
      150 +                // screen printed raw minor units before — 382
          +.50 as "38250".                                               
      151                  FinancialAmountText(
      152                    minorUnits: op.totalAmountMinorUnits,
      153                    currencyCode: op.currencyCode,
      154                    tone: tone,
      155                    direction: direction,
      156                    size: FinancialAmountSize.display,
      155 -                  isStruckThrough: op.isReversed,             
      157 +                  isStruckThrough: isReversedOriginal,        
      158                  ),
      159                ],
      160              ),
      161            ),
      162 +          if (detail.counterpart case final ReversalCounterpar
          +t counterpart)                                                
      163 +            ..._chain(context, l10n, counterpart),            
      164 +          if (detail.ledgerLines.isNotEmpty) ...[             
      165 +            const SizedBox(height: AppTheme.space24),         
      166 +            SectionHeader(                                    
      167 +              title: isReversedOriginal                       
      168 +                  ? l10n.detailLedgerEntriesOriginalTitle     
      169 +                  : l10n.detailLedgerEntriesTitle,            
      170 +            ),                                                
      171 +            // The two sides, stated as debit and credit rathe
          +r than implied by                                             
      172 +            // a sign. Both use CurrencyAmountRow — no new com
          +ponent.                                                       
      173 +            for (final line in detail.ledgerLines)            
      174 +              CurrencyAmountRow(                              
      175 +                label: line.direction == LedgerDirection.debit
      176 +                    ? l10n.reviewDebitLabel(line.accountName) 
      177 +                    : l10n.reviewCreditLabel(line.accountName)
          +,                                                             
      178 +                minorUnits: line.amountMinorUnits,            
      179 +                currencyCode: line.currencyCode,              
      180 +                tone: detail.isNeutralised                    
      181 +                    ? FinancialAmountTone.muted               
      182 +                    : FinancialAmountTone.neutral,            
      183 +              ),                                              
      184 +            if (isReversedOriginal) ...[                      
      185 +              const SizedBox(height: AppTheme.space12),       
      186 +              _horizontal(                                    
      187 +                Text(                                         
      188 +                  l10n.detailEntriesStillInLedgerNote,        
      189 +                  style: context.textRoles.supportingMeta.copy
          +With(                                                         
      190 +                    color: colors.secondaryText,              
      191 +                  ),                                          
      192 +                ),                                            
      193 +              ),                                              
      194 +            ],                                                
      195 +          ],                                                  
      196            const SizedBox(height: AppTheme.space24),
      197            AppReviewSection(
      198              title: l10n.detailSectionTitle,
     ...
      206                    label: l10n.fieldCategory,
      207                    value: categoryLabelFromCode(l10n, code),
      208                  ),
      209 +              // Names, not UUIDs. The id remains the fallback
          + so a missing                                                 
      210 +              // join reads as missing data rather than as a b
          +lank row.                                                     
      211                if (op.sourceAccountId case final String id)
      174 -                AppReviewRowData(label: l10n.fieldSourceAccoun
          -t, value: id),                                                
      212 +                AppReviewRowData(                             
      213 +                  label: l10n.fieldSourceAccount,             
      214 +                  value: detail.sourceAccountName ?? id,      
      215 +                ),                                            
      216                if (op.destinationAccountId case final String id
           )
      217                  AppReviewRowData(
      218                    label: l10n.fieldDestinationAccount,
      178 -                  value: id,                                  
      219 +                  value: detail.destinationAccountName ?? id, 
      220                  ),
      221                if (summary.spenderMemberId case final String id
           )
      181 -                AppReviewRowData(label: l10n.fieldSpender, val
          -ue: id),                                                      
      222 +                AppReviewRowData(                             
      223 +                  label: l10n.fieldSpender,                   
      224 +                  value: detail.spenderName ?? id,            
      225 +                ),                                            
      226                if (summary.beneficiaryMemberId case final Strin
           g id)
      183 -                AppReviewRowData(label: l10n.fieldBeneficiary,
          - value: id),                                                  
      227 +                AppReviewRowData(                             
      228 +                  label: l10n.fieldBeneficiary,               
      229 +                  value: detail.beneficiaryName ?? id,        
      230 +                ),                                            
      231                if (summary.scope case final scope?)
      232                  AppReviewRowData(
      233                    label: l10n.fieldScope,
     ...
      242                if (summary.note case final String note)
      243                  AppReviewRowData(label: l10n.fieldNote, value:
            note),
      244                // The reversal's own reason, shown wherever the
            reversal is
      198 -              // opened. This is the audit value of an append-
          -only correction:                                              
      199 -              // "reversed" says nothing, "entered twice" says
          - everything.                                                  
      245 +              // opened: "reversed" says nothing, "entered twi
          +ce" says                                                      
      246 +              // everything.                                  
      247                if (op.reversalReason case final String reason)
      201 -                AppReviewRowData(                             
      202 -                  label: l10n.reversalReasonLabel,            
      203 -                  value: reason,                              
      204 -                ),                                            
      248 +                AppReviewRowData(label: l10n.reversalReasonLab
          +el, value: reason),                                           
      249              ],
      250            ),
      251            const SizedBox(height: AppTheme.space24),
      208 -          Padding(                                            
      209 -            padding: const EdgeInsets.symmetric(horizontal: Ap
          -pTheme.space16),                                              
      210 -            child: Text(                                      
      252 +          _horizontal(                                        
      253 +            Text(                                             
      254                l10n.detailRecordedAt(op.recordedAt.toIso8601Str
           ing()),
      255                style: context.textRoles.supportingMeta.copyWith
           (
      256                  color: colors.secondaryText,
     ...
      260            const SizedBox(height: AppTheme.space24),
      261            // The append-only explainer. Permanent, not conditi
           onal: it is how
      262            // the screen answers "where is edit" before the use
           r goes looking.
      220 -          Padding(                                            
      221 -            padding: const EdgeInsets.symmetric(horizontal: Ap
          -pTheme.space16),                                              
      222 -            child: Column(                                    
      263 +          _horizontal(                                        
      264 +            Column(                                           
      265                crossAxisAlignment: CrossAxisAlignment.start,
      266                children: [
      267                  Text(
     ...
      270                  ),
      271                  const SizedBox(height: AppTheme.space8),
      272                  Text(
      231 -                  op.isReversed                               
      232 -                      ? l10n.detailEntriesStillInLedgerNote   
      233 -                      : l10n.detailNoEditNoDeleteBody,        
      273 +                  l10n.detailNoEditNoDeleteBody,              
      274                    style: context.textRoles.body.copyWith(
      275                      color: colors.secondaryText,
      276                    ),
     ...
      282        ),
      283      );
      284    }
      285 +                                                              
      286 +  /// The lineage, numbered, with "you are here" on the step b
          +eing viewed.                                                  
      287 +  ///                                                         
      288 +  /// Two steps and a stated net of zero. Which step is which 
          +depends on which                                              
      289 +  /// half the user opened, so the pair is assembled from the 
          +counterpart                                                   
      290 +  /// rather than assuming the original is always first on scr
          +een.                                                          
      291 +  List<Widget> _chain(                                        
      292 +    BuildContext context,                                     
      293 +    AppLocalizations l10n,                                    
      294 +    ReversalCounterpart counterpart,                          
      295 +  ) {                                                         
      296 +    final op = detail.summary.operation;                      
      297 +    final viewingOriginal = counterpart.isReversingEntry;     
      298 +                                                              
      299 +    final here = _ChainStep(                                  
      300 +      step: viewingOriginal ? '1' : '2',                      
      301 +      title: viewingOriginal                                  
      302 +          ? l10n.detailChainStepOriginal('1', op.effectiveDate
          +)                                                             
      303 +          : l10n.detailChainStepReversal('2', op.effectiveDate
          +),                                                            
      304 +      caption: l10n.detailChainYouAreHere,                    
      305 +      minorUnits: op.totalAmountMinorUnits,                   
      306 +      currencyCode: op.currencyCode,                          
      307 +      direction: viewingOriginal                              
      308 +          ? FinancialAmountDirection.outflow                  
      309 +          : FinancialAmountDirection.inflow,                  
      310 +      operationId: null,                                      
      311 +    );                                                        
      312 +                                                              
      313 +    final other = _ChainStep(                                 
      314 +      step: viewingOriginal ? '2' : '1',                      
      315 +      title: viewingOriginal                                  
      316 +          ? l10n.detailChainStepReversal('2', counterpart.effe
          +ctiveDate)                                                    
      317 +          : l10n.detailChainStepOriginal('1', counterpart.effe
          +ctiveDate),                                                   
      318 +      caption: _counterpartCaption(l10n, counterpart),        
      319 +      minorUnits: counterpart.totalAmountMinorUnits,          
      320 +      currencyCode: counterpart.currencyCode,                 
      321 +      direction: viewingOriginal                              
      322 +          ? FinancialAmountDirection.inflow                   
      323 +          : FinancialAmountDirection.outflow,                 
      324 +      operationId: counterpart.operationId,                   
      325 +    );                                                        
      326 +                                                              
      327 +    final steps = viewingOriginal ? [here, other] : [other, he
          +re];                                                          
      328 +                                                              
      329 +    return [                                                  
      330 +      const SizedBox(height: AppTheme.space24),               
      331 +      SectionHeader(title: l10n.detailChainTitle),            
      332 +      for (final step in steps) step,                         
      333 +      // The net is stated, not implied: it is the whole claim
          + of an                                                        
      334 +      // append-only correction.                              
      335 +      CurrencyAmountRow(                                      
      336 +        label: l10n.reversalNetEffectOn(                      
      337 +          detail.sourceAccountName ?? detail.destinationAccoun
          +tName ?? '',                                                  
      338 +        ),                                                    
      339 +        minorUnits: 0,                                        
      340 +        currencyCode: op.currencyCode,                        
      341 +        isEmphasised: true,                                   
      342 +        showDivider: false,                                   
      343 +      ),                                                      
      344 +    ];                                                        
      345 +  }                                                           
      346 +                                                              
      347 +  String? _counterpartCaption(                                
      348 +    AppLocalizations l10n,                                    
      349 +    ReversalCounterpart counterpart,                          
      350 +  ) {                                                         
      351 +    // Only the reversing half carries a reason and an author 
          +worth naming.                                                 
      352 +    if (!counterpart.isReversingEntry) return null;           
      353 +    if (counterpart.reason case final String reason) {        
      354 +      return l10n.detailChainReasonBy(reason, counterpart.auth
          +orName ?? '');                                                
      355 +    }                                                         
      356 +    return null;                                              
      357 +  }                                                           
      358 +                                                              
      359 +  Widget _horizontal(Widget child) => Padding(                
      360 +    padding: const EdgeInsets.symmetric(horizontal: AppTheme.s
          +pace16),                                                      
      361 +    child: child,                                             
      362 +  );                                                          
      363  }
      364 +                                                              
      365 +/// One step of the reversal lineage.                         
      366 +class _ChainStep extends StatelessWidget {                    
      367 +  const _ChainStep({                                          
      368 +    required this.step,                                       
      369 +    required this.title,                                      
      370 +    required this.caption,                                    
      371 +    required this.minorUnits,                                 
      372 +    required this.currencyCode,                               
      373 +    required this.direction,                                  
      374 +    required this.operationId,                                
      375 +  });                                                         
      376 +                                                              
      377 +  final String step;                                          
      378 +  final String title;                                         
      379 +  final String? caption;                                      
      380 +  final int minorUnits;                                       
      381 +  final String currencyCode;                                  
      382 +  final FinancialAmountDirection direction;                   
      383 +                                                              
      384 +  /// Null for the step being viewed; otherwise the half to op
          +en.                                                           
      385 +  final String? operationId;                                  
      386 +                                                              
      387 +  @override                                                   
      388 +  Widget build(BuildContext context) {                        
      389 +    final row = CurrencyAmountRow(                            
      390 +      label: title,                                           
      391 +      caption: caption,                                       
      392 +      minorUnits: minorUnits,                                 
      393 +      currencyCode: currencyCode,                             
      394 +      tone: FinancialAmountTone.muted,                        
      395 +      direction: direction,                                   
      396 +    );                                                        
      397 +    if (operationId == null) return row;                      
      398 +    return InkWell(                                           
      399 +      onTap: () => context.push('/transactions/$operationId'),
      400 +      child: row,                                             
      401 +    );                                                        
      402 +  }                                                           
      403 +}                                                             

  Ran 1 shell command (ctrl+o to expand)

⏺ Now update the detail screen test to the new provider and cover the chain:

⏺ Write(test/widget/features/transactions/transaction_detail_screen_test.dart)
  ⎿  Added 197 lines, removed 33 lines
       1  /// Transaction detail.
       2  ///
       3 -/// Two claims are under test. The amount is money, not a raw i
         -nteger — this                                                  
       4 -/// screen printed 382.50 EGP as "38250 EGP" before. And the sc
         -reen answers                                                   
       5 -/// "where is edit" out loud: the append-only explainer is perm
         -anent, the                                                     
       6 -/// reversal is offered once, and an already-reversed operation
         - says why the                                                  
       7 -/// action is gone.                                            
       3 +/// Three claims are under test. The amount is money, not a raw
         + integer — this                                                
       4 +/// screen printed 382.50 EGP as "38250 EGP" before. Accounts a
         +nd members are                                                 
       5 +/// named, not UUIDs. And the screen answers "where is edit" ou
         +t loud: the                                                    
       6 +/// double entry is shown, the append-only explainer is permane
         +nt, and a                                                      
       7 +/// reversed operation renders the lineage instead of a second 
         +reversal.                                                      
       8  library;
       9  
      10  import 'package:family_money_manager/core/database/app_database
          .dart';
     ...
      13  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
      14  import 'package:family_money_manager/core/presentation/componen
          ts/components.dart';
      15  import 'package:family_money_manager/features/ledger/domain/ope
          ration.dart';
      16 +import 'package:family_money_manager/features/transactions/doma
         +in/transaction_detail.dart';                                   
      17  import 'package:family_money_manager/features/transactions/doma
          in/transaction_summary.dart';
      18  import 'package:family_money_manager/features/transactions/pres
          entation/providers/transaction_providers.dart';
      19  import 'package:family_money_manager/features/transactions/pres
          entation/transaction_detail_screen.dart';
     ...
      24  import 'package:go_router/go_router.dart';
      25  
      26  const _operationId = 'op-1';
      27 +const _walletName = 'ةيصخش ةيدقن ةظفحم';                       
      28 +const _spenderName = 'نمحرلا دبع ءانه';                        
      29  
      27 -TransactionSummary _summary({                                  
      30 +TransactionDetail _detail({                                    
      31    bool isReversed = false,
      32    String? reversalReason,
      33    OperationType type = OperationType.expense,
      31 -}) => TransactionSummary(                                      
      32 -  operation: Operation(                                        
      33 -    id: _operationId,                                          
      34 -    householdId: 'household-v1',                               
      35 -    type: type,                                                
      36 -    effectiveDate: '2026-07-25',                               
      37 -    recordedAt: DateTime.utc(2026, 7, 25, 14, 21),             
      38 -    totalAmountMinorUnits: 38250,                              
      39 -    currencyCode: 'EGP',                                       
      40 -    createdBy: 'member-primary-v1',                            
      41 -    createdAt: '2026-07-25T14:21:00Z',                         
      42 -    updatedAt: '2026-07-25T14:21:00Z',                         
      43 -    isReversed: isReversed,                                    
      44 -    reversalReason: reversalReason,                            
      45 -    sourceAccountId: 'acc-1',                                  
      34 +  ReversalCounterpart? counterpart,                            
      35 +  List<OperationLedgerLine> ledgerLines = const [              
      36 +    OperationLedgerLine(                                       
      37 +      entryId: 'entry-debit',                                  
      38 +      direction: LedgerDirection.debit,                        
      39 +      accountId: 'acc-1',                                      
      40 +      accountName: _walletName,                                
      41 +      amountMinorUnits: 38250,                                 
      42 +      currencyCode: 'EGP',                                     
      43 +      entryType: LedgerEntryType.expenseDebit,                 
      44 +    ),                                                         
      45 +  ],                                                           
      46 +}) => TransactionDetail(                                       
      47 +  summary: TransactionSummary(                                 
      48 +    operation: Operation(                                      
      49 +      id: _operationId,                                        
      50 +      householdId: 'household-v1',                             
      51 +      type: type,                                              
      52 +      effectiveDate: '2026-07-25',                             
      53 +      recordedAt: DateTime.utc(2026, 7, 25, 14, 21),           
      54 +      totalAmountMinorUnits: 38250,                            
      55 +      currencyCode: 'EGP',                                     
      56 +      createdBy: 'member-hana',                                
      57 +      createdAt: '2026-07-25T14:21:00Z',                       
      58 +      updatedAt: '2026-07-25T14:21:00Z',                       
      59 +      isReversed: isReversed,                                  
      60 +      reversalReason: reversalReason,                          
      61 +      sourceAccountId: 'acc-1',                                
      62 +    ),                                                         
      63 +    categoryCode: 'groceries',                                 
      64 +    spenderMemberId: 'member-hana',                            
      65 +    isRecurring: false,                                        
      66    ),
      47 -  categoryCode: 'groceries',                                   
      48 -  isRecurring: false,                                          
      67 +  ledgerLines: ledgerLines,                                    
      68 +  sourceAccountName: _walletName,                              
      69 +  spenderName: _spenderName,                                   
      70 +  createdByName: _spenderName,                                 
      71 +  counterpart: counterpart,                                    
      72  );
      73  
      51 -Widget _buildApp(TransactionSummary summary) {                 
      74 +Widget _buildApp(TransactionDetail detail) {                   
      75    final router = GoRouter(
      76      initialLocation: '/transactions/$_operationId',
      77      routes: [
     ...
      103          ref.onDispose(db.close);
      104          return db;
      105        }),
       83 -      transactionDetailProvider.overrideWith((ref, _) async =>
          - summary),                                                    
      106 +      transactionDetailWithLedgerProvider.overrideWith((ref, _
          +) async => detail),                                           
      107      ],
      108      child: MaterialApp.router(
      109        locale: const Locale('ar'),
     ...
      138    testWidgets('the amount goes through the money component, no
           t raw units', (
      139      tester,
      140    ) async {
      118 -    await tester.pumpWidget(_buildApp(_summary()));           
      141 +    await tester.pumpWidget(_buildApp(_detail()));            
      142      await tester.pump();
      143  
      144      final amount = tester.widget<FinancialAmountText>(
      122 -      find.byType(FinancialAmountText),                       
      145 +      find.byType(FinancialAmountText).first,                 
      146      );
      147      expect(amount.minorUnits, 38250);
      148      expect(amount.currencyCode, 'EGP');
     ...
      151      expect(find.text('38250 EGP'), findsNothing);
      152    });
      153  
      154 +  testWidgets('the double entry is shown, named and labelled b
          +y side', (                                                    
      155 +    tester,                                                   
      156 +  ) async {                                                   
      157 +    await tester.pumpWidget(                                  
      158 +      _buildApp(                                              
      159 +        _detail(                                              
      160 +          ledgerLines: const [                                
      161 +            OperationLedgerLine(                              
      162 +              entryId: 'entry-debit',                         
      163 +              direction: LedgerDirection.debit,               
      164 +              accountId: 'cat-groceries',                     
      165 +              accountName: 'ةلاقب',                           
      166 +              amountMinorUnits: 38250,                        
      167 +              currencyCode: 'EGP',                            
      168 +              entryType: LedgerEntryType.expenseDebit,        
      169 +            ),                                                
      170 +            OperationLedgerLine(                              
      171 +              entryId: 'entry-credit',                        
      172 +              direction: LedgerDirection.credit,              
      173 +              accountId: 'acc-1',                             
      174 +              accountName: _walletName,                       
      175 +              amountMinorUnits: 38250,                        
      176 +              currencyCode: 'EGP',                            
      177 +              entryType: LedgerEntryType.expenseCredit,       
      178 +            ),                                                
      179 +          ],                                                  
      180 +        ),                                                    
      181 +      ),                                                      
      182 +    );                                                        
      183 +    await tester.pump();                                      
      184 +                                                              
      185 +    final l10n = _l10n(tester);                               
      186 +    expect(find.text(l10n.detailLedgerEntriesTitle), findsOneW
          +idget);                                                       
      187 +    expect(find.text(l10n.reviewDebitLabel('ةلاقب')), findsOne
          +Widget);                                                      
      188 +    expect(find.text(l10n.reviewCreditLabel(_walletName)), fin
          +dsOneWidget);                                                 
      189 +  });                                                         
      190 +                                                              
      191 +  testWidgets('accounts and members are named, never UUIDs', (
          +tester) async {                                               
      192 +    await tester.pumpWidget(_buildApp(_detail()));            
      193 +    await tester.pump();                                      
      194 +                                                              
      195 +    expect(find.text(_walletName), findsWidgets);             
      196 +    expect(find.text(_spenderName), findsOneWidget);          
      197 +    expect(find.text('acc-1'), findsNothing);                 
      198 +    expect(find.text('member-hana'), findsNothing);           
      199 +  });                                                         
      200 +                                                              
      201    testWidgets('the append-only explainer is always present', (
           tester) async {
      132 -    await tester.pumpWidget(_buildApp(_summary()));           
      202 +    await tester.pumpWidget(_buildApp(_detail()));            
      203      await tester.pump();
      204  
      205      final l10n = _l10n(tester);
     ...
      208    });
      209  
      210    testWidgets('the reversal action opens the reversal route', 
           (tester) async {
      141 -    await tester.pumpWidget(_buildApp(_summary()));           
      211 +    await tester.pumpWidget(_buildApp(_detail()));            
      212      await tester.pump();
      213  
      214      final l10n = _l10n(tester);
     ...
      219    });
      220  
      221    testWidgets(
      152 -    'a reversed operation is struck through, banners why, and 
          -offers no '                                                   
      222 +    'a reversed original is struck through, keeps its entries,
          + and offers no '                                              
      223      'second reversal',
      224      (tester) async {
      155 -      await tester.pumpWidget(_buildApp(_summary(isReversed: t
          -rue)));                                                       
      225 +      await tester.pumpWidget(                                
      226 +        _buildApp(                                            
      227 +          _detail(                                            
      228 +            isReversed: true,                                 
      229 +            counterpart: const ReversalCounterpart(           
      230 +              operationId: 'op-rev',                          
      231 +              effectiveDate: '2026-07-25',                    
      232 +              totalAmountMinorUnits: 38250,                   
      233 +              currencyCode: 'EGP',                            
      234 +              isReversingEntry: true,                         
      235 +              reason: 'نيترم تلخدأُ',                         
      236 +              authorName: 'دمحأ',                             
      237 +            ),                                                
      238 +          ),                                                  
      239 +        ),                                                    
      240 +      );                                                      
      241        await tester.pump();
      242  
      243        final l10n = _l10n(tester);
      244        final amount = tester.widget<FinancialAmountText>(
      160 -        find.byType(FinancialAmountText),                     
      245 +        find.byType(FinancialAmountText).first,               
      246        );
      247        expect(amount.isStruckThrough, isTrue);
      248        expect(amount.tone, FinancialAmountTone.muted);
      249  
      250        expect(find.text(l10n.detailAlreadyReversedNoAction), fi
           ndsOneWidget);
      251        expect(find.text(l10n.detailAddReversalAction), findsNot
           hing);
      252 +      // The entries are still there — they were answered, not
          + erased.                                                      
      253 +      expect(find.text(l10n.detailLedgerEntriesOriginalTitle),
          + findsOneWidget);                                             
      254        expect(find.text(l10n.detailEntriesStillInLedgerNote), f
           indsOneWidget);
      255      },
      256    );
      257  
      258 +  testWidgets(                                                
      259 +    'the lineage is numbered, marks where you are, and states 
          +the net as zero',                                             
      260 +    (tester) async {                                          
      261 +      await tester.pumpWidget(                                
      262 +        _buildApp(                                            
      263 +          _detail(                                            
      264 +            isReversed: true,                                 
      265 +            counterpart: const ReversalCounterpart(           
      266 +              operationId: 'op-rev',                          
      267 +              effectiveDate: '2026-07-26',                    
      268 +              totalAmountMinorUnits: 38250,                   
      269 +              currencyCode: 'EGP',                            
      270 +              isReversingEntry: true,                         
      271 +              reason: 'نيترم تلخدأُ',                         
      272 +              authorName: 'دمحأ',                             
      273 +            ),                                                
      274 +          ),                                                  
      275 +        ),                                                    
      276 +      );                                                      
      277 +      await tester.pump();                                    
      278 +                                                              
      279 +      final l10n = _l10n(tester);                             
      280 +      expect(find.text(l10n.detailChainTitle), findsOneWidget)
          +;                                                             
      281 +      expect(                                                 
      282 +        find.text(l10n.detailChainStepOriginal('1', '2026-07-2
          +5')),                                                         
      283 +        findsOneWidget,                                       
      284 +      );                                                      
      285 +      expect(                                                 
      286 +        find.text(l10n.detailChainStepReversal('2', '2026-07-2
          +6')),                                                         
      287 +        findsOneWidget,                                       
      288 +      );                                                      
      289 +      expect(find.text(l10n.detailChainYouAreHere), findsOneWi
          +dget);                                                        
      290 +      // The reason and its author ride on the reversing step 
          +itself.                                                       
      291 +      expect(                                                 
      292 +        find.text(l10n.detailChainReasonBy('حأ' ,'نيترم تلخدأُ
          +                                                        ,))'دم
      293 +        findsOneWidget,                                       
      294 +      );                                                      
      295 +                                                              
      296 +      final netRow = tester.widget<CurrencyAmountRow>(        
      297 +        find.ancestor(                                        
      298 +          of: find.text(l10n.reversalNetEffectOn(_walletName))
          +,                                                             
      299 +          matching: find.byType(CurrencyAmountRow),           
      300 +        ),                                                    
      301 +      );                                                      
      302 +      expect(netRow.minorUnits, 0);                           
      303 +    },                                                        
      304 +  );                                                          
      305 +                                                              
      306 +  testWidgets('the other half of the pair is reachable from th
          +e chain', (                                                   
      307 +    tester,                                                   
      308 +  ) async {                                                   
      309 +    await tester.pumpWidget(                                  
      310 +      _buildApp(                                              
      311 +        _detail(                                              
      312 +          isReversed: true,                                   
      313 +          counterpart: const ReversalCounterpart(             
      314 +            operationId: 'op-rev',                            
      315 +            effectiveDate: '2026-07-26',                      
      316 +            totalAmountMinorUnits: 38250,                     
      317 +            currencyCode: 'EGP',                              
      318 +            isReversingEntry: true,                           
      319 +            reason: 'نيترم تلخدأُ',                           
      320 +            authorName: 'دمحأ',                               
      321 +          ),                                                  
      322 +        ),                                                    
      323 +      ),                                                      
      324 +    );                                                        
      325 +    await tester.pump();                                      
      326 +                                                              
      327 +    final l10n = _l10n(tester);                               
      328 +    await tester.tap(find.text(l10n.detailChainStepReversal('2
          +', '2026-07-26')));                                           
      329 +    await tester.pumpAndSettle();                             
      330 +                                                              
      331 +    // A second detail screen is now on top, opened on the oth
          +er half.                                                      
      332 +    expect(find.byType(TransactionDetailScreen), findsNWidgets
          +(2));                                                         
      333 +  });                                                         
      334 +                                                              
      335    testWidgets('a recorded reversal reason is shown verbatim', 
           (tester) async {
      336      await tester.pumpWidget(
      337        _buildApp(
      174 -        _summary(                                             
      338 +        _detail(                                              
      339            type: OperationType.reversal,
      340            reversalReason: 'أطخلاب نيترم تلخدأُ',
      341          ),

  Ran 4 shell commands (ctrl+o to expand)
  ⎿  Found 6 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Update(test/widget/features/transactions/transaction_detail_screen_test.dart)
  ⎿  Added 15 lines, removed 2 lines
      332      );
      333      await tester.pumpAndSettle();
      334  
      335 -    // A second detail screen is now on top, opened on the oth
          -er half.                                                      
      336 -    expect(find.byType(TransactionDetailScreen), findsNWidgets
          -(2));                                                         
      335 +    // A second detail screen is now on top, opened on the oth
          +er half. The                                                  
      336 +    // first is still mounted underneath, which is why offstag
          +e is included.                                                
      337 +    expect(                                                   
      338 +      find.byType(TransactionDetailScreen, skipOffstage: false
          +),                                                            
      339 +      findsNWidgets(2),                                       
      340 +    );                                                        
      341 +    expect(                                                   
      342 +      tester                                                  
      343 +          .widgetList<TransactionDetailScreen>(               
      344 +            find.byType(TransactionDetailScreen, skipOffstage:
          + false),                                                      
      345 +          )                                                   
      346 +          .last                                               
      347 +          .operationId,                                       
      348 +      'op-rev',                                               
      349 +    );                                                        
      350    });
      351  
      352    testWidgets('a recorded reversal reason is shown verbatim', 
           (tester) async {
  Ran 3 shell commands (ctrl+o to expand)

⏺ +1834 −2 — still only the two pre-existing failures. Analyzer and formatter
  clean.

  Implemented (this turn)

  The detail query. New operationDetailWithLedger on TransactionQueryRepository,
  returning a TransactionDetail read model: the operation's real ledger lines
  with account names joined, source/destination/spender/beneficiary/author names
  resolved, and the other half of its reversal pair. Kept separate from
  operationDetail so list callers don't pay for three extra joins. Names resolve
  with one IN query per table, not one per id; a missing join falls back to the
  id rather than to blank, so missing data doesn't read as a rendering bug.

  The counterpart walk goes both ways: from an original, reversedBy names the
  correction directly; from a reversal, nothing points forward, so it walks
  ledger_entries.reversal_of_entry_id back to the original's operation.

  The DB test caught a real bug in my own previous turn's work — _rowToSummary
  never read reversal_reason, so every operation coming out of the transactions
  query had a null reason no matter what was stored. The widget test had passed
  because it constructs Operation directly. Fixed: the column is now in all
  three SELECT lists and the mapper.

  Detail screen rebuilt on D1/D2. The double entry rendered as debit and credit
  rows via CurrencyAmountRow — no new component, per the spec. The numbered
  lineage with "you are here", the reversing step carrying its reason and
  author, the net stated as 0.00, and the other half tappable. Accounts and
  members are named. A reversed original keeps its entries under "the original"
  heading with the note explaining they were answered, not erased.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 340 files
  - flutter test — +1834 −2 (was +1785 −8 at the start of this session)

  New this turn: 8 DB tests on the query (including household isolation and both
  directions of the pair walk), 9 widget tests on the rebuilt screen. Two ARB
  keys added for the chain steps; both locales still symmetric.

  Notes

  - Known inconsistency I left alone: drift_dashboard_query_repository also
  builds Operations and doesn't read reversal_reason. Nothing on the dashboard
  renders a reason today, and widening its recent-activity query for unused data
  would be speculative — flagging rather than fixing.
  - Still open in phase 8: the C1–C6 transaction list. That's the last piece —
  sticky date groups, the reversed pair as two adjacent rows, per-currency
  summaries, the filter sheet with its result count, and the "filtered to
  nothing" empty state. It needs the same name joins on the list query, which
  now exist as a pattern to follow.
  - Also still deferred, as before: budgets/goals/certificates detail routes are
  not yet root pushes, and your two open decisions (certificate-principal
  double classification, spouse-wallet exclusion).

✻ Crunched for 8m 33s

❯ go ahead                                                                      

  Read 1 file, ran 1 shell command (ctrl+o to expand)

⏺ Update(lib/features/transactions/domain/transaction_summary.dart)
  ⎿  Added 5 lines
      18      this.scope,
      19      required this.isRecurring,
      20      this.note,
      21 +    this.spenderName,                                          
      22 +    this.beneficiaryName,                                      
      23 +    this.sourceAccountName,                                    
      24 +    this.destinationAccountName,                               
      25 +    this.createdByName,                                        
      26    });
      27  
      28    /// The underlying financial operation (type, amount, date, a
          ccounts, etc.).

⏺ Update(lib/features/transactions/domain/transaction_summary.dart)
  ⎿  Added 19 lines
      45  
      46    /// Optional free-text note.
      47    final String? note;
      48 +                                                               
      49 +  // ── Resolved display names ────────────────────────────────
         +─────────────────                                              
      50 +  //                                                           
      51 +  // The ids above are the stable identity; these are what a pe
         +rson reads. A                                                  
      52 +  // row that says "ةيدقن ةظفحم · ءانه" is buildable, one that 
         +says                                                           
      53 +  // "member-7f3a · acc-91c2" is not — and resolving it in the 
         +query is one                                                   
      54 +  // join rather than N lookups per rendered row.              
      55 +  //                                                           
      56 +  // Null when the referenced row is missing or the query did n
         +ot ask for                                                     
      57 +  // names. Callers fall back to the id, never to blank: a blan
         +k reads as a                                                   
      58 +  // rendering bug, an id reads as missing data.               
      59 +                                                               
      60 +  final String? spenderName;                                   
      61 +  final String? beneficiaryName;                               
      62 +  final String? sourceAccountName;                             
      63 +  final String? destinationAccountName;                        
      64 +                                                               
      65 +  /// Display name of whoever recorded the operation.          
      66 +  final String? createdByName;                                 
      67  }

⏺ Now the joins in all three list/detail queries:

  Ran 1 shell command (ctrl+o to expand)

⏺ Now drop the duplicated name fields from TransactionDetail:

  Ran 4 shell commands (ctrl+o to expand)

⏺ Now the list screen itself:

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)

⏺ Write(lib/features/transactions/presentation/transaction_list_grouping.dart)
  ⎿  Wrote 129 lines to
     lib/features/transactions/presentation/transaction_list_grouping.dart
       1 /// Turning a flat list of operations into what the list screen 
       2 ///
       3 /// Kept out of the widget deliberately: grouping by date and re
       4 /// two currencies together are decisions about money, and they 
         are far easier
       6 library;
       7 
         .dart';
       9 import 'package:family_money_manager/features/transactions/domai
      10 import 'package:meta/meta.dart';
     … +138 lines (ctrl+o to expand)

⏺ Write(lib/features/transactions/presentation/transactions_screen.dart)
  ⎿  Added 257 lines, removed 51 lines
       1 +/// The transaction list.                                      
       2 +///                                                            
       3 +/// Built for hundreds of rows: fixed-geometry tiles, sticky da
         +te headers, and                                                
       4 +/// a period summary that never adds two currencies together. A
         + reversed pair                                                 
       5 +/// appears as two adjacent rows — hiding the original would ma
         +ke the ledger a                                                
       6 +/// lie, and hiding the correction would make the balance incom
         +prehensible.                                                   
       7 +library;                                                       
       8 +                                                               
       9 +import 'package:family_money_manager/app/app_theme.dart';      
      10  import 'package:family_money_manager/core/application/app_resul
          t.dart';
      11  import 'package:family_money_manager/core/financial/ledger_enum
          s.dart';
      12  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
      13  import 'package:family_money_manager/core/localization/enum_lab
          el_helpers.dart';
      14  import 'package:family_money_manager/core/presentation/componen
          ts/components.dart';
      15 +import 'package:family_money_manager/core/presentation/theme/ap
         +p_theme_extensions.dart';                                      
      16  import 'package:family_money_manager/features/transactions/doma
          in/transaction_filter.dart';
      17  import 'package:family_money_manager/features/transactions/doma
          in/transaction_summary.dart';
      18  import 'package:family_money_manager/features/transactions/pres
          entation/category_label_helper.dart';
      19  import 'package:family_money_manager/features/transactions/pres
          entation/providers/transaction_providers.dart';
      20 +import 'package:family_money_manager/features/transactions/pres
         +entation/transaction_list_grouping.dart';                      
      21  import 'package:flutter/material.dart';
      22  import 'package:flutter_riverpod/flutter_riverpod.dart';
      23  import 'package:go_router/go_router.dart';
     ...
       36        transactionListProvider((_householdId, filter)),
       37      );
       38  
       28 -    return Scaffold(                                          
       29 -      appBar: AppBar(title: Text(l10n.transactionsTitle)),    
       39 +    return AppScreenScaffold(                                 
       40 +      title: Text(l10n.transactionsTitle),                    
       41        floatingActionButton: FloatingActionButton(
       42          heroTag: 'fab_transactions',
       43          onPressed: () => context.push('/transactions/new'),
       44          child: const Icon(Icons.add),
       45        ),
       46        body: transactionsAsync.when(
       36 -        loading: () => AppLoadingState(message: l10n.loadingLa
          -bel),                                                         
       37 -        error: (_, _) => AppErrorState(message: l10n.errorGene
          -ric),                                                         
       38 -        data: (result) {                                      
       39 -          return switch (result) {                            
       40 -            AppOk(:final value) =>                            
       41 -              value.isEmpty                                   
       42 -                  ? AppEmptyState(                            
       43 -                      title: l10n.transactionsEmpty,          
       44 -                      actionLabel: l10n.actionRecordExpense,  
       45 -                      onAction: () => context.push('/transacti
          -ons/new'),                                                    
       46 -                    )                                         
       47 -                  : RefreshIndicator(                         
       48 -                      onRefresh: () async {                   
       49 -                        ref.invalidate(                       
       50 -                          transactionListProvider((_householdI
          -d, filter)),                                                  
       51 -                        );                                    
       52 -                      },                                      
       53 -                      child: ListView.separated(              
       54 -                        itemCount: value.length,              
       55 -                        separatorBuilder: (_, _) => const Divi
          -der(height: 1),                                               
       56 -                        itemBuilder: (context, i) =>          
       57 -                            _TransactionTile(summary: value[i]
          -),                                                            
       58 -                      ),                                      
       59 -                    ),                                        
       60 -            _ => AppErrorState(message: l10n.errorGeneric),   
       61 -          };                                                  
       47 +        // A skeleton at the real row pitch, not a spinner: th
          +e list's geometry                                             
       48 +        // is already known, so nothing moves when the data la
          +nds.                                                          
       49 +        loading: () => const AppSkeletonList(),               
       50 +        error: (_, _) => AppErrorState(message: l10n.transacti
          +onsErrorTitle),                                               
       51 +        data: (result) => switch (result) {                   
       52 +          AppOk(:final value) when value.isEmpty => AppEmptySt
          +ate(                                                          
       53 +            title: l10n.transactionsEmpty,                    
       54 +            actionLabel: l10n.actionRecordExpense,            
       55 +            onAction: () => context.push('/transactions/new'),
       56 +          ),                                                  
       57 +          AppOk(:final value) => RefreshIndicator(            
       58 +            onRefresh: () async {                             
       59 +              ref.invalidate(transactionListProvider((_househo
          +ldId, filter)));                                              
       60 +            },                                                
       61 +            child: _GroupedList(transactions: value),         
       62 +          ),                                                  
       63 +          _ => AppErrorState(message: l10n.transactionsErrorTi
          +tle),                                                         
       64          },
       65        ),
       66      );
       67    }
       68  }
       69  
       70 +class _GroupedList extends StatelessWidget {                  
       71 +  const _GroupedList({required this.transactions});           
       72 +                                                              
       73 +  final List<TransactionSummary> transactions;                
       74 +                                                              
       75 +  @override                                                   
       76 +  Widget build(BuildContext context) {                        
       77 +    final groups = groupByEffectiveDate(transactions);        
       78 +    final totals = totalsByCurrency(transactions);            
       79 +                                                              
       80 +    return ResponsiveContentContainer(                        
       81 +      child: CustomScrollView(                                
       82 +        slivers: [                                            
       83 +          if (totals.isNotEmpty)                              
       84 +            SliverToBoxAdapter(child: _PeriodSummary(totals: t
          +otals)),                                                      
       85 +          for (final group in groups) ...[                    
       86 +            // Sticky, so the day a row belongs to is never of
          +f-screen while                                                
       87 +            // its rows are.                                  
       88 +            SliverPersistentHeader(                           
       89 +              pinned: true,                                   
       90 +              delegate: _DateHeaderDelegate(                  
       91 +                date: group.effectiveDate,                    
       92 +                count: group.transactions.length,             
       93 +              ),                                              
       94 +            ),                                                
       95 +            SliverList.builder(                               
       96 +              itemCount: group.transactions.length,           
       97 +              itemBuilder: (context, index) =>                
       98 +                  _TransactionTile(summary: group.transactions
          +[index]),                                                     
       99 +            ),                                                
      100 +          ],                                                  
      101 +          const SliverToBoxAdapter(child: SizedBox(height: App
          +Theme.space32)),                                              
      102 +        ],                                                    
      103 +      ),                                                      
      104 +    );                                                        
      105 +  }                                                           
      106 +}                                                             
      107 +                                                              
      108 +/// Period figures, one block per currency.                   
      109 +class _PeriodSummary extends StatelessWidget {                
      110 +  const _PeriodSummary({required this.totals});               
      111 +                                                              
      112 +  final List<TransactionPeriodTotals> totals;                 
      113 +                                                              
      114 +  @override                                                   
      115 +  Widget build(BuildContext context) {                        
      116 +    final l10n = AppLocalizations.of(context);                
      117 +    final colors = context.financialColors;                   
      118 +                                                              
      119 +    return Column(                                            
      120 +      crossAxisAlignment: CrossAxisAlignment.stretch,         
      121 +      children: [                                             
      122 +        for (final total in totals)                           
      123 +          Padding(                                            
      124 +            padding: const EdgeInsets.fromLTRB(               
      125 +              AppTheme.space16,                               
      126 +              AppTheme.space16,                               
      127 +              AppTheme.space16,                               
      128 +              AppTheme.space8,                                
      129 +            ),                                                
      130 +            child: Column(                                    
      131 +              crossAxisAlignment: CrossAxisAlignment.start,   
      132 +              children: [                                     
      133 +                FinancialSummary(                             
      134 +                  metrics: [                                  
      135 +                    FinancialMetricData(                      
      136 +                      label: l10n.transactionsSummaryIncome,  
      137 +                      minorUnits: total.incomeMinorUnits,     
      138 +                      currencyCode: total.currencyCode,       
      139 +                      tone: FinancialAmountTone.income,       
      140 +                      direction: FinancialAmountDirection.infl
          +ow,                                                           
      141 +                    ),                                        
      142 +                    FinancialMetricData(                      
      143 +                      label: l10n.transactionsSummaryExpense, 
      144 +                      minorUnits: total.expenseMinorUnits,    
      145 +                      currencyCode: total.currencyCode,       
      146 +                      tone: FinancialAmountTone.expense,      
      147 +                      direction: FinancialAmountDirection.outf
          +low,                                                          
      148 +                    ),                                        
      149 +                    // Third and labelled, never folded into t
          +he first two.                                                 
      150 +                    FinancialMetricData(                      
      151 +                      label: l10n.transactionsSummaryTransfer,
      152 +                      minorUnits: total.transferMinorUnits,   
      153 +                      currencyCode: total.currencyCode,       
      154 +                      tone: FinancialAmountTone.transfer,     
      155 +                      direction: FinancialAmountDirection.inte
          +rnal,                                                         
      156 +                    ),                                        
      157 +                  ],                                          
      158 +                ),                                            
      159 +                const SizedBox(height: AppTheme.space8),      
      160 +                // The summary states its own scope. Only one 
          +currency is                                                   
      161 +                // being totalled, and rows in others are stil
          +l in the list                                                 
      162 +                // below carrying their own code.             
      163 +                Text(                                         
      164 +                  totals.length > 1                           
      165 +                      ? l10n.transactionsSummaryCurrencyOnly(t
          +otal.currencyCode)                                            
      166 +                      : l10n.transactionsTransferNotCounted,  
      167 +                  style: context.textRoles.supportingMeta.copy
          +With(                                                         
      168 +                    color: colors.secondaryText,              
      169 +                  ),                                          
      170 +                ),                                            
      171 +              ],                                              
      172 +            ),                                                
      173 +          ),                                                  
      174 +      ],                                                      
      175 +    );                                                        
      176 +  }                                                           
      177 +}                                                             
      178 +                                                              
      179 +/// A pinned day header carrying that day's row count.        
      180 +class _DateHeaderDelegate extends SliverPersistentHeaderDelega
          +te {                                                          
      181 +  const _DateHeaderDelegate({required this.date, required this
          +.count});                                                     
      182 +                                                              
      183 +  final String date;                                          
      184 +  final int count;                                            
      185 +                                                              
      186 +  static const double _height = 40;                           
      187 +                                                              
      188 +  @override                                                   
      189 +  double get minExtent => _height;                            
      190 +                                                              
      191 +  @override                                                   
      192 +  double get maxExtent => _height;                            
      193 +                                                              
      194 +  @override                                                   
      195 +  Widget build(                                               
      196 +    BuildContext context,                                     
      197 +    double shrinkOffset,                                      
      198 +    bool overlapsContent,                                     
      199 +  ) {                                                         
      200 +    final l10n = AppLocalizations.of(context);                
      201 +    final colors = context.financialColors;                   
      202 +    return Container(                                         
      203 +      height: _height,                                        
      204 +      // Opaque: a pinned header that rows scroll through has 
          +to hide them.                                                 
      205 +      color: colors.mainSurface,                              
      206 +      padding: const EdgeInsets.symmetric(horizontal: AppTheme
          +.space16),                                                    
      207 +      alignment: AlignmentDirectional.centerStart,            
      208 +      child: Row(                                             
      209 +        children: [                                           
      210 +          Expanded(                                           
      211 +            child: Text(                                      
      212 +              _label(l10n),                                   
      213 +              style: context.textRoles.sectionTitle,          
      214 +            ),                                                
      215 +          ),                                                  
      216 +          Text(                                               
      217 +            l10n.transactionsGroupCount('$count'),            
      218 +            style: context.textRoles.supportingMeta.copyWith( 
      219 +              color: colors.secondaryText,                    
      220 +            ),                                                
      221 +          ),                                                  
      222 +        ],                                                    
      223 +      ),                                                      
      224 +    );                                                        
      225 +  }                                                           
      226 +                                                              
      227 +  /// "Today" and "Yesterday" carry more than a date does; any
          +thing older is                                                
      228 +  /// better served by the date itself.                       
      229 +  String _label(AppLocalizations l10n) {                      
      230 +    final now = DateTime.now();                               
      231 +    final today = _iso(now);                                  
      232 +    final yesterday = _iso(now.subtract(const Duration(days: 1
          +)));                                                          
      233 +    if (date == today) return '${l10n.transactionsGroupToday} 
          +· $date';                                                     
      234 +    if (date == yesterday) return '${l10n.transactionsGroupYes
          +terday} · $date';                                             
      235 +    return date;                                              
      236 +  }                                                           
      237 +                                                              
      238 +  String _iso(DateTime value) =>                              
      239 +      '${value.year}-${value.month.toString().padLeft(2, '0')}
          +-'                                                            
      240 +      '${value.day.toString().padLeft(2, '0')}';              
      241 +                                                              
      242 +  @override                                                   
      243 +  bool shouldRebuild(_DateHeaderDelegate oldDelegate) =>      
      244 +      oldDelegate.date != date || oldDelegate.count != count; 
      245 +}                                                             
      246 +                                                              
      247  class _TransactionTile extends StatelessWidget {
      248    const _TransactionTile({required this.summary});
      249  
     ...
      253    Widget build(BuildContext context) {
      254      final l10n = AppLocalizations.of(context);
      255      final op = summary.operation;
       77 -    final kind = _typeKind(op.type);                          
      256 +                                                              
      257 +    // Names, not ids. The id stays as the fallback so a missi
          +ng join reads as                                              
      258 +    // missing data rather than as a blank row.               
      259 +    final source = summary.sourceAccountName ?? op.sourceAccou
          +ntId;                                                         
      260 +    final destination =                                       
      261 +        summary.destinationAccountName ?? op.destinationAccoun
          +tId;                                                          
      262      final accountOrDirection = switch (op.type) {
       79 -      OperationType.transfer =>                               
       80 -        '${op.sourceAccountId ?? '—'} → ${op.destinationAccoun
          -tId ?? '—'}',                                                 
      263 +      OperationType.transfer => '${source ?? '—'} → ${destinat
          +ion ?? '—'}',                                                 
      264        OperationType.income || OperationType.openingBalance =>
       82 -        op.destinationAccountId ?? op.currencyCode,           
       83 -      _ => op.sourceAccountId ?? op.currencyCode,             
      265 +        destination ?? op.currencyCode,                       
      266 +      _ => source ?? op.currencyCode,                         
      267      };
      268  
      269      return TransactionListTile(
      270        typeLabel: operationTypeLabel(l10n, op.type),
       88 -      typeKind: kind,                                         
       89 -      primaryDescription: op.description?.trim().isNotEmpty ==
          - true                                                         
       90 -          ? op.description!                                   
       91 -          : (summary.note?.trim().isNotEmpty == true          
       92 -                ? summary.note!                               
       93 -                : operationTypeLabel(l10n, op.type)),         
      271 +      typeKind: _typeKind(op.type),                           
      272 +      primaryDescription: _description(l10n),                 
      273        accountOrDirection: accountOrDirection,
      274        effectiveDate: op.effectiveDate,
      275        minorUnits: op.totalAmountMinorUnits,
      276        currencyCode: op.currencyCode,
       98 -      memberOrCategory: summary.categoryCode != null          
       99 -          ? categoryLabelFromCode(l10n, summary.categoryCode!)
      100 -          : null,                                             
      277 +      // The spender is who the row is about; the category is 
          +what it was for.                                              
      278 +      // Prefer the person, because "who spent this" is the qu
          +estion a                                                      
      279 +      // household asks of its own ledger first.              
      280 +      memberOrCategory: summary.spenderName ?? _categoryLabel(
          +l10n),                                                        
      281 +      associationLabel: _reversalMeta(l10n),                  
      282        isReversed: op.isReversed,
      283        reversedLabel: op.isReversed ? l10n.transactionReversed 
           : null,
      284        onTap: () => context.push('/transactions/${op.id}'),
      285      );
      286    }
      287  
      107 -  FinancialTypeKind _typeKind(OperationType type) {           
      108 -    return switch (type) {                                    
      109 -      OperationType.income => FinancialTypeKind.income,       
      110 -      OperationType.expense => FinancialTypeKind.expense,     
      111 -      OperationType.transfer => FinancialTypeKind.transfer,   
      112 -      OperationType.reversal => FinancialTypeKind.reversal,   
      113 -      OperationType.adjustment => FinancialTypeKind.adjustment
          -,                                                             
      114 -      _ => FinancialTypeKind.other,                           
      115 -    };                                                        
      288 +  String _description(AppLocalizations l10n) {                
      289 +    final op = summary.operation;                             
      290 +    if (op.description?.trim().isNotEmpty ?? false) return op.
          +description!;                                                 
      291 +    if (summary.note?.trim().isNotEmpty ?? false) return summa
          +ry.note!;                                                     
      292 +    return _categoryLabel(l10n) ?? operationTypeLabel(l10n, op
          +.type);                                                       
      293    }
      294 +                                                              
      295 +  String? _categoryLabel(AppLocalizations l10n) =>            
      296 +      summary.categoryCode == null                            
      297 +      ? null                                                  
      298 +      : categoryLabelFromCode(l10n, summary.categoryCode!);   
      299 +                                                              
      300 +  /// What makes the reversed pair legible in the list itself.
      301 +  ///                                                         
      302 +  /// The original says its counter-entry exists; the reversin
          +g entry says what                                             
      303 +  /// it answers and why. Read together, the two adjacent rows
          + explain a                                                    
      304 +  /// balance that would otherwise look like a duplicate.     
      305 +  String? _reversalMeta(AppLocalizations l10n) {              
      306 +    final op = summary.operation;                             
      307 +    if (op.isReversed) return l10n.transactionsReversedOrigina
          +lMeta;                                                        
      308 +    if (op.type != OperationType.reversal) return null;       
      309 +    if (op.reversalReason case final String reason) {         
      310 +      return l10n.transactionsReversalRefersTo(op.effectiveDat
          +e, reason);                                                   
      311 +    }                                                         
      312 +    return null;                                              
      313 +  }                                                           
      314 +                                                              
      315 +  FinancialTypeKind _typeKind(OperationType type) => switch (t
          +ype) {                                                        
      316 +    OperationType.income => FinancialTypeKind.income,         
      317 +    OperationType.expense => FinancialTypeKind.expense,       
      318 +    OperationType.transfer => FinancialTypeKind.transfer,     
      319 +    OperationType.reversal => FinancialTypeKind.reversal,     
      320 +    OperationType.adjustment => FinancialTypeKind.adjustment, 
      321 +    _ => FinancialTypeKind.other,                             
      322 +  };                                                          
      323  }

  Ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 3 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now tests — the grouping logic as pure functions, and the list screen:

⏺ Write(test/unit/features/transactions/transaction_list_grouping_test.dart)
  ⎿  Wrote 167 lines to
     test/unit/features/transactions/transaction_list_grouping_test.dart
       1 /// Grouping and totalling the transaction list.
       3 /// The rule these exist to protect: a total never crosses a cur
         rency, and a
         ak by adding a
         enshot.
       6 library;
       8 import 'package:family_money_manager/core/financial/ledger_enums
         .dart';
         ation.dart';
         n/transaction_summary.dart';
     … +182 lines (ctrl+o to expand)

  Ran 1 shell command (ctrl+o to expand)

⏺ Now the list screen widget test:

⏺ Write(test/widget/features/transactions/transactions_screen_test.dart)
  ⎿  Wrote 335 lines to
     test/widget/features/transactions/transactions_screen_test.dart
       1 /// The transaction list.
       3 /// The claims under test are the ones the design insists on: ro
         ws name people
          the transfer
         reversed pair
       6 /// appears as two adjacent rows that between them explain the b
       7 library;
       8 
         .dart';
         dart';
     … +369 lines (ctrl+o to expand)

  Ran 5 shell commands (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Implemented

  Names on the list query. Five LEFT JOINs on the three summary queries resolve
  spender, beneficiary, source/destination account, and author names — every
  join keyed on a primary key and scoped to the same household, so a row can
  never pick up a name from another family's data. TransactionSummary now
  carries the resolved names alongside the ids, with the id as the fallback so a
  missing join reads as missing data rather than a blank row.

  This also let me collapse the duplication I introduced last turn:
  TransactionDetail had its own copy of those five name fields plus a
  hand-rolled _namesById helper. Both are gone — the detail read model is now
  just summary + ledgerLines + counterpart, and names come from one place.

  Grouping and totalling extracted as pure functions
  (transaction_list_grouping.dart). Two rules live there because they're rules
  about money, not about pixels: totals are computed per currency with no
  combined figure and no default currency; and a reversed original and its
  reversing entry are both excluded — their net is zero by construction, and
  counting both would double the error.

  The list screen rebuilt. Sticky per-day headers with row counts,
  Today/Yesterday labels, AppSkeletonList at the real row pitch instead of a
  spinner, and a period summary where the transfer figure sits third, labelled,
  and explicitly outside income and expense. Reversed pairs render as two
  adjacent rows: the original says its counter-entry exists, the reversing entry
  says what it answers and why. Rows now show ةيصخش ةيدقن ةظفحم · ءانه where
  they showed UUIDs.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 343 files
  - flutter test — +1852 −2 (started this session at +1785 −8)

  18 new tests: 9 unit on the grouping/totalling rules, 9 widget on the list. 13
  ARB keys added; both locales symmetric at 592.

  Notes

  - Not done from doc 04: C2 the filter sheet (with its
  result-count-on-the-button), C3 search, and the C5 "filtered to nothing" empty
  state — that state needs the filter to exist first, so the empty state
  currently only handles a genuinely empty ledger. Also deferred: the
  pagination-failure banner that vouches for already-loaded rows, and the 200 ms
  insert animation on a new counter-entry. These are a coherent next chunk and
  all sit on top of TransactionFilter, which is still only ever constructed as
  const TransactionFilter().
  - Same two carried-over items as before: budgets/goals/certificates detail
  routes aren't root pushes yet, and the dashboard query still doesn't read
  reversal_reason (nothing there renders it).
  - Your two open decisions are unchanged — certificate-principal double
  classification, and spouse-wallet exclusion from the headline balance.

✻ Worked for 8m 30s

❯ go ahead                                                                      

  Searched for 1 pattern, read 1 file, ran 1 shell command (ctrl+o to expand)
⏺ Write(lib/features/transactions/domain/transaction_filter.dart)
  ⎿  Added 161 lines
       2  import 'package:family_money_manager/core/financial/ledger_enum
          s.dart';
       3  import 'package:meta/meta.dart';
       4  
       5 +/// An amount band, in one currency.                           
       6 +///                                                            
       7 +/// The currency is required rather than optional because a ran
         +ge without one                                                 
       8 +/// is a mixed-currency comparison: "over 5,000" would silently
         + match a USD                                                   
       9 +/// transaction against an EGP threshold. That is the same erro
         +r as a mixed                                                   
      10 +/// total, and it is prevented here by making the invalid state
      11 +/// unrepresentable rather than by checking for it later.      
      12 +@immutable                                                     
      13 +final class TransactionAmountRange {                           
      14 +  const TransactionAmountRange({                               
      15 +    required this.currencyCode,                                
      16 +    this.minMinorUnits,                                        
      17 +    this.maxMinorUnits,                                        
      18 +  });                                                          
      19 +                                                               
      20 +  final String currencyCode;                                   
      21 +                                                               
      22 +  /// Inclusive lower bound. Null means no lower bound.        
      23 +  final int? minMinorUnits;                                    
      24 +                                                               
      25 +  /// Inclusive upper bound. Null means no upper bound.        
      26 +  final int? maxMinorUnits;                                    
      27 +                                                               
      28 +  /// True when neither bound is set, in which case the range r
         +estricts                                                       
      29 +  /// nothing and only the currency would apply.               
      30 +  bool get isUnbounded => minMinorUnits == null && maxMinorUnit
         +s == null;                                                     
      31 +                                                               
      32 +  @override                                                    
      33 +  bool operator ==(Object other) =>                            
      34 +      identical(this, other) ||                                
      35 +      other is TransactionAmountRange &&                       
      36 +          other.currencyCode == currencyCode &&                
      37 +          other.minMinorUnits == minMinorUnits &&              
      38 +          other.maxMinorUnits == maxMinorUnits;                
      39 +                                                               
      40 +  @override                                                    
      41 +  int get hashCode => Object.hash(currencyCode, minMinorUnits, 
         +maxMinorUnits);                                                
      42 +}                                                              
      43 +                                                               
      44  /// Filter parameters for transaction history queries.
      45  ///
      46  /// All fields are optional; omitting a field means "no restric
          tion".
     ...
      55      this.scope,
      56      this.fromDate,
      57      this.toDate,
      58 +    this.amountRange,                                          
      59 +    this.searchQuery,                                          
      60 +    this.includeReversed = true,                               
      61      this.pageSize = 50,
      62      this.offsetId,
      63    });
     ...
       86    /// Inclusive end date "YYYY-MM-DD". Null means no upper bou
           nd.
       87    final String? toDate;
       88  
       89 +  /// Restrict to an amount band in one currency.             
       90 +  final TransactionAmountRange? amountRange;                  
       91 +                                                              
       92 +  /// Free text matched against description, note and account 
          +names.                                                        
       93 +  ///                                                         
       94 +  /// Deliberately does *not* imply a date restriction: someon
          +e searching for                                               
       95 +  /// an amount is looking for one specific transaction, not b
          +rowsing a month.                                              
       96 +  /// Callers that want the active period respected pass it in
          + the date                                                     
       97 +  /// fields as usual.                                        
       98 +  final String? searchQuery;                                  
       99 +                                                              
      100 +  /// Whether reversed originals and reversing entries are inc
          +luded.                                                        
      101 +  ///                                                         
      102 +  /// Defaults to true, and the UI defaults its toggle on: exc
          +luding them by                                                
      103 +  /// default would quietly hide history, which is the one thi
          +ng an                                                         
      104 +  /// append-only ledger exists to prevent.                   
      105 +  final bool includeReversed;                                 
      106 +                                                              
      107    /// Maximum number of results to return. Defaults to 50.
      108    final int pageSize;
      109  
     ...
      111    /// When provided, results begin after the operation with th
           is ID in the
      112    /// canonical ordering.
      113    final String? offsetId;
      114 +                                                              
      115 +  /// How many restrictions the user has applied.             
      116 +  ///                                                         
      117 +  /// Drives the "clear all (3)" affordance, so it counts what
          + a person would                                               
      118 +  /// call a filter — not [pageSize] or [offsetId], which are 
          +plumbing, and                                                 
      119 +  /// not [searchQuery], which has its own visible field.     
      120 +  int get activeCriteriaCount => [                            
      121 +    accountId != null,                                        
      122 +    operationType != null,                                    
      123 +    categoryCode != null,                                     
      124 +    spenderMemberId != null,                                  
      125 +    beneficiaryMemberId != null,                              
      126 +    scope != null,                                            
      127 +    fromDate != null || toDate != null,                       
      128 +    amountRange != null,                                      
      129 +    !includeReversed,                                         
      130 +  ].where((isActive) => isActive).length;                     
      131 +                                                              
      132 +  bool get hasActiveCriteria => activeCriteriaCount > 0;      
      133 +                                                              
      134 +  /// Copies with overrides. Pass a `clear*` flag to unset a f
          +ield, since a                                                 
      135 +  /// null argument cannot be told apart from "not supplied". 
      136 +  TransactionFilter copyWith({                                
      137 +    String? accountId,                                        
      138 +    OperationType? operationType,                             
      139 +    String? categoryCode,                                     
      140 +    String? spenderMemberId,                                  
      141 +    String? beneficiaryMemberId,                              
      142 +    ExpenseScope? scope,                                      
      143 +    String? fromDate,                                         
      144 +    String? toDate,                                           
      145 +    TransactionAmountRange? amountRange,                      
      146 +    String? searchQuery,                                      
      147 +    bool? includeReversed,                                    
      148 +    int? pageSize,                                            
      149 +    String? offsetId,                                         
      150 +    bool clearAccountId = false,                              
      151 +    bool clearOperationType = false,                          
      152 +    bool clearCategoryCode = false,                           
      153 +    bool clearSpenderMemberId = false,                        
      154 +    bool clearBeneficiaryMemberId = false,                    
      155 +    bool clearScope = false,                                  
      156 +    bool clearDates = false,                                  
      157 +    bool clearAmountRange = false,                            
      158 +    bool clearSearchQuery = false,                            
      159 +  }) => TransactionFilter(                                    
      160 +    accountId: clearAccountId ? null : accountId ?? this.accou
          +ntId,                                                         
      161 +    operationType: clearOperationType                         
      162 +        ? null                                                
      163 +        : operationType ?? this.operationType,                
      164 +    categoryCode: clearCategoryCode ? null : categoryCode ?? t
          +his.categoryCode,                                             
      165 +    spenderMemberId: clearSpenderMemberId                     
      166 +        ? null                                                
      167 +        : spenderMemberId ?? this.spenderMemberId,            
      168 +    beneficiaryMemberId: clearBeneficiaryMemberId             
      169 +        ? null                                                
      170 +        : beneficiaryMemberId ?? this.beneficiaryMemberId,    
      171 +    scope: clearScope ? null : scope ?? this.scope,           
      172 +    fromDate: clearDates ? null : fromDate ?? this.fromDate,  
      173 +    toDate: clearDates ? null : toDate ?? this.toDate,        
      174 +    amountRange: clearAmountRange ? null : amountRange ?? this
          +.amountRange,                                                 
      175 +    searchQuery: clearSearchQuery ? null : searchQuery ?? this
          +.searchQuery,                                                 
      176 +    includeReversed: includeReversed ?? this.includeReversed, 
      177 +    pageSize: pageSize ?? this.pageSize,                      
      178 +    offsetId: offsetId ?? this.offsetId,                      
      179 +  );                                                          
      180 +                                                              
      181 +  @override                                                   
      182 +  bool operator ==(Object other) =>                           
      183 +      identical(this, other) ||                               
      184 +      other is TransactionFilter &&                           
      185 +          other.accountId == accountId &&                     
      186 +          other.operationType == operationType &&             
      187 +          other.categoryCode == categoryCode &&               
      188 +          other.spenderMemberId == spenderMemberId &&         
      189 +          other.beneficiaryMemberId == beneficiaryMemberId && 
      190 +          other.scope == scope &&                             
      191 +          other.fromDate == fromDate &&                       
      192 +          other.toDate == toDate &&                           
      193 +          other.amountRange == amountRange &&                 
      194 +          other.searchQuery == searchQuery &&                 
      195 +          other.includeReversed == includeReversed &&         
      196 +          other.pageSize == pageSize &&                       
      197 +          other.offsetId == offsetId;                         
      198 +                                                              
      199 +  @override                                                   
      200 +  int get hashCode => Object.hash(                            
      201 +    accountId,                                                
      202 +    operationType,                                            
      203 +    categoryCode,                                             
      204 +    spenderMemberId,                                          
      205 +    beneficiaryMemberId,                                      
      206 +    scope,                                                    
      207 +    fromDate,                                                 
      208 +    toDate,                                                   
      209 +    amountRange,                                              
      210 +    searchQuery,                                              
      211 +    includeReversed,                                          
      212 +    pageSize,                                                 
      213 +    offsetId,                                                 
      214 +  );                                                          
      215  }

⏺ Now apply the new criteria in the query, plus a count for the sheet's button:

⏺ Update(lib/features/transactions/data/drift_transaction_query_repository.dart)
  ⎿  Added 58 lines
      465        where.write(' AND $tablePrefix.effective_date <= ?');
      466        args.add(filter.toDate);
      467      }
      468 +    if (filter.accountId case final String accountId) {       
      469 +      where.write(                                            
      470 +        ' AND ($tablePrefix.source_account_id = ?'            
      471 +        ' OR $tablePrefix.destination_account_id = ?)',       
      472 +      );                                                      
      473 +      args                                                    
      474 +        ..add(accountId)                                      
      475 +        ..add(accountId);                                     
      476 +    }                                                         
      477 +    if (filter.amountRange case final TransactionAmountRange r
          +ange) {                                                       
      478 +      // The currency is always part of the comparison, never 
          +optional: an                                                  
      479 +      // amount band that spanned currencies would match a USD
          + row against an                                               
      480 +      // EGP threshold.                                       
      481 +      where.write(' AND $tablePrefix.currency_code = ?');     
      482 +      args.add(range.currencyCode);                           
      483 +      if (range.minMinorUnits case final int min) {           
      484 +        where.write(' AND $tablePrefix.total_amount_minor_unit
          +s >= ?');                                                     
      485 +        args.add(min);                                        
      486 +      }                                                       
      487 +      if (range.maxMinorUnits case final int max) {           
      488 +        where.write(' AND $tablePrefix.total_amount_minor_unit
          +s <= ?');                                                     
      489 +        args.add(max);                                        
      490 +      }                                                       
      491 +    }                                                         
      492 +    if (!filter.includeReversed) {                            
      493 +      // Both halves go: the original whose effect was cancell
          +ed, and the                                                   
      494 +      // entry that cancelled it.                             
      495 +      where.write(                                            
      496 +        ' AND $tablePrefix.is_reversed = 0 AND $tablePrefix.ty
          +pe != ?',                                                     
      497 +      );                                                      
      498 +      args.add(OperationType.reversal.code);                  
      499 +    }                                                         
      500 +    if (filter.searchQuery?.trim() case final String query    
      501 +        when query.isNotEmpty) {                              
      502 +      // Description, note and both account names. `LIKE` is c
          +ase-insensitive                                               
      503 +      // for ASCII only in SQLite, which is why the Arabic sid
          +e matches                                                     
      504 +      // literally — correct for Arabic, where there is no cas
          +e to fold.                                                    
      505 +      where.write(                                            
      506 +        ' AND ($tablePrefix.description LIKE ?'               
      507 +        ' OR $contextPrefix.note LIKE ?'                      
      508 +        ' OR src.name LIKE ?'                                 
      509 +        ' OR dst.name LIKE ?)',                               
      510 +      );                                                      
      511 +      // Escaped so a user typing % or _ searches for those ch
          +aracters rather                                               
      512 +      // than turning their query into a wildcard.            
      513 +      final pattern = '%${_escapeLike(query)}%';              
      514 +      args                                                    
      515 +        ..add(pattern)                                        
      516 +        ..add(pattern)                                        
      517 +        ..add(pattern)                                        
      518 +        ..add(pattern);                                       
      519 +    }                                                         
      520    }
      521  
      522 +  /// Escapes SQL `LIKE` metacharacters. Paired with `ESCAPE` 
          +below.                                                        
      523 +  String _escapeLike(String value) => value                   
      524 +      .replaceAll(r'\', r'\\')                                
      525 +      .replaceAll('%', r'\%')                                 
      526 +      .replaceAll('_', r'\_');                                
      527 +                                                              
      528    List<Variable<Object>> _toVariables(List<Object?> args) {
      529      return args.map((a) {
      530        if (a is String) return Variable.withString(a);

⏺ Update(lib/features/transactions/data/drift_transaction_query_repository.dart)
  ⎿  Added 8 lines, removed 4 lines
      503        // for ASCII only in SQLite, which is why the Arabic sid
           e matches
      504        // literally — correct for Arabic, where there is no cas
           e to fold.
      505        where.write(
      506 -        ' AND ($tablePrefix.description LIKE ?'               
      507 -        ' OR $contextPrefix.note LIKE ?'                      
      508 -        ' OR src.name LIKE ?'                                 
      509 -        ' OR dst.name LIKE ?)',                               
      506 +        r" AND (" +                                           
      507 +            tablePrefix +                                     
      508 +            r".description LIKE ? ESCAPE '\'"                 
      509 +                r' OR ' +                                     
      510 +            contextPrefix +                                   
      511 +            r".note LIKE ? ESCAPE '\'"                        
      512 +                r" OR src.name LIKE ? ESCAPE '\'"             
      513 +                r" OR dst.name LIKE ? ESCAPE '\')",           
      514        );
      515        // Escaped so a user typing % or _ searches for those ch
           aracters rather
      516        // than turning their query into a wildcard.

⏺ Now the count method for the sheet's button:

⏺ Update(lib/features/transactions/data/transaction_query_repository.dart)
  ⎿  Added 11 lines
      32      required String householdId,
      33    });
      34  
      35 +  /// Counts every operation matching [filter], ignoring its pa
         +ge size.                                                       
      36 +  ///                                                          
      37 +  /// Exists so the filter sheet can put the result count on it
         +s own confirm                                                  
      38 +  /// button: knowing a filter matches 87 of 1,248 *before* com
         +mitting to it                                                  
      39 +  /// makes filtering to nothing a rare accident rather than th
         +e normal way to                                                
      40 +  /// discover the empty state.                                
      41 +  Future<int> countOperations({                                
      42 +    required String householdId,                               
      43 +    TransactionFilter filter = const TransactionFilter(),      
      44 +  });                                                          
      45 +                                                               
      46    /// Returns [operationDetail] plus its ledger lines, resolved
           names, and the
      47    /// other half of its reversal pair when it has one.
      48    ///
  ⎿  Found 2 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Update(lib/features/transactions/data/drift_transaction_query_repository.dart)
  ⎿  Added 5 lines, removed 8 lines
      502        // Description, note and both account names. `LIKE` is c
           ase-insensitive
      503        // for ASCII only in SQLite, which is why the Arabic sid
           e matches
      504        // literally — correct for Arabic, where there is no cas
           e to fold.
      505 +      const escape = r"ESCAPE '\'";                           
      506        where.write(
      506 -        r" AND (" +                                           
      507 -            tablePrefix +                                     
      508 -            r".description LIKE ? ESCAPE '\'"                 
      509 -                r' OR ' +                                     
      510 -            contextPrefix +                                   
      511 -            r".note LIKE ? ESCAPE '\'"                        
      512 -                r" OR src.name LIKE ? ESCAPE '\'"             
      513 -                r" OR dst.name LIKE ? ESCAPE '\')",           
      507 +        ' AND ($tablePrefix.description LIKE ? $escape'       
      508 +        ' OR $contextPrefix.note LIKE ? $escape'              
      509 +        ' OR src.name LIKE ? $escape'                         
      510 +        ' OR dst.name LIKE ? $escape)',                       
      511        );
      512        // Escaped so a user typing % or _ searches for those ch
           aracters rather
      513        // than turning their query into a wildcard.

⏺ Update(lib/features/transactions/data/drift_transaction_query_repository.dart)
  ⎿  Added 38 lines
      216      return rows.isEmpty ? null : _rowToSummary(rows.first);
      217    }
      218  
      219 +  // ── countOperations ──────────────────────────────────────
          +──────────────────                                            
      220 +                                                              
      221 +  @override                                                   
      222 +  Future<int> countOperations({                               
      223 +    required String householdId,                              
      224 +    TransactionFilter filter = const TransactionFilter(),     
      225 +  }) async {                                                  
      226 +    final whereClause = StringBuffer('o.household_id = ?');   
      227 +    final args = <Object?>[householdId];                      
      228 +                                                              
      229 +    _applyFilterClauses(                                      
      230 +      whereClause,                                            
      231 +      args,                                                   
      232 +      filter,                                                 
      233 +      tablePrefix: 'o',                                       
      234 +      contextPrefix: 'oc',                                    
      235 +    );                                                        
      236 +                                                              
      237 +    // The same joins as the list, because the filter can rest
          +rict on account                                               
      238 +    // names. No LIMIT: the point of this query is the total t
          +he page size                                                  
      239 +    // would otherwise hide.                                  
      240 +    final rows = await _db                                    
      241 +        .customSelect('''                                     
      242 +      SELECT COUNT(*) AS matching_count                       
      243 +      FROM operations o                                       
      244 +      LEFT JOIN operation_contexts oc ON oc.operation_id = o.i
          +d                                                             
      245 +      LEFT JOIN financial_accounts src                        
      246 +        ON src.id = o.source_account_id AND src.household_id =
          + o.household_id                                               
      247 +      LEFT JOIN financial_accounts dst                        
      248 +        ON dst.id = o.destination_account_id                  
      249 +       AND dst.household_id = o.household_id                  
      250 +      WHERE $whereClause                                      
      251 +    ''', variables: _toVariables(args))                       
      252 +        .get();                                               
      253 +                                                              
      254 +    return rows.first.read<int>('matching_count');            
      255 +  }                                                           
      256 +                                                              
      257    // ── operationDetailWithLedger ────────────────────────────
           ──────────────────
      258  
      259    @override

  Ran 1 shell command (ctrl+o to expand)

⏺ Now a DB test for the filter semantics before wiring the UI:

⏺ Write(test/database/transaction_filter_db_test.dart)
  ⎿  Wrote 331 lines to test/database/transaction_filter_db_test.dart
       1 /// Filtering and searching the transaction list.
       3 /// Three rules carry real weight here. An amount band never cro
         sses a
         rately asks
       5 /// otherwise. And the count the filter sheet promises is the co
       6 /// then shows — a button that says "87" and produces 40 is wors
         e than no
       8 library;
       9 
         dart';
     … +353 lines (ctrl+o to expand)

  Ran 1 shell command (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ 14/14. Now the filter sheet and search on the screen:

  Ran 1 shell command (ctrl+o to expand)

⏺ Write(lib/features/transactions/presentation/transaction_filter_sheet.dart)
  ⎿  Wrote 287 lines to
     lib/features/transactions/presentation/transaction_filter_sheet.dart
       1 /// The filter sheet.
       3 /// Its one structural idea: the result count rides on the confi
         rm button. You
       4 /// know a filter matches 87 of 1,248 before committing to it, w
       5 /// filtering to nothing into a rare accident rather than the no
         rmal way to
       7 library;
       8 
       9 import 'package:family_money_manager/app/app_theme.dart';
         .dart';
     … +310 lines (ctrl+o to expand)

⏺ Update(lib/features/transactions/presentation/providers/transaction_providers.
        dart)
  ⎿  Added 11 lines
       97        return useCase.execute(householdId: householdId, filter:
            filter);
       98      });
       99  
      100 +/// How many operations a filter matches, ignoring its page si
          +ze.                                                           
      101 +///                                                           
      102 +/// Watched by the filter sheet so its confirm button can carr
          +y the count.                                                  
      103 +final transactionCountProvider =                              
      104 +    FutureProvider.family<int, (String, TransactionFilter)>((r
          +ef, args) {                                                   
      105 +      final (householdId, filter) = args;                     
      106 +      return ref                                              
      107 +          .watch(transactionQueryRepositoryProvider)          
      108 +          .countOperations(householdId: householdId, filter: f
          +ilter);                                                       
      109 +    });                                                       
      110 +                                                              
      111  // ── Transaction detail provider ────────────────────────────
           ───────────────────
      112  
      113  final transactionDetailProvider =
  ⎿  Found 6 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now wire the sheet and search into the list screen:

⏺ Update(lib/features/transactions/presentation/transactions_screen.dart)
  ⎿  Added 204 lines, removed 23 lines
       25  const _householdId = 'household-v1';
       26  
       27  /// Main transactions screen showing recent operation history.
       28 -class TransactionsScreen extends ConsumerWidget {             
       28 +class TransactionsScreen extends ConsumerStatefulWidget {     
       29    const TransactionsScreen({super.key});
       30  
       31    @override
       32 -  Widget build(BuildContext context, WidgetRef ref) {         
       32 +  ConsumerState<TransactionsScreen> createState() => _Transact
          +ionsScreenState();                                            
       33 +}                                                             
       34 +                                                              
       35 +class _TransactionsScreenState extends ConsumerState<Transacti
          +onsScreen> {                                                  
       36 +  TransactionFilter _filter = const TransactionFilter();      
       37 +  final _searchController = TextEditingController();          
       38 +  bool _isSearching = false;                                  
       39 +                                                              
       40 +  @override                                                   
       41 +  void dispose() {                                            
       42 +    _searchController.dispose();                              
       43 +    super.dispose();                                          
       44 +  }                                                           
       45 +                                                              
       46 +  @override                                                   
       47 +  Widget build(BuildContext context) {                        
       48      final l10n = AppLocalizations.of(context);
       34 -    const filter = TransactionFilter();                       
       49      final transactionsAsync = ref.watch(
       36 -      transactionListProvider((_householdId, filter)),        
       50 +      transactionListProvider((_householdId, _filter)),       
       51      );
       52 +    // What the ledger holds regardless of the filter. An empt
          +y result has to                                               
       53 +    // be able to say "you have 1,248 transactions, none match
          + this".                                                       
       54 +    final unfilteredCount = ref                               
       55 +        .watch(                                               
       56 +          transactionCountProvider((_householdId, const Transa
          +ctionFilter())),                                              
       57 +        )                                                     
       58 +        .valueOrNull;                                         
       59  
       60      return AppScreenScaffold(
       40 -      title: Text(l10n.transactionsTitle),                    
       61 +      title: _isSearching                                     
       62 +          ? _SearchField(                                     
       63 +              controller: _searchController,                  
       64 +              onChanged: _applySearch,                        
       65 +              onClose: _closeSearch,                          
       66 +            )                                                 
       67 +          : Text(l10n.transactionsTitle),                     
       68 +      actions: [                                              
       69 +        if (!_isSearching)                                    
       70 +          IconButton(                                         
       71 +            icon: const Icon(Icons.search),                   
       72 +            tooltip: l10n.transactionsSearchHint,             
       73 +            onPressed: () => setState(() => _isSearching = tru
          +e),                                                           
       74 +          ),                                                  
       75 +        IconButton(                                           
       76 +          icon: Badge(                                        
       77 +            isLabelVisible: _filter.hasActiveCriteria,        
       78 +            label: Text('${_filter.activeCriteriaCount}'),    
       79 +            child: const Icon(Icons.filter_list),             
       80 +          ),                                                  
       81 +          tooltip: l10n.transactionsFilterTitle,              
       82 +          onPressed: _openFilterSheet,                        
       83 +        ),                                                    
       84 +      ],                                                      
       85        floatingActionButton: FloatingActionButton(
       86          heroTag: 'fab_transactions',
       87          onPressed: () => context.push('/transactions/new'),
       88          child: const Icon(Icons.add),
       89        ),
       46 -      body: transactionsAsync.when(                           
       47 -        // A skeleton at the real row pitch, not a spinner: th
          -e list's geometry                                             
       48 -        // is already known, so nothing moves when the data la
          -nds.                                                          
       49 -        loading: () => const AppSkeletonList(),               
       50 -        error: (_, _) => AppErrorState(message: l10n.transacti
          -onsErrorTitle),                                               
       51 -        data: (result) => switch (result) {                   
       52 -          AppOk(:final value) when value.isEmpty => AppEmptySt
          -ate(                                                          
       53 -            title: l10n.transactionsEmpty,                    
       54 -            actionLabel: l10n.actionRecordExpense,            
       55 -            onAction: () => context.push('/transactions/new'),
       90 +      body: Column(                                           
       91 +        children: [                                           
       92 +          if (_isSearching)                                   
       93 +            // Said out loud rather than left to be discovered
          +: a search that                                               
       94 +            // silently spanned or silently respected the peri
          +od would be                                                   
       95 +            // equally confusing, so the screen states which i
          +t does.                                                       
       96 +            Padding(                                          
       97 +              padding: const EdgeInsets.symmetric(            
       98 +                horizontal: AppTheme.space16,                 
       99 +                vertical: AppTheme.space8,                    
      100 +              ),                                              
      101 +              child: Text(                                    
      102 +                l10n.transactionsSearchIgnoresPeriod,         
      103 +                style: context.textRoles.supportingMeta.copyWi
          +th(                                                           
      104 +                  color: context.financialColors.secondaryText
          +,                                                             
      105 +                ),                                            
      106 +              ),                                              
      107 +            ),                                                
      108 +          Expanded(                                           
      109 +            child: transactionsAsync.when(                    
      110 +              // A skeleton at the real row pitch, not a spinn
          +er: the list's                                                
      111 +              // geometry is already known, so nothing moves w
          +hen data lands.                                               
      112 +              loading: () => const AppSkeletonList(),         
      113 +              error: (_, _) =>                                
      114 +                  AppErrorState(message: l10n.transactionsErro
          +rTitle),                                                      
      115 +              data: (result) => switch (result) {             
      116 +                AppOk(:final value) when value.isEmpty => _Emp
          +tyState(                                                      
      117 +                  isFiltered:                                 
      118 +                      _filter.hasActiveCriteria ||            
      119 +                      (_filter.searchQuery?.isNotEmpty ?? fals
          +e),                                                           
      120 +                  unfilteredCount: unfilteredCount,           
      121 +                  onClearFilters: _clearFilters,              
      122 +                ),                                            
      123 +                AppOk(:final value) => RefreshIndicator(      
      124 +                  onRefresh: () async {                       
      125 +                    ref.invalidate(                           
      126 +                      transactionListProvider((_householdId, _
          +filter)),                                                     
      127 +                    );                                        
      128 +                  },                                          
      129 +                  child: _GroupedList(transactions: value),   
      130 +                ),                                            
      131 +                _ => AppErrorState(message: l10n.transactionsE
          +rrorTitle),                                                   
      132 +              },                                              
      133 +            ),                                                
      134            ),
       57 -          AppOk(:final value) => RefreshIndicator(            
       58 -            onRefresh: () async {                             
       59 -              ref.invalidate(transactionListProvider((_househo
          -ldId, filter)));                                              
       60 -            },                                                
       61 -            child: _GroupedList(transactions: value),         
       62 -          ),                                                  
       63 -          _ => AppErrorState(message: l10n.transactionsErrorTi
          -tle),                                                         
       64 -        },                                                    
      135 +        ],                                                    
      136        ),
      137      );
      138    }
      139 +                                                              
      140 +  /// Search deliberately drops the date bounds.              
      141 +  ///                                                         
      142 +  /// Someone searching for an amount is looking for one speci
          +fic transaction,                                              
      143 +  /// not browsing a month — a search that silently honoured t
          +he active period                                              
      144 +  /// would report "not found" for a transaction that exists. 
      145 +  void _applySearch(String query) {                           
      146 +    setState(() {                                             
      147 +      _filter = query.trim().isEmpty                          
      148 +          ? _filter.copyWith(clearSearchQuery: true)          
      149 +          : _filter.copyWith(searchQuery: query, clearDates: t
          +rue);                                                         
      150 +    });                                                       
      151 +  }                                                           
      152 +                                                              
      153 +  void _closeSearch() {                                       
      154 +    _searchController.clear();                                
      155 +    setState(() {                                             
      156 +      _isSearching = false;                                   
      157 +      _filter = _filter.copyWith(clearSearchQuery: true);     
      158 +    });                                                       
      159 +  }                                                           
      160 +                                                              
      161 +  void _clearFilters() {                                      
      162 +    _searchController.clear();                                
      163 +    setState(() {                                             
      164 +      _filter = const TransactionFilter();                    
      165 +      _isSearching = false;                                   
      166 +    });                                                       
      167 +  }                                                           
      168 +                                                              
      169 +  Future<void> _openFilterSheet() async {                     
      170 +    final updated = await showTransactionFilterSheet(         
      171 +      context: context,                                       
      172 +      initial: _filter,                                       
      173 +      householdId: _householdId,                              
      174 +    );                                                        
      175 +    if (updated == null || !mounted) return;                  
      176 +    setState(() => _filter = updated);                        
      177 +  }                                                           
      178  }
      179  
      180 +class _SearchField extends StatelessWidget {                  
      181 +  const _SearchField({                                        
      182 +    required this.controller,                                 
      183 +    required this.onChanged,                                  
      184 +    required this.onClose,                                    
      185 +  });                                                         
      186 +                                                              
      187 +  final TextEditingController controller;                     
      188 +  final ValueChanged<String> onChanged;                       
      189 +  final VoidCallback onClose;                                 
      190 +                                                              
      191 +  @override                                                   
      192 +  Widget build(BuildContext context) {                        
      193 +    final l10n = AppLocalizations.of(context);                
      194 +    return TextField(                                         
      195 +      controller: controller,                                 
      196 +      autofocus: true,                                        
      197 +      // The field is a first-strong isolate by virtue of the 
          +app's direction;                                              
      198 +      // a query like «382 ةلاقب» keeps its Latin numeric run 
          +intact because                                                
      199 +      // nothing here re-orders it.                           
      200 +      decoration: InputDecoration(                            
      201 +        hintText: l10n.transactionsSearchHint,                
      202 +        border: InputBorder.none,                             
      203 +        suffixIcon: IconButton(                               
      204 +          icon: const Icon(Icons.close),                      
      205 +          onPressed: onClose,                                 
      206 +        ),                                                    
      207 +      ),                                                      
      208 +      onChanged: onChanged,                                   
      209 +    );                                                        
      210 +  }                                                           
      211 +}                                                             
      212 +                                                              
      213 +/// Empty because the ledger is, or empty because a filter exc
          +luded everything.                                             
      214 +///                                                           
      215 +/// The two are different problems and get different copy: a f
          +iltered-empty                                                 
      216 +/// result names the count the user does have and offers to dr
          +op the filter,                                                
      217 +/// because an empty result is a filter problem, never a data 
          +problem.                                                      
      218 +class _EmptyState extends StatelessWidget {                   
      219 +  const _EmptyState({                                         
      220 +    required this.isFiltered,                                 
      221 +    required this.unfilteredCount,                            
      222 +    required this.onClearFilters,                             
      223 +  });                                                         
      224 +                                                              
      225 +  final bool isFiltered;                                      
      226 +  final int? unfilteredCount;                                 
      227 +  final VoidCallback onClearFilters;                          
      228 +                                                              
      229 +  @override                                                   
      230 +  Widget build(BuildContext context) {                        
      231 +    final l10n = AppLocalizations.of(context);                
      232 +    if (!isFiltered) {                                        
      233 +      return AppEmptyState(                                   
      234 +        title: l10n.transactionsEmpty,                        
      235 +        actionLabel: l10n.actionRecordExpense,                
      236 +        onAction: () => context.push('/transactions/new'),    
      237 +      );                                                      
      238 +    }                                                         
      239 +    return AppEmptyState(                                     
      240 +      title: l10n.transactionsEmptyFilteredTitle,             
      241 +      message: unfilteredCount == null                        
      242 +          ? null                                              
      243 +          : l10n.transactionsEmptyFilteredBody('$unfilteredCou
          +nt'),                                                         
      244 +      actionLabel: l10n.transactionsClearFilters,             
      245 +      onAction: onClearFilters,                               
      246 +      icon: Icons.filter_list_off,                            
      247 +    );                                                        
      248 +  }                                                           
      249 +}                                                             
      250 +                                                              
      251  class _GroupedList extends StatelessWidget {
      252    const _GroupedList({required this.transactions});
      253  

  Ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Now extend the list screen tests for filter and search:

  Ran 1 shell command (ctrl+o to expand)

⏺ Update(test/widget/features/transactions/transactions_screen_test.dart)
  ⎿  Error editing file

  Read 1 file, ran 1 shell command (ctrl+o to expand)
⏺ Update(test/widget/features/transactions/transactions_screen_test.dart)
  ⎿  Added 3 lines, removed 10 lines
      427        await tester.pumpAndSettle();
      428        await tester.tap(find.text(l10n.transactionsFilterShowRe
           versed));
      429        await tester.pumpAndSettle();
      430 -      await tester.tap(                                       
      431 -        find.textContaining(                                  
      432 -          l10n                                                
      433 -              .transactionsFilterApply('')                    
      434 -              .replaceAll('{count}', '')                      
      435 -              .trim()                                         
      436 -              .split(' ')                                     
      437 -              .first,                                         
      438 -        ),                                                    
      439 -      );                                                      
      430 +      // By type, because the confirm label carries a count th
          +at moves with                                                 
      431 +      // the draft — asserting on the text here would re-test 
          +the count.                                                    
      432 +      await tester.tap(find.byType(PrimaryActionButton));     
      433        await tester.pumpAndSettle();
      434  
      435        expect(requestedFilters.last.includeReversed, isFalse);

  Read 1 file, ran 7 shell commands (ctrl+o to expand)

⏺ Update(test/widget/features/transactions/transactions_screen_test.dart)
  ⎿  Added 1 line, removed 3 lines
      387          // Nothing selected yet: the count is the whole ledger
           .
      388          expect(find.text(l10n.transactionsFilterApply('1248'))
           , findsOneWidget);
      389  
      390 -        await tester.tap(                                     
      391 -          find.text(operationTypeLabel(l10n, OperationType.exp
          -ense)),                                                       
      392 -        );                                                    
      390 +        await tester.tap(_typeChip(l10n, OperationType.expense
          +));                                                           
      391          await tester.pumpAndSettle();
      392  
      393          // Selecting a type changes the promised count before 
           it is applied.

  Ran 1 shell command (ctrl+o to expand)

⏺ All 15 pass. Full check:

  Ran 2 shell commands (ctrl+o to expand)

⏺ The architecture boundary test caught my filter sheet doing raw /100 money
  scaling. Fixing it properly:

  Searched for 1 pattern, ran 5 shell commands (ctrl+o to expand)

⏺ +1872 −2 — back to only the two pre-existing failures.

  Implemented

  TransactionFilter grown up. It gained an amount band, search, a
  reversed-history toggle, value equality, and copyWith with explicit clear*
  flags. Two design decisions are enforced by the types rather than by checks:

  - TransactionAmountRange requires a currency. A band without one silently
  compares a USD row against an EGP threshold — the same error as a mixed total
  — so the invalid state is unrepresentable rather than validated after the
  fact.
  - includeReversed defaults to true. Hiding reversed history by default is the
  one thing an append-only ledger exists to prevent.

  Query support: account, amount band, reversed-history opt-out, and search
  across description, note and both account names — with LIKE metacharacters
  escaped, so typing % searches for % instead of matching everything. Plus
  countOperations, which runs the same joins with no LIMIT.

  The filter sheet puts the result count on its own confirm button: you see
  "show 87 transactions" before committing, so filtering to nothing becomes a
  rare accident rather than the normal way to find the empty state. The count
  updates live as the draft changes.

  Search drops the date bounds and says so on screen — someone searching for an
  amount wants one transaction, not a month, and a search that silently honoured
  the period would report "not found" for something that exists.

  The filtered-empty state is distinct from the empty-ledger one: it names the
  count you do have ("you have 1,248 transactions — none match this filter") and
  offers to clear, because an empty result is a filter problem, never a data
  problem.

  The repo's own architecture test caught me

  architecture_boundaries_test flagged my filter sheet doing value * 100 /
  minorUnits / 100 to convert typed bounds. That was a real defect, not a lint:
  the bounds would have disagreed with the amounts they're compared against for
  any non-2-scale currency, and would have rejected Arabic-Indic digits the rest
  of the app accepts. Both bounds now go through MoneyInputFormatter, and the
  input filter allows ٩–٠ and ٫/، to match what the parser handles.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 345 files
  - flutter test — +1872 −2

  20 new tests: 14 DB on filter semantics (currency isolation, inclusive bounds,
  both halves of a reversal excluded together, wildcard escaping,
  count-matches-list, household isolation), 6 widget on the sheet and search. 14
  ARB keys; both locales symmetric.

  Notes

  - Deliberately not built: category/account/member/scope pickers in the sheet —
  the filter supports them and the query applies them, but each needs its own
  picker surface, and the sheet is honest about offering only what it can
  actually set. Also not built: saved searches, the "nearest result without the
  amount condition" hint from C5, and the C6 pagination-failure banner.
  - The amount band is offered in EGP only; the sheet has no currency selector
  yet. It reads the currency from an existing band, so it round-trips correctly,
  but a user can't presently set a USD band.
  - Carried over unchanged: budgets/goals/certificates detail routes aren't root
  pushes; the dashboard query doesn't read reversal_reason; and your two open
  decisions (certificate-principal double classification, spouse-wallet
  exclusion).

✻ Crunched for 14m 19s

❯ go ahead                                                                      

  Searched for 1 pattern, read 2 files, ran 1 shell command (ctrl+o to expand)

⏺ Phase 9. Starting with the highest-value item — deleting ReportAmountText,
  which every report and budget amount currently flows through:

  Ran 1 shell command (ctrl+o to expand)

⏺ Now migrate the call sites. Income/expense first, as the template:

⏺ Write(lib/features/reports/presentation/income_expense_report_screen.dart)
  ⎿  Added 126 lines, removed 108 lines
       1  /// Income & Expense report screen.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
       9  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
       9 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      10 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      11  import 'package:flutter/material.dart';
      12  import 'package:flutter_riverpod/flutter_riverpod.dart';
      13  
     ...
      21      final req = ref.watch(reportRequestProvider);
      22      final reportAsync = ref.watch(incomeExpenseReportProvider(r
          eq));
      23  
      23 -    return Scaffold(                                           
      24 -      appBar: AppBar(                                          
      25 -        title: Text(l10n.reportIncomeExpenseTitle),            
      26 -        actions: [                                             
      27 -          IconButton(                                          
      28 -            icon: const Icon(Icons.refresh),                   
      29 -            tooltip: l10n.reportRefresh,                       
      30 -            onPressed: () => ref.invalidate(incomeExpenseReport
         -Provider(req)),                                                
      31 -          ),                                                   
      32 -        ],                                                     
      33 -      ),                                                       
      24 +    void retry() => ref.invalidate(incomeExpenseReportProvider(
         +req));                                                         
      25 +                                                               
      26 +    return AppScreenScaffold(                                  
      27 +      title: Text(l10n.reportIncomeExpenseTitle),              
      28 +      actions: [                                               
      29 +        IconButton(                                            
      30 +          icon: const Icon(Icons.refresh),                     
      31 +          tooltip: l10n.reportRefresh,                         
      32 +          onPressed: retry,                                    
      33 +        ),                                                     
      34 +      ],                                                       
      35        body: Column(
      36          crossAxisAlignment: CrossAxisAlignment.start,
      37          children: [
     ...
      39            const Divider(height: 1),
      40            Expanded(
      41              child: reportAsync.when(
      41 -              loading: () => const ReportLoading(),            
      42 -              error: (_, _) => ReportErrorState(               
      43 -                onRetry: () => ref.invalidate(incomeExpenseRepo
         -rtProvider(req)),                                              
      42 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      43 +              error: (_, _) => AppErrorState(                  
      44 +                message: l10n.reportError,                     
      45 +                onRetry: retry,                                
      46 +                retryLabel: l10n.reportRefresh,                
      47                ),
      48                data: (result) {
      49                  if (result is! AppOk<List<CurrencyFlowSummary>>
          ) {
      47 -                  return ReportErrorState(                     
      48 -                    onRetry: () =>                             
      49 -                        ref.invalidate(incomeExpenseReportProvi
         -der(req)),                                                     
      50 +                  return AppErrorState(                        
      51 +                    message: l10n.reportError,                 
      52 +                    onRetry: retry,                            
      53 +                    retryLabel: l10n.reportRefresh,            
      54                    );
      55                  }
      56                  final flows = result.value;
      53 -                if (flows.isEmpty) return const ReportEmptyStat
         -e();                                                           
      57 +                if (flows.isEmpty) {                           
      58 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      59 +                }                                              
      60                  return _IncomeExpenseContent(flows: flows, l10n
          : l10n);
      61                },
      62              ),
     ...
       75  
       76    @override
       77    Widget build(BuildContext context) {
       72 -    return ListView(                                          
       73 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       74 -      children: [                                             
       75 -        ReportInfoNote(text: l10n.reportTransferNote),        
       76 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       77 -        for (final flow in flows) ...[                        
       78 -          CurrencyHeader(currencyCode: flow.currencyCode),    
       79 -          _FlowCard(flow: flow, l10n: l10n),                  
       78 +    return ResponsiveContentContainer(                        
       79 +      child: ListView(                                        
       80 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       81 +        children: [                                           
       82 +          Padding(                                            
       83 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       84 +            child: Column(                                    
       85 +              children: [                                     
       86 +                AppInlineNotice(message: l10n.reportTransferNo
          +te),                                                          
       87 +                const SizedBox(height: AppTheme.space8),      
       88 +                AppInlineNotice(message: l10n.reportCurrencySe
          +parate),                                                      
       89 +              ],                                              
       90 +            ),                                                
       91 +          ),                                                  
       92 +          for (final flow in flows) ...[                      
       93 +            // One section per currency, never a combined tota
          +l: adding two                                                 
       94 +            // currencies produces a figure that is true of no
          +thing.                                                        
       95 +            SectionHeader(title: flow.currencyCode),          
       96 +            _FlowRows(flow: flow, l10n: l10n),                
       97 +          ],                                                  
       98 +          const SizedBox(height: AppTheme.space24),           
       99          ],
       81 -        const SizedBox(height: 24),                           
       82 -      ],                                                      
      100 +      ),                                                      
      101      );
      102    }
      103  }
      104  
       87 -class _FlowCard extends StatelessWidget {                     
       88 -  const _FlowCard({required this.flow, required this.l10n});  
      105 +class _FlowRows extends StatelessWidget {                     
      106 +  const _FlowRows({required this.flow, required this.l10n});  
      107  
      108    final CurrencyFlowSummary flow;
      109    final AppLocalizations l10n;
      110  
      111    @override
      112    Widget build(BuildContext context) {
       95 -    final colors = context.financialColors;                   
      113      final hasReversals = flow.hasReversalEffect;
      114  
       98 -    return Card(                                              
       99 -      margin: const EdgeInsets.symmetric(vertical: 4),        
      100 -      child: Padding(                                         
      101 -        padding: const EdgeInsets.all(12),                    
      102 -        child: Column(                                        
      103 -          crossAxisAlignment: CrossAxisAlignment.start,       
      104 -          children: [                                         
      105 -            // Income section                                 
      106 -            ReportAmountRow(                                  
      107 -              label: l10n.reportGrossIncome,                  
      108 -              minorUnits: flow.grossIncomeMinorUnits,         
      109 -              currencyCode: flow.currencyCode,                
      110 -              color: colors.income,                           
      111 -              icon: Icons.arrow_downward,                     
      112 -            ),                                                
      113 -            if (flow.incomeReversalMinorUnits != 0)           
      114 -              ReportAmountRow(                                
      115 -                label: l10n.reportReversalEffect,             
      116 -                minorUnits: -flow.incomeReversalMinorUnits,   
      117 -                currencyCode: flow.currencyCode,              
      118 -                color: colors.secondaryText,                  
      119 -                icon: Icons.undo,                             
      120 -              ),                                              
      121 -            if (hasReversals)                                 
      122 -              ReportAmountRow(                                
      123 -                label: l10n.reportNetIncome,                  
      124 -                minorUnits: flow.netIncomeMinorUnits,         
      125 -                currencyCode: flow.currencyCode,              
      126 -                color: colors.income,                         
      127 -                icon: Icons.arrow_downward,                   
      128 -                bold: true,                                   
      129 -              ),                                              
      130 -            const Divider(height: 12),                        
      131 -            // Expense section                                
      132 -            ReportAmountRow(                                  
      133 -              label: l10n.reportGrossExpense,                 
      134 -              minorUnits: flow.grossExpenseMinorUnits,        
      135 -              currencyCode: flow.currencyCode,                
      136 -              color: colors.expense,                          
      137 -              icon: Icons.arrow_upward,                       
      138 -            ),                                                
      139 -            if (flow.expenseReversalMinorUnits != 0)          
      140 -              ReportAmountRow(                                
      141 -                label: l10n.reportReversalEffect,             
      142 -                minorUnits: -flow.expenseReversalMinorUnits,  
      143 -                currencyCode: flow.currencyCode,              
      144 -                color: colors.secondaryText,                  
      145 -                icon: Icons.undo,                             
      146 -              ),                                              
      147 -            if (hasReversals)                                 
      148 -              ReportAmountRow(                                
      149 -                label: l10n.reportNetExpense,                 
      150 -                minorUnits: flow.netExpenseMinorUnits,        
      151 -                currencyCode: flow.currencyCode,              
      152 -                color: colors.expense,                        
      153 -                icon: Icons.arrow_upward,                     
      154 -                bold: true,                                   
      155 -              ),                                              
      156 -            const Divider(height: 12),                        
      157 -            // Net cash flow                                  
      158 -            ReportAmountRow(                                  
      159 -              label: l10n.reportNetCashFlow,                  
      160 -              minorUnits: flow.netCashFlowMinorUnits,         
      161 -              currencyCode: flow.currencyCode,                
      162 -              color: flow.netCashFlowMinorUnits >= 0          
      163 -                  ? colors.income                             
      164 -                  : colors.expense,                           
      165 -              bold: true,                                     
      166 -            ),                                                
      167 -            if (hasReversals) ...[                            
      168 -              const SizedBox(height: 4),                      
      169 -              ReportInfoNote(text: l10n.reportReversalNote),  
      170 -            ],                                                
      171 -          ],                                                  
      115 +    return Column(                                            
      116 +      crossAxisAlignment: CrossAxisAlignment.stretch,         
      117 +      children: [                                             
      118 +        CurrencyAmountRow(                                    
      119 +          label: l10n.reportGrossIncome,                      
      120 +          minorUnits: flow.grossIncomeMinorUnits,             
      121 +          currencyCode: flow.currencyCode,                    
      122 +          tone: FinancialAmountTone.income,                   
      123 +          direction: FinancialAmountDirection.inflow,         
      124          ),
      173 -      ),                                                      
      125 +        if (flow.incomeReversalMinorUnits != 0)               
      126 +          CurrencyAmountRow(                                  
      127 +            label: l10n.reportReversalEffect,                 
      128 +            minorUnits: flow.incomeReversalMinorUnits,        
      129 +            currencyCode: flow.currencyCode,                  
      130 +            // Reversing an income removes money that had been
          + counted as                                                   
      131 +            // arriving, so it reads as an outflow — quietly, 
          +because a                                                     
      132 +            // correction is not a threshold.                 
      133 +            tone: FinancialAmountTone.muted,                  
      134 +            direction: FinancialAmountDirection.outflow,      
      135 +          ),                                                  
      136 +        if (hasReversals)                                     
      137 +          CurrencyAmountRow(                                  
      138 +            label: l10n.reportNetIncome,                      
      139 +            minorUnits: flow.netIncomeMinorUnits,             
      140 +            currencyCode: flow.currencyCode,                  
      141 +            tone: FinancialAmountTone.income,                 
      142 +            direction: FinancialAmountDirection.inflow,       
      143 +            isEmphasised: true,                               
      144 +          ),                                                  
      145 +        CurrencyAmountRow(                                    
      146 +          label: l10n.reportGrossExpense,                     
      147 +          minorUnits: flow.grossExpenseMinorUnits,            
      148 +          currencyCode: flow.currencyCode,                    
      149 +          tone: FinancialAmountTone.expense,                  
      150 +          direction: FinancialAmountDirection.outflow,        
      151 +        ),                                                    
      152 +        if (flow.expenseReversalMinorUnits != 0)              
      153 +          CurrencyAmountRow(                                  
      154 +            label: l10n.reportReversalEffect,                 
      155 +            minorUnits: flow.expenseReversalMinorUnits,       
      156 +            currencyCode: flow.currencyCode,                  
      157 +            // The mirror of the line above: reversing an expe
          +nse returns                                                   
      158 +            // money that had been counted as spent.          
      159 +            tone: FinancialAmountTone.muted,                  
      160 +            direction: FinancialAmountDirection.inflow,       
      161 +          ),                                                  
      162 +        if (hasReversals)                                     
      163 +          CurrencyAmountRow(                                  
      164 +            label: l10n.reportNetExpense,                     
      165 +            minorUnits: flow.netExpenseMinorUnits,            
      166 +            currencyCode: flow.currencyCode,                  
      167 +            tone: FinancialAmountTone.expense,                
      168 +            direction: FinancialAmountDirection.outflow,      
      169 +            isEmphasised: true,                               
      170 +          ),                                                  
      171 +        // Weight, not colour. This figure was previously tint
          +ed green or red                                               
      172 +        // by its own sign, which puts a verdict on a derived 
          +number; the sign                                              
      173 +        // and the glyph already say which way it went.       
      174 +        CurrencyAmountRow(                                    
      175 +          label: l10n.reportNetCashFlow,                      
      176 +          minorUnits: flow.netCashFlowMinorUnits.abs(),       
      177 +          currencyCode: flow.currencyCode,                    
      178 +          direction: flow.netCashFlowMinorUnits >= 0          
      179 +              ? FinancialAmountDirection.inflow               
      180 +              : FinancialAmountDirection.outflow,             
      181 +          isEmphasised: true,                                 
      182 +          showDivider: false,                                 
      183 +        ),                                                    
      184 +        if (hasReversals) ...[                                
      185 +          const SizedBox(height: AppTheme.space8),            
      186 +          Padding(                                            
      187 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
      188 +            child: AppInlineNotice(message: l10n.reportReversa
          +lNote),                                                       
      189 +          ),                                                  
      190 +        ],                                                    
      191 +      ],                                                      
      192      );
      193    }
      194  }

  Ran 1 shell command (ctrl+o to expand)

⏺ Template works. Now the remaining nine files:

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/category_report_screen.dart)
  ⎿  Added 52 lines, removed 62 lines
       1  /// Category report screen — expense and income by category.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/applicati
          on/get_category_report_use_case.dart';
       9  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
      10  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
      10 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:family_money_manager/features/transactions/doma
          in/transaction_category.dart';
      13  import 'package:family_money_manager/features/transactions/pres
          entation/category_label_helper.dart';
      14  import 'package:flutter/material.dart';
     ...
      23      final req = ref.watch(reportRequestProvider);
      24      final reportAsync = ref.watch(categoryReportProvider(req));
      25  
      25 -    return Scaffold(                                           
      26 -      appBar: AppBar(                                          
      27 -        title: Text(l10n.reportCategoriesTitle),               
      28 -        actions: [                                             
      29 -          IconButton(                                          
      30 -            icon: const Icon(Icons.refresh),                   
      31 -            tooltip: l10n.reportRefresh,                       
      32 -            onPressed: () => ref.invalidate(categoryReportProvi
         -der(req)),                                                     
      33 -          ),                                                   
      34 -        ],                                                     
      35 -      ),                                                       
      26 +    void retry() => ref.invalidate(categoryReportProvider(req))
         +;                                                              
      27 +                                                               
      28 +    return AppScreenScaffold(                                  
      29 +      title: Text(l10n.reportCategoriesTitle),                 
      30 +      actions: [                                               
      31 +        IconButton(                                            
      32 +          icon: const Icon(Icons.refresh),                     
      33 +          tooltip: l10n.reportRefresh,                         
      34 +          onPressed: retry,                                    
      35 +        ),                                                     
      36 +      ],                                                       
      37        body: Column(
      38          children: [
      39            const ReportPeriodSelector(),
      40            const Divider(height: 1),
      41            Expanded(
      42              child: reportAsync.when(
      42 -              loading: () => const ReportLoading(),            
      43 -              error: (_, _) => ReportErrorState(               
      44 -                onRetry: () => ref.invalidate(categoryReportPro
         -vider(req)),                                                   
      43 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      44 +              error: (_, _) => AppErrorState(                  
      45 +                message: l10n.reportError,                     
      46 +                onRetry: retry,                                
      47 +                retryLabel: l10n.reportRefresh,                
      48                ),
      49                data: (result) {
      50                  if (result is! AppOk<CategoryReport>) {
      48 -                  return ReportErrorState(                     
      49 -                    onRetry: () => ref.invalidate(categoryRepor
         -tProvider(req)),                                               
      51 +                  return AppErrorState(                        
      52 +                    message: l10n.reportError,                 
      53 +                    onRetry: retry,                            
      54 +                    retryLabel: l10n.reportRefresh,            
      55                    );
      56                  }
      57                  final report = result.value;
      58                  if (report.expenseByCategory.isEmpty &&
      59                      report.incomeByCategory.isEmpty) {
      55 -                  return const ReportEmptyState();             
      60 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      61                  }
      62                  return _CategoryContent(report: report, l10n: l
          10n);
      63                },
     ...
       77  
       78    @override
       79    Widget build(BuildContext context) {
       75 -    return ListView(                                          
       76 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       77 -      children: [                                             
       78 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       79 -        if (report.expenseByCategory.isNotEmpty) ...[         
       80 -          _SectionHeader(title: l10n.reportGrossExpense),     
       81 -          for (final item in report.expenseByCategory)        
       82 -            _CategoryRow(item: item, l10n: l10n),             
       80 +    return ResponsiveContentContainer(                        
       81 +      child: ListView(                                        
       82 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       83 +        children: [                                           
       84 +          Padding(                                            
       85 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       86 +            child: AppInlineNotice(message: l10n.reportCurrenc
          +ySeparate),                                                   
       87 +          ),                                                  
       88 +          if (report.expenseByCategory.isNotEmpty) ...[       
       89 +            SectionHeader(title: l10n.reportGrossExpense),    
       90 +            for (final item in report.expenseByCategory)      
       91 +              _CategoryRow(item: item, l10n: l10n),           
       92 +          ],                                                  
       93 +          if (report.incomeByCategory.isNotEmpty) ...[        
       94 +            SectionHeader(title: l10n.reportGrossIncome),     
       95 +            for (final item in report.incomeByCategory)       
       96 +              _CategoryRow(item: item, l10n: l10n),           
       97 +          ],                                                  
       98 +          const SizedBox(height: AppTheme.space24),           
       99          ],
       84 -        if (report.incomeByCategory.isNotEmpty) ...[          
       85 -          _SectionHeader(title: l10n.reportGrossIncome),      
       86 -          for (final item in report.incomeByCategory)         
       87 -            _CategoryRow(item: item, l10n: l10n),             
       88 -        ],                                                    
       89 -        const SizedBox(height: 24),                           
       90 -      ],                                                      
       91 -    );                                                        
       92 -  }                                                           
       93 -}                                                             
       94 -                                                              
       95 -class _SectionHeader extends StatelessWidget {                
       96 -  const _SectionHeader({required this.title});                
       97 -  final String title;                                         
       98 -                                                              
       99 -  @override                                                   
      100 -  Widget build(BuildContext context) {                        
      101 -    return Padding(                                           
      102 -      padding: const EdgeInsets.only(top: 16, bottom: 4),     
      103 -      child: Text(                                            
      104 -        title,                                                
      105 -        style: Theme.of(                                      
      106 -          context,                                            
      107 -        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeigh
          -t.bold),                                                      
      100        ),
      101      );
      102    }
     ...
      110  
      111    @override
      112    Widget build(BuildContext context) {
      121 -    final colors = context.financialColors;                   
      113      final isExpense = item.categoryType == CategoryType.expens
           e;
      123 -    return ListTile(                                          
      124 -      contentPadding: EdgeInsets.zero,                        
      125 -      leading: const Icon(Icons.label_outline),               
      126 -      title: Text(categoryLabelFromCode(l10n, item.categoryCod
          -e)),                                                          
      127 -      subtitle: Text(l10n.reportTransactionCount(item.transact
          -ionCount)),                                                   
      128 -      trailing: ReportAmountText(                             
      129 -        minorUnits: item.totalMinorUnits,                     
      130 -        currencyCode: item.currencyCode,                      
      131 -        color: isExpense ? colors.expense : colors.income,    
      132 -      ),                                                      
      114 +    return CurrencyAmountRow(                                 
      115 +      label: categoryLabelFromCode(l10n, item.categoryCode),  
      116 +      caption: l10n.reportTransactionCount(item.transactionCou
          +nt),                                                          
      117 +      minorUnits: item.totalMinorUnits,                       
      118 +      currencyCode: item.currencyCode,                        
      119 +      tone: isExpense ? FinancialAmountTone.expense : Financia
          +lAmountTone.income,                                           
      120 +      direction: isExpense                                    
      121 +          ? FinancialAmountDirection.outflow                  
      122 +          : FinancialAmountDirection.inflow,                  
      123      );
      124    }
      125  }

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/report_flow_row.dart)
  ⎿  Wrote 76 lines to
     lib/features/reports/presentation/report_flow_row.dart
       1 /// One movement line in an account's period flow.
       3 /// Not a new component — it returns a [CurrencyAmountRow] and a
       4 /// of its own. What it owns is the one decision the report scre
         ens kept
         ned depending
         a *magnitude*
         ed value to it
       8 /// renders a double negative; passing a positive value to a lin
       9 /// represents a subtraction renders a lie. Deciding it once, he
      10 /// both flow reports can be read as arithmetic.
     … +80 lines (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/account_flow_report_screen.dart)
  ⎿  Error writing file
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/account_flow_report_screen.dart)  ⎿  Added 105 lines, removed 105 lines
       1  /// Account flow report screen — income/expense/transfer flows 
          per account.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
       9  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
       9 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      10 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_flow_row.dart';                                     
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:flutter/material.dart';
      13  import 'package:flutter_riverpod/flutter_riverpod.dart';
      14  
     ...
      21      final req = ref.watch(reportRequestProvider);
      22      final reportAsync = ref.watch(accountFlowReportProvider(req
          ));
      23  
      22 -    return Scaffold(                                           
      23 -      appBar: AppBar(                                          
      24 -        title: Text(l10n.reportAccountsTitle),                 
      25 -        actions: [                                             
      26 -          IconButton(                                          
      27 -            icon: const Icon(Icons.refresh),                   
      28 -            tooltip: l10n.reportRefresh,                       
      29 -            onPressed: () => ref.invalidate(accountFlowReportPr
         -ovider(req)),                                                  
      30 -          ),                                                   
      31 -        ],                                                     
      32 -      ),                                                       
      24 +    void retry() => ref.invalidate(accountFlowReportProvider(re
         +q));                                                           
      25 +                                                               
      26 +    return AppScreenScaffold(                                  
      27 +      title: Text(l10n.reportAccountsTitle),                   
      28 +      actions: [                                               
      29 +        IconButton(                                            
      30 +          icon: const Icon(Icons.refresh),                     
      31 +          tooltip: l10n.reportRefresh,                         
      32 +          onPressed: retry,                                    
      33 +        ),                                                     
      34 +      ],                                                       
      35        body: Column(
      36          children: [
      37            const ReportPeriodSelector(),
      38            const Divider(height: 1),
      39            Expanded(
      40              child: reportAsync.when(
      39 -              loading: () => const ReportLoading(),            
      40 -              error: (_, _) => ReportErrorState(               
      41 -                onRetry: () => ref.invalidate(accountFlowReport
         -Provider(req)),                                                
      41 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      42 +              error: (_, _) => AppErrorState(                  
      43 +                message: l10n.reportError,                     
      44 +                onRetry: retry,                                
      45 +                retryLabel: l10n.reportRefresh,                
      46                ),
      47                data: (result) {
      48                  if (result is! AppOk<List<AccountFlowBreakdown>
          >) {
      45 -                  return ReportErrorState(                     
      46 -                    onRetry: () =>                             
      47 -                        ref.invalidate(accountFlowReportProvide
         -r(req)),                                                       
      49 +                  return AppErrorState(                        
      50 +                    message: l10n.reportError,                 
      51 +                    onRetry: retry,                            
      52 +                    retryLabel: l10n.reportRefresh,            
      53                    );
      54                  }
      55                  final accounts = result.value;
      51 -                if (accounts.isEmpty) return const ReportEmptyS
         -tate();                                                        
      56 +                if (accounts.isEmpty) {                        
      57 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      58 +                }                                              
      59                  return _AccountFlowContent(accounts: accounts, 
          l10n: l10n);
      60                },
      61              ),
     ...
       74  
       75    @override
       76    Widget build(BuildContext context) {
       70 -    return ListView(                                          
       71 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       72 -      children: [                                             
       73 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       74 -        for (final account in accounts) ...[                  
       75 -          _AccountCard(account: account, l10n: l10n),         
       76 -          const SizedBox(height: 8),                          
       77 +    return ResponsiveContentContainer(                        
       78 +      child: ListView(                                        
       79 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       80 +        children: [                                           
       81 +          Padding(                                            
       82 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       83 +            child: AppInlineNotice(message: l10n.reportCurrenc
          +ySeparate),                                                   
       84 +          ),                                                  
       85 +          for (final account in accounts)                     
       86 +            _AccountFlow(account: account, l10n: l10n),       
       87 +          const SizedBox(height: AppTheme.space24),           
       88          ],
       78 -        const SizedBox(height: 24),                           
       79 -      ],                                                      
       89 +      ),                                                      
       90      );
       91    }
       92  }
       93  
       84 -class _AccountCard extends StatelessWidget {                  
       85 -  const _AccountCard({required this.account, required this.l10
          -n});                                                          
       94 +class _AccountFlow extends StatelessWidget {                  
       95 +  const _AccountFlow({required this.account, required this.l10
          +n});                                                          
       96  
       97    final AccountFlowBreakdown account;
       98    final AppLocalizations l10n;
       99  
      100    @override
      101    Widget build(BuildContext context) {
       92 -    final colors = context.financialColors;                   
       93 -    return Card(                                              
       94 -      margin: EdgeInsets.zero,                                
       95 -      child: Padding(                                         
       96 -        padding: const EdgeInsets.all(12),                    
       97 -        child: Column(                                        
       98 -          crossAxisAlignment: CrossAxisAlignment.start,       
       99 -          children: [                                         
      100 -            Text(                                             
      101 -              account.accountName,                            
      102 -              style: Theme.of(context).textTheme.titleSmall,  
      103 -            ),                                                
      104 -            const SizedBox(height: 8),                        
      105 -            ReportAmountRow(                                  
      106 -              label: l10n.reportOpeningBalance,               
      107 -              minorUnits: account.openingBalanceMinorUnits,   
      108 -              currencyCode: account.currencyCode,             
      109 -            ),                                                
      110 -            if (account.incomeMinorUnits != 0)                
      111 -              ReportAmountRow(                                
      112 -                label: l10n.dashboardPeriodIncome,            
      113 -                minorUnits: account.incomeMinorUnits,         
      114 -                currencyCode: account.currencyCode,           
      115 -                color: colors.income,                         
      116 -                icon: Icons.arrow_downward,                   
      117 -              ),                                              
      118 -            if (account.expenseMinorUnits != 0)               
      119 -              ReportAmountRow(                                
      120 -                label: l10n.dashboardPeriodExpenses,          
      121 -                minorUnits: -account.expenseMinorUnits,       
      122 -                currencyCode: account.currencyCode,           
      123 -                color: colors.expense,                        
      124 -                icon: Icons.arrow_upward,                     
      125 -              ),                                              
      126 -            if (account.transfersInMinorUnits != 0)           
      127 -              ReportAmountRow(                                
      128 -                label: '${l10n.transactionTypeTransfer} (+)', 
      129 -                minorUnits: account.transfersInMinorUnits,    
      130 -                currencyCode: account.currencyCode,           
      131 -                color: colors.transfer,                       
      132 -                icon: Icons.south_west,                       
      133 -              ),                                              
      134 -            if (account.transfersOutMinorUnits != 0)          
      135 -              ReportAmountRow(                                
      136 -                label: '${l10n.transactionTypeTransfer} (-)', 
      137 -                minorUnits: -account.transfersOutMinorUnits,  
      138 -                currencyCode: account.currencyCode,           
      139 -                color: colors.transfer,                       
      140 -                icon: Icons.north_east,                       
      141 -              ),                                              
      142 -            if (account.adjustmentsMinorUnits != 0)           
      143 -              ReportAmountRow(                                
      144 -                label: l10n.transactionTypeAdjustment,        
      145 -                minorUnits: account.adjustmentsMinorUnits,    
      146 -                currencyCode: account.currencyCode,           
      147 -                icon: Icons.tune,                             
      148 -              ),                                              
      149 -            if (account.reversalEffectMinorUnits != 0)        
      150 -              ReportAmountRow(                                
      151 -                label: l10n.reportReversalEffect,             
      152 -                minorUnits: account.reversalEffectMinorUnits, 
      153 -                currencyCode: account.currencyCode,           
      154 -                color: colors.secondaryText,                  
      155 -                icon: Icons.undo,                             
      156 -              ),                                              
      157 -            const Divider(height: 12),                        
      158 -            ReportAmountRow(                                  
      159 -              label: l10n.reportClosingBalance,               
      160 -              minorUnits: account.closingBalanceMinorUnits,   
      161 -              currencyCode: account.currencyCode,             
      162 -              bold: true,                                     
      163 -            ),                                                
      164 -          ],                                                  
      102 +    return Column(                                            
      103 +      crossAxisAlignment: CrossAxisAlignment.stretch,         
      104 +      children: [                                             
      105 +        SectionHeader(title: account.accountName),            
      106 +        balanceRow(                                           
      107 +          label: l10n.reportOpeningBalance,                   
      108 +          minorUnits: account.openingBalanceMinorUnits,       
      109 +          currencyCode: account.currencyCode,                 
      110          ),
      166 -      ),                                                      
      111 +        if (account.incomeMinorUnits != 0)                    
      112 +          flowRow(                                            
      113 +            label: l10n.dashboardPeriodIncome,                
      114 +            magnitudeMinorUnits: account.incomeMinorUnits,    
      115 +            currencyCode: account.currencyCode,               
      116 +            direction: FinancialAmountDirection.inflow,       
      117 +            tone: FinancialAmountTone.income,                 
      118 +          ),                                                  
      119 +        if (account.expenseMinorUnits != 0)                   
      120 +          flowRow(                                            
      121 +            label: l10n.dashboardPeriodExpenses,              
      122 +            magnitudeMinorUnits: account.expenseMinorUnits,   
      123 +            currencyCode: account.currencyCode,               
      124 +            direction: FinancialAmountDirection.outflow,      
      125 +            tone: FinancialAmountTone.expense,                
      126 +          ),                                                  
      127 +        // Transfers keep the internal glyph rather than a plu
          +s or a minus: a                                               
      128 +        // transfer changes no household total, and the label 
          +already says                                                  
      129 +        // which way it went for this account.                
      130 +        if (account.transfersInMinorUnits != 0)               
      131 +          flowRow(                                            
      132 +            label: l10n.reportTransferIn,                     
      133 +            magnitudeMinorUnits: account.transfersInMinorUnits
          +,                                                             
      134 +            currencyCode: account.currencyCode,               
      135 +            direction: FinancialAmountDirection.internal,     
      136 +            tone: FinancialAmountTone.transfer,               
      137 +          ),                                                  
      138 +        if (account.transfersOutMinorUnits != 0)              
      139 +          flowRow(                                            
      140 +            label: l10n.reportTransferOut,                    
      141 +            magnitudeMinorUnits: account.transfersOutMinorUnit
          +s,                                                            
      142 +            currencyCode: account.currencyCode,               
      143 +            direction: FinancialAmountDirection.internal,     
      144 +            tone: FinancialAmountTone.transfer,               
      145 +          ),                                                  
      146 +        if (account.adjustmentsMinorUnits != 0)               
      147 +          signedFlowRow(                                      
      148 +            label: l10n.transactionTypeAdjustment,            
      149 +            signedMinorUnits: account.adjustmentsMinorUnits,  
      150 +            currencyCode: account.currencyCode,               
      151 +          ),                                                  
      152 +        if (account.reversalEffectMinorUnits != 0)            
      153 +          signedFlowRow(                                      
      154 +            label: l10n.reportReversalEffect,                 
      155 +            signedMinorUnits: account.reversalEffectMinorUnits
          +,                                                             
      156 +            currencyCode: account.currencyCode,               
      157 +            tone: FinancialAmountTone.muted,                  
      158 +          ),                                                  
      159 +        balanceRow(                                           
      160 +          label: l10n.reportClosingBalance,                   
      161 +          minorUnits: account.closingBalanceMinorUnits,       
      162 +          currencyCode: account.currencyCode,                 
      163 +          isEmphasised: true,                                 
      164 +          showDivider: false,                                 
      165 +        ),                                                    
      166 +      ],                                                      
      167      );
      168    }
      169  }

  Ran 1 shell command (ctrl+o to expand)

⏺ Four down, six to go:

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/home_savings_report_screen.dart)
  ⎿  Error writing file

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/home_savings_report_screen.dart)
  ⎿  Added 117 lines, removed 113 lines
       1  /// Home savings flow report screen.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
       9  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
       9 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      10 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_flow_row.dart';                                     
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:flutter/material.dart';
      13  import 'package:flutter_riverpod/flutter_riverpod.dart';
      14  
     ...
      21      final req = ref.watch(reportRequestProvider);
      22      final reportAsync = ref.watch(homeSavingsReportProvider(req
          ));
      23  
      22 -    return Scaffold(                                           
      23 -      appBar: AppBar(                                          
      24 -        title: Text(l10n.reportHomeSavingsTitle),              
      25 -        actions: [                                             
      26 -          IconButton(                                          
      27 -            icon: const Icon(Icons.refresh),                   
      28 -            tooltip: l10n.reportRefresh,                       
      29 -            onPressed: () => ref.invalidate(homeSavingsReportPr
         -ovider(req)),                                                  
      30 -          ),                                                   
      31 -        ],                                                     
      32 -      ),                                                       
      24 +    void retry() => ref.invalidate(homeSavingsReportProvider(re
         +q));                                                           
      25 +                                                               
      26 +    return AppScreenScaffold(                                  
      27 +      title: Text(l10n.reportHomeSavingsTitle),                
      28 +      actions: [                                               
      29 +        IconButton(                                            
      30 +          icon: const Icon(Icons.refresh),                     
      31 +          tooltip: l10n.reportRefresh,                         
      32 +          onPressed: retry,                                    
      33 +        ),                                                     
      34 +      ],                                                       
      35        body: Column(
      36          children: [
      37            const ReportPeriodSelector(),
      38            const Divider(height: 1),
      39            Expanded(
      40              child: reportAsync.when(
      39 -              loading: () => const ReportLoading(),            
      40 -              error: (_, _) => ReportErrorState(               
      41 -                onRetry: () => ref.invalidate(homeSavingsReport
         -Provider(req)),                                                
      41 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      42 +              error: (_, _) => AppErrorState(                  
      43 +                message: l10n.reportError,                     
      44 +                onRetry: retry,                                
      45 +                retryLabel: l10n.reportRefresh,                
      46                ),
      47                data: (result) {
      48                  if (result is! AppOk<List<HomeSavingsFlowSummar
          y>>) {
      45 -                  return ReportErrorState(                     
      46 -                    onRetry: () =>                             
      47 -                        ref.invalidate(homeSavingsReportProvide
         -r(req)),                                                       
      49 +                  return AppErrorState(                        
      50 +                    message: l10n.reportError,                 
      51 +                    onRetry: retry,                            
      52 +                    retryLabel: l10n.reportRefresh,            
      53                    );
      54                  }
      55                  final accounts = result.value;
      51 -                if (accounts.isEmpty) return const ReportEmptyS
         -tate();                                                        
      56 +                if (accounts.isEmpty) {                        
      57 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      58 +                }                                              
      59                  return _HomeSavingsContent(accounts: accounts, 
          l10n: l10n);
      60                },
      61              ),
     ...
       74  
       75    @override
       76    Widget build(BuildContext context) {
       70 -    return ListView(                                          
       71 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       72 -      children: [                                             
       73 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       74 -        ReportInfoNote(text: l10n.reportTransferNote),        
       75 -        for (final account in accounts) ...[                  
       76 -          _HomeSavingsCard(account: account, l10n: l10n),     
       77 -          const SizedBox(height: 8),                          
       77 +    return ResponsiveContentContainer(                        
       78 +      child: ListView(                                        
       79 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       80 +        children: [                                           
       81 +          Padding(                                            
       82 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       83 +            child: Column(                                    
       84 +              children: [                                     
       85 +                AppInlineNotice(message: l10n.reportCurrencySe
          +parate),                                                      
       86 +                const SizedBox(height: AppTheme.space8),      
       87 +                AppInlineNotice(message: l10n.reportTransferNo
          +te),                                                          
       88 +              ],                                              
       89 +            ),                                                
       90 +          ),                                                  
       91 +          for (final account in accounts)                     
       92 +            _HomeSavingsFlow(account: account, l10n: l10n),   
       93 +          const SizedBox(height: AppTheme.space24),           
       94          ],
       79 -        const SizedBox(height: 24),                           
       80 -      ],                                                      
       95 +      ),                                                      
       96      );
       97    }
       98  }
       99  
       85 -class _HomeSavingsCard extends StatelessWidget {              
       86 -  const _HomeSavingsCard({required this.account, required this
          -.l10n});                                                      
      100 +class _HomeSavingsFlow extends StatelessWidget {              
      101 +  const _HomeSavingsFlow({required this.account, required this
          +.l10n});                                                      
      102  
      103    final HomeSavingsFlowSummary account;
      104    final AppLocalizations l10n;
      105  
      106    @override
      107    Widget build(BuildContext context) {
       93 -    final colors = context.financialColors;                   
       94 -    return Card(                                              
       95 -      margin: EdgeInsets.zero,                                
       96 -      child: Padding(                                         
       97 -        padding: const EdgeInsets.all(12),                    
       98 -        child: Column(                                        
       99 -          crossAxisAlignment: CrossAxisAlignment.start,       
      100 -          children: [                                         
      101 -            Text(                                             
      102 -              account.accountName,                            
      103 -              style: Theme.of(context).textTheme.titleSmall,  
      104 -            ),                                                
      105 -            const SizedBox(height: 8),                        
      106 -            ReportAmountRow(                                  
      107 -              label: l10n.reportOpeningBalance,               
      108 -              minorUnits: account.openingBalanceMinorUnits,   
      109 -              currencyCode: account.currencyCode,             
      110 -            ),                                                
      111 -            if (account.directIncomeMinorUnits != 0)          
      112 -              ReportAmountRow(                                
      113 -                label: l10n.dashboardPeriodIncome,            
      114 -                minorUnits: account.directIncomeMinorUnits,   
      115 -                currencyCode: account.currencyCode,           
      116 -                color: colors.income,                         
      117 -                icon: Icons.arrow_downward,                   
      118 -              ),                                              
      119 -            if (account.directExpenseMinorUnits != 0)         
      120 -              ReportAmountRow(                                
      121 -                label: l10n.dashboardPeriodExpenses,          
      122 -                minorUnits: -account.directExpenseMinorUnits, 
      123 -                currencyCode: account.currencyCode,           
      124 -                color: colors.expense,                        
      125 -                icon: Icons.arrow_upward,                     
      126 -              ),                                              
      127 -            if (account.spouseWalletFundingMinorUnits != 0)   
      128 -              ReportAmountRow(                                
      129 -                label: '${l10n.reportSpouseWalletTitle} (${l10
          -n.reportFunded})',                                            
      130 -                minorUnits: -account.spouseWalletFundingMinorU
          -nits,                                                         
      131 -                currencyCode: account.currencyCode,           
      132 -                color: colors.transfer,                       
      133 -                icon: Icons.north_east,                       
      134 -              ),                                              
      135 -            if (account.spouseWalletReturnMinorUnits != 0)    
      136 -              ReportAmountRow(                                
      137 -                label:                                        
      138 -                    '${l10n.reportSpouseWalletTitle} (${l10n.r
          -eportReturned})',                                             
      139 -                minorUnits: account.spouseWalletReturnMinorUni
          -ts,                                                           
      140 -                currencyCode: account.currencyCode,           
      141 -                color: colors.transfer,                       
      142 -                icon: Icons.south_west,                       
      143 -              ),                                              
      144 -            if (account.adjustmentsMinorUnits != 0)           
      145 -              ReportAmountRow(                                
      146 -                label: l10n.transactionTypeAdjustment,        
      147 -                minorUnits: account.adjustmentsMinorUnits,    
      148 -                currencyCode: account.currencyCode,           
      149 -                icon: Icons.tune,                             
      150 -              ),                                              
      151 -            if (account.reversalEffectMinorUnits != 0)        
      152 -              ReportAmountRow(                                
      153 -                label: l10n.reportReversalEffect,             
      154 -                minorUnits: account.reversalEffectMinorUnits, 
      155 -                currencyCode: account.currencyCode,           
      156 -                color: colors.secondaryText,                  
      157 -                icon: Icons.undo,                             
      158 -              ),                                              
      159 -            const Divider(height: 12),                        
      160 -            ReportAmountRow(                                  
      161 -              label: l10n.reportPeriodClosingBalance,         
      162 -              minorUnits: account.closingBalanceMinorUnits,   
      163 -              currencyCode: account.currencyCode,             
      164 -              bold: true,                                     
      165 -            ),                                                
      166 -            ReportAmountRow(                                  
      167 -              label: l10n.reportCurrentBalance,               
      168 -              minorUnits: account.currentBalanceMinorUnits,   
      169 -              currencyCode: account.currencyCode,             
      170 -              bold: true,                                     
      171 -            ),                                                
      172 -          ],                                                  
      108 +    return Column(                                            
      109 +      crossAxisAlignment: CrossAxisAlignment.stretch,         
      110 +      children: [                                             
      111 +        SectionHeader(title: account.accountName),            
      112 +        balanceRow(                                           
      113 +          label: l10n.reportOpeningBalance,                   
      114 +          minorUnits: account.openingBalanceMinorUnits,       
      115 +          currencyCode: account.currencyCode,                 
      116          ),
      174 -      ),                                                      
      117 +        if (account.directIncomeMinorUnits != 0)              
      118 +          flowRow(                                            
      119 +            label: l10n.dashboardPeriodIncome,                
      120 +            magnitudeMinorUnits: account.directIncomeMinorUnit
          +s,                                                            
      121 +            currencyCode: account.currencyCode,               
      122 +            direction: FinancialAmountDirection.inflow,       
      123 +            tone: FinancialAmountTone.income,                 
      124 +          ),                                                  
      125 +        if (account.directExpenseMinorUnits != 0)             
      126 +          flowRow(                                            
      127 +            label: l10n.dashboardPeriodExpenses,              
      128 +            magnitudeMinorUnits: account.directExpenseMinorUni
          +ts,                                                           
      129 +            currencyCode: account.currencyCode,               
      130 +            direction: FinancialAmountDirection.outflow,      
      131 +            tone: FinancialAmountTone.expense,                
      132 +          ),                                                  
      133 +        // Funding a spouse wallet moves money between the hou
          +sehold's own                                                  
      134 +        // accounts, so both legs carry the internal glyph and
          + neither is                                                   
      135 +        // spending. The label says which leg it is.          
      136 +        if (account.spouseWalletFundingMinorUnits != 0)       
      137 +          flowRow(                                            
      138 +            label: l10n.reportSpouseWalletFunded,             
      139 +            magnitudeMinorUnits: account.spouseWalletFundingMi
          +norUnits,                                                     
      140 +            currencyCode: account.currencyCode,               
      141 +            direction: FinancialAmountDirection.internal,     
      142 +            tone: FinancialAmountTone.transfer,               
      143 +          ),                                                  
      144 +        if (account.spouseWalletReturnMinorUnits != 0)        
      145 +          flowRow(                                            
      146 +            label: l10n.reportSpouseWalletReturned,           
      147 +            magnitudeMinorUnits: account.spouseWalletReturnMin
          +orUnits,                                                      
      148 +            currencyCode: account.currencyCode,               
      149 +            direction: FinancialAmountDirection.internal,     
      150 +            tone: FinancialAmountTone.transfer,               
      151 +          ),                                                  
      152 +        if (account.adjustmentsMinorUnits != 0)               
      153 +          signedFlowRow(                                      
      154 +            label: l10n.transactionTypeAdjustment,            
      155 +            signedMinorUnits: account.adjustmentsMinorUnits,  
      156 +            currencyCode: account.currencyCode,               
      157 +          ),                                                  
      158 +        if (account.reversalEffectMinorUnits != 0)            
      159 +          signedFlowRow(                                      
      160 +            label: l10n.reportReversalEffect,                 
      161 +            signedMinorUnits: account.reversalEffectMinorUnits
          +,                                                             
      162 +            currencyCode: account.currencyCode,               
      163 +            tone: FinancialAmountTone.muted,                  
      164 +          ),                                                  
      165 +        balanceRow(                                           
      166 +          label: l10n.reportPeriodClosingBalance,             
      167 +          minorUnits: account.closingBalanceMinorUnits,       
      168 +          currencyCode: account.currencyCode,                 
      169 +          isEmphasised: true,                                 
      170 +        ),                                                    
      171 +        balanceRow(                                           
      172 +          label: l10n.reportCurrentBalance,                   
      173 +          minorUnits: account.currentBalanceMinorUnits,       
      174 +          currencyCode: account.currencyCode,                 
      175 +          isEmphasised: true,                                 
      176 +          showDivider: false,                                 
      177 +        ),                                                    
      178 +      ],                                                      
      179      );
      180    }
      181  }

  Read 1 file, ran 1 shell command (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/spouse_wallet_report_screen.dart)
  ⎿  Added 114 lines, removed 100 lines
       1  /// Spouse wallet report screen.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
       9  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
       9 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      10 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_flow_row.dart';                                     
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:flutter/material.dart';
      13  import 'package:flutter_riverpod/flutter_riverpod.dart';
      14  
     ...
      21      final req = ref.watch(reportRequestProvider);
      22      final reportAsync = ref.watch(spouseWalletReportProvider(re
          q));
      23  
      22 -    return Scaffold(                                           
      23 -      appBar: AppBar(                                          
      24 -        title: Text(l10n.reportSpouseWalletTitle),             
      25 -        actions: [                                             
      26 -          IconButton(                                          
      27 -            icon: const Icon(Icons.refresh),                   
      28 -            tooltip: l10n.reportRefresh,                       
      29 -            onPressed: () => ref.invalidate(spouseWalletReportP
         -rovider(req)),                                                 
      30 -          ),                                                   
      31 -        ],                                                     
      32 -      ),                                                       
      24 +    void retry() => ref.invalidate(spouseWalletReportProvider(r
         +eq));                                                          
      25 +                                                               
      26 +    return AppScreenScaffold(                                  
      27 +      title: Text(l10n.reportSpouseWalletTitle),               
      28 +      actions: [                                               
      29 +        IconButton(                                            
      30 +          icon: const Icon(Icons.refresh),                     
      31 +          tooltip: l10n.reportRefresh,                         
      32 +          onPressed: retry,                                    
      33 +        ),                                                     
      34 +      ],                                                       
      35        body: Column(
      36          children: [
      37            const ReportPeriodSelector(),
      38            const Divider(height: 1),
      39            Expanded(
      40              child: reportAsync.when(
      39 -              loading: () => const ReportLoading(),            
      40 -              error: (_, _) => ReportErrorState(               
      41 -                onRetry: () => ref.invalidate(spouseWalletRepor
         -tProvider(req)),                                               
      41 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      42 +              error: (_, _) => AppErrorState(                  
      43 +                message: l10n.reportError,                     
      44 +                onRetry: retry,                                
      45 +                retryLabel: l10n.reportRefresh,                
      46                ),
      47                data: (result) {
      48                  if (result is! AppOk<List<SpouseWalletReport>>)
           {
      45 -                  return ReportErrorState(                     
      46 -                    onRetry: () =>                             
      47 -                        ref.invalidate(spouseWalletReportProvid
         -er(req)),                                                      
      49 +                  return AppErrorState(                        
      50 +                    message: l10n.reportError,                 
      51 +                    onRetry: retry,                            
      52 +                    retryLabel: l10n.reportRefresh,            
      53                    );
      54                  }
      55                  final wallets = result.value;
      51 -                if (wallets.isEmpty) return const ReportEmptySt
         -ate();                                                         
      56 +                if (wallets.isEmpty) {                         
      57 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      58 +                }                                              
      59                  return _SpouseWalletContent(wallets: wallets, l
          10n: l10n);
      60                },
      61              ),
     ...
       74  
       75    @override
       76    Widget build(BuildContext context) {
       70 -    return ListView(                                          
       71 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       72 -      children: [                                             
       73 -        ReportInfoNote(text: l10n.reportTransferNote),        
       74 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       75 -        for (final wallet in wallets) ...[                    
       76 -          _WalletCard(wallet: wallet, l10n: l10n),            
       77 -          const SizedBox(height: 8),                          
       77 +    return ResponsiveContentContainer(                        
       78 +      child: ListView(                                        
       79 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       80 +        children: [                                           
       81 +          Padding(                                            
       82 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       83 +            child: Column(                                    
       84 +              children: [                                     
       85 +                AppInlineNotice(message: l10n.reportTransferNo
          +te),                                                          
       86 +                const SizedBox(height: AppTheme.space8),      
       87 +                AppInlineNotice(message: l10n.reportCurrencySe
          +parate),                                                      
       88 +              ],                                              
       89 +            ),                                                
       90 +          ),                                                  
       91 +          for (final wallet in wallets)                       
       92 +            _WalletFlow(wallet: wallet, l10n: l10n),          
       93 +          const SizedBox(height: AppTheme.space24),           
       94          ],
       79 -        const SizedBox(height: 24),                           
       80 -      ],                                                      
       95 +      ),                                                      
       96      );
       97    }
       98  }
       99  
       85 -class _WalletCard extends StatelessWidget {                   
       86 -  const _WalletCard({required this.wallet, required this.l10n}
          -);                                                            
      100 +class _WalletFlow extends StatelessWidget {                   
      101 +  const _WalletFlow({required this.wallet, required this.l10n}
          +);                                                            
      102  
      103    final SpouseWalletReport wallet;
      104    final AppLocalizations l10n;
      105  
      106    @override
      107    Widget build(BuildContext context) {
       93 -    final colors = context.financialColors;                   
      108      return Semantics(
      109        label: wallet.accountName,
       96 -      child: Card(                                            
       97 -        margin: EdgeInsets.zero,                              
       98 -        child: Padding(                                       
       99 -          padding: const EdgeInsets.all(12),                  
      100 -          child: Column(                                      
      101 -            crossAxisAlignment: CrossAxisAlignment.start,     
      102 -            children: [                                       
      103 -              Text(                                           
      104 -                wallet.accountName,                           
      105 -                style: Theme.of(context).textTheme.titleSmall,
      106 -              ),                                              
      107 -              const SizedBox(height: 8),                      
      108 -              ReportAmountRow(                                
      109 -                label: l10n.reportOpeningBalance,             
      110 -                minorUnits: wallet.openingBalanceMinorUnits,  
      111 -                currencyCode: wallet.currencyCode,            
      112 -              ),                                              
      113 -              if (wallet.periodFundedMinorUnits != 0)         
      114 -                ReportAmountRow(                              
      115 -                  label: l10n.reportFunded,                   
      116 -                  minorUnits: wallet.periodFundedMinorUnits,  
      117 -                  currencyCode: wallet.currencyCode,          
      118 -                  color: colors.income,                       
      119 -                  icon: Icons.south_west,                     
      120 -                ),                                            
      121 -              if (wallet.periodSpentMinorUnits != 0)          
      122 -                ReportAmountRow(                              
      123 -                  label: l10n.reportSpent,                    
      124 -                  minorUnits: -wallet.periodSpentMinorUnits,  
      125 -                  currencyCode: wallet.currencyCode,          
      126 -                  color: colors.expense,                      
      127 -                  icon: Icons.arrow_upward,                   
      128 -                ),                                            
      129 -              if (wallet.periodReturnedMinorUnits != 0)       
      130 -                ReportAmountRow(                              
      131 -                  label: l10n.reportReturned,                 
      132 -                  minorUnits: -wallet.periodReturnedMinorUnits
          -,                                                             
      133 -                  currencyCode: wallet.currencyCode,          
      134 -                  color: colors.transfer,                     
      135 -                  icon: Icons.north_east,                     
      136 -                ),                                            
      137 -              if (wallet.periodReversalEffectMinorUnits != 0) 
      138 -                ReportAmountRow(                              
      139 -                  label: l10n.reportReversalEffect,           
      140 -                  minorUnits: wallet.periodReversalEffectMinor
          -Units,                                                        
      141 -                  currencyCode: wallet.currencyCode,          
      142 -                  color: colors.secondaryText,                
      143 -                  icon: Icons.undo,                           
      144 -                ),                                            
      145 -              const Divider(height: 12),                      
      146 -              ReportAmountRow(                                
      147 -                label: l10n.reportPeriodClosingBalance,       
      148 -                minorUnits: wallet.periodClosingBalanceMinorUn
          -its,                                                          
      149 -                currencyCode: wallet.currencyCode,            
      150 -                bold: true,                                   
      151 -              ),                                              
      152 -              ReportAmountRow(                                
      153 -                label: l10n.reportCurrentBalance,             
      154 -                minorUnits: wallet.currentBalanceMinorUnits,  
      155 -                currencyCode: wallet.currencyCode,            
      156 -                bold: true,                                   
      157 -              ),                                              
      158 -              if (wallet.periodClosingBalanceMinorUnits !=    
      159 -                  wallet.currentBalanceMinorUnits)            
      160 -                ReportInfoNote(text: l10n.reportReversalNote),
      161 -            ],                                                
      110 +      child: Column(                                          
      111 +        crossAxisAlignment: CrossAxisAlignment.stretch,       
      112 +        children: [                                           
      113 +          SectionHeader(title: wallet.accountName),           
      114 +          balanceRow(                                         
      115 +            label: l10n.reportOpeningBalance,                 
      116 +            minorUnits: wallet.openingBalanceMinorUnits,      
      117 +            currencyCode: wallet.currencyCode,                
      118            ),
      163 -        ),                                                    
      119 +          // Funding and returning are both moves between the 
          +household's own                                               
      120 +          // accounts. Only the middle line is real spending —
          + which is the                                                 
      121 +          // whole point of this report, and was previously ob
          +scured by                                                     
      122 +          // funding being tinted as income.                  
      123 +          if (wallet.periodFundedMinorUnits != 0)             
      124 +            flowRow(                                          
      125 +              label: l10n.reportFunded,                       
      126 +              magnitudeMinorUnits: wallet.periodFundedMinorUni
          +ts,                                                           
      127 +              currencyCode: wallet.currencyCode,              
      128 +              direction: FinancialAmountDirection.internal,   
      129 +              tone: FinancialAmountTone.transfer,             
      130 +            ),                                                
      131 +          if (wallet.periodSpentMinorUnits != 0)              
      132 +            flowRow(                                          
      133 +              label: l10n.reportSpent,                        
      134 +              magnitudeMinorUnits: wallet.periodSpentMinorUnit
          +s,                                                            
      135 +              currencyCode: wallet.currencyCode,              
      136 +              direction: FinancialAmountDirection.outflow,    
      137 +              tone: FinancialAmountTone.expense,              
      138 +            ),                                                
      139 +          if (wallet.periodReturnedMinorUnits != 0)           
      140 +            flowRow(                                          
      141 +              label: l10n.reportReturned,                     
      142 +              magnitudeMinorUnits: wallet.periodReturnedMinorU
          +nits,                                                         
      143 +              currencyCode: wallet.currencyCode,              
      144 +              direction: FinancialAmountDirection.internal,   
      145 +              tone: FinancialAmountTone.transfer,             
      146 +            ),                                                
      147 +          if (wallet.periodReversalEffectMinorUnits != 0)     
      148 +            signedFlowRow(                                    
      149 +              label: l10n.reportReversalEffect,               
      150 +              signedMinorUnits: wallet.periodReversalEffectMin
          +orUnits,                                                      
      151 +              currencyCode: wallet.currencyCode,              
      152 +              tone: FinancialAmountTone.muted,                
      153 +            ),                                                
      154 +          balanceRow(                                         
      155 +            label: l10n.reportPeriodClosingBalance,           
      156 +            minorUnits: wallet.periodClosingBalanceMinorUnits,
      157 +            currencyCode: wallet.currencyCode,                
      158 +            isEmphasised: true,                               
      159 +          ),                                                  
      160 +          balanceRow(                                         
      161 +            label: l10n.reportCurrentBalance,                 
      162 +            minorUnits: wallet.currentBalanceMinorUnits,      
      163 +            currencyCode: wallet.currencyCode,                
      164 +            isEmphasised: true,                               
      165 +            showDivider: false,                               
      166 +          ),                                                  
      167 +          if (wallet.periodClosingBalanceMinorUnits !=        
      168 +              wallet.currentBalanceMinorUnits) ...[           
      169 +            const SizedBox(height: AppTheme.space8),          
      170 +            Padding(                                          
      171 +              padding: const EdgeInsets.symmetric(            
      172 +                horizontal: AppTheme.space16,                 
      173 +              ),                                              
      174 +              child: AppInlineNotice(message: l10n.reportRever
          +salNote),                                                     
      175 +            ),                                                
      176 +          ],                                                  
      177 +        ],                                                    
      178        ),
      179      );
      180    }

  Searched for 3 patterns, read 1 file, ran 1 shell command (ctrl+o to expand)

⏺ Fixing defect #7 — the beneficiary and the recorder are printed as raw UUIDs:

  Ran 1 shell command (ctrl+o to expand)

⏺ Now the protected funds screen, surfacing the joined names:

⏺ Write(lib/features/reports/presentation/protected_funds_report_screen.dart)
  ⎿  Added 116 lines, removed 117 lines
       1  /// Protected funds report screen.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       6 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       7 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       8  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
       9  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
       9 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      10 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_flow_row.dart';                                     
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:flutter/material.dart';
      13  import 'package:flutter_riverpod/flutter_riverpod.dart';
      14  
     ...
      21      final req = ref.watch(reportRequestProvider);
      22      final reportAsync = ref.watch(protectedFundsReportProvider(
          req));
      23  
      22 -    return Scaffold(                                           
      23 -      appBar: AppBar(                                          
      24 -        title: Text(l10n.reportProtectedFundsTitle),           
      25 -        actions: [                                             
      26 -          IconButton(                                          
      27 -            icon: const Icon(Icons.refresh),                   
      28 -            tooltip: l10n.reportRefresh,                       
      29 -            onPressed: () => ref.invalidate(protectedFundsRepor
         -tProvider(req)),                                               
      30 -          ),                                                   
      31 -        ],                                                     
      32 -      ),                                                       
      24 +    void retry() => ref.invalidate(protectedFundsReportProvider
         +(req));                                                        
      25 +                                                               
      26 +    return AppScreenScaffold(                                  
      27 +      title: Text(l10n.reportProtectedFundsTitle),             
      28 +      actions: [                                               
      29 +        IconButton(                                            
      30 +          icon: const Icon(Icons.refresh),                     
      31 +          tooltip: l10n.reportRefresh,                         
      32 +          onPressed: retry,                                    
      33 +        ),                                                     
      34 +      ],                                                       
      35        body: Column(
      36          children: [
      37            const ReportPeriodSelector(),
      38            const Divider(height: 1),
      39            Expanded(
      40              child: reportAsync.when(
      39 -              loading: () => const ReportLoading(),            
      40 -              error: (_, _) => ReportErrorState(               
      41 -                onRetry: () =>                                 
      42 -                    ref.invalidate(protectedFundsReportProvider
         -(req)),                                                        
      41 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      42 +              error: (_, _) => AppErrorState(                  
      43 +                message: l10n.reportError,                     
      44 +                onRetry: retry,                                
      45 +                retryLabel: l10n.reportRefresh,                
      46                ),
      47                data: (result) {
      48                  if (result is! AppOk<List<ProtectedFundsSummary
          >>) {
      46 -                  return ReportErrorState(                     
      47 -                    onRetry: () =>                             
      48 -                        ref.invalidate(protectedFundsReportProv
         -ider(req)),                                                    
      49 +                  return AppErrorState(                        
      50 +                    message: l10n.reportError,                 
      51 +                    onRetry: retry,                            
      52 +                    retryLabel: l10n.reportRefresh,            
      53                    );
      54                  }
      55                  final funds = result.value;
      52 -                if (funds.isEmpty) return const ReportEmptyStat
         -e();                                                           
      56 +                if (funds.isEmpty) {                           
      57 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      58 +                }                                              
      59                  return _ProtectedFundsContent(funds: funds, l10
          n: l10n);
      60                },
      61              ),
     ...
       74  
       75    @override
       76    Widget build(BuildContext context) {
       71 -    return ListView(                                          
       72 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       73 -      children: [                                             
       74 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       75 -        for (final fund in funds) ...[                        
       76 -          _FundCard(fund: fund, l10n: l10n),                  
       77 -          const SizedBox(height: 8),                          
       77 +    return ResponsiveContentContainer(                        
       78 +      child: ListView(                                        
       79 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       80 +        children: [                                           
       81 +          Padding(                                            
       82 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       83 +            child: AppInlineNotice(message: l10n.reportCurrenc
          +ySeparate),                                                   
       84 +          ),                                                  
       85 +          for (final fund in funds) _FundFlow(fund: fund, l10n
          +: l10n),                                                      
       86 +          const SizedBox(height: AppTheme.space24),           
       87          ],
       79 -        const SizedBox(height: 24),                           
       80 -      ],                                                      
       88 +      ),                                                      
       89      );
       90    }
       91  }
       92  
       85 -class _FundCard extends StatelessWidget {                     
       86 -  const _FundCard({required this.fund, required this.l10n});  
       93 +class _FundFlow extends StatelessWidget {                     
       94 +  const _FundFlow({required this.fund, required this.l10n});  
       95  
       96    final ProtectedFundsSummary fund;
       97    final AppLocalizations l10n;
       98  
       99    @override
      100    Widget build(BuildContext context) {
       93 -    final colors = context.financialColors;                   
       94 -    return Card(                                              
       95 -      margin: EdgeInsets.zero,                                
       96 -      child: Padding(                                         
       97 -        padding: const EdgeInsets.all(12),                    
       98 -        child: Column(                                        
       99 -          crossAxisAlignment: CrossAxisAlignment.start,       
      100 -          children: [                                         
      101 -            Text(                                             
      102 -              fund.accountName,                               
      103 -              style: Theme.of(context).textTheme.titleSmall,  
      104 -            ),                                                
      105 -            const SizedBox(height: 8),                        
      106 -            ReportAmountRow(                                  
      107 -              label: l10n.reportOpeningBalance,               
      108 -              minorUnits: fund.openingBalanceMinorUnits,      
      109 -              currencyCode: fund.currencyCode,                
      110 -            ),                                                
      111 -            if (fund.fundingMinorUnits != 0)                  
      112 -              ReportAmountRow(                                
      113 -                label: l10n.reportFunded,                     
      114 -                minorUnits: fund.fundingMinorUnits,           
      115 -                currencyCode: fund.currencyCode,              
      116 -                color: colors.income,                         
      117 -                icon: Icons.arrow_downward,                   
      118 -              ),                                              
      119 -            if (fund.withdrawalMinorUnits != 0)               
      120 -              ReportAmountRow(                                
      121 -                label: l10n.reportWithdrawals,                
      122 -                minorUnits: -fund.withdrawalMinorUnits,       
      123 -                currencyCode: fund.currencyCode,              
      124 -                color: colors.expense,                        
      125 -                icon: Icons.arrow_upward,                     
      126 -              ),                                              
      127 -            if (fund.reversalEffectMinorUnits != 0)           
      128 -              ReportAmountRow(                                
      129 -                label: l10n.reportReversalEffect,             
      130 -                minorUnits: fund.reversalEffectMinorUnits,    
      131 -                currencyCode: fund.currencyCode,              
      132 -                color: colors.secondaryText,                  
      133 -                icon: Icons.undo,                             
      134 -              ),                                              
      135 -            const Divider(height: 12),                        
      136 -            ReportAmountRow(                                  
      137 -              label: l10n.reportPeriodClosingBalance,         
      138 -              minorUnits: fund.closingBalanceMinorUnits,      
      139 -              currencyCode: fund.currencyCode,                
      140 -              bold: true,                                     
      141 -            ),                                                
      142 -            ReportAmountRow(                                  
      143 -              label: l10n.reportCurrentBalance,               
      144 -              minorUnits: fund.currentBalanceMinorUnits,      
      145 -              currencyCode: fund.currencyCode,                
      146 -              bold: true,                                     
      147 -            ),                                                
      148 -            if (fund.withdrawalAudits.isNotEmpty) ...[        
      149 -              const SizedBox(height: 8),                      
      150 -              Text(                                           
      151 -                l10n.reportWithdrawals,                       
      152 -                style: Theme.of(context).textTheme.labelMedium
          -,                                                             
      153 -              ),                                              
      154 -              ...fund.withdrawalAudits.map(                   
      155 -                (audit) => _AuditRow(audit: audit, l10n: l10n)
          -,                                                             
      156 -              ),                                              
      157 -            ],                                                
      158 -          ],                                                  
      101 +    return Column(                                            
      102 +      crossAxisAlignment: CrossAxisAlignment.stretch,         
      103 +      children: [                                             
      104 +        SectionHeader(title: fund.accountName),               
      105 +        // Protected money is stated as held: it exists, and i
          +t cannot be                                                   
      106 +        // spent. That is a different thing from a spendable b
          +alance, and the                                               
      107 +        // component says so with the lock rather than with a 
          +colour.                                                       
      108 +        balanceRow(                                           
      109 +          label: l10n.reportOpeningBalance,                   
      110 +          minorUnits: fund.openingBalanceMinorUnits,          
      111 +          currencyCode: fund.currencyCode,                    
      112          ),
      160 -      ),                                                      
      113 +        if (fund.fundingMinorUnits != 0)                      
      114 +          flowRow(                                            
      115 +            label: l10n.reportFunded,                         
      116 +            magnitudeMinorUnits: fund.fundingMinorUnits,      
      117 +            currencyCode: fund.currencyCode,                  
      118 +            direction: FinancialAmountDirection.inflow,       
      119 +            tone: FinancialAmountTone.protected,              
      120 +          ),                                                  
      121 +        if (fund.withdrawalMinorUnits != 0)                   
      122 +          flowRow(                                            
      123 +            label: l10n.reportWithdrawals,                    
      124 +            magnitudeMinorUnits: fund.withdrawalMinorUnits,   
      125 +            currencyCode: fund.currencyCode,                  
      126 +            direction: FinancialAmountDirection.outflow,      
      127 +            tone: FinancialAmountTone.protected,              
      128 +          ),                                                  
      129 +        if (fund.reversalEffectMinorUnits != 0)               
      130 +          signedFlowRow(                                      
      131 +            label: l10n.reportReversalEffect,                 
      132 +            signedMinorUnits: fund.reversalEffectMinorUnits,  
      133 +            currencyCode: fund.currencyCode,                  
      134 +            tone: FinancialAmountTone.muted,                  
      135 +          ),                                                  
      136 +        balanceRow(                                           
      137 +          label: l10n.reportPeriodClosingBalance,             
      138 +          minorUnits: fund.closingBalanceMinorUnits,          
      139 +          currencyCode: fund.currencyCode,                    
      140 +          isEmphasised: true,                                 
      141 +        ),                                                    
      142 +        balanceRow(                                           
      143 +          label: l10n.reportCurrentBalance,                   
      144 +          minorUnits: fund.currentBalanceMinorUnits,          
      145 +          currencyCode: fund.currencyCode,                    
      146 +          isEmphasised: true,                                 
      147 +          showDivider: false,                                 
      148 +        ),                                                    
      149 +        if (fund.withdrawalAudits.isNotEmpty) ...[            
      150 +          const SizedBox(height: AppTheme.space16),           
      151 +          SectionHeader(title: l10n.reportWithdrawals),       
      152 +          for (final audit in fund.withdrawalAudits)          
      153 +            _AuditRow(audit: audit, l10n: l10n),              
      154 +        ],                                                    
      155 +      ],                                                      
      156      );
      157    }
      158  }
     ...
      165  
      166    @override
      167    Widget build(BuildContext context) {
      173 -    final colors = context.financialColors;                   
      174 -    return ListTile(                                          
      175 -      contentPadding: EdgeInsets.zero,                        
      176 -      dense: true,                                            
      177 -      leading: Icon(                                          
      178 -        audit.isReversed ? Icons.undo : Icons.arrow_upward,   
      179 -        color: audit.isReversed ? colors.secondaryText : color
          -s.expense,                                                    
      180 -        size: 18,                                             
      181 -      ),                                                      
      182 -      title: Text(audit.reason, maxLines: 1, overflow: TextOve
          -rflow.ellipsis),                                              
      183 -      subtitle: Text(                                         
      184 -        '${l10n.reportBeneficiary}: ${audit.beneficiaryMemberI
          -d}  •  ${audit.effectiveDate}',                               
      185 -      ),                                                      
      186 -      trailing: ReportAmountText(                             
      187 -        minorUnits: audit.amountMinorUnits,                   
      188 -        currencyCode: audit.currencyCode,                     
      189 -        color: audit.isReversed ? colors.secondaryText : color
          -s.expense,                                                    
      190 -      ),                                                      
      168 +    // The caption is the audit trail: who it was for, who rec
          +orded it, when.                                               
      169 +    // It printed a raw UUID for the beneficiary before, and n
          +ever named the                                                
      170 +    // recorder at all even though the column was already stor
          +ed.                                                           
      171 +    final beneficiary = audit.beneficiaryName ?? audit.benefic
          +iaryMemberId;                                                 
      172 +    final caption = audit.recordedByName == null              
      173 +        ? l10n.reportAuditFor(beneficiary, audit.effectiveDate
          +)                                                             
      174 +        : l10n.reportAuditForBy(                              
      175 +            beneficiary,                                      
      176 +            audit.recordedByName!,                            
      177 +            audit.effectiveDate,                              
      178 +          );                                                  
      179 +                                                              
      180 +    return CurrencyAmountRow(                                 
      181 +      label: audit.reason,                                    
      182 +      caption: caption,                                       
      183 +      minorUnits: audit.amountMinorUnits,                     
      184 +      currencyCode: audit.currencyCode,                       
      185 +      tone: audit.isReversed                                  
      186 +          ? FinancialAmountTone.muted                         
      187 +          : FinancialAmountTone.protected,                    
      188 +      direction: FinancialAmountDirection.outflow,            
      189 +      semanticsContext: beneficiary,                          
      190      );
      191    }
      192  }

  Ran 1 shell command (ctrl+o to expand)

⏺ Two report screens and two budget screens left:

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/spending_attribution_report_screen.dar
       t)
  ⎿  Added 81 lines, removed 129 lines
       1  /// Spending attribution report screen — by spender, beneficiar
          y, and scope.
       2  library;
       3  
       4 +import 'package:family_money_manager/app/app_theme.dart';      
       5  import 'package:family_money_manager/core/application/app_resul
          t.dart';
       5 -import 'package:family_money_manager/core/financial/account_enu
         -ms.dart';                                                      
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       7  import 'package:family_money_manager/core/localization/enum_lab
          el_helpers.dart';
       8 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       8 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       9  import 'package:family_money_manager/features/reports/applicati
          on/get_spending_attribution_report_use_case.dart';
      10  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
      11 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:flutter/material.dart';
      13  import 'package:flutter_riverpod/flutter_riverpod.dart';
      14  
     ...
      22      final req = ref.watch(reportRequestProvider);
      23      final reportAsync = ref.watch(spendingAttributionReportProv
          ider(req));
      24  
      25 -    return Scaffold(                                           
      26 -      appBar: AppBar(                                          
      27 -        title: Text(l10n.reportAttributionTitle),              
      28 -        actions: [                                             
      29 -          IconButton(                                          
      30 -            icon: const Icon(Icons.refresh),                   
      31 -            tooltip: l10n.reportRefresh,                       
      32 -            onPressed: () =>                                   
      33 -                ref.invalidate(spendingAttributionReportProvide
         -r(req)),                                                       
      34 -          ),                                                   
      35 -        ],                                                     
      36 -      ),                                                       
      25 +    void retry() => ref.invalidate(spendingAttributionReportPro
         +vider(req));                                                   
      26 +                                                               
      27 +    return AppScreenScaffold(                                  
      28 +      title: Text(l10n.reportAttributionTitle),                
      29 +      actions: [                                               
      30 +        IconButton(                                            
      31 +          icon: const Icon(Icons.refresh),                     
      32 +          tooltip: l10n.reportRefresh,                         
      33 +          onPressed: retry,                                    
      34 +        ),                                                     
      35 +      ],                                                       
      36        body: Column(
      37          children: [
      38            const ReportPeriodSelector(),
      39            const Divider(height: 1),
      40            Expanded(
      41              child: reportAsync.when(
      43 -              loading: () => const ReportLoading(),            
      44 -              error: (_, _) => ReportErrorState(               
      45 -                onRetry: () =>                                 
      46 -                    ref.invalidate(spendingAttributionReportPro
         -vider(req)),                                                   
      42 +              loading: () => AppLoadingState(message: l10n.load
         +ingLabel),                                                     
      43 +              error: (_, _) => AppErrorState(                  
      44 +                message: l10n.reportError,                     
      45 +                onRetry: retry,                                
      46 +                retryLabel: l10n.reportRefresh,                
      47                ),
      48                data: (result) {
      49                  if (result is! AppOk<SpendingAttributionReport>
          ) {
      50 -                  return ReportErrorState(                     
      51 -                    onRetry: () =>                             
      52 -                        ref.invalidate(spendingAttributionRepor
         -tProvider(req)),                                               
      50 +                  return AppErrorState(                        
      51 +                    message: l10n.reportError,                 
      52 +                    onRetry: retry,                            
      53 +                    retryLabel: l10n.reportRefresh,            
      54                    );
      55                  }
      56                  final report = result.value;
     ...
      58                      report.bySpender.isNotEmpty ||
      59                      report.byBeneficiary.isNotEmpty ||
      60                      report.byScope.isNotEmpty;
      60 -                if (!hasData) return const ReportEmptyState(); 
      61 +                if (!hasData) {                                
      62 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      63 +                }                                              
      64                  return _AttributionContent(report: report, l10n
          : l10n);
      65                },
      66              ),
     ...
       79  
       80    @override
       81    Widget build(BuildContext context) {
       79 -    return ListView(                                          
       80 -      padding: const EdgeInsets.symmetric(horizontal: 16, vert
          -ical: 8),                                                     
       81 -      children: [                                             
       82 -        ReportInfoNote(text: l10n.reportCurrencySeparate),    
       83 -        // By Spender                                         
       84 -        if (report.bySpender.isNotEmpty) ...[                 
       85 -          _SectionHeader(title: l10n.reportSpenderSection),   
       86 -          for (final item in report.bySpender)                
       87 -            _MemberRow(                                       
       88 -              memberName: item.memberDisplayName,             
       89 -              totalMinorUnits: item.totalMinorUnits,          
       90 -              currencyCode: item.currencyCode,                
       91 -              transactionCount: item.transactionCount,        
       92 -              l10n: l10n,                                     
       93 -            ),                                                
       82 +    return ResponsiveContentContainer(                        
       83 +      child: ListView(                                        
       84 +        padding: const EdgeInsets.symmetric(vertical: AppTheme
          +.space8),                                                     
       85 +        children: [                                           
       86 +          Padding(                                            
       87 +            padding: const EdgeInsets.symmetric(horizontal: Ap
          +pTheme.space16),                                              
       88 +            child: AppInlineNotice(message: l10n.reportCurrenc
          +ySeparate),                                                   
       89 +          ),                                                  
       90 +          if (report.bySpender.isNotEmpty) ...[               
       91 +            SectionHeader(title: l10n.reportSpenderSection),  
       92 +            for (final item in report.bySpender)              
       93 +              _AttributionRow(                                
       94 +                label: item.memberDisplayName,                
       95 +                totalMinorUnits: item.totalMinorUnits,        
       96 +                currencyCode: item.currencyCode,              
       97 +                transactionCount: item.transactionCount,      
       98 +                l10n: l10n,                                   
       99 +              ),                                              
      100 +          ],                                                  
      101 +          if (report.byBeneficiary.isNotEmpty) ...[           
      102 +            SectionHeader(title: l10n.reportBeneficiarySection
          +),                                                            
      103 +            for (final item in report.byBeneficiary)          
      104 +              _AttributionRow(                                
      105 +                label: item.memberDisplayName,                
      106 +                totalMinorUnits: item.totalMinorUnits,        
      107 +                currencyCode: item.currencyCode,              
      108 +                transactionCount: item.transactionCount,      
      109 +                l10n: l10n,                                   
      110 +              ),                                              
      111 +          ],                                                  
      112 +          if (report.byScope.isNotEmpty) ...[                 
      113 +            SectionHeader(title: l10n.reportScopeSection),    
      114 +            for (final item in report.byScope)                
      115 +              _AttributionRow(                                
      116 +                label: expenseScopeDashboardLabel(l10n, item.s
          +cope),                                                        
      117 +                totalMinorUnits: item.totalMinorUnits,        
      118 +                currencyCode: item.currencyCode,              
      119 +                transactionCount: item.transactionCount,      
      120 +                l10n: l10n,                                   
      121 +              ),                                              
      122 +          ],                                                  
      123 +          const SizedBox(height: AppTheme.space24),           
      124          ],
       95 -        // By Beneficiary                                     
       96 -        if (report.byBeneficiary.isNotEmpty) ...[             
       97 -          _SectionHeader(title: l10n.reportBeneficiarySection)
          -,                                                             
       98 -          for (final item in report.byBeneficiary)            
       99 -            _MemberRow(                                       
      100 -              memberName: item.memberDisplayName,             
      101 -              totalMinorUnits: item.totalMinorUnits,          
      102 -              currencyCode: item.currencyCode,                
      103 -              transactionCount: item.transactionCount,        
      104 -              l10n: l10n,                                     
      105 -            ),                                                
      106 -        ],                                                    
      107 -        // By Scope                                           
      108 -        if (report.byScope.isNotEmpty) ...[                   
      109 -          _SectionHeader(title: l10n.reportScopeSection),     
      110 -          for (final item in report.byScope)                  
      111 -            _ScopeRow(                                        
      112 -              scope: item.scope,                              
      113 -              totalMinorUnits: item.totalMinorUnits,          
      114 -              currencyCode: item.currencyCode,                
      115 -              transactionCount: item.transactionCount,        
      116 -              l10n: l10n,                                     
      117 -            ),                                                
      118 -        ],                                                    
      119 -        const SizedBox(height: 24),                           
      120 -      ],                                                      
      121 -    );                                                        
      122 -  }                                                           
      123 -}                                                             
      124 -                                                              
      125 -class _SectionHeader extends StatelessWidget {                
      126 -  const _SectionHeader({required this.title});                
      127 -  final String title;                                         
      128 -                                                              
      129 -  @override                                                   
      130 -  Widget build(BuildContext context) {                        
      131 -    return Padding(                                           
      132 -      padding: const EdgeInsets.only(top: 16, bottom: 4),     
      133 -      child: Text(                                            
      134 -        title,                                                
      135 -        style: Theme.of(                                      
      136 -          context,                                            
      137 -        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeigh
          -t.bold),                                                      
      125        ),
      126      );
      127    }
      128  }
      129  
      143 -class _MemberRow extends StatelessWidget {                    
      144 -  const _MemberRow({                                          
      145 -    required this.memberName,                                 
      130 +/// One attributed total. The three sections differ only in wh
          +at the label is,                                              
      131 +/// so they share a row rather than duplicating one per dimens
          +ion.                                                          
      132 +class _AttributionRow extends StatelessWidget {               
      133 +  const _AttributionRow({                                     
      134 +    required this.label,                                      
      135      required this.totalMinorUnits,
      136      required this.currencyCode,
      137      required this.transactionCount,
      138      required this.l10n,
      139    });
      140  
      152 -  final String memberName;                                    
      141 +  final String label;                                         
      142    final int totalMinorUnits;
      143    final String currencyCode;
      144    final int transactionCount;
     ...
      146  
      147    @override
      148    Widget build(BuildContext context) {
      160 -    final colors = context.financialColors;                   
      161 -    return ListTile(                                          
      162 -      contentPadding: EdgeInsets.zero,                        
      163 -      title: Text(memberName),                                
      164 -      subtitle: Text(l10n.reportTransactionCount(transactionCo
          -unt)),                                                        
      165 -      trailing: ReportAmountText(                             
      166 -        minorUnits: totalMinorUnits,                          
      167 -        currencyCode: currencyCode,                           
      168 -        color: colors.expense,                                
      169 -      ),                                                      
      149 +    return CurrencyAmountRow(                                 
      150 +      label: label,                                           
      151 +      caption: l10n.reportTransactionCount(transactionCount), 
      152 +      minorUnits: totalMinorUnits,                            
      153 +      currencyCode: currencyCode,                             
      154 +      tone: FinancialAmountTone.expense,                      
      155 +      direction: FinancialAmountDirection.outflow,            
      156      );
      157    }
      158  }
      173 -                                                              
      174 -class _ScopeRow extends StatelessWidget {                     
      175 -  const _ScopeRow({                                           
      176 -    required this.scope,                                      
      177 -    required this.totalMinorUnits,                            
      178 -    required this.currencyCode,                               
      179 -    required this.transactionCount,                           
      180 -    required this.l10n,                                       
      181 -  });                                                         
      182 -                                                              
      183 -  final ExpenseScope scope;                                   
      184 -  final int totalMinorUnits;                                  
      185 -  final String currencyCode;                                  
      186 -  final int transactionCount;                                 
      187 -  final AppLocalizations l10n;                                
      188 -                                                              
      189 -  String _scopeLabel(AppLocalizations l10n) =>                
      190 -      expenseScopeDashboardLabel(l10n, scope);                
      191 -                                                              
      192 -  @override                                                   
      193 -  Widget build(BuildContext context) {                        
      194 -    final colors = context.financialColors;                   
      195 -    return ListTile(                                          
      196 -      contentPadding: EdgeInsets.zero,                        
      197 -      title: Text(_scopeLabel(l10n)),                         
      198 -      subtitle: Text(l10n.reportTransactionCount(transactionCo
          -unt)),                                                        
      199 -      trailing: ReportAmountText(                             
      200 -        minorUnits: totalMinorUnits,                          
      201 -        currencyCode: currencyCode,                           
      202 -        color: colors.expense,                                
      203 -      ),                                                      
      204 -    );                                                        
      205 -  }                                                           
      206 -}                                                             

  Read 1 file (ctrl+o to expand)

⏺ Write(lib/features/reports/presentation/report_transaction_list_screen.dart)
  ⎿  Added 60 lines, removed 84 lines
       5  import 'package:family_money_manager/core/financial/ledger_enum
          s.dart';
       6  import 'package:family_money_manager/core/localization/app_loca
          lizations.dart';
       7  import 'package:family_money_manager/core/localization/enum_lab
          el_helpers.dart';
       8 -import 'package:family_money_manager/core/presentation/theme/ap
         -p_theme_extensions.dart';                                      
       8 +import 'package:family_money_manager/core/presentation/componen
         +ts/components.dart';                                           
       9  import 'package:family_money_manager/features/reports/domain/re
          port_models.dart';
      10  import 'package:family_money_manager/features/reports/presentat
          ion/providers/report_providers.dart';
      11 -import 'package:family_money_manager/features/reports/presentat
         -ion/report_widgets.dart';                                      
      11 +import 'package:family_money_manager/features/reports/presentat
         +ion/report_period_selector.dart';                              
      12  import 'package:family_money_manager/features/transactions/pres
          entation/category_label_helper.dart';
      13  import 'package:flutter/material.dart';
      14  import 'package:flutter_riverpod/flutter_riverpod.dart';
     ...
      26      final req = ref.watch(reportRequestProvider);
      27      final reportAsync = ref.watch(reportTransactionsProvider(re
          q));
      28  
      29 -    return Scaffold(                                           
      30 -      appBar: AppBar(                                          
      31 -        title: Text(l10n.reportDrillDown),                     
      32 -        actions: [                                             
      33 -          IconButton(                                          
      34 -            icon: const Icon(Icons.refresh),                   
      35 -            tooltip: l10n.reportRefresh,                       
      36 -            onPressed: () => ref.invalidate(reportTransactionsP
         -rovider(req)),                                                 
      37 -          ),                                                   
      38 -        ],                                                     
      39 -      ),                                                       
      29 +    void retry() => ref.invalidate(reportTransactionsProvider(r
         +eq));                                                          
      30 +                                                               
      31 +    return AppScreenScaffold(                                  
      32 +      title: Text(l10n.reportDrillDown),                       
      33 +      actions: [                                               
      34 +        IconButton(                                            
      35 +          icon: const Icon(Icons.refresh),                     
      36 +          tooltip: l10n.reportRefresh,                         
      37 +          onPressed: retry,                                    
      38 +        ),                                                     
      39 +      ],                                                       
      40        body: Column(
      41          children: [
      42            const ReportPeriodSelector(),
      43            const Divider(height: 1),
      44            Expanded(
      45              child: reportAsync.when(
      46 -              loading: () => const ReportLoading(),            
      47 -              error: (_, _) => ReportErrorState(               
      48 -                onRetry: () => ref.invalidate(reportTransaction
         -sProvider(req)),                                               
      46 +              loading: () => const AppSkeletonList(),          
      47 +              error: (_, _) => AppErrorState(                  
      48 +                message: l10n.reportError,                     
      49 +                onRetry: retry,                                
      50 +                retryLabel: l10n.reportRefresh,                
      51                ),
      52                data: (result) {
      53                  if (result is! AppOk<List<ReportTransactionRow>
          >) {
      52 -                  return ReportErrorState(                     
      53 -                    onRetry: () =>                             
      54 -                        ref.invalidate(reportTransactionsProvid
         -er(req)),                                                      
      54 +                  return AppErrorState(                        
      55 +                    message: l10n.reportError,                 
      56 +                    onRetry: retry,                            
      57 +                    retryLabel: l10n.reportRefresh,            
      58                    );
      59                  }
      60                  final rows = result.value;
      58 -                if (rows.isEmpty) return const ReportEmptyState
         -();                                                            
      61 +                if (rows.isEmpty) {                            
      62 +                  return AppEmptyState(title: l10n.reportEmpty)
         +;                                                              
      63 +                }                                              
      64                  return _TransactionList(rows: rows, l10n: l10n)
          ;
      65                },
      66              ),
     ...
      79  
      80    @override
      81    Widget build(BuildContext context) {
      77 -    return ListView.separated(                                 
      78 -      padding: const EdgeInsets.symmetric(vertical: 4),        
      79 -      itemCount: rows.length,                                  
      80 -      separatorBuilder: (_, _) => const Divider(height: 1),    
      81 -      itemBuilder: (context, index) {                          
      82 -        return _TransactionRow(row: rows[index], l10n: l10n);  
      83 -      },                                                       
      82 +    return ResponsiveContentContainer(                         
      83 +      child: ListView.builder(                                 
      84 +        itemCount: rows.length,                                
      85 +        itemBuilder: (context, index) =>                       
      86 +            _TransactionRow(row: rows[index], l10n: l10n),     
      87 +      ),                                                       
      88      );
      89    }
      90  }
     ...
       95    final ReportTransactionRow row;
       96    final AppLocalizations l10n;
       97  
       94 -  IconData _icon() => switch (row.operationType) {            
       95 -    OperationType.income => Icons.arrow_downward,             
       96 -    OperationType.expense ||                                  
       97 -    OperationType.childFundWithdrawal => Icons.arrow_upward,  
       98 -    OperationType.transfer => Icons.swap_horiz,               
       99 -    OperationType.reversal => Icons.undo,                     
      100 -    OperationType.openingBalance => Icons.flag_outlined,      
      101 -    _ => Icons.receipt_outlined,                              
      102 -  };                                                          
      103 -                                                              
      104 -  Color _color(AppFinancialColors colors) => switch (row.opera
          -tionType) {                                                   
      105 -    OperationType.income => colors.income,                    
      106 -    OperationType.expense ||                                  
      107 -    OperationType.childFundWithdrawal => colors.expense,      
      108 -    OperationType.transfer => colors.transfer,                
      109 -    // A reversal is a correction, not a threshold — grey ink 
          -plus the undo                                                 
      110 -    // glyph, never the warning role, which belongs on notices
          -.                                                             
      111 -    OperationType.reversal => colors.secondaryText,           
      112 -    _ => colors.secondaryText,                                
      113 -  };                                                          
      114 -                                                              
       98 +  /// The same tile the transaction list uses.                
       99 +  ///                                                         
      100 +  /// Arriving at a transaction from a report used to show a d
          +ifferent row                                                  
      101 +  /// than arriving at it from the list — different geometry, 
          +different                                                     
      102 +  /// grammar, a raw amount string. One row model means the dr
          +ill-down reads                                                
      103 +  /// like what it drills into.                               
      104    @override
      105    Widget build(BuildContext context) {
      117 -    final color = _color(context.financialColors);            
      118 -    return Semantics(                                         
      119 -      label:                                                  
      120 -          '${operationTypeLabel(l10n, row.operationType)} ${Re
          -portAmountText.formatMinorUnits(row.amountMinorUnits, row.curr
          -encyCode)} ${row.effectiveDate}',                             
      121 -      button: true,                                           
      122 -      child: ListTile(                                        
      123 -        leading: CircleAvatar(                                
      124 -          backgroundColor: color.withAlpha(30),               
      125 -          child: Icon(_icon(), color: color, size: 18),       
      126 -        ),                                                    
      127 -        title: Text(row.accountName),                         
      128 -        subtitle: Column(                                     
      129 -          crossAxisAlignment: CrossAxisAlignment.start,       
      130 -          children: [                                         
      131 -            Text(row.effectiveDate),                          
      132 -            if (row.categoryCode != null)                     
      133 -              Text(                                           
      134 -                categoryLabelFromCode(l10n, row.categoryCode!)
          -,                                                             
      135 -                style: Theme.of(context).textTheme.bodySmall, 
      136 -              ),                                              
      137 -            if (row.isReversed)                               
      138 -              Text(                                           
      139 -                l10n.reportReversalEffect,                    
      140 -                style: Theme.of(                              
      141 -                  context,                                    
      142 -                ).textTheme.labelSmall?.copyWith(color: color)
          -,                                                             
      143 -              ),                                              
      144 -          ],                                                  
      145 -        ),                                                    
      146 -        trailing: ReportAmountText(                           
      147 -          minorUnits: row.amountMinorUnits,                   
      148 -          currencyCode: row.currencyCode,                     
      149 -          color: color,                                       
      150 -        ),                                                    
      151 -        onTap: () => context.push('/transactions/${row.operati
          -onId}'),                                                      
      152 -      ),                                                      
      106 +    final typeKind = switch (row.operationType) {             
      107 +      OperationType.income => FinancialTypeKind.income,       
      108 +      OperationType.expense ||                                
      109 +      OperationType.childFundWithdrawal => FinancialTypeKind.e
          +xpense,                                                       
      110 +      OperationType.transfer => FinancialTypeKind.transfer,   
      111 +      OperationType.reversal => FinancialTypeKind.reversal,   
      112 +      OperationType.adjustment => FinancialTypeKind.adjustment
          +,                                                             
      113 +      _ => FinancialTypeKind.other,                           
      114 +    };                                                        
      115 +                                                              
      116 +    return TransactionListTile(                               
      117 +      typeLabel: operationTypeLabel(l10n, row.operationType), 
      118 +      typeKind: typeKind,                                     
      119 +      primaryDescription: row.categoryCode == null            
      120 +          ? operationTypeLabel(l10n, row.operationType)       
      121 +          : categoryLabelFromCode(l10n, row.categoryCode!),   
      122 +      accountOrDirection: row.accountName,                    
      123 +      effectiveDate: row.effectiveDate,                       
      124 +      minorUnits: row.amountMinorUnits,                       
      125 +      currencyCode: row.currencyCode,                         
      126 +      isReversed: row.isReversed,                             
      127 +      reversedLabel: row.isReversed ? l10n.transactionReversed
          + : null,                                                      
      128 +      onTap: () => context.push('/transactions/${row.operation
          +Id}'),                                                        
      129      );
      130    }
      131  }

  Searched for 2 patterns, ran 2 shell commands (ctrl+o to expand)

⏺ lib/ is clean. Now the characterization test that pinned the old formatter has
  to be updated — it exists precisely to make this change loud:

  Searched for 2 patterns, ran 11 shell commands (ctrl+o to expand)

⏺ Budget detail is green; the remaining budget failure is the pre-existing one.
  Full suite:

  Ran 1 shell command (ctrl+o to expand)

⏺ +1872 −2 — back to the two pre-existing failures.

  Implemented

  Phase 9 opened by deleting report_widgets.dart (352 lines). It held a second,
  weaker copy of components the design system already owned — amount text,
  amount rows, currency headers, loading/error/empty states, info notes — and
  every copy had drifted. Only the period selector was genuinely
  report-specific; it moved to its own file.

  Defect #14 is closed. ReportAmountText.formatMinorUnits was behind every
  report, budget and drill-down amount, and broke four rules at once: currency
  code leading the number, an ASCII hyphen inside the numeric run (which RTL
  bidi moved to the wrong side), no thousands grouping, and a silent scale-2
  fallback for unknown codes. All ten call-site files now go through
  FinancialAmountText / CurrencyAmountRow / AmountDisplayFormatter.

  Two real rendering bugs surfaced while migrating, both from the old API's
  color: parameter letting call sites paint whatever they liked:

  - Net cash flow was tinted green or red by its own sign — a colour verdict on
  a derived figure, which the design forbids. It's weight now; the sign and
  glyph already say which way it went.
  - On the spouse-wallet report, funding was tinted as income. Funding a wallet
  moves money between the household's own accounts; tinting it as income
  obscured the one line on that screen that is real spending.

  Defect #7 is closed. The protected-funds audit printed beneficiaryMemberId raw
  — a UUID where a child's name belongs. Both the beneficiary and the person
  who recorded the withdrawal are now joined to their names; created_by was
  already stored and simply never surfaced. An audit row now reads "for Yousuf ·
  by Ahmed · 2026-07-24".

  report_flow_row.dart centralises the one thing the reports kept getting subtly
  wrong: some stored figures are signed and some aren't, while
  FinancialAmountText takes a magnitude and derives the sign from direction.
  Passing a pre-negated value rendered a double negative.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 346 files
  - flutter test — +1872 −2

  The phase-0 characterization test did its job: it was written to fail loudly
  at exactly this change. Rewritten from before-picture to after-picture — each
  assertion that pinned a defect is now inverted, and it documents which
  formatter owns which job so a future "simplification" has to argue with a
  test. One budget test that pinned 'EGP 400.00' updated to '400.00' /
  '1,000.00'.

  6 ARB keys added (transfer in/out, spouse wallet funded/returned, two audit
  captions); both locales symmetric.

  Notes

  - Still open in phase 9: defect #20 — ReportFilter is still only ever const 
  ReportFilter(), so the drill-down screen exists but nothing navigates to it
  with a dimension set. Report rows need to become tappable, which means
  CurrencyAmountRow gaining an onTap or being wrapped. That's the next piece.
  Also untouched: defect #3 (reconciles defined, zero call sites) and the charts
  from doc 13–15.
  - The budget screens got the minimum honest fix — string composition moved to
  AmountDisplayFormatter — rather than a full redesign; budgets are their own
  chunk.
  - Carried over: budgets/goals/certificates detail routes aren't root pushes;
  dashboard query doesn't read reversal_reason; and your two open decisions.

✻ Churned for 17m 41s

❯ go ahead                                                                      
  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)

⏺ Now defect #20 — the drill-down that's unreachable. First, making a money row
  genuinely tappable:

  Ran 3 shell commands (ctrl+o to expand)

⏺ Now the drill-down action on the request notifier, and wiring the report rows:

  Ran 2 shell commands (ctrl+o to expand)

⏺ Now wire the rows to actually drill down:

  Ran 3 shell commands (ctrl+o to expand)

⏺ Now replace the ad-hoc InkWell in the transaction detail chain with the
  component's own onTap:

  Ran 1 shell command (ctrl+o to expand)

⏺ Now tests for the drill-down:

⏺ Write(test/widget/features/reports/report_drill_down_test.dart)
  ⎿  Wrote 222 lines to
     test/widget/features/reports/report_drill_down_test.dart
       1 /// The report drill-down.
       3 /// `ReportFilter` supported every dimension from the start and 
         no screen ever
         ach it. These
       5 /// tests pin the wiring: a breakdown figure is a claim about a 
       6 /// transactions, tapping it filters to that set, and the period
          it was
       8 library;
       9 
         .dart';
     … +242 lines (ctrl+o to expand)

  Ran 3 shell commands (ctrl+o to expand)
  ⎿  Found 2 new diagnostic issues in 1 file (ctrl+o to expand)

❯ continue                                                                      
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

  Ran 2 shell commands (ctrl+o to expand)

⏺ +1877 −2 — the same two pre-existing failures.

  Implemented

  Defect #20 is closed. ReportFilter supported eight dimensions from day one and
  no screen ever set one, so the drill-down list existed but nothing could
  reach it.

  - CurrencyAmountRow gained an onTap. When set, the row takes a chevron, a
  tonal press (not a ripple) and button semantics — a row that is tappable and
  doesn't look it is worse than one that isn't tappable at all. The chevron
  flips by Directionality rather than trusting the icon font, since Flutter's
  chevrons don't mirror on their own and a chevron pointing the wrong way in
  Arabic reads as "back".
  - ReportRequestNotifier.drillDown(...) narrows to one dimension and carries
  the period over. It replaces the whole filter rather than adding to it — two
  dimensions chained by accident would produce a list matching neither figure
  the user tapped. clearFilter() is the way back.
  - Category, spender, beneficiary and scope rows are now wired. The drill-down
  screen states that it's showing a subset and offers "show all" — the
  difference between "these are my transactions" and "these are some of them".

  This also let me remove the ad-hoc InkWell I'd wrapped around the
  reversal-chain row two turns ago; that screen now uses the component's own
  onTap and gets the chevron and press treatment for free.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 347 files
  - flutter test — +1877 −2

  5 new widget tests: each dimension drills to itself and nothing else, the
  period survives, and a tappable row announces itself (chevron + isButton). 2
  ARB keys; locales symmetric.

  Notes

  - Account-flow drill-down not wired: on that screen the account is a section
  header, not a breakdown row, so there's no figure to tap. It needs a
  header-level affordance, which is a different shape from the row work —
  flagged rather than bolted on.
  - Still open in phase 9: defect #3 (AccountFlowBreakdown.reconciles is defined
  with zero call sites — the reconciliation invariant is computed and never
  checked), and the charts from docs 13–15 (BarSeries / LineSeries / ShareBar
  don't exist).
  - Carried over, unchanged: budgets/goals/certificates detail routes aren't
  root pushes; the dashboard query doesn't read reversal_reason; the transaction
  filter sheet has no category/account/member pickers and no currency selector.
  - Your two decisions are still open — certificate-principal double
  classification, and spouse-wallet exclusion from the headline balance. Phase 9
  has now put the spouse wallet on screen in two reports, so the second one is
  getting more visible, not less.

✻ Cogitated for 19m 53s

❯ go ahead                                                                      

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)

⏺ Correcting the handoff's framing: reconciles isn't unused — it's tested but
  never shown. A user reading a flow table that doesn't add up gets no signal:

  Ran 1 shell command (ctrl+o to expand)

⏺ Write(test/widget/features/reports/account_flow_reconciliation_test.dart)
  ⎿  Wrote 145 lines to
     test/widget/features/reports/account_flow_reconciliation_test.dart
       1 /// The account-flow report tells you when its own figures do no
       2 ///
       3 /// `AccountFlowBreakdown.reconciles` has always been able to ch
       4 /// accounting identity, and until now nothing above the domain 
       5 /// it. A period breakdown whose lines do not sum to its own clo
         sing balance
       7 library;
       8 
         .dart';
         dart';
     … +159 lines (ctrl+o to expand)

  Ran 2 shell commands (ctrl+o to expand)

⏺ +1881 −2.

  Implemented

  Defect #3 — but the handoff's framing was wrong, and worth correcting:
  AccountFlowBreakdown.reconciles is not unused. It's asserted in
  report_account_flow_db_test.dart:286. The real gap was that nothing above the 
  domain layer ever asked it, so a period breakdown whose lines don't sum to its
  own closing balance would be shown in silence.

  The account-flow report now checks the identity and says so when it fails.
  Three deliberate choices in how:

  - Warning tone, not error. Nothing in the ledger is broken and there's nothing
  to retry; the error role belongs to failures the user caused.
  - The copy separates what's suspect from what isn't. Balances are derived from
  the ledger and stay correct — only the period attribution is in doubt. Saying
  just "these don't add up" would call the balances into question too.
  - The figures stay on screen. Hiding them would leave the user warned about
  something they can't see.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 348 files
  - flutter test — +1881 −2, still only the two pre-existing failures

  4 new tests, including one that pins the identity itself so the check can't
  quietly become a no-op. 2 ARB keys; locales symmetric.

  Where things stand

  Phase 9's defect work is done: #14 (the report formatter), #7 (UUIDs in the
  protected-funds audit), #20 (unreachable drill-down), #3 (unsurfaced
  reconciliation). Phases 0–8 complete; phase 9 complete except the charts.

  Remaining, in the order I'd take them:

  1. Charts (docs 13–15) — BarSeries, LineSeries, ShareBar don't exist. The
  largest single remaining piece of the handoff.
  2. Navigation phase — budgets/goals/certificates detail routes as root pushes,
  with the shell/back tests rewritten together.
  3. Transaction filter polish — category/account/member pickers and a currency
  selector for the amount band.
  4. Budget and goal screens — they got the minimum honest fix during the
  formatter migration, not a redesign.

  Two decisions of yours are still outstanding and I've now flagged them across
  five turns: the certificate-principal double classification between
  protectedBalances and heldByReason, and the spouse-wallet exclusion from the
  headline balance. The spouse wallet is now rendered in two reports and the
  dashboard, so the second one is getting steadily more expensive to change. I
  can keep going without them, but they're the only things blocking a coherent
  answer to "what is my money doing".

✻ Churned for 4m 0s

❯ go ahead                                                                      

  Ran 2 shell commands (ctrl+o to expand)
⏺ Skill(dataviz)
  ⎿  Successfully loaded skill

  Ran 2 shell commands (ctrl+o to expand)

⏺ Now the three primitives:

⏺ Write(lib/core/presentation/components/chart_primitives.dart)
  ⎿  Wrote 541 lines to
     lib/core/presentation/components/chart_primitives.dart
       1 /// Three chart primitives, and no more.
       3 /// All ink. A chart in this product has no palette: a bar is no
         t a colour, it
         a hatch
         hat is
       6 /// [ProgressMeter]'s rule extended to charts, and it is what ke
       7 /// of them legible in greyscale, under dichromacy, and in force
         d-colours mode
       9 ///
         compared by
     … +597 lines (ctrl+o to expand)

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)
  ⎿  Found 1 new diagnostic issue in 1 file (ctrl+o to expand)

⏺ Now tests for the primitives — the rules they exist to enforce:

⏺ Write(test/widget/presentation/chart_primitives_test.dart)
  ⎿  Wrote 251 lines to test/widget/presentation/chart_primitives_test.dart
       1 /// The three chart primitives.
       3 /// What is worth testing about a chart is not its pixels but it
         s promises:
       4 /// that it never shows a number its own labels do not carry, th
       5 /// with the language, that a bar cannot draw past its own track
         , and that a
         e are the ways
       7 /// a chart lies, and none of them is visible in a screenshot.
       8 library;
      10 import 'package:family_money_manager/app/app_theme.dart';
     … +270 lines (ctrl+o to expand)

  Ran 3 shell commands (ctrl+o to expand)

⏺ Now put them to work — the category report's table gains its chart:

  Ran 3 shell commands (ctrl+o to expand)

⏺ +1896 −2.

  Implemented

  The three chart primitives from doc 18 (AJ1): ShareBar, BarSeries, LineSeries
  — additive, since no report drew a chart before.

  They're all ink. That's the handoff's rule, not a shortcut: a bar isn't a
  colour, it's a length on a shared baseline, and colour enters only as a hatch
  carrying an exception — ProgressMeter's rule extended to charts. No pie, ever.
  Lines get points joined by a thin line, no smoothing: a curve asserts values
  between measurements, and in a ledger every value between two month-end
  snapshots is a fiction.

  On the dataviz skill — I loaded it as instructed. Its colour procedure (steps
  2–3, the CVD validator, categorical hue order) doesn't apply here: there is no
  categorical palette to validate, and monochrome is trivially CVD-safe. Its
  structural guidance did apply and I followed it: ≤24 px bar thickness, 4 px
  rounded data-end square at the baseline, 2 px round-capped lines, ≥8 px
  markers with a 2 px surface ring rather than a stroke, hairline solid
  gridlines, surface gaps between neighbours. Two of its checks are satisfied
  structurally rather than by feature — "a table view exists" and "texture
  available for the CVD/print case" are what the handoff mandates outright.

  Each primitive mirrors with the language: the bar grows from the leading edge,
  time runs leading-to-trailing.

  Three ways a chart lies, closed by construction: a share above its own whole
  is clamped rather than overdrawn (so the wrong number stays visible);
  BarSeries takes an explicit maxValue so two series can be compared instead of
  each being normalised to its own maximum; and every mark carries its own
  formatted figure.

  The category report is the first consumer — table first, then the picture of
  it.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 350 files
  - flutter test — +1896 −2, still only the two pre-existing failures

  15 new tests. They assert the promises, not the pixels — clamping, the
  zero-span and empty-series guards, both text directions, screen-reader
  phrasing (a chart reads as its figures, not as a rectangle), and one that pins
  the governing rule: the chart's bars can never outnumber or exceed the table 
  above it.

  Notes

  - ShareBar and LineSeries are built and tested but not yet placed on a screen
  — ShareBar belongs on the attribution report and LineSeries needs a
  month-over-month query that doesn't exist yet. I'd rather say that than wire a
  chart to data I'd have to invent.
  - Remaining from the handoff, roughly in order: the navigation phase
  (budgets/goals/certificates detail routes as root pushes, with shell/back
  tests rewritten together); the transaction filter's missing pickers and
  currency selector; budget and goal screens, which got the minimum honest fix
  during the formatter migration rather than a redesign; and doc 18's other
  components (date picker, category picker, tabs/segments).
  - Your two decisions are still open — certificate-principal double
  classification, and spouse-wallet exclusion from the headline balance. Nothing
  I've done depends on them, but they're the last things standing between the
  app and a coherent answer to "what is my money doing", and the spouse wallet
  now appears in three places rather than one.

✻ Brewed for 7m 26s

❯ go ahead                                                                      

  Listed 1 directory, ran 1 shell command (ctrl+o to expand)

⏺ Now the router change — the remaining detail routes as root pushes:

  Ran 2 shell commands (ctrl+o to expand)

⏺ Now a test for what root-pushing actually buys — the behaviour, not the
  wiring:

⏺ Write(test/widget/navigation/detail_routes_above_shell_test.dart)
  ⎿  Wrote 164 lines to
     test/widget/navigation/detail_routes_above_shell_test.dart
       1 /// Detail screens sit above the shell, not inside a tab.
       3 /// The behaviour this buys, and the reason it was worth a route
         r change:
         tab to More
       5 /// and discards Home's scroll position. A destination should no
       6 /// tab you are on. The observable consequence is that a detail 
         screen has no
         ally were.
       8 library;
      10 import 'dart:async';
     … +173 lines (ctrl+o to expand)

  Searched for 1 pattern, ran 2 shell commands (ctrl+o to expand)
  ⎿  Found 3 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ All three pass, including the behaviour that motivated the change. Full check:

  Ran 1 shell command (ctrl+o to expand)

⏺ +1899 −2. The navigation phase is done — this was the last thing I'd been
  carrying forward across turns.

  Implemented

  All ten detail and detail-action routes now push above the shell: transaction
  detail and reverse, account detail, budget detail, goal detail with fund and
  release, certificate detail with profit and redeem.

  The key has to be set on each route individually, including children of an
  already-root-pushed route — go_router resolves the navigator per route rather
  than inheriting from the parent. A goal's "fund" screen without it would slide
  the bottom bar back in halfway through the flow. That's documented on the key
  itself, since it's the kind of thing the next person adding a route gets
  wrong.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 351 files
  - flutter test — +1899 −2

  3 new tests, written against the behaviour rather than the wiring:

  - Every root-pushed route shows no bottom navigation — driven off a list, so a
  route added without the key fails with the path in the reason.
  - Every shell destination keeps its bottom navigation — the other half, so
  "fix" the first test by root-pushing everything and this one catches you.
  - Home → account detail → back lands on Home. That's the actual defect: an
  account lives on the More branch, so opening one from Home used to switch the
  visible tab and discard Home's scroll position.

  The two existing shell tests still pass unchanged — the page-key regression
  they guard is untouched.

  Where things stand

  Phases 0–9 complete, plus navigation. All the numbered defects from the
  handoff's list that I've been tracking are closed.

  Remaining, in the order I'd take them:

  1. Transaction filter pickers — category, account, member and scope selectors,
  plus a currency selector for the amount band. The filter and query support
  all of them; only the sheet doesn't offer them.
  2. Budget and goal screens — they got the minimum honest fix during the
  formatter migration, not the redesign docs 07 and 11 specify.
  3. Doc 18's other components — date picker, category picker, tabs/segments
  (currently still Material defaults; that's defect #18).
  4. ShareBar and LineSeries placement — built and tested, not yet on a screen.
  LineSeries needs a month-over-month query that doesn't exist.

  And your two decisions are still open. I've flagged them every turn for six
  turns now and nothing I've built depends on them, but they are genuinely the
  last product questions in the redesign: the certificate-principal double
  classification between protectedBalances and heldByReason, and whether the
  spouse wallet is excluded from the headline balance. If you'd rather I just
  pick defensible answers and note them as assumptions, say so and I will —
  otherwise I'll keep working around them.

✻ Worked for 4m 26s

❯ go ahead                                                                      

  Searched for 1 pattern, ran 1 shell command (ctrl+o to expand)
⏺ Now the pickers. Adding four dimensions and a currency selector to the filter
  sheet:

  Read 1 file, ran 2 shell commands (ctrl+o to expand)

⏺ Now the two menu pickers:

  Ran 3 shell commands (ctrl+o to expand)

⏺ Write(test/widget/features/transactions/transaction_filter_sheet_test.dart)
  ⎿  Wrote 302 lines to
     test/widget/features/transactions/transaction_filter_sheet_test.dart
       1 /// The filter sheet's pickers.
       3 /// The filter and the query supported every one of these dimens
         ions from the
         ing is the
       5 /// part that can go wrong: that each control writes the dimensi
       6 /// to, that clearing means cleared rather than "first option", 
         and that the
       8 library;
       9 
         .dart';
     … +332 lines (ctrl+o to expand)

  Ran 2 shell commands (ctrl+o to expand)

⏺ Two real bugs, both caught by the tests — a controlled-value problem and a
  crash:

  Ran 2 shell commands (ctrl+o to expand)

⏺ All 10 pass. Full check:

  Ran 1 shell command (ctrl+o to expand)

⏺ +1909 −2.

  Implemented

  The filter sheet now offers every dimension the query already supported.
  Category and scope as chips (closed sets the app defines); account and spender
  as menus (household data of unknown size and unknown name length — a chip row
  of a dozen long Arabic names is a wall, not a control). Plus a currency
  selector on the amount band.

  Two design points worth naming:

  - The category chip writes the code, not the label. The query matches on the
  stable code; a localised label would match nothing, and would match
  differently per locale.
  - Switching the band's currency re-parses the typed text at the new scale
  rather than reinterpreting the stored minor units, which would silently move
  the threshold the user set.

  Archived members stay selectable — they spent money that's still in the
  ledger, and a filter that couldn't reach it would make that history
  unsearchable.

  Two bugs the tests caught in my own picker

  Both were real, and neither was visible without writing the test:

  1. A crash. Reopening the sheet with an account filter already active, before
  the async account list arrived, tripped DropdownButton's "exactly one matching
  item" assertion. Now the value is only passed when the list can actually show
  it.
  2. An uncontrolled control. I'd used DropdownButtonFormField's initialValue,
  which is read once on first build — so "clear all" would clear the draft while
  the menu kept displaying the old selection. Both pickers are now fully
  controlled by value, with the draft as the single source of truth.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 352 files
  - flutter test — +1909 −2, still only the two pre-existing failures

  10 new tests: each control writes the dimension it claims to, re-tapping a
  chip clears rather than re-selects, the band always carries a currency and
  disappears entirely when both bounds are emptied (not a band with two nulls,
  which would still pin the filter to one currency), "clear all" restores
  includeReversed to the default the ledger insists on, and cancelling changes
  nothing. 7 ARB keys; locales symmetric.

  Remaining

  1. Budget and goal screens — docs 07 and 11. They got the minimum honest fix
  during the formatter migration, not the redesign.
  2. Doc 18's other components — date picker, category picker surface,
  tabs/segments. Still Material defaults; that's defect #18, the last one open.
  3. ShareBar and LineSeries placement — built and tested, unplaced. LineSeries
  needs a month-over-month query that doesn't exist.

  I'll stop re-listing your two open product decisions each turn — they're
  noted, nothing I'm building depends on them, and I'll raise them again only
  when something actually blocks on them.

✻ Sautéed for 8m 57s

❯ go ahead                                                                      

  Searched for 1 pattern, ran 3 shell commands (ctrl+o to expand)

⏺ Write(lib/core/presentation/components/app_date_picker.dart)
  ⎿  Wrote 202 lines to
     lib/core/presentation/components/app_date_picker.dart
       1 /// The date sheet.
       3 /// A sheet from the bottom, like every other choice in this app
         , rather than
       5 ///
         three
       7 /// shortcuts: almost every date this app asks for is today, yes
       8 /// start of the month, and the calendar grid is the fallback ra
         ther than the
         abled or
         ppen in the
     … +232 lines (ctrl+o to expand)

  Ran 1 shell command (ctrl+o to expand)

⏺ Now migrate the seven showDatePicker call sites:

  Searched for 1 pattern, ran 2 shell commands (ctrl+o to expand)

⏺ All seven migrated. Now tests, including the defect that motivated this:

⏺ Write(test/widget/presentation/app_date_picker_test.dart)
  ⎿  Wrote 210 lines to test/widget/presentation/app_date_picker_test.dart
       1 /// The date sheet.
       3 /// The rule under test is the one the stock picker could not ex
         press: bounds
         vent its own
       5 /// pair, and one of them let an expense be recorded a year in t
       6 library;
       7 
       9 import 'package:family_money_manager/core/localization/app_local
         izations.dart';
         s/components.dart';
     … +224 lines (ctrl+o to expand)

  Ran 4 shell commands (ctrl+o to expand)
  ⎿  Found 23 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ +1919 −2.

  Implemented

  showAppDatePicker — a bottom sheet like every other choice in the app,
  replacing all seven showDatePicker calls. No stock date dialog remains in
  lib/.

  The design point that mattered: callers state what the date is for, not what
  its bounds are. DatePurpose.ledgerEntry versus DatePurpose.futureTarget. Every
  call site previously invented its own pair — DateTime(2000)/DateTime(2100),
  DateTime(2020)/DateTime(2050), now + 365 days — and the expense, income and
  transfer forms all let you record a transaction up to a year in the future. A
  ledger records what happened; that's now unrepresentable rather than merely
  discouraged.

  Two smaller things worth noting:

  - The sheet explains why the greyed days are grey. An explained constraint is
  a rule; an unexplained one is a bug the user works around.
  - A stored date outside its own bounds is clamped rather than asserted on —
  data written before the bound existed opens on a valid day instead of
  crashing.

  The three shortcuts (today, yesterday, start of month) come before the grid,
  because they answer the question most of the time. A shortcut outside the
  caller's bounds is dropped rather than offered and refused.

  What I did not do

  Month and weekday names still come from Flutter's own bundle via
  CalendarDatePicker, not the ARB. That's the one part of doc 18's AJ2 spec not
  met — it objects on provenance grounds, since every other string in the
  project comes from the ARB. Meeting it means hand-building the calendar grid,
  which is a larger piece than the fix that was actually load-bearing. It's
  marked in the source at the point it applies.

  Validation

  - flutter analyze — No issues found
  - dart format --set-exit-if-changed lib test — clean, 354 files
  - flutter test — +1919 −2, still the two pre-existing failures

  10 new tests: the grid stops at today for a ledger entry and runs past it for
  a target, the warning appears only where there's something to warn about, a
  stored future date clamps instead of asserting, a caller's own floor is
  honoured, out-of-bounds shortcuts are dropped, and dismiss/confirm return what
  they should.

  Remaining

  - Doc 18's other components — category picker surface, tabs/segments, and the
  6 AlertDialog sites. That's the rest of defect #18.
  - Budget and goal screens (docs 07, 11) — still the minimum fix, not the
  redesign.
  - ShareBar / LineSeries placement — LineSeries needs a month-over-month query
  that doesn't exist.
  - The two showDateRangePicker sites (dashboard, report period selector) still
  use the Material range dialog. A range sheet is a different component from a
  single-date one; I'd rather build it deliberately than stretch this one.

✻ Crunched for 9m 34s

※ recap: You're implementing the Figma-style design handoff into the Flutter app; phases 0–9 plus navigation are done, and I just replaced all seven date pickers with a purpose-bounded sheet. Suite is +1919 −2 (both pre-existing). Next: doc 18's category picker and tabs. (disable recaps in /config)