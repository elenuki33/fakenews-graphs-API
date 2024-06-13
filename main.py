#!/usr/bin/env python
# encoding: utf-8

import json
from flask import Flask, request, make_response, jsonify
import subprocess
import datetime

from flask_pymongo import PyMongo
import pandas as pd
import os, glob
from services.mongo_service import MongoService
from models.dbMongo import mongo
mongoService = MongoService()

# SWAGGER CONFIG
from flask_openapi3 import Info, Tag
from flask_openapi3 import OpenAPI, RequestBody
from pydantic import BaseModel, Field
from typing import Optional

app = Flask(__name__)

#app.config["MONGO_URI"] = "mongodb://ealgar:3l3n4@hodor.uv.es:27017/?authSource=admin"
#app.config["MONGO_URI"] = "mongodb://localhost/remiss
app.config["MONGO_URI"] = os.environ.get("MONGO_URL")


mongo.init_app(app)

max_temporal_files = 10
temporal_folder = '/app/Rscripts/data'
#temporal_folder = '/home/administrador/Documentos/REMISS-api/Rscripts/data'


class GraphParameters(BaseModel):
    window: Optional[str] = Field(None, description='Number of days (ex: 20)')
    start: Optional[str] = Field(None, description='Start date (ex:2020-12-01)')
    end: Optional[str] = Field(None, description='End date (ex:2023-12-01)')
    name: Optional[str] = Field(None, description='Dataset name (madrid, castleon, andalucia, catalunya)')


info = Info(title="REMISS API", version="1.0.0")
app = OpenAPI(__name__, info=info)


@app.get("/")
def home():
    return jsonify({
        "Message": "REMISS API  up and running successfully"
    })


def rotate_temporal_files():
    temporal_files = os.listdir(temporal_folder)

    if len(temporal_files) >= max_temporal_files:
        # Ordenar los archivos temporales por fecha de modificación
        temporal_files.sort(key=lambda x: os.path.getmtime(os.path.join(temporal_folder, x)))

        # Eliminar el archivo más antiguo
        os.remove(os.path.join(temporal_folder, temporal_files[0]))


def get_latest_temporal_file():
    files = glob.glob(os.path.join(temporal_folder, "temporal_*.csv"))
    if not files:
        return None
    # Ordenar los archivos por fecha de modificación descendente
    files.sort(key=lambda x: os.path.getmtime(x), reverse=True)

    #print(files[0])
    return files[0]  # file más nuevo


def to_date(date_string):
    try:
        return datetime.datetime.strptime(date_string, "%Y-%m-%d").date()
    except ValueError:
        raise ValueError('{} is not valid date in the format YYYY-MM-DD'.format(date_string))


def get_result_dataset(data):
    #data = dataset.get("data", [])
    result = data
    if result is None or len(result) == 0:
        df = pd.DataFrame(columns=data.columns)
    else:
        df = pd.DataFrame(result)

    current_datetime = datetime.datetime.now()
    filename = "temporal_" + current_datetime.strftime("%Y-%m-%d_%H-%M-%S") + ".csv"
    file_path = os.path.join(temporal_folder, filename)

    df.to_csv(file_path, index=False)

    #df.info()

    # rotate 10 temp files
    rotate_temporal_files()


@app.get('/api/get_data',
    description='Get dataset from database in csv format',
    responses={200: {"content": {"text/csv": {"schema": {"type": "string"}}}}},
    methods=['POST', 'GET'])
def get_data(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    df_final = get_latest_temporal_file()
    df = pd.read_csv(df_final)

    resp = make_response(df.to_csv())
    resp.headers["Content-Disposition"] = "attachment; filename=data.csv"
    resp.headers["Content-Type"] = "text/csv"

    return resp


@app.get('/api/graph1',
         description='Average emotions line graph per hour',
         responses={200: {"content": {"text/json": {}}}},
         methods=['POST', 'GET'])
def r_graph1(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    # call to r script with csv temp to create graph
    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/line_graph.R"
    r_script = "/app/Rscripts/line_graph.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)
    #print('-----')
    print(result.returncode, result.stdout, result.stderr)
    # Return HTML graph generated with script R
    return result.stdout


@app.get('/api/graph2',
         description='Average emotions bar graph',
         responses={200: {"content": {"text/json": {}}}},
         methods=['POST', 'GET'])
def r_graph2(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/media_caracteristicas.R"
    r_script = "/app/Rscripts/media_caracteristicas.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)
    #print(result.returncode, result.stdout, result.stderr)

    return result.stdout


@app.get('/api/graph3',
         description='Top hashtags graph',
         responses={200: {"content": {"text/json": {}}}},
         methods=['POST', 'GET'])
def r_graph3(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    # call to r script with csv temp to create graph
    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/top_tweeteros.R"
    r_script = "/app/Rscripts/top_tweeteros.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)

    return result.stdout


@app.get('/api/graph4',
         description='Top profiles graph',
         responses={200: {"content": {"text/json": {}}}},
         methods=['POST', 'GET'])
def r_graph4(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')


    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/top_hashtags.R"
    r_script = "/app/Rscripts/top_hashtags.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)

    return result.stdout


@app.get('/api/graph5',
         description='Topic ranking graph',
         responses={200: {"content": {"text/json": {}}}},
         methods=['POST', 'GET'])
def r_graph5(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    # call to r script with csv temp to create graph
    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/top_tweet_words.R"
    r_script = "/app/Rscripts/top_tweet_words.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)
    #print(result.returncode, result.stdout, result.stderr)
    return result.stdout


@app.get('/api/graph6',
         description='Network topics graph',
         responses={200: {"content": {"text/html": {}}}},
         methods=['POST', 'GET'])
def r_graph6(query: GraphParameters):
    # get args url
    window = request.args.get('window')
    date_start = request.args.get('start')
    date_end = request.args.get('end')
    db_name = request.args.get('name')

    # call to ESADE MONGO
    coll_data = mongoService.get_dataset(db_name, date_start, date_end, window)
    get_result_dataset(coll_data)  # create temporal.csv

    #coll_data.info()

    # call to r script with csv temp to create graph
    temporal_csv = get_latest_temporal_file()
    #r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/top_arañitas.R"
    r_script = "/app/Rscripts/top_arañitas.R"
    result = subprocess.run(["Rscript", r_script, temporal_csv], capture_output=True, text=True)
    #print(result.returncode, result.stdout, result.stderr)

    return result.stdout


@app.route('/getdbnames', methods=['GET'])
def get_databases():
    quitar = ['admin', 'config', 'local', 'remiss', 'CVCUI2']
    names = [i for i in list(mongoService.get_db_names()) if i not in quitar]

    return names


@app.route('/api/upload', methods=['POST', 'GET'])
def upload_mongo():
    csv_file_path = '/media/nas/peerobs_sync/shared/REMISS/INMIGRACION/bcn15_final.csv'

    '''
    f = open('/media/nas/peerobs_sync/shared/REMISS/andalucia.json' , 'w')

    with open(json_path, 'r', encoding='utf-8') as file:
        json_data = json.load(file)
        json.dump(json_data, f, ensure_ascii=False, indent=4)
    '''
    df = pd.read_csv(csv_file_path)

    # Convertir el DataFrame de pandas a una lista de diccionarios (cada fila es un diccionario)
    data = df.to_dict(orient='records')
    
    mongoService.create_dataset(data, 'uv_bcn15')

    return 'ok'



if __name__ == "__main__":
    host = '0.0.0.0'
    app.run(host=host, port=5005)
