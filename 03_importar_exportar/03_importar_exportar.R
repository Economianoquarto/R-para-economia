# =============================================================================
# TUTORIAL 03 - IMPORTAR E EXPORTAR DADOS (CSV E EXCEL)
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
# 4. Ao final há exercícios. Escreva as respostas nos espaços indicados
#    por "# SUA RESPOSTA AQUI".
# 5. Este tutorial NÃO precisa de internet: os dados já estão na pasta.
#
# OBJETIVOS
# ---------
# Ao final deste tutorial, você será capaz de:
#
# - entender onde o R procura um arquivo e escrever caminhos relativos;
# - inspecionar um arquivo de texto ANTES de importá-lo;
# - importar um CSV com separador ";" e decimal com vírgula;
# - reconhecer e corrigir problemas de encoding (acentos);
# - controlar os tipos das colunas em vez de aceitar o palpite do R;
# - identificar a unidade de observação e conferir a chave da base;
# - ler e gravar planilhas do Excel com readxl e writexl;
# - calcular estatísticas descritivas em vários níveis de agregação;
# - exportar resultados para um único .xlsx com várias abas.
#
# A BASE DE DADOS
# ---------------
# Preços de revenda de combustíveis coletados pela ANP (Agência Nacional do
# Petróleo, Gás Natural e Biocombustíveis) na Série Histórica de Preços.
#
#   Fonte:   https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos
#   Arquivo: preços do 1º semestre de 2026 (janeiro a junho)
#   Recorte: apenas o município de TERESINA/PI
#
# ATENÇÃO ao nome do arquivo: "2026_01" é o PRIMEIRO SEMESTRE de 2026, não
# o mês de janeiro. Nunca confie no nome do arquivo para saber o período
# coberto - confira as datas dentro da base (faremos isso na seção 6).
#
# O arquivo original da ANP tem 422.418 linhas e cobre o Brasil inteiro.
# Aqui usamos apenas Teresina, para que o arquivo seja leve o suficiente
# para o Posit Cloud.
#
# Arquivos que já estão na pasta 03_importar_exportar/:
#   postos_teresina_2026_01.csv   - a base no formato original da ANP
#   postos_teresina_2026_01.xlsx  - a mesma base em Excel
# =============================================================================


# 1. Preparação da sessão --------------------------------------------------

# Limpa os objetos da sessão para evitar que o script dependa de objetos
# criados anteriormente no Environment.
rm(list = ls())

# A instalação é necessária apenas uma vez em cada projeto.
# Se os pacotes ainda não estiverem instalados, remova o # das linhas abaixo,
# execute-as e depois coloque o # novamente.
# install.packages("tidyverse")
# install.packages("readxl")
# install.packages("writexl")

library(tidyverse)
library(readxl)   # LER arquivos .xls e .xlsx
library(writexl)  # GRAVAR arquivos .xlsx

# Por que dois pacotes diferentes para Excel?
#
# O readxl só lê e o writexl só grava. Os dois são leves e não dependem de
# Java nem de ter o Excel instalado, o que evita a maior parte dos problemas
# de instalação. O readxl faz parte do tidyverse, mas NÃO é carregado por
# library(tidyverse): é preciso chamá-lo explicitamente.
#
# Existe também o pacote openxlsx, que lê e grava no mesmo pacote e permite
# formatar a planilha (negrito, largura de coluna, congelar painel). Se você
# só precisa dos dados, readxl + writexl basta.


# 2. Onde o R procura os arquivos ------------------------------------------

# Esta é a causa nº 1 de erro na hora de importar dados.
#
# Quando você escreve read_csv("dados.csv"), o R procura o arquivo dentro do
# DIRETÓRIO DE TRABALHO (working directory). Para ver qual é ele:
getwd()

# Como este projeto tem um arquivo .Rproj, o diretório de trabalho é a PASTA
# RAIZ do projeto - e NÃO a pasta onde este script está salvo. Confira quais
# arquivos e pastas o R enxerga a partir daí:
list.files()

