// Run with Node.js and sharp available, then run python scripts/icon_assets.py.
const sharp = require('sharp');
const path = require('node:path');
const root = path.resolve(__dirname, '../assets/icons');
(async () => {
  const names = ['token', 'beetle', 'chest', 'special-chest'];
  const tiles = await Promise.all(names.map(async (name, i) => ({
    input: await sharp(path.join(root, `${name}.svg`)).resize(128, 128).png().toBuffer(),
    left: i * 128, top: 0,
  })));
  await sharp({ create: { width: 512, height: 128, channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(tiles).png().toFile(path.join(root, 'markers.png'));
})().catch(error => { console.error(error); process.exitCode = 1; });
