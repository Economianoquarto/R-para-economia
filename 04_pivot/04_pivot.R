# =============================================================================
# TUTORIAL 04 - MUDANDO O FORMATO DA BASE: UM PAINEL POSTO x SEMANA
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute de cima para baixo, linha a linha ou bloco a bloco, com
#    Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 3. Ao final há um exercício. Escreva a resposta no espaço indicado por
#    "# SUA RESPOSTA AQUI".
# 4. Este tutorial NÃO precisa de internet.
#
# OBJETIVOS
# ---------
# - identificar a que SEMANA (domingo a sábado) pertence cada data;
# - distinguir formato COMPRIDO (long) de formato LARGO (wide);
# - montar um PAINEL posto x semana com pivot_wider(), sem agregar nada;
# - reconhecer as duas colunas que estragam um pivot_wider silenciosamente;
# - conferir a chave unidade x tempo, como se faz em qualquer painel;
# - entender por que o NA de um painel desbalanceado não é zero;
# - voltar ao formato comprido com pivot_longer() para calcular variações.
#
# O QUE VAMOS CONSTRUIR
# ---------------------
# Um painel de preços da gasolina comum em Teresina:
#
#   uma LINHA por posto revendedor;
#   uma COLUNA por semana do 1º semestre de 2026;
#   em cada célula, o preço coletado naquele posto naquela semana.
#
# Repare: o preço vai para a célula COMO FOI COLETADO. Não existe média
# nenhuma neste tutorial - o pivot_wider() aqui só REORGANIZA os valores que
# já estão na base, um por célula.
#
# A BASE DE DADOS
# ---------------
# A mesma do Tutorial 03: preços de revenda de combustíveis coletados pela
# ANP em Teresina/PI no 1º semestre de 2026.
#
#   Arquivo: 04_pivot/postos_teresina_2026_01.xlsx
#   Fonte:   https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos
#
# O arquivo está na pasta deste tutorial, para que ele rode sozinho, sem
# depender de nenhuma outra pasta do projeto. É a mesma planilha usada no
# Tutorial 03, sem nenhuma alteração.
#
# Trate esse arquivo como SOMENTE LEITURA. Todo resultado deste script sai em
# arquivos novos; o dado bruto nunca é sobrescrito. Assim, se algo der errado
# no meio do caminho, basta rodar o script de novo desde o início.
# =============================================================================


# 1. Preparação da sessão --------------------------------------------------

rm(list = ls())

# install.packages("tidyverse")
# install.packages("readxl")
# install.packages("writexl")

library(tidyverse)  # usaremos dplyr, tidyr, stringr e lubridate
library(readxl)     # ler .xlsx
library(writexl)    # gravar .xlsx

# pivot_longer() e pivot_wider() vêm do tidyr, carregado por
# library(tidyverse). Não é preciso chamar library(tidyr) separadamente.

# O caminho é RELATIVO à raiz do projeto - a pasta que contém o arquivo
# .Rproj -, e não à pasta onde este script está salvo. É por isso que ele
# começa com "04_pivot/". Confira com getwd() se tiver dúvida.
caminho_precos <- "04_pivot/postos_teresina_2026_01.xlsx"

file.exists(caminho_precos)   # deve dar TRUE


# 2. Importando os dados ---------------------------------------------------

precos_bruto <- read_excel(caminho_precos, sheet = "postos_teresina")

dim(precos_bruto)   # esperado: 2308 x 16

precos <- precos_bruto %>%
  select(
    revenda     = Revenda,
    cnpj        = `CNPJ da Revenda`,
    bairro      = Bairro,
    produto     = Produto,
    data_coleta = `Data da Coleta`,
    valor_venda = `Valor de Venda`,
    bandeira    = Bandeira
  ) %>%
  mutate(
    data_coleta = as_date(data_coleta),  # o Excel devolve data-e-hora
    cnpj        = str_trim(cnpj)         # tira espaços nas pontas, por segurança
  )

glimpse(precos)