# Você deve ver as pastas dos tutoriais: 01_introducao_ao_R, 02_sidra,
# 03_importar_exportar, 04_geobr.
#
# Para olhar dentro de uma pasta específica:
list.files("03_importar_exportar")

# Por isso, todo caminho neste tutorial começa com "03_importar_exportar/":
# ele é RELATIVO à raiz do projeto.
caminho_csv  <- "03_importar_exportar/postos_teresina_2026_01.csv"
caminho_xlsx <- "03_importar_exportar/postos_teresina_2026_01.xlsx"

# file.exists() responde "o R consegue achar esse arquivo?". Se der FALSE,
# o problema é o caminho, não o arquivo.
file.exists(caminho_csv)
file.exists(caminho_xlsx)

# Duas coisas que você NÃO deve fazer:
#
# 1. Usar caminho absoluto, como "C:/Users/SeuNome/Documentos/dados.csv".
#    Esse caminho só existe no seu computador. O script deixa de funcionar
#    no Posit Cloud, no computador de um colega e no seu próximo notebook.
#
# 2. Usar setwd() para "consertar" o caminho. Além de quebrar em outra
#    máquina, ele muda um estado global da sessão: o resto do script passa a
#    depender de você ter rodado aquela linha antes.
#
# Observação: em R, use SEMPRE a barra normal "/" nos caminhos, mesmo no
# Windows. A barra invertida "\" é caractere de escape e daria erro.
# Alternativa que monta o caminho sozinha, com a barra certa em cada sistema:
# file.path("03_importar_exportar", "postos_teresina_2026_01.csv")


# 3. Olhando o arquivo cru antes de importar -------------------------------

# Um .csv é apenas um arquivo de texto. Antes de importar, leia as primeiras
# linhas COMO TEXTO. Isso responde, em 5 segundos, quatro perguntas que
# definem os argumentos da importação.
readLines(caminho_csv, n = 3)

# Repare no resultado:
#
# 1. Separador de colunas: ";" (ponto e vírgula), não ","
# 2. Separador decimal:    "," (vírgula) - veja "5,89"
# 3. Formato de data:      "07/01/2026" = dia/mês/ano
# 4. Acentos:              o arquivo está em UTF-8 (o padrão hoje)
#
# Esse conjunto - ";" com decimal "," - é o padrão brasileiro/europeu, e é
# como o Excel em português exporta CSV. Ele NÃO é o padrão do read_csv().


# 4. Importando o CSV -------------------------------------------------------

## 4.1 O erro clássico: usar read_csv() em um arquivo com ";" ----

# read_csv() espera vírgula como separador de colunas. Como o arquivo usa
# ";", ele não encontra nenhuma vírgula e conclui que existe UMA coluna só.
teste_errado <- read_csv(caminho_csv)

# Uma coluna, com o cabeçalho inteiro virando o nome dela:
dim(teste_errado)
names(teste_errado)

# Guarde esse sintoma: "importei e veio uma coluna só" quase sempre
# significa separador errado.

## 4.2 A importação correta ----

# read_delim() deixa você declarar o separador. O locale() descreve as
# convenções do arquivo: qual símbolo é o decimal e qual é o encoding.
postos_bruto <- read_delim(
  caminho_csv,
  delim = ";",
  locale = locale(
    decimal_mark = ",",   # "5,89" deve virar o número 5.89
    encoding = "UTF-8"    # para os acentos virem certos (ex.: SABBÁ)
  )
)

# Atalho: read_csv2() já assume delim = ";" e decimal ",". É mais curto,
# mas read_delim() deixa explícito o que está sendo suposto sobre o arquivo,
# e é isso que você vai querer quando o arquivo tiver alguma particularidade:
# postos_bruto <- read_csv2(caminho_csv)

## 4.3 Conferindo a importação ----

