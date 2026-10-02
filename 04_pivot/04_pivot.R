# =============================================================================
# TUTORIAL 04 - MUDANDO O FORMATO DA BASE: pivot_wider() E pivot_longer()
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute de cima para baixo, linha a linha ou bloco a bloco, com
#    Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 3. Ao final há um exercício em duas partes. Escreva as respostas nos
#    espaços indicados por "# SUA RESPOSTA AQUI".
# 4. Este tutorial NÃO precisa de internet nem de nenhum arquivo de dados.
#
# OBJETIVOS
# ---------
# - distinguir formato COMPRIDO (long) de formato LARGO (wide);
# - passar do formato comprido para o largo com pivot_wider();
# - passar do formato largo para o comprido com pivot_longer();
# - perceber que a UNIDADE DE OBSERVAÇÃO muda a cada giro, e conferir o
#   resultado contando linhas, colunas e valores.
#
# OS DADOS
# --------
# Vamos SIMULAR duas bases pequenas, digitadas aqui mesmo no script. Elas
# são pequenas de propósito: cabem inteiras na tela, e dá para conferir a
# olho cada valor antes e depois de girar a base.
#
#   1. desemprego_comprido - taxa de desemprego de 3 estados em 3 anos, já
#      no formato COMPRIDO. Vamos girá-la para o formato largo.
#
#   2. receita_largo - receita de 4 empresas em 3 anos, já no formato
#      LARGO. Vamos girá-la para o formato comprido.
#
# Os valores são FICTÍCIOS, inventados só para o tutorial. Não os use como
# dado de verdade.
# =============================================================================


# 1. Preparação da sessão --------------------------------------------------

rm(list = ls())

# install.packages("tidyverse")

library(tidyverse)

# pivot_wider() e pivot_longer() vêm do pacote tidyr, e tribble(), que usaremos
# para digitar as bases, vem do tibble. Os dois são carregados pelo
# library(tidyverse).


# 2. Formato comprido e formato largo --------------------------------------
#
# A MESMA informação pode ser guardada de duas formas.
#
# COMPRIDO (long) - uma linha por estado-ano:
#
#   estado    ano   taxa_desemprego
#   CE       2023               8.4
#   CE       2024               7.6
#   CE       2025               7.1
#   MA       2023               7.9
#   ...
#
# LARGO (wide) - uma linha por estado, uma coluna por ano:
#
#   estado   ano_2023   ano_2024   ano_2025
#   CE            8.4        7.6        7.1
#   MA            7.9        7.2        6.8
#   ...
#
# Nenhum número mudou: o 7.6 do Ceará em 2024 está nas duas tabelas. O que
# mudou foi o LUGAR onde o ano aparece. No formato comprido o ano é uma
# COLUNA, com os valores 2023, 2024 e 2025; no largo, ele virou parte do
# NOME das colunas.
#
# Com isso muda também a UNIDADE DE OBSERVAÇÃO, isto é, o que cada linha
# representa:
#
#   COMPRIDO -> cada linha é um estado em um ano   (estado x ano)
#   LARGO    -> cada linha é um estado             (estado)
#
# Nenhum dos dois formatos é "o certo":
#
#   COMPRIDO -> é o formato de TRABALHO. filter(), group_by(), summarise()
#               e ggplot() esperam que o ano seja uma coluna.
#
#   LARGO    -> é o formato de LEITURA. Mostra a trajetória de cada estado
#               em uma linha, como numa tabela de relatório ou de Excel.
#
# As duas funções deste tutorial:
#
#   pivot_wider()  comprido -> largo   (menos linhas, mais colunas)
#   pivot_longer() largo -> comprido   (mais linhas, menos colunas)


# 3. De comprido para largo: pivot_wider() ---------------------------------

## 3.1 Simulando a base comprida ----

# tribble() monta uma tabela linha por linha. A primeira linha, com "~",
# traz os nomes das colunas; cada linha seguinte é uma observação.
# Taxa de desemprego em % da força de trabalho (valores fictícios).
desemprego_comprido <- tribble(
  ~estado, ~ano, ~taxa_desemprego,
  "CE",    2023,  8.4,
  "CE",    2024,  7.6,
  "CE",    2025,  7.1,
  "MA",    2023,  7.9,
  "MA",    2024,  7.2,
  "MA",    2025,  6.8,
  "PI",    2023,  8.1,
  "PI",    2024,  7.5,
  "PI",    2025,  6.6
)

desemprego_comprido

# UNIDADE DE OBSERVAÇÃO: estado x ano
# 3 estados x 3 anos = 9 linhas
dim(desemprego_comprido)   # 9 linhas x 3 colunas

## 3.2 Conferindo a chave antes de girar ----

# No formato largo, cada combinação estado x ano vira UMA célula. Por isso,
# antes de girar, conferimos que essa combinação não se repete na base
# comprida (esperado: 0 linhas).
desemprego_comprido %>%
  count(estado, ano) %>%
  filter(n > 1)

