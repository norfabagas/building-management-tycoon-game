import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const root = path.dirname(fileURLToPath(import.meta.url));
const workspace = path.resolve(root, '../..');
const runtime = 'C:/Users/bgsno/.cache/codex-runtimes/codex-primary-runtime/dependencies';
process.env.RUNTIME_NODE_MODULES=`${runtime}/node/node_modules`;
const skill = 'C:/Users/bgsno/.codex/plugins/cache/openai-primary-runtime/presentations/26.1007.11041/skills/presentations';
const { Presentation, PresentationFile } = await import(pathToFileURL(`${runtime}/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs`));
const { finalizePresentation } = await import(pathToFileURL(`${skill}/container_tools/artifact_tool_utils.mjs`));
const C = {bg:'#F5F3EB', ink:'#203B3A', muted:'#657B77', line:'#D7DED7', white:'#FFFFFF', green:'#237563', mint:'#E6EFE8', land:'#D9E8CF', apartment:'#EDC879', hotel:'#B7A9D3', office:'#8EB9D0', food:'#E9A08B', red:'#B94343', paleRed:'#F7E9E7', gray:'#EBEDE8'};
const W=1600,H=1000;
const pres=Presentation.create({slideSize:{width:W,height:H}});
const brandBytes=await fs.readFile(path.join(workspace,'design/brand/bm-tower.png'));
const titles=['Foundations','Interaction states','Map components','Interiors and transport','Local profiles','CBD map','Building types','Land footprint','Floors and capacity','Construction review','Building cross-section','Rooms and floor leases','Tenants and visitors','Building upgrades','Daily finances','Portrait, landscape and web'];
let s, serial=0; const evidence=[];
function shape(g,x,y,w,h,fill=C.white,stroke='none',radius=0){
  if(x<0||y<0||x+w>W+.1||y+h>H+.1)throw Error(`Bounds ${serial}: ${x},${y},${w},${h}`);
  return s.shapes.add({geometry:g,name:`component-${++serial}`,position:{left:x,top:y,width:w,height:h},fill,line:{fill:stroke,style:'solid',width:stroke==='none'?0:1},...(radius?{borderRadius:radius}:{})});
}
const rect=(x,y,w,h,f=C.white,stroke='none',r=0)=>shape('rect',x,y,w,h,f,stroke,r);
const circle=(x,y,size,f)=>shape('ellipse',x,y,size,size,f);
function text(t,x,y,w,size=22,color=C.ink,bold=false,align='left',h=size*1.55){const o=shape('textbox',x,y,w,h,'none');o.text=t;o.text.style={typeface:'Arial',fontSize:size,color,bold,alignment:align,verticalAlignment:'middle',insets:0};evidence.push({page:pres.slides.items.length,text:t,x,y,w,h});return o;}
const line=(x,y,w,color=C.line)=>rect(x,y,w,1,color);
function btn(t,x,y,w=180,type='primary'){const f=type==='primary'?C.green:type==='pressed'?C.ink:type==='disabled'?C.gray:C.white;rect(x,y,w,48,f,type==='secondary'?C.line:'none',8);text(t,x+12,y+8,w-24,20,type==='primary'||type==='pressed'?C.white:type==='disabled'?C.muted:C.ink,true,'center',32);}
function tag(t,x,y,w=120,type='neutral'){rect(x,y,w,32,type==='error'?C.paleRed:type==='active'?C.mint:C.gray,'none',4);text(t,x+10,y+4,w-20,16,type==='error'?C.red:type==='active'?C.green:C.muted,true,'center',24);}
function field(label,value,x,y,w=400,error=false){text(label,x,y,w,18,C.muted);rect(x,y+34,w,56,C.white,error?C.red:C.line,8);text(value,x+16,y+43,w-32,22);}
function panel(title,x=48,y=220,w=480,h=680){rect(x,y,w,h,C.white,C.line,12);text(title,x+24,y+20,w-48,24,C.ink,true);line(x+24,y+66,w-48);}
function row(label,value,x,y,w=432){text(label,x,y,w*.64,20,C.muted);text(value,x+w*.6,y,w*.4,20,C.ink,true,'right');line(x,y+42,w);}
function progress(x,y,w,pct,color=C.green){rect(x,y,w,8,C.gray,'none',4);rect(x,y,w*pct,8,color,'none',4);}
function start(index){s=pres.slides.add();s.background.fill=C.bg;const b=brandBytes.buffer.slice(brandBytes.byteOffset,brandBytes.byteOffset+brandBytes.byteLength);s.images.add({blob:b,contentType:'image/png',alt:'BM tower icon',position:{left:48,top:32,width:48,height:48}});text('Building Management Tycoon',112,36,800,26,C.ink,true);text(String(index+1).padStart(2,'0')+' / 16',1424,40,128,18,C.muted,false,'right');line(48,104,1504);text(String(index+1).padStart(2,'0')+' · '+titles[index],48,128,1480,44,C.ink,true, 'left',64);text('Design reference. Sample values are illustrative.',48,948,1200,16,C.muted);}
function facade(type,x,y,w=180,h=180){const color=C[type];rect(x,y,w,h,color,C.ink,4);rect(x+8,y+8,w-16,24,C.white);text(type==='food'?'F&B':type.toUpperCase(),x+8,y+8,w-16,14,C.ink,true,'center',24);const rows=type==='food'?2:4;for(let r=0;r<rows;r++)for(let c=0;c<3;c++)rect(x+16+c*(w-32)/3,y+48+r*(h-64)/rows,(w-56)/3,Math.max(10,(h-88)/rows),C.white);rect(x+w/2-12,y+h-24,24,24,C.ink);}
function plot(type,x,y,sz=96,selected=false){rect(x,y,sz,sz,C.land,selected?C.green:C.line,4);if(type){const tall=type==='office'||type==='hotel';const bx=x+sz*(tall?.22:.15),by=y+sz*(type==='food'?.30:.15),bw=sz*(tall?.56:.70),bh=sz*(type==='food'?.50:.70);rect(bx,by,bw,bh,C[type],C.ink,3);const n=type==='office'?3:type==='hotel'?2:1;for(let i=0;i<n;i++)rect(bx+bw*.16,by+bh*.16+i*bh*.22,bw*.68,bh*.12,C.white);if(type==='food')rect(x+sz*.15,y+sz*.22,sz*.70,sz*.08,C.ink);}}
function map(x,y,cell=96,cols=6,rows=5,filled=true,select=true){for(let r=0;r<rows;r++)for(let c=0;c<cols;c++){const types=['office','apartment',null,'food','hotel',null];const type=filled&&((r+c)%3!==0)?types[(r*2+c)%6]:null;plot(type,x+c*cell,y+r*cell,cell-4,select&&r===2&&c===2);}}
function room(x,y,w=136,h=108,state='occupied',type='apartment'){rect(x,y,w,h,state==='selected'?C.mint:C.gray,state==='selected'?C.green:C.line,8);if(type==='parking'){rect(x+16,y+16,w-32,h-48,C.white,C.line,4);if(state!=='vacant')rect(x+36,y+24,w-72,h-64,C.office,C.ink,4);}else {rect(x+14,y+14,w*.42,h*.4,C.white,C.line,4);rect(x+w*.64,y+14,w*.22,h*.4,C[type],C.ink,4);}text(state,x+12,y+h-34,w-24,16,state==='selected'?C.green:C.muted,false,'center',26);}
function floor(x,y,w,label,kind='apartment',selected=false){rect(x,y,w,88,selected?C.mint:C.white,selected?C.green:C.line,4);text(label,x+12,y+24,52,18,C.ink,true);if(kind==='office'){rect(x+76,y+12,w-112,56,C.office,'none',4);text('Whole-floor lease',x+92,y+22,w-144,20,C.ink,true);}else for(let i=0;i<4;i++){rect(x+76+i*(w-100)/4,y+12,(w-124)/4,56,C[kind]||C.gray,'none',4);if(kind==='parking')text('P',x+76+i*(w-100)/4,y+18,(w-124)/4,26,C.ink,true,'center',40);}rect(x+w-24,y+4,16,80,C.gray);}
function leaseCard(type,label,value,x,y,w=432){rect(x,y,w,126,C.bg,C.line,8);rect(x+16,y+16,56,56,C[type],'none',4);text(type==='office'?'OF':type==='hotel'?'HT':type==='food'?'FB':'AP',x+16,y+24,56,20,C.ink,true,'center',40);text(label,x+88,y+16,w-104,22,C.ink,true);text(value,x+88,y+52,w-104,18,C.muted);}

