# main.py

import os
import json
from dotenv import load_dotenv
import numpy as np
from openai import OpenAI
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_functions import https_fn

# ... (your other initializations) ...
if not firebase_admin._apps:
    cred = credentials.Certificate('service-account-key.json')
    firebase_admin.initialize_app(cred)
db = firestore.client()
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def cosine_sim(a, b):
    a = np.array(a)
    b = np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# <<< START OF CORRECTED FUNCTION >>>
@https_fn.on_request()
def find_similar_memes_v2(req: https_fn.Request) -> https_fn.Response:
    
    # --- This CORS handling part is still correct and necessary ---
    if req.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }
        return https_fn.Response("", headers=headers, status=204)

    headers = { "Access-Control-Allow-Origin": "*" }

    # --- The main logic with the fix ---
    try:
        # <<< THIS IS THE FIX >>>
        # Use force=True to bypass strict header checking and ensure the body is parsed as JSON.
        body = req.get_json(force=True) 
        
        query = body.get("query")
        if not query:
            return https_fn.Response("Missing 'query' in request body.", status=400, headers=headers)

        # ... The rest of your function logic is correct and does not need to change ...
        top_k = body.get("top_k", 25)
        enabled_folders = body.get("enabled_folders")
        
        if not enabled_folders or 'all' in enabled_folders:
            enabled_folders = ['mygo', 'popular']

        response = client.embeddings.create(input=query, model="text-embedding-ada-002")
        query_embedding = response.data[0].embedding

        memes_query = db.collection_group("items").where('folder_id', 'in', enabled_folders)

        sims = []
        for meme_doc in memes_query.stream():
            meme_data = meme_doc.to_dict()
            if "embedding" in meme_data and "id" in meme_data:
                similarity = cosine_sim(query_embedding, meme_data["embedding"])
                folder_name = meme_doc.reference.parent.parent.id
                sims.append({
                    "id": meme_data["id"],
                    "description": meme_data.get("description", ""),
                    "score": similarity,
                    "folderName": folder_name,
                })

        top_results = sorted(sims, key=lambda x: x["score"], reverse=True)[:top_k]
        
        return https_fn.Response(json.dumps(top_results), mimetype="application/json", headers=headers)
    
    except Exception as e:
        print(f"An error occurred: {e}")
        return https_fn.Response(f"Internal Server Error: {e}", status=500, headers=headers)
