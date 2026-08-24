import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/password_generator/data/password_history_store.dart';
import 'package:keyva/feature/password_generator/model/password_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 23, 12, 0, 0);

  PasswordHistoryEntry entry(String password, DateTime copiedAt) {
    return PasswordHistoryEntry(password: password, copiedAt: copiedAt);
  }

  Map<String, Object> seedPrefs(List<PasswordHistoryEntry> entries) {
    return {
      PasswordHistoryStore.historyKey: jsonEncode(
        entries.map((e) => e.toJson()).toList(),
      ),
    };
  }

  Future<PasswordHistoryStore> createStore({
    required Map<String, Object> initial,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final store = PasswordHistoryStore(clock: () => now);
    await store.init();
    return store;
  }

  test('keeps history newer than 7 days', () async {
    final store = await createStore(
      initial: seedPrefs([
        entry('hist-keep-recent', now.subtract(const Duration(days: 6))),
      ]),
    );

    expect(store.entries, hasLength(1));
    expect(store.entries.single.password, 'hist-keep-recent');
  });

  test('keeps history at the exact 7-day boundary', () async {
    final store = await createStore(
      initial: seedPrefs([
        entry('hist-keep-edge', now.subtract(const Duration(days: 7))),
      ]),
    );

    expect(store.entries, hasLength(1));
    expect(store.entries.single.password, 'hist-keep-edge');
  });

  test('removes history older than 7 days', () async {
    final store = await createStore(
      initial: seedPrefs([
        entry(
          'hist-drop-old',
          now.subtract(const Duration(days: 7, milliseconds: 1)),
        ),
        entry('hist-keep-recent', now.subtract(const Duration(days: 1))),
      ]),
    );

    expect(store.entries, hasLength(1));
    expect(store.entries.single.password, 'hist-keep-recent');
  });

  test('persists cleanup so a new store does not reload expired entries', () async {
    await createStore(
      initial: seedPrefs([
        entry(
          'hist-drop-old',
          now.subtract(const Duration(days: 7, milliseconds: 1)),
        ),
        entry('hist-keep-recent', now.subtract(const Duration(hours: 2))),
      ]),
    );

    final reloaded = PasswordHistoryStore(clock: () => now);
    await reloaded.init();

    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.single.password, 'hist-keep-recent');
  });

  test('addFromCopy purges expired entries before inserting', () async {
    final store = await createStore(
      initial: seedPrefs([
        entry(
          'hist-drop-old',
          now.subtract(const Duration(days: 8)),
        ),
      ]),
    );

    await store.addFromCopy('hist-new-copy');

    expect(store.entries, hasLength(1));
    expect(store.entries.single.password, 'hist-new-copy');
    expect(store.entries.single.copiedAt, now);
  });
}
