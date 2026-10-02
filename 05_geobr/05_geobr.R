# =============================================================================
# TUTORIAL 05 - DADOS ESPACIAIS DO BRASIL COM O PACOTE GEOBR
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Execute de cima para baixo, linha a linha ou bloco a bloco, com
#    Ctrl+Enter (Windows/Linux) ou Cmd+Enter (Mac).
# 2. As seções terminadas em "----" aparecem no painel Outline do RStudio.
# 3. Este tutorial PRECISA de internet: as bases são baixadas na hora.
# 4. Ao final há um exercício sobre o Piauí. Escreva a resposta no espaço
#    indicado por "# SUA RESPOSTA AQUI".
#
# OBJETIVOS
# ---------
# - baixar bases espaciais oficiais do Brasil com três funções do geobr:
#   read_state(), read_municipality() e read_schools();
# - reconhecer um objeto espacial (sf) e a sua coluna de geometria;
# - fazer mapas com ggplot2 e geom_sf(), com polígonos e com pontos;
# - contar escolas por município, percebendo a mudança na unidade de
#   observação.
# =============================================================================


# 1. O que é o geobr? ------------------------------------------------------
#
# O geobr é um pacote do Ipea que baixa direto no R as bases espaciais
# oficiais do Brasil (do IBGE, do INEP e de outros órgãos), sem precisar
# procurar, baixar e descompactar arquivos de mapa.
#
#   Documentação: https://ipea.github.io/geobr/
#
# Vamos usar três funções:
#
#   Função                Unidade de observação   Geometria
#   ----------------------------------------------------------
#   read_state()          estado (UF)             polígono
#   read_municipality()   município               polígono
#   read_schools()        escola                  ponto
#
# ATENÇÃO: as malhas de estados e municípios trazem nomes, códigos e o
# desenho do território. Elas NÃO trazem PIB, população ou renda. Para
# isso, baixa-se a variável em outra fonte (o SIDRA, por exemplo) e junta-se
# à malha pelo código do estado ou do município.


# 2. Preparação da sessão --------------------------------------------------

rm(list = ls())

# Algumas bases espaciais são grandes. Damos até 10 minutos para cada
# download, em vez do padrão de 1 minuto.
options(timeout = 600)

# Rode as linhas de instalação só na primeira vez (tire o # do início).
# install.packages("tidyverse")
# install.packages("geobr")

library(tidyverse)  # dplyr e ggplot2
library(sf)         # funções para objetos espaciais, como st_drop_geometry()
library(geobr)      # funções de download: read_state(), read_municipality()...

# Este tutorial foi testado com o geobr 2.1.0 e usa o ano de 2022. Se
# read_state() der o erro "Invalid Value to argument 'year/date'", o geobr
# instalado é antigo (a versão 1.9.1, por exemplo, só vai até 2020).
# Reinstale com install.packages("geobr") e reinicie o R (menu Session >
# Restart R). Se packageVersion("geobr") continuar mostrando 1.9.1, o R do
# seu computador é antigo demais para receber a versão nova pronta:
# atualize o R para a versão mais recente e instale o geobr de novo.
packageVersion("geobr")


# 3. Estados: read_state() -------------------------------------------------
#
# UNIDADE DE OBSERVAÇÃO: estado (UF)
# CHAVE: code_state
#
# code_state = "all" pede todas as UFs.

estados_2022 <- read_state(year = 2022, code_state = "all")

# 26 estados + Distrito Federal = 27 linhas
nrow(estados_2022)

## 3.1 O que é um objeto sf ----

# O resultado é um objeto "sf" (de simple features): uma tabela comum com
# uma coluna a mais, geometry, que guarda o desenho de cada estado.
class(estados_2022)
estados_2022

# Para olhar só a tabela, sem o desenho, use st_drop_geometry(). Faremos
# isso sempre que formos contar ou conferir dados.
estados_2022 %>%
  st_drop_geometry() %>%
  head()

## 3.2 O primeiro mapa ----

# geom_sf() lê a coluna geometry sozinho: não é preciso dizer quem é x e
# quem é y, como num gráfico de dispersão.
ggplot(estados_2022) +
  geom_sf(fill = "#2D3E50", color = "white", linewidth = 0.25) +
  labs(
    title   = "Estados brasileiros, 2022",
    caption = "Fonte: IBGE, via pacote geobr"
  ) +
  theme_void()


# 4. Municípios: read_municipality() ---------------------------------------
#
# UNIDADE DE OBSERVAÇÃO: município
# CHAVE: code_muni (código do IBGE, com 7 dígitos)
#
# Passando a sigla de uma UF em code_muni, baixamos todos os municípios
# daquele estado. Usaremos o Paraná como exemplo; o Piauí fica para o
# exercício.

municipios_pr <- read_municipality(year = 2022, code_muni = "PR")

nrow(municipios_pr)                  # 399 municípios
unique(municipios_pr$abbrev_state)   # só "PR"

