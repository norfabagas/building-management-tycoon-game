import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

// Recover original raster bytes from a fresh Figma download_assets rawImages URL.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const [source,url]=process.argv.slice(2);
if(!source||!url)throw Error('Usage: node design/production/restore-source.mjs <archived-source-path> <Figma-raw-image-url>');
const archive=JSON.parse(await fs.readFile(path.join(root,'design/figma-manifest.json'),'utf8'));
const asset=archive.assets.find(asset=>asset.source===source);
if(!asset||!source.startsWith('design/')||!source.endsWith('.png'))throw Error('Choose an archived design PNG from design/figma-manifest.json.');
const target=path.resolve(root,source);
if(!target.startsWith(root+path.sep))throw Error('Source path leaves the repository.');
const endpoint=new URL(url);
if(endpoint.protocol!=='https:'||endpoint.hostname!=='www.figma.com'||!endpoint.pathname.startsWith('/api/mcp/asset/'))throw Error('Use the fresh original rawImages URL from Figma download_assets.');
try { await fs.access(target);throw Error('Destination exists; keep or move it before restoring.'); }
catch(error) { if(error.code!=='ENOENT')throw error; }
const response=await fetch(endpoint);
if(!response.ok)throw Error(`Figma download failed: HTTP ${response.status}`);
const bytes=Buffer.from(await response.arrayBuffer());
if(bytes.length!==asset.bytes||crypto.createHash('sha256').update(bytes).digest('hex')!==asset.sha256)throw Error('Downloaded bytes differ from the archived original. Use rawImages, not the resized node export.');
await fs.mkdir(path.dirname(target),{recursive:true});
await fs.writeFile(target,bytes,{flag:'wx'});
console.log(`Restored and SHA-256 verified ${source}`);
