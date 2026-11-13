# =============================================================================
# TUTORIAL 06 - DO SIDRA PARA O MAPA: POPULAÇÃO DOS MUNICÍPIOS DO MARANHÃO
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute de cima para baixo, linha a linha ou bloco a bloco, com
#    Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 3. Este tutorial PRECISA de internet: os dados do SIDRA e a malha dos
#    municípios são baixados na hora.
# 4. Ao final há um exercício sobre o Piauí, que repete exatamente os mesmos
#    passos. Escreva a resposta no espaço indicado por "# SUA RESPOSTA AQUI".
#
# A IDEIA EM UMA FRASE
# --------------------
# O SIDRA tem o número, o geobr tem o desenho do território, e o código do
# IBGE é a ponte entre os dois.
#
# OBJETIVOS
# ---------
# - baixar do SIDRA uma variável no nível de município (tutorial 02);
# - baixar a malha municipal de um estado com o geobr (tutorial 05);
# - juntar as duas bases pelo código do IBGE com left_join(), conferindo a
#   chave antes e o resultado depois;
# - desenhar um mapa colorido por valor (mapa coroplético) com geom_sf();
# - perceber como um município muito grande domina a escala de cores e como
#   faixas de valores resolvem isso.
# =============================================================================


# 1. As duas bases e a ponte entre elas ------------------------------------
#
#   Base                      O que traz                     Chave
#   ---------------------------------------------------------------------
#   SIDRA (sidrar)            população de cada município    código do IBGE
#   malha municipal (geobr)   o desenho de cada município    código do IBGE
#
# Nenhuma das duas resolve sozinha: a malha não tem população e o SIDRA não
# tem o desenho do território. O mapa nasce do encontro das duas.
#
# A ponte é o código do município no IBGE, com 7 dígitos (Teresina = 2211001).
# NÃO juntamos as bases pelo nome do município. O nome muda de uma fonte para
# outra (no SIDRA vem "Caxias - MA"; no geobr, "Caxias"), há diferenças de
# acentuação e há nomes repetidos em estados diferentes. O código é estável.


# 2. Preparação da sessão --------------------------------------------------

rm(list = ls())

# A malha municipal é um arquivo grande. Damos até 10 minutos para o
# download, em vez do padrão de 1 minuto.
options(timeout = 600)

# Rode as linhas de instalação só na primeira vez (tire o # do início).
# install.packages("tidyverse")
# install.packages("sidrar")
# install.packages("geobr")

library(tidyverse)  # dplyr, ggplot2
library(sidrar)     # get_sidra(): dados do IBGE pela API do SIDRA
library(sf)         # objetos espaciais, st_drop_geometry()
library(geobr)      # read_municipality(): malha dos municípios


# 3. O número: população dos municípios do Maranhão ------------------------
#
# Usamos a mesma tabela do tutorial 02, agora no nível de município:
#
#   x        = 6579    -> tabela "População residente estimada";
#   variable = 9324    -> população residente estimada, em pessoas;
#   period   = "2026"  -> ano fixo (veja o aviso abaixo);
#   geo      = "City"  -> o resultado vem por município;
#   geo.filter = list("State" = 21) -> só os municípios do Maranhão.
#
# geo e geo.filter trabalham juntos: geo diz o nível do resultado (município)
# e geo.filter diz onde procurar (dentro da UF 21). Sem o filtro, viriam os
# mais de 5.500 municípios do Brasil.
#
# 21 é o código do IBGE para o Maranhão (o Piauí é 22). Os códigos de UF são
# os dois primeiros dígitos do código do município.
#
# REPRODUTIBILIDADE: period = "last" traz sempre a divulgação mais recente e,
# por isso, os números mudariam de uma divulgação para a outra. Com o ano
# fixo em "2026", todas as conferências deste tutorial continuam valendo.

populacao_ma_sidra <- get_sidra(
  x = 6579,
  variable = 9324,
  period = "2026",
  geo = "City",
  geo.filter = list("State" = 21)
)

## 3.1 Primeira inspeção ----

