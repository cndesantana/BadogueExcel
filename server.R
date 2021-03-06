library(stringr)
library(quanteda)
library(readtext)
library(ggplot2)
library(tidyr)
library(shinydashboard)
library(shiny)
library(shinyFiles)
library(devtools)
library(Rfacebook)
library(lubridate)
library(dplyr)
library(stylo)
library(tidytext)
library(tm)
library(wordcloud)
library(xlsx)
library(gdata)
library(readxl)
library(htmlwidgets)
library(httr)

getFBID <- function(fburl){
   return(unlist(strsplit(httr::POST(url='https://findmyfbid.com',body=list(url = fburl), encode="json")$headers$`amp-redirect-to`,'/'))[5])
   }

getIndiceDeSentimentoReactions <- function(reactions){
   reacoes <- toupper(reactions)
   allreacoes <- c("LOVE","HAHA","ANGRY","SAD");
   ml <- length(which(sentimentos==allsentimentos[1]));#Positivo
   mh <- length(which(sentimentos==allsentimentos[2]));#Positivo
   ma <- length(which(sentimentos==allsentimentos[3]));#Negativo
   ms <- length(which(sentimentos==allsentimentos[4]));#Negativo
   mt <- ml + mh + ma + ms;#Total
   
   indicesentimento <- as.numeric((ml + mh - ma - ms)/mt)
   
   return(indicesentimento)
}

#workdir <- "/srv/shiny-server/cns/BadogueExcel"
#workdir <- "/home/cdesantana/DataSCOUT/Objectiva/BadogueExcel"
workdir <- system("cat myworkdir",intern=TRUE)
badwords <- c("scontent.xx.fbcdn.net","https","oh","oe","pra"," v ","como","para","de","do","da","das","dos","isso","esse","nisso","nesse","aquele","nesses","aqueles","aquela","aquelas","que","q","é","sr","governador","rui","costa","senhor")

getTidySentimentos <- function(file){
   polaridade <- toupper(file$Polaridade)
   text <- file$Conteúdo
   myCorpus <- corpus(text)
   metadoc(myCorpus, "language") <- "portuguese"
   tokenInfo <- summary(myCorpus)
   kwic(myCorpus, "gestor")
   myStemMat <- dfm(myCorpus, remove = stopwords("portuguese"), stem = TRUE, remove_punct = TRUE)
   byPolaridadeDfm <- dfm(myCorpus, groups = polaridade, remove = c(stopwords("portuguese"),badwords), remove_punct = TRUE)
   ap_td <- tidy(byPolaridadeDfm)
   names(ap_td) <- c("sentimento","term","count")
   return(ap_td);
}

getDFMatrix <- function(text){
   myCorpus <- corpus(text)
   metadoc(myCorpus, "language") <- "portuguese"
   tokenInfo <- summary(myCorpus)
   kwic(myCorpus, "gestor")
   myStemMat <- dfm(myCorpus, remove = stopwords("portuguese"), stem = TRUE, remove_punct = TRUE)
   mydfm <- dfm(myCorpus, remove = c(stopwords("portuguese"),badwords), remove_punct = TRUE, remove_numbers= TRUE)
   return(mydfm)
#   ap_td <- tidy(mydfm)
#   names(ap_td) <- c("sentimento","term","count")
#   return(ap_td);
}

options(shiny.fullstacktrace = TRUE)

