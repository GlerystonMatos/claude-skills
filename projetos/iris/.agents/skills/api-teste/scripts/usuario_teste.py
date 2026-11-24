import base64
import hashlib
import io
import json
import secrets
import sys
import uuid
from datetime import datetime, timezone
import urllib.request
from pathlib import Path

LOGIN = 'teste-validacao'
ITERACOES = 600_000


def gerar_hash(senha: str) -> str:
    salt = secrets.token_bytes(16)
    derivado = hashlib.pbkdf2_hmac('sha256', senha.encode('utf-8'), salt, ITERACOES, 32)
    return f'pbkdf2-sha256${ITERACOES}${base64.b64encode(salt).decode()}${base64.b64encode(derivado).decode()}'


def preparar(scratch: Path) -> None:
    usuarios_arquivo = scratch / 'api-dados' / 'AppUsuarios.json'
    credencial = scratch / 'usuario-teste.json'
    dados = json.load(io.open(usuarios_arquivo, encoding='utf-8'))
    usuarios = dados['usuarios']
    if any(usuario.get('login') == LOGIN for usuario in usuarios) and credencial.exists():
        print(f'{LOGIN} já existe na cópia')
        return
    senha = secrets.token_urlsafe(18)
    usuarios[:] = [usuario for usuario in usuarios if usuario.get('login') != LOGIN]
    usuarios.append({
        'id': uuid.uuid4().hex,
        'login': LOGIN,
        'nome': 'Teste de validação',
        'hashSenha': gerar_hash(senha),
        'tipo': 'Interno',
        'perfilId': 'administrador',
        'ativo': True,
        'trocarSenhaNoProximoAcesso': False,
        'versaoSeguranca': 1,
        'criadoEm': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    })
    io.open(usuarios_arquivo, 'w', encoding='utf-8').write(json.dumps(dados, ensure_ascii=False))
    io.open(credencial, 'w', encoding='utf-8').write(json.dumps({'login': LOGIN, 'senha': senha}))
    print(f'{LOGIN} criado na cópia; credencial em {credencial} (não exibir)')


def sessao(scratch: Path, saida: Path, base: str) -> None:
    credencial = json.load(io.open(scratch / 'usuario-teste.json', encoding='utf-8'))
    requisicao = urllib.request.Request(
        f'{base}/api/auth/login',
        data=json.dumps(credencial).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST')
    resposta = json.loads(urllib.request.urlopen(requisicao).read())
    armazenada = {'tokenAcesso': resposta['tokenAcesso'], 'tokenRenovacao': resposta['tokenRenovacao'], 'lembrar': False, 'usuario': resposta['usuario']}
    io.open(saida, 'w', encoding='utf-8').write(json.dumps(json.dumps(armazenada)))
    print(f'sessão de {resposta["usuario"]["login"]} gravada em {saida} (apagar logo após o uso)')


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] not in ('preparar', 'sessao'):
        print('uso: usuario_teste.py preparar <scratchpad> | sessao <scratchpad> <arquivo-saida> [url-api]')
        return 2
    scratch = Path(sys.argv[2])
    if sys.argv[1] == 'preparar':
        preparar(scratch)
    else:
        sessao(scratch, Path(sys.argv[3]), sys.argv[4] if len(sys.argv) > 4 else 'http://localhost:5290')
    return 0


if __name__ == '__main__':
    sys.exit(main())
