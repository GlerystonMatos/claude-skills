---
name: infra-gcp-padrao
description: Prepara (sem aplicar) a infraestrutura GCP de um projeto no padrão do argos-infra (C:\Projetos\argos\argos-infra) — Terraform de Cloud Run, Cloud Build pela branch deploy, Artifact Registry, Firestore e SAs num projeto GCP próprio na mesma conta de faturamento, killswitch central no repositório gcp-finops (C:\Projetos\gcp-finops) — com análise de custo das cotas gratuitas divididas pela conta, conferência do que a aplicação precisa mudar para rodar no Cloud Run (CSP, limite de 32 MiB, disco em memória, variáveis, download de arquivos grandes), monitoramento das cotas na aplicação e passo a passo que nunca perde dados. Use quando o usuário pedir "criar a infra no GCP", "subir na mesma GCP do Argos", "deixar pronto para criar a infra", "quanto vai custar ter outro projeto" ou "incluir o projeto no finops".
argument-hint: [pasta do projeto]
---

# Infra GCP no padrão do Argos

Objetivo: deixar a infra pronta para o usuário aplicar, com custo zero validado e sem risco de perder dado. **Nunca** rodar
`terraform apply`/`destroy`, `gcloud` que altere recurso, nem push na branch `deploy` sem pedido explícito.

## 1. Levantar antes de escrever
- Leia o `argos-infra/` inteiro (README, `criar.md`, `atualizar.md`, `excluir.md`, `cloudbuild.yaml`, `terraform/app`) e o
  `gcp-finops/` (README, `criar.md`, `atualizar.md`, `excluir.md`, `terraform/`, `ferramentas/Inventariar-Gcp.ps1`). Eles são a referência de forma: nomes de arquivo, comentários em pt-BR, ordem dos passos.
- Leia o projeto: Dockerfiles, `nginx.conf` (CSP!), `Program.cs` (CORS, `UseHttpsRedirection`, endpoint de saúde), todas as variáveis
  lidas (`Configuration[...]`, `GetEnvironmentVariable`, `SECAO__CHAVE` = `SECAO:CHAVE`) e onde ficam dados e arquivos.
- Se o `gcloud` estiver logado, meça só com leitura (`gcloud projects list`, `gcloud billing budgets list`, tamanho dos repositórios
  do Artifact Registry e buckets). Sem login, peça `! gcloud auth login` ou deixe a medição no checklist.
- Procure o `terraform.tfstate` das árvores existentes: se não estiver na máquina, o `destroy` não funciona daqui — o roteiro precisa
  dizer de onde trazê-lo e ter o caminho manual.

## 2. Validar o custo (cotas da conta × do projeto)
Monte a tabela **Recurso | Cota gratuita | Escopo | Uso somado | Risco** e confira os valores atuais na documentação oficial
(Free Tier, preços do Cloud Run, Cloud Storage e Cloud Build — a tabela de Cloud Build já apareceu com valores divergentes):
- **Por conta de faturamento** (divididas entre todos os projetos): Cloud Run (requisições, vCPU-s, GiB-s, saída de 1 GiB/mês),
  Cloud Storage (5 GB-mês em us-central1/east1/west1, 100 GB/mês de saída, operações A/B), Artifact Registry (0,5 GB), Cloud Build,
  Secret Manager (6 versões ativas; cada conexão do GitHub usa 1), Functions/Pub/Sub.
- **Por projeto**: Firestore (banco `(default)`), Cloud Logging.
- Projeto, APIs, IAM e orçamentos não custam nada; a conta tem cota de **projetos vinculados**.
- Riscos típicos: arquivo grande servido pela API (saída do Cloud Run), memória alta (GiB-s), imagens acumuladas (Artifact Registry e
  `gcf-artifacts`), soft delete do Cloud Storage (arquivo apagado cobrado por 7 dias), excedente aparecendo no projeto "errado".
- Se o modelo do Argos não servir (ex.: anexos pela API para arquivos grandes), diga com evidência (arquivo:linha) e proponha opções.