# Sempre confira a base logo depois de importar, antes de qualquer análise.
dim(postos_bruto)       # esperado: 2308 linhas x 16 colunas
names(postos_bruto)
glimpse(postos_bruto)
head(postos_bruto)

# problems() lista as linhas em que o readr não conseguiu converter um valor
# para o tipo escolhido. O ideal é que venha vazio (0 linhas).
problems(postos_bruto)

# Duas coisas para observar no glimpse():
#
# 1. "Valor de Venda" veio como <dbl> (número). Foi o decimal_mark = ","
#    que fez isso. Sem ele, viria como texto e nenhuma média funcionaria.
#
# 2. "Data da Coleta" veio como <chr> (texto), não como data. O readr só
#    reconhece datas sozinho no formato internacional (aaaa-mm-dd). Como o
#    arquivo usa dd/mm/aaaa, a conversão fica por nossa conta (seção 5).
#
# Sobre o campo entre aspas: o arquivo original da ANP tem endereços como
#    "LOJA: 101;"
# ou seja, um ponto e vírgula DENTRO do valor. O read_delim() entende que o
# que está entre aspas é um único campo e não quebra a linha ali. É por isso
# que se importa CSV com uma função de importação, e não separando o texto
# manualmente por ";".


# 5. Selecionando colunas, renomeando e ajustando tipos --------------------

# A base tem 16 colunas, com nomes que têm espaço e acento e por isso
# precisam de crase (`) para serem citados. Vamos ficar com o que interessa
# e usar nomes curtos, sem espaço e sem acento.
postos <- postos_bruto %>%
  select(
    `Estado - Sigla`,
    Municipio,
    Revenda,
    `CNPJ da Revenda`,
    Bairro,
    Produto,
    `Data da Coleta`,
    `Valor de Venda`,
    `Valor de Compra`,
    `Unidade de Medida`,
    Bandeira
  ) %>%
  rename(
    uf           = `Estado - Sigla`,
    municipio    = Municipio,
    revenda      = Revenda,
    cnpj         = `CNPJ da Revenda`,
    bairro       = Bairro,
    produto      = Produto,
    data_coleta  = `Data da Coleta`,
    valor_venda  = `Valor de Venda`,
    valor_compra = `Valor de Compra`,
    unidade      = `Unidade de Medida`,
    bandeira     = Bandeira
  ) %>%
  mutate(
    cnpj = str_trim(cnpj),          # o arquivo traz um espaço antes do CNPJ
    data_coleta = dmy(data_coleta)  # dmy() = dia-mês-ano, do lubridate
  )

glimpse(postos)

# Sobre os tipos:
#
# - cnpj é TEXTO, e deve continuar sendo. Ele é um identificador, não uma
#   quantidade: não faz sentido somar CNPJs, e convertê-lo para número
#   apagaria os zeros à esquerda.
#
# - data_coleta agora é <date>. Isso permite ordenar, filtrar por período e
#   extrair o mês. Como texto, "10/02/2026" viria ANTES de "07/03/2026" numa
#   ordenação alfabética, o que estaria errado.
#
# Confira se a conversão de data funcionou. Se dmy() falhar em alguma linha,
# ela vira NA e o R avisa com "failed to parse".
sum(is.na(postos$data_coleta))   # esperado: 0

# Atalho para limpar nomes de coluna: o pacote janitor tem clean_names(),
# que transforma "Valor de Venda" em "valor_de_venda" automaticamente.
# Aqui preferimos rename() explícito: dá mais trabalho, mas deixa registrado
# no script exatamente qual coluna original virou qual nome novo.


# 6. Unidade de observação e verificações de integridade -------------------

# Antes de calcular qualquer estatística, é preciso responder: o que é uma
# LINHA desta base?
#
# Aqui, cada linha é um preço coletado em um posto, para um produto, em uma
# data. Ou seja, a unidade de observação é:
#
#                    posto (CNPJ) × produto × data da coleta
#
# Isso importa: um posto que vende 5 produtos aparece 5 vezes em cada visita
# da ANP. Contar linhas NÃO é contar postos.

