import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const CENTRAL = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function git(...argumentos) {
    const resultado = spawnSync('git', argumentos, { encoding: 'utf8' });
    return resultado.status === 0 ? resultado.stdout.trim() : '';
}

function nomeDoRepositorio() {
    const remoto = git('remote', 'get-url', 'origin');
    if (remoto) return basename(remoto.replace(/\/+$/, '')).replace(/\.git$/, '');
    const raiz = git('rev-parse', '--show-toplevel');
    return raiz ? basename(raiz) : '';
}

function ler(caminho) {
    return readFileSync(caminho, 'utf8').replace(/^﻿/, '').replace(/\r\n/g, '\n').trimEnd();
}

const skill = process.argv[2];
if (!skill || skill.startsWith('-')) {
    console.log('Uso: node configuracao.mjs <skill>   (na raiz do projeto)');
    process.exit(2);
}
const repo = nomeDoRepositorio();
if (!repo) {
    console.log('ERRO: a pasta atual não está num repositório git.');
    process.exit(2);
}

const relativoProjeto = `projetos/${repo}/${skill}.md`;
const arquivoProjeto = join(CENTRAL, relativoProjeto);
const scriptsGlobais = join(CENTRAL, 'skills', skill, 'scripts');
const scriptsProjeto = join(CENTRAL, 'projetos', repo, skill, 'scripts');

console.log(`repositorio: ${repo}`);
console.log(`central: ${CENTRAL}`);
if (existsSync(scriptsGlobais)) console.log(`scripts-globais: ${scriptsGlobais}`);
if (existsSync(scriptsProjeto)) console.log(`scripts: ${scriptsProjeto}`);

if (!existsSync(arquivoProjeto)) {
    console.log(`SEM CONFIGURACAO: ${relativoProjeto} não existe. Proponha criar (ver a skill).`);
    process.exit(3);
}

const projeto = ler(arquivoProjeto);
const base = projeto.match(/^Base:\s*(\S+)/);
if (base) {
    const relativoBase = `projetos/_${base[1]}/${skill}.md`;
    if (!existsSync(join(CENTRAL, relativoBase))) {
        console.log(`ERRO: ${relativoProjeto} aponta para a base ${relativoBase}, que não existe.`);
        process.exit(4);
    }
    console.log(`\n===== base: ${relativoBase} (a configuração do projeto prevalece quando divergir) =====\n`);
    console.log(ler(join(CENTRAL, relativoBase)));
}
console.log(`\n===== projeto: ${relativoProjeto} =====\n`);
console.log(projeto);
