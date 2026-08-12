# =============================================================================
# TUTORIAL 01 - INTRODUÇÃO AO R
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
# 2. Leia os comentários (linhas que começam com #) antes de rodar o
#    código: eles explicam o que a linha seguinte faz e por quê.
# 3. Use o painel "Outline" do Posit Cloud (ícone de lista no
#    canto superior direito do editor) para navegar entre as seções -
#    todas as seções abaixo terminam em "----" e aparecem no índice.
# 4. Ao final do tutorial há uma seção "EXERCÍCIOS PRÁTICOS". É lá que
#    você deve responder, escrevendo seu código logo abaixo de cada
#    pergunta, no espaço indicado por "# SUA RESPOSTA AQUI".
# 5. Quando terminar, siga as instruções da última seção do script
#    para compartilhar o projeto comigo pelo Posit Cloud.
#
# Material adaptado, com fins didáticos, a partir do curso "Introdução
# ao R" do NEDUR/UFPR (Prof. Vinicius A. Vale, Tania M. Alberti e
# Davi W. Catelan - http://nedur.ufpr.br/cursos/), reorganizado e
# expandido para a disciplina Economia no Quarto.
#
# =============================================================================


# 0. Fonte / Material de referência ----------------------------------------
#
# Este tutorial é uma adaptação, com fins didáticos, do script original
# "Introdução ao R" do curso do NEDUR (Núcleo de Estudos em
# Desenvolvimento Urbano e Regional) da UFPR:
#
#   https://github.com/davicatelan/introducao-R-nedur-ufpr/blob/main/intro-R.R
#
# Autores do material original: Prof. Vinicius A. Vale, Tania M.
# Alberti e Davi W. Catelan. Consulte o repositório acima para o
# script original e outros materiais do curso.


# 1. O que são R e RStudio/Posit Cloud? ----------------------------------
#
# R é uma linguagem de programação voltada para análise estatística e
# visualização de dados. É gratuita, de código aberto, e é o padrão em
# muitas áreas de pesquisa em Economia, especialmente em microeconometria
# aplicada e análise de dados públicos.
#
# RStudio é um "IDE" (ambiente de desenvolvimento integrado): um programa
# que deixa mais fácil escrever, rodar e organizar código R, com editor
# de script, console, visualizador de gráficos e navegador de arquivos
# na mesma tela.
#
# Posit Cloud (antigo RStudio Cloud) é uma versão do RStudio que roda
# no navegador, sem precisar instalar nada no seu computador. É o que
# usaremos neste curso: cada projeto do Posit Cloud já vem com seu
# próprio diretório de trabalho, então normalmente você NÃO precisa
# usar setwd() como em uma instalação local do R.


# 2. Primeiros passos --------------------------------------------------
#
# Ver o diretório de trabalho atual (no Posit Cloud, já é a pasta do
# projeto):
getwd()

# Limpar o Environment (painel superior direito, com a lista de objetos)
# é uma boa prática no início de um script, para garantir que você não
# está usando, sem perceber, algum objeto de uma sessão anterior:
rm(list = ls())


# 3. Pacotes (packages) --------------------------------------------------
#
# R vem com um conjunto de funções "base", mas grande parte do seu poder
# vem de pacotes (packages): coleções de funções extras, mantidas pela
# comunidade e distribuídas pelo CRAN (Comprehensive R Archive Network).
#
# install.packages() baixa e instala o pacote (só precisa ser feito UMA
# vez por projeto). library() carrega o pacote na sessão atual (precisa
# ser feito toda vez que você abre o projeto e vai usar aquele pacote).
#
# Vamos instalar de uma vez só os pacotes que usaremos neste tutorial.
# No Posit Cloud isso pode levar alguns minutos na primeira vez -
# é normal, pode aproveitar para ler o restante do tutorial enquanto
# espera. Se a instalação travar, vá em Session > Restart R e tente de
# novo.

install.packages("tidyverse") # inclui ggplot2, dplyr, tidyr, readr, tibble
install.packages("wooldridge") # bases de dados clássicas de Econometria

