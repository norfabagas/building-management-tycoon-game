import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
const root=path.dirname(fileURLToPath(import.meta.url)),workspace=path.resolve(root,'../..');
const runtime='C:/Users/bgsno/.cache/codex-runtimes/codex-primary-runtime/dependencies';
const skill='C:/Users/bgsno/.codex/plugins/cache/openai-primary-runtime/presentations/26.1009.11318/skills/presentations';
process.env.RUNTIME_NODE_MODULES=`${runtime}/node/node_modules`;
const {Presentation,PresentationFile}=await import(pathToFileURL(`${runtime}/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs`));
const {finalizePresentation}=await import(pathToFileURL(`${skill}/container_tools/artifact_tool_utils.mjs`));
const require=createRequire(`${runtime}/node/package.json`),sharp=require('sharp');
const W=1600,H=1000,FONT='Trebuchet MS';
const C={bg:'#F5F3EB',paper:'#FFFCF1',ink:'#203B3A',muted:'#66766D',line:'#CAD2C6',green:'#237563',dark:'#185343',mint:'#DBEBDD',land:'#BBD995',amber:'#E9B754',coral:'#E98D70',blue:'#65B1C5',gray:'#E2E5DE',red:'#AF443F',paleRed:'#F8E4DC',white:'#FFFFFF'};
const assets={};for(const n of ['buildings','interiors','people','transport','district'])assets[n]=await fs.readFile(path.join(root,`assets/${n}.png`));
assets.logo=await fs.readFile(path.join(workspace,'design/brand/bm-tower.png'));
const titles=['Game identity','Building exteriors','District tiles and placement','Rooms and transport','Residents and visitors','Controls and navigation','Local profiles','CBD map','Construction / building type','Construction / land footprint','Construction / floors and review','Building and floor management','Tenants and parking','Building upgrades','Daily finances','Portrait, landscape and web'];
const pres=Presentation.create({slideSize:{width:W,height:H}});let s,serial=0;const evidence=[];
function box(x,y,w,h,fill=C.paper,stroke=C.line,r=12,sw=2){if(x<0||y<0||x+w>W+.1||y+h>H+.1)throw Error(`Outside board ${pres.slides.items.length}: ${x},${y},${w},${h}`);return s.shapes.add({geometry:'rect',name:`ui-${++serial}`,position:{left:x,top:y,width:w,height:h},fill,line:{fill:stroke,style:'solid',width:stroke==='none'?0:sw},borderRadius:r});}
function txt(t,x,y,w,size=22,color=C.ink,bold=false,align='left',h=size*1.4){const o=box(x,y,w,h,'none','none',0);o.text=t;o.text.style={typeface:FONT,fontSize:size,color,bold,alignment:align,verticalAlignment:'middle',insets:0};evidence.push({page:pres.slides.items.length,text:t,x,y,w,h});return o;}
const rule=(x,y,w)=>box(x,y,w,1,C.line,'none',0);
function img(key,x,y,w,h,crop,alt=key){const o=s.images.add({blob:assets[key],contentType:'image/png',alt,position:{left:x,top:y,width:w,height:h},fit:'contain',...(crop?{crop}:{})});return o;}
const quad=i=>({left:i%2*.5,top:Math.floor(i/2)*.5,right:(1-i%2)*.5,bottom:(1-Math.floor(i/2))*.5});
const bld=(i,x,y,w=300,h=300)=>img('buildings',x,y,w,h,quad(i),['Apartment exterior','Hotel exterior','Office exterior','Food court exterior'][i]);
const roomRects=[[.006,.154,.504,.504],[.504,.154,.006,.504],[.007,.505,.503,.153],[.503,.505,.006,.153]];
function room(i,x,y,w=280,h=195){const [left,top,right,bottom]=roomRects[i];return img('interiors',x,y,w,h,{left,top,right,bottom},['Apartment room','Hotel room','Whole-floor office suite','Food court'][i]);}
function person(i,x,y,w=128,h=200){return img('people',x,y,w,h,{left:i%3/3,right:(2-i%3)/3,top:Math.floor(i/3)/2,bottom:(1-Math.floor(i/3))/2},['Resident','Hotel guest','Office tenant','Customer','Maintenance worker','Resident walking'][i]);}
const transportRects=[[.004,.135,.389,.521],[.618,.132,.004,.521],[.031,.502,.497,.129],[.512,.502,.024,.129]];
function transport(i,x,y,w,h){const [left,top,right,bottom]=transportRects[i];return img('transport',x,y,w,h,{left,top,right,bottom},['Basement parking','Standard lift','Executive lift','Stairs'][i]);}
function button(label,x,y,w=220,state='primary'){const fill=state==='disabled'?C.gray:state==='secondary'?C.paper:state==='pressed'?C.dark:C.green;const color=state==='disabled'?C.muted:state==='secondary'?C.ink:C.paper;box(x,y+4,w,52,state==='disabled'?C.line:C.ink,'none',12);box(x,y,w,52,fill,state==='disabled'?C.line:C.ink,12,2);txt(label,x+12,y+8,w-24,22,color,true,'center',34);if(state==='focus')box(x-5,y-5,w+10,66,'none',C.ink,16,2);}
function label(t,x,y,w=160,fill=C.mint,color=C.green){box(x,y,w,34,fill,'none',8);txt(t,x+10,y+5,w-20,17,color,true,'center',24);}
function input(t,value,x,y,w=400,error=false,focus=false){txt(t,x,y,w,18,C.muted);box(x,y+34,w,58,C.white,error?C.red:focus?C.green:C.line,10,focus?3:2);txt(value,x+16,y+46,w-32,23);}
function row(t,v,x,y,w=400){txt(t,x,y,w*.6,21,C.muted);txt(v,x+w*.56,y,w*.44,22,C.ink,true,'right');rule(x,y+44,w);}
function bar(x,y,w,p,color=C.green){box(x,y,w,12,C.gray,'none',6);box(x,y,w*p,12,color,'none',6);}
function panel(title,x,y,w,h){box(x,y,w,h,C.paper,C.line,18);txt(title,x+24,y+20,w-48,26,C.ink,true);rule(x+24,y+68,w-48);}
function start(i){s=pres.slides.add();s.background.fill=C.bg;img('logo',48,28,48,48,undefined,'Defined square BM tower mark');txt('Building Management Tycoon',112,32,1050,27,C.ink,true);txt(`${String(i+1).padStart(2,'0')} / 16`,1424,34,128,18,C.muted,false,'right');rule(48,96,1504);txt(`${String(i+1).padStart(2,'0')}  ${titles[i]}`,48,120,1504,39,C.ink,true,'left',60);txt('Game design reference. Economy values and district names are examples.',48,950,1456,16,C.muted);}
function hud(x,y,w){box(x,y,w,76,C.paper,C.ink,16);img('logo',x+16,y+16,40,40);txt('Central District',x+72,y+12,w*.36,25,C.ink,true);txt('Day 12 / Morning',x+72,y+44,w*.36,17,C.muted);txt('$12,000',x+w-410,y+21,170,28,C.ink,true,'right');label('80 gems',x+w-206,y+23,180,C.mint,C.green);}
function nav(x,y,w){box(x,y,w,72,C.paper,C.ink,16);['Build','Tenants','Upgrades'].forEach((t,i)=>button(t,x+16+i*(w-32)/3,y+9,(w-56)/3,i===0?'primary':'secondary'));}
function district(x,y,w,h){return img('district',x,y,w,h,undefined,'Isometric Central Business District with four building types and empty land');}
function grid(x,y,cell,cols,rows,selected=false){for(let r=0;r<rows;r++)for(let c=0;c<cols;c++){const active=selected&&c>=1&&c<=3&&r>=1&&r<=2;s.shapes.add({geometry:'diamond',name:`plot-${++serial}`,position:{left:x+(rows-1-r+c)*cell*.5,top:y+(r+c)*cell*.25,width:cell,height:cell*.5},fill:active?C.mint:C.land,line:{fill:active?C.green:'#97B675',style:'solid',width:active?3:1.5}});}}

