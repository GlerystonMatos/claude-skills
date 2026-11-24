import { createHmac, randomBytes, randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, openSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { copiarBanco, executarPg } from '../../../../skills/api-teste/scripts/copiar-postgres.mjs';

const BANCO_TESTE = 'dashboard_frt_teste';
const PORTA_API = 5290;
const URL_API = `http://localhost:${PORTA_API}`;
const PASTA_API = resolve(process.env.DASHBOARD_FRT_API ?? join(process.cwd(), '..', 'dashboard-frt-api'));
const PROJETO_API = join(PASTA_API, 'DashboardFrt.Api');

function sair(mensagem) {
    console.error(mensagem);
    process.exit(1);
}

function lerJson(caminho) {
    return JSON.parse(readFileSync(caminho, 'utf8').replace(/^\uFEFF/, ''));
}

function lerEnvApi() {
    const caminho = join(PASTA_API, '.env');
    if (!existsSync(caminho)) return {};
    const valores = {};
    for (const linha of readFileSync(caminho, 'utf8').split(/\r?\n/)) {
        const correspondencia = linha.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
        if (correspondencia) valores[correspondencia[1]] = correspondencia[2].replace(/^["']|["']$/g, '');
    }
    return valores;
}

function lerConexao(texto) {
    const partes = {};
    for (const par of texto.split(';')) {
        const indice = par.indexOf('=');
        if (indice > 0) partes[par.slice(0, indice).trim().toLowerCase()] = par.slice(indice + 1).trim();
    }
    const host = partes.host === 'host.docker.internal' ? '127.0.0.1' : (partes.host ?? '127.0.0.1');
    return {
        host,
        porta: partes.port ?? '5432',
        banco: partes.database ?? 'dashboard_frt',
        usuario: partes.username ?? partes['user id'] ?? 'postgres',
        senha: partes.password ?? '',
    };
}

function conexaoOrigem() {
    const env = lerEnvApi();
    if (env.CONNECTION_STRING) return lerConexao(env.CONNECTION_STRING);
    const desenvolvimento = join(PROJETO_API, 'appsettings.Development.json');
    if (existsSync(desenvolvimento)) {
        const texto = lerJson(desenvolvimento).ConnectionStrings?.DefaultConnection;
        if (texto) return lerConexao(texto);
    }
    return sair('Conexão do PostgreSQL não encontrada (CONNECTION_STRING no .env da API ou appsettings.Development.json).');
}

function textoConexao(conexao, banco) {
    return `Host=${conexao.host};Port=${conexao.porta};Database=${banco};Username=${conexao.usuario};Password=${conexao.senha}`;
}

function caminhoConfig(scratch) {
    return join(scratch, 'api-teste.json');
}

function lerConfig(scratch) {
    const caminho = caminhoConfig(scratch);
    if (!existsSync(caminho)) sair('Rode antes: node ambiente-teste.mjs banco <scratchpad>');
    return lerJson(caminho);
}

function banco(scratch, recriar) {
    mkdirSync(scratch, { recursive: true });
    const origem = conexaoOrigem();
    if (origem.banco === BANCO_TESTE) sair('A conexão de origem já aponta para o banco de teste.');
    copiarBanco(origem, origem.banco, BANCO_TESTE, { recriar, pastaTemporaria: scratch });

    const caminho = caminhoConfig(scratch);
    const anterior = existsSync(caminho) ? lerJson(caminho) : {};
    writeFileSync(caminho, JSON.stringify({
        conexao: textoConexao(origem, BANCO_TESTE),
        chaveJwt: anterior.chaveJwt ?? randomBytes(48).toString('base64'),
    }, null, 2));
    console.log(`Configuração de teste gravada em ${caminho} (não exibir).`);
}

function licenciados(scratch) {
    const config = lerConfig(scratch);
    const conexao = lerConexao(config.conexao);
    const saida = executarPg('psql', ['-d', conexao.banco, '-tAF', ' | ', '-c', 'select "Id", "Nome", "Ativo" from "Licenciados" order by "Nome"'], conexao);
    console.log(saida.trim() || 'Nenhum licenciado no banco de teste.');
}

async function aguardarSaude(segundos) {
    for (let tentativa = 0; tentativa < segundos; tentativa++) {
        try {
            const resposta = await fetch(`${URL_API}/HealthCheck/Check`);
            if (resposta.ok) return true;
        } catch {
            await new Promise((resolver) => setTimeout(resolver, 1000));
            continue;
        }
        await new Promise((resolver) => setTimeout(resolver, 1000));
    }
    return false;
}

async function api(scratch) {
    const config = lerConfig(scratch);
    const env = lerEnvApi();
    const pastaPublicacao = join(scratch, 'api');
    const log = join(scratch, 'api.log');

    console.log('Publicando a API no scratchpad...');
    const publicacao = spawnSync('dotnet', ['publish', PROJETO_API, '-c', 'Release', '-o', pastaPublicacao, '--nologo', '-v', 'q'], { encoding: 'utf8' });
    if (publicacao.status !== 0) sair(`dotnet publish falhou:\n${publicacao.stdout}\n${publicacao.stderr}`);

    const variaveis = {
        ...process.env,
        ASPNETCORE_ENVIRONMENT: 'Development',
        ASPNETCORE_URLS: URL_API,
        ConnectionStrings__DefaultConnection: config.conexao,
        Jwt__SecretKey: config.chaveJwt,
        HTTPS_PROXY: 'http://127.0.0.1:9',
        HTTP_PROXY: 'http://127.0.0.1:9',
        NO_PROXY: 'localhost,127.0.0.1',
    };
    if (env.AUTOMAPPER_LICENSE_KEY) variaveis.AutoMapper__LicenseKey = env.AUTOMAPPER_LICENSE_KEY;
    if (env.FUSO_HORARIO) variaveis.FUSO_HORARIO = env.FUSO_HORARIO;

    const saida = openSync(log, 'w');
    const processo = spawn('dotnet', [join(pastaPublicacao, 'DashboardFrt.Api.dll')], {
        cwd: pastaPublicacao,
        env: variaveis,
        detached: true,
        stdio: ['ignore', saida, saida],
        windowsHide: true,
    });
    processo.unref();
    writeFileSync(join(scratch, 'api.pid'), String(processo.pid));

    if (await aguardarSaude(90)) console.log(`API de teste no ar em ${URL_API} (PID ${processo.pid}, log em ${log}).`);
    else sair(`A API não respondeu em ${URL_API}/HealthCheck/Check; veja ${log}.`);
}

function base64Url(valor) {
    return Buffer.from(valor).toString('base64url');
}

function token(scratch, destino, licenciadoId) {
    if (!destino) sair('Informe o arquivo de destino do token.');
    const config = lerConfig(scratch);
    const jwt = lerJson(join(PROJETO_API, 'appsettings.json')).Jwt ?? {};
    const perfil = licenciadoId ? 'AdminLicenciado' : 'AdminGlobal';
    const agora = Math.floor(Date.now() / 1000);
    const cabecalho = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const carga = base64Url(JSON.stringify({
        id: randomUUID(),
        unique_name: 'Teste de validação',
        email: 'teste@validacao.local',
        perfil,
        role: perfil,
        licenciadoId: licenciadoId ?? '',
        nbf: agora,
        iat: agora,
        exp: agora + 4 * 3600,
        iss: jwt.Issuer ?? 'DashboardFrt.Api',
        aud: jwt.Audience ?? 'DashboardFrt',
    }));
    const assinatura = createHmac('sha256', Buffer.from(config.chaveJwt, 'utf8')).update(`${cabecalho}.${carga}`).digest('base64url');
    mkdirSync(dirname(resolve(destino)), { recursive: true });
    writeFileSync(destino, `${cabecalho}.${carga}.${assinatura}`);
    console.log(`Token de teste (${perfil}) gravado em ${destino} (não exibir; vale 4 h).`);
}

function parar(scratch) {
    const arquivoPid = join(scratch, 'api.pid');
    if (!existsSync(arquivoPid)) {
        console.log('Nenhuma API de teste registrada.');
        return;
    }
    const pid = readFileSync(arquivoPid, 'utf8').trim();
    spawnSync('taskkill', ['/F', '/T', '/PID', pid], { encoding: 'utf8' });
    rmSync(arquivoPid, { force: true });
    console.log(`API de teste encerrada (PID ${pid}).`);
}

const [comando, scratch, ...resto] = process.argv.slice(2);
if (!comando || !scratch) sair('Uso: node ambiente-teste.mjs <banco|licenciados|api|token|parar> <scratchpad> [opções]');

switch (comando) {
    case 'banco':
        banco(scratch, resto.includes('--recriar'));
        break;
    case 'licenciados':
        licenciados(scratch);
        break;
    case 'api':
        await api(scratch);
        break;
    case 'token':
        token(scratch, resto[0], resto[1]);
        break;
    case 'parar':
        parar(scratch);
        break;
    default:
        sair(`Comando desconhecido: ${comando}`);
}
