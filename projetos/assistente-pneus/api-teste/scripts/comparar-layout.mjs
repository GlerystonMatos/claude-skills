import fs from 'node:fs';
import path from 'node:path';

const [pasta, nome] = process.argv.slice(2);
const a = JSON.parse(fs.readFileSync(path.join(pasta, `${nome}-a.json`), 'utf8'));
const b = JSON.parse(fs.readFileSync(path.join(pasta, `${nome}-b.json`), 'utf8'));
console.log(`elementos: original ${a.length}, novo ${b.length}`);
const normalizar = (lista) => lista.forEach((item) => { if (item.borda.startsWith('0px')) item.borda = '0'; });
normalizar(a);
normalizar(b);
const max = Math.max(a.length, b.length);
let diferencas = 0;
for (let i = 0; i < max && diferencas < 25; i++) {
    const x = JSON.stringify(a[i]);
    const y = JSON.stringify(b[i]);
    if (x !== y) {
        diferencas++;
        console.log(`#${i}\n  A ${x}\n  B ${y}`);
    }
}
console.log(diferencas ? `diferenças (até 25): ${diferencas}` : 'idênticos');
