import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';

const require = createRequire(import.meta.url);
const sharp = require(process.env.RUNTIME_NODE_MODULES
  ? path.join(process.env.RUNTIME_NODE_MODULES, 'sharp') : 'sharp');
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../..');
const output = path.join(root, 'assets/game');
const source = path.join(here, 'sources');
const C = {ink:'#203B3A', paper:'#FFFCF1', bg:'#F5F3EB', green:'#237563',
  mint:'#DBEBDD', land:'#BBD995', grass:'#97B675', amber:'#E9B754',
  coral:'#E98D70', blue:'#65B1C5', red:'#AF443F', border:'#CAD2C6',
  road:'#626F70', darkRoad:'#4A595B', cream:'#E6D5B5', teal:'#39AFC0'};
const catalog = [];
const original = n => path.join(root, `design/tycoon/assets/${n}.png`);
const svg = (w,h,body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
const poly = (points,fill,stroke=C.ink,sw=2) => `<polygon points="${points}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
const rect = (x,y,w,h,fill,r=0,stroke=C.ink,sw=2) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const line = (x1,y1,x2,y2,stroke=C.ink,sw=2) => `<path d="M${x1} ${y1}L${x2} ${y2}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round"/>`;
const circle = (x,y,r,fill,stroke=C.ink,sw=2) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
const group = (transform,body) => `<g transform="${transform}">${body}</g>`;
const escape = t => t.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');

// Generated sheets can have uneven gutters. Locate real transparent row/column
// boundaries instead of cutting through a shoe at a nominal quarter boundary.
async function spriteGrid(input) {
  const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const rows=new Array(info.height).fill(0),cols=new Array(info.width).fill(0);
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>128){rows[y]++;cols[x]++;}
  function cuts(counts,other) {
    const values=[0],length=counts.length,threshold=Math.max(2,Math.floor(other*.002));
    for(let quarter=1;quarter<4;quarter++) {
      const ideal=length*quarter/4,low=Math.floor(ideal-length*.06),high=Math.ceil(ideal+length*.06);
      let best=null;
      for(let i=low;i<=high;i++)if(counts[i]<=threshold) {
        const start=i;while(i<=high&&counts[i]<=threshold)i++;
        if(i-start<3)continue;
        const center=Math.floor((start+i)/2),distance=Math.abs(center-ideal);
        if(!best||distance<best.distance)best={center,distance};
      }
      if(!best)throw Error(`No clean sprite gutter near ${quarter}/4 in ${input}`);
      values.push(best.center);
    }
    values.push(length);return values;
  }
  return {x:cuts(cols,info.height),y:cuts(rows,info.width)};
}

async function register(id,relative,meta={}) {
  const file = path.join(output,relative);
  const bytes = await fs.readFile(file);
  const dim = relative.endsWith('.png') ? await sharp(bytes).metadata() : {};
  let sourceHash={};
  if(meta.source) {
    const sourceBytes=await fs.readFile(path.join(root,meta.source));
    const text=/\.(svg|py|js|mjs|json)$/.test(meta.source);
    sourceHash={sourceHashMode:text?'lf-text':'binary',sourceSha256:crypto.createHash('sha256')
      .update(text?sourceBytes.toString('utf8').replaceAll('\r\n','\n'):sourceBytes).digest('hex')};
  }
  catalog.push({id,path:`assets/game/${relative}`,bytes:bytes.length,
    sha256:crypto.createHash('sha256').update(bytes).digest('hex'),
    ...(dim.width ? {width:dim.width,height:dim.height,hasAlpha:dim.hasAlpha} : {}),
    pivot:[0.5,1],...meta,...sourceHash});
}

async function draw(id,category,name,w,h,body,meta={}) {
  const input = svg(w,h,body);
  const sourcePath = path.join(source,category,`${name}.svg`);
  const relative = `${category}/${name}.png`;
  await fs.mkdir(path.dirname(sourcePath),{recursive:true});
  await fs.mkdir(path.dirname(path.join(output,relative)),{recursive:true});
  await fs.writeFile(sourcePath,input+'\n');
  await sharp(Buffer.from(input)).png().toFile(path.join(output,relative));
  await register(id,relative,{provenance:'authored-vector',source:path.relative(root,sourcePath).replaceAll('\\','/'),...meta});
}

async function crop(id,category,name,atlas,box,width,height) {
  const input = original(atlas), metadata = await sharp(input).metadata();
  const [l,t,r,b] = box;
  const left=Math.floor(l*metadata.width),top=Math.floor(t*metadata.height);
  const cropWidth=Math.floor((1-r)*metadata.width)-left;
  const cropHeight=Math.floor((1-b)*metadata.height)-top;
  const region=await sharp(input).extract({left,top,width:cropWidth,height:cropHeight}).png().toBuffer();
  const extracted=await sharp(region).trim({threshold:8}).png().toBuffer();
  const relative=`${category}/${name}.png`;
  await fs.mkdir(path.dirname(path.join(output,relative)),{recursive:true});
  await sharp(extracted).resize(width-16,height-16,{fit:'contain',background:'#00000000'})
    .extend({top:8,bottom:8,left:8,right:8,background:'#00000000'})
    .png().toFile(path.join(output,relative));
  await register(id,relative,{provenance:'approved-atlas-export',source:path.relative(root,input).replaceAll('\\','/'),sourceRect:{left,top,width:cropWidth,height:cropHeight}});
}

await fs.mkdir(output,{recursive:true});
await fs.mkdir(source,{recursive:true});
const logoFile=path.join(root,'design/brand/bm-tower.svg');
const logoSvg=await fs.readFile(logoFile,'utf8');
const logoInner=logoSvg.slice(logoSvg.indexOf('<rect'),logoSvg.lastIndexOf('</svg>'));
for(const size of [24,32,48,64,128,256,512,1024]) {
  await fs.mkdir(path.join(output,'brand'),{recursive:true});
  const name=`mark-${size}.png`;
  await sharp(Buffer.from(logoSvg)).resize(size,size).png().toFile(path.join(output,'brand',name));
  await register(`brand.mark-${size}`,`brand/${name}`,{pivot:[0.5,0.5],provenance:'defined-bm-logo',source:'design/brand/bm-tower.svg'});
}
const wordmark=JSON.parse(await fs.readFile(path.join(source,'wordmark-paths.json'),'utf8'));
const outlineText=(text,x,y,size,maxWidth=Infinity)=>{
  const glyphs=[...text].map(c=>wordmark.glyphs[c]??wordmark.glyphs['?']);
  const advance=glyphs.reduce((sum,g)=>sum+g.width,0);
  const scale=Math.min(size/wordmark.units,maxWidth/Math.max(1,advance));
  let cursor=0;
  return group(`translate(${x} ${y}) scale(${scale} ${-scale})`,glyphs.map(g=>{const item=group(`translate(${cursor} 0)`,`<path d="${g.d}" fill="${C.ink}"/>`);cursor+=g.width;return item;}).join(''));
};
const titlePaths=wordmark.lines.map(row=>group(`translate(${row.x} ${row.y}) scale(${row.scale} ${-row.scale})`,row.paths.map(p=>group(`translate(${p.x} 0)`,`<path d="${p.d}" fill="${C.ink}"/>`)).join(''))).join('');
await draw('brand.title','brand','title',800,144,group('translate(0 8) scale(.25)',logoInner)+titlePaths,{pivot:[0,0.5],fontSource:'assets/fonts/Roboto.ttf'});

// The approved illustrations are exported without redesigning them.
const types=['apartment','hotel','office','food-court'];
for(let i=0;i<4;i++) await crop(`buildings.${types[i]}`,'buildings',types[i],'buildings',
  [i%2*.5,Math.floor(i/2)*.5,(1-i%2)*.5,(1-Math.floor(i/2))*.5],512,512);
const roomRects=[[.006,.154,.504,.504],[.504,.154,.006,.504],[.007,.505,.503,.153],[.503,.505,.006,.153]];
for(let i=0;i<4;i++) await crop(`rooms.${types[i]}`,'rooms',types[i],'interiors',roomRects[i],640,448);
const roleNames=['resident','guest','office','customer','maintenance','resident-walking-reference'];
for(let i=0;i<6;i++) await crop(`characters.${roleNames[i]}`,'characters',roleNames[i],'people',
  [i%3/3,Math.floor(i/3)/2,(2-i%3)/3,(1-Math.floor(i/3))/2],192,320);
const transportRects=[[.004,.135,.389,.521],[.618,.132,.004,.521],[.031,.502,.497,.129],[.512,.502,.024,.129]];
const transportNames=['parking-occupied','standard-lift','executive-lift','stairs'];
for(let i=0;i<4;i++) await crop(`transport.${transportNames[i]}`,'transport',transportNames[i],'transport',transportRects[i],i===0?640:448,448);
await fs.mkdir(path.join(output,'backgrounds'),{recursive:true});
await fs.copyFile(original('district'),path.join(output,'backgrounds/district-preview.png'));
await register('backgrounds.district-preview','backgrounds/district-preview.png',{pivot:[0.5,0.5],provenance:'approved-district-artwork',source:'design/tycoon/assets/district.png',usage:'Promotional scene only; never initialize saved buildings from this image.'});

// Isometric tiles share one projection. Tile dimensions are art units, not road rules.
const diamond=fill=>poly('130,4 258,68 130,132 2,68',fill,C.ink,1.5)
  +poly('2,68 130,132 130,144 2,80',C.grass,C.ink,1.5)
  +poly('130,132 258,68 258,80 130,144','#7E9B64',C.ink,1.5);
const iso=body=>group('matrix(1 .5 -1 .5 130 4)',`<defs><clipPath id="tile-mask"><rect width="128" height="128"/></clipPath></defs><g clip-path="url(#tile-mask)">${body}</g>`);
const sprouts=iso(line(24,28,22,24,'#90AC72',2)+line(24,28,28,25,'#90AC72',2)+line(94,88,94,82,'#90AC72',2)+line(94,88,98,84,'#90AC72',2));
await draw('tiles.land','tiles','land',260,148,diamond(C.land)+sprouts,{tileSize:[256,128],pivot:[0.5,132/148]});
for(const [name,color] of [['selected',C.green],['valid',C.green],['invalid',C.red],['reserved',C.amber]]) {
  await draw(`tiles.${name}`,'tiles',name,260,148,diamond(C.land)+poly('130,8 250,68 130,128 10,68',name==='invalid'?'#F8E4DC':C.mint,color,4),{tileSize:[256,128],pivot:[0.5,132/148]});
}
const ends=[[64,0],[128,64],[64,128],[0,64]];
for(let mask=0;mask<16;mask++) {
  let road=rect(0,0,128,128,C.cream,0,'none',0);
  if(mask===0) road+=circle(64,64,27,C.road,'none',0);
  for(let bit=0;bit<4;bit++) if(mask&(1<<bit)) road+=line(64,64,...ends[bit],C.road,58);
  road+=circle(64,64,29,C.road,'none',0);
  for(let bit=0;bit<4;bit++) if(mask&(1<<bit)) {
    const [x,y]=ends[bit];
    road+=line(64+(x-64)*.62,64+(y-64)*.62,64+(x-64)*.91,64+(y-64)*.91,C.paper,2);
  }
  const suffix=mask.toString(2).padStart(4,'0');
  await draw(`tiles.road-${suffix}`,'tiles',`road-${suffix}`,260,148,diamond(C.cream)+iso(road),
    {tileSize:[256,128],pivot:[.5,132/148],connections:{north:!!(mask&1),east:!!(mask&2),south:!!(mask&4),west:!!(mask&8)}});
}
for(let axis=0;axis<2;axis++) {
  let markings=rect(0,0,128,128,C.road,0,'none',0);
  for(let n=0;n<6;n++) markings+=axis===0?rect(32+n*11,16,5,96,C.paper,0,'none',0):rect(16,32+n*11,96,5,C.paper,0,'none',0);
  await draw(`tiles.crosswalk-${axis}`,'tiles',`crosswalk-${axis}`,260,148,diamond(C.cream)+iso(markings),{tileSize:[256,128],pivot:[.5,132/148]});
}

// Street fixtures are artwork only; their prices/unlocks are not decided here.
const tree=poly('128,107 166,126 128,145 90,126',C.cream)
  +rect(121,60,14,67,'#8D654B',2)+line(128,83,108,65,'#8D654B',7)
  +`<path d="M128 16C116 12 109 22 106 34C94 34 89 49 94 59C85 65 88 82 98 88C95 104 112 118 126 111C140 121 161 105 157 90C175 84 171 64 160 59C166 41 153 32 146 32C144 21 137 15 128 16Z" fill="${C.green}" stroke="${C.ink}" stroke-width="3"/>`
  +`<path d="M128 26C113 40 101 50 108 68C100 83 112 99 124 99C122 80 139 59 134 40Z" fill="${C.grass}"/>`;
await draw('decorations.tree','decorations','tree',256,164,tree);
await draw('decorations.planter','decorations','planter',192,192,
  poly('40,125 95,148 148,124 148,160 95,184 40,160',C.cream)
  +poly('40,125 95,100 148,124 95,148',C.paper)
  +`<path d="M96 137V50M96 90Q45 45 52 27Q87 36 96 90M96 111Q145 71 150 46Q107 49 96 111M96 70Q127 36 126 15Q100 25 96 70" fill="${C.green}" stroke="${C.ink}" stroke-width="3" stroke-linejoin="round"/>`);
await draw('decorations.hedge','decorations','hedge',256,148,
  poly('20,75 144,137 242,87 118,25',C.cream)
  +poly('20,51 144,113 242,63 118,1',C.green)
  +poly('20,51 144,113 144,137 20,75','#60894F')
  +poly('144,113 242,63 242,87 144,137',C.grass));
await draw('decorations.bench','decorations','bench',256,180,
  poly('25,103 157,169 229,133 97,67',C.cream)
  +line(57,102,57,143,C.ink,5)+line(175,143,175,176,C.ink,5)
  +poly('33,83 160,146 217,118 90,54','#B68758')
  +poly('33,33 160,96 160,132 33,69',C.amber)
  +line(44,48,148,100,'#A47845',2)+line(44,61,148,113,'#A47845',2));
await draw('decorations.streetlamp','decorations','streetlamp',128,256,
  poly('31,229 65,246 98,229 65,212',C.cream)+line(65,222,65,62,C.ink,7)
  +line(65,62,90,47,C.ink,6)+poly('72,31 105,31 112,54 66,54',C.paper)
  +rect(71,53,35,8,C.amber,3,C.ink,2));
await draw('decorations.table-set','decorations','table-set',256,200,
  line(128,114,128,175,C.ink,5)+poly('128,70 213,112 128,155 43,112',C.amber)
  +poly('128,70 213,112 213,118 128,161 43,118 43,112',C.cream)
  +line(51,150,51,191,C.ink,4)+line(191,160,191,195,C.ink,4)
  +poly('27,137 60,153 91,137 59,121',C.coral)+poly('160,150 194,167 226,151 192,134',C.coral)
  +circle(128,110,9,C.green)+rect(122,116,12,10,C.paper,1));

// Structural exterior pieces can repeat for any eventual floor count.
const wallColors=[C.amber,C.coral,C.blue,C.mint];
const floorBody=(type,lobby=false)=>{
  const index=types.indexOf(type),color=wallColors[index];
  const facade=side=>{
    let body=rect(0,0,120,48,color,0,'none',0)+rect(0,0,120,5,C.paper,0,'none',0);
    for(let n=0;n<4;n++) {
      const x=10+n*28;
      body+=rect(x,11,18,25,C.teal,0,C.paper,3)+line(x+9,12,x+9,35,C.ink,1);
      if(type==='apartment'||type==='hotel') body+=rect(x-2,34,22,5,C.paper,0,C.ink,1);
    }
    if(lobby && side===1) body+=rect(39,13,39,35,C.teal,0,C.paper,4)+line(58.5,14,58.5,47,C.ink,2);
    if(type==='food-court' && lobby) body+=rect(6,9,108,12,C.coral,0,C.paper,1);
    return body;
  };
  return poly('128,8 248,68 128,128 8,68',C.paper)
    +poly('8,68 128,128 128,176 8,116',color)
    +poly('128,128 248,68 248,116 128,176',color)
    +group('matrix(1 .5 0 1 8 68)',facade(0))
    +group('matrix(1 -.5 0 1 128 128)',facade(1));
};
const roofBody=(type,tier=1)=>{
  let body=poly('128,8 248,68 128,128 8,68',C.paper)
    +poly('128,18 228,68 128,118 28,68','#B3BAB4')
    +poly('8,68 128,128 128,137 8,77',C.cream)+poly('128,128 248,68 248,77 128,137',C.paper)
    +poly('110,44 146,62 118,76 82,58',C.paper)
    +poly('82,58 118,76 118,96 82,78',C.cream)+poly('118,76 146,62 146,82 118,96','#B9AF9B');
  if(tier>=2) body+=circle(176,67,8,C.green)+circle(62,69,8,C.green);
  if(tier===3) body+=poly('128,14 238,69 128,124 18,69','none',C.amber,3);
  return body;
};
for(const type of types) {
  for(const [name,body] of [['lobby',floorBody(type,true)],['floor',floorBody(type)],['roof',roofBody(type)]])
    await draw(`buildings.${type}-${name}`,'buildings',`${type}-${name}`,256,184,body,{floorStep:48,usage:'Repeatable structural module; art dimensions do not decide room capacity.'});
  for(let tier=1;tier<=3;tier++) {
    const floors=type==='food-court'?1:3;
    const shift=50*(floors-1)+10;
    let body=poly(`128,${shift+48} 254,${shift+111} 128,${shift+184} 2,${shift+111}`,C.cream);
    for(let floor=0;floor<floors;floor++) body+=group(`translate(0 ${shift-floor*48})`,floorBody(type,floor===0));
    body+=group(`translate(0 ${shift-(floors-1)*48})`,roofBody(type,tier));
    await draw(`buildings.${type}-luxury-${tier}`,'buildings',`${type}-luxury-${tier}`,256,shift+200,body,{luxuryTier:tier,usage:'Canonical visual preview only; stack modules for saved floor count.'});
  }
}
for(const [stage,body] of [
  ['foundation',diamond(C.cream)+iso(rect(18,18,92,92,'#D2C5B0',0,C.ink,2))],
  ['frame',diamond(C.cream)+line(42,90,42,35,C.ink,5)+line(130,133,130,78,C.ink,5)+line(218,90,218,35,C.ink,5)+line(42,35,130,78,C.amber,7)+line(130,78,218,35,C.amber,7)],
  ['fenced',diamond(C.cream)+iso(rect(8,8,112,112,'none',0,C.amber,7))+iso(line(8,8,120,120,C.ink,2))]
]) await draw(`buildings.construction-${stage}`,'buildings',`construction-${stage}`,260,148,body,{tileSize:[256,128],pivot:[.5,132/148]});

// Neutral structural cutaway, overlays and independent transport pieces.
for(let i=0;i<types.length;i++) {
  let body=rect(8,8,496,296,C.paper,5)+rect(44,42,424,212,wallColors[i],0,'none',0)
    +poly('16,12 496,12 468,42 44,42',C.cream)
    +poly('16,12 44,42 44,254 16,292',C.paper)
    +poly('496,12 468,42 468,254 496,292',C.cream)
    +poly('44,254 468,254 496,292 16,292','#CEAC82');
  for(let n=0;n<6;n++)body+=line(44+n*80,254,16+n*90,292,'#B58D62',1);
  body+=rect(181,62,198,146,C.teal,0,C.paper,8)
    +poly('186,70 265,70 186,145','#68C1CA','none',0)
    +poly('283,70 370,70 283,160','#68C1CA','none',0)
    +line(280,66,280,204,C.ink,3)+rect(174,210,212,10,C.paper,0)
    +rect(58,68,64,186,'#AD8256',0,C.ink,2)+rect(66,80,48,164,'none',0,'#8B6949',2)
    +line(109,165,109,181,C.ink,4)+rect(32,16,448,8,C.paper,0,'none',0);
  await draw(`rooms.${types[i]}-vacant-shell`,'rooms',`${types[i]}-vacant-shell`,512,320,body,{usage:'Unfurnished structural module. Lease state is a native UI overlay.'});
}
for(const [name,color] of [['selected',C.green],['blocked',C.red],['vacant',C.border]]) {
  let body=rect(6,6,500,308,'none',9,color,6);
  if(name==='blocked') for(let x=16;x<496;x+=30) body+=line(x,304,Math.min(496,x+120),184,color,2);
  await draw(`rooms.overlay-${name}`,'rooms',`overlay-${name}`,512,320,body,{pivot:[.5,.5],usage:'Place over rooms; no text or baked occupancy values.'});
}
const shaft=rect(12,8,168,304,C.cream,3)+rect(30,22,132,276,C.darkRoad,0,C.ink,2)
  +line(43,26,43,294,C.border,3)+line(149,26,149,294,C.border,3);
await draw('transport.lift-shaft','transport','lift-shaft',192,320,shaft);
for(const [name,color] of [['standard',C.teal],['executive',C.amber]]) {
  await draw(`transport.${name}-carriage`,'transport',`${name}-carriage`,160,224,
    rect(8,8,144,204,C.paper,4)+rect(20,24,120,170,color,2)+line(80,26,80,192,C.ink,2)+rect(28,199,104,7,C.darkRoad,1,'none',0));
  const frames=[];
  for(let n=0;n<5;n++) {
    const gap=n*17;
    const body=rect(12,8,168,304,C.paper,3)+rect(28,24,136,276,C.darkRoad,0)
      +rect(28,24,68-gap,276,color,0,C.ink,2)+rect(96+gap,24,68-gap,276,color,0,C.ink,2);
    const frame=await sharp(Buffer.from(svg(192,320,body))).png().toBuffer();frames.push({input:frame,left:n*192,top:0});
  }
  const rel=`transport/${name}-doors.png`;
  await sharp({create:{width:960,height:320,channels:4,background:'#00000000'}}).composite(frames).png().toFile(path.join(output,rel));
  await register(`transport.${name}-doors`,rel,{provenance:'authored-vector-animation',frameSize:[192,320],columns:5,rows:1,animations:{open:{frames:[0,1,2,3,4],fps:8,loop:false},close:{frames:[4,3,2,1,0],fps:8,loop:false}}});
}
await draw('transport.parking-empty','transport','parking-empty',640,320,
  rect(8,8,624,300,C.cream,4)+rect(28,28,584,216,'#A8AEA8',0,'none',0)+rect(28,244,584,48,C.road,0,'none',0)
  +line(28,83,612,83,C.amber,10)+line(225,200,225,282,C.paper,4)+line(415,200,415,282,C.paper,4)
  +rect(60,257,110,8,C.amber,2)+rect(266,257,110,8,C.amber,2)+rect(466,257,110,8,C.amber,2));
await draw('transport.car','transport','car',256,144,
  `<path d="M25 88L41 49Q52 28 84 28H147Q168 30 186 56L225 66Q240 68 240 91V112H16V96Z" fill="${C.blue}" stroke="${C.ink}" stroke-width="3"/>`
  +poly('58,40 93,40 93,69 44,69',C.teal)+poly('104,40 147,40 169,69 104,69',C.teal)
  +circle(63,111,19,C.darkRoad)+circle(192,111,19,C.darkRoad)+circle(63,111,10,C.border)+circle(192,111,10,C.border));

// Semantic icons are original vectors, with consistent contour weight.
const iconPaths={
  dollar:'M32 8V56M46 17C42 11 22 11 18 21C12 36 51 27 47 43C44 55 22 55 15 46',
  gem:'M12 23L22 10H42L52 23L32 54ZM12 23H52M22 10L25 23L32 54L39 23L42 10',
  parking:'M15 54V10H34C53 10 53 34 34 34H15',
  luxury:'M10 20L21 29L32 11L43 29L54 20L49 47H15ZM16 54H48',
  happy:'M32 12A20 20 0 1 0 32 52A20 20 0 1 0 32 12M22 25V28M42 25V28M23 38Q32 49 41 38',
  neutral:'M32 12A20 20 0 1 0 32 52A20 20 0 1 0 32 12M22 25V28M42 25V28M23 42H41',
  unhappy:'M32 12A20 20 0 1 0 32 52A20 20 0 1 0 32 12M22 25V28M42 25V28M23 45Q32 34 41 45',
  maintenance:'M42 10C30 7 24 20 31 29L12 48L20 56L39 37C49 42 60 30 54 19L46 27L37 18Z',
  tax:'M9 22L32 9L55 22ZM14 27V47M26 27V47M38 27V47M50 27V47M9 52H55',
  synergy:'M25 19L31 13C44 1 61 20 48 31L39 39M39 45L33 51C20 63 3 44 16 33L25 25M23 41L41 23',
  build:'M10 51L44 17M36 9L56 29M28 17L48 37M8 51L13 56',
  tenants:'M23 13A9 9 0 1 0 23 31A9 9 0 1 0 23 13M8 54V45Q8 35 23 35Q38 35 38 45V54M42 16Q55 16 55 27Q55 33 49 35M45 42Q57 42 57 53',
  upgrade:'M32 55V12M15 29L32 12L49 29M12 53H52',
  calendar:'M14 12H50V54H14ZM14 24H50M23 7V18M41 7V18M23 34H27M37 34H41M23 43H27M37 43H41',
  clock:'M32 10A22 22 0 1 0 32 54A22 22 0 1 0 32 10M32 18V33L43 40',
  sunday:'M14 12H50V54H14ZM14 24H50M23 7V18M41 7V18M23 40L29 46L42 32',
  lift:'M15 9H49V55H15ZM23 37L32 28L41 37M32 28V48M24 17H40',
  stairs:'M10 53H21V42H32V31H43V20H54M9 45L45 9M35 9H45V19',
  home:'M9 30L32 10L55 30M15 25V54H49V25M26 54V36H38V54',
  hotel:'M12 54V10H52V54M23 54V39H41V54M23 20H27M37 20H41M23 29H27M37 29H41',
  office:'M15 54V8H49V54M24 18H27M37 18H40M24 28H27M37 28H40M24 38H27M37 38H40M28 54V46H36V54',
  food:'M14 9V27Q14 34 24 34V55M24 9V55M34 9V27Q34 34 24 34M49 9V55M49 9Q39 23 49 31',
  road:'M22 8L12 56M42 8L52 56M32 11V20M32 28V37M32 45V54',
  locked:'M15 29H49V55H15ZM23 29V18Q23 6 32 6Q41 6 41 18V29M32 39V47',
  check:'M12 33L26 47L53 17',
  close:'M16 16L48 48M48 16L16 48',
  back:'M39 12L19 32L39 52',
  info:'M32 10A22 22 0 1 0 32 54A22 22 0 1 0 32 10M32 29V45M32 19V20',
  warning:'M32 9L57 53H7ZM32 25V37M32 44V45',
  achievement:'M20 10H44V27Q44 43 32 43Q20 43 20 27ZM20 16H9V23Q9 34 22 34M44 16H55V23Q55 34 42 34M32 43V53M21 55H43',
  decoration:'M16 55V29H48V55ZM12 29L32 8L52 29M24 55V41H40V55',
  sound:'M10 24H21L35 12V52L21 40H10ZM43 24Q50 32 43 40M49 16Q62 32 49 48',
  muted:'M10 24H21L35 12V52L21 40H10ZM44 23L57 41M57 23L44 41',
  save:'M12 10H44L53 19V54H12ZM22 10V27H43V10M22 54V38H43V54',
  empty:'M12 17H52V54H12ZM21 10H43M23 35H41M32 26V44'
};
for(const [name,d] of Object.entries(iconPaths)) {
  const accent=name==='gem'?C.blue:name==='dollar'||name==='luxury'?C.amber:C.mint;
  await draw(`icons.${name}`,'icons',name,64,64,
    circle(32,32,29,accent,'none',0)+`<path d="${d}" fill="none" stroke="${C.ink}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>`,{pivot:[.5,.5],minimumDisplaySize:24});
}

