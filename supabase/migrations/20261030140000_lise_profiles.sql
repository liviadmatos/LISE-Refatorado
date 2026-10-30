-- Perfil de avatar e credencial de demonstração com hash (nunca texto puro).
BEGIN;

ALTER TABLE public.usuarios
    ADD COLUMN IF NOT EXISTS avatar VARCHAR(16) NOT NULL DEFAULT 'leaf',
    ADD COLUMN IF NOT EXISTS demo_password_hash VARCHAR(255);

COMMIT;