## 6.1 Quantos postos, produtos, bandeiras e datas ----

nrow(postos)                     # 2308 linhas (preços coletados)
n_distinct(postos$cnpj)          # 67 postos
n_distinct(postos$produto)       # 5 produtos
n_distinct(postos$bandeira)      # 5 bandeiras
n_distinct(postos$data_coleta)   # 76 datas de coleta

postos %>% count(produto, sort = TRUE)
postos %>% count(bandeira, sort = TRUE)

# Atenção a "BRANCA": é a categoria dos postos SEM bandeira, que compram de
# distribuidores variados. É uma informação de verdade, não um dado faltante.
# Se você a tratasse como ausente, perderia cerca de um quarto da amostra.

## 6.2 O período realmente coberto ----

# O nome do arquivo diz "2026_01", mas os dados vão de janeiro a junho.
range(postos$data_coleta)

postos %>%
  count(mes = floor_date(data_coleta, "month"))

# floor_date(x, "month") empurra qualquer data para o primeiro dia do mês.
# É a forma mais segura de agrupar por mês, porque o resultado continua
# sendo uma data e continua ordenando corretamente.

## 6.3 Conferindo a chave da base ----

# Se posto × produto × data identifica cada observação, então não pode
# existir nenhuma combinação repetida. O resultado abaixo deve ter 0 linhas.
duplicatas_chave <- postos %>%
  count(cnpj, produto, data_coleta) %>%
  filter(n > 1)

duplicatas_chave
nrow(duplicatas_chave)   # esperado: 0

# Se aqui aparecessem linhas, seria preciso investigar ANTES de seguir:
# duplicata de verdade? duas coletas no mesmo dia? erro de digitação no
# CNPJ? Cada explicação leva a um tratamento diferente - e simplesmente
# apagar as repetições com distinct() poderia esconder um problema real.

## 6.4 Valores ausentes ----

# Conta os NA de todas as colunas de uma vez. O across() aplica a mesma
# função a várias colunas; o pivot_longer() vira o resultado de uma linha
# larga para uma tabela comprida, bem mais fácil de ler.
ausentes_por_coluna <- postos %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  pivot_longer(
    everything(),
    names_to = "coluna",
    values_to = "ausentes"
  )

ausentes_por_coluna

# Duas colunas têm ausentes, e o tratamento certo é diferente em cada caso.
#
# valor_compra tem 2308 ausentes, ou seja, está VAZIA na base inteira: a ANP
# não divulga o preço de compra nesta série.
#
# NA aqui significa "não informado", e não "comprou de graça". Substituir
# esse NA por zero criaria uma margem de lucro de 100% em todos os postos.
# Como a coluna não traz informação nenhuma, o correto é removê-la e dizer
# por quê - e não preenchê-la.
postos <- postos %>%
  select(-valor_compra)

# bairro tem 50 ausentes: aqui o preço EXISTE, só o endereço está incompleto.
# Essas 50 linhas continuam valendo para qualquer estatística de preço, e
# apagá-las jogaria fora observações boas. Elas só atrapalhariam em uma
# análise por bairro - e aí o certo é excluí-las nesse cálculo específico,
# registrando quantas foram, e não da base inteira.
postos %>%
  filter(is.na(bairro)) %>%
  count(revenda, sort = TRUE)

## 6.5 Colunas constantes ----

# Depois do recorte, algumas colunas têm um único valor em todas as linhas.
postos %>% count(uf)
postos %>% count(municipio)
postos %>% count(unidade)

# unidade é sempre "R$ / litro". Isso precisa ser conferido, e não suposto:
# se houvesse "R$ / m³" (do GNV) misturado, calcular uma média de valor_venda
# somaria reais por litro com reais por metro cúbico. O número sairia, mas
# não significaria nada.


