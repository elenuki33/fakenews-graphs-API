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
#library(emojifont)
library(visNetwork)
library(htmlwidgets)

arg = commandArgs(trailingOnly=TRUE)
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Negativo", "Neutro", "Positivo" )
paleta <- c("#D32F2F","#C2185B", "#FF4081", "#E040FB", "#536DFE", "#2196F3", "#00BCD4", "#4CAF50", "#FFEB3B", "#FF9800")


tweets <- read_csv(arg) #data
print(tweets)


top_tweeteros <- tweets %>%
  group_by(username) %>%
  tally() %>%
  arrange(desc(n)) %>%
  filter(row_number() <= 10)%>%
  mutate(username = paste0("@", username))

p <- plot_ly(data = top_tweeteros, x = ~n, y = ~reorder(username, n), type = 'bar', marker = list(color = paleta[1:10])) %>%
  add_trace(hovertemplate = '%{x}', name = '') %>%
  layout(xaxis = list(title = ""),
         yaxis = list(title = ""),
         showlegend = FALSE,
         margin = list(l = 100, r = 10, t = 10, b = 10),
         annotations = list(
           list(x = 0, y = top_tweeteros$username, text = "", xanchor = 'right', yanchor = 'middle', showarrow = FALSE, font = list(size = 8), padding = 10)
         ))


json_content <- plotly_json(p, pretty = TRUE)

writeLines(json_content, "json/top_tweeteros.json")

unlink("json/top_tweeteros_files", recursive = TRUE)

cat(json_content, sep = "\n")



































