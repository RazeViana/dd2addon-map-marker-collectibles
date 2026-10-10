"""Import reviewed Dark Arisen placement audits without touching base-game datasets.

The ignored audit inputs are needed only when accepting a new extraction. A normal
release build validates and packages the committed JSON and needs no game files.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import uuid

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'reframework/data/raze_MapMarkersAndCollectables'
MANIFEST = ROOT / 'scripts/dataset-manifest.json'
COUNTS = {755: 119, 757: 47, 758: 10, 795: 9, 826: 267, 885: 122, 894: 140,
          908: 40, 994: 3, 1004: 48, 1023: 6}
COVERAGE_TYPES = {908, 994, 1004, 1023}
RITUAL_TYPES = {755, 757, 758, 795}
GAME_VERSION = '4.0.0.0'
AUDIT_DATE = '2026-10-09'


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode('utf-8')).hexdigest()


def _encoded(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + '\n').encode('utf-8')


def validate_dlc_availability(metadata, locations_by_type):
    assert metadata.get('schema_version') == 1, 'Unsupported DLC availability schema'
    source = metadata.get('source', {})
    assert source.get('game_version') == GAME_VERSION and source.get('date') == AUDIT_DATE
    expected = {}
    for kind, locations in locations_by_type.items():
        assert kind in COUNTS, f'Unknown DLC gimmick type: {kind}'
        for guid in locations:
            assert guid not in expected, f'Duplicate DLC GUID across types: {guid}'
            expected[guid] = kind
    records = metadata.get('records')
    assert isinstance(records, dict) and records.keys() == expected.keys(), 'DLC availability coverage mismatch'
    for guid, kind in expected.items():
        record = records[guid]
        assert record.get('gimmick_id') == kind, f'Wrong DLC gimmick type: {guid}'
        variants = record.get('variants')
        assert isinstance(variants, list), f'Missing DLC variants: {guid}'
        provenance = record.get('source')
        assert isinstance(provenance, dict), f'Missing DLC provenance: {guid}'
        if kind in RITUAL_TYPES:
            sources = provenance.get('source_variants')
            assert isinstance(sources, list) and sources, f'Missing ritual sources: {guid}'
            has_catalog = any(source.get('catalog_references') for source in sources)
            assert bool(variants) == bool(has_catalog), f'Wrong ritual catalog coverage: {guid}'
            if not variants:
                assert isinstance(record.get('unresolved'), str) and record['unresolved'], f'Unguarded ritual chest: {guid}'
        else:
            assert isinstance(provenance.get('source_path'), str) and provenance['source_path']
            assert type(provenance.get('parameter_id')) is int
            quest_variables = provenance.get('quest_variables')
            assert isinstance(quest_variables, list)
            assert len(variants) == 1, f'Unexpected DLC placement variants: {guid}'
        for variant in variants:
            assert variant.get('world') == 'normal' and variant.get('quests') == [], f'Unverified DLC gate inferred: {guid}'
            unsupported = variant.get('unsupported')
            if kind in RITUAL_TYPES or kind in COVERAGE_TYPES or provenance.get('quest_variables'):
                assert isinstance(unsupported, str) and unsupported.strip(), f'Unverified gate dropped: {guid}'
            else:
                assert unsupported is None, f'Unexpected unsupported gate: {guid}'


def import_audits(collectibles_path, ritual_path, data_dir=DATA, manifest_path=MANIFEST):
    collectibles_path, ritual_path = Path(collectibles_path), Path(ritual_path)
    data_dir, manifest_path = Path(data_dir), Path(manifest_path)
    extended = any((data_dir / f'{kind}.json').exists() for kind in COVERAGE_TYPES)
    for kind in RITUAL_TYPES:
        path = data_dir / f'{kind}.json'
        if path.exists() and 'map_areas' in json.loads(path.read_bytes()):
            extended = True
    assert not extended, ('Chest coverage extension present; use scripts/chest_coverage.py to refresh it. '
                          'Import a new full extraction into a fresh staging directory first.')
    raw_collectibles, raw_ritual = collectibles_path.read_bytes(), ritual_path.read_bytes()
    audits = [(json.loads(raw_collectibles), {826, 885, 894}),
              (json.loads(raw_ritual), RITUAL_TYPES)]
    assert all(audit.get('source_archive') == 're_dlc_stm_2593290.pak' for audit, _ in audits)
    assert all(audit.get('source_manifest_sha256') and audit.get('parser_result_sha256') for audit, _ in audits)
    assert all(set(map(int, audit['groups'])) == kinds for audit, kinds in audits)
    source = {
        'game_version': GAME_VERSION, 'date': AUDIT_DATE,
        'source_archive': audits[0][0]['source_archive'],
        'collectibles_audit_sha256': hashlib.sha256(raw_collectibles).hexdigest(),
        'ritual_audit_sha256': hashlib.sha256(raw_ritual).hexdigest(),
        'source_manifest_sha256': audits[0][0]['source_manifest_sha256'],
        'parser_result_sha256': audits[0][0]['parser_result_sha256'],
        'validation': 'Diagnostic structural extraction; native activation and collection behavior require in-game checks.',
    }
    assert source['source_manifest_sha256'] == audits[1][0]['source_manifest_sha256']
    assert source['parser_result_sha256'] == audits[1][0]['parser_result_sha256']
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    assert manifest.get('format_version') == 1 and isinstance(manifest.get('files'), dict)
    pending = {}
    locations_by_type = {}
    availability = {'schema_version': 1, 'source': source, 'records': {}}
    for audit, kinds in audits:
        for kind in sorted(kinds):
            group = audit['groups'][str(kind)]
            rows = group['locations']
            assert len(rows) == COUNTS[kind], f'Unexpected {kind} count'
            locations = {}
            for guid, row in sorted(rows.items()):
                assert str(uuid.UUID(guid)) == guid, f'Invalid DLC GUID: {guid}'
                assert guid not in availability['records'], f'Duplicate DLC GUID: {guid}'
                position = row['position']
                assert set(position) == {'x', 'y', 'z'} and all(
                    type(position[axis]) in (int, float) and math.isfinite(position[axis])
                    for axis in ('x', 'y', 'z')), f'Invalid DLC position: {guid}'
                locations[guid] = position
                record = {'gimmick_id': kind, 'variants': []}
                if kind in RITUAL_TYPES:
                    sources = row['source_variants']
                    record['source'] = {'source_variants': sources}
                    if any(entry.get('catalog_references') for entry in sources):
                        record['variants'] = [{'world': 'normal', 'quests': [],
                            'unsupported': 'Lost Rites trial activation and chest renewal are unverified'}]
                    else:
                        record['unresolved'] = 'No catalog reference; Lost Rites trial activation and chest renewal are unverified'
                else:
                    quest_variables = row['availability']['quest_variables']
                    assert row['availability']['catalog_world'] == 'normal'
                    record['source'] = {'source_path': row['source_path'],
                        'parameter_id': row['parameter_id'], 'quest_variables': quest_variables}
                    variant = {'world': 'normal', 'quests': []}
                    if quest_variables:
                        variant['unsupported'] = 'Quest-variable placement gate is not yet evaluated'
                    record['variants'] = [variant]
                availability['records'][guid] = record
            locations_by_type[kind] = locations
            dataset = {'locations': locations,
                'source': dict(source, gimmick_id=kind, label=group['label']),
                'credits': 'See THIRD_PARTY_NOTICES.md for dataset authorship.'}
            name = f'{kind}.json'
            raw = _encoded(dataset)
            pending[data_dir / name] = raw
            manifest['files'][name] = {'sha256': hashlib.sha256(raw).hexdigest(),
                'locations_sha256': digest(locations), 'count': len(locations),
                'fresh_count': len(locations), 'fresh_guids_sha256': digest(sorted(locations))}
    validate_dlc_availability(availability, locations_by_type)
    raw_availability = _encoded(availability)
    pending[data_dir / 'dlc-availability.json'] = raw_availability
    manifest['dlc_availability'] = {'filename': 'dlc-availability.json',
        'sha256': hashlib.sha256(raw_availability).hexdigest(), 'count': len(availability['records'])}
    # All input checks finish before any target is replaced. Existing base datasets are untouched.
    data_dir.mkdir(parents=True, exist_ok=True)
    for path, raw in pending.items():
        if not path.exists() or path.read_bytes() != raw:
            path.write_bytes(raw)
    manifest_raw = _encoded(manifest)
    if manifest_path.read_bytes() != manifest_raw:
        manifest_path.write_bytes(manifest_raw)
    return {kind: len(locations) for kind, locations in locations_by_type.items()}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--collectibles', type=Path,
        default=ROOT / 'reference/runtime/dlc-audit/import-ready-collectibles.json')
    parser.add_argument('--ritual', type=Path,
        default=ROOT / 'reference/runtime/dlc-audit/import-ready-ritual-chests.json')
    args = parser.parse_args()
    print(import_audits(args.collectibles, args.ritual))