// 01 / Identity begins with the actual game world.
start(0);img('logo',64,264,112,112);txt('Building Management\nTycoon',64,412,592,56,C.ink,true,'left',150);txt('Build and manage your district.',64,598,568,27,C.muted);button('Start a district',64,708,292);district(628,218,924,580);txt('2D district map',672,838,350,22,C.ink,true);txt('Floor-by-floor management',1084,838,444,22,C.ink,true);

// 02 / Readable silhouettes and fixed material colors.
start(1);['Apartment','Hotel','Office tower','Food court'].forEach((name,i)=>{const x=48+i*384;bld(i,x+8,236,352,352);txt(name,x,630,352,30,C.ink,true);box(x,688,64,8,[C.amber,C.coral,C.blue,C.mint][i],'none',4);txt(['Long-term room rentals','Daily room occupancy','Whole-floor corporate leases','Daily customer sales'][i],x,728,352,21,C.muted,false,'left',64);});rule(48,824,1504);txt('Shared view angle, outlines, roof materials and window treatment.',48,852,1504,22,C.muted);

// 03 / Native placement components remain separate from scenery.
start(2);district(48,214,880,504);txt('Office + food court',72,744,720,27,C.ink,true);label('+30% sales example',72,792,272,C.mint,C.green);
txt('Placement grid',1008,228,480,28,C.ink,true);grid(1008,340,112,5,4,true);label('3 × 2 plots',1008,712,220);txt('Drag across empty land.',1008,768,480,22,C.muted);box(1008,830,480,64,C.paleRed,'none',12);txt('Overlap: choose another plot.',1028,846,440,20,C.red,true);

