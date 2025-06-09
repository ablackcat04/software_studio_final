import os
import json
from dotenv import load_dotenv
import numpy as np
from openai import OpenAI
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_functions import https_fn

load_dotenv()


# ======================================================================
#                     THE FINAL INITIALIZATION BLOCK
# ======================================================================
# This is the simplest possible way to initialize. It will work for
# local analysis AND when deployed to the cloud.

# Check if the app is already initialized to be absolutely safe.
if not firebase_admin._apps:
    # Use the service account key directly.
    # The Firebase environment will automatically find this when deployed.
    cred = credentials.Certificate('service-account-key.json')
    firebase_admin.initialize_app(cred)

# Initialize services
db = firestore.client()
# Use configured secrets for the API key
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def cosine_sim(a, b):
    # Ensure vectors are numpy arrays for calculations
    a = np.array(a)
    b = np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

@https_fn.on_request() # REMOVED the secrets parameter
def find_similar_memes(req: https_fn.Request) -> https_fn.Response:
    """HTTPS Cloud Function to find memes based on semantic similarity."""
    
    # Allow CORS for requests from any origin (useful for local Flutter web testing)
    headers = {
        "Access-Control-Allow-Origin": "*"
    }

    # Handle preflight CORS requests for web
    if req.method == "OPTIONS":
        options_headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }
        return https_fn.Response("", headers=options_headers, status=204)

    try:
        body = req.get_json()
        query = body.get("query")
        if not query:
            return https_fn.Response("Missing 'query' in request body.", status=400, headers=headers)

        top_k = body.get("top_k", 25)

        # 1. Get embedding for the user's query
        response = client.embeddings.create(input=query, model="text-embedding-ada-002")
        query_embedding = response.data[0].embedding

        # 2. Fetch all memes' data from Firestore
        memes_ref = db.collection("memes").stream()
        
        # 3. Calculate similarities in memory
        sims = []
        for meme_doc in memes_ref:
            meme_data = meme_doc.to_dict()
            if "embedding" in meme_data and "id" in meme_data:
                similarity = cosine_sim(query_embedding, meme_data["embedding"])
                sims.append({
                    "id": meme_data["id"],
                    "description": meme_data.get("description", ""),
                    "score": similarity,
                })

        # 4. Sort and return the top results
        top_results = sorted(sims, key=lambda x: x["score"], reverse=True)[:top_k]
        
        return https_fn.Response(json.dumps(top_results), mimetype="application/json", headers=headers)
    
    except Exception as e:
        print(f"An error occurred: {e}")
        return https_fn.Response(f"Internal Server Error: {e}", status=500, headers=headers)