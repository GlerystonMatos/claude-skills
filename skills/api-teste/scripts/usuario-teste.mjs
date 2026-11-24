import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { pbkdf2Sync, randomBytes, randomUUID } from 'node:crypto';
import { join } from 'node:path';

const LOGIN = 'teste-validacao';
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

function usuarioDoModelo(modelo, hash) {
    const base = { login: LOGIN, nome: 'Teste de validação', hashSenha: hash, perfilId: 'administrador', versaoSeguranca: 1 };
    if (modelo === 'argos') {
        return { ...base, temImagem: false, colaborador: { chave: LOGIN, sigla: 'TST', cor: '#9e9e9e' } };
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

function preparar(scratch, pastaDados, modelo) {
    const arquivoUsuarios = join(pastaDados, 'AppUsuarios.json');
    const credencial = join(scratch, 'usuario-teste.json');
    if (!existsSync(arquivoUsuarios)) sair(`${arquivoUsuarios} não existe na cópia; use o acesso inicial (bootstrap).`);
    const dados = JSON.parse(readFileSync(arquivoUsuarios, 'utf8').replace(/^﻿/, ''));
    if (dados.usuarios.some((usuario) => usuario.login === LOGIN) && existsSync(credencial)) {
        console.log(`${LOGIN} já existe na cópia`);
        return;
    }
    const senha = randomBytes(18).toString('base64url');
    dados.usuarios = dados.usuarios.filter((usuario) => usuario.login !== LOGIN);
    dados.usuarios.push(usuarioDoModelo(modelo, gerarHash(senha)));
    writeFileSync(arquivoUsuarios, JSON.stringify(dados));
    writeFileSync(credencial, JSON.stringify({ login: LOGIN, senha }));
    console.log(`${LOGIN} criado na cópia; credencial em ${credencial} (não exibir)`);
}

async function sessao(scratch, saida, url) {
    const credencial = JSON.parse(readFileSync(join(scratch, 'usuario-teste.json'), 'utf8'));
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
    preparar(scratch, opcao(resto, 'dados'), opcao(resto, 'modelo'));
} else if (comando === 'sessao' && scratch && resto[0] && opcao(resto, 'url')) {
    await sessao(scratch, resto[0], opcao(resto, 'url'));
} else {
    sair('Uso: node usuario-teste.mjs preparar <scratchpad> --dados <pasta com AppUsuarios.json> --modelo argos|iris\n'
        + '     node usuario-teste.mjs sessao <scratchpad> <arquivo-saida> --url <url da API>');
}