// 01: shared palette and primitives.
start(0);const swatches=[['Ink',C.ink],['Action',C.green],['Land',C.land],['Apartment',C.apartment],['Hotel',C.hotel],['Office',C.office],['Food',C.food],['Error',C.red]];
swatches.forEach(([n,c],i)=>{const x=48+i*190;rect(x,224,168,88,c,'none',8);text(n,x,328,168,20,C.ink,true);text(c.toUpperCase(),x,360,168,16,C.muted);});
panel('Typography',48,424,480,476);text('Building Management',72,520,432,32,C.ink,true);text('Floor 04',72,578,432,24,C.ink,true);text('View rooms and tenants',72,628,432,20);text('Room capacity follows the footprint.',72,680,432,18,C.muted);row('Font','Arial',72,758);row('Text sizes','16 / 20 / 24 / 44',72,824);
panel('Controls',560,424,480,476);btn('Build',584,520,200);btn('Cancel',808,520,208,'secondary');field('CBD name','Central District',584,608,432);tag('Available',584,740,144,'active');tag('Parking full',748,740,160,'error');text('48 px actions. 8 px control corners.',584,820,432,18,C.muted);
panel('Spacing',1072,424,480,476);[8,16,24,32,48].forEach((v,i)=>{text(String(v),1096,520+i*64,52,20,C.ink,true);rect(1168,532+i*64,v*6,16,C.green);});

