# LISE — projeto completo

Refatoração da aplicação existente: frontend JavaScript estático, API Flask/Python e banco PostgreSQL no Supabase. A publicação permanece separada em dois projetos Vercel, sem colocar credenciais do banco no navegador.

## Estrutura

- `frontend_spa/`: aplicação web estática, sem etapa de build.
- `backend_service/`: API Flask, testes e configuração para Vercel Functions.
- `supabase/migrations/`: migrações versionadas da base e da curadoria etimológica.
- `DEPLOY_VERCEL.md`: instruções completas de deploy.
- `RELATORIO_REFATORACAO.md`: mudanças, estado do banco, testes e limitações.

## Publicação

1. Envie o conteúdo desta pasta para um repositório GitHub privado ou autorizado.
2. Crie um projeto Vercel com Root Directory `frontend_spa` e outro com `backend_service`.
3. Configure as variáveis do backend descritas em `DEPLOY_VERCEL.md`.
4. Depois de publicar a API, ajuste `frontend_spa/config.js` com a origem dela e publique novamente.
5. O projeto Supabase LISE conectado já recebeu as duas novas migrações desta versão. Para esse banco, não execute novamente as migrações antigas.

## Conteúdo pedagógico

No banco LISE conectado, 33 termos oficiais, 27 elementos e 64 associações estão aprovados para uso. O conteúdo oficial herdado que ainda não foi validado permanece preservado como pendente e não participa de jogos etimológicos. O exemplo “Acelomado” foi mantido no histórico, com estado pendente.

## Desenvolvimento local

Consulte `backend_service/README.md` e `frontend_spa/README.md`. O backend requer Python 3.12. Use `.env.example` como modelo local e nunca publique `.env` ou credenciais reais.