server <- function(input, output) {
   
   plotIndiceSentimentoReacoes = function(){
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-3);
      data_final <- ymd(as.character(data)) + days(3);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final), reactions = TRUE)
      nposts <- length(mypage$link)
      pos_post <- which(as.character(mypage$link)%in%url)
      total_reactions <- (mypage$love_count + mypage$haha_count + mypage$sad_count + mypage$angry_count);
      comments_count <- (mypage$love_count + mypage$haha_count - mypage$sad_count - mypage$angry_count)/total_reactions
      
      ggplot() +
         geom_bar(stat = "identity",
                  aes(x = reorder(1:nposts,as.numeric(comments_count)), 
                      y = as.numeric(comments_count)),
                  fill = ifelse(levels(reorder(1:nposts,as.numeric(comments_count)))==pos_post,"green","grey50")) +
         theme(axis.text.x=element_blank(),
               axis.ticks.x=element_blank()) +
         ylab("Índice de Sentimento") +
         xlab("Posts") +
         geom_text( aes (x = reorder(1:nposts,as.numeric(comments_count)), y = round(as.numeric(comments_count),2), label = round(as.numeric(comments_count),2) ) , vjust = 0, hjust = 0, size = 2 )
      
   }

   plotComparacaoComentarios = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-3);
      data_final <- ymd(as.character(data)) + days(3);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final), reactions = TRUE)
      nposts <- length(mypage$link)
      pos_post <- which(as.character(mypage$link)%in%url)
      comments_count <- mypage$comments_count
      
      ggplot() +
         geom_bar(stat = "identity",aes(x = reorder(1:nposts,as.numeric(comments_count)), 
                                        y = as.numeric(comments_count)),
                  fill = ifelse(levels(reorder(1:nposts,as.numeric(comments_count)))==pos_post,"green","gray50")) +
         theme(axis.text.x=element_blank(),
               axis.ticks.x=element_blank()) +
         ylab("Numero de comentários") +
         xlab("Posts") +
         geom_text( aes (x = reorder(1:nposts,as.numeric(comments_count)), y = as.numeric(comments_count), label = as.numeric(comments_count) ) , vjust = 0, hjust = 0, size = 2 )

   }
   
   plotPalavrasUsuariosAngry = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
      
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)
         
      ids_reaction <- post_dados$reactions %>% 
         filter(from_type == "ANGRY") %>%
         select(from_id)
      
      if(length(ids_reaction$from_id) > 0){
         text <- post_dados$comments %>%
            filter(as.character(from_id) %in% ids_reaction$from_id) %>%
            dplyr::select(message)
         
         mydfm <- getDFMatrix(text$message);
         words_td <- topfeatures(mydfm, 50)
         ggplot() +
            geom_bar(stat = "identity",
                     aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                     fill = "magenta") +
            ylab("Numero de ocorrencias") +
            xlab("") +
            geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) +
            coord_flip()
      }
      else{
         ggplot()
      }
   }
   
   plotPalavrasUsuariosSad = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
      
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)
      
      ids_reaction <- post_dados$reactions %>% 
         filter(from_type == "SAD") %>%
         select(from_id)
      
      if(length(ids_reaction$from_id) > 0){
         text <- post_dados$comments %>%
            filter(as.character(from_id) %in% ids_reaction$from_id) %>%
            dplyr::select(message)
         
         mydfm <- getDFMatrix(text$message);
         words_td <- topfeatures(mydfm, 50)
         
         ggplot() +
            geom_bar(stat = "identity",
                     aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                     fill = "magenta") +
            ylab("Numero de ocorrencias") +
            xlab("") +
            geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) +
            coord_flip()
      }else{
         ggplot()
      }
   }
   
   plotPalavrasUsuariosLove = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
      
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)
      
      ids_reaction <- post_dados$reactions %>% 
         filter(from_type == "LOVE") %>%
         select(from_id)
      
      if(length(ids_reaction$from_id) > 0){
         text <- post_dados$comments %>%
            filter(as.character(from_id) %in% ids_reaction$from_id) %>%
            dplyr::select(message)
         
         mydfm <- getDFMatrix(text$message);
         words_td <- topfeatures(mydfm, 50)
         ggplot() +
            geom_bar(stat = "identity",
                     aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                     fill = "magenta") +
            ylab("Numero de ocorrencias") +
            xlab("") +
            geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) +
            coord_flip()
      }else{
         ggplot()
      }
   }
   
   plotPalavrasUsuariosHaha = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
      
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)
      
      ids_reaction <- post_dados$reactions %>% 
         filter(from_type == "HAHA") %>%
         select(from_id)
      
      if(length(ids_reaction$from_id) > 0){
         text <- post_dados$comments %>%
            filter(as.character(from_id) %in% ids_reaction$from_id) %>%
            dplyr::select(message)
         
         mydfm <- getDFMatrix(text$message);
         words_td <- topfeatures(mydfm, 50)
         ggplot() +
            geom_bar(stat = "identity",
                     aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                     fill = "magenta") +
            ylab("Numero de ocorrencias") +
            xlab("") +
            geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) +
            coord_flip()
      }else{
         ggplot()
      }
   }
   
   
   plotPalavrasUsuariosMaisParticipativos = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
   
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)
 
      autores <- post_dados$comments %>% 
         dplyr::select(from_name) %>%
         group_by(from_name) %>% 
         arrange(from_name) %>%
         summarise(total = sum(n())) %>%
         arrange(total) %>%
         tail(50) %>%
         dplyr::select(from_name)
 
      text <- post_dados$comments %>%
         filter(as.character(from_name) %in% autores$from_name) %>%
         dplyr::select(message)
 
      mydfm <- getDFMatrix(text$message);
      words_td <- topfeatures(mydfm, 50)
      ggplot() +
         geom_bar(stat = "identity",
                        aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                        fill = "magenta") +
         ylab("Numero de ocorrencias") +
         xlab("") +
         geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) +
         coord_flip()
   }

   plotUsuariosMaisParticipativos = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
   
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)

      post_dados$comments %>% 
         dplyr::select(from_name) %>%
         group_by(from_name) %>% 
         arrange(from_name) %>%
         summarise(total = sum(n())) %>%
         arrange(total) %>%
         tail(50) %>%
         ggplot() + 
         geom_bar(stat = "identity", 
                  aes(x = reorder(from_name,as.numeric(total)), y = as.numeric(total))
         ) + 
         ylab("Numero de Comentários") +
         xlab("") +
         geom_text( aes (x = reorder(from_name,as.numeric(total)), y = as.numeric(total), label = as.numeric(total) ) , vjust = 0, hjust = 0, size = 2 ) + 
         coord_flip()
   }


   plotUsuariosMaisCurtidos = function() {
      url <- input$urlpost
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
   
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000, reactions=TRUE)

      post_dados$comments %>% 
         dplyr::select(from_name,likes_count) %>%
         group_by(from_name) %>% 
         arrange(from_name, likes_count) %>%
         summarise(total = sum(as.numeric(likes_count))) %>%
         arrange(total) %>%
         filter(total >= 1) %>%
         tail(50) %>%
         ggplot() + 
         geom_bar(stat = "identity", 
                  aes(x = reorder(from_name,as.numeric(total)), y = as.numeric(total))
         ) + 
         ylab("Numero de Curtidas") +
         xlab("") +
         geom_text( aes (x = reorder(from_name,as.numeric(total)), y = as.numeric(total), label = as.numeric(total) ) , vjust = 0, hjust = 0, size = 2 ) + 
         coord_flip()
   }



  plotPalavras = function() {
      url <- input$urlpost
#      id_pagina <- input$fbid 
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
   
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000)
      text <- post_dados$comments$message
      mydfm <- getDFMatrix(text);
      words_td <- topfeatures(mydfm, 50)
      ggplot() + 
         geom_bar(stat = "identity", 
                        aes(x = reorder(names(words_td),as.numeric(words_td)), y = as.numeric(words_td)),
                        fill = "magenta") + 
         ylab("Numero de ocorrencias") +
         xlab("") +
         geom_text( aes (x = reorder(names(words_td),as.numeric(words_td)), y = words_td, label = words_td ) , vjust = 0, hjust = 0, size = 2 ) + 
         coord_flip()
  }

  output$downloadPalavrasData <- downloadHandler(
    filename = function() {
      paste("listadepalavras.png", sep = "")
    },
    content = function(file) {
      device <- function(..., width, height) {
        grDevices::png(..., width = width, height = height,
                       res = 300, units = "in")
      }
      ggsave(file, plot = plotPalavras(), device = device)

    }
  )

  #####
  
  plotReactions = function(){
     url <- input$urlpost
#     id_pagina <- input$fbid 
     id_pagina <- getFBID(url)
     data <- input$date
     
     # command file.path already controls for the OS
     load(paste(workdir,"/fb_oauth",sep=""));
     
     data_inicio <- ymd(as.character(data)) + days(-2);
     data_final <- ymd(as.character(data)) + days(2);
     
     mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
     id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
     
     post_reactions <- getReactions(id_post, token=fb_oauth)
     counts <- as.numeric(post_reactions[,-1])
     reactions <- c("Likes","Loves","Haha","Wow","Sad", "Angry")
     percent <- signif(100*(counts/sum(counts)),1)
     ggplot() + 
        geom_bar(stat="identity", aes(x=reactions, y = counts)) + 
        xlab("Reações") + 
        ylab("Número de Ocorrências") + 
        coord_flip()
  }
  
  output$downloadReactionsData <- downloadHandler(
     filename = function() {
        paste("reactions.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotReactions(), device = device)
        
     }     
  )  
  
  
  
#####
  
  plotWordcloud = function(){
     url <- input$urlpost
#     id_pagina <- input$fbid 
     id_pagina <- getFBID(url)
     data <- input$date
     
     # command file.path already controls for the OS
     load(paste(workdir,"/fb_oauth",sep=""));
     
     data_inicio <- ymd(as.character(data)) + days(-2);
     data_final <- ymd(as.character(data)) + days(2);
     
     mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
     id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
     
     post_dados <- getPost(id_post, token=fb_oauth, n= 10000)
     text <- post_dados$comments$message
     mydfm <- getDFMatrix(text);
     set.seed(100)
     textplot_wordcloud(mydfm, min.freq = 3, random.order = FALSE,
                        rot.per = .25, 
                        colors = RColorBrewer::brewer.pal(8,"Dark2"))
  }
  
  output$downloadWordcloudData <- downloadHandler(
     filename = function() {
        paste("wordcloud.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotWordcloud(), device = device)
        
     }     
  )  

  output$downloadUsuariosMaisParticipativos <- downloadHandler(
     filename = function() {
        paste("usuariosmaisparticipativos.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotUsuariosMaisParticipativos(), device = device)
        
     }     
  )  

  output$downloadPalavrasUsuariosMaisParticipativos <- downloadHandler(
     filename = function() {
        paste("palavrasusuariosmaisparticipativos.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotPalavrasUsuariosMaisParticipativos(), device = device)
        
     }     
  )  


  output$downloadUsuariosMaisCurtidos <- downloadHandler(
     filename = function() {
        paste("usuariosmaiscurtidos.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotUsuariosMaisCurtidos(), device = device)
        
     }     
  )  

  output$downloadPalavrasUsuariosAngry <- downloadHandler(
     filename = function() {
        paste("palavrasusuariosangry.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotPalavrasUsuariosAngry(), device = device)
        
     }     
  )  
  
  output$downloadPalavrasUsuariosSad <- downloadHandler(
     filename = function() {
        paste("palavrasusuariossad.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotPalavrasUsuariosSad(), device = device)
        
     }     
  )  
  
  output$downloadPalavrasUsuariosLove <- downloadHandler(
     filename = function() {
        paste("palavrasusuarioslove.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotPalavrasUsuariosLove(), device = device)
        
     }     
  )  
  
  output$downloadPalavrasUsuariosHaha <- downloadHandler(
     filename = function() {
        paste("palavrasusuarioshaha.png", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotPalavrasUsuariosHaha(), device = device)
        
     }     
  )  

  
  output$downloadComparacaoComentarios <- downloadHandler(
     filename = function() {
        paste("comparacaoComentarios", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotComparacaoComentarios(), device = device)
        
     }     
  )  
  
  output$downloadIndiceSentimentoReacoes <- downloadHandler(
     filename = function() {
        paste("indicesentimentoreacoes", sep = "")
     },
     content = function(file) {
        device <- function(..., width, height) {
           grDevices::png(..., width = width, height = height,
                          res = 300, units = "in")
        }
        ggsave(file, plot = plotIndiceSentimentoReacoes(), device = device)
        
     }     
  )  
  
  
#####

  output$downloadExcelData <- downloadHandler(
    filename = function() {
      paste("comentarios.xlsx", sep = "")
    },
    content = function(file) {
      url <- input$urlpost
#      id_pagina <- input$fbid 
      id_pagina <- getFBID(url)
      data <- input$date
      
      # command file.path already controls for the OS
      load(paste(workdir,"/fb_oauth",sep=""));
      
      data_inicio <- ymd(as.character(data)) + days(-2);
      data_final <- ymd(as.character(data)) + days(2);
      
      mypage <- getPage(id_pagina, token = fb_oauth, feed=TRUE, since= as.character(data_inicio), until=as.character(data_final))
      id_post <- mypage$id[which(as.character(mypage$link)%in%url)]
      
      post_dados <- getPost(id_post, token=fb_oauth, n= 10000)
      allmessages <- post_dados$comments %>% select(created_time,from_id,from_name,message);
      names(allmessages) <- c("Data","Autor ID","Autor Nome","Conteúdo");
      wb<-createWorkbook(type="xlsx")
      TABLE_COLNAMES_STYLE <- CellStyle(wb) + Alignment(wrapText=TRUE, horizontal="ALIGN_CENTER")
      sheet <- createSheet(wb, sheetName = "facebookdata")
      setColumnWidth(sheet, colIndex=1:length(allmessages[1,]), 25)
      addDataFrame(allmessages, sheet, colnamesStyle = TABLE_COLNAMES_STYLE, colStyle = TABLE_COLNAMES_STYLE, startColumn=1, row.names = FALSE)
      saveWorkbook(wb, file)
    })
}
