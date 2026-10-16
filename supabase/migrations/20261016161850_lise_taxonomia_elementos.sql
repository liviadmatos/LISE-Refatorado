BEGIN;

-- Formas gregas de composição conservam sua natureza de elementos compostos.
UPDATE public.radicais
SET classificacao = 'ELEMENTO_COMPOSICAO'
WHERE status_validacao = 'APROVADO'
  AND nome IN ('-gênese', '-sfera', '-cinese', '-lise', '-blasto', '-clasto', '-logo');

UPDATE public.termo_radicais
SET funcao = 'ELEMENTO_COMPOSICAO'
WHERE status_validacao = 'APROVADO'
  AND forma_no_termo IN ('gênese', 'sfera', 'cinese', 'lise', 'blasto', 'clasto', 'logo')
  AND funcao = 'SUFIXO';

COMMIT;