// Effects are sprite sheets with authored motion, not per-tap currency rewards.
for(const name of ['dust','coin','lift-arrival']) {
  const frames=[];
  for(let n=0;n<8;n++) {
    const p=n/7;
    let body='';
    if(name==='dust') for(let k=0;k<5;k++) body+=circle(26+k*18+(k-2)*p*5,92-p*28+(k%2)*8,5+Math.sin(p*Math.PI)*10,C.cream,'none',0);
    if(name==='coin') body=circle(64,86-p*52,19-p*3,C.amber,C.ink,2)+line(64,74-p*52,64,98-p*52,C.ink,2);
    if(name==='lift-arrival') body=circle(64,64,12+p*40,'none',C.amber,3)+line(47,64,60,76,C.green,4)+line(60,76,81,50,C.green,4);
    body=`<g opacity="${name==='dust'?Math.sin(Math.PI*(.05+.9*p)):(1-p*.85)}">${body}</g>`;
    const frame=await sharp(Buffer.from(svg(128,128,body))).png().toBuffer();
    frames.push({input:frame,left:n*128,top:0});
  }
  const relative=`effects/${name}.png`;await fs.mkdir(path.join(output,'effects'),{recursive:true});
  await sharp({create:{width:1024,height:128,channels:4,background:'#00000000'}}).composite(frames).png().toFile(path.join(output,relative));
  await register(`effects.${name}`,relative,{provenance:'authored-vector-animation',frameSize:[128,128],columns:8,rows:1,
    animations:{play:{frames:[0,1,2,3,4,5,6,7],fps:name==='dust'?12:10,loop:false}},usage:name==='coin'?'Play only after a financial closing, not per tap or per rent accrual.':'Visual feedback only.'});
}

