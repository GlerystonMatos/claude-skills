import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const CENTRAL = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SKILLS = join(CENTRAL, 'skills');
const temporaria = mkdtempSync(join(tmpdir(), 'claude-skills-testes-'));
const resultados = [];

function rodar(comando, argumentos, opcoes = {}) {
    const resultado = spawnSync(comando, argumentos, { encoding: 'utf8', ...opcoes });
    return { codigo: resultado.status, saida: `${resultado.stdout ?? ''}${resultado.stderr ?? ''}` };
}

function node(script, argumentos, opcoes) {
    return rodar(process.execPath, [script, ...argumentos], opcoes);
}

function git(pasta, ...argumentos) {
    return rodar('git', ['-C', pasta, '-c', 'user.name=teste', '-c', 'user.email=teste@teste', '-c', 'core.autocrlf=false', ...argumentos]);
}

function novoRepositorio(nome, origem) {
    const pasta = join(temporaria, nome);
    mkdirSync(pasta, { recursive: true });
    git(pasta, 'init', '-q');
    if (origem) git(pasta, 'remote', 'add', 'origin', origem);
    return pasta;
}

function teste(nome, corpo) {
    try {
        corpo();
        resultados.push({ nome, ok: true });
    } catch (erro) {
        resultados.push({ nome, ok: false, detalhe: erro.message });
    }
}

function esperar(condicao, mensagem) {
    if (!condicao) throw new Error(mensagem);
}

teste('configuracao.mjs: base + projeto, sem configuração e sem remote', () => {
    const script = join(CENTRAL, 'scripts', 'configuracao.mjs');
    const iris = novoRepositorio('cfg-iris', 'git@github.com:x/iris.git');
    const comBase = node(script, ['api-teste'], { cwd: iris });
    esperar(comBase.codigo === 0, `código ${comBase.codigo}`);
    esperar(comBase.saida.includes('===== base: projetos/argos/padrao/api-teste.md'), 'não mostrou a base');
    esperar(comBase.saida.includes('===== projeto: projetos/iris/api-teste.md'), 'não mostrou o projeto');
    const semConfiguracao = node(script, ['api-teste'], { cwd: novoRepositorio('cfg-nenhum', 'https://x/nao-existe-xyz.git') });
    esperar(semConfiguracao.codigo === 3 && semConfiguracao.saida.includes('SEM CONFIGURACAO'), 'sem configuração deveria sair com 3');
    const semRemoto = node(script, ['api-teste'], { cwd: novoRepositorio('sem-remoto-xyz') });
    esperar(semRemoto.saida.includes('repositorio: sem-remoto-xyz'), 'sem remote deveria usar o nome da pasta');
});

teste('api-teste/usuario-teste.mjs: modelos argos e iris, reaproveitamento e hash', () => {
    const script = join(SKILLS, 'api-teste', 'scripts', 'usuario-teste.mjs');
    for (const modelo of ['argos', 'iris']) {
        const pasta = join(temporaria, `usuario-${modelo}`);
        mkdirSync(join(pasta, 'dados'), { recursive: true });
        writeFileSync(join(pasta, 'dados', 'AppUsuarios.json'), '﻿{"usuarios":[{"login":"outro"}]}');
        const primeira = node(script, ['preparar', pasta, '--dados', join(pasta, 'dados'), '--modelo', modelo]);
        esperar(primeira.codigo === 0, `${modelo}: ${primeira.saida}`);
        const usuarios = JSON.parse(readFileSync(join(pasta, 'dados', 'AppUsuarios.json'), 'utf8')).usuarios;
        const criado = usuarios.find((u) => u.login === 'teste-validacao');
        esperar(usuarios.length === 2 && criado, `${modelo}: usuário não criado`);
        esperar(/^pbkdf2-sha256\$600000\$[A-Za-z0-9+/=]{24}\$[A-Za-z0-9+/=]{44}$/.test(criado.hashSenha), `${modelo}: hash fora do formato`);
        esperar(modelo === 'argos' ? criado.colaborador?.sigla === 'TST' : criado.tipo === 'Interno' && criado.ativo === true, `${modelo}: campos do modelo`);
        const segunda = node(script, ['preparar', pasta, '--dados', join(pasta, 'dados'), '--modelo', modelo]);
        esperar(segunda.saida.includes('já existe'), `${modelo}: deveria reaproveitar`);
    }
    esperar(node(script, ['preparar', temporaria, '--dados', temporaria, '--modelo', 'outro']).codigo !== 0, 'modelo inválido deveria falhar');
});

teste('api-teste/copiar-postgres.mjs: travas antes de tocar no banco', () => {
    const script = join(SKILLS, 'api-teste', 'scripts', 'copiar-postgres.mjs');
    const semTeste = node(script, ['--origem', 'a', '--destino', 'producao']);
    esperar(semTeste.codigo === 1 && semTeste.saida.includes('precisa ter "teste"'), 'destino sem "teste" deveria ser recusado');
    const mesmo = node(script, ['--origem', 'a_teste', '--destino', 'a_teste']);
    esperar(mesmo.codigo === 1 && mesmo.saida.includes('não pode ser o de origem'), 'origem igual ao destino deveria ser recusada');
    esperar(node(script, []).codigo === 1, 'sem argumentos deveria mostrar o uso');
});

