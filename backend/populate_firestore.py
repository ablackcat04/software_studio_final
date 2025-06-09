import json
import os
import time
from openai import OpenAI
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core import exceptions as google_exceptions # Import exceptions

# --- Configuration ---
BATCH_SIZE = 25
MEME_JSON_PATH = "../assets/images/new/description/mygo.json"
FIREBASE_CREDS_PATH = "./ai-meme-suggestion-firebase-adminsdk-fbsvc-1e5209bdbb.json"
FIRESTORE_COLLECTION = "new_memes"
EMBEDDING_MODEL = "text-embedding-ada-002"

# --- Initialization ---
print("🔧 Loading environment variables...")
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
print("🔐 OpenAI client initialized.")

print("🔑 Initializing Firebase credentials...")
cred = credentials.Certificate(FIREBASE_CREDS_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()
print("📦 Firebase Firestore client ready.")

# --- Load Local JSON ---
print(f"📄 Loading meme data from '{MEME_JSON_PATH}'...")
with open(MEME_JSON_PATH, "r", encoding="utf-8") as f:
    memes = json.load(f)
total_memes = len(memes)
print(f"🧠 Loaded {total_memes} memes from file.")

# --- Helper Function for Committing with Retry ---
# We create a helper function to avoid repeating the retry code.
def commit_batch_with_retry(batch_to_commit, max_retries=5):
    """Tries to commit a batch, retrying on contention errors with exponential backoff."""
    for attempt in range(max_retries):
        try:
            batch_to_commit.commit()
            return True # Success
        except google_exceptions.Aborted as e:
            print(f"   ⚠️ Firestore contention detected. Retrying... (Attempt {attempt + 1}/{max_retries})")
            # Exponential backoff: 1s, 2s, 4s, 8s, ...
            time.sleep(2 ** attempt)
        except Exception as e:
            print(f"   ❌ An unexpected error occurred during commit: {e}")
            return False # Unrecoverable error
    
    print(f"   ❌ Failed to commit batch after {max_retries} attempts.")
    return False # Failed after all retries

# --- Main Processing Loop ---
print("\n🚀 Starting to process and upload meme data to Firestore...")
batch = db.batch()
items_in_current_batch = 0
total_processed = 0
total_skipped = 0
total_failed = 0

for idx, (key, item) in enumerate(list(memes.items()), start=1):
    doc_ref = db.collection(FIRESTORE_COLLECTION).document(key)

    if doc_ref.get().exists:
        print(f"➡️ [{idx}/{total_memes}] SKIPPING: Meme '{key}' already exists in Firestore.")
        total_skipped += 1
        continue

    print(f"➡️ [{idx}/{total_memes}] PROCESSING: Meme '{key}'")
    text = item["文字"] + "\n" + "\n".join(item["使用案例"])

    try:
        print("   ✨ Generating embedding...")
        response = client.embeddings.create(input=text, model=EMBEDDING_MODEL)
        embedding = response.data[0].embedding
        print("   ✅ Embedding generated.")

        data = {
            "id": key,
            "description": text,
            "embedding": embedding,
        }

        batch.set(doc_ref, data)
        items_in_current_batch += 1
        print(f"   📥 Added '{key}' to batch. (Batch size: {items_in_current_batch}/{BATCH_SIZE})")

    except Exception as e:
        print(f"   ❌ ERROR processing '{key}': {e}")
        print("   Skipping this item and continuing.")
        total_failed += 1
        continue

    if items_in_current_batch >= BATCH_SIZE:
        print(f"\n💾 Committing batch of {items_in_current_batch} items...")
        
        # --- MODIFICATION: Use the retry function ---
        if commit_batch_with_retry(batch):
            print("   ✅ Batch committed successfully.")
            total_processed += items_in_current_batch
        else:
            print("   🛑 CRITICAL: Could not commit batch. Stopping script to avoid data loss.")
            total_failed += items_in_current_batch
            # You might want to break here to investigate the problem
            break 
        
        # Reset for the next batch
        batch = db.batch()
        items_in_current_batch = 0
        

# --- Final Commit ---
if items_in_current_batch > 0:
    print(f"\n💾 Committing final batch of {items_in_current_batch} items...")
    
    # --- MODIFICATION: Use the retry function here as well ---
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