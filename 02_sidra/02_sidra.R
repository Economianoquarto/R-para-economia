# =============================================================================
# TUTORIAL 02 - DADOS DO SIDRA E ESTATÍSTICAS DESCRITIVAS
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute o arquivo de cima para baixo, linha a linha ou bloco a bloco,
#    usando Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. Leia os comentários antes de executar o código. Eles explicam o que
#    entra em cada comando, o que sai dele e o que deve ser conferido.
# 3. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 4. Ao final há três exercícios. Escreva as respostas nos espaços
#    indicados por "# SUA RESPOSTA AQUI".
# 5. A consulta ao SIDRA depende de conexão com a internet.
#
# OBJETIVOS
# ---------
# Ao final deste tutorial, você será capaz de:
#
# - localizar uma tabela do SIDRA pelo pacote sidrar;
# - consultar os metadados de uma tabela;
# - baixar dados com get_sidra();
# - selecionar e renomear as colunas relevantes;
# - identificar a unidade de observação da base;
# - verificar duplicatas e valores ausentes;
# - calcular medidas de posição e de dispersão;
# - criar rankings e filtros com dplyr.
#
# Exemplo principal:
# Tabela 6579 - População residente estimada
# Variável 9324 - População residente estimada, em pessoas
# Nível territorial - Unidade da Federação (UF)
#
# Documentação:
# https://cran.r-project.org/package=sidrar
# https://apisidra.ibge.gov.br/home/ajuda
# =============================================================================


# 1. Preparação da sessão --------------------------------------------------

# Limpa os objetos da sessão para evitar que o script dependa de objetos
# criados anteriormente no Environment.
rm(list = ls())

# A instalação é necessária apenas uma vez em cada projeto.
# Se os pacotes ainda não estiverem instalados, remova o # das linhas abaixo,
# execute-as e depois coloque o # novamente.
# install.packages("sidrar")
# install.packages("tidyverse")

# library() deve ser executado sempre que uma nova sessão do R for iniciada.
library(sidrar)
library(tidyverse)


# 2. O que são SIDRA, API e sidrar? ---------------------------------------
#
# O SIDRA é o Sistema IBGE de Recuperação Automática. Ele reúne tabelas
# agregadas de diversas pesquisas do IBGE.
#
# Uma API permite solicitar os dados diretamente por código, sem precisar
# baixar e organizar manualmente uma planilha no site do SIDRA.
#
# O pacote sidrar faz a comunicação entre o R e a API do SIDRA. Neste
# tutorial usaremos principalmente três funções:
#
# search_sidra() - procura tabelas por palavras;
# info_sidra()   - mostra os parâmetros disponíveis em uma tabela;
# get_sidra()    - baixa os dados escolhidos.
#
# Cada consulta precisa responder, no mínimo, a quatro perguntas:
#
# 1. Qual é a tabela?
# 2. Qual é a variável?
# 3. Qual é o período?
# 4. Qual é o nível geográfico?


# 3. Procurando uma tabela -------------------------------------------------

# Procuramos tabelas cujos títulos contenham as palavras abaixo.
# O resultado é um vetor: os nomes são os códigos das tabelas e os valores
# são seus títulos.
tabelas_populacao <- search_sidra("população residente estimada")

tabelas_populacao
head(tabelas_populacao)

# Neste tutorial usaremos a tabela 6579.
# O código da tabela é um identificador, não o número de uma linha.


# 4. Consultando os metadados da tabela -----------------------------------

# Antes de baixar os dados, conferimos quais variáveis, períodos e níveis
# geográficos estão disponíveis na tabela 6579.
metadados_populacao <- info_sidra(6579)

# Nomes dos componentes retornados por info_sidra().
names(metadados_populacao)

# Informações gerais da tabela.
metadados_populacao$table

# Períodos disponíveis.
metadados_populacao$period

# Variáveis disponíveis e seus respectivos códigos.
metadados_populacao$variable