# A chave não pode se repetir: um código, um município. anyDuplicated()
# devolve 0 quando não há nenhum valor repetido.
anyDuplicated(municipios_pr$code_muni)

ggplot(municipios_pr) +
  geom_sf(fill = "#1B998B", color = "white", linewidth = 0.15) +
  labs(
    title   = "Municípios do Paraná, 2022",
    caption = "Fonte: IBGE, via pacote geobr"
  ) +
  theme_void()


# 5. Escolas: read_schools() -----------------------------------------------
#
# UNIDADE DE OBSERVAÇÃO: escola
# CHAVE: code_school (código da escola no INEP)
# GEOMETRIA: ponto, ou seja, a localização de cada escola
#
# Os dados vêm do Censo Escolar e do Catálogo de Escolas do INEP.

escolas_pr <- read_schools(year = 2022, code_muni = "PR")

nrow(escolas_pr)                        # 10084 escolas
anyDuplicated(escolas_pr$code_school)   # 0: nenhuma escola repetida

## 5.1 Nem toda escola da base está funcionando ----

# A coluna tp_situacao_funcionamento segue o código do Censo Escolar:
#
#   1 = em atividade
#   2 = paralisada (atividades suspensas temporariamente)
#   3 = extinta    (atividades encerradas de vez)
table(escolas_pr$tp_situacao_funcionamento)

# 550 das 10084 escolas do Paraná não estavam funcionando em 2022. Se a
# pergunta é "quantas escolas cada município tem", elas não devem entrar
# na conta. Ficamos só com as escolas em atividade:
escolas_pr_ativas <- escolas_pr %>%
  filter(tp_situacao_funcionamento == 1)

nrow(escolas_pr_ativas)   # 9534

# Contar sem esse filtro não daria erro nenhum: o número só sairia maior do
# que deveria. Esse tipo de erro só se evita lendo o que cada coluna quer
# dizer.

## 5.2 Mapa de pontos sobre polígonos ----

# Um mapa pode ter várias camadas, uma para cada geom_sf(). Como as camadas
# vêm de bases diferentes, cada uma recebe a sua em data =. A primeira
# camada fica embaixo: os municípios; as escolas vão por cima.
ggplot() +
  geom_sf(data = municipios_pr, fill = "#F4F1DE", color = "grey70", linewidth = 0.15) +
  geom_sf(data = escolas_pr_ativas, color = "#D1495B", size = 0.3, alpha = 0.5) +
  labs(
    title    = "Escolas em atividade no Paraná, 2022",
    subtitle = "Cada ponto é uma escola",
    caption  = "Fonte: INEP e IBGE, via pacote geobr"
  ) +
  theme_void()


# 6. Quantas escolas tem cada município? -----------------------------------
#
#   MUDANÇA DE UNIDADE:
#     antes:  escola      (9534 linhas)
#     depois: município   (uma linha por município)
#
# Tiramos a geometria antes de contar. Queremos uma tabela, e não um mapa;
# com os pontos junto, o count() também juntaria os pontos de cada
# município, o que deixa a conta bem mais lenta.

escolas_por_municipio <- escolas_pr_ativas %>%
  st_drop_geometry() %>%
  count(code_muni, name_muni, name = "numero_escolas") %>%
  arrange(desc(numero_escolas))

escolas_por_municipio

# Conferências:
# 1. Uma linha por município: 399, como na malha da seção 4. Se o nome de
#    um município variasse dentro do mesmo código, apareceriam mais linhas.
nrow(escolas_por_municipio)

# 2. Nenhuma escola sumiu nem foi contada duas vezes: a soma tem de dar
#    9534, o número de escolas em atividade.
sum(escolas_por_municipio$numero_escolas)


# =============================================================================
# EXERCÍCIO PRÁTICO - ESCOLAS NO PIAUÍ
# =============================================================================
#
# Repita os passos das seções 4 a 6 para o PIAUÍ (sigla "PI"), com o ano de
# 2022. Use nomes descritivos, como municipios_pi e escolas_pi.
#
#   a) Baixe os municípios do Piauí com read_municipality().
#      Para conferir: devem ser 224 municípios.
#
#   b) Baixe as escolas do Piauí com read_schools() e fique só com as que
#      estão em atividade (tp_situacao_funcionamento == 1).
#      Para conferir: devem sobrar 4277 escolas.
#      Responda em um comentário: quantas escolas ficaram de fora?
#
#   c) Faça um mapa com os municípios do Piauí e as escolas em atividade
#      por cima, como na seção 5.2. Não esqueça de trocar o título.
#
#   d) Conte as escolas em atividade por município, como na seção 6, e
#      responda em um comentário: quantas escolas em atividade há em
#      Teresina?

# SUA RESPOSTA AQUI



# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto (canto superior esquerdo, ao lado do logo do
#    Posit Cloud, clique no nome do projeto) para:
#       SeuNome_SeuSobrenome - Tutorial 05
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
# FIM DO TUTORIAL 05
# =============================================================================