# Sobre o str_trim(): no CSV original da ANP o CNPJ vem com um espaço na
# frente (" 06.331.431/0001-17"), e é por isso que o Tutorial 03 usa essa
# limpeza. Neste arquivo .xlsx o readxl já entrega o valor sem o espaço, ou
# seja, o str_trim() não muda nenhuma linha aqui. Mantemos assim mesmo: é
# barato e protege o script se a ANP mudar o formato numa próxima exportação.
#
# O CNPJ continua sendo TEXTO, com pontos e barra. Ele é um identificador,
# não uma quantidade: convertê-lo para número apagaria os zeros à esquerda.

# UNIDADE DE OBSERVAÇÃO: posto (cnpj) x produto x data da coleta
nrow(precos)                 # 2308 preços coletados
n_distinct(precos$cnpj)      # 67 postos
n_distinct(precos$produto)   # 5 produtos
range(precos$data_coleta)    # 05/01/2026 a 24/06/2026


# 3. Identificando a semana da coleta --------------------------------------

## 3.1 floor_date(): de uma data para a semana a que ela pertence ----

# Queremos semanas de DOMINGO a SÁBADO. A forma de representar uma semana
# que menos dá problema é guardar a DATA DO DOMINGO que a inicia.
#
# floor_date(x, unit = "week") empurra qualquer data para o primeiro dia da
# semana a que ela pertence. week_start diz qual é esse primeiro dia:
#
#   week_start = 7 -> domingo   (1 = segunda, 2 = terça, ..., 7 = domingo)
#   week_start = 1 -> segunda   (padrão ISO, usado na Europa)
precos <- precos %>%
  mutate(semana_inicio = floor_date(data_coleta, unit = "week", week_start = 7))

precos %>%
  select(data_coleta, semana_inicio) %>%
  head(10)

# Escrevemos week_start = 7 mesmo sendo esse o padrão do lubridate. O padrão
# vem de uma OPÇÃO GLOBAL (getOption("lubridate.week.start", 7)), que alguém
# pode ter mudado no .Rprofile. Deixar explícito custa sete caracteres e
# garante que o script produza o mesmo resultado em qualquer máquina.

## 3.2 Conferindo que as semanas começam mesmo no domingo ----

# wday() devolve o dia da semana. Todas as datas de início devem ser domingo.
semanas_distintas <- sort(unique(precos$semana_inicio))

length(semanas_distintas)   # 25 semanas
head(semanas_distintas)
table(wday(semanas_distintas, label = TRUE, week_start = 7))

# A tabela acima tem de mostrar 25 em "dom" e 0 em todos os outros dias.
# Se aparecer qualquer outro dia, o week_start está errado.

# Um detalhe da base, que vale conhecer: a ANP não coleta em fim de semana.
table(wday(precos$data_coleta, label = TRUE, week_start = 7))

# Como todas as coletas caem entre segunda e sexta, neste caso específico
# usar week_start = 1 formaria os mesmos grupos, só com outro rótulo. Em uma
# base com coletas de sábado ou domingo isso NÃO seria verdade, e o mesmo
# preço mudaria de semana conforme o argumento. É por isso que a escolha
# precisa ser declarada, e não deixada por conta do padrão.

## 3.3 Por que não usar week(), isoweek() ou epiweek() ----

# Essas funções devolvem o NÚMERO da semana, e cada uma conta de um jeito:
exemplo_datas <- as_date(c("2026-01-05", "2026-01-10", "2026-01-11", "2026-01-12"))

tibble(
  data     = exemplo_datas,
  dia      = wday(exemplo_datas, label = TRUE, week_start = 7),
  week     = week(exemplo_datas),      # semanas de 7 dias a partir de 1º/jan
  isoweek  = isoweek(exemplo_datas),   # padrão ISO, semana começa na segunda
  epiweek  = epiweek(exemplo_datas),   # padrão epidemiológico, começa no domingo
  floor    = floor_date(exemplo_datas, "week", week_start = 7)
)

# Três problemas com o número da semana:
#
# 1. As três funções discordam entre si para a mesma data.
# 2. O número recomeça em 1 todo ano. Numa base de dois anos, a "semana 3"
#    de 2026 e a de 2027 viram o mesmo valor e se misturam numa agregação.
# 3. O número não diz quando a semana foi. "Semana 14" não informa nada a
#    quem lê a tabela.
#
# semana_inicio é uma DATA: ordena corretamente, nunca se repete entre anos
# e mostra o período de cara. Use o número da semana só quando alguma regra
# externa (um calendário oficial, um relatório já existente) exigir.


