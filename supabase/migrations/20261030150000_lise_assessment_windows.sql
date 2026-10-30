-- Janela de realização da avaliação final vinculada a cada trilha/turma.
ALTER TABLE public.lise_avaliacoes
    ADD COLUMN IF NOT EXISTS abre_em TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS encerra_em TIMESTAMPTZ;
