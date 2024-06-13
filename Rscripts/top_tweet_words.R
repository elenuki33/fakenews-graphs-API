#! /usr/bin/Rscript
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
#library(emojifont)
library(visNetwork)
library(htmlwidgets)
library(tm)

library(topicmodels)

arg = commandArgs(trailingOnly=TRUE)
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Negativo", "Neutro", "Positivo", "Toxico")
paleta <- c("#D32F2F","#C2185B", "#FF4081", "#E040FB", "#536DFE", "#2196F3", "#00BCD4", "#4CAF50", "#FFEB3B", "#FF9800")


data <- read_csv(arg) #data

# Preprocesa el texto
corpus <- Corpus(VectorSource(data$text))
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removeWords, stopwords("es"))
corpus <- tm_map(corpus, stripWhitespace)

find_freq_terms_fun <- function(corpus_in){
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
#print(as.matrix(dtm))
if (!is.null(dtm)){

  raw.sum=apply(dtm,1,FUN=sum)
  table=dtm[raw.sum!=0,]

  k <- 5
  lda <- LDA(table, k = k)
  topic_terms <- terms(lda, 5)


  df <- data.frame(topic_terms)

  df_topic <- df %>%
    gather(key = "Topico", value = "Palabra", starts_with("Topic."))


  df_topic_freq <- df_topic %>%
    left_join(freq_terms_df, by = c("Palabra" = "Palabra")) %>%
    group_by(Topico) %>%
    summarise(Frequency_sum = sum(Frequency, na.rm = TRUE)) %>%
    arrange(desc(Frequency_sum))


  df_junto <-  left_join(df_topic, df_topic_freq, by = "Topico")

  resultado <- df_junto %>% arrange(desc(Frequency_sum))

  df_topic <- resultado %>%
    group_by(Topico) %>%
    summarize(Palabras_concatenadas = paste(Palabra, collapse = ", "))

  df_junto <-  left_join(df_topic, df_topic_freq, by = "Topico")

  resultado <- df_junto %>% arrange(desc(Frequency_sum))

  paleta <- c("#D32F2F","#C2185B", "#FF4081", "#E040FB", "#536DFE", "#2196F3", "#00BCD4", "#4CAF50", "#FFEB3B", "#FF9800")


  p <- plot_ly(data = resultado, x = resultado$Frequency_sum, y = reorder(resultado$Palabras_concatenadas, resultado$Frequency_sum), type = 'bar', marker = list(color = paleta[1:10])) %>%
    add_trace(hovertemplate = '%{x}', name = '') %>%
    layout(xaxis = list(title = ""),
           yaxis = list(title = ""),
           showlegend = FALSE,
           margin = list(l = 100, r = 10, t = 10, b = 10),
           annotations = list(
             list(x = 0, y = resultado$Palabras_concatenadas, text = "", xanchor = 'right', yanchor = 'middle', showarrow = FALSE, font = list(size = 8), padding = 10)
           ))
}else{

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




json_content <- plotly_json(p, pretty = TRUE)

writeLines(json_content, "json/top_tweet_words.json")

unlink("json/top_tweet_words_files", recursive = TRUE)

cat(json_content, sep = "\n")