# UNIDADE DE OBSERVAÇÃO ESPERADA: município × ano.
# Como pedimos um único ano, deve haver uma linha por município: 217 linhas,
# o número de municípios do Maranhão.
nrow(populacao_ma_sidra)
names(populacao_ma_sidra)
glimpse(populacao_ma_sidra)

# Um só ano e uma só unidade de medida, como pedimos.
count(populacao_ma_sidra, Ano)
count(populacao_ma_sidra, `Unidade de Medida`)

## 3.2 Selecionando e renomeando ----

# Mantemos o código como TEXTO: ele é um identificador, não uma quantidade.
# Somar ou tirar a média de códigos de município não significaria nada.
#
# Damos à coluna do código o nome code_muni, que é o nome usado pelo geobr.
# Com o mesmo nome nas duas bases, o left_join() da seção 5 fica mais simples.

populacao_ma <- populacao_ma_sidra %>%
  select(
    `Município (Código)`,
    `Município`,
    Ano,
    Valor
  ) %>%
  rename(
    code_muni = `Município (Código)`,
    municipio = `Município`,
    ano = Ano,
    populacao = Valor
  ) %>%
  mutate(
    code_muni = as.character(code_muni),
    ano = as.integer(ano)
  )

head(populacao_ma)
glimpse(populacao_ma)

## 3.3 Conferindo a chave e os valores ausentes ----

# A chave não pode se repetir: um código, um município. anyDuplicated()
# devolve 0 quando não há nenhum valor repetido.
anyDuplicated(populacao_ma$code_muni)

# Nenhuma população ausente. Se houvesse NA, o município apareceria cinza no
# mapa, e isso precisaria ser explicado — e não preenchido com zero.
sum(is.na(populacao_ma$populacao))


# 4. O desenho: malha dos municípios do Maranhão ---------------------------
#
# UNIDADE DE OBSERVAÇÃO: município
# CHAVE: code_muni
#
# É o mesmo read_municipality() do tutorial 05, trocando "PR" por "MA".

municipios_ma <- read_municipality(year = 2022, code_muni = "MA")

nrow(municipios_ma)                    # 217 municípios
anyDuplicated(municipios_ma$code_muni) # 0: nenhum código repetido

# No geobr o código vem como número; no SIDRA, como texto. É o mesmo código
# escrito de duas formas, e left_join() não junta texto com número: ele para
# com um erro dizendo que os tipos da chave são incompatíveis.
class(municipios_ma$code_muni)
class(populacao_ma$code_muni)

# Passamos o código da malha para texto, acompanhando a decisão da seção 3.2.
municipios_ma <- municipios_ma %>%
  mutate(code_muni = as.character(code_muni))

# Os dois primeiros códigos de cada base, agora no mesmo formato:
head(municipios_ma$code_muni, 2)
head(populacao_ma$code_muni, 2)


# 5. A junção das duas bases -----------------------------------------------
#
# ANTES DE JUNTAR:
#   chave esperada:   code_muni
#   unicidade:        conferida nas duas bases (seções 3.3 e 4)
#   relação esperada: um-para-um (cada município da malha tem uma população)
#   resultado:        217 linhas, uma por município
#
# A malha vai à ESQUERDA do left_join() por dois motivos: o resultado
# continua sendo um objeto sf, isto é, continua desenhável; e nenhum
# município do mapa some, mesmo que falte a população de algum deles.

mapa_populacao_ma <- municipios_ma %>%
  left_join(populacao_ma, by = "code_muni")

## 5.1 Conferências depois do join ----

# 1. O número de linhas não pode ter mudado: continua 217. Mais linhas
#    indicaria chave repetida em alguma das bases.
nrow(mapa_populacao_ma)

# 2. Nenhum município ficou sem população. Um NA aqui significaria um código
#    da malha que não existe na base do SIDRA.
sum(is.na(mapa_populacao_ma$populacao))

# 3. O caminho contrário: algum município do SIDRA ficou de fora do mapa?
#    anti_join() devolve as linhas da primeira base que não encontraram
#    correspondência na segunda. Zero linhas é o resultado esperado.
municipios_sem_mapa <- populacao_ma %>%
  anti_join(st_drop_geometry(municipios_ma), by = "code_muni")