// Empty land backgrounds are separate from the populated menu illustration.
for(const [name,w,h,tile] of [['empty-landscape',1920,1080,82],['empty-portrait',1080,1920,60]]) {
  let body=rect(0,0,w,h,C.bg,0,'none',0);
  const cx=w/2,cy=h/2-8*tile/2;
  for(let row=0;row<8;row++) for(let col=0;col<8;col++) {
    const x=cx+(col-row)*tile,y=cy+(row+col)*tile/2;
    body+=poly(`${x},${y} ${x+tile},${y+tile/2} ${x},${y+tile} ${x-tile},${y+tile/2}`,C.land,'#97B675',1.4);
  }
  await draw(`backgrounds.${name}`,'backgrounds',name,w,h,body,{pivot:[.5,.5],usage:'Illustrative empty viewport, not fixed district bounds.'});
}
for(const [name,color,opacity] of [['morning','#EFCF90',.08],['day','#FFFFFF',0],['afternoon','#DDA178',.12],['night','#153E52',.46],['noon','#E9B754',.04]]) {
  await draw(`backgrounds.phase-${name}`,'backgrounds',`phase-${name}`,32,32,`<rect width="32" height="32" fill="${color}" opacity="${opacity}"/>`,
    {pivot:[.5,.5],usage:'Stretch over world artwork only; native UI/text remain untinted.',allowEmpty:name==='day'});
}