// 02: compare controls directly; labels stay outside the game components.
start(1);
text('Actions',48,236,224,24,C.ink,true);
['Default','Pressed','Keyboard focus','Disabled'].forEach((label,i)=>{
  const x=320+i*304;
  text(label,x,236,272,20,C.muted);
  btn('Build',x,300,272,i===3?'disabled':i===1?'pressed':'primary');
  if(i===2)rect(x-6,294,284,60,'none',C.ink,10);
});
text('Requires more funds',1232,372,272,18,C.muted);
line(48,420,1504);
text('Text fields',48,456,224,24,C.ink,true);
['Default','Focused','Invalid'].forEach((label,i)=>{
  const x=320+i*408;
  text(label,x,456,368,20,C.muted);
  field('District name',i===2?'':'Central District',x,508,368,i===2);
  if(i===1)rect(x-4,538,376,64,'none',C.ink,10);
  if(i===2)text('Enter a district name.',x,616,368,18,C.red);
});
line(48,668,1504);
text('Plot selection',48,704,224,24,C.ink,true);
plot('office',320,704,112,false);text('Unselected',456,716,232,20,C.ink,true);text('Tap to view building',456,756,232,18,C.muted);
plot('office',728,704,112,true);text('Selected',864,716,232,20,C.green,true);text('Building details open',864,756,232,18,C.muted);
rect(1136,704,416,112,C.paleRed,'none',8);text('Parking full',1156,718,376,20,C.red,true);text('Expand parking before\nadding tenants.',1156,754,376,18,C.red,false,'left',52);

