# =============================================================================
# TUTORIAL 07 - JUNTANDO BASES COM OS JOINS DO DPLYR
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute de cima para baixo, linha a linha ou bloco a bloco, com
#    Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 3. Ao final há um exercício. Escreva a resposta no espaço indicado.
# 4. Este tutorial NÃO precisa de internet nem de arquivos de dados.
#
# OBJETIVOS
# ---------
# - identificar a chave e a unidade de observação antes de juntar bases;
# - distinguir left_join(), inner_join() e full_join();
# - usar semi_join() e anti_join() para verificar correspondências;
# - perceber que chaves repetidas podem aumentar o número de linhas.
#
# REFERÊNCIA
# ----------
# Atrebas, "A data.table and dplyr tour", seção Join:
# https://atrebas.github.io/post/2019-03-03-datatable-dplyr/#join
# =============================================================================


# 1. Preparação da sessão --------------------------------------------------

rm(list = ls())

# install.packages("tidyverse")
library(tidyverse)


# 2. Duas bases pequenas --------------------------------------------------
#
# A primeira base contém alunos e suas notas. A segunda contém a bolsa
# recebida por alguns alunos. Os valores são fictícios.
#
# UNIDADE DE OBSERVAÇÃO nas duas bases: aluno
# CHAVE esperada nas duas bases: id_aluno

notas <- tribble(
  ~id_aluno, ~nome,    ~nota,
  1,         "Ana",       8.5,
  2,         "Bruno",     7.0,
  3,         "Carla",     9.0,
  4,         "Diego",     6.5
)

bolsas <- tribble(
  ~id_aluno, ~valor_bolsa,
  2,                  500,
  3,                  700,
  5,                  600
)

notas
bolsas

## 2.1 Conferindo a chave ----

# Esperado: zero linhas nos dois resultados. Se aparecer alguma linha, a
# chave está repetida e o join pode multiplicar observações.
notas %>%
  count(id_aluno) %>%
  filter(n > 1)

bolsas %>%
  count(id_aluno) %>%
  filter(n > 1)

# Portanto, a relação esperada é um-para-um: cada aluno aparece no máximo
# uma vez em cada base.


# 3. Joins que acrescentam colunas ----------------------------------------

## 3.1 left_join(): mantém todas as linhas da esquerda ----

# Mantemos os quatro alunos de notas e trazemos o valor da bolsa quando há
# correspondência. Ana e Diego ficam com NA: não há bolsa registrada para
# seus códigos. NA significa ausência de informação, e não bolsa igual a zero.

notas_com_bolsa <- notas %>%
  left_join(bolsas, by = "id_aluno")

notas_com_bolsa
nrow(notas_com_bolsa) # 4: a quantidade de alunos de notas foi preservada

## 3.2 inner_join(): mantém somente as correspondências ----

# Bruno e Carla estão nas duas bases. Ana, Diego e o código 5 ficam de fora.

alunos_nas_duas_bases <- notas %>%
  inner_join(bolsas, by = "id_aluno")

alunos_nas_duas_bases
nrow(alunos_nas_duas_bases) # 2

## 3.3 full_join(): mantém todas as linhas das duas bases ----

# O resultado reúne todos os códigos. O aluno 5 aparece sem nome e sem nota,
# pois essas informações não existem na base notas.

todos_os_registros <- notas %>%
  full_join(bolsas, by = "id_aluno")

todos_os_registros
nrow(todos_os_registros) # 5

# right_join(notas, bolsas) também existe: ele preservaria todas as linhas da
# base à direita. Em geral, é mais fácil trocar a ordem das bases e usar
# left_join(), deixando à esquerda a base cuja amostra queremos preservar.


# 4. Joins que filtram linhas ---------------------------------------------
#
# semi_join() e anti_join() não acrescentam colunas. Eles usam a segunda
# base apenas para decidir quais linhas da primeira serão mantidas.

## 4.1 semi_join(): quais alunos de notas também aparecem em bolsas? ----

alunos_com_bolsa <- notas %>%
  semi_join(bolsas, by = "id_aluno")

alunos_com_bolsa

## 4.2 anti_join(): quais alunos de notas não aparecem em bolsas? ----

alunos_sem_bolsa <- notas %>%
  anti_join(bolsas, by = "id_aluno")

alunos_sem_bolsa

# Também devemos conferir o caminho contrário: qual bolsa não encontrou um
# aluno na base notas? O código 5 é o resultado esperado.

bolsas_sem_aluno <- bolsas %>%
  anti_join(notas, by = "id_aluno")

bolsas_sem_aluno


# 5. O cuidado principal: chaves repetidas --------------------------------
#
# Se o mesmo id_aluno aparecer duas vezes em bolsas, cada linha correspondente
# de notas também aparecerá duas vezes após o left_join(). Isso pode ser
# correto em uma relação um-para-muitos, mas seria erro se esperássemos uma
# linha por aluno. Por isso conferimos a chave ANTES e nrow() DEPOIS do join.
#
# Roteiro mínimo para um join seguro:
#   1. identificar a unidade de observação de cada base;
#   2. declarar a chave em by =;
#   3. verificar se a chave é única quando deveria ser;
#   4. usar anti_join() para encontrar códigos sem correspondência;
#   5. conferir o número de linhas e os NA depois do join.


# =============================================================================
# EXERCÍCIO PRÁTICO - EMPRESAS E SETORES
# =============================================================================
#
# As duas bases abaixo usam nomes diferentes para a mesma chave:
# codigo_empresa em empresas e codigo em setores.

empresas <- tribble(
  ~codigo_empresa, ~empresa,     ~receita,
  10,              "Empresa A",      120,
  20,              "Empresa B",       80,
  30,              "Empresa C",      200,
  40,              "Empresa D",       60
)

setores <- tribble(
  ~codigo, ~setor,
  10,      "Indústria",
  20,      "Serviços",
  30,      "Indústria",
  50,      "Comércio"
)

# TAREFAS:
# a) Verifique se a chave se repete em cada base.
# b) Crie empresas_com_setor com left_join(), preservando as quatro empresas.
#    Para chaves com nomes diferentes, use:
#    by = c("codigo_empresa" = "codigo")
# c) Use anti_join() para descobrir qual empresa ficou sem setor.
# d) Use anti_join() no sentido contrário para descobrir qual setor ficou sem
#    empresa. Responda em um comentário quais são os dois códigos.
# e) Confira o número de linhas de empresas_com_setor e conte quantos valores
#    ausentes existem na coluna setor.

# SUA RESPOSTA AQUI



# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto para: SeuNome_SeuSobrenome - Tutorial 07.
# 2. Salve o script (Ctrl+S / Cmd+S).
# 3. Clique em "Share", no canto superior direito.
# 4. Convide economianoquarto@gmail.com como "Viewer".
# 5. Clique em "Apply"/"Enviar convite".
#
# =============================================================================
# FIM DO TUTORIAL 07
# =============================================================================