// New raster animation artwork is supplied by the built-in image generator.
// Cell registration gives every frame a fixed canvas and a common foot baseline.
for(const role of roleNames.slice(0,5)) {
  const input=path.join(here,`animation_sources/${role}.png`);
  const grid=await spriteGrid(input),frames=[],cells=[];
  for(let i=0;i<16;i++) {
    const x=i%4,y=Math.floor(i/4),left=grid.x[x],top=grid.y[y];
    const width=grid.x[x+1]-left,height=grid.y[y+1]-top;
    const region=await sharp(input).extract({left,top,width,height}).png().toBuffer();
    const cell=await sharp(region).trim({threshold:8}).png().toBuffer();
    cells.push({cell,metadata:await sharp(cell).metadata()});
  }
  // One scale per actor, rather than enlarging/shrinking each pose independently.
  const scale=Math.min(224/Math.max(...cells.map(c=>c.metadata.width)),344/Math.max(...cells.map(c=>c.metadata.height)));
  for(let i=0;i<16;i++) {
    const {cell,metadata}=cells[i],x=i%4,y=Math.floor(i/4);
    const normalized=await sharp(cell).resize(Math.round(metadata.width*scale),Math.round(metadata.height*scale)).png().toBuffer();
    const cm=await sharp(normalized).metadata();
    const frame=await sharp({create:{width:256,height:384,channels:4,background:'#00000000'}})
      .composite([{input:normalized,left:Math.floor((256-cm.width)/2),top:364-cm.height}]).png().toBuffer();
    frames.push({input:frame,left:x*256,top:y*384});
  }
  const relative=`characters/${role}-animation.png`;
  await sharp({create:{width:1024,height:1536,channels:4,background:'#00000000'}}).composite(frames).png().toFile(path.join(output,relative));
  await register(`characters.${role}-animation`,relative,{provenance:'reference-guided-animation-export',source:path.relative(root,input).replaceAll('\\','/'),
    frameSize:[256,384],columns:4,rows:4,pivot:[.5,364/384],sourceGrid:grid,directions:{right:{flipX:false},left:{flipX:true}},
    animations:{idle:{frames:[0,1,2,3],fps:4,loop:true},walk:{frames:[4,5,6,7,8,9,10,11],fps:8,loop:true},stairs:{frames:[12,13,14,15],fps:6,loop:true}}});
}

