import { readFileSync, writeFileSync } from 'node:fs';

const [arquivo, arquivoPares] = process.argv.slice(2);
if (!arquivo || !arquivoPares) {
    console.error('uso: node substituir.mjs <arquivo> <pares.json>');
    console.error('pares.json: [["trecho antigo", "trecho novo"], ...] (ou [{ "antigo": "...", "novo": "..." }])');
    process.exit(2);
}

const pares = JSON.parse(readFileSync(arquivoPares, 'utf8')).map((par) => (Array.isArray(par) ? par : [par.antigo, par.novo]));
const bruto = readFileSync(arquivo, 'utf8');
const bom = bruto.startsWith('﻿') ? '﻿' : '';
const crlf = bruto.includes('\r\n');
const ajustar = (texto) => {
    const lf = texto.replace(/\r\n/g, '\n');
    return crlf ? lf.replace(/\n/g, '\r\n') : lf;
};

let conteudo = bruto.slice(bom.length);
const erros = [];
pares.forEach(([antigo, novo], indice) => {
    if (typeof antigo !== 'string' || typeof novo !== 'string' || antigo === '') {
        erros.push(`par ${indice + 1}: trecho antigo vazio ou par inválido`);
        return;
    }
    const alvo = ajustar(antigo);
    const ocorrencias = conteudo.split(alvo).length - 1;
    if (ocorrencias !== 1) {
        erros.push(`par ${indice + 1}: trecho aparece ${ocorrencias} vez(es), esperado 1: ${antigo.split('\n')[0].slice(0, 80)}`);
        return;
    }
    const substituto = ajustar(novo);
    conteudo = conteudo.replace(alvo, () => substituto);
});

if (erros.length > 0) {
    for (const erro of erros) console.error(erro);
    console.error(`${arquivo}: nada foi alterado`);
    process.exit(1);
}

writeFileSync(arquivo, bom + conteudo);
console.log(`${arquivo}: ${pares.length} substituição(ões), final de linha ${crlf ? 'CRLF' : 'LF'} mantido`);