teste('validar-rebase/linhas-perdidas.mjs: acha a linha do commit de fora removida pelo local', () => {
    const pasta = novoRepositorio('rebase');
    writeFileSync(join(pasta, 'x.txt'), 'a\nb\n');
    git(pasta, 'add', '.');
    git(pasta, 'commit', '-qm', 'base');
    writeFileSync(join(pasta, 'x.txt'), 'a\nb\nnova1\nnova2\n');
    git(pasta, 'commit', '-qam', 'fora');
    writeFileSync(join(pasta, 'x.txt'), 'a\nb\nnova1\nlocal\n');
    git(pasta, 'commit', '-qam', 'local');
    const saida = node(join(SKILLS, 'validar-rebase', 'scripts', 'linhas-perdidas.mjs'), ['HEAD~1', 'HEAD~2', 'HEAD'], { cwd: pasta }).saida;
    esperar(saida.includes('- nova2') && saida.includes('1 linha(s) para explicar') && !saida.includes('- nova1'), saida);
});

teste('sincronizar-gitconfig: estados, CRLF e trocas nos dois sentidos', () => {
    const script = join(SKILLS, 'sincronizar-gitconfig', 'scripts', 'sincronizar-gitconfig.mjs');
    const casa = join(temporaria, 'casa');
    mkdirSync(casa);
    const repo = novoRepositorio('gitconfig');
    git(repo, 'commit', '-q', '--allow-empty', '-m', 'inicio');
    const env = { ...process.env, USERPROFILE: casa, HOME: casa };
    const sync = (...argumentos) => node(script, [...argumentos, '--repo', repo], { env });
    const estado = () => sync('estado').saida.match(/estado: (\S+)/)?.[1];
    const local = join(casa, '.gitconfig');
    writeFileSync(local, '[alias]\n\tst = status\n');
    esperar(estado() === 'primeira-vez', 'esperava primeira-vez');
    sync('para-repositorio');
    git(repo, 'add', '.gitconfig');
    git(repo, 'commit', '-qm', 'a');
    sync('marcar');
    esperar(estado() === 'igual', 'esperava igual');
    writeFileSync(local, '[alias]\r\n\tst = status\r\n');
    esperar(estado() === 'igual', 'CRLF não deveria contar como mudança');
    writeFileSync(local, '[alias]\n\tst = status\n\tco = checkout\n');
    esperar(estado() === 'maquina-mais-nova', 'esperava maquina-mais-nova');
    writeFileSync(local, '[alias]\n\tst = status\n');
    writeFileSync(join(repo, '.gitconfig'), '[alias]\n\tst = status\n\tlg = log\n');
    esperar(estado() === 'repositorio-mais-novo', 'esperava repositorio-mais-novo');
    sync('para-maquina');
    esperar(readFileSync(local, 'utf8').includes('lg = log') && existsSync(`${local}.antes-da-sincronizacao`), 'para-maquina não atualizou');
    esperar(estado() === 'igual', 'esperava igual depois de para-maquina');
    writeFileSync(join(repo, '.gitconfig'), '[alias]\n\tst = status\n\tlg = log\n\tbr = branch\n');
    writeFileSync(local, '[alias]\n\tst = status\n\tlg = log\n\tx = y\n');
    esperar(estado() === 'conflito', 'esperava conflito');
    esperar(sync('marcar').codigo !== 0, 'marcar com diferença deveria falhar');
});

teste('sintaxe: scripts Node e PowerShell', () => {
    for (const script of [join(SKILLS, 'medir-layout', 'scripts', 'medir-layout.js'), join(SKILLS, 'revisar-padroes', 'scripts', 'verificar-imports.mjs'),
        join(CENTRAL, 'projetos', 'dashboard-frt', 'api-teste', 'scripts', 'ambiente-teste.mjs')]) {
        const resultado = rodar(process.execPath, ['--check', script]);
        esperar(resultado.codigo === 0, `${script}: ${resultado.saida}`);
    }
    const powershell = [join(SKILLS, 'doc-sync', 'scripts', 'kb-tools.ps1'), join(CENTRAL, 'projetos', 'cargas', 'doc-sync', 'scripts', 'auditoria.ps1'),
        join(SKILLS, 'iniciar-dashboard-frt', 'scripts', 'instalar-alias.ps1'), join(SKILLS, 'iniciar-dashboard-frt', 'scripts', 'executar.ps1'),
        join(CENTRAL, 'instalar.ps1'), join(CENTRAL, 'verificar-projetos.ps1')];
    const lista = powershell.map((p) => `'${p.replaceAll("'", "''")}'`).join(',');
    const comando = `$total = 0; foreach ($p in @(${lista})) { $e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$e); if ($e.Count) { Write-Output "$p : $($e[0].Message)"; $total += $e.Count } }; exit $total`;
    const resultado = rodar('powershell', ['-NoProfile', '-Command', comando]);
    esperar(resultado.codigo === 0, resultado.saida.trim());
});

teste('revisar-padroes/verificar-imports.mjs: aponta pirâmide fora de ordem', () => {
    const certo = join(temporaria, 'certo.ts');
    const errado = join(temporaria, 'errado.ts');
    writeFileSync(certo, "import { a } from 'a';\nimport { bb } from 'bb';\n");
    writeFileSync(errado, "import { bb } from 'bb';\nimport { a } from 'a';\n");
    const script = join(SKILLS, 'revisar-padroes', 'scripts', 'verificar-imports.mjs');
    esperar(node(script, ['--verificar', certo]).codigo === 0, 'arquivo certo foi apontado');
    esperar(node(script, ['--verificar', errado]).codigo === 1, 'arquivo errado não foi apontado');
});

rmSync(temporaria, { recursive: true, force: true });
for (const r of resultados) console.log(`${r.ok ? 'ok   ' : 'FALHA'} ${r.nome}${r.ok ? '' : `\n      ${r.detalhe}`}`);
const falhas = resultados.filter((r) => !r.ok).length;
console.log(`${resultados.length - falhas}/${resultados.length} testes passaram`);
process.exitCode = falhas ? 1 : 0;