// Deterministic PCM sound design lives in a separate, reproducible source.
const audioSpec=JSON.parse(await fs.readFile(path.join(here,'audio-spec.json'),'utf8'));
for(const item of audioSpec.assets) await register(`audio.${item.name}`,`audio/${item.name}.wav`,{provenance:'original-procedural-audio',source:'design/production/build_audio.py',...item});

catalog.sort((a,b)=>a.id.localeCompare(b.id));
const manifest={version:1,visualReference:'Approved Canva kit 2026-10-11',logoSourceSha256:crypto.createHash('sha256').update(logoSvg.replaceAll('\r\n','\n')).digest('hex'),
  palette:C,assets:catalog,notes:['Art geometry is not a gameplay balancing rule.','Malls, VIPs and future city integration are outside this current asset pack.','SFX/music are assets; playback/mute preferences still need application integration.']};
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');

const dartNames=new Set();
const constants=catalog.map(a=>{
  const name=a.id.split(/[.\-]/).map((p,i)=>i?p.charAt(0).toUpperCase()+p.slice(1):p).join('');
  if(dartNames.has(name))throw Error(`Duplicate Dart name ${name}`);dartNames.add(name);
  return `  static const ${name} = '${a.path}';`;
});
await fs.writeFile(path.join(root,'lib/app/production_assets.dart'),
  '// Generated by design/production/build.mjs. Do not edit individual paths.\nabstract final class ProductionAssets {\n  static const manifest = \'assets/game/manifest.json\';\n'+constants.join('\n')+'\n}\n');
