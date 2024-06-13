import json
import pandas as pd
from  pymongo import MongoClient
import pymongo
import os

client = MongoClient("mongodb://ealgar:3l3n4@hodor.uv.es:27017/remiss?authSource=admin")
db = client.get_database()

col_names = ['andalucia', 'castleon', 'catalunya', 'madrid']

for cn in col_names:    
    json_path = '/media/nas/peerobs_sync/shared/REMISS/ELECCIONES/DATA/tweets_'+cn+'_fakeness.json'

    file = open(json_path)
    json_data = json.load(file)
        
    new_coll = db['uv_' + cn]
    resultado = new_coll.insert_many(json_data)
    
    