// 03: geometrically consistent exteriors and map states.
start(2);['apartment','hotel','office','food'].forEach((type,i)=>{const x=48+i*384;panel(type==='food'?'Food court':type[0].toUpperCase()+type.slice(1),x,220,352,320);facade(type,x+96,312,160,180);});
panel('Plot states',48,572,736,328);[['Empty',null,false],['Selected','office',true],['Occupied','apartment',false]].forEach(([a,b,c],i)=>{plot(b,84+i*224,668,144,c);text(a,84+i*224,832,160,18);});
panel('Adjacency',816,572,736,328);plot('office',864,668,144);plot('food',1016,668,144);tag('+30% sales',1220,704,250,'active');text('Office beside food court. Sample bonus.',840,828,688,20,C.muted);

// 04: room and lift symbols use the same structural grammar.
start(3);panel('Room states',48,220,736,328);['vacant','occupied','selected'].forEach((t,i)=>room(84+i*224,328,184,148,t));
panel('Parking',816,220,736,328);['vacant','occupied','occupied'].forEach((t,i)=>room(852+i*224,328,184,148,t,'parking'));
panel('Stairs',48,580,480,320);for(let i=0;i<7;i++)rect(112+i*42,812-i*24,44,24,C.ink);text('Default access to each floor',72,840,432,18,C.muted);
panel('Standard lift',560,580,480,320);rect(744,680,112,128,C.gray,C.line,8);rect(760,710,80,80,C.office,C.ink,4);line(800,710,1);text('Maximum 3 lifts',584,840,432,18,C.muted);
panel('Executive lift',1072,580,480,320);rect(1256,680,112,128,C.gray,C.line,8);rect(1272,710,80,80,C.apartment,C.ink,4);text('Maximum 1 lift',1096,840,432,18,C.muted);

// 05: five local slots, no account flow.
start(4);panel('Choose a district',48,220,736,680);for(let i=0;i<5;i++){const y=318+i*104;rect(72,y,688,88,i===0?C.mint:C.bg,i===0?C.green:C.line,8);text(String(i+1).padStart(2,'0'),96,y+18,64,24,C.ink,true);text(i===0?'Central District':i===1?'Riverside':'Empty slot',176,y+12,320,22,C.ink,true);text(i<2?'Saved on this device':'Start a new district',176,y+46,320,16,C.muted);btn(i<2?'Load':'New',592,y+20,144,i===0?'primary':'secondary');}
panel('New district',816,220,736,680);field('District name','Central District',840,352,688);text('Choose an empty save slot.',840,488,688,20,C.muted);tag('Slot 03',840,548,144,'active');btn('Create district',840,632,256);text('Five local profiles. Progress stays on this device.',840,808,688,18,C.muted);

// 06: area map and contextual panel.
start(5);rect(48,220,1504,680,C.white,C.line,12);text('Central District',72,240,380,24,C.ink,true);text('$12,000',648,240,180,24,C.ink,true);text('80 gems',852,240,180,20);text('Day 12  /  Morning',1192,240,328,20,C.muted,false,'right');line(72,292,1456);map(80,320,104,9,5);rect(1056,316,472,552,C.bg,C.line,8);text('North Offices',1080,340,424,28,C.ink,true);tag('Office tower',1080,392,160,'active');row('Leased floors','4 / 6',1080,452,424);row('Parking','60 / 100',1080,516,424);row('Projected daily net','+$600',1080,580,424);btn('View building',1080,684,424);['Build','Tenants','Upgrades'].forEach((t,i)=>btn(t,80+i*240,844,216,i===0?'primary':'secondary'));

// 07: consistent building selection cards.
start(6);['apartment','hotel','office','food'].forEach((type,i)=>{const x=48+i*384;panel(type==='food'?'Food court':type[0].toUpperCase()+type.slice(1),x,220,352,680);facade(type,x+80,320,192,216);text(['Long-term room rentals','Daily room occupancy','Whole-floor leases','Daily customer sales'][i],x+24,592,304,20);tag(i===1?'Unlock condition TBD':'Available',x+24,656,304,i===1?'neutral':'active');btn(i===1?'Locked':'Select',x+24,792,304,i===1?'disabled':'primary');});

