-- =====================================================================
-- SQL QUEST — O ATAQUE AO REINO DOS DADOS
-- Arquivo completo (MySQL): criação do banco + dados + solução
-- Pode ser executado inteiro, quantas vezes quiser (ele recria tudo).
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 0: DDL (banco, tabela e dados)
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS sql_quest;
CREATE DATABASE sql_quest;

USE sql_quest;

CREATE TABLE jogadores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    classe VARCHAR(50) NOT NULL,
    nivel INT NOT NULL,
    moedas INT NOT NULL DEFAULT 0,
    pontos INT NOT NULL,
    guilda VARCHAR(50),
    bonus INT,
    status_jogador VARCHAR(30) NOT NULL,
    classificacao VARCHAR(30)
);

INSERT INTO jogadores
(nome, classe, nivel, moedas, pontos, guilda, bonus, status_jogador)
VALUES
('Arthas', 'Guerreiro', 18, 950, 7200, 'Dragões', 500, 'ATIVO'),

('Luna', 'Maga', 22, 1500, 9800, 'Fênix', NULL, 'ATIVO'),

('Thorim', 'Guerreiro', 15, 450, 5100, 'Dragões', 300, 'ATIVO'),

('Nyx', 'Assassina', 26, 2100, 12500, 'Sombras', NULL, 'ATIVO'),

('Eldrin', 'Mago', 12, 300, 3900, 'Fênix', 200, 'ATIVO'),

('Kael', 'Arqueiro', 20, 1100, 8300, 'Dragões', NULL, 'ATIVO'),

('Morgana', 'Maga', 30, 3200, 16000, 'Sombras', 1000, 'ATIVO'),

('Ragnar', 'Guerreiro', 8, 150, 1800, 'Dragões', NULL, 'INATIVO'),

('Lyra', 'Arqueira', 17, 700, 6500, 'Fênix', 400, 'ATIVO'),

('Draven', 'Assassino', 25, 1800, 11200, 'Sombras', 700, 'ATIVO'),

('Orion', 'Mago', 6, 80, 900, NULL, NULL, 'INATIVO'),

('Freya', 'Guerreira', 21, 1300, 8900, 'Dragões', 600, 'ATIVO');

-- Evita o erro 1175 (safe update mode) do Workbench
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- ETAPA 1: Classificação (CASE)
-- ---------------------------------------------------------------------
UPDATE jogadores
SET classificacao = CASE
    WHEN pontos >= 12000 THEN 'LENDÁRIO'
    WHEN pontos >= 8000  THEN 'ELITE'
    WHEN pontos >= 5000  THEN 'VETERANO'
    ELSE 'APRENDIZ'
END;

-- Conferência: não deve retornar nenhuma linha
SELECT * FROM jogadores WHERE classificacao IS NULL;

-- ---------------------------------------------------------------------
-- ETAPA 2: Bônus NULL -> 0 (COALESCE)
-- ---------------------------------------------------------------------
UPDATE jogadores
SET bonus = COALESCE(bonus, 0);

-- Conferência: não deve retornar nenhuma linha
SELECT * FROM jogadores WHERE bonus IS NULL;

-- ---------------------------------------------------------------------
-- ETAPA 3: +250 moedas para quem está acima da média de pontos
-- (subconsulta em tabela derivada, por causa do erro 1093 do MySQL)
-- Média considerando os 12 jogadores = 7675
-- ---------------------------------------------------------------------
UPDATE jogadores j
JOIN (SELECT AVG(pontos) AS media FROM jogadores) m
  ON j.pontos > m.media
SET j.moedas = j.moedas + 250;

-- ---------------------------------------------------------------------
-- ETAPA 4: Guerra das Guildas (GROUP BY + HAVING)
-- Somente guildas com média > 7000 (ignorando guilda NULL) -> Sombras
-- ---------------------------------------------------------------------
-- Conferência das médias (esperado: só Sombras)
SELECT guilda, AVG(pontos) AS media_pontos
FROM jogadores
WHERE guilda IS NOT NULL
GROUP BY guilda
HAVING AVG(pontos) > 7000;

UPDATE jogadores j
JOIN (
    SELECT guilda
    FROM jogadores
    WHERE guilda IS NOT NULL
    GROUP BY guilda
    HAVING AVG(pontos) > 7000
) g ON j.guilda = g.guilda
SET j.moedas = j.moedas + 300;

-- ---------------------------------------------------------------------
-- ETAPA 5: Conselho dos Campeões (top 3 por pontos: +1 nível)
-- ---------------------------------------------------------------------
-- Conferência: deve retornar exatamente 3 linhas
SELECT id, nome, pontos FROM jogadores ORDER BY pontos DESC LIMIT 3;

UPDATE jogadores j
JOIN (
    SELECT id FROM jogadores ORDER BY pontos DESC LIMIT 3
) t ON j.id = t.id
SET j.nivel = j.nivel + 1;

-- ---------------------------------------------------------------------
-- ETAPA 6: Treinamento emergencial (ATIVO e nível < 18: +2 níveis)
-- Usa o estado ATUAL do banco (após a etapa 5)
-- ---------------------------------------------------------------------
-- Conferência ANTES de atualizar (esperado: Thorim, Eldrin, Lyra)
SELECT id, nome, nivel, status_jogador
FROM jogadores
WHERE status_jogador = 'ATIVO' AND nivel < 18;

UPDATE jogadores
SET nivel = nivel + 2
WHERE status_jogador = 'ATIVO' AND nivel < 18;

-- ---------------------------------------------------------------------
-- ETAPA 7: Espiões de NullMaster (INATIVO e pontos < 2000)
-- ---------------------------------------------------------------------
-- Conferência ANTES de excluir (esperado: Ragnar e Orion)
SELECT id, nome, pontos, status_jogador
FROM jogadores
WHERE status_jogador = 'INATIVO' AND pontos < 2000;

DELETE FROM jogadores
WHERE status_jogador = 'INATIVO' AND pontos < 2000;

-- ---------------------------------------------------------------------
-- AUDITORIA FINAL
-- ---------------------------------------------------------------------
SELECT
    id,
    nome,
    nivel,
    moedas,
    pontos,
    guilda,
    bonus,
    status_jogador,
    classificacao
FROM jogadores
ORDER BY pontos DESC;

-- Validações extras
SELECT COUNT(*) AS total_jogadores FROM jogadores;                          -- 10
SELECT COUNT(*) AS bonus_nulos FROM jogadores WHERE bonus IS NULL;          -- 0
SELECT nome FROM jogadores WHERE classificacao = 'LENDÁRIO';                -- Morgana, Nyx

SET SQL_SAFE_UPDATES = 1;
