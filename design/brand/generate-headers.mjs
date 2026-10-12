import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const titles = ['Foundations', 'Interaction states', 'Map artwork', 'Interior artwork', 'Local profiles', 'CBD map & HUD', 'Building types', 'Land footprint', 'Floors & capacity', 'Cost review', 'Building cross-section', 'Floors & rooms', 'Tenants & visitors', 'Upgrades & maintenance', 'Finance & rewards', 'Responsive layouts'];
const heights = [80,74,64,64,64,32,32,64,68,60,36,68,56,76,64,64];
const mark = fs.readFileSync(path.join(root, 'bm-tower.svg'), 'utf8').match(/<rect[\s\S]*<\/svg>/)[0].replace('</svg>', '');
const xml = value => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;');
fs.mkdirSync(path.join(root, 'headers'), { recursive: true });
for (let i = 0; i < titles.length; i++) {
  const h = heights[i];
  const compact = h < 40;
  const size = compact ? 24 : 44;
  const y = (h - size) / 2;
  const titleSize = compact ? 14 : 18;
  const textY = h / 2 + titleSize * .35;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="794" height="${h}" viewBox="0 0 794 ${h}"><title>Building Management Tycoon — ${xml(titles[i])}</title><rect width="794" height="${h}" fill="#F5F3EB"/><g transform="translate(16 ${y}) scale(${size / 512})">${mark}</g><text x="${16 + size + 16}" y="${textY}" fill="#203B3A" font-family="Arial, Helvetica, sans-serif" font-size="${titleSize}" font-weight="700">Building Management Tycoon</text><text x="778" y="${h / 2 + 4}" text-anchor="end" fill="#203B3A" font-family="Arial, Helvetica, sans-serif" font-size="12" font-weight="700">${String(i + 1).padStart(2, '0')} · ${xml(titles[i])}</text></svg>\n`;
  fs.writeFileSync(path.join(root, 'headers', `${String(i + 1).padStart(2, '0')}.svg`), svg);
}
console.log('Generated 16 square-mark title headers.');
