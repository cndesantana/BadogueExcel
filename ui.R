library(shiny)

ui <- fluidPage(

  # App title ----
  titlePanel("Badogue's FB data download"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

         textInput("urlpost", 
                   "Escreva a URL do post que deseja analisar:", 
                   value = "http://..."
         ),
         # textInput("fbid", 
         #           "Escreva o ID da página do Facebook onde foi publicado esse post:", 
         #           value = "acesse http://findmyfbid.com/ para obter o ID..."
         # ),
         dateInput('date',
                   label = 'Selecione a data para a qual deseja analisar o post:',
                   value = Sys.Date()
         ),

      # Input: Choose dataset ----
#      selectInput("dataset", "Choose a dataset:",
#                  choices = c("rock", "pressure", "cars")),

      # Button
   tags$hr("Excel",br()),
      downloadButton("downloadExcelData", "Download Excel"),
   tags$hr("Reações e Palavras gerais",br()),
      downloadButton("downloadReactionsData", "Download Reações"),
      downloadButton("downloadPalavrasData", "Download Lista de Palavras"),
      downloadButton("downloadWordcloudData", "Download Nuvem de Palavras"),
   tags$hr("Usuários Participativos",br()),
      downloadButton("downloadUsuariosMaisParticipativos", "Download Lista de usuários que mais comentam"),
      downloadButton("downloadUsuariosMaisCurtidos", "Download Lista de usuários mais curtidos"),
      downloadButton("downloadPalavrasUsuariosMaisParticipativos", "Download Lista palavras usadas por usuários que mais comentam"),
   tags$hr("Usando Reações",br()),
      downloadButton("downloadPalavrasUsuariosAngry", "Download Lista de palavras usadas por usuários que reagem com ANGRY"),
   tags$hr(br()),
      downloadButton("downloadPalavrasUsuariosSad", "Download Lista de palavras usadas por usuários que reagem com SAD"),
   tags$hr(br()),
      downloadButton("downloadPalavrasUsuariosLove", "Download Lista de palavras usadas por usuários que reagem com LOVE"),
   tags$hr(br()),
      downloadButton("downloadPalavrasUsuariosHaha", "Download Lista de palavras usadas por usuários que reagem com HAHA"),
   tags$hr("Comparando Performance",br()),
   downloadButton("downloadComparacaoComentarios", "Download Comparação entre post e posts mais comentados nos últimos 7 dias")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

#      tableOutput("table")

    )

  )
)