// 04 / Architecture assets use a common cutaway module.
start(3);['Apartment room','Hotel room','Office floor lease','Food court'].forEach((name,i)=>{const x=48+i*384;room(i,x,234,352,250);txt(name,x,510,352,26,C.ink,true);});rule(48,576,1504);
transport(0,48,632,424,244);txt('Basement parking',48,896,424,20,C.ink,true);transport(1,552,636,200,240);txt('Standard lift',528,896,248,20,C.ink,true,'center');transport(2,856,636,200,240);txt('Executive lift',832,896,248,20,C.ink,true,'center');transport(3,1160,636,344,240);txt('Default stairs',1160,896,344,20,C.ink,true,'center');

// 05 / Roles and the walking pose use the same sprite sheet.
start(4);['Resident','Hotel guest','Office tenant','Customer','Maintenance','Walking pose'].forEach((name,i)=>{const x=48+i*256;person(i,x+32,244,176,296);txt(name,x,574,232,24,C.ink,true,'center');});rule(48,654,1504);txt('Tenant needs',48,706,320,30,C.ink,true);label('Happy',432,708,256);label('Needs a lift',736,708,256,C.amber,C.ink);label('Parking full',1040,708,288,C.paleRed,C.red);txt('Lift access affects happiness. Parking limits new occupancy.',432,808,1080,24,C.muted);

// 06 / Tactile controls share exact geometry across screens.
start(5);hud(48,220,1504);['Default','Pressed','Focused','Disabled'].forEach((t,i)=>{const x=48+i*384;txt(t,x,348,352,22,C.muted);button('Build',x,398,336,['primary','pressed','focus','disabled'][i]);});
input('District name','Central District',48,536,464);input('District name','Central District',560,536,464,false,true);input('District name','',1072,536,480,true);txt('Enter a district name.',1072,640,480,18,C.red);nav(48,738,736);txt('Morning / Day / Afternoon / Night / Noon',48,858,760,23,C.muted);txt('Achievement progress',840,730,384,25,C.ink,true);txt('320 / 1,000',1248,730,280,23,C.muted,false,'right');bar(840,790,688,.32);txt('Earn gems offline.',840,844,330,22,C.muted);button('Decorations',1200,832,328,'secondary');

