"""Build and validate the additive icon atlases for the current DD2 PC format."""
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "natives/stm/raze/mapmarkers"
TEXTURE = "raze/mapmarkers/markers.tex"
LAYOUT = ROOT / "assets/icons/native-atlas-layout.json"
PATTERN = struct.Struct("<Q4f2i")


def atlas_bytes(layout):
    textures = layout["textures"] + [TEXTURE]
    sequences = layout["sequences"] + [[4, len(layout["patterns"])]]
    patterns = layout["patterns"] + [
        [0, i / 4, 0, (i + 1) / 4, 1, len(layout["textures"]), -1] for i in range(4)
    ]
    tex_offset = 56
    seq_offset = tex_offset + len(textures) * 40
    pat_offset = seq_offset + len(sequences) * 8
    str_offset = pat_offset + len(patterns) * 32
    data = struct.pack("<6I4Q", 0x5556532E, len(textures), len(sequences), len(patterns),
                       0, 0, tex_offset, seq_offset, pat_offset, str_offset)
    strings = b""
    for i, path in enumerate(textures):
        data += struct.pack("<5Q", i, len(strings) // 2, *([0xFFFFFFFFFFFFFFFF] * 3))
        strings += (path + "\0").encode("utf-16le")
    data += b"".join(struct.pack("<2I", *sequence) for sequence in sequences)
    data += b"".join(PATTERN.pack(*pattern) for pattern in patterns)
    return data + strings


def build():
    from PIL import Image
    OUTPUT.mkdir(parents=True, exist_ok=True)
    image = Image.open(ROOT / "assets/icons/markers.png").convert("RGBA")
    width, height = image.size
    assert (width, height) == (512, 128)
    header = struct.pack("<IIHHHBBIiIIBBHHH", 0x00584554, 251211553, width, height, 1,
                         1, 16, 28, -1, 0, 17 << 7, 0, 0, 0, 7, 1)
    (OUTPUT / "markers.tex.251211553").write_bytes(
        header + struct.pack("<QII", 56, width * 4, width * height * 4) + image.tobytes())
    for name, layout in json.loads(LAYOUT.read_text()).items():
        (OUTPUT / f"{name}.uvs.8").write_bytes(atlas_bytes(layout))
    validate()


def validate():
    layouts = json.loads(LAYOUT.read_text())
    for name, layout in layouts.items():
        data = (OUTPUT / f"{name}.uvs.8").read_bytes()
        magic, textures, sequences, patterns, _, _, tex, seq, pat, strings = struct.unpack_from("<6I4Q", data)
        assert magic == 0x5556532E and textures == 3 and sequences == 3
        assert patterns == len(layout["patterns"]) + 4
        assert 56 <= tex < seq < pat < strings < len(data)
        # Every native UV and sequence remains intact, including empty atlas cells.
        for i, expected in enumerate(layout["patterns"]):
            assert list(PATTERN.unpack_from(data, pat + i * 32)) == expected
        for i, expected in enumerate(layout["sequences"]):
            assert list(struct.unpack_from("<2I", data, seq + i * 8)) == expected
        for i, expected in enumerate(layout["textures"] + [TEXTURE]):
            offset = struct.unpack_from("<Q", data, tex + i * 40 + 8)[0]
            assert data[strings + offset * 2:].decode("utf-16le").split("\0")[0] == expected
        for i in range(4):
            assert PATTERN.unpack_from(data, pat + (patterns - 4 + i) * 32) == (0, i/4, 0, (i+1)/4, 1, 2, -1)
    texture = (OUTPUT / "markers.tex.251211553").read_bytes()
    assert struct.unpack_from("<IIHH", texture) == (0x00584554, 251211553, 512, 128)
    assert struct.unpack_from("<QII", texture, 40) == (56, 2048, 262144)
    assert len(texture) == 262200 and any(texture[59::4])
    return [OUTPUT / name for name in ("fullmap.uvs.8", "minimap.uvs.8", "markers.tex.251211553")]


if __name__ == "__main__":
    build()
    print("Built and validated object icon assets")
