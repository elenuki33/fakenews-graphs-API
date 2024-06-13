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
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Negativo", "Neutro", "Positivo", "Toxico")
paleta <- c("#D32F2F","#C2185B", "#FF4081", "#E040FB", "#536DFE", "#2196F3", "#00BCD4", "#4CAF50", "#FFEB3B", "#FF9800")


data <- read_csv(arg) #data

x <- data %>%
  mutate(Ironia = mean(Ironia),
         Odio = mean(Odio),
         Dirigido = mean(Dirigido),
         Agresividad = mean(Agresividad),
         Diversion = mean(Diversion),
         Tristeza = mean(Tristeza),
         Enfado = mean(Enfado),
         Sorpresa = mean(Sorpresa),
         Disgusto = mean(Disgusto),
         Miedo = mean(Miedo),
         Toxico = mean(Toxico)) %>%
  select("Ironia", "Odio", "Dirigido", "Agresividad", "Diversion", "Tristeza", "Enfado", "Sorpresa", "Disgusto", "Miedo", "Toxico") %>%
  slice(1) %>%
  tidyr::gather(key = "Caracteristica", value = "Media")



max_media <- max(x$Media)
y_range <- if (max_media > 0.5) {
  c(0, max_media)
} else {
  c(0, 0.5)
}

p <- plot_ly(x, x = ~Caracteristica, y = ~Media, type = "bar", color = ~Caracteristica, colors = "viridis") %>%
  layout(title = "", xaxis = list(title = ""), yaxis = list(title = "", range = y_range),
         tickangle = -45, tickfont = list(size = 10)) %>%
  hide_legend() %>%
  layout(xaxis = list(
    tickmode = "array",
    tickvals = ~Caracteristica,
    ticktext = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Toxico")
  ))




json_content <- plotly_json(p, pretty = TRUE)

writeLines(json_content, "json/media_caracteristicas.json")

unlink("json/media_caracteristicas_files", recursive = TRUE)

cat(json_content, sep = "\n")