nrow(municipios_sem_mapa)

# 4. O objeto continua sendo espacial, e agora tem a coluna populacao.
class(mapa_populacao_ma)

mapa_populacao_ma %>%
  st_drop_geometry() %>%
  select(code_muni, name_muni, ano, populacao) %>%
  head()

## 5.2 Um olhar nos números antes do mapa ----

# Vale conhecer a variável antes de pintá-la. A distância entre a mediana e o
# máximo já antecipa o problema da seção 6.
summary(mapa_populacao_ma$populacao)

# Total do estado: 7.024.557 pessoas em 2026.
sum(mapa_populacao_ma$populacao)

# Os cinco municípios mais populosos.
mapa_populacao_ma %>%
  st_drop_geometry() %>%
  arrange(desc(populacao)) %>%
  select(name_muni, populacao) %>%
  head(5)


# 6. O mapa coroplético ----------------------------------------------------
#
# Mapa coroplético é o mapa em que a COR de cada área representa o valor de
# uma variável. Em relação ao tutorial 05, muda uma coisa só: a cor de
# preenchimento deixa de ser fixa e passa para dentro do aes().
#
#   antes (tutorial 05):  geom_sf(fill = "#1B998B")
#   agora:                geom_sf(aes(fill = populacao))
#
# scale_fill_viridis_c() define a escala de cores; o "c" é de contínua,
# porque população é uma variável contínua. direction = -1 faz os valores
# altos ficarem escuros.

