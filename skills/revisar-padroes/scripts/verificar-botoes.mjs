import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const raiz = process.argv[2] ?? 'src';
const botoesComTexto = ['Button', 'BotaoComCarregamento', 'LoadingButton'];
const botoesSoIcone = ['IconButton'];

function listar(pasta) {
    return readdirSync(pasta).flatMap((nome) => {
        const caminho = join(pasta, nome);
        if (statSync(caminho).isDirectory()) return nome === 'node_modules' ? [] : listar(caminho);
        return /\.tsx$/.test(nome) && !/\.test\.tsx$/.test(nome) ? [caminho] : [];
    });
}

function fimDaTag(texto, inicio) {
    let chaves = 0;
    let aspas = null;
    for (let i = inicio; i < texto.length; i++) {
        const c = texto[i];
        if (aspas) {
            if (c === aspas && texto[i - 1] !== '\\') aspas = null;
            continue;
        }
        if (c === '"' || c === "'" || c === '`') aspas = c;
        else if (c === '{') chaves++;
        else if (c === '}') chaves--;
        else if (c === '>' && chaves === 0) return i;
    }
    return texto.length;
}

function linhaDe(texto, posicao) {
    return texto.slice(0, posicao).split('\n').length;
}

const achados = [];

for (const caminho of listar(raiz)) {
    const texto = readFileSync(caminho, 'utf8');
    const abertura = /<([A-Z][A-Za-z]*)\b/g;
    for (const encontrado of texto.matchAll(abertura)) {
        const componente = encontrado[1];
        const ehComTexto = botoesComTexto.includes(componente);
        const ehSoIcone = botoesSoIcone.includes(componente);
        if (!ehComTexto && !ehSoIcone) continue;
        const atributos = texto.slice(encontrado.index, fimDaTag(texto, encontrado.index) + 1);
        if (atributos.includes('{...')) continue;
        const linha = linhaDe(texto, encontrado.index);
        if (ehComTexto && !/\b(startIcon|endIcon)=/.test(atributos)) achados.push(`${caminho}:${linha}: <${componente}> sem ícone (startIcon)`);
        if (ehSoIcone && !/\baria-label=/.test(atributos)) achados.push(`${caminho}:${linha}: <${componente}> sem aria-label`);
    }
}

for (const achado of achados) console.log(achado);
if (achados.length > 0) process.exitCode = 1;
else console.log('Todos os botões têm ícone e os botões de ícone têm aria-label.');