// 07 / Exactly five locally stored profiles.
start(6);district(48,250,696,392);img('logo',80,710,72,72);txt('Building Management Tycoon',172,714,540,27,C.ink,true);txt('Progress saves on this device.',80,826,600,23,C.muted);
panel('Choose a district',792,220,760,684);for(let i=0;i<5;i++){const y=320+i*110;box(816,y,712,88,i===0?C.mint:C.white,i===0?C.green:C.line,12);txt(String(i+1).padStart(2,'0'),836,y+24,64,27,C.ink,true);txt(i===0?'Central District':i===1?'Riverside':'Empty slot',916,y+14,376,24,C.ink,true);txt(i<2?'Saved on this device':'Start a new district',916,y+48,376,17,C.muted);button(i<2?'Load':'New',1344,y+16,160,i===0?'primary':'secondary');}

// 08 / Gameplay fills the screen behind contextual controls.
start(7);box(48,212,1504,688,C.bg,C.ink,20);district(72,302,944,536);hud(72,232,1456);panel('North Offices',1048,336,456,460);label('Office tower',1072,424,192,C.blue,C.ink);row('Leased floors','2 / 4',1072,496,408);row('Parking','60 / 100',1072,558,408);row('Projected net','+$600',1072,620,408);button('View building',1072,710,408);nav(72,808,912);

// 09 / Building selection uses the same exterior sprites.
start(8);txt('1  Type     2  Footprint     3  Floors     4  Review',48,216,1504,24,C.muted);['Apartment','Hotel','Office tower','Food court'].forEach((name,i)=>{const x=48+i*384;box(x,280,352,612,C.paper,i===0?C.green:C.line,18,i===0?3:2);bld(i,x+20,306,312,312);txt(name,x+24,650,304,27,C.ink,true);txt(['Rooms','Daily rooms','Floor leases','Customer sales'][i],x+24,702,304,21,C.muted);button(i===0?'Selected':'Select',x+24,804,304,i===0?'primary':'secondary');});

// 10 / Every type needs a manually drawn footprint.
start(9);txt('1  Type     2  Footprint     3  Floors     4  Review',48,216,1504,24,C.muted);box(48,278,936,612,C.paper,C.ink,18);grid(88,328,128,8,5,true);label('3 × 2 plots',88,770,264);txt('Drag across empty plots to set the land area.',88,840,848,21,C.muted);
panel('Apartment footprint',1016,278,536,612);bld(0,1216,354,160,160);row('Width','3 plots',1040,534,488);row('Length','2 plots',1040,596,488);label('Valid footprint',1040,674,240);button('Use this footprint',1040,750,488);txt('Back keeps your plan.',1040,840,488,18,C.muted);

// 11 / Floor entry, calculated capacity and cost review.
start(10);txt('1  Type     2  Footprint     3  Floors     4  Review',48,216,1504,24,C.muted);panel('Above-ground floors',48,280,472,608);input('Number of floors','4',72,388,424);button('−',72,516,96,'secondary');button('+',400,516,96,'secondary');row('Footprint','3 × 2',72,616,424);row('Room capacity','Calculated',72,686,424);txt('Rooms follow the footprint.',72,794,424,21,C.muted);
panel('Apartment',552,280,472,608);bld(0,588,378,400,400);txt('Sizing stays fixed after building.',576,814,424,20,C.muted);
panel('Review construction',1056,280,496,608);row('Construction cost','Estimate',1080,388,448);row('Daily upkeep','Estimate',1080,456,448);row('Current funds','$12,000',1080,524,448);label('Footprint and floors lock',1080,612,448,C.amber,C.ink);button('Confirm construction',1080,714,448);txt('Review the estimate before building.',1080,810,448,18,C.muted);

