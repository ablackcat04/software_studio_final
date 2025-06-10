import json
import os
import time
from openai import OpenAI
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core import exceptions as google_exceptions

# --- Configuration ---
BATCH_SIZE = 25
# <<< CHANGE >>> Define the folder name and the path to the JSON
FOLDER_NAME = "mygo" # Change this to "popular" when you run it for the other file
MEME_JSON_PATH = f"./description/mygo.json"
# <<< CHANGE >>> The target sub-collection name within each folder
SUB_COLLECTION_NAME = "memes2" 

FIREBASE_CREDS_PATH = "./ai-meme-suggestion-firebase-adminsdk-fbsvc-1e5209bdbb.json"
EMBEDDING_MODEL = "text-embedding-ada-002"

# --- Initialization ---
print("🔧 Loading environment variables...")
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
print("🔐 OpenAI client initialized.")

print("🔑 Initializing Firebase credentials...")
# Add a check to prevent re-initialization error if run in an interactive session
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CREDS_PATH)
    firebase_admin.initialize_app(cred)
    print("🚀 Firebase App Initialized.")
else:
    print("✅ Firebase App already initialized.")
    
db = firestore.client()
print("📦 Firebase Firestore client ready.")

# --- Load Local JSON ---
print(f"📄 Loading meme data from '{MEME_JSON_PATH}' for folder '{FOLDER_NAME}'...")
with open(MEME_JSON_PATH, "r", encoding="utf-8") as f:
    memes = json.load(f)
total_memes = len(memes)
print(f"🧠 Loaded {total_memes} memes from file.")

# --- Helper Function for Committing with Retry (Your function is great, no changes needed) ---
def commit_batch_with_retry(batch_to_commit, max_retries=5):
    # ... (Your function is perfect) ...
    for attempt in range(max_retries):
        try:
            batch_to_commit.commit()
            return True # Success
        except google_exceptions.Aborted as e:
            print(f"   ⚠️ Firestore contention detected. Retrying... (Attempt {attempt + 1}/{max_retries})")
            time.sleep(2 ** attempt)
        except Exception as e:
            print(f"   ❌ An unexpected error occurred during commit: {e}")
            return False # Unrecoverable error
    
    print(f"   ❌ Failed to commit batch after {max_retries} attempts.")
    return False

# --- Main Processing Loop ---
print(f"\n🚀 Starting to process and upload meme data to Firestore under folder '{FOLDER_NAME}'...")
batch = db.batch()
items_in_current_batch = 0
total_processed = 0
total_skipped = 0
total_failed = 0

for idx, (key, item) in enumerate(list(memes.items()), start=1):
    # <<< CHANGE >>> Construct the correct path to the nested sub-collection
    doc_ref = db.collection("folders").document(FOLDER_NAME).collection(SUB_COLLECTION_NAME).document(key)

    if doc_ref.get().exists:
        print(f"➡️ [{idx}/{total_memes}] SKIPPING: Meme '{key}' already exists in folder '{FOLDER_NAME}'.")
        total_skipped += 1
        continue

    print(f"➡️ [{idx}/{total_memes}] PROCESSING: Meme '{key}' for folder '{FOLDER_NAME}'")
    text = item["文字"] + "\n" + "\n".join(item["使用案例"])

    try:
        print("   ✨ Generating embedding...")
        response = client.embeddings.create(input=text, model=EMBEDDING_MODEL)
        embedding = response.data[0].embedding
        print("   ✅ Embedding generated.")

        # <<< CHANGE >>> Add the crucial 'folder_id' field to the data
        data = {
            "id": key,
            "description": text,
            "embedding": embedding,
            "folder_id": FOLDER_NAME, # This is essential for your Cloud Function query!
        }

        batch.set(doc_ref, data)
        items_in_current_batch += 1
        print(f"   📥 Added '{key}' to batch. (Batch size: {items_in_current_batch}/{BATCH_SIZE})")

    except Exception as e:
        print(f"   ❌ ERROR processing '{key}': {e}")
        print("   Skipping this item and continuing.")
        total_failed += 1
        continue

    # Commit batch when full
    if items_in_current_batch >= BATCH_SIZE:
        print(f"\n💾 Committing batch of {items_in_current_batch} items...")
        
        if commit_batch_with_retry(batch):
            print("   ✅ Batch committed successfully.")
            total_processed += items_in_current_batch
        else:
            print("   🛑 CRITICAL: Could not commit batch. Stopping script to avoid data loss.")
            total_failed += items_in_current_batch
            break 
        
        batch = db.batch()
        items_in_current_batch = 0

# --- Final Commit for any remaining items ---
if items_in_current_batch > 0:
    print(f"\n💾 Committing final batch of {items_in_current_batch} items...")
    
    if commit_batch_with_retry(batch):
        print("   ✅ Final batch committed successfully.")
        total_processed += items_in_current_batch
    else:
        print("   🛑 CRITICAL: Could not commit the final batch.")
        total_failed += items_in_current_batch
else:
    print("\nNo remaining items to commit in the final batch.")

print("\n--- 🏁 All Done! ---")
print(f"✅ Total items successfully processed and uploaded: {total_processed}")
print(f"⏭️  Total items skipped (already existed): {total_skipped}")
print(f"❌ Total items failed (due to errors or commit failures): {total_failed}")
print(f"--------------------")
print(f"Total items in source file: {total_memes}")