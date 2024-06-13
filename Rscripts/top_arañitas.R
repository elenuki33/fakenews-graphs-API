#! /usr/bin/Rscript
#setwd("/home/administrador/Documentos/REMISS-api/Rscripts")
setwd("/app/Rscripts")

library(readr)
library(dplyr)
library(lubridate)
library(plotly)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(tidyr)
library(purrr)
library(stringr)
library(stringi)
library(visNetwork)
library(htmlwidgets)
library(tm)
library(topicmodels)
library(jsonlite)

arg = commandArgs(trailingOnly=TRUE)
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Negativo", "Neutro", "Positivo", "Toxico")
paleta <- c("#D32F2F","#C2185B", "#FF4081", "#E040FB", "#536DFE", "#2196F3", "#00BCD4", "#4CAF50", "#FFEB3B", "#FF9800")


data <- read_csv(arg) #data



#Preprocesa el texto
corpus <- Corpus(VectorSource(data$text))
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removeWords, stopwords("es"))
corpus <- tm_map(corpus, stripWhitespace)

find_freq_terms_fun <- function(corpus_in) {
  doc_term_mat <- TermDocumentMatrix(corpus_in)
  freq_terms <- findFreqTerms(doc_term_mat)[1:max(doc_term_mat$nrow)]
  terms_grouped <- doc_term_mat[freq_terms,] %>%
    as.matrix() %>%
    rowSums() %>%
    data.frame(Palabra=freq_terms, Frequency = .) %>%
    arrange(desc(Frequency)) %>%
    mutate(prop_term_to_total_terms=Frequency/nrow(.))
  return(data.frame(terms_grouped))
}

freq_terms_df <- find_freq_terms_fun(corpus)

