import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const CENTRAL = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const problemas = [];
const avisar = (arquivo, texto) => problemas.push(`${arquivo}: ${texto}`);

const skills = readdirSync(join(CENTRAL, 'skills')).filter((nome) => statSync(join(CENTRAL, 'skills', nome)).isDirectory());
const nomesDeSkill = new Set(skills);

function arquivosMarkdown(pasta) {
    if (!existsSync(pasta)) return [];
    return readdirSync(pasta, { recursive: true })
        .map((relativo) => join(pasta, relativo))
        .filter((caminho) => caminho.endsWith('.md') && statSync(caminho).isFile());
}

const relativo = (caminho) => caminho.slice(CENTRAL.length + 1).replaceAll('\\', '/');

for (const skill of skills) {
    const arquivo = join(CENTRAL, 'skills', skill, 'SKILL.md');
    if (!existsSync(arquivo)) {
        avisar(`skills/${skill}`, 'sem SKILL.md');
        continue;
    }
    const texto = readFileSync(arquivo, 'utf8');
    const frente = texto.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!frente) {
        avisar(relativo(arquivo), 'sem front matter');
        continue;
    }
    const nome = frente[1].match(/^name:\s*(.+)$/m)?.[1].trim();
    const descricao = frente[1].match(/^description:\s*(.+)$/m)?.[1].trim();
    if (nome !== skill) avisar(relativo(arquivo), `name "${nome}" diferente da pasta "${skill}"`);
    if (!descricao) avisar(relativo(arquivo), 'description vazia');
    else if (descricao.length > 1024) avisar(relativo(arquivo), `description com ${descricao.length} caracteres (o limite comum é 1024)`);
}

const citacoes = [/\bskills?\s+\*{0,2}`([a-z0-9]+(?:-[a-z0-9]+)+)`/g, /`([a-z0-9]+(?:-[a-z0-9]+)+)`\s*\(global\)/g];
const documentos = [
    ...skills.flatMap((skill) => arquivosMarkdown(join(CENTRAL, 'skills', skill))),
    ...arquivosMarkdown(join(CENTRAL, 'projetos')),
    join(CENTRAL, 'README.md'),
];
for (const arquivo of documentos) {
    const texto = readFileSync(arquivo, 'utf8');
    for (const padrao of citacoes) {
        for (const [, citada] of texto.matchAll(padrao)) {
            if (!nomesDeSkill.has(citada)) avisar(relativo(arquivo), `cita a skill "${citada}", que não existe`);
        }
    }
}

const listaDoReadme = readFileSync(join(CENTRAL, 'README.md'), 'utf8').match(/Skills genéricas[^(]*\(([^)]*)\)/);
if (!listaDoReadme) {
    avisar('README.md', 'não achei a lista de skills da tabela "Estrutura"');
} else {
    const listadas = new Set([...listaDoReadme[1].matchAll(/`([^`]+)`/g)].map((m) => m[1]));
    for (const skill of skills) if (!listadas.has(skill)) avisar('README.md', `a skill "${skill}" falta na lista da tabela "Estrutura"`);
    for (const nome of listadas) if (!nomesDeSkill.has(nome)) avisar('README.md', `a lista da tabela "Estrutura" cita "${nome}", que não existe em skills/`);
}

const pastaProjetos = join(CENTRAL, 'projetos');
for (const projeto of existsSync(pastaProjetos) ? readdirSync(pastaProjetos) : []) {
    const pasta = join(pastaProjetos, projeto);
    if (!statSync(pasta).isDirectory()) continue;
    for (const item of readdirSync(pasta)) {
        const caminho = join(pasta, item);
        if (item === 'padrao' && statSync(caminho).isDirectory()) {
            for (const arquivoBase of readdirSync(caminho)) {
                if (!nomesDeSkill.has(arquivoBase.replace(/\.md$/, ''))) avisar(relativo(join(caminho, arquivoBase)), 'não corresponde a nenhuma skill de skills/');
            }
            continue;
        }
        const nomeSkill = item.replace(/\.md$/, '');
        if (!nomesDeSkill.has(nomeSkill)) {
            avisar(relativo(caminho), `não corresponde a nenhuma skill de skills/`);
            continue;
        }
        if (!item.endsWith('.md')) continue;
        const base = readFileSync(caminho, 'utf8').match(/^Base:\s*(\S+)/);
        if (base && !existsSync(join(pastaProjetos, base[1], "padrao", item))) avisar(relativo(caminho), `Base "${base[1]}" sem projetos/${base[1]}/padrao/${item}`);
    }
}

const eol = spawnSync('git', ['-C', CENTRAL, 'ls-files', '--eol'], { encoding: 'utf8' }).stdout.split(/\r?\n/);
for (const linha of eol) {
    const [indice, , , ...resto] = linha.split(/\s+/);
    const caminho = resto.join(' ');
    if (indice && (indice === 'i/crlf' || indice === 'i/mixed') && !/^LICENSE$/.test(caminho)) avisar(caminho, `final de linha ${indice.slice(2)} no índice (o repositório usa LF)`);
}

if (problemas.length === 0) {
    console.log(`claude-skills ok: ${skills.length} skills, ${documentos.length} documentos conferidos`);
} else {
    for (const problema of problemas) console.log(`aviso: ${problema}`);
    process.exitCode = 1;
}
