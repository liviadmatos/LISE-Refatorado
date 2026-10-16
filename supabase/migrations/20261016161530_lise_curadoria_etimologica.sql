BEGIN;

ALTER TABLE public.radicais ADD COLUMN IF NOT EXISTS origem_etimologica text;
ALTER TABLE public.radicais ADD COLUMN IF NOT EXISTS variantes jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.radicais ADD COLUMN IF NOT EXISTS status_validacao varchar(16) NOT NULL DEFAULT 'PENDENTE';
ALTER TABLE public.radicais ADD COLUMN IF NOT EXISTS fonte_etimologica text;
ALTER TABLE public.termos ADD COLUMN IF NOT EXISTS origem_conteudo varchar(20) NOT NULL DEFAULT 'OFICIAL';
ALTER TABLE public.termos ADD COLUMN IF NOT EXISTS status_conteudo varchar(16) NOT NULL DEFAULT 'PENDENTE';
ALTER TABLE public.termos ADD COLUMN IF NOT EXISTS fonte_definicao_url text;
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS forma_no_termo varchar(100);
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS funcao varchar(24);
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS significado_contextual text;
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS status_validacao varchar(16) NOT NULL DEFAULT 'PENDENTE';
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS referencia_url text;
ALTER TABLE public.termo_radicais ADD COLUMN IF NOT EXISTS justificativa text;

-- Registros legados permanecem preservados e ficam fora da seleção pedagógica até revisão.
UPDATE public.termos SET origem_conteudo = CASE WHEN criado_por IS NOT NULL OR coalesce(criado_pelo_professor, false) THEN 'PERSONALIZADO' ELSE 'OFICIAL' END;
UPDATE public.termos SET status_conteudo = CASE WHEN origem_conteudo = 'PERSONALIZADO' THEN 'ATIVO' ELSE 'PENDENTE' END;
UPDATE public.radicais SET status_validacao = 'PENDENTE';
UPDATE public.termo_radicais SET status_validacao = 'PENDENTE';

ALTER TABLE public.radicais DROP CONSTRAINT IF EXISTS radicais_classificacao_check;
ALTER TABLE public.radicais ADD CONSTRAINT radicais_classificacao_check CHECK (classificacao IN ('PREFIXO','RADICAL','SUFIXO','RAIZ','ELEMENTO_COMPOSICAO')) NOT VALID;
ALTER TABLE public.radicais VALIDATE CONSTRAINT radicais_classificacao_check;
ALTER TABLE public.radicais ADD CONSTRAINT radicais_status_validacao_check CHECK (status_validacao IN ('PENDENTE','APROVADO','REJEITADO')) NOT VALID;
ALTER TABLE public.radicais VALIDATE CONSTRAINT radicais_status_validacao_check;
ALTER TABLE public.termos ADD CONSTRAINT termos_origem_conteudo_check CHECK (origem_conteudo IN ('OFICIAL','PERSONALIZADO')) NOT VALID;
ALTER TABLE public.termos VALIDATE CONSTRAINT termos_origem_conteudo_check;
ALTER TABLE public.termos ADD CONSTRAINT termos_status_conteudo_check CHECK (status_conteudo IN ('ATIVO','PENDENTE','ARQUIVADO')) NOT VALID;
ALTER TABLE public.termos VALIDATE CONSTRAINT termos_status_conteudo_check;
ALTER TABLE public.termo_radicais ADD CONSTRAINT termo_radicais_status_validacao_check CHECK (status_validacao IN ('PENDENTE','APROVADO','REJEITADO')) NOT VALID;
ALTER TABLE public.termo_radicais VALIDATE CONSTRAINT termo_radicais_status_validacao_check;
ALTER TABLE public.termo_radicais ADD CONSTRAINT termo_radicais_funcao_check CHECK (funcao IS NULL OR funcao IN ('PREFIXO','SUFIXO','RADICAL','RAIZ','ELEMENTO_COMPOSICAO')) NOT VALID;
ALTER TABLE public.termo_radicais VALIDATE CONSTRAINT termo_radicais_funcao_check;

CREATE INDEX IF NOT EXISTS idx_termos_origem_status ON public.termos (origem_conteudo, status_conteudo);
CREATE INDEX IF NOT EXISTS idx_radicais_status ON public.radicais (status_validacao);
CREATE INDEX IF NOT EXISTS idx_termo_radicais_status_termo ON public.termo_radicais (status_validacao, fk_termo);

