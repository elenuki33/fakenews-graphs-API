#! /usr/bin/Rscript
#setwd("/home/administrador/Documentos/REMISS-api/Rscripts")
setwd("/app/Rscripts")


library(readr)
library(dplyr)
library(lubridate)
library(plotly)

arg = commandArgs(trailingOnly=TRUE)
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido", "Negativo", "Neutro", "Positivo" )

tweets <- read_csv(arg) #data

data_line_graph <- tweets %>%
  mutate(hora = hour(date)) %>%
  group_by(hora) %>%
  summarise(Agresividad=mean(Agresividad),
            Enfado=mean(Enfado),
            Disgusto=mean(Disgusto),
            Miedo=mean(Miedo),
            Odio=mean(Odio),
            Ironia=mean(Ironia),
            Diversion=mean(Diversion),
            Tristeza=mean(Tristeza),
            Sorpresa=mean(Sorpresa),
            Dirigido=mean(Dirigido),
            Tristeza=mean(Tristeza),
            Sorpresa=mean(Sorpresa),
            Dirigido=mean(Dirigido),
            Negativo=mean(Negativo),
            Neutro=mean(Neutro),
            Positivo=mean(Positivo))


horas_etiquetas <- sprintf("%d:00", 1:24)


#Graph
x <- c(1:100)
random_y <- rnorm(100, mean = 0)
data <- data.frame(x, random_y)
p <- plot_ly(data_line_graph, type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Agresividad, name="Agresividad", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Enfado, name="Enfado", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Disgusto, name="Disgusto", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Miedo, name="Miedo", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Odio, name="Odio", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Ironia, name="Ironia", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Diversion, name="Diversion", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Tristeza, name="Tristeza", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Sorpresa, name="Sorpresa", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Dirigido, name="Dirigido", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Negativo, name="Negativo", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Neutro, name="Neutro", type = 'scatter', mode = 'lines') %>%
    add_trace(x=~hora, y=~Positivo, name="Positivo", type = 'scatter', mode = 'lines')

p <- p %>% layout(title = " ",
             xaxis = list(title = " ", tickvals = 1:24, ticktext = horas_etiquetas),
             yaxis = list(title = " "),
             legend = list(orientation = "v"))

json_content <- plotly_json(p, pretty = TRUE)

writeLines(json_content, "json/line_graph.json")

unlink("json/line_graph_files", recursive = TRUE)

cat(json_content, sep = "\n")










