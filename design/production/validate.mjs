import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const sharp=require(process.env.RUNTIME_NODE_MODULES?path.join(process.env.RUNTIME_NODE_MODULES,'sharp'):'sharp');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const manifest=JSON.parse(await fs.readFile(path.join(root,'assets/game/manifest.json'),'utf8'));
const archivePath=path.join(root,'design/figma-manifest.json');
const archive=JSON.parse(await fs.readFile(archivePath,'utf8').catch(error=>{if(error.code==='ENOENT')return '{"assets":[]}';throw error;}));
const archivedSources=new Map(archive.assets.map(asset=>[asset.source,asset]));
const requireLocalSources=process.argv.includes('--require-local-sources');
const checkedArchivedSources=new Set();
const fail=message=>{throw Error(message);};
const ids=new Set(),paths=new Set();
const pubspec=await fs.readFile(path.join(root,'pubspec.yaml'),'utf8');
const master=await fs.readFile(path.join(root,'design/brand/bm-tower.svg'));
if(crypto.createHash('sha256').update(master.toString('utf8').replaceAll('\r\n','\n')).digest('hex')!==manifest.logoSourceSha256)fail('BM master changed after export.');
let framesChecked=0;
for(const asset of manifest.assets) {
  if(ids.has(asset.id)||paths.has(asset.path))fail(`Duplicate asset: ${asset.id}`);
  ids.add(asset.id);paths.add(asset.path);
  if(!asset.path.startsWith('assets/game/')||asset.path.includes('..'))fail(`Invalid path: ${asset.path}`);
  if(!pubspec.includes(`- ${path.posix.dirname(asset.path)}/`))fail(`Not bundled by Flutter: ${asset.path}`);
  const bytes=await fs.readFile(path.join(root,asset.path));
  if(bytes.length!==asset.bytes||crypto.createHash('sha256').update(bytes).digest('hex')!==asset.sha256)fail(`Changed asset: ${asset.id}`);
  if(asset.source) {
    let source;
    try { source=await fs.readFile(path.join(root,asset.source)); }
    catch(error) {
      if(error.code!=='ENOENT')throw error;
      const archived=archivedSources.get(asset.source);
      if(requireLocalSources||!archived||!archived.nodeId||!archived.imageHash||archived.sha256!==asset.sourceSha256||asset.sourceHashMode==='lf-text')fail(`Missing unverified source: ${asset.source}. Restore the original from Figma; see docs/DesignArchive.md.`);
      checkedArchivedSources.add(asset.source);
    }
    if(source) {
      const canonical=asset.sourceHashMode==='lf-text'?source.toString('utf8').replaceAll('\r\n','\n'):source;
      if(crypto.createHash('sha256').update(canonical).digest('hex')!==asset.sourceSha256)fail(`Source changed without re-export: ${asset.id}`);
    }
  }
  if(asset.path.endsWith('.wav')) {
    if(bytes.toString('ascii',0,4)!=='RIFF'||bytes.toString('ascii',8,12)!=='WAVE')fail(`Invalid WAV ${asset.id}`);
    if(bytes.readUInt16LE(20)!==1||bytes.readUInt16LE(34)!==16)fail(`WAV must be 16-bit PCM: ${asset.id}`);
    if(bytes.readUInt32LE(24)!==asset.sampleRate||bytes.readUInt16LE(22)!==asset.channels)fail(`WAV format mismatch: ${asset.id}`);
    const count=(bytes.length-44)/(asset.channels*2);
    if(Math.abs(count/asset.sampleRate-asset.seconds)>.001)fail(`WAV duration mismatch: ${asset.id}`);
    let peak=0;
    for(let i=44;i<bytes.length;i+=2)peak=Math.max(peak,Math.abs(bytes.readInt16LE(i)));
    if(peak<100||peak>=32767)fail(`Silent or clipped audio: ${asset.id}`);
    continue;
  }
  const m=await sharp(bytes).metadata();
  if(m.width!==asset.width||m.height!==asset.height)fail(`Dimension mismatch: ${asset.id}`);
  const decoded=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  if(!asset.allowEmpty && !decoded.data.some((v,i)=>i%4===3&&v>0))fail(`Invisible image: ${asset.id}`);
  if(asset.frameSize) {
    const [fw,fh]=asset.frameSize;
    if(fw*asset.columns!==m.width||fh*asset.rows!==m.height)fail(`Invalid sheet grid: ${asset.id}`);
    for(const [name,animation] of Object.entries(asset.animations)) {
      if(animation.fps<=0||animation.frames.length===0)fail(`Invalid playback: ${asset.id}.${name}`);
      for(const frame of animation.frames) {
        if(!Number.isInteger(frame)||frame<0||frame>=asset.columns*asset.rows)fail(`Invalid frame index: ${asset.id}.${name}`);
        const data=await sharp(bytes).extract({left:frame%asset.columns*fw,top:Math.floor(frame/asset.columns)*fh,width:fw,height:fh}).ensureAlpha().raw().toBuffer();
        if(!data.some((v,i)=>i%4===3&&v>24))fail(`Empty animation frame: ${asset.id}:${frame}`);
        if(asset.id.startsWith('characters.')) {
          for(let x=0;x<fw;x++)if(data[x*4+3]>24||data[((fh-1)*fw+x)*4+3]>24)fail(`Vertical frame clipping: ${asset.id}:${frame}`);
          for(let y=0;y<fh;y++)if(data[(y*fw)*4+3]>24||data[(y*fw+fw-1)*4+3]>24)fail(`Horizontal frame clipping: ${asset.id}:${frame}`);
        }
        framesChecked++;
      }
    }
  }
}
for(const role of ['resident','guest','office','customer','maintenance']) {
  const asset=manifest.assets.find(a=>a.id===`characters.${role}-animation`);
  if(!asset||asset.animations.idle.frames.length!==4||asset.animations.walk.frames.length!==8||asset.animations.stairs.frames.length!==4)fail(`Missing character states: ${role}`);
}
for(let mask=0;mask<16;mask++)if(!ids.has(`tiles.road-${mask.toString(2).padStart(4,'0')}`))fail(`Missing road connectivity ${mask}`);
for(const type of ['apartment','hotel','office','food-court'])for(const piece of ['lobby','floor','roof','luxury-1','luxury-2','luxury-3'])if(!ids.has(`buildings.${type}-${piece}`))fail(`Missing building module ${type}/${piece}`);
for(const phase of ['morning','day','afternoon','night','noon'])if(!ids.has(`backgrounds.phase-${phase}`))fail(`Missing phase ${phase}`);
console.log(`Validated ${ids.size} assets and ${framesChecked} referenced animation frames: hashes, decoding, bundling, alpha, clipping, audio and required coverage pass.`);
if(checkedArchivedSources.size)console.log(`Source provenance matched ${checkedArchivedSources.size} archived originals; remote source bytes were not fetched. Use --require-local-sources for a full restored-source audit.`);
