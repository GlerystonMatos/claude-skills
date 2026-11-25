import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PORTA = Number(process.argv[2] ?? 5301);
const PASTA_SCRIPT = path.dirname(fileURLToPath(import.meta.url));
const PASTA_DUMPS = process.argv[3] ?? path.join(process.cwd(), 'medicoes');
fs.mkdirSync(PASTA_DUMPS, { recursive: true });
const registro = [];

const estabelecimentos = [
    { chave: 10, codigo: '001', nome: 'Matriz Fortaleza' },
    { chave: 11, codigo: '002', nome: 'Filial Recife' },
];
const depositos = { 10: [{ chave: 100, codigo: 'D01', nome: 'Depósito de pneus novos' }, { chave: 101, codigo: 'D02', nome: 'Depósito de recapagem' }], 11: [{ chave: 110, codigo: 'D11', nome: 'Depósito Recife' }] };
const realizadores = [{ chave: 7, codigo: 'M01', nome: 'Maria Souza' }, { chave: 8, codigo: 'J02', nome: 'João Lima' }];
const veiculos = [
    { chave: 500, codigo: 'ABC1D23', nome: 'Cavalo Volvo FH', leiaute: 1, placa: 'ABC1D23' },
    { chave: 501, codigo: 'XYZ9K88', nome: 'Carreta Randon', leiaute: 2, placa: 'XYZ9K88' },
    { chave: 502, codigo: 'SEM0L00', nome: 'Dolly sem leiaute', leiaute: null, placa: 'SEM0L00' },
    { chave: 600, codigo: 'IND1A11', nome: 'Toco isolado', leiaute: 3, placa: 'IND1A11' },
];

function pneu(chave, codigo, tipoVida, descricaoVida) {
    return { chave, lote: chave, codigo, nome: `Pneu ${codigo} 295/80R22.5`, posicao: 1, tipoVida, descricaoVida };
}

function posicao(chave, codigo, nome, ordem, pneuAtual) {
    return { chave, chaveVinculo: chave + 10000, codigo, nome, ordem, ocupada: !!pneuAtual, pneu: pneuAtual };
}

const estruturas = {
    500: {
        veiculo: { chave: 500, codigo: 'ABC1D23', nome: 'Cavalo Volvo FH' },
        leiaute: { chave: 1, codigo: 'L6X4', nome: 'Cavalo 6x4', quantidadeEixos: 3, quantidadePneus: 10 },
        eixos: [
            { chave: 1, chaveCadastro: 91, codigo: 'E1', nome: 'Direcional', ordem: 1, quantidadePneus: 2, podeSerSuspenso: false, posicoes: [
                posicao(1, 'LE', 'Lado esquerdo', 1, pneu(9001, 'FG1001', 99, '1ª Vida')),
                posicao(2, 'LD', 'Lado direito', 2, pneu(9002, 'FG1002', 1, '1º Recape')),
            ] },
            { chave: 2, chaveCadastro: 92, codigo: 'E2', nome: 'Tração', ordem: 2, quantidadePneus: 4, podeSerSuspenso: false, posicoes: [
                posicao(3, 'LEE', 'Esquerdo externo', 1, pneu(9003, 'FG1003', 2, '2º Recape')),
                posicao(4, 'LEI', 'Esquerdo interno', 2, null),
                posicao(5, 'LDI', 'Direito interno', 3, pneu(9005, 'FG1005', 9, 'Sucateado')),
                posicao(6, 'LDE', 'Direito externo', 4, null),
            ] },
            { chave: 3, chaveCadastro: 93, codigo: 'E3', nome: 'Tração', ordem: 3, quantidadePneus: 4, podeSerSuspenso: true, posicoes: [
                posicao(7, 'LEE', 'Esquerdo externo', 1, pneu(9007, 'FG1007', null, null)),
                posicao(8, 'LEI', 'Esquerdo interno', 2, pneu(9008, 'FG1008', 3, '3º Recape')),
                posicao(9, 'LDI', 'Direito interno', 3, null),
                posicao(10, 'LDE', 'Direito externo', 4, pneu(9010, 'FG1010', 4, '4º Recape')),
            ] },
        ],
        steps: [posicao(20, 'ST1', 'Estepe 1', 1, pneu(9020, 'FG1020', 99, '1ª Vida')), posicao(21, 'ST2', 'Estepe 2', 2, null)],
    },
    501: {
        veiculo: { chave: 501, codigo: 'XYZ9K88', nome: 'Carreta Randon' },
        leiaute: { chave: 2, codigo: 'C3E', nome: 'Carreta 3 eixos', quantidadeEixos: 2, quantidadePneus: 8 },
        eixos: [1, 2].map((ordem) => ({ chave: 10 + ordem, chaveCadastro: 80 + ordem, codigo: `C${ordem}`, nome: 'Livre', ordem, quantidadePneus: 4, podeSerSuspenso: false, posicoes: [
            posicao(30 + ordem * 4, 'LEE', 'Esquerdo externo', 1, ordem === 1 ? pneu(9100 + ordem, `FG2${ordem}01`, 5, '5º Recape') : null),
            posicao(31 + ordem * 4, 'LEI', 'Esquerdo interno', 2, pneu(9110 + ordem, `FG2${ordem}02`, 6, '6º Recape')),
            posicao(32 + ordem * 4, 'LDI', 'Direito interno', 3, null),
            posicao(33 + ordem * 4, 'LDE', 'Direito externo', 4, pneu(9120 + ordem, `FG2${ordem}04`, 7, '7º Recape')),
        ] })),
        steps: [],
    },
    600: {
        veiculo: { chave: 600, codigo: 'IND1A11', nome: 'Toco isolado' },
        leiaute: { chave: 3, codigo: 'T4X2', nome: 'Toco 4x2', quantidadeEixos: 2, quantidadePneus: 6 },
        eixos: [
            { chave: 61, chaveCadastro: 71, codigo: 'D1', nome: 'Direcional', ordem: 1, quantidadePneus: 2, podeSerSuspenso: false, posicoes: [
                posicao(61, '1', 'Posição 1', 1, pneu(9601, 'FG6001', 8, '8º Recape')),
                posicao(62, '2', 'Posição 2', 2, null),
            ] },
            { chave: 62, chaveCadastro: 72, codigo: 'T1', nome: 'Tração', ordem: 2, quantidadePneus: 4, podeSerSuspenso: false, posicoes: [
                posicao(63, '3', 'Posição 3', 1, pneu(9603, 'FG6003', 99, '1ª Vida')),
                posicao(64, '4', 'Posição 4', 2, pneu(9604, 'FG6004', 1, '1º Recape')),
                posicao(65, '5', 'Posição 5', 3, null),
                posicao(66, '6', 'Posição 6', 4, pneu(9606, 'FG6006', 2, '2º Recape')),
            ] },
        ],
        steps: [],
    },
};

