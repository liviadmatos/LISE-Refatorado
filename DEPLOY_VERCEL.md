# Deploy da LISE na Vercel

O frontend e a API são publicados como dois projetos Vercel ligados ao mesmo repositório. A interface estática só chama a API; a API acessa o Postgres do Supabase pelo servidor.

## 1. Preparar o repositório

1. Descompacte o pacote e envie o conteúdo da pasta `LISE-Refatorado` a um repositório GitHub.
2. A raiz do repositório deve conter `frontend_spa/`, `backend_service/` e `supabase/`.
3. Não envie `.env` nem valores secretos. O arquivo `.env.example` contém apenas marcadores.

## 2. Publicar o frontend

1. Na Vercel, escolha **Add New → Project** e importe o repositório.
2. Defina **Root Directory** como `frontend_spa`.
3. Use **Framework Preset: Other**, deixe **Build Command** vazio e defina **Output Directory** como `.`.
4. Publique e anote o domínio de produção, por exemplo `https://lise-web.vercel.app`.

O primeiro deploy pode ser feito com `API_BASE_URL` vazio. A tela informa que falta configurar a API até a etapa 5.

## 3. Configurar as variáveis do backend

Crie outro projeto Vercel, usando o mesmo repositório, e defina **Root Directory** como `backend_service`. Cadastre as variáveis em **Settings → Environment Variables** para o ambiente **Production**:

| Variável | Valor |
|---|---|
| `DATABASE_URL` | URL do **Transaction Pooler** do Supabase LISE, porta `6543`, incluindo usuário e senha do banco. |
| `SUPABASE_URL` | URL do projeto LISE, como `https://SEU_REF.supabase.co`. |
| `SUPABASE_PUBLISHABLE_KEY` | Chave `publishable` habilitada ou chave `anon` antiga ainda habilitada. Nunca use `service_role` ou `secret`. |
| `SECRET_KEY` | Chave aleatória longa (ao menos 32 caracteres). Gere com `python -c "import secrets; print(secrets.token_urlsafe(48))"`. |
| `FRONTEND_URL` | URL final do frontend, sem barra ao final. |
| `FRONTEND_ORIGINS` | A mesma origem final, sem barra. Inclua também origens de domínio próprio usadas no navegador, separadas por vírgula. |
| `DEMO_MODE` | `false`. |

Não coloque `DATABASE_URL`, `SECRET_KEY`, chave `secret` ou `service_role` no frontend ou no GitHub. Se a senha do banco tiver caracteres reservados (`@`, `#`, `/` ou espaço), codifique-os na URL. O backend desativa prepared statements para funcionar com o pooler.

Em **Settings → Functions**, escolha a região de São Paulo (`gru1`) para aproximar a função do Supabase em `sa-east-1`, se essa região estiver disponível no plano. Publique a API. O `pyproject.toml` aponta para `vercel_app:app`; não é necessário configurar Gunicorn.

## 4. Atualizar URLs do Supabase Auth

No Supabase LISE, acesse **Authentication → URL Configuration**:

- **Site URL**: o domínio do frontend.
- **Redirect URLs**: adicione `https://SEU-FRONT.vercel.app/**` e, se usar, o domínio próprio.
- Para preview da Vercel, adicione apenas as origens de preview que você realmente usa.
- Adicione `http://localhost:5500/**` somente para testes locais.

Se usar recuperação de senha, configure o template **Reset Password** com `supabase/email_recuperacao.html`.

## 5. Ligar frontend e API

Depois de conhecer o domínio publicado para a API, edite `frontend_spa/config.js`:

```js
window.LISE_CONFIG = {
  API_BASE_URL: "https://SEU-BACKEND.vercel.app"
};
```

Use somente a origem, sem `/api/v1` e sem barra ao final. Faça commit e push; a Vercel publicará novamente o frontend.

Se usar outro domínio ou preview, adicione a origem exata em `FRONTEND_ORIGINS`, ajuste `FRONTEND_URL` para o ambiente correspondente e inclua o endereço de retorno no Supabase Auth. Faça novo deploy do backend após mudar variáveis.

## 6. Conferir o deploy

1. Abra `https://SEU-BACKEND.vercel.app/api/v1/healthz`. A resposta esperada é `{"status":"ok","service":"lise-api"}`.
2. Acesse o frontend, crie ou use uma conta de teste e confirme login, catálogo, turmas e coleções.
3. Em uma turma de teste, valide atribuição de trilha, prática dos termos, configuração da avaliação, aprovação e visualização da nota pelo professor.
4. Teste os jogos BioQuiz, Família de Palavras, Memória e Decifrador.

## Supabase e migrações

No projeto LISE que já está conectado, as migrações `lise_curadoria_etimologica` e `lise_taxonomia_elementos` foram aplicadas. Os registros existentes foram preservados; não execute novamente os SQLs legados nesse banco.

Os arquivos `20260918171455_lise_flask_integrado.sql`, `20261002140000_lise_frontend_api.sql` e `20261002160000_lise_assessments_and_deadlines.sql` documentam a instalação base e as versões anteriores. Só devem ser aplicados, em ordem de nome, numa base nova ou num destino que ainda não tenha essas estruturas, com backup e revisão do esquema. Na base LISE atual, o necessário já está aplicado.

As duas migrações desta refatoração são:

- `20261016161530_lise_curadoria_etimologica.sql`: acrescenta metadados e estados de validação, preserva os termos antigos como pendentes e registra o subconjunto curado com fontes e justificativas.
- `20261016161850_lise_taxonomia_elementos.sql`: corrige a classificação de elementos de composição aprovados.

## Referências oficiais

- [Vercel: monorepos](https://vercel.com/docs/monorepos)
- [Vercel: runtime Python](https://vercel.com/docs/functions/runtimes/python)
- [Vercel: regiões](https://vercel.com/docs/regions)
- [Supabase: conexão PostgreSQL](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Supabase Auth: URLs de retorno](https://supabase.com/docs/guides/auth/redirect-urls)
