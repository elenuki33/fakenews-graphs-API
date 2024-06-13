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


hashtags_excluidos <- c(
  "#EleccionesAndaluzas",
  "#EleccionesAlParlamentoDeAndalucía",
  "#ElCambioQueFunciona",
  "#EleccionesAndalucia",
  "#AndalucíaVota",
  "#AndalucíaLiberal",
  "#eleccionesandalucia2022",
  "#ParlamentodeAndalucía",
  "#Adelante19J",
  "#19J",
  "#SiVotamosGanamos",
  "#PorAndalucía",
  "#19junio",
  "#AndalucíaAvanza",
  "#EnDefensaPropia",
  "#19deJunio",
  "#CambioReal",
  "#SoloQuedaVox",
  "#19JAndalucia",
  "#PorAndalucía",
  "#Macarenazo",
  "#TeamVox",
  "#LevantandoEspaña",
  "#PedroSanchezTraidor",
  "#DebatesCompoLider",
  "#EleccionesCyL13F",
  "#EleccionesCyL2022",
  "#13F",
  "#CastillaYLeón",
  "#CambioYEsperanza",
  "#VotaCastillayLeon",
  "#PasiónPorCyL",
  "#QueTuVozSeEscuche",
  "#eleccionescastillayleon",
  "#albertosotillos",
  "#CompoLider",
  "#4M",
  "#4Mayo",
  "#EleccionesMadrid",
  "#eleccionesMadrid2021",
  "#MasMadrid4M",
  "#Elecciones4M",
  "#pucherazo",
  "#pucherazocorreos",
  "#IglesiasCierraAlSalir",
  "#PabloCierraAlSalir",
  "#LevantandoEspaña",
  "#EleccionesCatL6",
  "#Especial14FRTVE",
  "#Cataluña #14F",
  "#PresidentIlla",
  "#Elecciones14F",
  "#EleccionesCatalanas",
  "#4m",
  "#Eleccions14F",
  "#Pucherazo",
  "14F",
  "#PP",
  "EleccionsCatalanes",
  "VotaPSOE",
  "#PSOE",
  "#Vox"
)


twh <-tweets %>%
  separate_rows(hashtags, sep = ";") %>%
  filter(!grepl(paste0(hashtags_excluidos, collapse = "|"), hashtags)) %>%
  filter(hashtags != "") %>%
  count(hashtags, sort = TRUE)%>%
  filter(row_number() <= 10)


p<- plot_ly(data = twh, x = ~n, y = ~reorder(hashtags, n), type = 'bar', marker = list(color = paleta[1:10])) %>%
  add_trace(hovertemplate = '%{x}', name = '') %>%
  layout(xaxis = list(title = ""),
         yaxis = list(title = ""),
         showlegend = FALSE,
         margin = list(l = 100, r = 10, t = 10, b = 10),
         annotations = list(
           list(x = 0, y = twh$hashtags, text = "", xanchor = 'right', yanchor = 'middle', showarrow = FALSE, font = list(size = 8), padding = 10)
         ))

      
json_content <- plotly_json(p, pretty = TRUE)

writeLines(json_content, "json/top_hashtags.json")

unlink("json/top_hashtags_files", recursive = TRUE)

cat(json_content, sep = "\n")
      
      
      
      
      
      
      
      
      
      
      