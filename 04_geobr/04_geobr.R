# =============================================================================
# TUTORIAL 04 - DADOS ESPACIAIS DO BRASIL COM O PACOTE GEOBR
# Curso: Economia no Quarto - Ciência de Dados para Economia
# Professor(a): Caio Lopes | economianoquarto@gmail.com
# =============================================================================
#
# COMO USAR ESTE SCRIPT
# ----------------------
# 1. Não use o botão "Source" para rodar o arquivo inteiro de uma vez.
#    Vá executando de cima para baixo, LINHA A LINHA ou BLOCO A BLOCO,
#    com o cursor na linha e apertando Ctrl+Enter (Windows/Linux) ou
#    Cmd+Enter (Mac).
# 2. Leia os comentários antes de rodar o código. Neste tutorial, eles
#    são especialmente importantes porque identificam a unidade de
#    observação de cada base e explicam quando ela muda.
# 3. Use o painel "Outline" do Posit Cloud (ícone de lista no canto
#    superior direito do editor) para navegar entre as seções. Todas as
#    seções abaixo terminam em "----" e aparecem no índice.
# 4. Os downloads exigem conexão com a internet. Na primeira chamada de
#    uma função, o geobr pode levar alguns instantes para baixar a base.
# 5. Ao final há uma seção "EXERCÍCIOS PRÁTICOS". Escreva suas respostas
#    logo abaixo de cada pergunta, no espaço indicado.
# 6. Quando terminar, siga as instruções da última seção para compartilhar
#    o projeto comigo pelo Posit Cloud.
#
# OBJETIVOS DA AULA
# -----------------
# Ao final deste tutorial, você será capaz de:
#   - baixar malhas geográficas oficiais do Brasil;
#   - reconhecer a estrutura de um objeto espacial da classe sf;
#   - identificar a unidade de observação e as chaves geográficas;
#   - construir mapas com ggplot2 e geom_sf();
#   - trabalhar com polígonos e pontos;
#   - agregar uma base de escolas do nível escola para município;
#   - fazer um join seguro entre indicadores e uma malha municipal.
#
# =============================================================================


# 0. Fontes e material de referência ---------------------------------------
#
# O geobr é desenvolvido por pesquisadores do Instituto de Pesquisa
# Econômica Aplicada (Ipea) e facilita o acesso a bases espaciais oficiais
# produzidas por instituições como IBGE, INEP, DataSUS, MMA e FUNAI.
#
# Documentação oficial:
#   https://ipea.github.io/geobr/
#
# Repositório oficial:
#   https://github.com/ipea/geobr
#
# Como a forma recomendada de citação pode acompanhar as atualizações do
# pacote, consulte citation("geobr") para ver a referência indicada pela
# versão instalada no seu projeto.


# 1. O que é o geobr? ------------------------------------------------------
#
# O geobr permite baixar dados espaciais oficiais do Brasil diretamente
# no R. Em vez de procurar um arquivo shapefile, fazer download, descompactar
# e descobrir qual arquivo abrir, usamos funções com uma sintaxe padronizada.
#
# Exemplos de recortes disponíveis:
#   - país;
#   - regiões;
#   - estados;
#   - municípios;
#   - setores censitários;
#   - biomas;
#   - áreas urbanas;
#   - escolas;
#   - estabelecimentos de saúde.
#
# ATENÇÃO: as malhas de estados e municípios trazem principalmente nomes,
# códigos geográficos e a geometria. Elas não incluem automaticamente PIB,
# população, renda ou emprego.
#
# Em pesquisas econômicas, o fluxo mais comum é:
#
#   1. baixar a malha geográfica com o geobr;
#   2. obter a variável econômica em outra base;
#   3. conferir as chaves geográficas;
#   4. juntar as bases;
#   5. construir o mapa.
#
# Neste tutorial, manteremos os exemplos dentro do próprio geobr. Para criar
# um indicador temático, contaremos escolas geolocalizadas por município.