## 3. O que a aplicação precisa mudar para o Cloud Run
- CSP com origem da API fixa → gerar do `VITE_API_URL` no build do nginx.
- HTTP/1 limita requisição e resposta sem streaming a 32 MiB: limites de upload/importação abaixo disso, ou download direto do bucket.
- Disco do container = memória: upload em partes deve apagar cada parte ao juntar; `memory` do serviço compatível.
- Pasta local de dados/arquivos some no *cold start*: Firestore, Drive ou bucket obrigatórios.
- Arquivos grandes para cliente: bucket com URL assinada V4 (conta de runtime + `iamcredentials` + `serviceAccountTokenCreator` nela
  mesma, sem chave), sem soft delete nem versionamento; arquivamento no Drive acima de um limite, com cópia conferida antes de apagar.
- Monitoramento: toda cota usada pela aplicação deve aparecer numa tela (Firestore como o Argos; Cloud Storage e Cloud Run por
  contadores da própria API; Artifact Registry, Cloud Build e Secret Manager por consulta só leitura às APIs do Google), com limites
  configuráveis.
- Pergunte antes de implementar o que muda comportamento para o cliente (ex.: onde fica o arquivo, o que acontece com versão arquivada).

## 4. Escrever a infra
- `<projeto>-infra/terraform/app` copiado do Argos: nomes do projeto, `keep_image_count = 1`, `ignore_changes` da imagem **e do `env`**,
  SA de runtime dedicada, `projetos_monitorados` com papéis só de leitura, bucket quando houver arquivos grandes.
- `cloudbuild.yaml` com os testes do projeto antes das imagens.
- Killswitch: **não** criar finops por projeto. Incluir o projeto em `projetos_protegidos` do `gcp-finops` (orçamento por projeto,
  Function que desliga só aquele projeto, `conta-alerta` por e-mail).
- `.gitattributes`/`.editorconfig` com `*.tf`, `*.hcl`, `*.tfvars` em LF (como o Argos).

## 5. Escrever o passo a passo
- README como índice: arquitetura (mermaid), tabela "igual × diferente do Argos", custo, ajustes feitos, tabela **Processos**,
  rollback, recuperação do killswitch e referência operacional.
- **Três roteiros separados**: `criar.md` (um comando por passo em PowerShell, até o checklist pós-deploy), `atualizar.md` (código,
  variável de ambiente e Terraform, com a tabela "o que o apply faz com o que foi criado à mão") e `excluir.md`.
- Atualizar e excluir **começam pelo inventário** do que foi feito fora do Terraform (`Inventariar-Gcp.ps1 -Projeto ... -PastaTerraform .`,
  só leitura, linhas FORA DO TERRAFORM) e pela lista **Outros locais a verificar** da tela de backup da aplicação (Drive, contas de
  serviço, OAuth, tokens, chaves de ambiente, recursos manuais). Se a aplicação não tiver essa lista, proponha criá-la
  (`LocaisArmazenamento` + `GET /api/dados/locais` + cartões na tela, como Argos e Íris), sem nunca mostrar segredo.
- **Máxima em todo roteiro: nunca perder dados** — backup da aplicação, variáveis do Cloud Run salvas (`gcloud run services describe
  ... --format="yaml(spec.template.spec.containers[0].env)"`, guardadas fora do repositório), cópia do `terraform.tfstate` logo depois
  do primeiro `apply`, `plan -destroy` revisado antes de qualquer `destroy`, nada apagado antes da cópia conferida.
- Ordem do `atualizar.md` depois do inventário: copiar state, salvar variáveis, backup se o plano tocar em dados,
  `terraform plan -refresh-only` (o que mudou por fora), `plan -out` revisado, `apply plano.tfplan`, `plan` final com "No changes".
- Ordem do `excluir.md`: inventário → outros locais (decidir o que acontece com o que fica fora da GCP) → salvar tudo e conferir →
  esvaziar o que tiver trava (`force_destroy = false`) só depois da cópia → `plan -destroy` → `destroy` → retirar do gcp-finops →
  `gcloud projects delete` → limpar fora da GCP (GitHub, Drive) → só então apagar state local.
- Atualize as regras do projeto (AGENTS/CLAUDE) se elas proibiam nuvem/Terraform.

## 6. Validar e relatar
1. `terraform init -backend=false && terraform validate && terraform fmt -check` em cada árvore (sem Terraform instalado:
   `docker run hashicorp/terraform:<versão>` copiando a pasta para `/tmp` dentro do container, para não sujar o projeto).
2. Build, testes e lint do projeto; imagem do front construída com uma `VITE_API_URL` de Cloud Run para conferir a CSP.
3. Relate o que foi e o que não foi validado (o `plan` real depende dos projetos criados e do login). Não commite sem pedido.