const localDart=path.join(root,process.platform==='win32'?'.tools/flutter/bin/cache/dart-sdk/bin/dart.exe':'.tools/flutter/bin/cache/dart-sdk/bin/dart');
const dart=await fs.access(localDart).then(()=>localDart).catch(()=>'dart');
execFileSync(dart,['format','lib/app/production_assets.dart'],{cwd:root,stdio:'inherit'});

// Contact sheets use real generated assets, with captions outside the artwork.
const groups=[
  ['identity-world',a=>a.id.startsWith('brand.')||a.id.startsWith('backgrounds.')],
  ['buildings-rooms',a=>a.id.startsWith('buildings.')||a.id.startsWith('rooms.')],
  ['characters-transport',a=>a.id.startsWith('characters.')||a.id.startsWith('transport.')],
  ['tiles-icons-effects',a=>a.id.startsWith('tiles.')||a.id.startsWith('icons.')||a.id.startsWith('effects.')||a.id.startsWith('decorations.')]
];
const coverIds=['buildings.apartment','buildings.hotel','buildings.office','buildings.food-court','backgrounds.empty-landscape',
  'characters.resident-animation','characters.guest-animation','characters.office-animation','characters.customer-animation','characters.maintenance-animation',
  'tiles.road-0101','tiles.road-1010','tiles.road-0011','tiles.road-0111','tiles.road-1111',
  'icons.dollar','icons.gem','icons.sunday','transport.standard-lift','rooms.apartment'];