# Níveis geográficos disponíveis.
metadados_populacao$geo

# A tabela possui a variável 9324 e permite uma consulta no nível "State",
# que corresponde às Unidades da Federação.


# 5. Baixando os dados com get_sidra() ------------------------------------

# Faremos uma consulta com os seguintes parâmetros:
#
# x        = 6579  -> código da tabela;
# variable = 9324  -> código da variável;
# period   = "last" -> período mais recente disponível;
# geo      = "State" -> todas as Unidades da Federação.
#
# IMPORTANTE: period = "last" deixa a consulta atualizada, mas o ano e os
# valores podem mudar quando o IBGE fizer uma nova divulgação. Para uma
# análise que precisa ser reproduzida exatamente no futuro, use um ano fixo,
# por exemplo period = "2024", e registre a data da consulta.

data_consulta_sidra <- Sys.time()

populacao_sidra <- get_sidra(
  x = 6579,
  variable = 9324,
  period = "last", # opção: "2024" para fixar o ano
  geo = "State"    # opção: "City" para todos os municípios
)

data_consulta_sidra

# populacao_piaui <- get_sidra(
#  x = 6579,
#  variable = 9324,
#  period = "last",
#  geo = "State",
#  geo.filter = list(State = 22)
#)

#populacao_teresina <- get_sidra(
#  x = 6579,
#  variable = 9324,
#  period = "last",
#  geo = "City",
#  geo.filter = list(City = 2211001)
#)

# O mesmo pedido também poderia ser escrito diretamente como um caminho da
# API. Esta forma é útil quando copiamos uma consulta pronta do SIDRA:
#
# populacao_sidra_api <- get_sidra(
#   api = "/t/6579/n3/all/v/9324/p/last"
# )
#
# No caminho acima:
# t/6579 = tabela 6579;
# n3/all = todas as UFs;
# v/9324 = variável 9324;
# p/last = último período disponível.


# 6. Primeira inspeção da base --------------------------------------------

# Nunca começamos a análise supondo que a base veio com a estrutura esperada.
# Primeiro verificamos tamanho, nomes, tipos e algumas observações.
dim(populacao_sidra)
nrow(populacao_sidra)
ncol(populacao_sidra)
names(populacao_sidra)
glimpse(populacao_sidra)
head(populacao_sidra)

# A consulta deve retornar 27 linhas: uma para cada UF. Como usamos apenas o
# último período, a unidade de observação esperada é:
#
#                         UF × ano
#
# Se forem pedidos vários anos, a mesma UF aparecerá uma vez em cada ano.


# 7. Selecionando e renomeando as colunas ---------------------------------

# A resposta do SIDRA contém colunas descritivas e códigos. Para esta análise,
# manteremos somente as informações necessárias. Os códigos geográficos devem
# ser mantidos como texto: eles são identificadores, não quantidades.
populacao_uf <- populacao_sidra %>%
  select(
    `Unidade da Federação (Código)`,
    `Unidade da Federação`,
    Ano,
    `Unidade de Medida`,
    Valor
  ) %>%
  rename(
    codigo_uf = `Unidade da Federação (Código)`,
    estado = `Unidade da Federação`,
    ano = Ano,
    unidade = `Unidade de Medida`,
    populacao = Valor
  ) %>%
  mutate(
    codigo_uf = as.character(codigo_uf),
    ano = as.integer(ano),
    populacao_milhoes = populacao / 1000000
  )

populacao_uf
glimpse(populacao_uf)

# A variável populacao está em pessoas. A variável populacao_milhoes apenas
# muda a escala para facilitar a leitura; ela não altera a quantidade de
# observações nem substitui a variável original.


# 8. Verificações de integridade ------------------------------------------

## 8.1 Conferindo o nível da base ----

# Deve existir apenas um período na consulta principal.
populacao_uf %>%
  count(ano)

# Deve existir apenas uma unidade de medida.
populacao_uf %>%
  count(unidade)

## 8.2 Conferindo a chave UF × ano ----

