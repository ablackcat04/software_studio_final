import os
import json
import numpy as np
from openai import OpenAI
import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn

# Initialize services
firebase_admin.initialize_app()
db = firestore.client()
# Set your OpenAI key as a secret in Firebase: `firebase functions:secrets:set OPENAI_API_KEY`
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def cosine_sim(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

@https_fn.on_request()
def find_similar_memes(req: https_fn.Request) -> https_fn.Response:
    query = req.get_json().get("query")
    if not query:
        return https_fn.Response("Missing 'query' in request body.", status=400)

    # 1. Get embedding for the user's query
    response = client.embeddings.create(input=query, model="text-embedding-ada-002")
    query_embedding = response.data[0].embedding

    # 2. Fetch all memes' data from Firestore
    memes_ref = db.collection("memes").stream()
    
    # 3. Calculate similarities in memory
    sims = []
    for meme_doc in memes_ref:
        meme_data = meme_doc.to_dict()
        similarity = cosine_sim(query_embedding, meme_data["embedding"])
        sims.append({
            "id": meme_data["id"], # The most important piece of data to return!
            "description": meme_data["description"],
            "score": similarity,
        })

    # 4. Sort and return the top 25 results
    top_results = sorted(sims, key=lambda x: x["score"], reverse=True)[:25]

    # Return a JSON list of the top results
    return https_fn.Response(json.dumps(top_results), mimetype="application/json")