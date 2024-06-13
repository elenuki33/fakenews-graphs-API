#Libraries

library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(plotly)
library(purrr)
library(readr)
library(stringr)
library(stringi)
library(emojifont)
#library(flexdashboard)
#library(networkD3)
library(visNetwork)

options(scipen=999) #para cargar sin notacion cientifica los id


#Load the data
tweets <- read_csv("/home/peerobs_sync/shared/REMISS/ELECCIONES/DATA/tweets_ELECCIONES.csv")
topics <- read_csv("/home/peerobs_sync/shared/REMISS/ELECCIONES/DATA/tweets_topics_per_class.csv")

#Clean the data
tweets$date <- ymd_hms(tweets$date)
tweets$location <- replace(tweets$location, is.na(tweets$location), "")
get_name <- function(x){ return(str_match(x, '"(name)": "([^"]*)"')[,3]) }

tweets <- tweets %>% mutate(imagen = str_extract(extended_user, 'https://pbs.twimg.com/profile_images/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'),
                                  name = get_name(extended_user)) %>%
  mutate(name = stri_unescape_unicode(name))


#Change the language to spanish:
tweets <- tweets %>% rename("Ironia" = "ironic", "Odio" = "hateful", "Dirigido" = "targeted", "Agresividad" = "aggressive", "Diversion" = "joy", "Tristeza" = "sadness", "Enfado"  = "anger","Sorpresa" = "surprise", "Disgusto" = "disgust", "Miedo" =  "fear")


write_csv(tweets, "/home/peerobs_sync/shared/Rscripts_graphs/tweets.csv")



#Prepared data to line_graph
caracteristicas = c("Agresividad", "Enfado", "Disgusto", "Miedo", "Odio", "Ironia", "Diversion", "Tristeza", "Sorpresa", "Dirigido")

data_line_graph <- tweets %>%
    mutate(hora = hour(date)) %>%
    group_by(hora) %>%

