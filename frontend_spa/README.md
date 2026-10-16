# LISE frontend estático

Publique esta pasta como projeto Vercel independente: **Root Directory** `frontend_spa`, preset **Other**, sem build e **Output Directory** `.`. O arquivo `vercel.json` define a navegação SPA e os cabeçalhos.

Após publicar o backend, informe a origem da API em `config.js` (`https://...`, sem `/api/v1` e sem barra final) e publique novamente. O frontend não usa chaves do Supabase.

Localmente, configure `API_BASE_URL` como `http://127.0.0.1:5000`, inicie `python app.py` dentro de `backend_service/` e `python -m http.server 5500` nesta pasta.