# A combinação codigo_uf × ano deve identificar cada observação.
# Se o resultado abaixo tiver zero linhas, não há duplicatas nessa chave.
duplicatas_uf_ano <- populacao_uf %>%
  count(codigo_uf, ano) %>%
  filter(n > 1)

duplicatas_uf_ano
nrow(duplicatas_uf_ano)

## 8.3 Conferindo valores ausentes ----

# NA significa ausência de informação. Não devemos substituir NA por zero,
# pois uma população ausente não é economicamente igual a uma população nula.
resumo_ausentes <- populacao_uf %>%
  summarise(
    numero_observacoes = n(),
    populacao_ausente = sum(is.na(populacao)),
    estado_ausente = sum(is.na(estado))
  )

resumo_ausentes

# Depois dessa verificação, usaremos na.rm = TRUE nas estatísticas para que
# eventuais valores ausentes não impeçam os cálculos. O número de valores
# válidos e ausentes continuará registrado no resumo.


# 9. Estatísticas descritivas ---------------------------------------------

## 9.1 Resumo automático com summary() ----

# summary() informa mínimo, primeiro quartil, mediana, média, terceiro
# quartil e máximo de uma variável numérica.
summary(populacao_uf$populacao_milhoes)

## 9.2 Medidas de posição e total ----

# Como há uma observação por UF, a média abaixo é a média simples da população
# entre as UFs. Ela não é a população média por pessoa nem uma média ponderada.
resumo_populacao <- populacao_uf %>%
  summarise(
    ano_referencia = first(ano),
    numero_ufs = n(),
    valores_validos = sum(!is.na(populacao)),
    valores_ausentes = sum(is.na(populacao)),
    populacao_total_milhoes = sum(populacao_milhoes, na.rm = TRUE),
    media_milhoes = mean(populacao_milhoes, na.rm = TRUE),
    mediana_milhoes = median(populacao_milhoes, na.rm = TRUE),
    minimo_milhoes = min(populacao_milhoes, na.rm = TRUE),
    maximo_milhoes = max(populacao_milhoes, na.rm = TRUE)
  )

resumo_populacao

## 9.3 Medidas de dispersão ----

# As medidas abaixo mostram quanto as populações estaduais diferem entre si.
# O coeficiente de variação expressa o desvio-padrão como percentual da média.
resumo_dispersao <- populacao_uf %>%
  summarise(
    variancia = var(populacao_milhoes, na.rm = TRUE),
    desvio_padrao = sd(populacao_milhoes, na.rm = TRUE),
    amplitude = max(populacao_milhoes, na.rm = TRUE) -
      min(populacao_milhoes, na.rm = TRUE),
    intervalo_interquartil = IQR(populacao_milhoes, na.rm = TRUE),
    coeficiente_variacao_pct =
      100 * sd(populacao_milhoes, na.rm = TRUE) /
      mean(populacao_milhoes, na.rm = TRUE)
  )

resumo_dispersao

## 9.4 Quartis ----

# Os quartis dividem os valores ordenados em quatro partes.
quartis_populacao <- quantile(
  populacao_uf$populacao_milhoes,
  probs = c(0, 0.25, 0.50, 0.75, 1),
  na.rm = TRUE
)

quartis_populacao


# 10. Ranking e seleção lógica --------------------------------------------

## 10.1 Ordenando as UFs ----

# arrange(desc()) coloca as maiores populações no início.
ranking_populacao <- populacao_uf %>%
  arrange(desc(populacao)) %>%
  select(estado, ano, populacao, populacao_milhoes)

# sort() ordena os valores de um vetor.
# arrange() ordena as linhas de um data frame ou tibble,
# mantendo todas as colunas corretamente associadas.
# Para ordem crescente:
# populacao_uf %>%
# arrange(populacao)

ranking_populacao

# Cinco UFs com maior população estimada.
ranking_populacao %>%
  head(5)

## 10.2 UFs acima da média ----