library(tidyverse)
library(wooldridge)


# 4. Pedindo ajuda --------------------------------------------------------
#
# Toda função do R tem uma página de ajuda. Use "?" antes do nome da
# função (ou do pacote) para abrir a documentação no painel "Help":

?"sum"
?"mean"

# example() roda os exemplos que estão na própria documentação:
example(sum)


# 5. Operadores básicos ---------------------------------------------------

## 5.1 Operadores aritméticos ----
?"Arithmetic"
2 + 2   # soma
4 - 2   # subtração
3 * 2   # multiplicação
4 / 2   # divisão
4 ^ 2   # potência
5 %/% 2 # divisão inteira (quociente)
5 %% 2  # resto da divisão (módulo)

## 5.2 Operadores lógicos ----
#
# Comparações sempre retornam TRUE (verdadeiro) ou FALSE (falso).
?"Logic"
5 == 5  # é igual a?
5 == 4
5 >  4  # é maior que?
5 >= 5  # é maior ou igual a?
6 <  5  # é menor que?
5 <= 5  # é menor ou igual a?


# 6. Variáveis (objetos) --------------------------------------------------
#
# Para guardar um valor em um "objeto" (variável), usamos o operador de
# atribuição "<-" (atalho: Alt + -). Também é possível usar "=", mas
# "<-" é a convenção da comunidade R e a que usaremos no curso.

x <- 5
y <- x + 1
y          # ver o conteúdo de y
z <- 2 * x
z

# rm() remove um objeto específico do Environment:
rm(y)

# rm(list = ls()) remove TODOS os objetos:
rm(list = ls())


# 7. Vetores ----------------------------------------------------------------
#
# Um vetor é uma sequência de valores do MESMO tipo (todos números, ou
# todos texto, ou todos lógicos). É a estrutura de dados mais básica do R.

## 7.1 Criando vetores ----
x <- c(1, 5, 6)          # c() = "combine": junta valores em um vetor
x
class(x)                 # tipo do vetor: "numeric"

y <- c("Curitiba", "Sao Paulo", "Rio de Janeiro")
class(y)                 # "character" (texto)

v <- c(TRUE, FALSE, TRUE)
class(v)                 # "logical"

# Quando você mistura tipos, o R converte tudo para o tipo "mais geral"
# (regra de coerção): aqui, TRUE e 10 viram texto, porque há texto no
# vetor:
g <- c("Economia", TRUE, 10)
g
class(g)                 # "character" - repare que virou tudo texto!

# Sequências:
r <- 1:5
r
q <- seq(2, 4, by = 0.5)      # de 2 a 4, de 0.5 em 0.5
q
seq(0, 1, length = 5)         # 5 números igualmente espaçados entre 0 e 1

# Repetições:
w <- rep(5, times = 3)        # repete o número 5, três vezes
w
rep(1:2, times = 3)           # repete a sequência 1,2 três vezes
rep(1:2, each = 3)            # repete cada elemento 3 vezes seguidas

rm(list = ls())

## 7.2 Indexação (acessando posições de um vetor) ----
g <- c(10, 20, 30, 40, 50)
g[3]        # terceiro elemento
g[2:4]      # do segundo ao quarto elemento
g[-3]       # todos, MENOS o terceiro
g[c(1, 5)]  # primeiro e quinto elementos

# Indexação lógica: retorna os elementos que satisfazem uma condição
v <- c(1, 2, 2, 4, 5)
v[v == 2]      # elementos iguais a 2
v[v < 4]       # elementos menores que 4
v[v %in% c(1, 2)] # elementos que estão dentro do conjunto {1, 2}

rm(list = ls())

## 7.3 Operações com vetores ----
#
# As operações são feitas "elemento a elemento":
k <- c(2, 4, 6, 8, 10)
k * 2
k + 1

# Se dois vetores têm o mesmo tamanho, a operação também é elemento a
# elemento entre eles:
s <- c(1, 2, 3, 4, 5)
b <- k + s
b
b >= 9          # quais posições de b são >= 9?
b[b >= 9]       # quais VALORES de b são >= 9?
which(b >= 9)   # em quais POSIÇÕES isso acontece?