# 4. Formato comprido e formato largo --------------------------------------
#
# A MESMA informação pode ser guardada de duas formas.
#
# COMPRIDO (long) - uma linha por posto-semana observado:
#
#   cnpj                 semana_inicio   valor_venda
#   06.331.431/0001-17   2026-01-04             5.89
#   06.331.431/0001-17   2026-01-18             5.89
#   10.978.518/0001-58   2026-01-04             5.79
#   10.978.518/0001-58   2026-01-11             5.86
#
# LARGO (wide) - o PAINEL: uma linha por posto, uma coluna por semana:
#
#   cnpj                 2026-01-04   2026-01-11   2026-01-18
#   06.331.431/0001-17         5.89           NA         5.89
#   10.978.518/0001-58         5.79         5.86         5.86
#
# (os valores acima são reais; você vai vê-los na seção 5.3)
#
# Repare no NA: no formato largo aparece uma célula para TODA combinação
# posto x semana, inclusive as que não existiam no formato comprido. Aquele
# posto não foi visitado naquela semana. Voltaremos a isso na seção 5.5.
#
# Nenhum dos dois formatos é "o certo". O que muda é a unidade de observação
# e, com ela, o que fica fácil de fazer:
#
#   COMPRIDO -> é o formato de TRABALHO. group_by(), filter(), lag() e
#               ggplot() precisam que "semana" seja uma COLUNA, não um nome
#               de coluna. É o formato que o tidyverse espera.
#
#   LARGO    -> é o formato de LEITURA. Mostra a trajetória de cada posto em
#               uma linha, deixa os buracos de cobertura visíveis a olho nu e
#               é o que se entrega a quem vai abrir no Excel.
#
# As duas funções:
#
#   pivot_wider()  comprido -> largo   (menos linhas, mais colunas)
#   pivot_longer() largo -> comprido   (mais linhas, menos colunas)
#
# Em toda passagem de um formato para o outro a UNIDADE DE OBSERVAÇÃO muda.
# Confira sempre o número de linhas antes e depois.


# 5. pivot_wider(): montando o painel posto x semana -----------------------
#
# ATENÇÃO à regra que governa esta seção inteira:
#
#   no pivot_wider(), TODA coluna que não for names_from nem values_from é
#   tratada como IDENTIFICADORA, ou seja, entra na definição da linha.
#
# Queremos uma linha por POSTO. Então, antes de girar a base, precisamos
# resolver duas colunas que atrapalham: produto e data_coleta.

## 5.1 O produto: o erro das colunas-lista ----

# A base tem 5 produtos. O par posto x semana, portanto, NÃO identifica uma
# linha: numa mesma visita a ANP coleta gasolina, etanol, diesel...
precos %>%
  count(cnpj, semana_inicio) %>%
  filter(n > 1) %>%
  nrow()   # 629 pares repetidos, de 631

# Se girarmos assim mesmo, o pivot_wider() encontra vários valores para a
# mesma célula. Rode e leia o aviso.
teste_com_todos_produtos <- precos %>%
  select(cnpj, semana_inicio, valor_venda) %>%
  pivot_wider(names_from = semana_inicio, values_from = valor_venda)

# O aviso é "Values are not uniquely identified; output will contain
# list-cols". Como ele precisa de UM valor por célula e achou até cinco, ele
# guardou todos dentro da célula, em forma de lista.
class(teste_com_todos_produtos[[2]])   # "list", e não "numeric"

# Uma coluna-lista não é um número: nenhuma conta funciona com ela.
# mean(teste_com_todos_produtos[[2]])  # descomente para ver o erro
#
# Existe o atalho values_fn = mean, que resumiria os cinco produtos em um
# número - mas isso seria a média de gasolina com diesel e etanol, que não
# significa nada. A correção certa aqui não é resumir: é FILTRAR um produto.
precos_gasolina <- precos %>%
  filter(produto == "GASOLINA")

nrow(precos_gasolina)                    # 631 coletas
n_distinct(precos_gasolina$cnpj)         # 67 postos
n_distinct(precos_gasolina$semana_inicio)  # 25 semanas

