import json
import os
import numpy as np
from openai import OpenAI
from dotenv import load_dotenv

# ✅ 初始化
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ✅ 載入資料
with open("../assets/images/basic/description/mygo.json", "r", encoding="utf-8") as f:
    memes = json.load(f)

# ✅ 把每筆資料做成 embedding + 保留原始內容
docs = []
for key, item in memes.items():
    text = item["文字"] + "\n" + "\n".join(item["使用案例"])

    response = client.embeddings.create(
        input=text,
        model="text-embedding-ada-002"
    )
    embedding = response.data[0].embedding

    docs.append({
        "id": key,
        "text": text,
        "embedding": embedding,
        "image_path": f"../assets/images/basic/{key}.jpg"
    })

print(f"✅ 載入並計算完成 {len(docs)} 筆資料")

# ✅ 查詢階段
def cosine_sim(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

def search(query, top_k=4):
    response = client.embeddings.create(
        input=query,
        model="text-embedding-ada-002"
    )
    q_vec = response.data[0].embedding

    sims = [
        (doc["id"], cosine_sim(q_vec, doc["embedding"]), doc["image_path"])
        for doc in docs
    ]
    top = sorted(sims, key=lambda x: x[1], reverse=True)[:top_k]
    return top

# ✅ 測試：輸入一段話
while True:
    user_input = input("\n請輸入一段文字查梗圖（或 q 離開）:\n> ")
    if user_input.lower() == "q":
        break

    results = search(user_input)
    print("\n🔍 匹配結果：")
    for i, (id, score, path) in enumerate(results):
        print(f"{i+1}. 圖片 ID: {id}, 相似度: {score:.4f}, 圖片路徑: {path}")