CREATE TEMP TABLE lise_seed_radicals (nome text, significado text, origem text, variantes jsonb, classificacao text, fonte text, id_radical integer) ON COMMIT DROP;
CREATE TEMP TABLE lise_seed_terms (nome text, definicao text, area text, fonte text, id_termo integer) ON COMMIT DROP;
CREATE TEMP TABLE lise_seed_links (termo text, radical text, forma text, funcao text, significado text, justificativa text, ordem integer) ON COMMIT DROP;
INSERT INTO lise_seed_radicals (nome,significado,origem,variantes,classificacao,fonte) VALUES
('bio-','Elemento de composição: vida ou ser vivo.','Do grego bíos, «vida».','["bi(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biologia'),
('cito-','Elemento de composição: célula.','Do grego kýtos, «célula» ou «recipiente».','["cit(o)-", "-cito"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citocinese'),
('hemo-','Elemento de composição: sangue.','Do grego haîma, «sangue».','["hem(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemoglobina'),
('hemato-','Elemento de composição: sangue, na forma hemat(o)-.','Do grego haímatos, forma flexionada de haîma, «sangue».','["hemat(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hematologia'),
('-logia','Sufixo: estudo, discurso ou área de conhecimento.','Do grego -logía, derivado de lógos.','["logia"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citologia'),
('-gênese','Sufixo/elemento de composição: origem, formação ou produção.','Do grego génesis, «origem» ou «formação».','["genese", "gênese"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biog%C3%A9nese'),
('-sfera','Elemento de composição: esfera; em compostos, região ou conjunto.','Do grego sphaîra, «esfera».','["sfera"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biosfera'),
('plasm(o)-','Elemento de composição: plasma ou material formado.','Do grego plásma, «aquilo que foi moldado ou formado».','["plasma", "plasmo-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoplasma'),
('-cinese','Elemento de composição: movimento ou processo de movimento.','Do grego kínēsis, «movimento».','["cinese"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citocinese'),
('-lise','Sufixo/elemento de composição: dissolução, separação ou destruição.','Do grego lýsis, «dissolução» ou «separação».','["lise"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hem%C3%B3lise'),
('aut(o)-','Elemento de composição: próprio, por si mesmo.','Do grego autós, «próprio» ou «mesmo».','["auto-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/aut%C3%B3lise'),
('bacterio-','Elemento de composição: bactéria.','De bactéria, do grego baktḗrion, «pequeno bastão».','["bacteri(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/bacteri%C3%B3lise'),
('-rragia','Sufixo: fluxo intenso ou extravasamento.','Do grego rhēgnýnai/rhagḗ, associado a romper ou fluir.','["rragia"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemorragia'),
('-filia','Sufixo: afinidade, atração ou tendência.','Do grego philía, «amizade» ou «afinidade».','["filia"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemofilia'),
('adipo-','Elemento de composição: gordura.','Do latim adeps, adip- «gordura».','["adip(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/adip%C3%B3cito'),
('eritro-','Elemento de composição: vermelho.','Do grego erythρός (erythrós), «vermelho».','["eritr(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/eritr%C3%B3cito'),
('leuco-','Elemento de composição: branco.','Do grego leukós, «branco».','["leuk(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/leuc%C3%B3cito'),
('osteo-','Elemento de composição: osso.','Do grego ostéon, «osso».','["oste(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoblasto'),
('-blasto','Sufixo/elemento de composição: germe, célula jovem ou forma em desenvolvimento.','Do grego blastós, «germe».','["blasto"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoblasto'),
('-clasto','Sufixo/elemento de composição: quebra ou fragmentação.','Do grego klastós, «quebrado».','["clasto"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoclasto'),
('neuro-','Elemento de composição: nervo ou sistema nervoso.','Do grego neûron, «nervo».','["neur(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurotransmissor'),
('histo-','Elemento de composição: tecido.','Do grego histós, «tecido».','["hist(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/histologia'),
('cardio-','Elemento de composição: coração.','Do grego kardía, «coração».','["cardi(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/cardiologia'),
('eco-','Elemento de composição: ambiente ou relações dos seres vivos com o meio.','Do grego oîkos, «casa» ou «ambiente».','["ec(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/ecologia'),
('zoo-','Elemento de composição: animal.','Do grego zôion, «animal» ou «ser vivo».','["zo(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/zoologia'),
('micro-','Elemento de composição: pequeno.','Do grego mikrós, «pequeno».','["micr(o)-"]'::jsonb,'ELEMENTO_COMPOSICAO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/microbiologia'),
('-logo','Sufixo/elemento de composição: pessoa que estuda ou atua em determinada área.','Do grego lógos, «estudo» ou «discurso».','["logo"]'::jsonb,'SUFIXO','https://www.infopedia.pt/dicionarios/lingua-portuguesa/bi%C3%B3logo');
INSERT INTO lise_seed_terms (nome,definicao,area,fonte) VALUES
('Biologia','Ciência que estuda os seres vivos, suas estruturas, funções, origem, evolução e relações com o ambiente.','Bioenergética e Bioquímica Celular','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biologia'),
('Biosfera','Conjunto das regiões da Terra onde há vida, considerado em interação com os ambientes físicos.','Ecologia e Evolução','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biosfera'),
('Biogênese','Formação de novos seres vivos a partir de seres vivos preexistentes; o termo também nomeia o processo de origem biológica.','Biologia e Evolução','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biog%C3%A9nese'),
('Biotecnologia','Uso de organismos vivos, células ou componentes biológicos para desenvolver produtos ou processos.','Bioenergética e Bioquímica Celular','https://www.infopedia.pt/dicionarios/lingua-portuguesa/biotecnologia'),
('Biólogo','Profissional com formação em Biologia que estuda os seres vivos e processos biológicos.','Bioenergética e Bioquímica Celular','https://www.infopedia.pt/dicionarios/lingua-portuguesa/bi%C3%B3logo'),
('Citologia','Área da Biologia que estuda as células.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citologia'),
('Citoplasma','Parte da célula entre a membrana plasmática e o núcleo, constituída pelo citosol e por estruturas celulares.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoplasma'),
('Citocinese','Etapa da divisão celular em que ocorre a separação do citoplasma entre as células-filhas.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citocinese'),
('Citoesqueleto','Rede de filamentos e túbulos proteicos que contribui para a forma, organização e movimento celular.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoesqueleto'),
('Hemocitologia','Estudo das células e dos elementos figurados do sangue.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemocitologia'),
('Hematologia','Área que estuda o sangue, os órgãos hematopoiéticos e as doenças relacionadas.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hematologia'),
('Hemoglobina','Proteína dos glóbulos vermelhos que se liga ao oxigênio e participa do seu transporte no sangue.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemoglobina'),
('Hemólise','Ruptura ou destruição de hemácias, com liberação de hemoglobina.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hem%C3%B3lise'),
('Hemorragia','Perda de sangue causada pelo rompimento de vasos sanguíneos ou por alteração da hemostasia.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemorragia'),
('Hemofilia','Grupo de distúrbios hereditários da coagulação associados à deficiência de fatores específicos de coagulação.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemofilia'),
('Autólise','Degradação de componentes de uma célula por enzimas da própria célula.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/aut%C3%B3lise'),
('Plasmólise','Retração do protoplasto de uma célula vegetal após perda de água em meio hipertônico.','Botânica','https://www.infopedia.pt/dicionarios/lingua-portuguesa/plasm%C3%B3lise'),
('Bacteriólise','Dissolução ou destruição de bactérias.','Microbiologia e Imunologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/bacteri%C3%B3lise'),
('Citólise','Ruptura ou destruição de células.','Citologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/cit%C3%B3lise'),
('Adipócito','Célula especializada no armazenamento de lipídios, principal constituinte do tecido adiposo.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/adip%C3%B3cito'),
('Eritrócito','Hemácia; célula sanguínea que transporta oxigênio por meio da hemoglobina.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/eritr%C3%B3cito'),
('Leucócito','Glóbulo branco; célula do sangue envolvida na defesa do organismo.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/leuc%C3%B3cito'),
('Osteoblasto','Célula que participa da formação da matriz óssea.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoblasto'),
('Osteócito','Célula óssea madura que mantém a matriz do tecido ósseo.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/oste%C3%B3cito'),
('Osteoclasto','Célula multinucleada especializada na reabsorção do tecido ósseo.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoclasto'),
('Neurologia','Área médica dedicada ao sistema nervoso e às suas doenças.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurologia'),
('Neurotransmissor','Substância química liberada por neurônios que transmite sinais entre células na sinapse.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurotransmissor'),
('Histologia','Estudo dos tecidos biológicos e de sua organização.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/histologia'),
('Histogênese','Formação e desenvolvimento dos tecidos durante o desenvolvimento do organismo.','Histologia e Embriologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/histog%C3%AAnese'),
('Cardiologia','Área médica dedicada ao coração e ao sistema cardiovascular.','Fisiologia Humana','https://www.infopedia.pt/dicionarios/lingua-portuguesa/cardiologia'),
('Ecologia','Área da Biologia que estuda as relações dos organismos entre si e com o ambiente.','Ecologia e Evolução','https://www.infopedia.pt/dicionarios/lingua-portuguesa/ecologia'),
('Zoologia','Ramo da Biologia que estuda os animais.','Ecologia e Evolução','https://www.infopedia.pt/dicionarios/lingua-portuguesa/zoologia'),
('Microbiologia','Ramo da Biologia que estuda microrganismos.','Microbiologia e Imunologia','https://www.infopedia.pt/dicionarios/lingua-portuguesa/microbiologia');
INSERT INTO lise_seed_links (termo,radical,forma,funcao,significado,justificativa,ordem) VALUES
('Biologia','bio-','bio','ELEMENTO_COMPOSICAO','Vida; base lexical do termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biologia.',1),
('Biologia','-logia','logia','SUFIXO','Elemento que indica estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biologia.',2),
('Biosfera','bio-','bio','ELEMENTO_COMPOSICAO','Vida; elemento inicial registrado na formação do termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biosfera.',1),
('Biosfera','-sfera','sfera','SUFIXO','Esfera ou região considerada como conjunto.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biosfera.',2),
('Biogênese','bio-','bio','ELEMENTO_COMPOSICAO','Vida.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biog%C3%A9nese.',1),
('Biogênese','-gênese','gênese','SUFIXO','Origem ou formação.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biog%C3%A9nese.',2),
('Biotecnologia','bio-','bio','ELEMENTO_COMPOSICAO','Vida; componente biológico da tecnologia.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/biotecnologia.',1),
('Biólogo','bio-','bio','ELEMENTO_COMPOSICAO','Vida.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/bi%C3%B3logo.',1),
('Biólogo','-logo','logo','SUFIXO','Pessoa que estuda ou atua em uma área.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/bi%C3%B3logo.',2),
('Citologia','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citologia.',1),
('Citologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citologia.',2),
('Citoplasma','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoplasma.',1),
('Citoplasma','plasm(o)-','plasma','RADICAL','Material formado que compõe o protoplasma celular.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoplasma.',2),
('Citocinese','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citocinese.',1),
('Citocinese','-cinese','cinese','SUFIXO','Movimento; no termo, processo de separação do citoplasma.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citocinese.',2),
('Citoesqueleto','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/citoesqueleto.',1),
('Hemocitologia','hemo-','hemo','ELEMENTO_COMPOSICAO','Sangue.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemocitologia.',1),
('Hemocitologia','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemocitologia.',2),
('Hemocitologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemocitologia.',3),
('Hematologia','hemato-','hemato','ELEMENTO_COMPOSICAO','Sangue; forma hemato- distinta de hemo-.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hematologia.',1),
('Hematologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hematologia.',2),
('Hemoglobina','hemo-','hemo','ELEMENTO_COMPOSICAO','Sangue.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemoglobina.',1),
('Hemólise','hemo-','hemo','ELEMENTO_COMPOSICAO','Sangue.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hem%C3%B3lise.',1),
('Hemólise','-lise','lise','SUFIXO','Ruptura ou destruição.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hem%C3%B3lise.',2),
('Hemorragia','hemo-','hemo','ELEMENTO_COMPOSICAO','Sangue.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemorragia.',1),
('Hemorragia','-rragia','rragia','SUFIXO','Fluxo intenso ou extravasamento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemorragia.',2),
('Hemofilia','hemo-','hemo','ELEMENTO_COMPOSICAO','Sangue.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemofilia.',1),
('Hemofilia','-filia','filia','SUFIXO','Afinidade; no termo, componente lexical tradicional.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/hemofilia.',2),
('Autólise','aut(o)-','auto','ELEMENTO_COMPOSICAO','Próprio; a degradação é realizada por enzimas da própria célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/aut%C3%B3lise.',1),
('Autólise','-lise','lise','SUFIXO','Dissolução ou destruição.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/aut%C3%B3lise.',2),
('Plasmólise','plasm(o)-','plasma','RADICAL','Plasma/protoplasma celular.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/plasm%C3%B3lise.',1),
('Plasmólise','-lise','lise','SUFIXO','Retração e separação do protoplasto.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/plasm%C3%B3lise.',2),
('Bacteriólise','bacterio-','bacterio','ELEMENTO_COMPOSICAO','Bactéria.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/bacteri%C3%B3lise.',1),
('Bacteriólise','-lise','lise','SUFIXO','Dissolução ou destruição.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/bacteri%C3%B3lise.',2),
('Citólise','cito-','cito','ELEMENTO_COMPOSICAO','Célula.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/cit%C3%B3lise.',1),
('Citólise','-lise','lise','SUFIXO','Ruptura ou destruição.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/cit%C3%B3lise.',2),
('Adipócito','adipo-','adipo','ELEMENTO_COMPOSICAO','Gordura.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/adip%C3%B3cito.',1),
('Adipócito','cito-','cito','SUFIXO','Célula; forma específica -cito no termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/adip%C3%B3cito.',2),
('Eritrócito','eritro-','eritro','ELEMENTO_COMPOSICAO','Vermelho.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/eritr%C3%B3cito.',1),
('Eritrócito','cito-','cito','SUFIXO','Célula; forma específica -cito no termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/eritr%C3%B3cito.',2),
('Leucócito','leuco-','leuco','ELEMENTO_COMPOSICAO','Branco.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/leuc%C3%B3cito.',1),
('Leucócito','cito-','cito','SUFIXO','Célula; forma específica -cito no termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/leuc%C3%B3cito.',2),
('Osteoblasto','osteo-','osteo','ELEMENTO_COMPOSICAO','Osso.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoblasto.',1),
('Osteoblasto','-blasto','blasto','SUFIXO','Gérmen ou célula em desenvolvimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoblasto.',2),
('Osteócito','osteo-','osteo','ELEMENTO_COMPOSICAO','Osso.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/oste%C3%B3cito.',1),
('Osteócito','cito-','cito','SUFIXO','Célula; forma específica -cito no termo.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/oste%C3%B3cito.',2),
('Osteoclasto','osteo-','osteo','ELEMENTO_COMPOSICAO','Osso.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoclasto.',1),
('Osteoclasto','-clasto','clasto','SUFIXO','Quebra ou fragmentação; referência à reabsorção óssea.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/osteoclasto.',2),
('Neurologia','neuro-','neuro','ELEMENTO_COMPOSICAO','Nervo ou sistema nervoso.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurologia.',1),
('Neurologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurologia.',2),
('Neurotransmissor','neuro-','neuro','ELEMENTO_COMPOSICAO','Sistema nervoso; forma neuro- registrada no verbete.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/neurotransmissor.',1),
('Histologia','histo-','histo','ELEMENTO_COMPOSICAO','Tecido.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/histologia.',1),
('Histologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/histologia.',2),
('Histogênese','histo-','histo','ELEMENTO_COMPOSICAO','Tecido.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/histog%C3%AAnese.',1),
('Histogênese','-gênese','gênese','SUFIXO','Origem ou formação.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/histog%C3%AAnese.',2),
('Cardiologia','cardio-','cardio','ELEMENTO_COMPOSICAO','Coração.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/cardiologia.',1),
('Cardiologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/cardiologia.',2),
('Ecologia','eco-','eco','ELEMENTO_COMPOSICAO','Ambiente; do grego oîkos, casa/ambiente.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/ecologia.',1),
('Ecologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/ecologia.',2),
('Zoologia','zoo-','zoo','ELEMENTO_COMPOSICAO','Animal.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/zoologia.',1),
('Zoologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/zoologia.',2),
('Microbiologia','micro-','micro','ELEMENTO_COMPOSICAO','Pequeno.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/microbiologia.',1),
('Microbiologia','bio-','bio','ELEMENTO_COMPOSICAO','Vida.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/microbiologia.',2),
('Microbiologia','-logia','logia','SUFIXO','Estudo ou área de conhecimento.','Relação curada a partir da forma observada e da etimologia indicada no verbete lexical: https://www.infopedia.pt/dicionarios/lingua-portuguesa/microbiologia.',3);