# Agora sim: posto x semana identifica cada linha (esperado: 0 linhas).
# Esta é a verificação de chave que se faz em QUALQUER painel, antes de
# qualquer coisa - a combinação unidade x tempo não pode se repetir.
precos_gasolina %>%
  count(cnpj, semana_inicio) %>%
  filter(n > 1)

## 5.2 A data da coleta: a coluna que quebra o painel em silêncio ----

# data_coleta varia DENTRO de cada posto: é uma data diferente a cada visita.
# Se ela ficar na base, vira coluna identificadora e cada visita gera uma
# linha própria - o painel simplesmente não se forma.
teste_com_data <- precos_gasolina %>%
  select(cnpj, revenda, data_coleta, semana_inicio, valor_venda) %>%
  pivot_wider(names_from = semana_inicio, values_from = valor_venda)

nrow(teste_com_data)   # 631 linhas, e não 67

# Nenhum aviso apareceu. Este é o erro mais traiçoeiro do pivot_wider():
# o resultado sai, parece uma tabela, e está errado.
#
# Como saber quais colunas podem ficar? A regra é: só entram as que são
# CONSTANTES dentro da unidade. revenda, bairro e bandeira descrevem o posto
# e não mudam de uma semana para outra; data_coleta muda. Conferindo
# (esperado: 0 linhas):
precos_gasolina %>%
  distinct(cnpj, revenda, bairro, bandeira) %>%
  count(cnpj) %>%
  filter(n > 1)

# Duas formas de resolver, equivalentes:
#
#   a) select() deixando data_coleta de fora, como faremos a seguir;
#   b) id_cols = c(cnpj, revenda, bairro, bandeira) dentro do pivot_wider(),
#      declarando explicitamente quem identifica a linha e ignorando o resto.
#
# id_cols é mais seguro em bases largas, porque não depende de você lembrar
# de tirar cada coluna problemática.

## 5.3 O painel ----

# Um último ajuste antes de girar: os nomes das colunas.
#
# Nomes de coluna são sempre TEXTO. Passando semana_inicio (uma data) direto,
# o R criaria colunas chamadas `2026-01-04`, que exigem crase toda vez que
# forem citadas. Criamos um rótulo de texto, com "_" no lugar do "-", e
# usamos names_prefix para marcar que aquilo é uma semana.
#
# O formato "%Y_%m_%d" (ano_mês_dia) foi escolhido porque ordena
# corretamente na ordem alfabética - "2026_02_01" vem depois de
# "2026_01_25", o que "01_02_2026" não garantiria.
#
#   MUDANÇA DE UNIDADE:
#     antes:  posto x semana   (631 linhas)
#     depois: posto            ( 67 linhas)

painel_gasolina <- precos_gasolina %>%
  mutate(semana_rotulo = format(semana_inicio, "%Y_%m_%d")) %>%
  select(cnpj, revenda, bairro, bandeira, semana_rotulo, valor_venda) %>%
  pivot_wider(
    names_from   = semana_rotulo,
    values_from  = valor_venda,
    names_prefix = "sem_",
    names_sort   = TRUE      # colunas em ordem cronológica
  )

dim(painel_gasolina)   # 67 linhas x 29 colunas (4 de identificação + 25 semanas)
names(painel_gasolina)[1:8]

# Olhando as cinco primeiras semanas de cinco postos:
painel_gasolina %>%
  select(cnpj, 5:9) %>%
  head(5)

# Sobre names_sort = TRUE: sem esse argumento, o pivot_wider() cria as
# colunas na ordem em que os valores aparecem na base. Se a base não
# estivesse ordenada por data, as semanas sairiam fora de ordem - e ninguém
# repara nisso olhando uma tabela de 29 colunas. Num painel, a ordem do tempo
# é parte da informação.

## 5.4 Conferindo o painel ----

# Quatro conferências, que valem para qualquer painel:

# 1. Uma linha por unidade: o número de linhas tem de bater com o número de
#    postos distintos do formato comprido.
nrow(painel_gasolina) == n_distinct(precos_gasolina$cnpj)

# 2. A chave da nova base é única (esperado: 0 linhas).
painel_gasolina %>%
  count(cnpj) %>%
  filter(n > 1)

# 3. Uma coluna por período: o número de colunas de semana tem de bater com
#    o número de semanas distintas.
painel_gasolina %>%
  select(starts_with("sem_")) %>%
  ncol()

