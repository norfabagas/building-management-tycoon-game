import 'package:building_management_tycoon/data/game_repository.dart';
import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/domain/local_profile.dart';
import 'package:building_management_tycoon/features/district/district_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

LocalProfile profile(int slot) => LocalProfile(
  slot: slot,
  areaName: 'District $slot',
  createdAt: DateTime(2020),
);

void main() {
  test('legacy slots initialize once and transactions serialize simultaneous reservations', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final initial = await repository.update(profile(1), 1000);
    expect(
      initial.watermark,
      1000,
    ); // Old profile creation is not offline game time.
    final outcomes = await Future.wait([
      repository.update(
        profile(1),
        1000,
        (s) => DistrictSimulation.place(s, const Footprint(0, 0, 2, 4)),
      ),
      repository.update(
        profile(1),
        1000,
        (s) => DistrictSimulation.place(s, const Footprint(3, 0, 2, 4)),
      ),
    ]);
    expect(outcomes.last.buildings.length, 2);
    final reloaded = await repository.update(profile(1), 1000);
    expect(reloaded.reserved, 4000000);
    expect(reloaded.available, 0);
    final second = await repository.update(profile(2), 1000);
    expect(second.balance, 4000000);
    expect(second.buildings, isEmpty);
    final paid = await repository.update(profile(1), 241000);
    expect(paid.balance, 0);
    expect((await repository.update(profile(1), 241000)).balance, 0);
    await database.close();
  });

  test('failed transaction preserves wallet/ledger; view model publishes no successful mutation', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final model = DistrictViewModel(
      profile(1),
      repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(0),
    );
    await model.save();
    final before = model.game!.toJson();
    expect(
      await model.save((s) {
        DistrictSimulation.place(s, const Footprint(0, 0, 2, 4));
        throw StateError('storage transaction failed');
      }),
      isFalse,
    );
    expect(model.game!.toJson(), before);
    expect((await repository.update(profile(1), 0)).toJson(), before);
    expect(model.error, isNotNull);
    expect(
      await model.save(
        (s) => DistrictSimulation.place(s, const Footprint(0, 0, 2, 4)),
      ),
      isTrue,
    );
    expect(model.game!.buildings.length, 1);
    model.dispose();
    await database.close();
  });

  test('unsupported/corrupt game saves are preserved and cannot become a new wallet', () async {
    final database = await openNewInMemoryDatabase();
    final repository = GameRepository(open: () async => database);
    final bad = {'version': 99, 'balance': 9};
    await GameRepository.store.record('1').put(database, bad);
    await expectLater(repository.update(profile(1), 0), throwsFormatException);
    expect(await GameRepository.store.record('1').get(database), bad);
    await database.close();
  });
}
