# Antes do commit — Caronte

Itens do Caronte além da skill. `<back>` = `caronte-back` (`Caronte.sln`, testes em `Caronte.NUnitTest`), `<front>` =
`caronte-front` (Create React App). Não segue o pacote de padrões do Argos (código legado em C#/React 17): sem as buscas objetivas
da `revisar-padroes` e sem as regras básicas de TypeScript/C# que o código existente não adota (`var`, comentários e imports seguem
o estilo do arquivo mexido).

1. **Migrations**: entidade ou configuração em `Caronte.Data` mudou → migration nova em `Caronte.Data/Migrations` (com o
   `CaronteContextModelSnapshot.cs` atualizado); nunca editar migration já aplicada. A Api aplica as pendentes na subida.
2. **Espelho de tipos**: DTO ou rota em `Caronte.Api/Controllers` / `Caronte.Domain/Dto` mudou → `caronte-front/src/services`
   (tipos e chamadas) acompanha.
3. **Chave AES compartilhada**: `Caronte.Service/Utilities/Criptografia.cs` e `caronte-front/src/services/config.ts` usam a mesma
   chave; mudou de um lado, muda do outro.
4. **Variáveis**: variável nova ou renomeada na Api → `docker-compose.yml`, `.env.example`, tabela de `caronte-back/README.md` e
   aviso no relatório para configurar no Cloud Run antes do deploy (`cloudbuild.yaml` de cada pasta).
5. **Validação**:
   - `dotnet build Caronte.sln` em `<back>`: sem warnings **novos** (o projeto tem 26 warnings antigos de pacotes/código legado);
   - `dotnet test Caronte.NUnitTest` em `<back>`;
   - `npm run build` em `<front>` (não há `lint` nem testes do front configurados).