# Se algum par estado x ano aparecesse duas vezes, o pivot_wider() teria
# dois valores para a mesma célula e não saberia qual escolher. Veja o
# problema comum nº 1, na seção 5.

## 3.3 Girando ----

# Os dois argumentos principais:
#
#   names_from  = de qual coluna saem os NOMES das novas colunas   (ano)
#   values_from = de qual coluna saem os VALORES das células        (taxa_desemprego)
#
# Toda coluna que não for names_from nem values_from fica como está e passa
# a identificar a linha. Aqui só sobra estado: uma linha por estado.
#
# names_prefix = "ano_" coloca um começo de texto no nome de cada coluna
# nova. Sem ele, as colunas se chamariam `2023`, `2024` e `2025`. Nomes que
# começam com número funcionam, mas exigem crase toda vez que forem citados
# (desemprego_largo$`2023`), o que é fácil de esquecer.
#
#   MUDANÇA DE UNIDADE:
#     antes:  estado x ano   (9 linhas)
#     depois: estado         (3 linhas)

desemprego_largo <- desemprego_comprido %>%
  pivot_wider(
    names_from   = ano,
    values_from  = taxa_desemprego,
    names_prefix = "ano_"
  )

desemprego_largo

## 3.4 Conferindo o resultado ----

# 1. Uma linha por estado: os dois números devem ser 3.
nrow(desemprego_largo)
n_distinct(desemprego_comprido$estado)

# 2. Uma coluna por ano, além da coluna estado.
names(desemprego_largo)

# 3. Nenhuma célula vazia (esperado: 0). Como cada estado tem os três anos
#    na base comprida, todas as 3 x 3 = 9 células devem estar preenchidas.
sum(is.na(desemprego_largo))


# 4. De largo para comprido: pivot_longer() --------------------------------

## 4.1 Simulando a base larga ----

# É assim que muitas tabelas chegam do IBGE, de relatórios de empresas ou de
# planilhas de Excel: uma linha por unidade e um ano em cada coluna.
# Receita em R$ milhões (valores fictícios).
receita_largo <- tribble(
  ~empresa,    ~receita_2022, ~receita_2023, ~receita_2024,
  "Empresa A",           120,           135,           150,
  "Empresa B",            80,            78,            90,
  "Empresa C",           200,           210,           205,
  "Empresa D",            45,            60,            72
)

receita_largo

# UNIDADE DE OBSERVAÇÃO: empresa
dim(receita_largo)   # 4 linhas x 4 colunas

## 4.2 Girando ----

# Os três argumentos principais:
#
#   cols      = quais colunas devem ser empilhadas
#   names_to  = nome da NOVA coluna que recebe os NOMES das colunas empilhadas
#   values_to = nome da NOVA coluna que recebe os VALORES
#
# Em cols usamos starts_with("receita_"), que pega todas as colunas cujo
# nome começa com "receita_". É mais seguro do que digitar as três, e
# continua funcionando se a base ganhar um ano novo.
#
# names_prefix = "receita_" faz aqui o caminho inverso do que fez no
# pivot_wider(): RETIRA o prefixo, para que a coluna ano receba "2022" e não
# "receita_2022".
#
#   MUDANÇA DE UNIDADE:
#     antes:  empresa         ( 4 linhas)
#     depois: empresa x ano   (12 linhas = 4 empresas x 3 anos)

receita_comprido <- receita_largo %>%
  pivot_longer(
    cols         = starts_with("receita_"),
    names_to     = "ano",
    values_to    = "receita",
    names_prefix = "receita_"
  )

receita_comprido

## 4.3 O ano voltou como TEXTO ----

# Repare no tipo da coluna ano no resultado acima: <chr>, ou seja, texto. Ela
# foi montada a partir de NOMES de colunas, e nome de coluna é sempre texto.
class(receita_comprido$ano)   # "character"

# Como texto, "2022" não é um número: não dá para fazer conta com ele, e um
# filtro como ano > 2022 compararia letras, e não anos. Convertemos:
receita_comprido <- receita_comprido %>%
  mutate(ano = as.numeric(ano))

class(receita_comprido$ano)   # "numeric"
receita_comprido

## 4.4 Conferindo o resultado ----

# 1. Uma linha por empresa x ano: 4 empresas x 3 anos = 12 linhas.
nrow(receita_comprido)

# 2. A chave nova não se repete (esperado: 0 linhas).
receita_comprido %>%
  count(empresa, ano) %>%
  filter(n > 1)

# 3. Nenhum valor mudou: a soma das receitas é a mesma nos dois formatos.
#    Os dois números devem dar 1445.
sum(receita_comprido$receita)
sum(receita_largo %>% select(starts_with("receita_")))

