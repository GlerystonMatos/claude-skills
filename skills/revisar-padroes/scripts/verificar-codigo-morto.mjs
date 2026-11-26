import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const raiz = process.argv[2] ?? 'src';
const extensoes = /\.(ts|tsx)$/;
const declaracao = /^export\s+(?:async\s+)?(?:function|const|let|interface|type|class)\s+([A-Za-z_$][\w$]*)/gm;

function listar(pasta) {
    return readdirSync(pasta).flatMap((nome) => {
        const caminho = join(pasta, nome);
        if (statSync(caminho).isDirectory()) return nome === 'node_modules' ? [] : listar(caminho);
        return extensoes.test(nome) && !nome.endsWith('.d.ts') ? [caminho] : [];
    });
}

const arquivos = listar(raiz).map((caminho) => ({ caminho, texto: readFileSync(caminho, 'utf8') }));
const ehTeste = (caminho) => /\.test\.tsx?$/.test(caminho);
const espelhoDeTipos = (caminho) => /(^|[\\/])tipos\.ts$/.test(caminho);
const achados = [];
const avisos = [];

for (const arquivo of arquivos) {
    if (ehTeste(arquivo.caminho) || espelhoDeTipos(arquivo.caminho)) continue;
    for (const [, nome] of arquivo.texto.matchAll(declaracao)) {
        const palavra = new RegExp(`\\b${nome.replace(/\$/g, '\\$')}\\b`);
        const outros = arquivos.filter((outro) => outro !== arquivo && palavra.test(outro.texto));
        if (outros.length === 0) achados.push(`${relative('.', arquivo.caminho)}: ${nome} (exportado e usado só no próprio arquivo)`);
        else if (outros.every((outro) => ehTeste(outro.caminho))) avisos.push(`${relative('.', arquivo.caminho)}: ${nome} (fora do arquivo, só nos testes)`);
    }
}

achados.forEach((linha) => console.log(linha));
avisos.forEach((linha) => console.log(`aviso: ${linha}`));
if (achados.length) process.exit(1);