rm(list = ls())

## 7.4 Funções úteis com vetores ----
x <- c(2, 4, 6, 8, 10)
sum(x)       # soma
mean(x)      # média
median(x)    # mediana
sd(x)        # desvio-padrão
range(x)     # mínimo e máximo
summary(x)   # resumo estatístico completo

g <- c(5, 2, 2, 1, 10)
sort(g)                    # ordena, do menor para o maior
sort(g, decreasing = TRUE) # do maior para o menor
table(g)                   # conta quantas vezes cada valor aparece
unique(g)                  # valores únicos, sem repetição
length(g)                  # quantos elementos tem o vetor

rm(list = ls())


# 8. Matrizes ---------------------------------------------------------------
#
# Uma matriz é uma tabela retangular de números, organizada em linhas e
# colunas - útil, por exemplo, para representar sistemas de equações ou
# fazer álgebra linear (como em modelos de insumo-produto).

## 8.1 Criando matrizes ----
C <- matrix(seq(1, 100), ncol = 10, nrow = 10)
C

# byrow = TRUE preenche a matriz por linha, em vez de por coluna:
L <- matrix(seq(1, 100), ncol = 10, nrow = 10, byrow = TRUE)
L

# cbind() e rbind() juntam vetores como colunas ou linhas:
X <- cbind(c(-1, 4), c(3, 2))
X
Y <- rbind(c(-1, 4), c(3, 2))
Y

## 8.2 Indexação de matrizes ----
C[1, 2]     # elemento da linha 1, coluna 2
C[3, ]      # linha 3 inteira
C[, 1]      # coluna 1 inteira
C[2:4, ]    # linhas 2 a 4

## 8.3 Operações com matrizes ----
C * 10
C[C >= 50]  # todos os elementos maiores ou iguais a 50 (vira vetor)

## 8.4 Outras funções e álgebra linear ----
sum(C); mean(C); t(C)          # soma, média e transposta
rowSums(C); colSums(C)         # soma por linha / por coluna
rowMeans(C); colMeans(C)       # média por linha / por coluna

X <- cbind(c(-1, 4), c(3, 2))
Y <- cbind(c(1, 3), c(2, 4))
X + Y
X %*% Y      # multiplicação matricial (diferente de X * Y!)
diag(2)      # matriz identidade 2x2
solve(Y)     # matriz inversa de Y

rm(list = ls())


# 9. Data frames e tibbles ---------------------------------------------------
#
# Um data frame é uma tabela como as de uma planilha: cada COLUNA pode
# ter um tipo diferente (números, texto, datas...), mas todas as
# colunas têm o mesmo número de linhas. É a estrutura mais usada para
# trabalhar com bases de dados reais.
#
# tibble é uma versão "moderna" do data frame, usada pelo tidyverse, com
# impressão mais organizada e alguns comportamentos mais previsíveis.
#
# Vamos usar a base wage1, do pacote wooldridge - uma base clássica de
# Economia do Trabalho, com salário (wage), anos de educação (educ),
# experiência (exper) e outras variáveis de uma amostra de
# trabalhadores.

data("wage1")
str(wage1)     # estrutura da base: variáveis, tipos, primeiras linhas
?"wage1"       # descrição de cada variável (documentação da base)

wage1tib <- as_tibble(wage1)
wage1tib

## 9.1 Manipulando data frames (R "base") ----
wage1[2, 3]                    # linha 2, coluna 3
wage1[, c("wage", "educ")]     # só as colunas wage e educ
wage1$educ                     # coluna educ, como vetor
subset(wage1, wage > 10)       # só as linhas com salário > 10
summary(wage1$wage)
head(wage1)                    # 6 primeiras linhas
tail(wage1)                    # 6 últimas linhas

## 9.2 Criando/transformando variáveis ----
wage1$wage_mensal <- wage1$wage * 4.33 # de salário/hora para salário/mês aprox.

rm(list = ls())


