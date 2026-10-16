# LISE API

API Flask preparada para ser publicada em projeto Vercel separado. Configure `backend_service` como Root Directory. A entrada WSGI é `vercel_app:app`; o health check é `/api/v1/healthz`.

Cadastre no painel da Vercel: `DATABASE_URL` (Transaction Pooler Supabase, porta 6543), `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SECRET_KEY` (aleatória e longa), `FRONTEND_URL`, `FRONTEND_ORIGINS` e `DEMO_MODE=false`. Consulte [DEPLOY_VERCEL.md](../DEPLOY_VERCEL.md) para passos, Auth e migrações.

O navegador não recebe senha do banco nem chave administrativa. A API restringe CORS às origens configuradas e valida autenticação, papel e vínculo com os dados pedidos.

## Executar localmente

Use Python 3.12. Copie `.env.example` para `.env`, preencha valores de desenvolvimento e rode:

```bash
python -m pip install -r requirements-dev.txt
python app.py
```

Em outro terminal, dentro de `frontend_spa/`, rode `python -m http.server 5500` e configure a URL local da API em `config.js`. Execute testes com `python -m pytest` nesta pasta.