-- Atualiza um registro canônico por forma; duplicatas antigas continuam guardadas e pendentes.
UPDATE public.radicais r SET nome=s.nome, significado=s.significado, classificacao=s.classificacao, origem_etimologica=s.origem, variantes=s.variantes, fonte_etimologica=s.fonte, status_validacao='APROVADO' FROM lise_seed_radicals s WHERE r.id_radical=(SELECT min(r2.id_radical) FROM public.radicais r2 WHERE regexp_replace(lower(r2.nome),'[^[:alnum:]]','','g')=regexp_replace(lower(s.nome),'[^[:alnum:]]','','g'));
INSERT INTO public.radicais (nome,significado,classificacao,origem_etimologica,variantes,status_validacao,fonte_etimologica) SELECT s.nome,s.significado,s.classificacao,s.origem,s.variantes,'APROVADO',s.fonte FROM lise_seed_radicals s WHERE NOT EXISTS (SELECT 1 FROM public.radicais r WHERE regexp_replace(lower(r.nome),'[^[:alnum:]]','','g')=regexp_replace(lower(s.nome),'[^[:alnum:]]','','g'));
UPDATE lise_seed_radicals s SET id_radical=(SELECT min(r.id_radical) FROM public.radicais r WHERE regexp_replace(lower(r.nome),'[^[:alnum:]]','','g')=regexp_replace(lower(s.nome),'[^[:alnum:]]','','g') AND r.status_validacao='APROVADO');