const pneusDisponiveis = [
    { chave: 7001, lote: 7001, codigo: 'NV7001', nome: 'Pneu novo 295/80R22.5', deposito: 100, saldo: 1 },
    { chave: 7002, lote: 7002, codigo: 'NV7002', nome: 'Pneu novo 275/80R22.5', deposito: 100, saldo: 1 },
    { chave: 7003, lote: 7003, codigo: 'SALDO0', nome: 'Pneu sem saldo', deposito: 100, saldo: 0 },
];
const motivos = [
    { chave: 40, codigo: 'M1', nome: 'Desgaste', situacao: 1, tipo: 1, finaliza: false },
    { chave: 41, codigo: 'M2', nome: 'Furo', situacao: 1, tipo: 1, finaliza: false },
];

function filtrar(lista, busca) {
    if (!busca) return lista;
    const termo = busca.toLowerCase();
    return lista.filter((item) => `${item.codigo} ${item.nome}`.toLowerCase().includes(termo));
}

function responder(resposta, status, corpo) {
    resposta.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*' });
    resposta.end(corpo === undefined ? '' : JSON.stringify(corpo));
}

function lerCorpo(requisicao) {
    return new Promise((resolver) => {
        let texto = '';
        requisicao.on('data', (parte) => { texto += parte; });
        requisicao.on('end', () => resolver(texto));
    });
}

const movimentacaoEdicao = {
    agenteDetalhes: realizadores[0], agente: 7, veiculo: 600, veiculoDetalhes: veiculos[3], data: '2026-11-20T00:00:00', estabelecimento: 10,
    estabelecimentoDetalhes: estabelecimentos[0], chave: 3210, temLancamentoPosterior: false, hodometro: 123456, tipo: 1, hora: '08:15',
    itens: [{ pneuDetalhes: { chave: 7001, codigo: 'NV7001', nome: 'Pneu novo 295/80R22.5' }, defeitoDetalhes: null, evento: 1,
        posicaoDetalhes: { chave: 62, codigo: '2', nome: 'Posição 2', chaveVinculo: 10062, step: false, eixo: { chave: 61, codigo: 'D1', nome: 'Direcional' } },
        defeito: null, chave: 777, veiculo: 600, nucleo: 62, depositoDetalhes: depositos[10][0], lote: 7001, observacao: 'Montado na revisão', chCriacao: 100 }],
};

