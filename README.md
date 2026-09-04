# R para Economia

Tutoriais passo a passo de R para a disciplina de Ciência de Dados em
Economia. Cada pasta numerada é um tutorial independente, com um script
`.R` comentado que combina **explicação + código + exercícios práticos**.

## Tutoriais disponíveis

| # | Pasta | Conteúdo |
|---|-------|----------|
| 01 | [`01_introducao_ao_R/`](01_introducao_ao_R/01_introducao_ao_R.R) | R e RStudio/Posit Cloud, pacotes, operadores, vetores, matrizes, data frames/tibbles, dplyr e pipe, importação/exportação de dados, gráficos com ggplot2 |
| 02 | [`02_sidra/`](02_sidra/02_sidra.R) | Dados do SIDRA/IBGE com o pacote sidrar, consulta e metadados de tabelas, seleção e renomeação de colunas, verificação de duplicatas e valores ausentes, estatísticas descritivas, rankings e filtros com dplyr |
| 03 | [`03_importar_exportar/`](03_importar_exportar/03_importar_exportar.R) | Diretório de trabalho e caminhos relativos, leitura de CSV com separador `;` e decimal com vírgula, encoding e tipos de coluna, unidade de observação, verificação de chave e de valores ausentes, leitura e escrita de Excel com readxl/writexl, estatísticas descritivas e exportação em várias abas |
| 04 | [`04_geobr/`](04_geobr/04_geobr.R) | Dados espaciais oficiais do Brasil com geobr, objetos sf, estados, municípios, sedes municipais, escolas, mapas temáticos, agregações e joins geográficos |

Novos tutoriais serão adicionados a este repositório ao longo do curso.

## Antes de começar: instalação

Quem for rodar os tutoriais no próprio computador precisa instalar R,
RStudio e Git. O passo a passo está em
[`tutorial_instalacao_r_posit_git.pdf`](tutorial_instalacao_r_posit_git.pdf).

Quem for usar o Posit Cloud não precisa instalar nada: siga direto para
a seção abaixo.

## Como abrir um tutorial no Posit Cloud (passo a passo para alunos)

1. Crie uma conta gratuita em [posit.cloud](https://posit.cloud) (se
   ainda não tiver uma).
2. Dentro do seu workspace, clique em **New Project** (canto superior
   direito) e depois em **New Project from Git Repository**.
3. Cole a URL deste repositório:
   `https://github.com/Economianoquarto/R-para-economia`
4. Aguarde o Posit Cloud clonar o repositório e criar o projeto. Isso
   cria uma **cópia própria** do projeto na sua conta — você pode
   editar, rodar e salvar à vontade, sem afetar o repositório original.
5. No painel "Files" (canto inferior direito), abra a pasta do
   tutorial (ex.: `01_introducao_ao_R/`) e clique no arquivo `.R` para
   abri-lo no editor.
6. Siga as instruções no topo do próprio script: rode o código
   linha a linha (ou bloco a bloco) com `Ctrl+Enter`, leia os
   comentários, e responda aos exercícios na seção
   **EXERCÍCIOS PRÁTICOS**, ao final do arquivo.

## Como me enviar sua resolução

Depois de responder aos exercícios, **não é necessário enviar nada por
e-mail ou baixar arquivos** — compartilhe o projeto comigo direto pelo
Posit Cloud:

1. Renomeie o projeto para `SeuNome_SeuSobrenome - Tutorial XX`, trocando
   `XX` pelo número do tutorial resolvido (clique no nome do projeto, no
   canto superior esquerdo da tela).
2. Salve o script (`Ctrl+S`).
3. Clique em **Share**, no canto superior direito da tela do projeto.
4. Convide o e-mail **economianoquarto@gmail.com** como colaborador
   (permissão de "Viewer" já é suficiente).
5. Clique em **Apply**.

Essas instruções também estão repetidas ao final de cada script de
tutorial.

## Fontes dos dados

O tutorial `03_importar_exportar` usa a Série Histórica de Preços de
Combustíveis da [ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos),
referente ao 1º semestre de 2026. O arquivo original cobre o Brasil inteiro
(422.418 linhas, 72 MB); o que está no repositório é o recorte do município
de Teresina/PI (2.308 linhas), mantido no formato original da ANP — separador
`;`, decimal com vírgula e datas em `dd/mm/aaaa` —, que é justamente o que o
tutorial ensina a importar.

## Créditos

O primeiro tutorial (`01_introducao_ao_R`) foi adaptado, com fins
didáticos, a partir do material *"Introdução ao R"* do NEDUR/UFPR
(Prof. Vinicius A. Vale, Tania M. Alberti e Davi W. Catelan —
[nedur.ufpr.br/cursos](http://nedur.ufpr.br/cursos/)), reorganizado e
expandido para esta disciplina. Script original disponível em:
[github.com/davicatelan/introducao-R-nedur-ufpr](https://github.com/davicatelan/introducao-R-nedur-ufpr/blob/main/intro-R.R).