-- Reaproveita registros de termos existentes, priorizando o ID com mais vínculos de trilha.
UPDATE lise_seed_terms s SET id_termo=(SELECT t.id_termo FROM public.termos t WHERE lower(t.palavra_completa)=lower(s.nome) ORDER BY (SELECT count(*) FROM public.trilha_termos tt WHERE tt.fk_termo=t.id_termo) DESC, t.id_termo LIMIT 1);
UPDATE public.termos t SET palavra_completa=s.nome, definicao_biologica=s.definicao, fk_area=(SELECT a.id_area FROM public.areas a WHERE lower(a.nome)=lower(s.area) LIMIT 1), origem_conteudo='OFICIAL', status_conteudo='ATIVO', fonte_definicao_url=s.fonte FROM lise_seed_terms s WHERE t.id_termo=s.id_termo;
INSERT INTO public.termos (palavra_completa,definicao_biologica,fk_area,origem_conteudo,status_conteudo,fonte_definicao_url) SELECT s.nome,s.definicao,(SELECT a.id_area FROM public.areas a WHERE lower(a.nome)=lower(s.area) LIMIT 1),'OFICIAL','ATIVO',s.fonte FROM lise_seed_terms s WHERE s.id_termo IS NULL;
UPDATE lise_seed_terms s SET id_termo=(SELECT t.id_termo FROM public.termos t WHERE lower(t.palavra_completa)=lower(s.nome) ORDER BY (SELECT count(*) FROM public.trilha_termos tt WHERE tt.fk_termo=t.id_termo) DESC, t.id_termo LIMIT 1);