n_distinct(precos_gasolina$semana_inicio)   # os dois devem dar 25

# 4. Nada sumiu: a soma das células preenchidas tem de bater com o número de
#    linhas do formato comprido.
sum(!is.na(painel_gasolina %>% select(starts_with("sem_"))))
nrow(precos_gasolina)   # os dois devem dar 631

## 5.5 O NA do painel desbalanceado NÃO é zero ----

# O painel tem 67 x 25 = 1675 células, e só 631 estão preenchidas.
67 * 25
sum(is.na(painel_gasolina %>% select(starts_with("sem_"))))   # 1044 vazias

# Menos de 40% preenchido:
round(100 * 631 / 1675, 1)

# Isso NÃO é defeito da base. A ANP faz rodízio: visita cerca de 29 postos
# por semana, não os 67. Cada célula vazia significa "este posto não foi
# visitado nesta semana" - e não "o preço foi zero", nem "o posto fechou".
#
# Preencher com values_fill = 0 criaria 1044 preços zerados e destruiria
# qualquer estatística. O NA aqui está correto e deve permanecer.
#
# Um painel assim se chama DESBALANCEADO: as unidades não são observadas nos
# mesmos períodos. Quantas semanas cada posto tem:
precos_gasolina %>%
  count(cnpj, name = "semanas_observadas") %>%
  summarise(
    minimo  = min(semanas_observadas),
    mediana = median(semanas_observadas),
    maximo  = max(semanas_observadas)
  )

# De 1 a 22 semanas, com mediana 8. Um posto observado uma única vez não
# sustenta nenhuma afirmação sobre trajetória de preço, e qualquer
# comparação entre postos precisa levar isso em conta.
#
# Quantos postos a ANP visitou em cada semana:
precos_gasolina %>%
  count(semana_inicio, name = "postos_visitados") %>%
  print(n = 25)

# Repare nas semanas com 3, 5, 11 e 13 postos. Uma média de preço calculada
# nessas semanas descreve um punhado de postos, não a cidade - e a variação
# de uma semana para a outra pode ser só mudança da amostra.


# 6. pivot_longer(): de volta ao formato comprido --------------------------

## 6.1 A volta ----

# Os argumentos são:
#
#   cols      = quais colunas devem ser empilhadas
#   names_to  = nome da NOVA coluna que recebe os NOMES das colunas
#   values_to = nome da NOVA coluna que recebe os VALORES
#
# Usamos starts_with("sem_") em cols: é justamente para isso que serve o
# prefixo criado na seção 5.3. Listar as 25 colunas na mão funcionaria, mas
# quebraria assim que a base ganhasse uma semana nova.
#
# names_prefix = "sem_" no pivot_longer() faz o caminho inverso: REMOVE o
# prefixo do texto antes de guardá-lo na coluna semana_rotulo.
#
#   MUDANÇA DE UNIDADE:
#     antes:  posto            (  67 linhas)
#     depois: posto x semana   (1675 linhas, contando as células vazias)

painel_comprido <- painel_gasolina %>%
  pivot_longer(
    cols         = starts_with("sem_"),
    names_to     = "semana_rotulo",
    values_to    = "valor_venda",
    names_prefix = "sem_"
  )

nrow(painel_comprido)                      # 1675 = 67 x 25
sum(is.na(painel_comprido$valor_venda))    # 1044

# values_drop_na = TRUE descarta as células vazias na hora de empilhar,
# devolvendo exatamente a base de onde partimos.
painel_comprido <- painel_gasolina %>%
  pivot_longer(
    cols           = starts_with("sem_"),
    names_to       = "semana_rotulo",
    values_to      = "valor_venda",
    names_prefix   = "sem_",
    values_drop_na = TRUE
  ) %>%
  mutate(semana_inicio = ymd(semana_rotulo))   # de volta a DATA

nrow(painel_comprido) == nrow(precos_gasolina)   # TRUE (631)
glimpse(painel_comprido)

# Note o ymd(): o rótulo voltou como TEXTO ("2026_01_04"). Para ordenar,
# filtrar por período ou calcular diferenças de tempo, ele precisa virar data
# de novo. Como texto, a ordenação funcionaria por acaso neste formato, mas
# a subtração de datas da seção 6.2 não funcionaria de jeito nenhum.
#
# Cuidado: values_drop_na = TRUE APAGA linhas. Use quando o NA significa
# "esta combinação não existe" (o nosso caso: visita que não houve). Se
# significasse "houve visita, mas o preço não foi anotado", você estaria
# jogando fora justamente as observações que precisaria investigar.