groups.unshift(['asset-overview',a=>coverIds.includes(a.id)]);
await fs.mkdir(path.join(here,'previews'),{recursive:true});
for(const [name,filter] of groups) {
  const items=catalog.filter(filter),cols=5,cw=280,ch=246,w=cols*cw+48,h=Math.ceil(items.length/cols)*ch+92;
  let captions=outlineText(name==='asset-overview'?'Building Management Tycoon - asset library':name.replaceAll('-',' / '),88,46,28,w-120);
  const images=[{input:await sharp(Buffer.from(logoSvg)).resize(48,48).png().toBuffer(),left:24,top:12}];
  for(let i=0;i<items.length;i++) {
    const a=items[i],x=24+(i%cols)*cw,y=76+Math.floor(i/cols)*ch;
    captions+=rect(x,y,cw-12,ch-12,C.paper,12,C.border,1)+outlineText(a.id,x+12,y+ch-29,14,cw-36);
    const firstFrame=a.frameSize?await sharp(path.join(root,a.path)).extract({left:0,top:0,width:a.frameSize[0],height:a.frameSize[1]}).png().toBuffer():path.join(root,a.path);
    const png=await sharp(firstFrame).resize(cw-40,ch-64,{fit:'inside',withoutEnlargement:true}).png().toBuffer();
    const dim=await sharp(png).metadata();
    images.push({input:png,left:x+Math.floor((cw-12-dim.width)/2),top:y+Math.floor((ch-54-dim.height)/2)});
  }
  await sharp(Buffer.from(svg(w,h,rect(0,0,w,h,C.bg,0,'none',0)+captions))).composite(images).png().toFile(path.join(here,'previews',`${name}.png`));
}
const grouped=Object.groupBy(catalog,a=>a.id.split('.')[0]);
let sections='';
for(const [category,items] of Object.entries(grouped)) {
  sections+=`<section id="${category}"><h2>${category}</h2><div class="grid">`;
  for(const a of items) {
    sections+=`<article><h3>${a.id}</h3>`;
    if(a.path.endsWith('.wav'))sections+=`<audio controls preload="none" src="../../${a.path}"></audio>`;
    else if(a.frameSize)sections+=`<canvas data-id="${a.id}" width="${a.frameSize[0]}" height="${a.frameSize[1]}"></canvas><select aria-label="Animation for ${a.id}">${Object.keys(a.animations).map(k=>`<option>${k}</option>`).join('')}</select>`;
    else sections+=`<img src="../../${a.path}" alt="${a.id}" loading="lazy">`;
    sections+=`<p>${a.frameSize?`${Object.keys(a.animations).join(' / ')}`:a.width?`${a.width} × ${a.height}`:`${a.seconds}s PCM`}</p><a href="../../${a.path}">Open asset</a></article>`;
  }
  sections+='</div></section>';
}
await fs.writeFile(path.join(here,'gallery.html'),`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>BM game assets</title><style>body{margin:0;background:${C.bg};color:${C.ink};font:16px system-ui}main{max-width:1440px;margin:auto;padding:32px}header{display:flex;gap:24px;align-items:center}header img{width:64px}nav{position:sticky;top:0;background:${C.bg};padding:16px 0;display:flex;gap:16px;flex-wrap:wrap;z-index:2}a{color:${C.green}}section{scroll-margin-top:72px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:16px}article{background:${C.paper};border:1px solid ${C.border};border-radius:18px;padding:16px;overflow:hidden}h3{font-size:14px;overflow-wrap:anywhere}article img,canvas{width:100%;height:220px;object-fit:contain;background:repeating-conic-gradient(#e6e9df 0% 25%,#f9faf6 0% 50%) 50%/20px 20px}audio{width:100%}select,button{font:inherit;padding:8px;border-radius:8px;border:1px solid ${C.border};background:${C.paper};color:${C.ink}}</style><main><header><img src="../../assets/game/brand/mark-128.png" alt="BM"><div><h1>Building Management Tycoon</h1><p>Repository asset library · ${catalog.length} assets · approved BM identity</p></div></header><nav>${Object.keys(grouped).map(c=>`<a href="#${c}">${c}</a>`).join('')}<button id="motion">Pause animations</button></nav>${sections}</main><script>const manifest=${JSON.stringify(manifest)};let motion=!matchMedia('(prefers-reduced-motion:reduce)').matches;const controls=document.getElementById('motion');controls.textContent=motion?'Pause animations':'Play animations';controls.onclick=()=>{motion=!motion;controls.textContent=motion?'Pause animations':'Play animations'};for(const canvas of document.querySelectorAll('canvas')){const a=manifest.assets.find(x=>x.id===canvas.dataset.id),img=new Image,select=canvas.parentElement.querySelector('select');img.src='../../'+a.path;const ctx=canvas.getContext('2d');function render(time){const seq=a.animations[select.value],i=motion?Math.floor(time/1000*seq.fps)%seq.frames.length:0,frame=seq.frames[i],x=(frame%a.columns)*a.frameSize[0],y=Math.floor(frame/a.columns)*a.frameSize[1];ctx.clearRect(0,0,canvas.width,canvas.height);if(img.complete&&img.naturalWidth)ctx.drawImage(img,x,y,...a.frameSize,0,0,...a.frameSize);requestAnimationFrame(render)}requestAnimationFrame(render)}</script></html>`);
console.log(`Exported ${catalog.length} game assets, manifest, Dart catalog and galleries.`);
