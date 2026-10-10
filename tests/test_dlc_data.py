"""Portable importer fixtures and checks on committed DLC release data."""
import copy
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'reframework/data/raze_MapMarkersAndCollectables'
sys.path.insert(0, str(ROOT / 'scripts'))
from dlc_data import import_audits, validate_dlc_availability

COUNTS = {755: 119, 757: 47, 758: 10, 795: 9, 826: 267, 885: 122, 894: 140}
RITUAL_TYPES = (755, 757, 758, 795)
BASE_TYPES = (10, 11, 12, 13, 161, 167, 465, 495, 653, 692, 693, 694)


def fixture_guid(kind, index):
    return str(uuid.UUID(int=kind * 1000 + index + 1))


def write_synthetic_audits(directory):
    """Use the documented record shapes without depending on ignored game extracts."""
    common = {'source_archive': 're_dlc_stm_2593290.pak',
              'source_manifest_sha256': 'a' * 64, 'parser_result_sha256': 'b' * 64}
    collectibles, ritual = dict(common, groups={}), dict(common, groups={})
    for kind, count in COUNTS.items():
        rows = {}
        for index in range(count):
            position = {'x': float(index), 'y': float(kind), 'z': -float(index)}
            if kind in RITUAL_TYPES:
                catalog = [] if kind == 755 and index < 3 else [{
                    'catalog': f'natives/stm/appdata/generate/manualset/content/rdl_{kind}/table.user.3',
                    'kind': 'normal', 'list': '_NormalTableList'}]
                row = {'position': position, 'source_variants': [{
                    'source_path': f'natives/stm/appdata/generate/manualset/content/rdl_{kind}/chest.user.3',
                    'parameter_id': index, 'table_layer': 2 if not catalog else 0,
                    'catalog_references': catalog}],
                    'availability': {'catalog_world': 'normal',
                                     'trial_activation': 'unverified', 'renewal': 'unverified'}}
            else:
                variables = [{'_QuestID': 40010, '_NameHash': 1963397663,
                              '_ValueType': 2, '_CompareType': 1, '_BoolValue': True,
                              '_IntValue': -1}] if kind == 885 and index < 6 else []
                row = {'position': position,
                       'source_path': f'natives/stm/appdata/generate/manualset/nrdfield/{kind}.user.3',
                       'parameter_id': index,
                       'availability': {'catalog_world': 'normal', 'quest_variables': variables}}
            rows[fixture_guid(kind, index)] = row
        target = ritual if kind in RITUAL_TYPES else collectibles
        target['groups'][str(kind)] = {'label': f'Synthetic type {kind}', 'locations': rows}
    paths = (directory / 'import-ready-collectibles.json',
             directory / 'import-ready-ritual-chests.json')
    for path, content in zip(paths, (collectibles, ritual)):
        path.write_text(json.dumps(content), encoding='utf-8')
    return paths


def shipped_data():
    datasets = {kind: json.loads((DATA / f'{kind}.json').read_text(encoding='utf-8'))
                for kind in COUNTS}
    availability = json.loads((DATA / 'dlc-availability.json').read_text(encoding='utf-8'))
    legacy_guids = {guid for dataset in datasets.values() for guid in dataset['locations']}
    availability['records'] = {guid: record for guid, record in availability['records'].items() if guid in legacy_guids}
    return datasets, availability


class DlcDataTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dd2-dlc-data-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / 'data'
        self.data.mkdir()
        self.manifest = self.root / 'dataset-manifest.json'
        shutil.copy2(ROOT / 'scripts/dataset-manifest.json', self.manifest)
        for kind in BASE_TYPES:
            shutil.copy2(DATA / f'{kind}.json', self.data / f'{kind}.json')
        self.audits = write_synthetic_audits(self.root)

    def test_import_is_idempotent_and_preserves_base_data(self):
        base_before = {kind: (self.data / f'{kind}.json').read_bytes() for kind in BASE_TYPES}
        import_audits(*self.audits, self.data, self.manifest)
        datasets = {kind: json.loads((self.data / f'{kind}.json').read_text()) for kind in COUNTS}
        availability = json.loads((self.data / 'dlc-availability.json').read_text())
        self.assertEqual({kind: len(data['locations']) for kind, data in datasets.items()}, COUNTS)
        self.assertEqual(datasets[885]['locations'][fixture_guid(885, 0)],
                         {'x': 0.0, 'y': 885.0, 'z': -0.0})
        self.assertEqual(len(availability['records']), 714)
        self.assertEqual(availability['source']['game_version'], '4.0.0.0')
        self.assertEqual(availability['source']['date'], '2026-10-09')
        before = {p.name: p.read_bytes() for p in self.data.iterdir()}
        before['dataset-manifest.json'] = self.manifest.read_bytes()
        import_audits(*self.audits, self.data, self.manifest)
        after = {p.name: p.read_bytes() for p in self.data.iterdir()}
        after['dataset-manifest.json'] = self.manifest.read_bytes()
        self.assertEqual(after, before)
        self.assertEqual(base_before, {kind: (self.data / f'{kind}.json').read_bytes()
                                       for kind in BASE_TYPES})

    def test_shipped_locations_and_unknown_gates_are_conservative(self):
        datasets, availability = shipped_data()
        by_type = {kind: data['locations'] for kind, data in datasets.items()}
        self.assertEqual({kind: len(locations) for kind, locations in by_type.items()}, COUNTS)
        self.assertEqual(len(availability['records']), 714)
        validate_dlc_availability(availability, by_type)
        records = availability['records']
        rare = [records[guid] for guid in by_type[885] if any(
            variant.get('unsupported') for variant in records[guid]['variants'])]
        self.assertEqual(len(rare), 6)
        ritual = [records[guid] for kind in RITUAL_TYPES for guid in by_type[kind]]
        self.assertEqual(len(ritual), 185)
        self.assertEqual(sum(not record['variants'] for record in ritual), 3)
        self.assertTrue(all(record.get('unresolved') or all(
            variant.get('unsupported') for variant in record['variants']) for record in ritual))
        for kind in (826, 894):
            self.assertTrue(all(records[guid]['variants'] == [{'world': 'normal', 'quests': []}]
                                for guid in by_type[kind]))

    def test_legacy_import_rejects_extended_payload_before_writing(self):
        for path in DATA.glob('*.json'):
            shutil.copy2(path, self.data / path.name)
        before = {p.name: p.read_bytes() for p in self.data.iterdir()}
        before['dataset-manifest.json'] = self.manifest.read_bytes()
        with self.assertRaisesRegex(AssertionError, 'coverage extension'):
            import_audits(*self.audits, self.data, self.manifest)
        after = {p.name: p.read_bytes() for p in self.data.iterdir()}
        after['dataset-manifest.json'] = self.manifest.read_bytes()
        self.assertEqual(after, before, 'Legacy import modified extended coverage before rejecting it')

    def test_validator_rejects_missing_coverage_wrong_type_and_lost_gate(self):
        datasets, availability = shipped_data()
        by_type = {kind: data['locations'] for kind, data in datasets.items()}
        rare_guid = next(guid for guid in by_type[885]
                         if availability['records'][guid]['variants'][0].get('unsupported'))
        for corruption in ('missing', 'wrong_type', 'lost_gate', 'unguarded_ritual'):
            with self.subTest(corruption=corruption):
                bad = copy.deepcopy(availability)
                if corruption == 'missing':
                    bad['records'].pop(rare_guid)
                elif corruption == 'wrong_type':
                    bad['records'][rare_guid]['gimmick_id'] = 826
                elif corruption == 'lost_gate':
                    bad['records'][rare_guid]['variants'][0].pop('unsupported')
                else:
                    ritual_guid = next(iter(by_type[755]))
                    bad['records'][ritual_guid]['variants'] = [{'world': 'normal', 'quests': []}]
                with self.assertRaises((AssertionError, ValueError)):
                    validate_dlc_availability(bad, by_type)


if __name__ == '__main__':
    unittest.main()