// 08: placement is mandatory, errors remain legible.
start(7);panel('Draw the footprint',48,220,992,680);map(80,320,112,8,4,false,false);rect(192,432,328,216,C.mint,C.green,4);text('3 × 2 plots',224,504,260,28,C.green,true,'center');text('Drag across empty land to set width and length.',72,828,944,20,C.muted);
panel('Placement',1072,220,480,680);row('Width','3 plots',1096,328);row('Length','2 plots',1096,392);tag('Valid footprint',1096,468,432,'active');btn('Use this footprint',1096,548,432);rect(1096,656,432,88,C.paleRed,'none',8);text('Overlaps a building',1112,668,400,20,C.red,true);text('Choose another plot.',1112,704,400,18,C.red);rect(1096,772,432,88,C.paleRed,'none',8);text('Outside the district',1112,784,400,20,C.red,true);text('Keep the footprint within the grid.',1112,820,400,18,C.red);

// 09: rooms are calculated, not editable.
start(8);panel('Above-ground floors',48,220,480,680);field('Number of floors','4',72,352,432);btn('−',72,468,96,'secondary');btn('+',408,468,96,'secondary');row('Footprint','3 × 2 plots',72,596);row('Rooms per floor','Calculated',72,660);row('Total room capacity','Calculated',72,724);text('Room capacity follows the footprint.',72,820,432,18,C.muted);
panel('Apartment / hotel',560,220,480,680);for(let i=0;i<4;i++)floor(584,324+i*120,432,String(4-i).padStart(2,'0'),'apartment');
panel('Other building types',1072,220,480,680);leaseCard('office','Office tower','Lease whole floors.',1096,328);leaseCard('food','Food court','Track customer sales.',1096,496);rect(1096,716,432,128,C.mint,'none',8);text('Permanent sizing',1112,730,400,22,C.green,true);text('Footprint, floors and room capacity\nstay fixed after construction.',1112,772,400,18,C.green,false,'left',56);

// 10: simple confirmation, explicit immutable sizing.
start(9);panel('Construction plan',48,220,736,680);facade('apartment',96,340,200,240);text('Apartment',336,344,400,30,C.ink,true);row('Footprint','3 × 2 plots',336,412,400);row('Above-ground floors','4',336,476,400);row('Rooms per floor','Calculated',336,540,400);rect(72,676,688,112,C.mint,'none',8);text('Sizing stays fixed after building.',96,698,640,22,C.green,true);text('Review the footprint and floor count carefully.',96,740,640,18,C.green);
panel('Review cost',816,220,736,680);row('Construction','Estimate',840,344,688);row('Daily maintenance','Estimate',840,416,688);row('Current funds','$12,000',840,488,688);text('Review the total cost before building.',840,580,688,18,C.muted);btn('Confirm construction',840,656,688);tag('Insufficient funds',840,772,688,'error');text('Earn more before building. Your plan stays available.',840,824,688,18,C.muted);

// 11: floors and basement parking, no underground rental rooms.
start(10);panel('North Offices',48,220,992,680);for(let i=0;i<6;i++)floor(88,320+i*88,696,i<3?'0'+(3-i):'B'+(i-2),i<3?'office':'parking',i===1);rect(808,320,72,520,C.gray,C.line,4);rect(816,416,56,72,C.office,C.ink,4);rect(896,320,72,520,C.gray,C.line,4);text('Lift',800,848,88,16,C.muted,false,'center');text('Stairs',888,848,96,16,C.muted,false,'center');
panel('Building summary',1072,220,480,680);row('Leased floors','2 / 3',1096,328);row('Parking','60 / 100',1096,392);row('Standard lifts','1 / 3',1096,456);row('Executive lifts','0 / 1',1096,520);text('B1–B3 are parking only.',1096,612,432,20,C.muted);btn('Manage selected floor',1096,692,432);btn('View upgrades',1096,776,432,'secondary');