// 12 / Side-view cutaway: rooms above ground, parking below.
start(11);box(48,220,960,680,C.paper,C.ink,18);txt('Amber Apartments',72,240,640,27,C.ink,true);txt('Tap a room / drag to pan',72,286,640,18,C.muted);for(let i=0;i<4;i++){const y=316+i*144;txt(i<3?String(3-i).padStart(2,'0'):'B1',72,y+54,56,22,C.ink,true);if(i<3){room(0,148,y,216,144);room(0,372,y,216,144);transport(1,620,y,160,144);transport(3,812,y,156,144);}else{transport(0,148,y,264,144);transport(0,424,y,264,144);}}box(142,458,228,148,'none',C.green,8,4);
panel('Floor 02 / Room 0201',1040,220,512,680);room(0,1064,326,464,252);label('Occupied',1064,602,192);row('Tenant','Maya',1064,668,464);row('Parking','Available',1064,734,464);button('View tenant',1064,814,464);

// 13 / Tenant context preserves the capacity constraint.
start(12);panel('Maya / Apartment resident',48,220,736,680);person(0,88,326,208,360);room(0,332,368,404,260);label('Happy',88,724,192);txt('Room 0201 / Amber Apartments',88,802,632,24,C.ink,true);
panel('Parking capacity',816,220,736,680);transport(0,860,324,648,284);row('Used spaces','80 / 100',840,642,688);bar(840,706,688,.8);box(840,766,688,98,C.paleRed,'none',12);txt('At full capacity, new occupancy stops.',860,776,648,22,C.red,true);txt('Expand parking before adding tenants.',860,820,648,20,C.red);

// 14 / Upgrade benefits sit beside daily maintenance.
start(13);[['Luxury','Rating upgrades','Level example'],['Parking','Basements only','0 / 3 levels'],['Standard lift','Better floor access','0 / 3 lifts'],['Executive lift','Executive access','1 / 1 lift']].forEach(([a,b,c],i)=>{const x=48+i*384;box(x,224,352,668,C.paper,C.line,18);txt(a,x+24,248,304,27,C.ink,true);if(i===0)bld(0,x+40,314,272,272);else transport(i===1?0:i===2?1:2,x+24,340,304,236);txt(c,x+24,610,304,24,C.ink,true);txt(b,x+24,660,304,21,C.muted);txt('Cost: estimate',x+24,706,304,20,C.muted);txt('Daily upkeep: estimate',x+24,746,304,19,C.muted);button(i===3?'Maximum reached':'Review upgrade',x+24,818,304,i===3?'disabled':'primary');});

// 15 / Daily and offline net include expenses and taxes.
start(14);['Noon closing','Offline return','Loss day'].forEach((t,i)=>panel(t,48+i*512,220,480,680));
[['$1,000','−$300','−$100','+$600'],['$2,000','−$600','−$200','+$1,200'],['$200','−$300','−$100','−$200']].forEach((vals,i)=>{const x=72+i*512;label(i===1?'2 simulated days':i===0?'Day 12':'Day example',x,328,240);['Gross revenue','Maintenance','Tax'].forEach((t,j)=>row(t,vals[j],x,416+j*72,432));txt('Net',x,650,432,21,C.muted);txt(vals[3],x,690,432,52,i===2?C.red:C.green,true);txt(i===1?'Already applied to your balance.':i===0?'Added at daily closing.':'Deducted at daily closing.',x,786,432,20,C.muted);button('Continue',x,830,432);});

