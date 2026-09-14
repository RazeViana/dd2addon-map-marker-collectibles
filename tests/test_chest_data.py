"""Check additive imports and progression metadata without a game installation."""
from pathlib import Path
import importlib.util
import json
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ChestDataTests(unittest.TestCase):
    def load_importer(self):
        path = ROOT / 'scripts/update_chest_data.py'
        self.assertTrue(path.is_file(), 'additive chest-data importer is missing')
        spec = importlib.util.spec_from_file_location('update_chest_data', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_append_preserves_saved_identity_and_existing_coordinates(self):
        importer = self.load_importer()
        original = {'old': {'x': 1, 'y': 2, 'z': 3}, 'unmatched': {'x': 4, 'y': 5, 'z': 6}}
        fresh = [{'guid': 'old', 'positions': [[100, 200, 300]]},
                 {'guid': 'new', 'positions': [[7, 8, 9]]}]
        updated, added = importer.append_locations(original, fresh)
        self.assertEqual(updated, {**original, 'new': {'x': 7, 'y': 8, 'z': 9}})
        self.assertEqual(added, ['new'])
        self.assertNotIn('new', original, 'import changed its source data')

    def test_conflicting_new_positions_are_not_silently_overwritten(self):
        importer = self.load_importer()
        with self.assertRaises(ValueError):
            importer.append_locations({}, [{'guid': 'new', 'positions': [[1, 2, 3], [4, 5, 6]]}])

    def test_reconciliation_removes_absent_guids_and_corrects_only_real_position_changes(self):
        importer = self.load_importer()
        original = {'retired': {'x': 1, 'y': 2, 'z': 3},
            'moved': {'x': 4, 'y': 5, 'z': 6}, 'rounded': {'x': 7, 'y': 8, 'z': 9}}
        fresh = [{'guid': 'moved', 'positions': [[14, 15, 16]]},
            {'guid': 'rounded', 'positions': [[7.00001, 8, 9]]},
            {'guid': 'added', 'positions': [[10, 11, 12]]}]
        actual = importer.reconcile_locations(original, fresh)
        self.assertEqual(set(actual), {'moved', 'rounded', 'added'})
        self.assertEqual(actual['moved'], {'x': 14, 'y': 15, 'z': 16})
        self.assertEqual(actual['rounded'], original['rounded'])
        self.assertEqual(original['moved'], {'x': 4, 'y': 5, 'z': 6})
        with self.assertRaises(ValueError):
            importer.reconcile_locations(original, [fresh[0], fresh[0]])

    def test_build_rejects_chests_outside_verified_fresh_guid_set(self):
        importer = self.load_importer()
        sys.path.insert(0, str(ROOT / 'scripts'))
        import build
        dataset = {'locations': {'verified': {'x': 1, 'y': 2, 'z': 3}}}
        verified = {'fresh_count': 1, 'fresh_guids_sha256': importer.digest(['verified'])}
        build.validate_chest_provenance(dataset, verified)
        dataset['locations']['ghost'] = {'x': 4, 'y': 5, 'z': 6}
        with self.assertRaises(AssertionError):
            build.validate_chest_provenance(dataset, verified)

    def test_later_import_retains_original_baseline_and_all_additions(self):
        import hashlib
        importer = self.load_importer()
        original = {'old': {'x': 1, 'y': 2, 'z': 3}, 'retired': {'x': 4, 'y': 5, 'z': 6}}
        with tempfile.TemporaryDirectory() as temporary:
            importer.ROOT = Path(temporary)
            importer.DATA = importer.ROOT / 'data'
            importer.CHEST_TYPES = (10,)
            importer.DATA.mkdir()
            (importer.ROOT / 'scripts').mkdir()
            audit = importer.ROOT / 'audit'
            audit.mkdir()
            data_path = importer.DATA / '10.json'
            manifest_path = importer.ROOT / 'scripts/dataset-manifest.json'
            data_path.write_text(json.dumps({'locations': original}))
            manifest_path.write_text(json.dumps({'files': {'10.json': {
                'sha256': hashlib.sha256(data_path.read_bytes()).hexdigest(),
                'locations_sha256': importer.digest(original), 'count': 2}}}))
            source = {'path': 'placement', 'appear_num': [1, 1], 'appear_rate': 100, 'group': 1,
                'settings': {'_SetFlagSetting': {'_TimeZone': 15,
                    '_QuestFlagInfos': {'_CheckType': 0, '_Infos': []}}},
                'tables': [{'_EventFlags': 0, '_LayerType': 0, '_GenerateTiming': 0, '_RequestType': 1}]}
            for added_guids in (['first'], ['first', 'second']):
                (audit / 'fresh-chest-records.json').write_text(json.dumps({'records': [
                    {'guid': guid, 'gimmick_id': 10,
                     'positions': [[original[guid][a] for a in 'xyz']] if guid in original else [[7, 8, 9]],
                     'sources': [source]} for guid in list(original) + added_guids]}))
                (audit / 'chest-catalog-membership.json').write_text(json.dumps({'records': [
                    {'guid': guid, 'sources': [{'path': 'placement',
                        'catalog_references': [{'catalog_kind': 'normal'}]}]}
                    for guid in list(original) + added_guids]}))
                importer.main(audit)
                dataset = json.loads(data_path.read_text())
                manifest = json.loads(manifest_path.read_text())['files']['10.json']
                self.assertEqual(dataset['supplemental_source']['added_guids'], added_guids)
                self.assertEqual(manifest['base_count'], 2)
                self.assertEqual(manifest['base_locations_sha256'], importer.digest(original))
                self.assertEqual(manifest['added_count'], len(added_guids))
                self.assertEqual(dataset['locations']['old'], original['old'])
            generated = (data_path, manifest_path, importer.DATA / 'chest-availability.json')
            before = [path.read_bytes() for path in generated]
            importer.main(audit)
            self.assertEqual([path.read_bytes() for path in generated], before)

            fresh_path = audit / 'fresh-chest-records.json'
            fresh = json.loads(fresh_path.read_text())
            fresh['records'] = [r for r in fresh['records'] if r['guid'] != 'retired']
            next(r for r in fresh['records'] if r['guid'] == 'old')['positions'] = [[11, 12, 13]]
            fresh_path.write_text(json.dumps(fresh))
            membership_path = audit / 'chest-catalog-membership.json'
            membership = json.loads(membership_path.read_text())
            membership['records'] = [r for r in membership['records'] if r['guid'] != 'retired']
            membership_path.write_text(json.dumps(membership))
            with self.assertRaisesRegex(ValueError, 'reconcile'):
                importer.main(audit)
            self.assertEqual([path.read_bytes() for path in generated], before, 'rejected import changed data')
            importer.main(audit, reconcile=True)
            dataset = json.loads(data_path.read_text())
            manifest = json.loads(manifest_path.read_text())['files']['10.json']
            self.assertNotIn('retired', dataset['locations'])
            self.assertEqual(dataset['locations']['old'], {'x': 11, 'y': 12, 'z': 13})
            self.assertEqual(manifest['retired_locations'], {'retired': original['retired']})
            self.assertEqual(manifest['corrected_positions'], {'old': original['old']})
            self.assertEqual(importer.reconstruct_original(dataset['locations'],
                dataset['supplemental_source']['added_guids'], manifest), original)
            self.assertEqual(manifest['base_count'], 2)
            self.assertEqual(manifest['base_locations_sha256'], importer.digest(original))
            self.assertEqual(manifest['added_count'], 2)
            self.assertEqual(set(json.loads(generated[2].read_text())['chests']), set(dataset['locations']))
            before = [path.read_bytes() for path in generated]
            importer.main(audit, reconcile=True)
            self.assertEqual([path.read_bytes() for path in generated], before)

    def test_world_is_derived_from_catalog_not_chest_size(self):
        importer = self.load_importer()
        self.assertEqual(importer.catalog_world(['back']), 'unmoored')
        self.assertEqual(importer.catalog_world(['normal']), 'any')
        self.assertEqual(importer.catalog_world(['ori']), 'normal')
        self.assertEqual(importer.catalog_world(['normal', 'back']), 'any')
        self.assertEqual(importer.catalog_world(['ori', 'back']), 'any')
        with self.assertRaises(ValueError):
            importer.catalog_world([])

    def test_packaging_rejects_incomplete_or_cross_type_availability(self):
        sys.path.insert(0, str(ROOT / 'scripts'))
        import build
        self.assertTrue(hasattr(build, 'validate_chest_metadata'), 'availability data has no package validation')
        locations = {10: {'old': {'x':1,'y':2,'z':3}}}
        valid = {'schema_version':1, 'chests':{'old':{'gimmick_id':10,
            'variants':[{'world':'any','quests':[]}]}}}
        build.validate_chest_metadata(valid, locations)
        for bad in ({'schema_version':1,'chests':{}},
                    {'schema_version':1,'chests':{'old':{'gimmick_id':11,'variants':[]}}},
                    {'schema_version':1,'chests':{'old':{'gimmick_id':10,'variants':[{'world':'guess'}]}}}):
            with self.subTest(bad=bad), self.assertRaises(AssertionError):
                build.validate_chest_metadata(bad, locations)

    def test_shipped_data_retains_original_provenance_with_explicit_retirements_and_corrections(self):
        import hashlib
        data = ROOT / 'reframework/data/raze_MapMarkersAndCollectables'
        manifest = json.loads((ROOT / 'scripts/dataset-manifest.json').read_text())
        importer = self.load_importer()
        for name in ('10.json', '11.json', '495.json'):
            dataset = json.loads((data / name).read_text())
            added = dataset['supplemental_source']['added_guids']
            base = manifest['files'][name]
            original = importer.reconstruct_original(dataset['locations'], added, base)
            canonical = json.dumps(original, sort_keys=True, separators=(',', ':')).encode()
            self.assertEqual(hashlib.sha256(canonical).hexdigest(), base['base_locations_sha256'])
            self.assertEqual(len(original), base['base_count'])
            self.assertEqual(len(added), len(set(added)))
            self.assertTrue(set(added) <= dataset['locations'].keys())


if __name__ == '__main__':
    unittest.main()
