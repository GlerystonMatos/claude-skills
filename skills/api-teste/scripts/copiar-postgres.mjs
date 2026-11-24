import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

function sair(mensagem) {
    console.error(mensagem);
    process.exit(1);
}

export function localizarBinPostgres() {
    if (process.env.PG_BIN) return process.env.PG_BIN;
    const raiz = 'C:\\Program Files\\PostgreSQL';
    if (!existsSync(raiz)) return '';
    const versoes = readdirSync(raiz)
        .filter((versao) => existsSync(join(raiz, versao, 'bin', 'psql.exe')))
        .sort((a, b) => Number(b) - Number(a));
    return versoes.length > 0 ? join(raiz, versoes[0], 'bin') : '';
}

function comandoPg(nome) {
    const bin = localizarBinPostgres();
    return bin ? join(bin, `${nome}.exe`) : nome;
}

export function executarPg(nome, argumentos, conexao) {
    const resultado = spawnSync(comandoPg(nome), ['-h', conexao.host, '-p', conexao.porta, '-U', conexao.usuario, ...argumentos], {
        env: { ...process.env, PGPASSWORD: conexao.senha },
        encoding: 'utf8',
    });
    if (resultado.error) sair(`Falha ao executar ${nome}: ${resultado.error.message}`);
    if (resultado.status !== 0) sair(`${nome} falhou: ${resultado.stderr.trim()}`);
    return resultado.stdout;
}

export function lerVariavelEnv(arquivo, nome) {
    if (!existsSync(arquivo)) sair(`Arquivo ${arquivo} não encontrado.`);
    for (const linha of readFileSync(arquivo, 'utf8').split(/\r?\n/)) {
        const correspondencia = linha.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$/);
        if (correspondencia && correspondencia[1] === nome) return correspondencia[2].replace(/^["']|["']$/g, '');
    }
    return sair(`Variável ${nome} não encontrada em ${arquivo}.`);
}

export function copiarBanco(conexao, origem, destino, { recriar = false, pastaTemporaria } = {}) {
    if (origem === destino) sair('O banco de destino não pode ser o de origem.');
    if (!destino.includes('teste')) sair(`O banco de destino (${destino}) precisa ter "teste" no nome.`);
    const existe = executarPg('psql', ['-d', 'postgres', '-tAc', `select 1 from pg_database where datname = '${destino}'`], conexao).trim() === '1';

    if (existe && !recriar) {
        console.log(`Banco ${destino} já existe; reaproveitado (use --recriar para copiar de novo).`);
        return 'reaproveitado';
    }
    if (existe) executarPg('dropdb', ['--force', destino], conexao);

    const pasta = pastaTemporaria ?? process.env.TEMP ?? '.';
    mkdirSync(pasta, { recursive: true });
    const arquivoCopia = join(pasta, `${destino}-origem.dump`);
    executarPg('pg_dump', ['-Fc', '-f', arquivoCopia, origem], conexao);
    executarPg('createdb', [destino], conexao);
    executarPg('pg_restore', ['--no-owner', '--no-privileges', '-d', destino, arquivoCopia], conexao);
    rmSync(arquivoCopia, { force: true });
    console.log(`Banco ${destino} copiado de ${origem}.`);
    return 'copiado';
}

function lerArgumentos(lista) {
    const valores = { recriar: false };
    for (let indice = 0; indice < lista.length; indice++) {
        const nome = lista[indice];
        if (nome === '--recriar') valores.recriar = true;
        else if (nome.startsWith('--')) valores[nome.slice(2)] = lista[++indice];
    }
    return valores;
}

function principal() {
    const argumentos = lerArgumentos(process.argv.slice(2));
    if (!argumentos.origem || !argumentos.destino) {
        sair('Uso: node copiar-postgres.mjs --origem <banco> --destino <banco_teste> [--host 127.0.0.1] [--porta 5432] '
            + '[--usuario postgres] [--env <arquivo .env> --var-senha <NOME>] [--temp <pasta>] [--recriar]\n'
            + 'Senha: --env + --var-senha, ou PGPASSWORD no ambiente. Nunca é exibida.');
    }
    const senha = argumentos.env
        ? lerVariavelEnv(resolve(argumentos.env), argumentos['var-senha'] ?? 'PGPASSWORD')
        : (process.env.PGPASSWORD ?? '');
    const conexao = {
        host: argumentos.host ?? '127.0.0.1',
        porta: argumentos.porta ?? '5432',
        usuario: argumentos.usuario ?? 'postgres',
        senha,
    };
    copiarBanco(conexao, argumentos.origem, argumentos.destino, { recriar: argumentos.recriar, pastaTemporaria: argumentos.temp });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) principal();
