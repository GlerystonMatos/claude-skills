import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { pbkdf2Sync, randomBytes, randomUUID } from 'node:crypto';
import { join } from 'node:path';

const LOGIN = 'teste-validacao';

function loginDoPerfil(perfil) {
    return perfil === undefined ? LOGIN : `teste-${perfil.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')}`;
}

function arquivoCredencial(scratch, perfil) {
    return join(scratch, perfil === undefined ? 'usuario-teste.json' : `usuario-${loginDoPerfil(perfil)}.json`);
}
const ITERACOES = 600_000;

function sair(mensagem) {
    console.error(mensagem);
    process.exit(1);
}

function gerarHash(senha) {
    const salt = randomBytes(16);
    const derivado = pbkdf2Sync(senha, salt, ITERACOES, 32, 'sha256');
    return `pbkdf2-sha256$${ITERACOES}$${salt.toString('base64')}$${derivado.toString('base64')}`;
}

function usuarioDoModelo(modelo, hash, perfil) {
    const login = loginDoPerfil(perfil);
    const nome = perfil === undefined ? 'Teste de validação' : `Teste de validação (${perfil})`;
    const base = { login, nome, hashSenha: hash, perfilId: perfil ?? 'administrador', versaoSeguranca: 1 };
    if (modelo === 'argos') {
        return { ...base, temImagem: false, colaborador: { chave: login, sigla: perfil === undefined ? 'TST' : 'TSP', cor: '#9e9e9e' } };
    }
    if (modelo === 'iris') {
        return {
            id: randomUUID().replaceAll('-', ''),
            ...base,
            tipo: 'Interno',
            ativo: true,
            trocarSenhaNoProximoAcesso: false,
            criadoEm: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
        };
    }
    return sair(`Modelo desconhecido: ${modelo} (use argos ou iris).`);
}

function validarPerfil(pastaDados, perfil) {
    if (perfil === undefined) return;
    const arquivoPerfis = join(pastaDados, 'AppPerfis.json');
    if (!existsSync(arquivoPerfis)) return;
    const dados = JSON.parse(readFileSync(arquivoPerfis, 'utf8').replace(/^\uFEFF/, ''));
    const perfis = Array.isArray(dados) ? dados : dados.perfis ?? [];
    if (!perfis.some((item) => item.id === perfil)) {
        sair(`Perfil ${perfil} não existe na cópia. Perfis: ${perfis.map((item) => `${item.id} (${item.nome})`).join(', ')}`);
    }
}

function preparar(scratch, pastaDados, modelo, perfil) {
    const arquivoUsuarios = join(pastaDados, 'AppUsuarios.json');
    const credencial = arquivoCredencial(scratch, perfil);
    const login = loginDoPerfil(perfil);
    if (!existsSync(arquivoUsuarios)) sair(`${arquivoUsuarios} não existe na cópia; use o acesso inicial (bootstrap).`);
    validarPerfil(pastaDados, perfil);
    const dados = JSON.parse(readFileSync(arquivoUsuarios, 'utf8').replace(/^\uFEFF/, ''));
    if (dados.usuarios.some((usuario) => usuario.login === login) && existsSync(credencial)) {
        console.log(`${login} já existe na cópia`);
        return;
    }
    const senha = randomBytes(18).toString('base64url');
    dados.usuarios = dados.usuarios.filter((usuario) => usuario.login !== login);
    dados.usuarios.push(usuarioDoModelo(modelo, gerarHash(senha), perfil));
    writeFileSync(arquivoUsuarios, JSON.stringify(dados));
    writeFileSync(credencial, JSON.stringify({ login, senha }));
    console.log(`${login} criado na cópia${perfil === undefined ? '' : ` com o perfil ${perfil}`}; credencial em ${credencial} (não exibir)`);
}

async function sessao(scratch, saida, url, perfil) {
    const arquivo = arquivoCredencial(scratch, perfil);
    if (!existsSync(arquivo)) sair(`${arquivo} não existe: rode antes o preparar${perfil === undefined ? '' : ` com --perfil ${perfil}`}.`);
    const credencial = JSON.parse(readFileSync(arquivo, 'utf8'));
    const resposta = await fetch(`${url}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credencial),
    });
    if (!resposta.ok) sair(`Login falhou: HTTP ${resposta.status}`);
    const corpo = await resposta.json();
    const armazenada = { tokenAcesso: corpo.tokenAcesso, tokenRenovacao: corpo.tokenRenovacao, lembrar: false, usuario: corpo.usuario };
    writeFileSync(saida, JSON.stringify(JSON.stringify(armazenada)));
    console.log(`sessão de ${corpo.usuario.login} gravada em ${saida} (apagar logo após o uso)`);
}

function opcao(lista, nome) {
    const indice = lista.indexOf(`--${nome}`);
    return indice >= 0 ? lista[indice + 1] : undefined;
}

const [comando, scratch, ...resto] = process.argv.slice(2);
if (comando === 'preparar' && scratch && opcao(resto, 'dados') && opcao(resto, 'modelo')) {
    preparar(scratch, opcao(resto, 'dados'), opcao(resto, 'modelo'), opcao(resto, 'perfil'));
} else if (comando === 'sessao' && scratch && resto[0] && opcao(resto, 'url')) {
    await sessao(scratch, resto[0], opcao(resto, 'url'), opcao(resto, 'perfil'));
} else {
    sair('Uso: node usuario-teste.mjs preparar <scratchpad> --dados <pasta com AppUsuarios.json> --modelo argos|iris [--perfil <id do perfil>]\n'
        + '     node usuario-teste.mjs sessao <scratchpad> <arquivo-saida> --url <url da API> [--perfil <id do perfil>]');
}
