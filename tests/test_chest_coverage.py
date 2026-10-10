"""Release coverage checks derived from the installed game's chest scan."""
import copy
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'reframework/data/raze_MapMarkersAndCollectables'
sys.path.insert(0, str(ROOT / 'scripts'))
from dlc_data import validate_dlc_availability
from chest_coverage import import_coverage
from test_dlc_data import import_audits, write_synthetic_audits, fixture_guid


class ChestCoverageTests(unittest.TestCase):
    def test_missing_native_chest_families_are_packaged(self):
        self.assertTrue(all((DATA / f'{kind}.json').is_file() for kind in (908, 994, 1004, 1023)),
                        'Omitted native chest families')
        for kind, count in {908: 40, 994: 3, 1004: 48, 1023: 6}.items():
            with self.subTest(kind=kind):
                path = DATA / f'{kind}.json'
                self.assertTrue(path.is_file(), f'Omitted native chest family {kind}')
                self.assertEqual(len(json.loads(path.read_text())['locations']), count)
        chest = json.loads((DATA / '908.json').read_text())['locations']['00772d39-a0a7-4d3e-8bf4-258b4dd47cf6']
        self.assertEqual(chest, {'x': -3309.924072265625, 'y': 90.2938232421875, 'z': -1980.20849609375})

    def test_all_trial_locations_have_source_map_ids_and_bounds(self):
        count, areas = 0, set()
        for kind in (755, 757, 758, 795):
            dataset = json.loads((DATA / f'{kind}.json').read_text())
            self.assertEqual(set(dataset.get('map_areas', {})), set(dataset['locations']))
            for guid, pos in dataset['locations'].items():
                area = dataset['map_areas'][guid]
                areas.add(area)
                x0, z0, x1, z1 = dataset['map_bounds'][str(area)]
                self.assertTrue(x0 <= pos['x'] <= x1 and z0 <= pos['z'] <= z1)
                count += 1
        self.assertEqual(count, 185)
        self.assertEqual(areas, set(range(6001, 6013)))
        dataset = json.loads((DATA / '755.json').read_text())
        self.assertEqual(dataset['map_areas']['04a211d5-7596-4a05-94e2-e27417e6bdcd'], 6012)
        self.assertEqual(dataset['map_bounds']['6012'], [-1255, -961, -231, 63])

    def test_extended_availability_keeps_unknown_event_and_quest_gates(self):
        metadata = json.loads((DATA / 'dlc-availability.json').read_text())
        kinds = (755, 757, 758, 795, 826, 885, 894, 908, 994, 1004, 1023)
        datasets = {}
        for kind in kinds:
            path = DATA / f'{kind}.json'
            self.assertTrue(path.is_file(), f'Missing DLC payload {kind}')
            datasets[kind] = json.loads(path.read_text())['locations']
        self.assertEqual(len(metadata['records']), 811)
        validate_dlc_availability(metadata, datasets)
        for kind in (908, 994, 1004, 1023):
            guid = next(iter(datasets[kind]))
            bad = copy.deepcopy(metadata)
            bad['records'][guid]['variants'][0].pop('unsupported')
            with self.assertRaises(AssertionError, msg=f'Lost gate accepted for {kind}'):
                validate_dlc_availability(bad, datasets)


class CoverageImportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dd2-chest-coverage-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / 'data'
        self.data.mkdir()
        self.manifest = self.root / 'dataset-manifest.json'
        shutil.copy2(ROOT / 'scripts/dataset-manifest.json', self.manifest)
        import_audits(*write_synthetic_audits(self.root), self.data, self.manifest)
        audit = {'audit_date': '2026-10-10', 'comparison': 'released v1.5',
                 'unresolved_prefabs': [], 'moved_existing_chests': {}, 'missing_count': 97,
                 'archive_inventories': [{'archive': name, 'entry_table_sha256': 'c' * 64}
                     for name in ('re_chunk_000.pak', 're_dlc_stm_2593290.pak')],
                 'chest_prefabs': {}, 'missing_chests': {}}
        for kind, count in {908: 40, 994: 3, 1004: 48, 1023: 6}.items():
            audit['chest_prefabs'][str(kind)] = {'is_chest': True}
            for index in range(count):
                guid = fixture_guid(kind, index)
                audit['missing_chests'][guid] = {'guid': guid, 'gimmick_id': kind,
                    'position': [float(index), 0.0, -float(index)],
                    'path': f'natives/stm/appdata/generate/manualset/coverage/{kind}.user.3',
                    'param_id': index, 'native_label': f'Synthetic {kind}',
                    'tables': [{'_TableID': 1}],
                    'settings': {'_SetFlagSetting': {'_QuestFlagInfos': {'_Infos': []}}}}
        trials = {f'rdl_{index:02}': {'chests': []} for index in range(1, 13)}
        for kind in (755, 757, 758, 795):
            locations = json.loads((self.data / f'{kind}.json').read_bytes())['locations']
            for index, (guid, position) in enumerate(locations.items()):
                trials[f'rdl_{index % 12 + 1:02}']['chests'].append(
                    {'guid': guid, 'position': position, 'gimmick_id': kind})
        maps = {'menu': [{'UIArea': area, 'BasePosX': -200, 'BasePosZ': -200,
                         'DispRangeX': 400, 'DispRangeZ': 400} for area in range(6001, 6013)]}
        self.inputs = tuple(self.root / name for name in ('audit.json', 'trials.json', 'maps.json'))
        for path, value in zip(self.inputs, (audit, trials, maps)):
            path.write_text(json.dumps(value), encoding='utf-8')

    def snapshot(self):
        return {p.name: p.read_bytes() for p in self.data.iterdir()} | {
            'dataset-manifest.json': self.manifest.read_bytes()}

    def test_coverage_import_is_idempotent(self):
        result = import_coverage(*self.inputs, self.data, self.manifest)
        self.assertEqual(result, {'added': 97, 'trial_routes': 185, 'dlc_records': 811})
        before = self.snapshot()
        self.assertEqual(import_coverage(*self.inputs, self.data, self.manifest), result)
        self.assertEqual(self.snapshot(), before)

    def test_invalid_trial_rectangle_does_not_replace_data(self):
        maps = json.loads(self.inputs[2].read_bytes())
        maps['menu'][0]['DispRangeX'] = 1
        self.inputs[2].write_text(json.dumps(maps), encoding='utf-8')
        before = self.snapshot()
        with self.assertRaisesRegex(AssertionError, 'outside source map'):
            import_coverage(*self.inputs, self.data, self.manifest)
        self.assertEqual(self.snapshot(), before)


if __name__ == '__main__':
    unittest.main()