#Crea una matriz término-documento
dtm <- DocumentTermMatrix(corpus)
if (!is.null(dtm)){

  raw.sum=apply(dtm,1,FUN=sum) #sum by raw each raw of the table
  table=dtm[raw.sum!=0,]


  k <- 5
  lda <- LDA(table, k = k)
  topic_terms <- terms(lda, 5)

  df <- data.frame(topic_terms) %>%
    pivot_longer(names_to = "Topico", values_to  = "Palabra", cols = c(Topic.1, Topic.2,Topic.3, Topic.4, Topic.5))

  df_topicos <- df %>%
    mutate(Topico = case_when(
      Topico == "Topic.1" ~ 0,
      Topico == "Topic.2" ~ 1,
      Topico == "Topic.3" ~ 2,
      Topico == "Topic.4" ~ 3,
      Topico == "Topic.5" ~ 4
    ), type = "Palabras", size = 5) %>%
    rename(name = Palabra, topic = Topico)

  # Ahora lo unimos con los nombres de los grafos
  df_topicos_ <- data.frame(
    name = as.character(rep(0:4, each = 1)),
    topic = rep(0:4, each = 1),
    size = 50,
    type = "Topicos"
  )

  #Los unimos y creamos un nuevo id
  dfgrafo <- bind_rows(df_topicos_, df_topicos) %>%
    mutate(id = row_number() - 1)

  #Las separamos de nuevo porque queremos el nuevo ID
  t1 <- dfgrafo[0:5,] %>% select(id, name, topic, type)
  t2 <- dfgrafo[6:nrow(dfgrafo),] %>% select(id, name, topic, type)

  # COLORES ROJO Y GRIS
  #queremos ver los que son fake:
  nuevo <- data %>% rowwise() %>%
    select(text, fakeness) %>%
    mutate(Topico0 = any(unname(sapply(t2 %>% filter(topic == "0") %>% .$name, grepl, x = text))),
           Topico1 = any(unname(sapply(t2 %>% filter(topic == "1") %>% .$name, grepl, x = text))),
           Topico2 = any(unname(sapply(t2 %>% filter(topic == "2") %>% .$name, grepl, x = text))),
           Topico3 = any(unname(sapply(t2 %>% filter(topic == "3") %>% .$name, grepl, x = text))),
           Topico4 = any(unname(sapply(t2 %>% filter(topic == "4") %>% .$name, grepl, x = text)))
    )

  topico0 <- nuevo %>%
    filter(Topico0 == TRUE) %>%
    summarise((as.numeric(fakeness))) %>%
    rename(fakeness = "(as.numeric(fakeness))")

  topico0_media <- mean(topico0$fakeness)


  topico1 <- nuevo %>%
    filter(Topico1 == TRUE) %>%
    summarise((as.numeric(fakeness))) %>%
    rename(fakeness = "(as.numeric(fakeness))")

  topico1_media <- mean(topico1$fakeness)


  topico2 <- nuevo %>%
    filter(Topico2 == TRUE) %>%
    summarise((as.numeric(fakeness))) %>%
    rename(fakeness = "(as.numeric(fakeness))")
  topico2_media <- mean(topico2$fakeness)


  topico3 <- nuevo %>%
    filter(Topico3 == TRUE) %>%
    summarise((as.numeric(fakeness))) %>%
    rename(fakeness = "(as.numeric(fakeness))")

  topico3_media <- mean(topico3$fakeness)


  topico4 <- nuevo %>%
    filter(Topico4 == TRUE) %>%
    summarise((as.numeric(fakeness))) %>%
    rename(fakeness = "(as.numeric(fakeness))")

  topico4_media <- mean(topico4$fakeness)


  t1 <- t1 %>%
    mutate(fakeness = case_when(
      topic == "0" ~ topico0_media,
      topic == "1" ~ topico1_media,
      topic == "2" ~ topico2_media,
      topic == "3" ~ topico3_media,
      topic == "4" ~ topico4_media),
      color = ifelse(fakeness >= 0.6, "red", "grey"))



  t2$raiz_revisada <- t2$name

  for (i in 1:nrow(t2)) {
    palabra_actual <- t2$name[i]
    palabra_mas_corta <- palabra_actual

    #Itera nuevamente para comparar con todas las demás palabras
    for (j in 1:nrow(t2)) {
      if (i != j) {
        palabra_comparar <- t2$name[j]

        #Comprueba si está contenida en la palabra actual
        if (grepl(palabra_comparar, palabra_actual)) {
          #Comprueba si la palabra es más corta que la actual más corta
          if (nchar(palabra_comparar) < nchar(palabra_mas_corta)) {
            palabra_mas_corta <- palabra_comparar
          }
        }
      }
    }

    t2$raiz_revisada[i] <- palabra_mas_corta
  }

  t_palabras <- t2  %>%
    select(id, raiz_revisada, topic, type) %>%
    rename (name = raiz_revisada) %>%
    mutate(color = "white")

  t_topicos <- t1 %>%
    select(-fakeness)


  a <- rbind(t_topicos, t_palabras) %>%
    select(-c("id", "topic")) %>%
    distinct() %>%
    group_by() %>%
    mutate(id = row_number() - 1)

  b <- left_join(a, rbind(t_topicos, t_palabras), by = "name")

  #colores <- c("lightblue", "magenta", "turquoise", "salmon", "gold")

  c <- b %>% select(id.x, name, topic, type.x, color.x) %>%
    rename(id =  id.x, type = type.x, color = color.x) %>%
    mutate(
      shape = ifelse(type == 'Topicos', 'box', 'ellipse'),
      size = ifelse(type == 'Topicos', 50, 10),
      shadow = ifelse(type == 'Topicos', TRUE, FALSE),
      value = ifelse(type == "Topicos", 30, 40)
    )

  #c$color <- colores[c$id + 1]

  #c <- c %>%mutate(color = ifelse(type == "Palabras", "White", color))

  c$name <- ifelse(grepl("^\\d+$", c$name), paste("Tópico", c$name), c$name)

  topic_t <- c %>%
    filter(type == "Topicos")

  result_df <- c %>%
    left_join(topic_t, by = "topic") %>%
    select(source = id.y, target = id.x)

  source_target <- result_df %>%
    filter(source != target)

  Mislinks <- source_target
  Misnodes <- c %>%
    select(-topic) %>%
    distinct()

  Misnodes <- Misnodes %>%
    rename(label = name, group = type) %>%
    select(id, label, group, color, shadow, shape) #Quitamos el shape porque sale mal

  Mislinks <- Mislinks %>%
    rename(from = source, to = target) %>%
    select(from, to) %>%
    distinct()

  p <-   visNetwork(Misnodes, Mislinks, height = "700px", width = "100%", main="Los 5 topicos más frecuentes") %>% addFontAwesome()  %>%
    visOptions(highlightNearest = TRUE) %>%
    visOptions(
      highlightNearest = list(enabled = T, degree = 1, hover = F),
      selectedBy = "group",
      collapse = FALSE
    )

} else{
  p <- plot_ly() %>%
    layout(title = " ",
           showlegend = FALSE,
           annotations = list(
             text = "No hay suficientes datos para extraer tópicos.",
             x = 0.5,
             y = 0.5,
             xref = "paper",
             yref = "paper",
             showarrow = FALSE
           )
    )
}

# HTML
# htmlwidgets::saveWidget(p, "html/arañitas_topicos.html")
# 
# html <- readLines("html/arañitas_topicos.html")
# 
# #Obtiene el contenido HTML del widget
# widget_html <- paste(html, collapse = "\n")
# 
# writeLines(widget_html, "html/arañitas_topicos.txt")#mantener si elena lo necesita
# 
# 
# #Eliminar los archivos que sobran:
# unlink("html/arañitas_topicos_files", recursive = TRUE)
# 
# x <- file.remove("html/arañitas_topicos.html")
# 
# #Devolver el contenido del txt:
# cat(readLines("html/arañitas_topicos.txt"), sep = "\n")


# JSON
# 
# print(toJSON(Mislinks))
# print(toJSON(Misnodes))
# 
# 
# datos_json <- list(Mislinks = Mislinks, Misnodes = Misnodes)
# write_json(datos_json, "archivo.json")


print(toJSON(list(Mislinks = Mislinks, Misnodes = Misnodes)))