ggplot(mapa_populacao_ma) +
  geom_sf(aes(fill = populacao), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(option = "magma", direction = -1) +
  labs(
    title   = "População estimada dos municípios do Maranhão, 2026",
    fill    = "Pessoas",
    caption = "Fonte: IBGE (SIDRA, tabela 6579) e malha municipal do IBGE, via geobr"
  ) +
  theme_void()

# O QUE DEU ERRADO NESSE MAPA?
# O mapa está correto, mas informa pouco. São Luís tem 1,09 milhão de
# habitantes e a mediana dos municípios é de 17.625 pessoas: a escala de
# cores precisa ir de 4 mil a 1,1 milhão, e quase todo o estado acaba na
# mesma cor clara. O mapa só mostra o que já sabíamos, que a capital é
# grande.


# 7. Faixas de população ---------------------------------------------------
#
# A saída é parar de pintar o valor exato e passar a pintar FAIXAS. Assim as
# diferenças entre os municípios pequenos e médios, que são a maioria,
# voltam a aparecer.
#
# cut() transforma uma variável numérica em categorias:
#
#   breaks = os pontos de corte; Inf é "daí para cima";
#   labels = o nome de cada faixa, na mesma ordem dos cortes.
#
# Os cortes abaixo são uma escolha nossa, em números redondos. Outra divisão
# razoável daria um mapa um pouco diferente — por isso a escolha das faixas
# faz parte do resultado e deve aparecer na legenda ou no texto.

mapa_populacao_ma <- mapa_populacao_ma %>%
  mutate(
    faixa_populacao = cut(
      populacao,
      breaks = c(0, 10000, 20000, 50000, 100000, Inf),
      labels = c("até 10 mil", "10 a 20 mil", "20 a 50 mil",
                 "50 a 100 mil", "mais de 100 mil")
    )
  )

# Conferência: quantos municípios caíram em cada faixa? A soma tem de dar
# 217, e nenhuma linha pode ter ficado como NA — o que aconteceria se algum
# valor ficasse fora dos cortes.
mapa_populacao_ma %>%
  st_drop_geometry() %>%
  count(faixa_populacao)

# Agora a escala é discreta, com cinco categorias, e usamos
# scale_fill_brewer() no lugar de scale_fill_viridis_c().
ggplot(mapa_populacao_ma) +
  geom_sf(aes(fill = faixa_populacao), color = "white", linewidth = 0.1) +
  scale_fill_brewer(palette = "YlGnBu") +
  labs(
    title    = "População estimada dos municípios do Maranhão, 2026",
    subtitle = "Municípios agrupados em faixas de população",
    fill     = "População",
    caption  = "Fonte: IBGE (SIDRA, tabela 6579) e malha municipal do IBGE, via geobr"
  ) +
  theme_void()

# Compare os dois mapas. O segundo mostra o eixo Imperatriz-Açailândia, no
# oeste, a faixa litorânea em volta de São Luís e o vazio demográfico do sul
# do estado. Nada disso aparecia no primeiro.


# 8. Salvando o mapa (opcional) --------------------------------------------
#
# ggsave() salva o último gráfico exibido. Tire o # para usar:
#
# ggsave("mapa_populacao_ma.png", width = 7, height = 7, dpi = 300)
#
# Para reproduzir depois a análise exatamente como ela está hoje, também vale
# guardar a base já juntada:
#
# saveRDS(mapa_populacao_ma, "mapa_populacao_ma.rds")


# =============================================================================
# EXERCÍCIO PRÁTICO - POPULAÇÃO DOS MUNICÍPIOS DO PIAUÍ
# =============================================================================
#
# Refaça as seções 3 a 7 para o PIAUÍ. Muda só o estado: o código da UF no
# geo.filter passa a ser 22 e a sigla no read_municipality() passa a ser
# "PI". Mantenha a tabela 6579, a variável 9324 e o período "2026". Use
# nomes descritivos, como populacao_pi, municipios_pi e mapa_populacao_pi.
#
#   a) Baixe do SIDRA a população estimada dos municípios do Piauí em 2026.
#      Para conferir: devem vir 224 linhas, uma por município.
#      Selecione e renomeie as colunas como na seção 3.2 e confirme que o
#      código não se repete.
#

populacao_pi_sidra <- get_sidra(
  x = 6579,
  variable = 9324,
  period = "2026",
  geo = "City",
  geo.filter = list("State" = 22)
)

nrow(populacao_pi_sidra) # 224 municípios
glimpse(populacao_pi_sidra)

populacao_pi <- populacao_pi_sidra %>%
  select(
    `Município (Código)`,
    `Município`,
    Ano,
    Valor
  ) %>%
  rename(
    code_muni = `Município (Código)`,
    municipio = `Município`,
    ano = Ano,
    populacao = Valor
  ) %>%
  mutate(
    code_muni = as.character(code_muni),
    ano = as.integer(ano)
  )

head(populacao_pi)
anyDuplicated(populacao_pi$code_muni) # 0: nenhum código repetido

#   b) Baixe a malha dos municípios do Piauí com read_municipality() e passe
#      o code_muni para texto.
#      Para conferir: 224 municípios.
#

municipios_pi <- read_municipality(year = 2022, code_muni = "PI")

nrow(municipios_pi)                    # 224 municípios
anyDuplicated(municipios_pi$code_muni) # 0: nenhum código repetido

municipios_pi <- municipios_pi %>%
  mutate(code_muni = as.character(code_muni))

class(municipios_pi$code_muni) # "character"

#   c) Junte as duas bases com left_join(), com a malha à esquerda, e faça as
#      conferências da seção 5.1.
#      Responda em um comentário: o join manteve as 224 linhas? Ficou algum
#      município sem população?
#
#   d) Faça o mapa coroplético com a escala contínua, como na seção 6.
#      Responda em um comentário: qual município domina a escala de cores?
#
#   e) Crie as faixas de população com os mesmos cortes da seção 7 e faça o
#      mapa das faixas. Conte quantos municípios caíram em cada faixa.
#      Responda em um comentário: no Piauí, essas faixas separam bem os
#      municípios ou quase todos caem na mesma faixa? Se a maioria ficou
#      junta, proponha cortes melhores para o Piauí e refaça o mapa.


# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto (canto superior esquerdo, ao lado do logo do
#    Posit Cloud, clique no nome do projeto) para:
#       SeuNome_SeuSobrenome - Tutorial 06
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
# FIM DO TUTORIAL 06
# =============================================================================