# 2. Unidade de observação em bases espaciais -----------------------------
#
# A unidade de observação continua sendo importante quando trabalhamos com
# mapas. A diferença é que cada observação também possui uma geometria.
#
# Exemplos:
#
# Base                         Unidade de observação     Tipo de geometria
# -------------------------------------------------------------------------
# read_state()                 estado                    polígono
# read_municipality()          município                 polígono
# read_municipal_seat()        sede municipal            ponto
# read_schools()               escola                    ponto
# read_statistical_grid()      célula da grade           polígono
#
# A coluna de geometria não transforma duas linhas repetidas em observações
# diferentes. As chaves ainda precisam ser conferidas antes de agregações e
# joins.


# 3. Preparação do ambiente -----------------------------------------------

# Limpar o Environment evita usar objetos de uma sessão anterior sem notar.
rm(list = ls())

# Aumentamos o tempo máximo de espera porque algumas bases espaciais são
# maiores que bases tabulares comuns.
options(timeout = 600)

# Rode as linhas de instalação somente na primeira vez em cada projeto.
# A instalação do geobr também instala dependências espaciais importantes.
# A versão atual do geobr requer R 4.4 ou mais recente. Se a instalação
# informar que o pacote não está disponível para sua versão do R, atualize a
# versão do R usada pelo projeto antes de tentar novamente.
install.packages("tidyverse")
install.packages("geobr")

# O tidyverse será usado para manipulação de dados e gráficos.
# O sf fornece as funções para objetos espaciais.
# O geobr fornece as funções de download.
library(tidyverse)
library(sf)
library(geobr)

# Registrar as versões ajuda a reproduzir a aula posteriormente.
R.version.string
packageVersion("geobr")
packageVersion("sf")
packageVersion("dplyr")

# Ver a forma de citação recomendada para a versão instalada:
citation("geobr")


# 4. Quais bases estão disponíveis? ---------------------------------------
#
# list_geobr() consulta as bases e os anos disponíveis. Essa consulta é
# preferível a supor que uma função aceita qualquer ano.

bases_geobr <- list_geobr(wide = TRUE)

glimpse(bases_geobr)
bases_geobr

# Vamos localizar somente as bases utilizadas nesta aula. A coluna Function
# tem F maiúsculo porque esse é o nome usado no objeto retornado pelo pacote.
bases_da_aula <- bases_geobr %>%
  filter(
    Function %in% c(
      "read_state",
      "read_municipality",
      "read_municipal_seat",
      "read_schools",
      "read_statistical_grid"
    )
  )

bases_da_aula

# Usaremos 2022 porque esse ano está disponível em comum para estados,
# municípios, sedes municipais e escolas. Manter o mesmo ano reduz o risco
# de juntar recortes territoriais incompatíveis.


# 5. Baixando a malha dos estados -----------------------------------------
#
# UNIDADE DE OBSERVAÇÃO: estado/UF.
# CHAVE ESPERADA: code_state.
#
# code_state = "all" solicita todas as UFs. simplified = TRUE usa uma
# geometria mais leve, adequada para visualização e para esta aula.

estados_2022 <- read_state(
  year = 2022,
  code_state = "all",
  simplified = TRUE,
  showProgress = FALSE
)

# Primeiras verificações:
class(estados_2022)
glimpse(estados_2022)
nrow(estados_2022)

# O Brasil possui 26 estados e o Distrito Federal. Portanto, esperamos
# encontrar 27 observações.
nrow(estados_2022) == 27

# Verificamos se code_state identifica cada linha de forma única.
duplicatas_estados <- estados_2022 %>%
  st_drop_geometry() %>%
  count(code_state) %>%
  filter(n > 1)

duplicatas_estados

# Se o resultado acima tiver zero linhas, não encontramos códigos estaduais
# repetidos.


# 6. Entendendo um objeto sf ----------------------------------------------
#
# Um objeto sf se parece com um data frame, mas possui uma coluna especial
# chamada geometry. Essa coluna guarda pontos, linhas ou polígonos.

names(estados_2022)

# Tipo das geometrias presentes na base:
table(st_geometry_type(estados_2022))

# Sistema de Referência de Coordenadas (CRS):
st_crs(estados_2022)

# As bases do geobr usam SIRGAS 2000, geralmente identificado como EPSG 4674.
# O CRS informa ao R como as coordenadas devem ser interpretadas.

# Conferir se as geometrias são válidas:
table(st_is_valid(estados_2022))

# st_drop_geometry() remove a geometria e retorna apenas a parte tabular.
# Isso é útil para tabelas, contagens e verificações que não usam o mapa.
tabela_estados <- estados_2022 %>%
  st_drop_geometry()