http.createServer(async (requisicao, resposta) => {
    const url = new URL(requisicao.url, `http://localhost:${PORTA}`);
    const corpoTexto = await lerCorpo(requisicao);
    if (requisicao.method === 'OPTIONS') {
        resposta.writeHead(204, { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, Accept', 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS' });
        resposta.end();
        return;
    }
    if (url.pathname === '/dump') {
        const nome = url.searchParams.get('nome').replace(/[^a-z0-9-]/gi, '');
        fs.writeFileSync(path.join(PASTA_DUMPS, `${nome}.json`), corpoTexto);
        responder(resposta, 200, { ok: true });
        return;
    }
    if (url.pathname === '/roteiro.js') {
        resposta.writeHead(200, { 'Content-Type': 'text/javascript', 'Access-Control-Allow-Origin': '*' });
        resposta.end(fs.readFileSync(path.join(PASTA_SCRIPT, 'roteiro-navegador.js')));
        return;
    }
    if (url.pathname === '/registro') {
        responder(resposta, 200, registro.splice(0));
        return;
    }
    registro.push({ metodo: requisicao.method, caminho: url.pathname, consulta: url.search, autorizacao: requisicao.headers.authorization ?? null, tipo: requisicao.headers['content-type'] ?? null, corpo: corpoTexto || null });
    const rota = url.pathname.replace('/api/assistente-pneus', '');
    const busca = url.searchParams.get('busca') ?? '';
    const veiculo = Number(url.searchParams.get('veiculo'));
    if (requisicao.headers.authorization !== 'Bearer teste') return responder(resposta, 401, { message: 'não autorizado' });
    await new Promise((resolver) => setTimeout(resolver, 150));
    if (busca.includes('falha')) return responder(resposta, 500, { error: { message: 'Falha simulada na busca' } });
    switch (`${requisicao.method} ${rota}`) {
        case 'GET /estabelecimentos': return responder(resposta, 200, filtrar(estabelecimentos, busca));
        case 'GET /depositos-pneus': return responder(resposta, 200, filtrar(depositos[url.searchParams.get('estabelecimento')] ?? [], busca));
        case 'GET /realizadores': return responder(resposta, 200, filtrar(realizadores, busca));
        case 'GET /veiculos': return responder(resposta, 200, filtrar(veiculos, busca));
        case 'GET /conjunto-atrelado': {
            const marca = path.join(PASTA_DUMPS, 'falhar-conjunto');
            if (fs.existsSync(marca)) { fs.rmSync(marca); return responder(resposta, 500, { message: 'Falha simulada no conjunto' }); }
            if (veiculo === 600) return responder(resposta, 200, { veiculoSelecionado: 600, veiculoTracionado: 600, possuiAtrelamentos: false, veiculos: [{ ...veiculos[3], tracionado: true, selecionado: true }] });
            return responder(resposta, 200, { veiculoSelecionado: veiculo, veiculoTracionado: 500, possuiAtrelamentos: true, veiculos: veiculos.slice(0, 3).map((item) => ({ ...item, tracionado: item.chave === 500, selecionado: item.chave === veiculo })) });
        }
        case 'GET /estrutura-veiculo': return estruturas[veiculo] ? responder(resposta, 200, estruturas[veiculo]) : responder(resposta, 404, { message: 'Estrutura não encontrada' });
        case 'GET /ultimo-hodometro': return responder(resposta, 200, { veiculo, hodometro: veiculo === 501 ? null : 150000 });
        case 'GET /pneus-disponiveis': return responder(resposta, 200, filtrar(pneusDisponiveis, busca));
        case 'GET /motivos-desmontagem': return responder(resposta, 200, filtrar(motivos, busca));
        case 'GET /movimentacoes': return responder(resposta, 200, movimentacaoEdicao);
        case 'DELETE /movimentacoes': return responder(resposta, 200, { chave: Number(url.searchParams.get('chave')), mensagem: 'Movimentação excluída.' });
        case 'PUT /movimentacoes': return responder(resposta, 200, { chave: JSON.parse(corpoTexto).chave, versao: 2, mensagem: 'Movimentação atualizada com sucesso.' });
        case 'POST /movimentacoes': {
            const corpo = JSON.parse(corpoTexto);
            if (corpo.itens.some((item) => item.lote === 7003)) return responder(resposta, 400, { errorCode: 25, message: 'Saldo insuficiente. Lote: "SALDO0 (7003)" Depósito: "D01 - Depósito de pneus novos (100)"' });
            if (corpo.hodometro !== null && corpo.hodometro < 1000 && !corpo.confirmarGiro) return responder(resposta, 200, { requerConfirmacaoGiro: true, mensagem: 'Hodômetro informado (500) menor que o último (150000). Distância real: 850500 km.' });
            return responder(resposta, 200, { movimentacoes: [{ chave: 4321, versao: 1, veiculo: corpo.veiculo, quantidadeItens: corpo.itens.length }], quantidadeMovimentacoes: 1, mensagem: 'Movimentação gravada com sucesso.' });
        }
        default: return responder(resposta, 404, { message: `Rota não simulada: ${rota}` });
    }
}).listen(PORTA, () => console.log(`API simulada em http://localhost:${PORTA}`));
