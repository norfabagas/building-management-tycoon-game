import 'dart:math' as math;

import 'package:building_management_tycoon/domain/district_game.dart';
import 'package:building_management_tycoon/features/district/district_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('3D people and vehicles retain volume throughout a full turn', () {
    for (var i = 0; i < 72; i++) {
      final heading = i * math.pi / 36;
      for (final zoom in [.5, 1.0, 2.0]) {
        final tile = 80 * zoom;
        final figures = [
          CityFigure.car(heading),
          for (final type in BuildingType.values)
            CityFigure.walker(type, heading, i / 5),
        ];
        for (final model in figures) {
          final bounds = model.bounds(tile);
          expect(bounds.width, greaterThan(tile * .12));
          expect(bounds.height, greaterThan(tile * .15));
          final vertices = model.faces.expand((f) => f.vertices).toList();
          expect(
            vertices.map((v) => v.x).reduce(math.max) -
                vertices.map((v) => v.x).reduce(math.min),
            greaterThan(.1),
          );
          expect(
            vertices.map((v) => v.y).reduce(math.max) -
                vertices.map((v) => v.y).reduce(math.min),
            greaterThan(.1),
          );
          expect(
            vertices.map((v) => v.z).reduce(math.max) -
                vertices.map((v) => v.z).reduce(math.min),
            greaterThan(.1),
          );
          for (final face in model.faces) {
            expect(face.normal.dot(face.normal), closeTo(1, .000001));
            expect(face.depth.isFinite, isTrue);
          }
        }
      }
    }
  });
  test('articulated walking changes pose and wraps without scaling the body', () {
    final start = CityFigure.walker(BuildingType.apartment, .7, 0);
    final step = CityFigure.walker(BuildingType.apartment, .7, math.pi / 2);
    final end = CityFigure.walker(BuildingType.apartment, .7, math.pi * 2);
    List<CityVertex> points(CityFigure model) =>
        model.faces.expand((f) => f.vertices).toList();
    // Faces can reorder in depth as limbs swing: compare the XYZ point sets.
    String signature(CityFigure model) =>
        (points(model)
                .map(
                  (p) =>
                      '${p.x.toStringAsFixed(4)},${p.y.toStringAsFixed(4)},${p.z.toStringAsFixed(4)}',
                )
                .toList()
              ..sort())
            .join(';');
    expect(signature(step), isNot(signature(start)));
    // Avoid signed zero when measuring a periodic return.
    final a = start.bounds(80), b = end.bounds(80);
    expect((a.topLeft - b.topLeft).distance, lessThan(.000001));
    expect((a.bottomRight - b.bottomRight).distance, lessThan(.000001));
  });
  for (final type in BuildingType.values) {
    for (final site in [
      const Footprint(0, 0, 2, 2),
      const Footprint(0, 0, 2, 8),
      const Footprint(0, 0, 8, 2),
    ]) {
      test(
        '${type.name} ${site.width}x${site.length} raises roof only for completed above-ground upgrades',
        () {
          final building = ApartmentBuilding(
            id: 1,
            footprint: site,
            type: type,
            stage: ConstructionStage.ready,
          );
          final state = DistrictGame(
            watermark: 0,
            balance: 100000000,
            nextBuildingId: 2,
            buildings: [building],
          );
          final map = MapProjection(const Size(900, 700), Offset.zero);
          Rect bounds() => map.buildingRect(
            site,
            type: type,
            floors: building.completedFloors,
          );
          final before = bounds();
          DistrictSimulation.orderUpgrade(state, 1, BuildingUpgrade.floor);
          expect(bounds(), before);
          DistrictSimulation.cancelUpgrade(state, 1);
          expect(bounds(), before);
          void finish(BuildingUpgrade kind) {
            DistrictSimulation.orderUpgrade(state, 1, kind);
            for (var i = 0; i < 20 && building.upgrade != null; i++) {
              DistrictSimulation.advance(state, state.watermark + 24000);
            }
            expect(building.upgrade, isNull);
          }

          finish(BuildingUpgrade.floor);
          final after = bounds();
          expect(
            before.top - after.top,
            closeTo(map.storeyHeight(type: type), .0001),
          );
          expect(after.bottom, before.bottom);
          expect(after.width, before.width);
          final restored = DistrictGame.fromJson(state.toJson())
              .buildings
              .single;
          expect(
            map.buildingRect(
              site,
              type: type,
              floors: restored.completedFloors,
            ),
            after,
          );
          finish(BuildingUpgrade.basement);
          expect(bounds(), after);
          finish(BuildingUpgrade.standardLift);
          expect(bounds(), after);
          expect(building.footprint.toJson(), site.toJson());
        },
      );
    }
  }
  test(
    'upper storeys remain clickable while empty bounding-box corners do not',
    () {
      final map = MapProjection(const Size(900, 700), Offset.zero);
      const site = Footprint(0, 0, 2, 2);
      final short = map.buildingSilhouette(site);
      final tall = map.buildingSilhouette(site, floors: 10);
      final roof = map.buildingCorners(site, roof: true, floors: 10);
      final upperFace = (roof[2] + roof[1]) / 2 + const Offset(0, 5);
      expect(tall.contains(upperFace), isTrue);
      expect(short.contains(upperFace), isFalse);
      expect(
        tall.contains(tall.getBounds().topLeft + const Offset(1, 1)),
        isFalse,
      );
    },
  );
}