class(tabela_estados)
glimpse(tabela_estados)


# 7. Primeiro mapa com geom_sf() ------------------------------------------
#
# geom_sf() entende automaticamente a coluna geometry. Por isso, não é
# necessário informar variáveis x e y como em um gráfico de dispersão.

mapa_estados <- ggplot(data = estados_2022) +
  geom_sf(
    fill = "#2D3E50",
    color = "white",
    linewidth = 0.25
  ) +
  labs(
    title = "Estados brasileiros",
    subtitle = "Malha territorial de 2022",
    caption = "Fonte: IBGE, via pacote geobr"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

mapa_estados


# 8. Baixando os municípios do Paraná ------------------------------------
#
# UNIDADE DE OBSERVAÇÃO: município.
# CHAVE ESPERADA: code_muni.
#
# Usaremos o Paraná porque o recorte é suficientemente variado para os mapas
# e menor que baixar todos os municípios brasileiros. Para solicitar todos
# os municípios de uma UF, passamos sua sigla em code_muni.

municipios_pr <- read_municipality(
  year = 2022,
  code_muni = "PR",
  simplified = TRUE,
  showProgress = FALSE
)

class(municipios_pr)
glimpse(municipios_pr)
nrow(municipios_pr)

# Conferimos se todas as observações pertencem ao Paraná.
unique(municipios_pr$abbrev_state)

# Conferimos a chave municipal. Uma saída com zero linhas é o resultado
# esperado.
duplicatas_municipios <- municipios_pr %>%
  st_drop_geometry() %>%
  count(code_muni) %>%
  filter(n > 1)

duplicatas_municipios

# Visualizar somente algumas colunas, sem imprimir a geometria:
municipios_pr %>%
  st_drop_geometry() %>%
  select(code_muni, name_muni, abbrev_state) %>%
  arrange(name_muni) %>%
  head(10)


# 9. Mapa dos municípios -------------------------------------------------

mapa_municipios_pr <- ggplot(data = municipios_pr) +
  geom_sf(
    fill = "#1B998B",
    color = "white",
    linewidth = 0.15
  ) +
  labs(
    title = "Municípios do Paraná",
    subtitle = "Malha municipal de 2022",
    caption = "Fonte: IBGE, via pacote geobr"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

mapa_municipios_pr


# 10. Procurando o código de um município --------------------------------
#
# Bases do IBGE normalmente identificam municípios por códigos de 7 dígitos.
# O nome não é uma chave segura: pode conter acentos, grafias diferentes ou
# municípios homônimos em estados distintos.
#
# lookup_muni() ajuda a localizar o código a partir do nome.

busca_curitiba <- lookup_muni(
  name_muni = "Curitiba",
  year = 2022
)

busca_curitiba

# Filtramos a UF antes de extrair o código. Essa etapa torna explícito qual
# município queremos, mesmo quando uma busca por nome devolver mais de uma
# observação.
codigo_curitiba <- busca_curitiba %>%
  filter(abbrev_state == "PR") %>%
  pull(code_muni)

codigo_curitiba

# Selecionar Curitiba dentro da malha já baixada não altera a unidade de
# observação: continuamos no nível município, mas agora com uma única linha.
curitiba <- municipios_pr %>%
  filter(code_muni == codigo_curitiba)

nrow(curitiba)


# 11. Pontos: sedes municipais --------------------------------------------
#
# read_municipal_seat() retorna a localização das sedes municipais.
#
# UNIDADE DE OBSERVAÇÃO: sede municipal.
# TIPO DE GEOMETRIA: ponto.

sedes_pr <- read_municipal_seat(
  year = 2022,
  code_muni = "PR",
  showProgress = FALSE
)

class(sedes_pr)
glimpse(sedes_pr)
table(st_geometry_type(sedes_pr))

# A comparação abaixo é uma verificação útil: esperamos uma sede para cada
# município. Se os valores forem diferentes, devemos investigar antes de usar
# as bases em conjunto.
nrow(municipios_pr)
nrow(sedes_pr)
nrow(municipios_pr) == nrow(sedes_pr)

# Sobreposição de duas camadas:
#   1. polígonos dos municípios;
#   2. pontos das sedes municipais.

mapa_sedes_pr <- ggplot() +
  geom_sf(
    data = municipios_pr,
    fill = "#F4F1DE",
    color = "white",
    linewidth = 0.15
  ) +
  geom_sf(
    data = sedes_pr,
    color = "#D1495B",
    size = 0.6,
    alpha = 0.8
  ) +
  labs(
    title = "Sedes municipais do Paraná",
    subtitle = "Pontos sobre a malha municipal de 2022",
    caption = "Fonte: IBGE, via pacote geobr"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

mapa_sedes_pr


# 12. Uma base temática do geobr: escolas --------------------------------
#
# read_schools() usa dados do Censo Escolar e do Catálogo de Escolas do INEP.
# Os pontos são formados por coordenadas do produtor original e, em alguns
# casos, por coordenadas obtidas por geocodificação.
#
# UNIDADE DE OBSERVAÇÃO NA BASE ORIGINAL: escola.
# TIPO DE GEOMETRIA: ponto.
#
# Este download é maior que as malhas anteriores e pode demorar na primeira
# execução. showProgress = TRUE deixa a barra de progresso visível.

escolas_pr <- read_schools(
  year = 2022,
  code_muni = "PR",
  showProgress = TRUE
)

class(escolas_pr)
glimpse(escolas_pr)
nrow(escolas_pr)
table(st_geometry_type(escolas_pr))

# É importante interpretar corretamente o que será contado. O indicador
# abaixo representará o número de registros de escolas geolocalizadas que
# aparecem nessa versão da base. Ele não mede matrículas, vagas, qualidade
# escolar ou capacidade de atendimento.

# Antes de agrupar, verificamos quantas escolas não possuem código municipal.
escolas_sem_codigo <- escolas_pr %>%
  st_drop_geometry() %>%
  filter(is.na(code_muni))

nrow(escolas_sem_codigo)


# 13. Agregando escolas por município -------------------------------------
#
# ESTA É UMA MUDANÇA DE UNIDADE DE OBSERVAÇÃO:
#
#   antes:  uma linha por escola;
#   depois: uma linha por município presente na base de escolas.
#
# Excluímos da agregação somente registros sem code_muni, pois eles não podem
# ser associados com segurança à malha municipal. O número removido foi
# conferido no bloco anterior.

escolas_por_municipio <- escolas_pr %>%
  st_drop_geometry() %>%
  filter(!is.na(code_muni)) %>%
  count(
    code_muni,
    name = "numero_escolas"
  )

glimpse(escolas_por_municipio)
nrow(escolas_por_municipio)
summary(escolas_por_municipio$numero_escolas)

# Como count() agrupou por code_muni, esperamos uma linha por código.
# Ainda assim, fazemos a verificação explicitamente antes do join.
duplicatas_escolas_por_municipio <- escolas_por_municipio %>%
  count(code_muni) %>%
  filter(n > 1)

duplicatas_escolas_por_municipio


# 14. Conferindo correspondências antes do join ---------------------------
#
# anti_join() mostra municípios da malha sem correspondência na tabela de
# escolas. Não transformamos essas ausências automaticamente em zero: elas
# podem refletir ausência de registros geolocalizados ou algum problema de
# cobertura/codificação que precisa ser interpretado.

municipios_sem_escolas_na_base <- municipios_pr %>%
  st_drop_geometry() %>%
  select(code_muni, name_muni) %>%
  anti_join(
    escolas_por_municipio,
    by = "code_muni"
  )

municipios_sem_escolas_na_base
nrow(municipios_sem_escolas_na_base)

# A verificação inversa procura códigos da base de escolas que não aparecem
# na malha municipal de 2022.
codigos_escolas_sem_malha <- escolas_por_municipio %>%
  anti_join(
    municipios_pr %>%
      st_drop_geometry() %>%
      select(code_muni),
    by = "code_muni"
  )

codigos_escolas_sem_malha
nrow(codigos_escolas_sem_malha)


# 15. Join entre o indicador e a malha municipal --------------------------
#
# A relação esperada é um-para-um:
#   - uma linha por município na malha;
#   - no máximo uma linha por município na tabela agregada.
#
# relationship = "one-to-one" pede ao dplyr que gere um erro se essa relação
# não for respeitada. Isso ajuda a evitar duplicações silenciosas.

n_linhas_antes_join <- nrow(municipios_pr)

municipios_com_escolas <- municipios_pr %>%
  left_join(
    escolas_por_municipio,
    by = "code_muni",
    relationship = "one-to-one"
  )

n_linhas_depois_join <- nrow(municipios_com_escolas)

n_linhas_antes_join
n_linhas_depois_join
n_linhas_antes_join == n_linhas_depois_join

# Conferimos os valores ausentes que permaneceram após o join.
municipios_com_escolas %>%
  st_drop_geometry() %>%
  filter(is.na(numero_escolas)) %>%
  select(code_muni, name_muni, numero_escolas)


# 16. Mapa temático: escolas por município --------------------------------
#
# Agora a cor de cada polígono representa numero_escolas. Municípios sem
# correspondência aparecem em cinza, preservando a diferença entre NA e zero.

mapa_escolas_pr <- ggplot(data = municipios_com_escolas) +
  geom_sf(
    aes(fill = numero_escolas),
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    name = "Número de escolas",
    na.value = "grey80",
    labels = scales::label_number(big.mark = ".")
  ) +
  labs(
    title = "Escolas geolocalizadas por município",
    subtitle = "Paraná, 2022",
    caption = "Fonte: INEP, via pacote geobr"
  ) +
  theme_void() +
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

mapa_escolas_pr


# 17. Aproximando o mapa: escolas de Curitiba -----------------------------
#
# Como municipios_pr e escolas_pr usam code_muni, podemos filtrar as duas
# bases pelo mesmo código. Não precisamos fazer um join para apenas sobrepor
# as geometrias no gráfico.

escolas_curitiba <- escolas_pr %>%
  filter(code_muni == codigo_curitiba)

nrow(curitiba)
nrow(escolas_curitiba)

mapa_escolas_curitiba <- ggplot() +
  geom_sf(
    data = curitiba,
    fill = "#F4F1DE",
    color = "#2D3E50",
    linewidth = 0.4
  ) +
  geom_sf(
    data = escolas_curitiba,
    color = "#D1495B",
    size = 0.8,
    alpha = 0.65
  ) +
  labs(
    title = "Escolas geolocalizadas em Curitiba",
    subtitle = "Cada ponto representa um registro da base de 2022",
    caption = "Fonte: INEP, via pacote geobr"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

mapa_escolas_curitiba


# 18. Geometria simplificada ou original? --------------------------------
#
# Para várias funções de polígonos, simplified = TRUE é o padrão. A versão
# simplificada possui menos vértices e é mais rápida para baixar e desenhar.
# Ela é adequada para mapas didáticos e visualizações gerais.
#
# simplified = FALSE retorna a resolução original e deve ser considerada em
# análises espaciais que dependem de limites mais detalhados. A base será
# maior e o processamento será mais demorado.
#
# Exemplo de sintaxe (não é necessário rodar nesta aula):
#
# municipios_pr_detalhados <- read_municipality(
#   year = 2022,
#   code_muni = "PR",
#   simplified = FALSE
# )
#
# Não escolha a versão apenas pela aparência. A resolução necessária depende
# do objetivo da análise.


# 19. População e PIB: o que o geobr oferece? -----------------------------
#
# read_state() e read_municipality() NÃO incluem população ou PIB.
#
# O geobr possui read_statistical_grid(), que traz estimativas populacionais
# em células de uma grade espacial para anos específicos. A unidade é célula
# da grade, e não município. Somar ou repartir essas células entre municípios
# exige cuidados metodológicos e não deve ser confundido com o total municipal
# oficial divulgado pelo IBGE.
#
# A grade pode ser grande. Por isso, o bloco abaixo é apenas uma extensão
# opcional e não faz parte da execução principal da aula:
#
# grade_curitiba <- read_statistical_grid(
#   year = 2022,
#   code_muni = codigo_curitiba,
#   showProgress = TRUE
# )
#
# glimpse(grade_curitiba)
# table(st_geometry_type(grade_curitiba))
#
# Para obter população municipal, PIB, renda ou emprego, o procedimento mais
# comum é baixar uma tabela do IBGE/SIDRA ou de outra fonte oficial e fazer o
# join com a malha usando code_muni ou code_state.


# 20. Outras bases para explorar ------------------------------------------
#
# Consulte bases_geobr e a documentação antes de escolher ano e recorte.
# Alguns exemplos:
#
#   read_biomes()               - biomas brasileiros
#   read_census_tract()         - setores censitários
#   read_health_facilities()    - estabelecimentos de saúde
#   read_health_region()        - regiões de saúde
#   read_favela()               - favelas e comunidades urbanas
#   read_polling_places()       - locais de votação
#   read_indigenous_land()      - terras indígenas
#   read_conservation_units()   - unidades de conservação
#
# Bases de pontos podem ser agregadas por município ou estado para criar
# indicadores como número de escolas ou de estabelecimentos. Antes disso,
# sempre confira cobertura, valores ausentes e significado de cada registro.


# =============================================================================
# EXERCÍCIOS PRÁTICOS
# =============================================================================
#
# Responda escrevendo o código logo abaixo de cada pergunta, no espaço
# indicado por "# SUA RESPOSTA AQUI". Rode o código para conferir que
# funciona antes de passar ao próximo exercício.
#
# Não apague as perguntas nem o código do tutorial acima.


## Exercício 1 (Consultando as bases disponíveis) ----
# Use bases_geobr para localizar as linhas correspondentes a:
#   a) biomas;
#   b) estabelecimentos de saúde;
#   c) setores censitários.
# Mostre as funções e os anos disponíveis.

# SUA RESPOSTA AQUI


## Exercício 2 (Escolhendo uma UF) ----
# Escolha uma UF diferente do Paraná. Crie um objeto chamado uf_escolhida
# contendo a sigla em letras maiúsculas, por exemplo "BA".
#
# Depois, baixe:
#   a) o polígono do estado com read_state();
#   b) todos os seus municípios com read_municipality().
#
# Use o ano de 2022 e simplified = TRUE. Dê nomes descritivos aos objetos.

# SUA RESPOSTA AQUI


## Exercício 3 (Conferindo a estrutura) ----
# Na base municipal criada no Exercício 2:
#   a) informe o número de municípios;
#   b) confira se todos pertencem à UF escolhida;
#   c) procure duplicatas em code_muni;
#   d) consulte o CRS e o tipo de geometria.
#
# Escreva um comentário interpretando o resultado da verificação de
# duplicatas.

# SUA RESPOSTA AQUI


## Exercício 4 (Mapa municipal) ----
# Faça um mapa dos municípios da UF escolhida usando geom_sf(). Adicione:
#   a) título;
#   b) subtítulo com o ano;
#   c) fonte;
#   d) theme_void().

# SUA RESPOSTA AQUI


## Exercício 5 (Código de um município) ----
# Escolha um município da UF utilizada nos exercícios anteriores.
# Use lookup_muni() para encontrar seu código de 7 dígitos.
#
# Confira a UF do resultado antes de guardar o código em um objeto.

# SUA RESPOSTA AQUI


## Exercício 6 (Agregação e join) ----
# Baixe as escolas da UF escolhida para 2022. Em seguida:
#   a) conte quantas escolas não possuem code_muni;
#   b) exclua apenas esses registros da agregação;
#   c) conte o número de escolas por code_muni;
#   d) verifique se code_muni é único na tabela agregada;
#   e) use anti_join() para localizar municípios sem correspondência;
#   f) faça um left_join() com a malha municipal;
#   g) confira o número de linhas antes e depois do join.
#
# Lembre-se: a unidade muda de escola para município durante a agregação.

# SUA RESPOSTA AQUI


## Exercício 7 (Mapa temático) ----
# Usando a base final do Exercício 6, faça um mapa do número de escolas por
# município. Municípios com NA devem aparecer em cinza.
#
# Em um comentário, explique por que NA não foi automaticamente substituído
# por zero.

# SUA RESPOSTA AQUI


## Exercício 8 - opcional (Explorando outra base) ----
# Escolha UMA das funções abaixo e consulte sua documentação com ?:
#
#   read_biomes
#   read_health_facilities
#   read_favela
#   read_polling_places
#
# Identifique:
#   a) a unidade de observação;
#   b) o tipo de geometria;
#   c) os anos disponíveis;
#   d) uma pergunta econômica ou de política pública que poderia ser
#      estudada com essa base.
#
# Não é obrigatório baixar bases grandes neste exercício.

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