# 10. Manipulação de dados com dplyr (e o operador pipe %>%) ------------------
#
# O pacote dplyr (parte do tidyverse) tem "verbos" para manipular
# tabelas de forma mais legível que a sintaxe base do R:
#   select()   - escolhe colunas
#   rename()   - renomeia colunas
#   mutate()   - cria/transforma colunas
#   filter()   - filtra linhas por condição
#   group_by() - agrupa linhas (ex.: por categoria)
#   summarise()- resume um grupo (ex.: média, soma)
#
# O operador pipe %>% (ou o nativo |>) lê-se "e depois": ele pega o
# resultado de uma linha e "encaminha" para a próxima função, evitando
# ter que aninhar várias funções uma dentro da outra.

data("wage1")

# Vamos criar faixas de escolaridade, para ter uma variável categórica
# para agrupar (assim como o tutorial original agrupava exportações por
# UF):
wage1 <- wage1 %>%
  mutate(fx_educ = cut(educ,
                        breaks = c(-Inf, 8, 12, Inf),
                        labels = c("Fundamental", "Medio", "Superior")))

# Exemplo de "cadeia" de manipulação com pipe:
resumo_wage <- wage1 %>%
  select(wage, educ, exper, fx_educ) %>%   # mantém só as colunas de interesse
  rename(salario = wage,                   # renomeia para português
         educacao = educ,
         experiencia = exper) %>%
  mutate(log_salario = log(salario)) %>%   # cria nova coluna: log do salário
  group_by(fx_educ) %>%                    # agrupa por faixa de escolaridade
  summarise(salario_medio = mean(salario), # resume cada grupo
            n_trabalhadores = n())

resumo_wage

# Sem pipe, o mesmo resultado exigiria funções aninhadas, bem menos
# legível:
# summarise(group_by(mutate(rename(select(wage1, wage, educ, exper,
#   fx_educ), salario = wage, educacao = educ, experiencia = exper),
#   log_salario = log(salario)), fx_educ), salario_medio = mean(salario))


# 11. Importação e exportação de dados ----------------------------------------
#
# Na prática, você quase sempre vai importar dados de um arquivo (CSV,
# Excel...) em vez de digitá-los à mão. Abaixo, criamos um CSV a partir
# do resumo_wage só para praticar a exportação e a importação - no seu
# dia a dia, o arquivo já vai existir (baixado do IBGE, IPEA, etc.) e
# você vai direto para o read_csv()/read_excel().

## 11.1 Exportando para CSV ----
write_csv(resumo_wage, "resumo_wage_educacao.csv")

## 11.2 Importando de CSV ----
resumo_importado <- read_csv("resumo_wage_educacao.csv")
resumo_importado

# Dica: se o seu arquivo usar ";" como separador (comum em CSVs
# exportados do Excel em português), use read_csv2() ou
# read_delim(..., delim = ";") em vez de read_csv().

## 11.3 Salvando/lendo objetos do R (formato .rds, mantém classes/tipos) ----
saveRDS(resumo_wage, "resumo_wage_educacao.rds")
resumo_wage2 <- readRDS("resumo_wage_educacao.rds")

## 11.4 Importando Excel (.xlsx) ----
# Se você tiver um arquivo Excel no seu projeto, a função é:
#   library(readxl)
#   dados <- read_excel("nome_do_arquivo.xlsx", sheet = "Planilha1")
# (não vamos rodar isso agora porque não temos um .xlsx no projeto)


# 12. Gráficos com ggplot2 -----------------------------------------------------
#
# ggplot2 constrói gráficos "em camadas": primeiro você diz QUAIS dados
# e QUAIS variáveis usar (aes = "aesthetic mappings"), depois soma (+)
# camadas de geometria (geom_*), rótulos, temas, etc.

ggplot(data = resumo_wage, aes(x = fx_educ, y = salario_medio)) +
  geom_col(fill = "steelblue")