// 12: apartment room tiles, office lease as whole-floor component.
start(11);panel('Apartment / hotel rooms',48,220,992,404);for(let i=0;i<6;i++)room(80+i%3*296,324+Math.floor(i/3)*132,264,108,i===2?'selected':i===4?'vacant':'occupied');
panel('Whole-floor office lease',48,656,992,244);leaseCard('office','Floor 04','Corporate tenant leases the entire floor.',72,746,944);
panel('Selected room',1072,220,480,680);text('Room 0403',1096,328,432,30,C.ink,true);tag('Occupied',1096,396,160,'active');row('Building type','Apartment',1096,468);row('Daily rent','Estimate',1096,532);row('Parking capacity','Available',1096,596);btn('View tenant',1096,704,432);btn('Back to floor',1096,788,432,'secondary');

// 13: roles represented by typed components, not stock characters.
start(12);panel('Occupancy',48,220,736,680);leaseCard('apartment','Apartment resident','Long-term room rental',72,328,688);leaseCard('hotel','Hotel guest','Daily room occupancy',72,488,688);leaseCard('office','Corporate tenant','Whole-floor lease',72,648,688);text('Needs affect happiness and occupancy.',72,828,688,18,C.muted);
panel('Traffic and parking',816,220,736,680);leaseCard('food','Food court customers','Sales depend on visitor traffic.',840,328,688);row('Parking used','80 / 100',840,510,688);progress(840,576,688,.8);row('Daily visitor traffic','Estimate',840,628,688);rect(840,724,688,128,C.paleRed,'none',8);text('Parking-full state',864,744,640,22,C.red,true);text('At 100 / 100, new occupancy is blocked.\nExpand parking to increase capacity.',864,786,640,20,C.red,false,'left',56);

// 14: recurring costs and exact upgrade limits.
start(13);[['Luxury','Increase the luxury rating.','Level: example'],['Underground parking','Excavate parking levels only.','Maximum: B3'],['Standard lifts','Improve vertical access.','Maximum: 3'],['Executive lift','Add executive access.','Maximum: 1']].forEach(([a,b,c],i)=>{const x=48+i*384;panel(a,x,220,352,680);rect(x+24,324,304,144,i===1?C.gray:i===2?C.office:i===3?C.apartment:C.mint,'none',8);text(i===1?'B1 / B2 / B3':i===2?'0 / 3':i===3?'1 / 1':'01',x+40,364,272,36,C.ink,true,'center');text(b,x+24,508,304,20,C.ink,false,'left',72);text(c,x+24,592,304,18,C.muted);row('Cost','Estimate',x+24,648,304);text('Daily maintenance: estimate',x+24,716,304,18,C.muted);btn(i===3?'Maximum reached':'Review upgrade',x+24,804,304,i===3?'disabled':'primary');});

// 15: exact financial arithmetic, offline net already applied.
start(14);panel('Noon closing',48,220,480,680);row('Gross revenue','$1,000',72,328);row('Maintenance','−$300',72,392);row('Tax','−$100',72,456);text('Net profit',72,556,432,20,C.muted);text('+$600',72,600,432,52,C.green,true);text('Add net at daily closing.',72,708,432,20,C.muted);btn('Continue',72,804,432);
panel('Offline return',560,220,480,680);text('2 simulated days',584,328,432,24,C.ink,true);row('Gross revenue','$2,000',584,400);row('Maintenance','−$600',584,464);row('Tax','−$200',584,528);text('+$1,200',584,612,432,52,C.green,true);text('Already added to your balance.',584,724,432,20,C.muted);btn('Continue',584,804,432);
panel('Loss and rewards',1072,220,480,680);row('Gross revenue','$200',1096,328);row('Maintenance','−$300',1096,384);row('Tax','−$100',1096,440);text('−$200',1096,512,432,48,C.red,true);text('Achievement',1096,604,432,24,C.ink,true);text('Earn gems through achievements.',1096,648,432,20,C.muted);progress(1096,716,432,.32);text('320 / 1,000  —  sample progress',1096,744,432,18,C.muted);tag('Gem decoration concept',1096,828,432,'active');

