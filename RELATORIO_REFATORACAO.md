# Relatório da refatoração LISE

## Resultado

O LISE continua baseado na SPA JavaScript, na API Flask/Python e no banco Supabase existentes. A entrega mantém a arquitetura de dois projetos Vercel. O frontend não recebe credenciais do Postgres; o backend usa a conexão do Transaction Pooler e a autenticação do Supabase.

## Curadoria do banco etimológico

No projeto Supabase LISE, a consulta final encontrou:

| Conteúdo | Aprovado/ativo | Pendente | Total |
|---|---:|---:|---:|
| Termos | 33 | 243 | 276 |
| Elementos etimológicos | 27 | 277 | 304 |
| Relações termo–elemento | 64 | 462 | 526 |

Os 33 termos ativos são: Adipócito, Autólise, Bacteriólise, Biogênese, Biologia, Biólogo, Biosfera, Biotecnologia, Cardiologia, Citocinese, Citoesqueleto, Citólise, Citologia, Citoplasma, Ecologia, Eritrócito, Hematologia, Hemocitologia, Hemofilia, Hemoglobina, Hemólise, Hemorragia, Histogênese, Histologia, Leucócito, Microbiologia, Neurologia, Neurotransmissor, Osteoblasto, Osteócito, Osteoclasto, Plasmólise e Zoologia.

Os 27 elementos aprovados são: `-blasto`, `-cinese`, `-clasto`, `-filia`, `-gênese`, `-lise`, `-logia`, `-logo`, `-rragia`, `-sfera`, `adipo-`, `aut(o)-`, `bacterio-`, `bio-`, `cardio-`, `cito-`, `eco-`, `eritro-`, `hemato-`, `hemo-`, `histo-`, `leuco-`, `micro-`, `neuro-`, `osteo-`, `plasm(o)-` e `zoo-`.

O esquema agora registra a origem, variantes, fonte e estado de cada elemento; cada associação registra a forma presente no termo, função, significado contextual, referência e justificativa. As grafias `hemo-` e `hemato-` permanecem registros distintos. A classificação de elementos de composição foi ajustada para `-blasto`, `-cinese`, `-clasto`, `-gênese`, `-lise`, `-logo` e `-sfera`; sufixos verdadeiros continuam classificados como sufixos.

A consulta de integridade confirmou **zero relações aprovadas sem referência**, **zero relações aprovadas com termo inativo** e **zero relações aprovadas com elemento pendente**. O termo “Acelomado” e suas relações antigas não foram apagados: está como `PENDENTE` e não aparece no conteúdo ativo. Os 243 termos oficiais legados e todas as associações não revisadas foram preservados como pendentes. Nenhuma definição legada foi reescrita automaticamente.

O conteúdo aprovado foi selecionado por relações linguísticas justificáveis e fontes registradas. Esta versão não afirma que o inventário cobre todo o currículo: foram priorizados os casos com referências e associações que puderam ser sustentadas. A curadoria ainda requer expansão antes de atingir a referência de 90–150 termos.

## Aplicação, jogos e fluxos

- Jogos ativos: BioQuiz, Família de Palavras, Memória e Decifrador. Montagem de Palavras e flashcards foram retirados dos fluxos de produto; os registros e a tabela histórica de flashcards permanecem no banco.
- BioQuiz cria questões de termos/definições e de elementos/ significados aprovados. Perguntas sobre um elemento registram a prática dos termos cobertos por aquela relação.
- Família de Palavras usa somente associações aprovadas. Termos personalizados podem ser explorados e praticados em modos de termo/definição, mas não criam elementos etimológicos automaticamente.
- Memória registra os pares no servidor, trata a repetição de um par como idempotente e recusa reutilizar cartas que já foram combinadas. O frontend bloqueia cliques enquanto as cartas estão em conferência e durante a pausa de erro.
- O progresso e a disponibilidade das avaliações contam termos ativos. A avaliação continua separada dos jogos e a trilha só é concluída após prática e aprovação.
- O cadastro de professor não exige código de convite. A área de turma deixou de carregar o feed de atividades. Turmas, coleções, favoritos, trilhas, prazos, ranking e notas foram mantidos.
- O detalhe de termos exibe as formas observadas e links para fontes. O menu lateral compacto, as rotas de turmas/coleções e os estados de carregamento/erro foram ajustados.
- As telas de professor e aluno continuam protegidas por autenticação e autorização do backend. CORS permanece restrito às origens configuradas; a migração não concedeu acesso público às tabelas.

## Preservação dos dados Supabase

Após a atualização, a base continua contendo 50 usuários, 8 turmas, 6 trilhas, 2 coleções, 7 sessões de jogos e 143 partidas. A estratégia foi aditiva: referências históricas continuam apontando aos mesmos registros, e os termos selecionados foram conectados às relações de trilha/coleção/favorito sem apagar o histórico antigo.

As migrações `20261016161530_lise_curadoria_etimologica` e `20261016161850_lise_taxonomia_elementos` estão no histórico do Supabase e os arquivos SQL locais usam os mesmos números de versão. Elas foram aplicadas no projeto LISE conectado.

## Arquivos

### Criados

- `DEPLOY_VERCEL.md` — instruções de publicação, configuração do Supabase Auth, variáveis e validação do deploy.
- `RELATORIO_REFATORACAO.md` — este relatório.
- `supabase/migrations/20261016161530_lise_curadoria_etimologica.sql` — novas colunas, curadoria, referências e sinalização de conteúdo pendente.
- `supabase/migrations/20261016161850_lise_taxonomia_elementos.sql` — correção taxonômica dos elementos aprovados.

### Modificados

- `README.md`, `backend_service/README.md`, `frontend_spa/README.md`.
- `backend_service/.env.example`, `backend_service/app.py`.
- `backend_service/backend/models.py`, `backend_service/backend/services.py`, `backend_service/backend/rest_api.py`.
- `backend_service/tests/test_api.py`.
- `frontend_spa/app.js`, `frontend_spa/app.css`, `frontend_spa/config.js`.

Nenhum arquivo de código ou registro histórico foi removido do banco. O modelo e a tabela antigos de flashcards continuam no schema para preservar compatibilidade com o histórico.

## Validação executada

- `python -m pytest -q` em `backend_service/`: **7 testes aprovados**.
- `python -m compileall -q .` em `backend_service/`: concluído.
- `node --check frontend_spa/app.js`: concluído.
- Validação SQL no Supabase: contagens acima, “Acelomado” pendente e nenhuma relação aprovada ligada a conteúdo inativo.
- O teste cobre login/CORS, isolamento de termos, coleções, registro de termos sem decomposição automática, rejeição dos jogos removidos, BioQuiz, Memória, prática de trilha, avaliação e escopo de turma.

## Limitações e próximo passo

- Foram curados 33 termos e 27 elementos, abaixo da referência de volume. Os outros 243 termos oficiais aguardam revisão e não entram nos jogos que dependem de etimologia aprovada.
- A validação registra fontes e justificativas no banco, mas não equivale a uma revisão acadêmica externa; novas entradas devem seguir o mesmo processo antes de serem ativadas.
- Não foi medido benchmark comparativo de latência. Portanto, não é atribuída uma porcentagem de ganho de desempenho.
- O pacote está preparado para Vercel, mas nenhum domínio foi publicado nesta execução. A publicação depende da importação do repositório do usuário e da configuração das variáveis listadas em `DEPLOY_VERCEL.md`.
