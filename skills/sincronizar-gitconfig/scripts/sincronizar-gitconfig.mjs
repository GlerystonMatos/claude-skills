import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const ARQUIVO_LOCAL = join(homedir(), '.gitconfig');
const ARQUIVO_ESTADO = join(homedir(), '.gitconfig-sincronizado');
const NOME_NO_REPOSITORIO = '.gitconfig';

function sair(mensagem) {
    console.error(mensagem);
    process.exit(1);
}

function normalizar(texto) {
    return texto.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\s+$/, '') + '\n';
}

function ler(caminho) {
    return existsSync(caminho) ? normalizar(readFileSync(caminho, 'utf8')) : null;
}

function hash(texto) {
    return texto === null ? null : createHash('sha256').update(texto).digest('hex');
}

function pastaRepositorio(argumentos) {
    const indice = argumentos.indexOf('--repo');
    if (indice >= 0) return argumentos[indice + 1];
    if (process.env.GITCONFIG_REPO) return process.env.GITCONFIG_REPO;
    return 'C:\\Projetos\\gitconfig';
}

function dataUltimoCommit(repo) {
    const resultado = spawnSync('git', ['-C', repo, 'log', '-1', '--format=%cI', '--', NOME_NO_REPOSITORIO], { encoding: 'utf8' });
    return resultado.stdout.trim() || null;
}

function diferenca(repo, arquivoRepo) {
    const resultado = spawnSync('git', ['-C', repo, 'diff', '--no-index', '--color=never', '--ignore-cr-at-eol',
        '--src-prefix=repositorio/', '--dst-prefix=maquina/', arquivoRepo, ARQUIVO_LOCAL], { encoding: 'utf8' });
    return resultado.stdout;
}

function gravarEstado(texto) {
    writeFileSync(ARQUIVO_ESTADO, `${hash(texto)}\n`);
}

function situacao(repo) {
    if (!existsSync(join(repo, '.git'))) sair(`Repositório não encontrado em ${repo} (use --repo <pasta> ou GITCONFIG_REPO).`);
    const arquivoRepo = join(repo, NOME_NO_REPOSITORIO);
    const local = ler(ARQUIVO_LOCAL);
    const remoto = ler(arquivoRepo);
    const ultimo = existsSync(ARQUIVO_ESTADO) ? readFileSync(ARQUIVO_ESTADO, 'utf8').trim() : null;
    if (local === null) sair(`${ARQUIVO_LOCAL} não existe.`);

    let estado;
    if (remoto === null) estado = 'primeira-vez';
    else if (local === remoto) estado = 'igual';
    else if (ultimo === null) estado = 'sem-historico';
    else if (hash(local) === ultimo) estado = 'repositorio-mais-novo';
    else if (hash(remoto) === ultimo) estado = 'maquina-mais-nova';
    else estado = 'conflito';

    return { estado, arquivoRepo, local, remoto };
}

const [comando, ...argumentos] = process.argv.slice(2);
const repo = pastaRepositorio(argumentos);
const atual = situacao(repo);

if (comando === 'estado') {
    console.log(`estado: ${atual.estado}`);
    console.log(`maquina: ${ARQUIVO_LOCAL} (alterado em ${statSync(ARQUIVO_LOCAL).mtime.toISOString()})`);
    console.log(`repositorio: ${atual.arquivoRepo}${atual.remoto === null ? ' (não existe)' : ` (último commit ${dataUltimoCommit(repo) ?? 'nenhum'})`}`);
    if (atual.estado === 'igual' && hash(atual.local) !== (existsSync(ARQUIVO_ESTADO) ? readFileSync(ARQUIVO_ESTADO, 'utf8').trim() : null)) {
        gravarEstado(atual.local);
        console.log('registro da última sincronização atualizado');
    }
    if (atual.remoto !== null && atual.estado !== 'igual') {
        console.log('--- diferença (repositorio → maquina) ---');
        console.log(diferenca(repo, atual.arquivoRepo));
    }
} else if (comando === 'para-repositorio') {
    writeFileSync(atual.arquivoRepo, atual.local);
    console.log(`copiado da máquina para ${atual.arquivoRepo}; commite, faça o push e rode "marcar"`);
} else if (comando === 'para-maquina') {
    if (atual.remoto === null) sair('O repositório ainda não tem .gitconfig.');
    const copia = `${ARQUIVO_LOCAL}.antes-da-sincronizacao`;
    copyFileSync(ARQUIVO_LOCAL, copia);
    writeFileSync(ARQUIVO_LOCAL, atual.remoto);
    gravarEstado(atual.remoto);
    console.log(`copiado do repositório para ${ARQUIVO_LOCAL}; versão anterior em ${copia}`);
} else if (comando === 'marcar') {
    if (atual.estado !== 'igual') sair(`Máquina e repositório ainda diferem (estado: ${atual.estado}); nada marcado.`);
    gravarEstado(atual.local);
    console.log('sincronização registrada');
} else {
    sair('Uso: node sincronizar-gitconfig.mjs <estado|para-repositorio|para-maquina|marcar> [--repo <pasta>]');
}
