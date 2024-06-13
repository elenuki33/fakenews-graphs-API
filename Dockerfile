# Utiliza una imagen que incluya Python y R
#FROM rocker/r-ver:4.1.0
# imagen de r

FROM r-base:4.3.2

# Define la variable de entorno con la URI de MongoDB
ENV MONGO_URL="mongodb://localhost/remiss"

# Instala las dependencias necesarias para R
RUN apt-get update && apt-get install -y \
    sudo \
    libcurl4 \
    libcurl4-openssl-dev \
    libexpat1\
    libssl-dev \
    libxml2-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libfftw3-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    gsl-bin \
    libgsl-dbg \
    libgsl-dev \
    libgslcblas0

#RUN apt-get update && apt-get install -y  --allow-downgrades\
 #   sudo \
  #  libexpat1=2.5.0-2+b2 \

# PYTHON
COPY requirements.txt .
RUN apt-get update && apt-get upgrade -y
RUN apt-get -y update
RUN apt-get -y install python3 python3-pip
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev python3-setuptools python3-dev python3.11-venv
RUN python3 -m venv /venv
RUN /venv/bin/pip install --upgrade pip
RUN /venv/bin/pip install -r requirements.txt
RUN /venv/bin/pip install Flask

# R
RUN apt-get install -y pandoc
RUN R -e "install.packages('topicmodels', dependencies = TRUE)"
RUN R -e "install.packages(c('rmarkdown', 'emojifont'), dependencies=TRUE)"

RUN R -e "install.packages(c('shiny', 'shinydashboard', 'jsonlite', 'flexdashboard', 'dplyr', 'ggplot2', 'lubridate', 'tidyr', 'plotly', 'purrr', 'readr', 'stringr', 'stringi', 'visNetwork', 'DT', 'httr', 'tm', 'shinydashboard', 'shinycssloaders'), repos='http://cran.rstudio.com/')"


WORKDIR /app
COPY . .
EXPOSE 5005
ENV FLASK_APP=main.py

CMD ["/venv/bin/python", "main.py"]