## 4.5 Para que serve o formato comprido ----

# Com o ano em uma coluna, perguntas sobre o tempo viram um group_by(). Por
# exemplo, a receita somada das quatro empresas em cada ano.
#
#   MUDANÇA DE UNIDADE (aqui é uma agregação, e não um giro):
#     antes:  empresa x ano   (12 linhas)
#     depois: ano             ( 3 linhas)
receita_comprido %>%
  group_by(ano) %>%
  summarise(receita_total = sum(receita))

# No formato largo o ano está espalhado em três nomes de coluna, e o
# group_by() não tem uma coluna ano onde se apoiar.


# 5. Problemas comuns ------------------------------------------------------
#
# 1. "Values are not uniquely identified; output will contain list-cols"
#    Aviso do pivot_wider(): a combinação unidade x tempo se repete na base
#    comprida, e uma mesma célula recebeu mais de um valor. Investigue com
#    count(unidade, tempo) %>% filter(n > 1), como na seção 3.2.
#
# 2. Apareceram NA no formato largo
#    Faltava aquela combinação na base comprida (por exemplo, um estado sem
#    dado em um dos anos). O NA quer dizer "não observado", e não zero. Não
#    preencha com 0 sem uma razão de verdade.
#
# 3. Colunas com nomes como `2023`, que exigem crase
#    Use names_prefix no pivot_wider() (seção 3.3).
#
# 4. A coluna ano saiu com valores como "receita_2022"
#    Faltou names_prefix no pivot_longer() (seção 4.2).
#
# 5. Depois do pivot_longer(), o ano é texto
#    É o normal: ele veio de nomes de coluna. Converta com as.numeric()
#    (seção 4.3).


# =============================================================================
# EXERCÍCIO PRÁTICO - DESFAZENDO OS GIROS
# =============================================================================
#
# No tutorial você girou cada base para o outro formato. Agora faça o
# caminho de volta: transforme cada base girada na base de onde ela saiu.
#
# Antes de começar, rode o script inteiro até aqui: o exercício usa os
# objetos desemprego_largo (seção 3) e receita_comprido (seção 4).
#
# Cada item termina com uma linha de conferência comentada. Depois de
# escrever sua resposta, apague o "#" do início dessa linha e rode-a.
# all.equal() compara a sua base com a original e devolve:
#
#   TRUE     -> as duas bases são iguais. Pronto!
#   um texto -> a descrição do que está diferente. Leia, corrija e rode de
#               novo. Dois exemplos:
#               'Component "ano": target is character, current is numeric'
#                  -> o ano da sua base ficou como texto;
#               'Names: 3 string mismatches'
#                  -> os nomes das colunas não batem com os da original.


## Exercício (a) - desemprego: de LARGO de volta para COMPRIDO ----

# Ponto de partida: desemprego_largo, com 3 linhas (seção 3.3).
desemprego_largo

# SUA TAREFA: use pivot_longer() para criar desemprego_de_volta, com uma
# linha por estado-ano e as colunas estado, ano e taxa_desemprego, igual a
# desemprego_comprido. Siga as seções 4.2 e 4.3:
#
#   - em cols, pegue as colunas que começam com "ano_";
#   - use names_prefix para tirar o "ano_" do ano;
#   - converta o ano de volta para número.

# SUA RESPOSTA AQUI



# Conferência (esperado: TRUE):
# all.equal(desemprego_de_volta, desemprego_comprido)


## Exercício (b) - receita: de COMPRIDO de volta para LARGO ----

# Ponto de partida: receita_comprido, com 12 linhas (seção 4.3).
receita_comprido

# SUA TAREFA: use pivot_wider() para criar receita_de_volta, com uma linha
# por empresa e as colunas receita_2022, receita_2023 e receita_2024, igual
# a receita_largo. Siga a seção 3.3 e pense: qual names_prefix recria os
# nomes originais das colunas?

# SUA RESPOSTA AQUI



# Conferência (esperado: TRUE):
# all.equal(receita_de_volta, receita_largo)


# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto (canto superior esquerdo, ao lado do logo do
#    Posit Cloud, clique no nome do projeto) para:
#       SeuNome_SeuSobrenome - Tutorial 04
#
# 2. Salve o script (Ctrl+S / Cmd+S).
#
# 3. Clique no botão "Share" (compartilhar), no canto superior direito
#    da tela do projeto.
#
# 4. Em "Invite collaborators" (ou "Convidar colaboradores"), digite o
#    e-mail: economianoquarto@gmail.com
#    e defina a permissão como "Viewer" (leitura é suficiente).
#
# 5. Clique em "Apply"/"Enviar convite".
#
# Pronto! Não precisa enviar nada por e-mail. Eu vou acessar o projeto
# compartilhado diretamente pelo Posit Cloud.
#
# =============================================================================
# FIM DO TUTORIAL 04
# =============================================================================