-- Redireciona vínculos atuais para o termo canônico sem apagar as referências antigas.
INSERT INTO public.trilha_termos (fk_trilha,fk_termo) SELECT DISTINCT old_link.fk_trilha,s.id_termo FROM lise_seed_terms s JOIN public.termos old_term ON lower(old_term.palavra_completa)=lower(s.nome) AND old_term.id_termo<>s.id_termo JOIN public.trilha_termos old_link ON old_link.fk_termo=old_term.id_termo ON CONFLICT DO NOTHING;
INSERT INTO public.lise_termo_turmas (fk_termo,fk_turma) SELECT DISTINCT s.id_termo,old_share.fk_turma FROM lise_seed_terms s JOIN public.termos old_term ON lower(old_term.palavra_completa)=lower(s.nome) AND old_term.id_termo<>s.id_termo JOIN public.lise_termo_turmas old_share ON old_share.fk_termo=old_term.id_termo ON CONFLICT DO NOTHING;
INSERT INTO public.lise_colecao_termos (fk_colecao,fk_termo) SELECT DISTINCT old_item.fk_colecao,s.id_termo FROM lise_seed_terms s JOIN public.termos old_term ON lower(old_term.palavra_completa)=lower(s.nome) AND old_term.id_termo<>s.id_termo JOIN public.lise_colecao_termos old_item ON old_item.fk_termo=old_term.id_termo ON CONFLICT DO NOTHING;
INSERT INTO public.lise_favoritos_termos (fk_usuario,fk_termo) SELECT DISTINCT old_favorite.fk_usuario,s.id_termo FROM lise_seed_terms s JOIN public.termos old_term ON lower(old_term.palavra_completa)=lower(s.nome) AND old_term.id_termo<>s.id_termo JOIN public.lise_favoritos_termos old_favorite ON old_favorite.fk_termo=old_term.id_termo ON CONFLICT DO NOTHING;
INSERT INTO public.usuario_trilha_termo (fk_usuario,fk_turma_trilha,fk_termo,acertou,jogado,data_conclusao) SELECT old_progress.fk_usuario,old_progress.fk_turma_trilha,s.id_termo,bool_or(old_progress.acertou),bool_or(old_progress.jogado),min(old_progress.data_conclusao) FROM lise_seed_terms s JOIN public.termos old_term ON lower(old_term.palavra_completa)=lower(s.nome) AND old_term.id_termo<>s.id_termo JOIN public.usuario_trilha_termo old_progress ON old_progress.fk_termo=old_term.id_termo GROUP BY old_progress.fk_usuario,old_progress.fk_turma_trilha,s.id_termo ON CONFLICT (fk_usuario,fk_turma_trilha,fk_termo) DO UPDATE SET acertou=public.usuario_trilha_termo.acertou OR EXCLUDED.acertou, jogado=public.usuario_trilha_termo.jogado OR EXCLUDED.jogado, data_conclusao=LEAST(public.usuario_trilha_termo.data_conclusao,EXCLUDED.data_conclusao);

