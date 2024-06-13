#!/usr/bin/env python
# encoding: utf-8

import json
from flask import Flask, request
import subprocess
import datetime
from flask_pymongo import PyMongo
import pandas as pd
import os
from models.dbMongo import mongo

app = Flask(__name__)
app.config['MONGO_URI'] = "mongodb://usuario:contraseña@direccion_ip:puerto/nombre_de_la_base_de_datos"
mongo.init_app(app)

def get_collection(collection_name):
    # Function to get specific collection
    #db = mongo_ESADE.db  # get db
    #return db[collection_name]
    pass


def to_date(date_string):
    try:
        return datetime.datetime.strptime(date_string, "%Y-%m-%d").date()
    except ValueError:
        raise ValueError('{} is not valid date in the format YYYY-MM-DD'.format(date_string))


def get_result_collection(date_start, date_end, collection):
    # query collection with date filter
    if date_start is not None and date_end is not None:
        query = {"date_field": {"$gte": date_start, "$lte": date_end}}
        result = list(collection.find(query))
    else:
        # date start and end not in args url
        result = list(collection.find())

    # create temporal csv
    df = pd.DataFrame(result)
    df.info()
    df.to_csv("temporal.csv", index=False)

    return result


@app.route('/api/hello', methods=['GET'])
def hello():
    return "hello"


@app.route('/api/graph1', methods=['GET'])
def r_graph1():
    # call to r script with csv temp to create graph
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/line_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    # Return HTML graph generated with script R
    return result.stdout


@app.route('/api/graph2', methods=['GET'])
def r_graph2():
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/topics_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    return result.stdout


@app.route('/api/graph3', methods=['GET'])
def r_graph3():
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/MH_topics_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    return result.stdout


@app.route('/api/graph4', methods=['GET'])
def r_graph4():
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/ranking_hashtags_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    return result.stdout


@app.route('/api/graph5', methods=['GET'])
def r_graph5():
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/ranking_topics_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    return result.stdout


@app.route('/api/graph6', methods=['GET'])
def r_graph6():
    r_script = "/home/administrador/Documentos/REMISS-api/Rscripts/ranking_tweeters_graph.R"
    result = subprocess.run(["Rscript", r_script], capture_output=True, text=True)
    return result.stdout


if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8888)