# 7. Excel: gravando e lendo .xlsx -----------------------------------------

## 7.1 Gravando um .xlsx ----

# write_xlsx() recebe a tabela e o caminho de saída.
write_xlsx(postos, "03_importar_exportar/postos_teresina_limpo.xlsx")

# Confira que o arquivo apareceu na pasta:
list.files("03_importar_exportar")

## 7.2 Lendo um .xlsx ----

# Uma planilha do Excel pode ter várias abas. Antes de ler, veja quais são:
excel_sheets(caminho_xlsx)

# Depois escolha a aba pelo nome (mais seguro) ou pela posição.
postos_do_excel <- read_excel(caminho_xlsx, sheet = "postos_teresina")

dim(postos_do_excel)
glimpse(postos_do_excel)

## 7.3 CSV e XLSX guardam coisas diferentes ----

# Compare o glimpse() acima com o da seção 4.3. No arquivo do Excel,
# "Data da Coleta" já veio como data e "Valor de Venda" já veio como número:
# não foi preciso locale(), nem decimal_mark, nem dmy().
#
# A razão é que o .xlsx guarda o TIPO de cada célula, enquanto o .csv é só
# texto - todo tipo ali é um palpite de quem lê. Em compensação, o .csv é
# leve, abre em qualquer programa e funciona bem com controle de versão
# (Git), enquanto o .xlsx é um arquivo binário.
#
# Regra prática: para TROCAR dados, prefira CSV. Para ENTREGAR resultados a
# quem vai abrir no Excel, use XLSX.
#
# Mas note que o tipo do Excel também não vem exatamente como você pediu: a
# data voltou como <dttm> (data-e-hora), e não como <date>. O Excel não
# separa os dois conceitos, então o readxl devolve sempre data-e-hora, com
# 00:00:00 no lugar do horário. Se você não precisa da hora, converta - um
# filtro por data pode não casar como você espera enquanto isso não for
# feito:
postos_do_excel <- postos_do_excel %>%
  mutate(`Data da Coleta` = as_date(`Data da Coleta`))

class(postos_do_excel$`Data da Coleta`)

## 7.4 Quando a planilha não começa na célula A1 ----

# Planilhas de órgãos públicos costumam trazer título, fonte e notas nas
# primeiras linhas. Os argumentos abaixo resolvem os casos mais comuns:
#
#   read_excel(arquivo, skip = 3)              # pula as 3 primeiras linhas
#   read_excel(arquivo, range = "B5:H120")     # lê só esse retângulo
#   read_excel(arquivo, n_max = 100)           # lê só as 100 primeiras
#   read_excel(arquivo, na = c("", "-", "..")) # trata esses códigos como NA
#
# Exemplo, lendo só as 10 primeiras linhas de 4 colunas:
amostra_excel <- read_excel(caminho_xlsx, range = "C1:F11")
amostra_excel


# 8. Estatísticas descritivas ----------------------------------------------

# A partir daqui, toda agregação MUDA a unidade de observação. Cada resumo
# abaixo indica o nível da base resultante.

## 8.1 Visão geral do preço ----

# summary() dá mínimo, quartis, mediana, média e máximo.
summary(postos$valor_venda)

# Esse número mistura gasolina, etanol e diesel, que têm preços muito
# diferentes. Serve para detectar valores absurdos, não para interpretar
# economicamente. A média que interessa é por produto.

## 8.2 Resumo por produto ----
# Nível da base resultante: PRODUTO (5 linhas)

resumo_por_produto <- postos %>%
  group_by(produto) %>%
  summarise(
    n_precos        = n(),
    n_postos        = n_distinct(cnpj),
    media           = mean(valor_venda),
    mediana         = median(valor_venda),
    desvio_padrao   = sd(valor_venda),
    minimo          = min(valor_venda),
    maximo          = max(valor_venda),
    coef_variacao   = 100 * sd(valor_venda) / mean(valor_venda)
  ) %>%
  arrange(desc(media))

