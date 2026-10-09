"""Check the shipped atlases retain the updated native symbols and all custom tiles."""
import json
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATTERN = struct.Struct('<Q4f2i')


class DlcIconAtlasTests(unittest.TestCase):
    def test_new_native_symbol_and_appended_custom_tiles(self):
        layout = json.loads((ROOT / 'assets/icons/native-atlas-layout.json').read_text())
        for name, count, texture in (('fullmap', 85, 1), ('minimap', 82, 0)):
            with self.subTest(name=name):
                native = layout[name]['patterns']
                self.assertEqual(len(native), count)
                self.assertEqual(layout[name]['sequences'][-1], [81, 4 if name == 'fullmap' else 1])
                self.assertEqual(native[-1], [0, .3125, .5, .375, .625, texture, -1])
                atlas = (ROOT / f'natives/stm/raze/mapmarkers/{name}.uvs.8').read_bytes()
                header = struct.unpack_from('<6I4Q', atlas)
                self.assertEqual(header[3], count + 11 + (2 if name == 'minimap' else 0))
                pattern_offset = header[8]
                self.assertEqual(list(PATTERN.unpack_from(atlas, pattern_offset + (count - 1) * 32)), native[-1])
                for tile in range(11):
                    pattern = PATTERN.unpack_from(atlas, pattern_offset + (count + tile) * 32)
                    for actual, expected in zip(pattern[1:5], (tile / 11, 0, (tile + 1) / 11, 1)):
                        self.assertAlmostEqual(actual, expected, delta=1e-7)
                    self.assertEqual(pattern[5], 2)

    def test_marker_texture_has_eleven_nonempty_tiles(self):
        texture = (ROOT / 'natives/stm/raze/mapmarkers/markers.tex.251211553').read_bytes()
        self.assertEqual(struct.unpack_from('<IIHH', texture), (0x00584554, 251211553, 1408, 128))
        pixels = texture[56:]
        for tile in range(11):
            alpha = pixels[(tile * 128 * 4) + 3:]
            self.assertTrue(any(alpha[row * 1408 * 4 + col * 4] for row in range(128) for col in range(128)), tile)


if __name__ == '__main__':
    unittest.main()