// 16 / Shared artwork and controls, rearranged for viewport shape.
start(15);txt('Portrait',48,220,360,26,C.ink,true);txt('Landscape',440,220,520,26,C.ink,true);txt('Web / tablet',992,220,560,26,C.ink,true);
box(48,270,360,624,C.paper,C.ink,20);img('logo',64,290,36,36);txt('Central District',112,290,280,23,C.ink,true);txt('$12,000 / 80 gems',64,348,328,19);txt('Day 12 / Morning',64,386,328,17,C.muted);district(64,432,328,184);box(64,636,328,162,C.paper,C.line,12);txt('North Offices',80,650,296,22,C.ink,true);txt('Parking 60 / 100',80,696,296,18,C.muted);button('View building',80,738,296);txt('Build      Tenants      Upgrades',64,840,328,18,C.ink,true,'center');
box(440,270,520,294,C.paper,C.ink,18);txt('Central District',456,284,312,20,C.ink,true);txt('$12,000',780,284,164,20,C.ink,true,'right');district(452,338,292,200);box(756,330,188,218,C.paper,C.line,12);txt('North Offices',772,344,156,19,C.ink,true);txt('Parking\n60 / 100',772,394,156,18,C.muted,false,'left',54);button('View',772,478,156);
box(992,270,560,386,C.paper,C.ink,18);txt('Central District',1008,286,324,22,C.ink,true);txt('$12,000',1344,286,192,22,C.ink,true,'right');district(1008,370,304,224);box(1328,346,208,292,C.paper,C.line,12);txt('North Offices',1344,360,176,20,C.ink,true);txt('2 / 4 floors',1344,418,176,18,C.muted);txt('60 / 100 parking',1344,466,176,18,C.muted);button('View building',1344,550,176);
txt('Same world, same controls',440,724,1112,30,C.ink,true);txt('Portrait opens a bottom sheet. Wide views use a side panel.',440,790,1112,23,C.muted);txt('Selection and construction plans survive rotation.',440,848,1112,23,C.muted);

await fs.mkdir(path.join(root,'previews'),{recursive:true});await fs.mkdir(path.join(root,'.build'),{recursive:true});await fs.mkdir(path.join(root,'output'),{recursive:true});
for(let i=0;i<pres.slides.items.length;i++){const png=await pres.export({slide:pres.slides.items[i],format:'png',scale:1});await fs.writeFile(path.join(root,'previews',String(i+1).padStart(2,'0')+'.png'),new Uint8Array(await png.arrayBuffer()));console.log(`Rendered ${i+1}/16`);}
const tiles=await Promise.all(Array.from({length:16},async(_,i)=>({input:await sharp(path.join(root,'previews',String(i+1).padStart(2,'0')+'.png')).resize(400,250).toBuffer(),left:16+i%4*408,top:16+Math.floor(i/4)*258})));await sharp({create:{width:1648,height:1048,channels:4,background:C.line}}).composite(tiles).png().toFile(path.join(root,'overview.png'));
const authored=path.join(root,'.build','authored.pptx'),candidate=path.join(root,'.build','candidate.pptx');await (await PresentationFile.exportPptx(pres)).save(authored);
execFileSync(`${runtime}/python/python.exe`,[path.join(root,'optimize_pptx.py'),authored,candidate],{stdio:'inherit'});
await fs.writeFile(path.join(root,'.build','geometry.json'),JSON.stringify(evidence,null,2));
const revision=process.argv[2]||'r1';if(!/^[a-z0-9-]+$/i.test(revision))throw Error('Invalid revision');
const final=path.join(root,'output',`Building-Management-Tycoon-${revision}.pptx`);
const result=await finalizePresentation({workspaceDir:workspace,candidatePath:candidate,finalPath:final,explicitTotalSlideCount:16,pythonExecutable:`${runtime}/python/python.exe`,integrityValidatorPath:`${skill}/container_tools/inspect_presentation_package_integrity.py`,layoutValidatorPath:`${skill}/container_tools/inspect_presentation_layout_geometry.py`,layoutArgs:['--expected-slide-size-emu','15240000,9525000','--validate-heading-fit'],requiredNativeTableOwnerSlides:[],fontPolicy:{basis:'design',families:[FONT]},verifyArtifactToolImport:true,receiptPath:path.join(root,'.build',`validation-${revision}.json`)});
console.log(JSON.stringify(result));