# O mesmo gráfico, mais "arrumado":
ggplot(data = resumo_wage, aes(x = fx_educ, y = salario_medio)) +
  geom_col(fill = "steelblue") +
  theme_minimal() +
  xlab("Faixa de escolaridade") +
  ylab("Salário médio (US$/hora)") +
  ggtitle("Salário médio por escolaridade") +
  labs(subtitle = "Base wage1 (Wooldridge)") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

# Gráfico de dispersão (scatter plot), usando a base completa wage1:
ggplot(data = wage1, aes(x = educ, y = wage)) +
  geom_point(color = "darkorange", alpha = 0.6) +
  theme_minimal() +
  xlab("Anos de educação") +
  ylab("Salário (US$/hora)") +
  ggtitle("Relação entre educação e salário")


# =============================================================================
# EXERCÍCIOS PRÁTICOS
# =============================================================================
#
# Responda escrevendo o código logo abaixo de cada pergunta, no espaço
# indicado por "# SUA RESPOSTA AQUI". Rode o código para conferir que
# funciona antes de passar para o próximo exercício. Não apague as
# perguntas nem o código do tutorial acima - eu vou avaliar o arquivo
# inteiro.
#
# Ao terminar, siga as instruções da seção "COMO ME ENVIAR" ao final
# deste arquivo.


## Exercício 1 (Operadores e variáveis) ----
# Crie duas variáveis, nota1 e nota2, com os valores 7.5 e 8.3.
# Calcule a média das duas notas e guarde em uma variável chamada
# media_final. Depois, verifique (com um operador lógico) se
# media_final é maior ou igual a 6 (nota mínima de aprovação).

# SUA RESPOSTA AQUI


## Exercício 2 (Vetores) ----
# Crie um vetor chamado pib_estados com o PIB (em bilhões de R$, use
# valores fictícios) de 5 estados brasileiros à sua escolha. Em
# seguida:
#   a) ordene o vetor do maior para o menor PIB;
#   b) use indexação lógica para selecionar apenas os estados cujo
#      PIB é maior que a média do vetor.

# SUA RESPOSTA AQUI


## Exercício 3 (Matrizes) ----
# Crie uma matriz 3x3 chamada gastos, representando os gastos mensais
# (linhas = 3 meses, colunas = 3 categorias: alimentação, transporte,
# lazer) de uma família fictícia. Calcule:
#   a) o total gasto em cada categoria (dica: colSums);
#   b) o total gasto em cada mês (dica: rowSums).

# SUA RESPOSTA AQUI


## Exercício 4 (Data frames / tibbles) ----
# Usando a base wage1 (já carregada no tutorial acima), calcule o
# salário médio (wage) somente das pessoas com mais de 12 anos de
# educação (educ). Use subset() OU filter() do dplyr - escolha um dos
# dois métodos.

# SUA RESPOSTA AQUI


## Exercício 5 (dplyr e pipe) ----
# A partir da base wage1, usando o operador %>%, crie um novo objeto
# chamado wage1_exp contendo:
#   a) apenas as colunas wage, educ e exper;
#   b) renomeadas para salario, educacao e experiencia;
#   c) com uma nova coluna log_salario = log(salario);
#   d) mostrando só as 6 primeiras linhas do resultado final (dica:
#      você pode terminar a cadeia de pipes com head()).

# SUA RESPOSTA AQUI


## Exercício 6 (Gráficos) ----
# Usando o objeto wage1_exp criado no Exercício 5 (sem o head(), ou
# refaça sem o head para ter a base completa), construa um gráfico de
# dispersão (geom_point) com experiencia no eixo x e salario no eixo
# y. Adicione título e nomes de eixo em português.

# SUA RESPOSTA AQUI


# =============================================================================
# COMO ME ENVIAR - Compartilhando o projeto pelo Posit Cloud
# =============================================================================
#
# 1. Renomeie o projeto (canto superior esquerdo, ao lado do logo do
#    Posit Cloud, clique no nome do projeto) para:
#       SeuNome_SeuSobrenome - Tutorial 01
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
# Pronto! Não precisa me enviar nada por e-mail - eu vou acessar o
# projeto compartilhado diretamente pelo Posit Cloud.
#
# =============================================================================