-- Conserva associações antigas em estado pendente, abrindo posições para as relações revisadas.
UPDATE public.termo_radicais tr SET ordem=tr.ordem+1000000 FROM lise_seed_terms s WHERE tr.fk_termo=s.id_termo AND tr.status_validacao='PENDENTE';
UPDATE public.termo_radicais tr SET ordem=l.ordem, forma_no_termo=l.forma, funcao=l.funcao, significado_contextual=l.significado, status_validacao='APROVADO', referencia_url=t.fonte, justificativa=l.justificativa FROM lise_seed_links l JOIN lise_seed_terms t ON lower(t.nome)=lower(l.termo) JOIN lise_seed_radicals r ON regexp_replace(lower(r.nome),'[^[:alnum:]]','','g')=regexp_replace(lower(l.radical),'[^[:alnum:]]','','g') WHERE tr.fk_termo=t.id_termo AND tr.fk_radical=r.id_radical AND tr.id=(SELECT min(tr2.id) FROM public.termo_radicais tr2 WHERE tr2.fk_termo=t.id_termo AND tr2.fk_radical=r.id_radical);
INSERT INTO public.termo_radicais (fk_termo,fk_radical,ordem,forma_no_termo,funcao,significado_contextual,status_validacao,referencia_url,justificativa) SELECT t.id_termo,r.id_radical,l.ordem,l.forma,l.funcao,l.significado,'APROVADO',t.fonte,l.justificativa FROM lise_seed_links l JOIN lise_seed_terms t ON lower(t.nome)=lower(l.termo) JOIN lise_seed_radicals r ON regexp_replace(lower(r.nome),'[^[:alnum:]]','','g')=regexp_replace(lower(l.radical),'[^[:alnum:]]','','g') WHERE NOT EXISTS (SELECT 1 FROM public.termo_radicais old WHERE old.fk_termo=t.id_termo AND old.fk_radical=r.id_radical AND old.status_validacao='APROVADO');

COMMIT;
