import json
import os
from openai import OpenAI
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

# --- Initialization ---
print("🔧 Loading environment variables...")
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
print("🔐 OpenAI client initialized.")

print("🔑 Initializing Firebase credentials...")
cred = credentials.Certificate("../backend/ai-meme-suggestion-firebase-adminsdk-fbsvc-1e5209bdbb.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
print("📦 Firebase Firestore client ready.")

# --- Load Local JSON ---
print("📄 Loading meme data from JSON file...")
with open("../assets/images/new/description/mygo.json", "r", encoding="utf-8") as f:
    memes = json.load(f)
print(f"🧠 Loaded {len(memes)} memes from file.")

print("🚀 Starting to process and upload meme data to Firestore...")
batch = db.batch()

for idx, (key, item) in enumerate(memes.items(), start=1):
    print(f"➡️ [{idx}/{len(memes)}] Processing meme: {key}")
    text = item["文字"] + "\n" + "\n".join(item["使用案例"])

    print("   ✨ Generating embedding...")
    response = client.embeddings.create(input=text, model="text-embedding-ada-002")
    embedding = response.data[0].embedding
    print("   ✅ Embedding generated.")

    doc_ref = db.collection("new_memes").document(key)

    data = {
        "id": key,
        "description": text,
        "embedding": embedding,
    }

    batch.set(doc_ref, data)
    print("   📥 Prepared batch write for Firestore.")

print("💾 Committing batch to Firestore...")
batch.commit()
print(f"✅ Successfully uploaded data for {len(memes)} memes to Firestore.")
