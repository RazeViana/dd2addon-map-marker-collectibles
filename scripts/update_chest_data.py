"""Import audited chest locations and export availability, preserving GUID identity.

Consumes the local, ignored audit artifacts produced from installed game resources.
Run only when intentionally accepting a chest-data update. Regular builds do not run it.
Use --reconcile after reviewing removals or position changes against a complete audit.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'reframework/data/raze_MapMarkersAndCollectables'
CHEST_TYPES = (10, 11, 12, 495, 692, 693, 694, 13, 465, 653)
POSITION_TOLERANCE = 0.01


def append_locations(original, fresh):
    updated, added = dict(original), []
    for record in sorted(fresh, key=lambda record: record['guid']):
        guid = record['guid']
        if guid in updated:
            continue
        positions = record['positions']
        if len(positions) != 1 or len(positions[0]) != 3:
            raise ValueError(f'Ambiguous new chest position: {guid}')
        updated[guid] = dict(zip('xyz', positions[0]))
        added.append(guid)
    return updated, added


def reconcile_locations(original, fresh):
    if len({record['guid'] for record in fresh}) != len(fresh):
        raise ValueError('Duplicate GUID in fresh chest records')
    updated, _ = append_locations({}, fresh)
    for guid, position in updated.items():
        if not all(type(value) in (int, float) and math.isfinite(value) for value in position.values()):
            raise ValueError(f'Invalid fresh chest position: {guid}')
        if guid in original and math.dist(list(position.values()), [original[guid][a] for a in 'xyz']) <= POSITION_TOLERANCE:
            updated[guid] = original[guid]
    return updated


def reconstruct_original(locations, added, manifest):
    added = set(added)
    assert added <= locations.keys()
    original = {guid: pos for guid, pos in locations.items() if guid not in added}
    retired = manifest.get('retired_locations', {})
    corrected = manifest.get('corrected_positions', {})
    assert not retired.keys() & locations.keys(), 'Retired chest is still active'
    assert corrected.keys() <= original.keys(), 'Correction has no original chest'
    original.update(retired)
    original.update(corrected)
    return original


def catalog_world(kinds):
    kinds = set(kinds)
    if not kinds or not kinds <= {'normal', 'back', 'ori'}:
        raise ValueError(f'Unsupported catalog membership: {sorted(kinds)}')
    if 'normal' in kinds or {'ori', 'back'} <= kinds:
        return 'any'
    return 'unmoored' if 'back' in kinds else 'normal'


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def main(audit, reconcile=False):
    fresh_path = audit / 'fresh-chest-records.json'
    membership_path = audit / 'chest-catalog-membership.json'
    records = json.loads(fresh_path.read_text())['records']
    membership_rows = json.loads(membership_path.read_text())['records']
    membership = {r['guid']: r for r in membership_rows}
    assert len(membership) == len(membership_rows), 'Duplicate catalog membership GUID'
    manifest_path = ROOT / 'scripts/dataset-manifest.json'
    manifest = json.loads(manifest_path.read_text())
    metadata = {'schema_version': 1, 'source': {
        'game_version': '3.2.0.0', 'date': '2026-09-14',
        'placement_records_sha256': hashlib.sha256(fresh_path.read_bytes()).hexdigest(),
        'catalog_membership_sha256': hashlib.sha256(membership_path.read_bytes()).hexdigest(),
        'validation': 'Installed executable metadata, catalog references and structural parsing; native behavior requires in-game checks.'},
        'chests': {}}
    by_guid = {r['guid']: r for r in records}
    assert len(by_guid) == len(records) and by_guid.keys() == membership.keys(), 'Fresh record/catalog GUID mismatch'
    pending = {}
    for kind in CHEST_TYPES:
        path = DATA / f'{kind}.json'
        dataset = json.loads(path.read_text())
        old = dataset['locations']
        previous = manifest['files'][path.name]
        assert hashlib.sha256(path.read_bytes()).hexdigest() == previous['sha256'], path.name
        fresh = [r for r in records if r['gimmick_id'] == kind]
        if not fresh:
            raise ValueError(f'No fresh records for chest type {kind}; check audit completeness')
        aligned = reconcile_locations(old, fresh)
        imported, added = append_locations(old, fresh)
        if reconcile:
            imported = aligned
        elif imported != aligned:
            raise ValueError(f'{path.name}: unmatched GUIDs or changed positions require --reconcile')
        previous_added = dataset.get('supplemental_source', {}).get('added_guids', [])
        assert len(previous_added) == len(set(previous_added))
        original = reconstruct_original(old, previous_added, previous)
        base_count = previous.get('base_count', len(original))
        base_digest = previous.get('base_locations_sha256', digest(original))
        assert len(original) == base_count and digest(original) == base_digest, path.name
        all_added = sorted(imported.keys() - original.keys())
        retired = {guid: original[guid] for guid in sorted(original.keys() - imported.keys())}
        corrected = {guid: original[guid] for guid in sorted(original.keys() & imported.keys())
                     if original[guid] != imported[guid]}
        dataset['locations'] = imported
        if all_added or retired or corrected or 'supplemental_source' in dataset:
            dataset['supplemental_source'] = {'game_version': '3.2.0.0',
                'source': 'Installed-game manual placement resources',
                'added_guids': all_added, 'original_coordinates_preserved': not corrected}
        for guid in sorted(imported):
            record = by_guid.get(guid)
            meta = {'gimmick_id': kind, 'variants': []}
            if record is None:
                raise ValueError(f'Chest absent from fresh records: {guid}')
            else:
                assert record['gimmick_id'] == kind
                for source in record['sources']:
                    refs = [ref for item in membership[guid]['sources'] if item['path'] == source['path']
                            for ref in item['catalog_references']]
                    world = catalog_world([ref['catalog_kind'] for ref in refs])
                    quest_info = source['settings']['_SetFlagSetting']['_QuestFlagInfos']
                    assert quest_info['_CheckType'] in (0, 1)
                    for table in source['tables']:
                        rule = {'world': world, 'quest_mode': 'and' if quest_info['_CheckType'] == 0 else 'or',
                            'quests': [{'id': q['_QuestID'], 'finish': q['_IsFinishCheck']} for q in quest_info['_Infos']]}
                        if table['_EventFlags']:
                            assert table['_EventFlags'] in (8, 32, 64)
                            rule['event_flag'] = table['_EventFlags']
                        unsupported = []
                        if table['_LayerType'] != 0:
                            unsupported.append('Quest-phase table activation requires additional state')
                        if kind in (13, 465, 653):
                            unsupported.append('Sphinx reward seal conditions are not yet verified')
                        if source['appear_num'] != [1, 1] or source['appear_rate'] != 100 or source['group'] != 1:
                            unsupported.append('Unsupported appearance rule')
                        if source['settings']['_SetFlagSetting']['_TimeZone'] != 15:
                            unsupported.append('Unsupported time-of-day restriction')
                        if table['_GenerateTiming'] != 0 or table['_RequestType'] not in (1, 4):
                            unsupported.append('Unsupported generation timing or request type')
                        if unsupported:
                            rule['unsupported'] = '; '.join(unsupported)
                        if rule not in meta['variants']:
                            meta['variants'].append(rule)
            metadata['chests'][guid] = meta
        if imported != old or added:
            raw = (json.dumps(dataset, separators=(',', ':'), ensure_ascii=False) + '\n').encode('utf-8')
            pending[path] = raw
        manifest['files'][path.name] = {'sha256': hashlib.sha256(pending.get(path, path.read_bytes())).hexdigest(),
            'locations_sha256': digest(imported), 'count': len(imported),
            'base_count': base_count, 'base_locations_sha256': base_digest, 'added_count': len(all_added),
            'fresh_count': len(fresh), 'fresh_guids_sha256': digest(sorted(r['guid'] for r in fresh))}
        if retired:
            manifest['files'][path.name]['retired_locations'] = retired
        if corrected:
            manifest['files'][path.name]['corrected_positions'] = corrected
    raw_meta = (json.dumps(metadata, indent=2) + '\n').encode()
    manifest['chest_availability'] = {'filename': 'chest-availability.json',
        'sha256': hashlib.sha256(raw_meta).hexdigest(), 'count': len(metadata['chests'])}
    # Validate and construct every result before replacing the development data files.
    for path, raw in pending.items():
        path.write_bytes(raw)
    (DATA / 'chest-availability.json').write_bytes(raw_meta)
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Updated {len(pending)} location datasets; availability for {len(metadata["chests"])} chest GUIDs.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--audit', type=Path, default=ROOT / 'reference/runtime/chest-audit')
    parser.add_argument('--reconcile', action='store_true', help='Apply reviewed removals and coordinate changes')
    args = parser.parse_args()
    main(args.audit, reconcile=args.reconcile)
