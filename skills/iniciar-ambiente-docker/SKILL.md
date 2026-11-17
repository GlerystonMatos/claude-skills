---
name: iniciar-ambiente-docker
description: Reinicia o ambiente Docker do projeto atual a partir do zero — derruba os containers (docker-compose down), remove as imagens cujo nome contém a palavra informada e sobe tudo de novo (docker-compose up -d), reconstruindo as imagens. Recebe uma palavra obrigatória (ex.: "iniciar-ambiente-docker argos" remove as imagens com "argos" no nome). Use quando o usuário pedir "iniciar ambiente docker", "reiniciar o docker do <projeto>", "recriar as imagens" ou chamar /iniciar-ambiente-docker <palavra>.
argument-hint: <palavra das imagens>
---

# Iniciar ambiente Docker

Equivale a `docker-compose down ; docker rmi $(imagens com a palavra) ; docker-compose up -d`, com a palavra no lugar do nome do projeto.

1. **Palavra**: é o argumento da chamada (ex.: `/iniciar-ambiente-docker argos` → `argos`). Sem palavra, pergunte qual usar e pare. Aceite só
   letras, números, `.`, `_` e `-` (ela entra num filtro de shell); outra coisa → recuse e explique.
2. **Pasta**: rode na raiz do projeto atual, onde está o `docker-compose.yml` (ou `compose.yml`). Sem arquivo de compose → avise e pare.
3. **Comando do compose**: use `docker-compose`; se não existir, `docker compose`. Docker parado (`docker info` falha) → avise e pare.
4. **Derrubar**: `docker-compose down`.
5. **Remover as imagens** com a palavra no nome (só repositório:tag, nunca a linha inteira do `docker images`, que mandaria ao `rmi` a data
   e o tamanho junto):

   ```bash
   imagens=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -i -- "$PALAVRA" | grep -v '<none>')
   [ -n "$imagens" ] && docker rmi $imagens
   ```

   Liste as imagens removidas. Nenhuma encontrada → siga em frente (não é erro). Imagem em uso por outro container que não é deste compose
   → o `rmi` recusa; relate e siga, sem usar `-f`.
6. **Subir**: `docker-compose up -d` (reconstrói as imagens removidas a partir do `build:` do compose; pode demorar — rode com tempo
   limite longo ou em segundo plano).
7. **Conferir**: `docker-compose ps` e relate os serviços e o estado de cada um (Up/Exited). Algum saiu → mostre as últimas linhas de
   `docker-compose logs <serviço>`.

Não remova volumes (`down -v`) nem imagens sem a palavra no nome, e não faça `docker system prune`, salvo pedido explícito.