resumo_por_produto

# Repare na diferença entre n_precos e n_postos: são 631 preços de gasolina,
# mas coletados em bem menos postos, porque o mesmo posto foi visitado
# várias vezes ao longo do semestre.
#
# O coeficiente de variação expressa o desvio-padrão como percentual da
# média. Ele permite comparar a dispersão entre produtos de preço médio
# diferente, o que o desvio-padrão sozinho não permite.
#
# Note que NÃO usamos na.rm = TRUE: já verificamos na seção 6.4 que
# valor_venda não tem nenhum ausente. Escrever na.rm = TRUE por reflexo é
# arriscado, porque esconde quantas observações entraram em cada conta.

## 8.3 Resumo por bandeira e produto ----
# Nível da base resultante: BANDEIRA × PRODUTO

resumo_por_bandeira <- postos %>%
  group_by(bandeira, produto) %>%
  summarise(
    n_precos = n(),
    n_postos = n_distinct(cnpj),
    media    = mean(valor_venda),
    mediana  = median(valor_venda),
    .groups  = "drop"
  ) %>%
  arrange(produto, media)

resumo_por_bandeira

# O .groups = "drop" desfaz o agrupamento depois do summarise(). Sem ele, a
# tabela continuaria agrupada por bandeira e as operações seguintes
# (mutate, filter) seriam feitas dentro de cada bandeira, sem aviso.

# Cuidado ao interpretar: algumas combinações têm pouquíssimas observações.
resumo_por_bandeira %>%
  filter(n_postos <= 3)

# Uma média calculada sobre 1 ou 2 postos descreve aqueles postos, não a
# bandeira. E, mesmo com muitas observações, a comparação entre bandeiras
# não separa o efeito da bandeira do efeito da localização: os postos não
# estão distribuídos ao acaso pela cidade.

## 8.4 Evolução mensal ----
# Nível da base resultante: MÊS × PRODUTO

resumo_mensal <- postos %>%
  mutate(mes = floor_date(data_coleta, "month")) %>%
  group_by(mes, produto) %>%
  summarise(
    n_precos = n(),
    media    = mean(valor_venda),
    .groups  = "drop"
  ) %>%
  arrange(produto, mes)

resumo_mensal

# Atenção: esta é a média dos preços COLETADOS no mês, e não um índice de
# preços. Se a ANP visitou postos diferentes em meses diferentes, parte da
# variação vem da mudança da amostra, e não da mudança dos preços. Repare
# como n_precos oscila bastante de um mês para outro.

## 8.5 Ranking de postos ----
# Nível da base resultante: POSTO (apenas gasolina comum)

ranking_gasolina <- postos %>%
  filter(produto == "GASOLINA") %>%
  group_by(cnpj, revenda, bairro, bandeira) %>%
  summarise(
    n_coletas   = n(),
    preco_medio = mean(valor_venda),
    .groups     = "drop"
  ) %>%
  arrange(desc(preco_medio))

ranking_gasolina

# Os cinco preços médios mais altos:
ranking_gasolina %>% head(5)

# Os cinco mais baixos:
ranking_gasolina %>% tail(5)

# Postos com poucas coletas aparecem nos extremos com mais facilidade, então
# vale olhar n_coletas antes de concluir qualquer coisa sobre o ranking.

## 8.6 Conferindo o resultado com um gráfico ----

