import { spawnSync } from 'node:child_process';

function git(...argumentos) {
    return spawnSync('git', argumentos, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }).stdout ?? '';
}

function linhas(diff, sinal) {
    const marcador = sinal.repeat(3);
    return diff.split(/\r?\n/)
        .filter((linha) => linha.startsWith(sinal) && !linha.startsWith(marcador))
        .map((linha) => linha.slice(1).trim());
}

const argumentos = process.argv.slice(2);
if (argumentos.length !== 3) {
    console.log('uso: node linhas-perdidas.mjs <commit-de-fora> <base> <commit-local>');
    process.exit(2);
}
const [deFora, base, local] = argumentos;
const arquivos = git('show', '--name-only', '--format=', deFora).split(/\r?\n/).filter(Boolean);
console.log(`${arquivos.length} arquivo(s) no commit de fora`);

let suspeitas = 0;
for (const arquivo of arquivos) {
    const adicionadas = new Set(linhas(git('diff', base, deFora, '--', arquivo), '+'));
    const removidas = linhas(git('diff', deFora, local, '--', arquivo), '-').filter((linha) => linha && adicionadas.has(linha));
    if (removidas.length > 0) {
        suspeitas += removidas.length;
        console.log(`## ${arquivo}: ${removidas.length} linha(s) do commit de fora removida(s) pelo local`);
        for (const linha of removidas) console.log(`   - ${linha.slice(0, 180)}`);
    }
}
console.log(`${suspeitas} linha(s) para explicar`);
console.log();
console.log('Arquivos do commit de fora alterados pelo local (só podem ser mudanças locais):');
console.log((arquivos.length > 0 ? git('diff', '--stat', deFora, local, '--', ...arquivos) : '') || '   nenhum');
