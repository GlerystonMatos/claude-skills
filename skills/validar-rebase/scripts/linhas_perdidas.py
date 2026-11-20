import subprocess
import sys


def git(*args: str) -> str:
    return subprocess.run(['git', *args], capture_output=True, encoding='utf-8', errors='replace').stdout


def linhas(diff: str, sinal: str) -> list[str]:
    marcador = sinal * 3
    return [linha[1:].strip() for linha in diff.splitlines() if linha.startswith(sinal) and not linha.startswith(marcador)]


def main() -> int:
    if len(sys.argv) != 4:
        print('uso: linhas_perdidas.py <commit-de-fora> <base> <commit-local>')
        return 2
    de_fora, base, local = sys.argv[1:]
    arquivos = git('show', '--name-only', '--format=', de_fora).split()
    print(f'{len(arquivos)} arquivo(s) no commit de fora')
    suspeitas = 0
    for arquivo in arquivos:
        adicionadas = set(linhas(git('diff', base, de_fora, '--', arquivo), '+'))
        removidas = [linha for linha in linhas(git('diff', de_fora, local, '--', arquivo), '-') if linha and linha in adicionadas]
        if removidas:
            suspeitas += len(removidas)
            print(f'## {arquivo}: {len(removidas)} linha(s) do commit de fora removida(s) pelo local')
            for linha in removidas:
                print(f'   - {linha[:180]}')
    print(f'{suspeitas} linha(s) para explicar')
    print()
    print('Arquivos do commit de fora alterados pelo local (só podem ser mudanças locais):')
    print(git('diff', '--stat', de_fora, local, '--', *arquivos) or '   nenhum')
    return 0


if __name__ == '__main__':
    sys.exit(main())