# Um gráfico é uma boa forma de conferir se a tabela faz sentido: quebras
# estranhas, saltos e valores fora de lugar aparecem na hora.
ggplot(resumo_mensal, aes(x = mes, y = media, color = produto)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  theme_minimal() +
  labs(
    title = "Preço médio de revenda em Teresina, 2026",
    subtitle = "Média dos preços coletados pela ANP em cada mês",
    x = NULL,
    y = "R$ por litro",
    color = "Produto",
    caption = "Fonte: ANP, Série Histórica de Preços de Combustíveis"
  )


# 9. Salvando as estatísticas em um .xlsx com várias abas ------------------

# Esta é a vantagem prática do XLSX sobre o CSV: um CSV guarda UMA tabela,
# enquanto um XLSX guarda várias, cada uma em sua aba.
#
# Para isso, passe uma LISTA NOMEADA para write_xlsx(): cada elemento vira
# uma aba, e o nome do elemento vira o nome da aba.
write_xlsx(
  list(
    por_produto  = resumo_por_produto,
    por_bandeira = resumo_por_bandeira,
    por_mes      = resumo_mensal,
    por_posto    = ranking_gasolina
  ),
  "03_importar_exportar/estatisticas_postos_teresina.xlsx"
)

# Nomes de aba do Excel não podem passar de 31 caracteres nem conter
# : \ / ? * [ ]

## 9.1 Conferindo o que foi gravado ----

# Não confie que gravou: abra o arquivo de volta e confira.
caminho_saida <- "03_importar_exportar/estatisticas_postos_teresina.xlsx"

excel_sheets(caminho_saida)

conferencia_produto <- read_excel(caminho_saida, sheet = "por_produto")
conferencia_produto

# As médias devem bater com resumo_por_produto:
all.equal(
  resumo_por_produto$media,
  conferencia_produto$media
)


# 10. Outros formatos ------------------------------------------------------

## 10.1 .rds - o formato do próprio R ----

# saveRDS() grava UM objeto do R exatamente como ele está, preservando
# classes, fatores e datas. É o melhor formato para guardar uma etapa
# intermediária do seu trabalho.
saveRDS(postos, "03_importar_exportar/postos_teresina_limpo.rds")

postos_do_rds <- readRDS("03_importar_exportar/postos_teresina_limpo.rds")
glimpse(postos_do_rds)

# A desvantagem é que só o R lê .rds. Não use para entregar dados a alguém
# que trabalha em outro programa.

## 10.2 CSV para abrir no Excel em português ----

# write_csv() grava no padrão internacional: separador "," e decimal ".".
# Ao abrir esse arquivo com duplo clique no Excel em português, tudo cai em
# uma coluna só - exatamente o problema da seção 4.1, ao contrário.
#
# write_csv2() grava no padrão brasileiro (";" e decimal ","), que o Excel
# em português abre direto:
write_csv2(resumo_por_produto, "03_importar_exportar/resumo_por_produto.csv")

readLines("03_importar_exportar/resumo_por_produto.csv", n = 3)

## 10.3 Qual formato usar ----
#
#   .csv  - trocar dados com outras pessoas e programas; versionar no Git
#   .xlsx - entregar resultados a quem vai abrir no Excel; várias abas
#   .rds  - guardar etapas intermediárias do seu próprio trabalho em R
#
# Em um projeto de pesquisa, guarde SEMPRE o arquivo bruto original, sem
# modificação, e gere os arquivos tratados por script. Assim qualquer
# resultado pode ser refeito do zero, e um erro de tratamento nunca destrói
# o dado de origem.


# 11. Problemas comuns -----------------------------------------------------
#
# 1. "cannot open file ... No such file or directory"
#    O R não achou o arquivo. Rode getwd() e list.files() e confira o
#    caminho. Use file.exists(caminho) para testar antes de importar.
#
# 2. Importei e veio UMA COLUNA só
#    Separador errado. Veja readLines(arquivo, n = 3) e use read_delim()
#    com o delim correto (";" no padrão brasileiro).
#
# 3. A coluna de valor veio como texto (<chr>) e a média não funciona
#    Decimal com vírgula. Acrescente locale(decimal_mark = ",").
#
# 4. Os acentos vieram trocados (Ã‡, Ã£, SABBÃ)
#    Encoding errado. Tente locale(encoding = "UTF-8") ou, em arquivos mais
#    antigos, locale(encoding = "latin1"). Para descobrir qual é:
#    guess_encoding(caminho_csv)
#
# 5. A data não ordena direito
#    Ela ainda é texto. Converta com dmy() (dd/mm/aaaa), mdy() ou ymd(),
#    conforme o formato do arquivo, e confira com sum(is.na(...)).
#
# 6. O .xlsx veio com colunas chamadas ...1, ...2 e lixo nas primeiras linhas
#    A planilha tem título antes da tabela. Use skip = ou range =.
#
# 7. "could not find function read_excel"
#    library(tidyverse) NÃO carrega o readxl. Rode library(readxl).


# =============================================================================
# EXERCÍCIOS PRÁTICOS
# =============================================================================
#
# Escreva o código abaixo de cada pergunta. Antes de continuar, confira os
# tipos das variáveis, a unidade de observação e o número de linhas.


## Exercício 1 (Importação e conferência) ----
# Importe novamente o arquivo postos_teresina_2026_01.csv, agora no objeto
# precos_teresina, usando read_delim() com os argumentos corretos de
# separador e decimal. Em seguida:
#
# a) confirme que a base tem 2308 linhas e 16 colunas;
# b) mostre que problems() não retornou nenhuma linha;
# c) em um comentário, explique o que aconteceria com a coluna
#    "Valor de Venda" se você esquecesse o decimal_mark.

# SUA RESPOSTA AQUI



## Exercício 2 (Unidade de observação e chave) ----
# A partir do objeto postos (já tratado na seção 5):
#
# a) crie postos_etanol, com apenas as observações de ETANOL;
# b) diga quantas linhas e quantos postos distintos ele tem, e explique em
#    um comentário por que os dois números são diferentes;
# c) verifique se a combinação cnpj × data_coleta identifica cada linha de
#    postos_etanol, e mostre o número de duplicatas encontradas.

# SUA RESPOSTA AQUI



## Exercício 3 (Estatísticas descritivas) ----
# Usando postos_etanol, crie resumo_etanol_bandeira com uma linha por
# bandeira, contendo:
#
# a) número de preços coletados;
# b) número de postos distintos;
# c) preço médio;
# d) mediana;
# e) desvio-padrão;
# f) preço mínimo e máximo.
#
# Ordene do preço médio mais baixo para o mais alto. Em um comentário,
# aponte qual bandeira você NÃO compararia com as demais e por quê.

# SUA RESPOSTA AQUI



## Exercício 4 (Exportação em Excel) ----
# Grave um único arquivo chamado
# "03_importar_exportar/exercicio_etanol.xlsx" com DUAS abas:
#
#   "por_bandeira" - o resumo_etanol_bandeira do exercício 3;
#   "por_posto"    - preço médio do etanol por posto (cnpj, revenda,
#                    bairro, número de coletas e preço médio).
#
# Depois de gravar, use excel_sheets() para confirmar os nomes das abas e
# read_excel() para reabrir a aba "por_posto" e conferir o número de linhas.

# SUA RESPOSTA AQUI



## Exercício 5 - opcional (Do bruto ao entregável) ----
# Partindo de postos_bruto (a base como veio do arquivo, seção 4.2), escreva
# uma única cadeia com %>% que:
#
# a) selecione e renomeie apenas municipio, produto, data da coleta e valor
#    de venda;
# b) converta a data com dmy();
# c) fique só com o mês de março de 2026;
# d) calcule o preço médio por produto;
# e) grave o resultado em "03_importar_exportar/exercicio_marco.xlsx".
#
# Confira o número de linhas depois do filtro de março e compare com a
# contagem por mês da seção 6.2.

# SUA RESPOSTA AQUI



# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto (canto superior esquerdo, ao lado do logo do
#    Posit Cloud, clique no nome do projeto) para:
#       SeuNome_SeuSobrenome - Tutorial 03
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
# FIM DO TUTORIAL 03
# =============================================================================
