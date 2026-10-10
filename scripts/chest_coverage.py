"""Accept the current chest scan and attach native trial map routing to DLC data."""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import uuid

from dlc_data import COUNTS, COVERAGE_TYPES, RITUAL_TYPES, DATA, MANIFEST, digest, _encoded, validate_dlc_availability


def validate_trial_routes(dataset):
    locations = dataset['locations']
    areas, bounds = dataset.get('map_areas'), dataset.get('map_bounds')
    assert isinstance(areas, dict) and areas.keys() == locations.keys(), 'Incomplete trial map routing'
    assert isinstance(bounds, dict), 'Missing trial map bounds'
    for guid, position in locations.items():
        area = areas[guid]
        assert type(area) is int and 6001 <= area <= 6012, f'Invalid trial map: {guid}'
        rectangle = bounds.get(str(area))
        assert isinstance(rectangle, list) and len(rectangle) == 4 and all(
            type(value) in (int, float) and math.isfinite(value) for value in rectangle)
        x0, z0, x1, z1 = rectangle
        assert x0 < x1 and z0 < z1
        assert x0 <= position['x'] <= x1 and z0 <= position['z'] <= z1, f'Trial position outside source map: {guid}'


def import_coverage(audit_path, trial_path, map_path, data_dir=DATA, manifest_path=MANIFEST):
    paths = tuple(map(Path, (audit_path, trial_path, map_path)))
    raw_audit, raw_trials, raw_maps = (path.read_bytes() for path in paths)
    audit, trials, maps = (json.loads(raw) for raw in (raw_audit, raw_trials, raw_maps))
    assert audit['audit_date'] == '2026-10-10' and audit['comparison'] == 'released v1.5'
    assert audit['unresolved_prefabs'] == [] and audit['moved_existing_chests'] == {}
    rows = audit['missing_chests']
    assert Counter(row['gimmick_id'] for row in rows.values()) == {kind: COUNTS[kind] for kind in COVERAGE_TYPES}
    assert audit['missing_count'] == len(rows) == 97
    inventories = {item['archive']: item['entry_table_sha256'] for item in audit['archive_inventories']}
    assert set(inventories) == {'re_chunk_000.pak', 're_dlc_stm_2593290.pak'}
    assert all(len(value) == 64 for value in inventories.values())
    data_dir, manifest_path = Path(data_dir), Path(manifest_path)
    manifest = json.loads(manifest_path.read_bytes())
    metadata = json.loads((data_dir / 'dlc-availability.json').read_bytes())
    source = {'game_version': '4.0.0.0', 'date': '2026-10-10',
              'source_archive': 're_dlc_stm_2593290.pak',
              'chest_audit_sha256': hashlib.sha256(raw_audit).hexdigest(),
              'archive_entry_tables': inventories,
              'validation': 'Fixed placements from installed game files; event and quest activation are not inferred.'}
    pending = {}
    for kind in sorted(COVERAGE_TYPES):
        locations = {}
        for guid, row in sorted(rows.items()):
            if row['gimmick_id'] != kind:
                continue
            assert str(uuid.UUID(guid)) == row['guid'] == guid
            coordinates = row['position']
            assert isinstance(coordinates, list) and len(coordinates) == 3 and all(
                type(value) in (int, float) and math.isfinite(value) for value in coordinates)
            locations[guid] = dict(zip('xyz', coordinates))
            native = audit['chest_prefabs'][str(kind)]
            assert native['is_chest'] is True
            assert row['path'].startswith('natives/stm/appdata/generate/manualset/')
            variable = row['settings']['_SetFlagSetting']['_QuestFlagInfos']['_Infos']
            record = {'gimmick_id': kind, 'variants': [{'world': 'normal', 'quests': [],
                'unsupported': 'Quest-linked placement activation is not evaluated' if kind == 994
                else 'Spoils chest event activation and renewal are not evaluated'}],
                'source': {'source_path': row['path'], 'parameter_id': row['param_id'],
                    'quest_variables': variable, 'native_label': row['native_label'],
                    'table_ids': [table['_TableID'] for table in row['tables']]}}
            # Reimporting the same accepted audit is safe; replacing a different identity is not.
            assert guid not in metadata['records'] or metadata['records'][guid] == record
            metadata['records'][guid] = record
        label = 'Norgan quest chest' if kind == 994 else 'Spoils chest'
        pending[f'{kind}.json'] = {'locations': locations, 'source': dict(source, gimmick_id=kind, label=label),
                                  'credits': 'See THIRD_PARTY_NOTICES.md for dataset authorship.'}

    bounds = {}
    for row in maps['menu']:
        area = row['UIArea']
        if not 6001 <= area <= 6012:
            continue
        rectangle = [row['BasePosX'], row['BasePosZ'], row['BasePosX']+row['DispRangeX'], row['BasePosZ']+row['DispRangeZ']]
        assert str(area) not in bounds or bounds[str(area)] == rectangle, 'Inconsistent trial map rectangle'
        bounds[str(area)] = rectangle
    assert set(bounds) == set(map(str, range(6001, 6013)))
    by_guid = {}
    for dungeon, group in trials.items():
        area = 6000 + int(dungeon.split('_')[1])
        for chest in group['chests']:
            guid = chest['guid']
            assert guid not in by_guid and chest['gimmick_id'] in RITUAL_TYPES
            by_guid[guid] = (area, chest)
    assert len(by_guid) == 185
    for kind in sorted(RITUAL_TYPES):
        dataset = json.loads((data_dir / f'{kind}.json').read_bytes())
        dataset['map_areas'] = {}
        dataset['map_bounds'] = {}
        for guid, position in dataset['locations'].items():
            area, chest = by_guid[guid]
            assert chest['gimmick_id'] == kind and chest['position'] == position
            dataset['map_areas'][guid] = area
            dataset['map_bounds'][str(area)] = bounds[str(area)]
        dataset['map_source'] = {'date': '2026-10-10', 'trials_sha256': hashlib.sha256(raw_trials).hexdigest(),
                                 'map_routing_sha256': hashlib.sha256(raw_maps).hexdigest(),
                                 'floor_assignment': 'Not inferred; full map shows positions throughout the selected trial.'}
        validate_trial_routes(dataset)
        pending[f'{kind}.json'] = dataset

    locations_by_type = {kind: pending[f'{kind}.json']['locations'] if f'{kind}.json' in pending
        else json.loads((data_dir / f'{kind}.json').read_bytes())['locations'] for kind in COUNTS}
    metadata['source']['coverage_audit'] = source
    validate_dlc_availability(metadata, locations_by_type)
    encoded = {}
    for name, dataset in pending.items():
        raw = _encoded(dataset)
        locations = dataset['locations']
        encoded[name] = raw
        manifest['files'][name] = {'sha256': hashlib.sha256(raw).hexdigest(),
            'locations_sha256': digest(locations), 'count': len(locations), 'fresh_count': len(locations),
            'fresh_guids_sha256': digest(sorted(locations))}
    encoded['dlc-availability.json'] = _encoded(metadata)
    manifest['dlc_availability'] = {'filename': 'dlc-availability.json',
        'sha256': hashlib.sha256(encoded['dlc-availability.json']).hexdigest(), 'count': len(metadata['records'])}
    # Validate every input and construct every output before replacing any files.
    for name, raw in encoded.items():
        path = data_dir / name
        if not path.exists() or path.read_bytes() != raw:
            path.write_bytes(raw)
    raw_manifest = _encoded(manifest)
    if manifest_path.read_bytes() != raw_manifest:
        manifest_path.write_bytes(raw_manifest)
    return {'added': len(rows), 'trial_routes': len(by_guid), 'dlc_records': len(metadata['records'])}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--audit', type=Path, required=True)
    parser.add_argument('--trials', type=Path, required=True)
    parser.add_argument('--maps', type=Path, required=True)
    args = parser.parse_args()
    print(import_coverage(args.audit, args.trials, args.maps))