## 6.2 Conferindo que a ida e a volta preservaram os dados ----

# Não basta o número de linhas bater: os VALORES também precisam bater.
# Ordenamos as duas bases do mesmo jeito e comparamos as colunas em comum.
base_original <- precos_gasolina %>%
  select(cnpj, semana_inicio, valor_venda) %>%
  arrange(cnpj, semana_inicio)

base_ida_e_volta <- painel_comprido %>%
  select(cnpj, semana_inicio, valor_venda) %>%
  arrange(cnpj, semana_inicio)

# all.equal() responde TRUE ou descreve as diferenças encontradas.
all.equal(base_original, base_ida_e_volta)

# Conferência complementar: nenhum par posto x semana pode ter aparecido nem
# sumido. Montamos a chave dos dois lados colando as duas colunas e
# comparamos os conjuntos com setdiff(), que devolve o que está no primeiro
# e não está no segundo. Esperado nos dois sentidos: character(0).
chave_original    <- paste(base_original$cnpj, base_original$semana_inicio)
chave_ida_e_volta <- paste(base_ida_e_volta$cnpj, base_ida_e_volta$semana_inicio)

setdiff(chave_original, chave_ida_e_volta)
setdiff(chave_ida_e_volta, chave_original)

# Comparamos os dois sentidos porque um setdiff() sozinho não detecta pares
# que apareceram a mais do outro lado.

## 6.3 Por que o formato comprido é o de trabalho: a variação semanal ----

# Aqui fica claro para que serve voltar. Queremos, para cada posto, o quanto
# o preço mudou em relação à coleta anterior. lag() pega o valor da linha
# anterior - e só faz sentido depois de AGRUPAR pela unidade e ORDENAR pelo
# tempo. Sem group_by(cnpj), o lag() do primeiro posto pegaria o último
# preço do posto anterior, sem avisar.
variacao_semanal <- painel_comprido %>%
  arrange(cnpj, semana_inicio) %>%
  group_by(cnpj) %>%
  mutate(
    preco_anterior  = lag(valor_venda),
    semana_anterior = lag(semana_inicio),
    variacao        = valor_venda - preco_anterior,
    semanas_de_gap  = as.numeric(semana_inicio - semana_anterior) / 7
  ) %>%
  ungroup()

variacao_semanal %>%
  select(revenda, semana_inicio, valor_venda, preco_anterior, variacao, semanas_de_gap) %>%
  head(10)

# ATENÇÃO METODOLÓGICA. Em um painel desbalanceado, "linha anterior" não
# quer dizer "semana anterior". Veja a distância que o lag() realmente
# atravessou em cada caso:
variacao_semanal %>%
  count(semanas_de_gap)

# Só 381 das 564 diferenças comparam semanas consecutivas. As outras pulam
# de 2 a 13 semanas, e chamá-las de "variação semanal" seria errado: elas
# acumulam a variação de vários meses.
#
# O tratamento correto é restringir o cálculo aos pares realmente
# consecutivos, e dizer quantos ficaram de fora:
variacao_semanal %>%
  filter(semanas_de_gap == 1) %>%
  summarise(
    n_variacoes    = n(),
    variacao_media = mean(variacao),
    variacao_min   = min(variacao),
    variacao_max   = max(variacao)
  )

# A gasolina subiu, em média, cerca de R$ 0,05 por litro de uma semana para
# a seguinte. Esse número descreve as 381 transições consecutivas
# observadas, e não "os postos de Teresina" - a ANP não sorteia quem visita.
#
# Nada disso seria possível no formato largo: lag(), group_by() e a
# subtração de datas precisam que a semana seja uma COLUNA.


# 7. Exportando ------------------------------------------------------------

# O XLSX guarda várias tabelas, uma por aba. Entregamos as duas versões: o
# painel largo, para leitura, e o comprido, para quem for continuar a
# análise.
write_xlsx(
  list(
    painel_largo   = painel_gasolina,
    painel_comprido = painel_comprido,
    variacao_semanal = variacao_semanal %>% filter(semanas_de_gap == 1)
  ),
  "04_pivot/painel_gasolina_teresina.xlsx"
)