write_csv(data_line_graph, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/data_line_graph.csv")



#Prepared data to ranking_tweeters --GRAPH3

ranking_tweeters <- tweets %>%
  group_by(username) %>%
  tally() %>%
  arrange(desc(n)) %>%
  filter(row_number() <= 10)%>%
  mutate(username = paste0("@", username))



write_csv(ranking_tweeters, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/ranking_tweeters.csv")



#Prepared data to ranking_hashtags --GRAPH3

ranking_hashtags <-
  tweets %>%
  separate_rows(hashtags, sep = ";") %>%
  filter(hashtags != "") %>%
  count(hashtags, sort = TRUE)%>%
  filter(row_number() <= 10)


write_csv(ranking_hashtags, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/ranking_hashtags.csv")



#Prepared data to ranking_topics --GRAPH3

ranking_topics <- topics %>%
  select(Words, Frequency)  %>%
  distinct(Words, .keep_all = TRUE)%>%
  arrange(desc(Frequency)) %>%
  filter(row_number() <= 10)

write_csv(ranking_topics, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/ranking_topics.csv")








































# TOPIC DATA:



#Seleccionamos los 5 mas frecuentes de la clase More Hoax:
topicos_top_mh <- topics %>% filter(Class == "More Hoax")%>% arrange(desc(Frequency)) %>% head(5) %>% select("Topic", "Words")

#Obtenemos el df con las palabras separadas
df_palabras <- topicos_top_mh %>%
  separate_rows(Words, sep = ",\\s*") %>%
  mutate(
    name = Words,
    size = 5,
    type = "Palabras"
  ) %>%
  select(name, topic = Topic, size, type)

#Quitamos mayusculas, acentos
df_palabras$name <- tolower(iconv(df_palabras$name, from = "UTF-8", to = "ASCII//TRANSLIT"))

#Eliminamos palabras comunes y los numeros
palabras_comunes <- c("el", "la", "los", "las", "un", "una", "unos", "unas", "yo", "tú", "él", "ella", "nosotros", "vosotros", "ellos", "ellas", "the", "mi", "de", "els", "per", "amb", "es", "mas", "si", "no") #la palabra mas no se que criterio hacer para quitarla
palabras_con_numeros <- df_palabras$name[grepl("^\\d+$", df_palabras$name)]

df_palabras <- subset(df_palabras, !(name %in% palabras_comunes) & !(name %in% palabras_con_numeros))


#Ahora como tenemos un df de numeros ordenados aleatorios, los ordenamos en orden ascendente
df_palabras <- df_palabras %>%
  arrange(topic)%>%
  mutate(new_topic = dense_rank(topic) - 1) #Asigna nuevos valores del 0 al 4 a los grupos ordenados


#Ahora lo unimos con los nombres de los grafos
df_topicos<- data.frame(
  name = as.character(rep(0:4, each = 1)),
  new_topic = rep(0:4, each = 1),
  size = 50,
  type = "Topicos"
)

#Los unimos y creamos un nuevo id
dfgrafo <- bind_rows(df_topicos, df_palabras) %>%
  mutate(id = row_number() -1) %>% select(-topic)

#Las separamos de nuevo porque queremos el nuevo ID
t1<- dfgrafo[0:5,] %>% select(id, name, new_topic, type) %>% rename(topic = new_topic)
t2 <- dfgrafo[6:nrow(dfgrafo),] %>% select(id, name, new_topic, type) %>% rename(topic = new_topic)

#Ahora queremos unir las palabras con el mismo significado pero que sean palabras distintas como votar, votado y voto o como elecciones, elecciones4m y eleccionesmadrid.
#Para eso:

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

  #Actualiza la columna "raiz_revisada" con la palabra más corta (si se encontró una)
  t2$raiz_revisada[i] <- palabra_mas_corta
}

#Ahora solo nos interesa id, name, topic, type y raiz_revisada
t_palabras <- t2  %>% select(id, raiz_revisada, topic, type) %>% rename (name = raiz_revisada)
t_topicos <- t1

a = rbind(t_topicos,t_palabras) %>%
  select(-c("id", "topic")) %>%
  distinct() %>%
  group_by() %>%
  mutate(id = row_number() -1)

b<- left_join(a, rbind(t_topicos,t_palabras), by = "name")

#Define una paleta de colores que quieras asignar a los diferentes topicos (top5)
colores <- c( "lightblue", "magenta", "turquoise", "salmon", "gold")


c <-b %>% select(id.x, name, topic, type.x) %>%
  rename(id =  id.x, type = type.x) %>%
  mutate(
    #color = ifelse(type == 'p', "skyblue", topic),
    shape = ifelse(type == 'Topicos', 'box', 'ellipse'),
    size = ifelse(type == 'Topicos', 50, 10),
    shadow = ifelse(type == 'Topicos', TRUE, FALSE),
    value = ifelse(type == "Topicos", 30, 40)
  )

#Asigna colores a la columna 'color' según el valor de 'id'
c$color <- colores[c$id + 1]

c <- c %>%
  mutate(color = ifelse(type == "Palabras", "White", color))

c$name <- ifelse(grepl("^\\d+$", c$name), paste("Tópico", c$name), c$name)


#Tabla de source y target
topic_t <- c %>%
  filter(type == "Topicos")

result_df <- c %>%
  left_join(topic_t, by = "topic") %>%
  select(source = id.y, target = id.x)

#Filtrar las filas donde source y target sean distintos
source_target <- result_df %>%
  filter(source != target)


Mislinks <- source_target
Misnodes <- c %>%
  select(-topic) %>%
  distinct()

#prerpara el df para visNetwork
Misnodes_MH <- Misnodes %>%
  rename(label = name, group = type) %>%
  select(id, label, group, color, shadow, shape) #Quitamos el shape porque sale mal

Mislinks_MH <- Mislinks %>%
  rename(from = source, to = target) %>%
  select(from, to) %>%
  distinct()





#Seleccionamos los 5 mas frecuentes de la clase Less Hoax:

#Seleccionamos los 5 mas frecuentes de esta clase:
topicos_top_lh <- topics %>% filter(Class == "Less Hoax")%>% arrange(desc(Frequency)) %>% head(5) %>% select("Topic", "Words")

#Obtenemos el df con las palabras separadas
df_palabras <- topicos_top_lh %>%
  separate_rows(Words, sep = ",\\s*") %>%
  mutate(
    name = Words,
    size = 5,
    type = "Palabras"
  ) %>%
  select(name, topic = Topic, size, type)

#Quitamos mayusculas, acentos
df_palabras$name <- tolower(iconv(df_palabras$name, from = "UTF-8", to = "ASCII//TRANSLIT"))

#Eliminamos palabras comunes y los numeros
palabras_comunes <- c("el", "la", "los", "las", "un", "una", "unos", "unas", "yo", "tú", "él", "ella", "nosotros", "vosotros", "ellos", "ellas", "the", "mi", "de", "els", "per", "amb", "es", "mas") #la palabra mas no se que criterio hacer para quitarla
palabras_con_numeros <- df_palabras$name[grepl("^\\d+$", df_palabras$name)]

df_palabras <- subset(df_palabras, !(name %in% palabras_comunes) & !(name %in% palabras_con_numeros))


#Ahora como tenemos un df de numeros ordenados aleatorios, los ordenamos en orden ascendente
df_palabras <- df_palabras %>%
  arrange(topic)%>%
  mutate(new_topic = dense_rank(topic) - 1) #Asigna nuevos valores del 0 al 4 a los grupos ordenados


#Ahora lo unimos con los nombres de los grafos
df_topicos<- data.frame(
  name = as.character(rep(0:4, each = 1)),
  new_topic = rep(0:4, each = 1),
  size = 50,
  type = "Topicos"
)

#Los unimos y creamos un nuevo id
dfgrafo <- bind_rows(df_topicos, df_palabras) %>%
  mutate(id = row_number() -1) %>% select(-topic)

#Las separamos de nuevo porque queremos el nuevo ID
t1<- dfgrafo[0:5,] %>% select(id, name, new_topic, type) %>% rename(topic = new_topic)
t2 <- dfgrafo[6:nrow(dfgrafo),] %>% select(id, name, new_topic, type) %>% rename(topic = new_topic)

#Ahora queremos unir las palabras con el mismo significado pero que sean palabras distintas como votar, votado y voto o como elecciones, elecciones4m y eleccionesmadrid.
#Para eso:

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

  #Actualiza la columna "raiz_revisada" con la palabra más corta (si se encontró una)
  t2$raiz_revisada[i] <- palabra_mas_corta
}

#Ahora solo nos interesa id, name, topic, type y raiz_revisada
t_palabras <- t2  %>% select(id, raiz_revisada, topic, type) %>% rename (name = raiz_revisada)
t_topicos <- t1

a = rbind(t_topicos,t_palabras) %>%
  select(-c("id", "topic")) %>%
  distinct() %>%
  group_by() %>%
  mutate(id = row_number() -1)

b<- left_join(a, rbind(t_topicos,t_palabras), by = "name")

#Define una paleta de colores que quieras asignar a los diferentes topicos (top5)
colores <- c( "lightblue", "magenta", "turquoise", "salmon", "gold")


c <-b %>% select(id.x, name, topic, type.x) %>%
  rename(id =  id.x, type = type.x) %>%
  mutate(
    #color = ifelse(type == 'p', "skyblue", topic),
    shape = ifelse(type == 'Topicos', 'box', 'ellipse'),
    size = ifelse(type == 'Topicos', 50, 10),
    shadow = ifelse(type == 'Topicos', TRUE, FALSE),
    value = ifelse(type == "Topicos", 30, 40)
  )

#Asigna colores a la columna 'color' según el valor de 'id'
c$color <- colores[c$id + 1]

c <- c %>%
  mutate(color = ifelse(type == "Palabras", "White", color))

c$name <- ifelse(grepl("^\\d+$", c$name), paste("Tópico", c$name), c$name)


#Tabla de source y target
topic_t <- c %>%
  filter(type == "Topicos")

result_df <- c %>%
  left_join(topic_t, by = "topic") %>%
  select(source = id.y, target = id.x)

#Filtrar las filas donde source y target sean distintos
source_target <- result_df %>%
  filter(source != target)


Mislinks <- source_target
Misnodes <- c %>%
  select(-topic) %>%
  distinct()

#prerpara el df para visNetwork
Misnodes_LH <- Misnodes %>%
  rename(label = name, group = type) %>%
  select(id, label, group, color, shadow, shape) #Quitamos el shape porque sale mal

Mislinks_LH <- Mislinks %>%
  rename(from = source, to = target) %>%
  select(from, to) %>%
  distinct()




# CSV NECESSARY TO TOPICS GRAPH -- GRAPH1

write_csv(Misnodes_MH, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/Misnodes_MH.csv")

write_csv(Mislinks_MH, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/Mislinks_MH.csv")



# CSV NECESSARY TO TOPICS GRAPH -- GRAPH2

write_csv(Misnodes_LH, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/Misnodes_LH.csv")

write_csv(Mislinks_LH, "/home/peerobs_sync/shared/REMISS/Rscripts_graphs/Mislinks_LH.csv")