# Primeiro guardamos a média em um objeto. Depois usamos esse valor no filtro.
media_populacao_milhoes <- mean(
  populacao_uf$populacao_milhoes,
  na.rm = TRUE
)

ufs_acima_media <- populacao_uf %>%
  filter(populacao_milhoes > media_populacao_milhoes) %>%
  arrange(desc(populacao_milhoes)) %>%
  select(estado, populacao_milhoes)

media_populacao_milhoes
ufs_acima_media
nrow(ufs_acima_media)


# 11. Reprodutibilidade ----------------------------------------------------

# period = "last" sempre busca o período mais recente disponível. Isso é útil
# para uma consulta atualizada, mas significa que o resultado pode mudar.
# Para reproduzir exatamente uma análise, substitua "last" por um ano fixo:
#
# populacao_sidra_2024 <- get_sidra(
#   x = 6579,
#   variable = 9324,
#   period = "2024",
#   geo = "State"
# )
#
# Também é possível salvar a base obtida na data da consulta:
#
# saveRDS(populacao_uf, "populacao_uf_sidra.rds")
#
# Em um projeto de pesquisa, registre no script:
#
# - o código da tabela;
# - o código da variável;
# - o período;
# - o nível geográfico;
# - a data da consulta;
# - a unidade de medida.


# 12. Problemas comuns -----------------------------------------------------
#
# 1. "could not find function get_sidra"
#    O pacote não foi carregado. Execute library(sidrar).
#
# 2. A consulta não retorna o resultado esperado
#    Confira os códigos e níveis com info_sidra(numero_da_tabela).
#
# 3. A coluna Valor possui NA
#    Verifique os símbolos e notas da tabela. Não substitua NA por zero sem
#    justificativa substantiva.
#
# 4. O número de linhas é maior do que o esperado
#    Confira a unidade de observação. Pode haver vários períodos, variáveis ou
#    categorias para cada localidade.
#
# 5. A consulta funcionava e parou de funcionar
#    Confira a conexão, a disponibilidade da API e a versão do pacote:
packageVersion("sidrar")


# =============================================================================
# EXERCÍCIOS PRÁTICOS
# =============================================================================
#
# Escreva o código abaixo de cada pergunta. Antes de continuar, confira os
# tipos das variáveis, a unidade de observação e o número de linhas.


## Exercício 1 (Nova consulta com get_sidra) ----
# Use get_sidra() para baixar a população residente estimada das 27 UFs em
# 2024. Utilize:
#
# - tabela 6579;
# - variável 9324;
# - período "2024";
# - nível geográfico "State".
#
# Guarde o resultado bruto no objeto populacao_sidra_2024. Em seguida, crie
# populacao_uf_2024 contendo apenas codigo_uf, estado, ano e populacao.
# Mantenha codigo_uf como texto e confirme se a base possui 27 linhas.

# SUA RESPOSTA AQUI



## Exercício 2 (Estatísticas descritivas) ----
# Usando populacao_uf_2024, crie um objeto chamado resumo_populacao_2024 com:
#
# a) número de UFs;
# b) população total;
# c) média;
# d) mediana;
# e) desvio-padrão;
# f) valor mínimo;
# g) valor máximo.
#
# Faça os cálculos em milhões de pessoas. Antes de usar na.rm = TRUE,
# verifique quantos valores de populacao estão ausentes.

# SUA RESPOSTA AQUI



## Exercício 3 (Ranking e filtro) ----
# Usando populacao_uf_2024:
#
# a) crie ranking_populacao_2024, ordenando as UFs da maior para a menor
#    população;
# b) mostre somente as cinco UFs mais populosas;
# c) crie ufs_acima_mediana_2024 contendo apenas as UFs cuja população seja
#    maior que a mediana das 27 UFs;
# d) conte quantas UFs ficaram acima da mediana.

# SUA RESPOSTA AQUI



# =============================================================================
# FIM DO TUTORIAL 02
# =============================================================================
