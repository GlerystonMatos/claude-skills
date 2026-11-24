import { readFileSync, writeFileSync } from 'node:fs';
const verificar = process.argv[2] === '--verificar';
const arquivos = process.argv.slice(verificar ? 3 : 2);
let problemas = 0;
for (const arquivo of arquivos) {
    const original = readFileSync(arquivo, 'utf8');
    const eol = original.includes('\r\n') ? '\r\n' : '\n';
    const linhas = original.split(/\r?\n/);
    let fim = 0;
    while (fim < linhas.length && /^import .*;$/.test(linhas[fim])) fim++;
    const bloco = linhas.slice(0, fim);
    const ordenado = bloco.map((l, i) => [l, i]).sort((a, b) => a[0].length - b[0].length || a[1] - b[1]).map((p) => p[0]);
    if (ordenado.join() === bloco.join()) continue;
    problemas++;
    if (verificar) console.log('fora do padrão: ' + arquivo);
    else writeFileSync(arquivo, [...ordenado, ...linhas.slice(fim)].join(eol));
}
if (verificar && problemas) process.exit(1);