list.files("04_pivot")

# Em um painel, a aba larga é a que as pessoas leem, mas a comprida é a que
# você deve guardar para trabalhar. Ela não tem células vazias inventadas e
# aceita uma semana nova sem mudar de estrutura.


# 8. Problemas comuns ------------------------------------------------------
#
# 1. "Values are not uniquely identified; output will contain list-cols"
#    A combinação unidade x tempo se repete na base. Ou falta filtrar uma
#    dimensão (foi o nosso caso: o produto), ou há duplicata de verdade.
#    Investigue com count(unidade, tempo) %>% filter(n > 1) ANTES de usar
#    values_fn para abafar o aviso.
#
# 2. O painel saiu com uma linha por observação, e não uma por unidade
#    Sobrou uma coluna que varia dentro da unidade (no nosso caso,
#    data_coleta) e virou identificadora. Não há aviso. Use id_cols = para
#    declarar quem identifica a linha.
#
# 3. As colunas de período saíram fora de ordem
#    Use names_sort = TRUE, e um rótulo de data que ordene alfabeticamente
#    (ano_mês_dia).
#
# 4. Os nomes das colunas ficaram com "-" e exigem crase
#    Troque o separador no format() e use names_prefix para dar um começo de
#    texto ao nome.
#
# 5. Apareceram muitos NA que não existiam antes
#    É o normal em painel desbalanceado. Só use values_fill = 0 se a
#    ausência significar mesmo zero - o que quase nunca é o caso em preços.
#
# 6. pivot_longer() devolveu mais linhas do que a base original
#    São as células vazias virando linhas. Use values_drop_na = TRUE.
#
# 7. Depois do pivot_longer(), a coluna de período é texto e não ordena
#    Converta de volta com ymd() (ou as_date()).
#
# 8. lag() devolveu valores estranhos na primeira linha de cada unidade
#    Faltou group_by(unidade) antes, ou arrange(unidade, tempo). Sem os
#    dois, lag() atravessa a fronteira entre unidades sem avisar.


# =============================================================================
# EXERCÍCIO PRÁTICO
# =============================================================================
#
# As duas bases abaixo já vêm prontas: basta RODAR os dois blocos. Seu
# trabalho é só girar cada uma para o outro formato.


## Exercício (a) - de COMPRIDO para LARGO ----

# Rode este bloco. Ele cria etanol_comprido, com os preços do etanol:
# uma linha por posto-semana, 582 linhas.
etanol_comprido <- precos %>%
  filter(produto == "ETANOL") %>%
  mutate(semana = format(semana_inicio, "%Y_%m_%d")) %>%
  select(cnpj, semana, valor_venda)

etanol_comprido
dim(etanol_comprido)

# SUA TAREFA: use pivot_wider() para criar etanol_largo, com uma linha por
# posto e uma coluna por semana. Use names_prefix = "sem_" e
# names_sort = TRUE, como na seção 5.3.
#
# Depois responda, em um comentário: quantas células ficaram vazias e o que
# cada uma delas significa?

# SUA RESPOSTA AQUI



## Exercício (b) - de LARGO para COMPRIDO ----

# Rode este bloco. Ele cria coletas_largo, com o número de coletas da ANP
# por bandeira em cada mês: 5 linhas (uma por bandeira) e 6 colunas de mês.
coletas_largo <- precos %>%
  mutate(mes = format(data_coleta, "%Y_%m")) %>%
  count(bandeira, mes) %>%
  pivot_wider(
    names_from   = mes,
    values_from  = n,
    names_prefix = "mes_",
    values_fill  = 0
  )

coletas_largo

# SUA TAREFA: use pivot_longer() para criar coletas_comprido, com uma linha
# por bandeira-mês e as colunas bandeira, mes e n_coletas. Empilhe as
# colunas com starts_with("mes_") e use names_prefix = "mes_" para tirar o
# prefixo do rótulo, como na seção 6.1.
#
# Para conferir: o resultado deve ter 30 linhas, e a soma de n_coletas deve
# dar 2308 - o total de preços coletados na base.

# SUA RESPOSTA AQUI



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
