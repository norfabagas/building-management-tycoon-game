import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const sharp=require(process.env.RUNTIME_NODE_MODULES?path.join(process.env.RUNTIME_NODE_MODULES,'sharp'):'sharp');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const master=path.join(root,'design/brand/bm-tower.png');
const outputs=[['web/favicon.png',32],['web/icons/Icon-192.png',192],['web/icons/Icon-512.png',512],['web/icons/Icon-maskable-192.png',192],['web/icons/Icon-maskable-512.png',512],['android/app/src/main/res/drawable/bm_tower.png',96]];
for(const [density,size]of [['mdpi',48],['hdpi',72],['xhdpi',96],['xxhdpi',144],['xxxhdpi',192]])outputs.push([`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,size]);
for(const [target,size]of outputs){const output=path.join(root,target);await fs.mkdir(path.dirname(output),{recursive:true});await sharp(master).resize(size,size).png().toFile(output);}
console.log(`Exported ${outputs.length} icons from the defined BM mark.`);
