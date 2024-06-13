from models.dbMongo import mongo
import pandas as pd
import datetime
from datetime import timedelta

def to_date(date_string):
    try:
        return datetime.datetime.strptime(date_string, "%Y-%m-%d").date()
    except ValueError:
        raise ValueError('{} is not valid date in the format YYYY-MM-DD'.format(date_string))

columns_names = ['_id', '...1', 'id_tweet', 'date', 'text', 'language',
       'possibly_sensitive', 'mentions', 'truncated', 'retweet_count',
       'reply_count', 'like_count', 'quote_count', 'id_user', 'username',
       'verified', 'extended_user', 'regla_de_bulo', 'label', 'dataset',
       'Ironia', 'Odio', 'Dirigido', 'Agresividad', 'others', 'Diversion',
       'Tristeza', 'Enfado', 'Sorpresa', 'Disgusto', 'Miedo', 'Negativo',
       'Neutro', 'Positivo', 'Toxico', 'Muy toxico', 'FAKE', 'POS_tags',
       'POS_entities', 'sentences', 'TFIDF', 'POS_entities_1d', 'POS_tags_1d',
       'TFIDF_1d', 'No ironico', 'REAL', 'fakeness', 'fakeness_probabilities',
       'datesearch', 'name', 'imagen', 'location', 'hashtags']

class MongoService:

    def get_dataset(self, db_name=None, date_start=None, date_end=None, window=None):

        # select db
        if db_name is not None and db_name != 'Todo' and db_name != '0' and db_name != 0:
            db = mongo.cx[db_name]
            collection = db['textual']

            if date_start is not None:
                if date_end is not None and date_end != 'NA':
                    date_end = date_end
                elif window is not None:
                    window = int(window)
                    date_end = date_start + timedelta(days=window)

                # print(date_start, date_end, type(date_end))
                #query = {"datesearch": {"$gte": date_start, "$lte": date_end}}

                query = {
                    "datesearch": {"$gte": date_start, "$lte": date_end},
                    "referenced_tweets": {"$not": {"$elemMatch": {"type": "retweeted"}}}
                }

                data = collection.find(query)
            else:
                # get all
                data = collection.find()

            data = pd.DataFrame(list(data))


        else:
            # get all collections
            data = pd.DataFrame()

            for name_db in mongo.cx.list_database_names():
                db = mongo.cx[name_db]
                collection = db['textual']
                if date_start is not None:
                    if date_end is not None and date_end != 'NA':
                        date_end = date_end
                    elif window is not None:
                        window = int(window)
                        date_end = date_start + timedelta(days=window)
                    #query = {"datesearch": {"$gte": date_start, "$lte": date_end}}

                    query = {
                        "datesearch": {"$gte": date_start, "$lte": date_end},
                        "referenced_tweets": {"$not": {"$elemMatch": {"type": "retweeted"}}}
                    }

                    data_collection = list(collection.find(query))
                else:
                    # get all
                    data_collection = list(collection.find())
                df_collection = pd.DataFrame(data_collection)
                data = pd.concat([data, df_collection], ignore_index=True)

        #data.info()

        if data.empty:
            data = pd.DataFrame(columns=columns_names)
            return data
        else:
            data['datesearch'] = pd.to_datetime(data['datesearch'])

            # select with window and not start
            if window is not None and window != '0' and window != 'Total' and window != 0 and date_start is None:
                if not data.empty:
                    date_start = data.iloc[0]['datesearch']
                window = int(window)
                date_end = date_start + timedelta(days=window)

                data = data[(data['datesearch'] >= date_start) & (data['datesearch'] <= date_end)]

            return data

    def create_dataset(self, json_data, db_name):
        db = mongo.cx[db_name]
        new_coll = db['textual']
        resultado = new_coll.insert_many(json_data)

        if resultado.inserted_ids:
            return {"message": f"Conjunto de datos en collection textual agregado exitosamente a la bd '{db_name}'",
                    "document_ids": [str(_id) for _id in resultado.inserted_ids]}
        else:
            return {"error": "No se pudo agregar el conjunto de datos"}, 500


    def delete_dataset(self, dataset_name):
        db = mongo.cx[dataset_name]
        return db.datasets.delete_one({"name": dataset_name})

    def get_db_names(self):
        return mongo.cx.list_database_names()