// 16: shared components in portrait, landscape and desktop arrangements.
start(15);text('Portrait',48,220,288,24,C.ink,true);text('Landscape',368,220,552,24,C.ink,true);text('Web / tablet',952,220,600,24,C.ink,true);
rect(48,272,288,624,C.white,C.line,12);text('Central District',64,292,256,20,C.ink,true);text('$12,000     80 gems',64,336,256,18);text('Day 12 / Morning',64,372,256,16,C.muted);map(72,424,40,6,8);rect(64,630,256,172,C.bg,C.line,8);text('North Offices',80,644,224,20,C.ink,true);text('Parking 60 / 100',80,688,224,18,C.muted);btn('Manage',80,736,224);['Build','Tenants','Upgrades'].forEach((t,i)=>{rect(64+i*86,828,80,48,i===0?C.green:C.white,C.line,8);text(t,66+i*86,838,76,16,i===0?C.white:C.ink,true,'center',28);});
rect(368,272,552,256,C.white,C.line,12);text('Central District',384,284,276,18,C.ink,true);text('$12,000 / Morning',656,284,248,16,C.muted,false,'right');map(384,328,44,7,4);rect(712,324,192,188,C.bg,C.line,8);text('North Offices',728,336,160,18,C.ink,true);text('Parking\n60 / 100',728,378,160,16,C.muted,false,'left',60);btn('Manage',728,452,160);
rect(952,272,600,400,C.white,C.line,12);text('Central District',968,284,276,18,C.ink,true);text('$12,000 / Morning',1280,284,256,16,C.muted,false,'right');map(972,328,46,6,6);rect(1268,324,268,324,C.bg,C.line,8);text('North Offices',1284,344,236,20,C.ink,true);row('Floors','4 / 6',1284,400,236);row('Parking','60 / 100',1284,464,236);btn('Manage',1284,536,236);btn('Upgrades',1284,592,236,'secondary');
text('Shared components',368,732,1184,24,C.ink,true);text('HUD, action buttons, map plots and building details keep the same styling.',368,780,1184,20,C.muted);text('Portrait uses a bottom sheet. Wider views use a side panel.',368,832,1184,20,C.muted);

await fs.mkdir(path.join(root,'previews'),{recursive:true});await fs.mkdir(path.join(root,'.build'),{recursive:true});await fs.mkdir(path.join(root,'output'),{recursive:true});
for(let i=0;i<pres.slides.items.length;i++){const png=await pres.export({slide:pres.slides.items[i],format:'png',scale:1});await fs.writeFile(path.join(root,'previews',`${String(i+1).padStart(2,'0')}.png`),new Uint8Array(await png.arrayBuffer()));console.log(`Rendered ${i+1}/16`);}
const candidate=path.join(root,'.build','candidate.pptx');await (await PresentationFile.exportPptx(pres)).save(candidate);
await fs.writeFile(path.join(root,'.build','geometry.json'),JSON.stringify(evidence,null,2));
const revision=process.argv[2]||new Date().toISOString().replace(/[^0-9]/g,'').slice(0,14);
if(!/^[a-z0-9-]+$/i.test(revision))throw Error('Revision must contain letters, digits or hyphens.');
const final=path.join(root,'output',`Building-Management-Tycoon-${revision}.pptx`);
const result=await finalizePresentation({workspaceDir:workspace,candidatePath:candidate,finalPath:final,explicitTotalSlideCount:16,pythonExecutable:`${runtime}/python/python.exe`,integrityValidatorPath:`${skill}/container_tools/inspect_presentation_package_integrity.py`,layoutValidatorPath:`${skill}/container_tools/inspect_presentation_layout_geometry.py`,layoutArgs:['--expected-slide-size-emu','15240000,9525000','--validate-heading-fit'],requiredNativeTableOwnerSlides:[],fontPolicy:{basis:'design',families:['Arial']},verifyArtifactToolImport:true,receiptPath:path.join(root,'.build',`validation-${revision}.json`)});
console.log(JSON.stringify(result));
