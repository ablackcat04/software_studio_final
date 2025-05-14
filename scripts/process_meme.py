import google.generativeai as genai
import os
import json
import time
from pathlib import Path
import re
# from PIL import Image # 如果遇到圖片格式問題，可能需要 PIL

# --- 配置 START ---
# 圖片資料夾路徑：請修改為你的實際路徑
IMAGE_FOLDER_PATH = r"."
# 輸出 JSON 檔案名稱與路徑：預設與腳本同目錄
OUTPUT_JSON_FILE = "meme_data.json"
# 錯誤日誌檔案名稱：預設與腳本同目錄
ERROR_LOG_FILE = "error_log.txt"
# 使用的 Gemini 模型名稱
MODEL_NAME = "gemini-2.5-flash-preview-04-17" # 或其他你指定的 preview 版本，例如 "gemini-1.5-flash-preview-0514"
# 儲存 Google Gemini API 金鑰的環境變數名稱
API_KEY_ENV_VAR = "GOOGLE_API_KEY"

# API 限制相關
# 每次批次請求之間的延遲秒數。用於遵守速率限制或避免請求過於頻繁。
# 即使是批次請求，也建議設定一個延遲。
BATCH_REQUEST_DELAY_SECONDS = 1 # 每次處理完一個批次後等待的秒數
# 每次運行腳本時一個批次最多處理的新圖片數量
MAX_IMAGES_PER_RUN = 30

# Prompt (已修改以適應多圖輸入和單一包含多個ID的JSON輸出)
SYSTEM_PROMPT_MULTI_IMAGE = """
Your Role:
You are a specialized AI component for a meme suggestion application. Your primary function is to analyze provided meme information from **multiple images** and their corresponding IDs, and then generate a **single structured JSON output** detailing **all** the memes in the batch.



Your Task:
You will receive a batch of inputs, where each image is introduced by a text block specifying its unique numerical ID. You **must** analyze **each** provided image based on its preceding ID. Your output **must be a single JSON object** that contains results for **all** images provided in this batch.

The output JSON object will have multiple top-level keys. Each key **must be the provided ID for one of the images, converted to a string, with no padding zeros** (e.g., if the ID is `1`, the key is `"1"`; if the ID is `42`, the key is `"42"`).
*IMPORTANT: Every item should contains enough information, no dependency on other item. 不要什麼場景與 ID 32 相似，請把他們都展開的寫出來
*IMPORTANT: Every item should contains enough information, no dependency on other item. 不要什麼畫面延續ID 2的場景，請把他們都展開的寫出來，因為我們的系統會用RAG抓單獨得出來，所以他們自己要能夠讓別人知道該有的訊息。如果出現任何單獨拿出來無法知道全部訊息的情形，就會有人死掉


The value associated with each ID key will be another JSON object containing the meme's details, structured as follows:

```json
{
  "文字": "STRING_VALUE",
  "角色": ["STRING_VALUE_1", "STRING_VALUE_2", ...],
  "描述": "STRING_VALUE",
  "使用案例": ["STRING_VALUE_1", "STRING_VALUE_2", ...]
}
```

Detailed Instructions for each field within the value object (these apply to the details for each individual meme):

1.  `文字` (Text):
    *   Type: String.
    *   Content: List all discernible text present in the meme.
    *   If there is no text in the meme, this field should be an empty string (`""`).
    *   Language: If text is present, transcribe it as accurately as possible. If it's in Chinese, use Traditional Chinese.

2.  `角色` (Character(s)):
    *   Type: Array of Strings.
    *   Content: Identify the character(s) appearing in the meme. You **must** use only the names from the provided list below.
    *   Character List (Name (Hair Color/Distinguishing Features)):
        *   `高松燈` (深紫色or灰色頭髮)
        *   `千早愛音` (粉色頭髮)
        *   `椎名立希` (黑色頭髮)
        *   `長崎爽世` (棕色頭髮)
        *   `要樂奈` (白色頭髮)
        *   `若葉睦` (淺綠色頭髮)
        *   `豐川祥子` (淺藍色頭髮)
        *   `三角初華` (淺黃色頭髮)
        *   `八幡海玲` (黑色頭髮)
        *   `若天寺若麥` (紫色頭髮、穿著較高松燈時尚、幾乎不會穿校服)
    *   Consider the impact of lighting/art style on hair color when making your identification.
    *   If multiple characters from the list are present, include all their names in the array.
    *   If no characters from the list are identifiable, or if the characters are not on this list, use an empty array (`[]`).

3.  `描述` (Description):
    *   Type: String.
    *   Content: Provide a comprehensive and engaging description of the meme. This should include visual elements, character expressions, setting, overall mood, and any implied narrative or context.
    *   Length: Approximately 200 to 500 **Chinese characters**.
    *   Language: **Traditional Chinese**.
    *   請位每個meme做單獨的描述，即使他們是某個畫面的延續，因為我們的系統需要每個單獨的meme description都能獨自存在。不這樣做的話，有人會死掉

4.  `使用案例` (Use Cases):
    *   Type: Array of Strings.
    *   Content: List 3 to 6 distinct, practical, and common ways the meme is used or could be used in online communication or real-life scenarios.
    *   Language: **Traditional Chinese**.
    *   Each use case should be a concise phrase or sentence.

Input Structure:
You will receive a sequence of content parts. The first part is this introductory text. Subsequent parts will alternate between a text block indicating an ID and its corresponding image. Example sequence for two images with IDs 1 and 42:
[
  This instruction text part,
  Text part: "--- START IMAGE FOR ID: 1 ---\nAnalyze the following image...",
  Image part for ID 1,
  Text part: "--- START IMAGE FOR ID: 42 ---\nAnalyze the following image...",
  Image part for ID 42,
  ... (more pairs for other images in the batch)
  Optional final text part reinforcing JSON output requirement.
]

Your Expected Output MUST be a single JSON object containing keys for ALL provided IDs in this batch, like:
```json
{
  "1": {
    "文字": "...",
    "角色": [...],
    "描述": "...",
    "使用案例": [...]
  },
  "42": {
    "文字": "...",
    "角色": [...],
    "描述": "...",
    "使用案例": [...]
  },
  // ... results for all other IDs in the batch
}
```

Key Reminders:
*   Generate only ONE JSON object for the entire batch.
*   The top-level keys of the JSON object MUST be the string IDs provided for each image.
*   Ensure the structure for the value of each ID key strictly follows the specified format (`文字`, `角色`, etc.).
*   Ensure all content for `描述` and `使用案例` is in **Traditional Chinese**.
*   Pay close attention to the character list and identification guidelines.
*   Do not include any text outside the JSON object in your response.
*   Every item should contains enough information, no dependency on other item. 不要什麼場景與 ID 32 相似，請把他們都展開的寫出來
*   IMPORTANT: Every item should contains enough information, no dependency on other item. 不要什麼畫面延續ID 2的場景，請把他們都展開的寫出來，因為我們的系統會用RAG抓單獨得出來，所以他們自己要能夠讓別人知道該有的訊息

"""
# --- 配置 END ---

def log_error(message):
    """記錄錯誤到日誌檔案"""
    try:
        with open(ERROR_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")
        print(f"Error: {message}")
    except Exception as e:
        print(f"Error logging message: {message} - Failed to write to log file: {e}")


def load_existing_data(json_file_path):
    """載入已存在的 JSON 資料"""
    if os.path.exists(json_file_path):
        try:
            with open(json_file_path, "r", encoding="utf-8") as f:
                content = f.read()
                if not content:
                    print(f"警告：JSON 檔案 {json_file_path} 是空的。")
                    return {}
                return json.loads(content)
        except json.JSONDecodeError:
            log_error(f"無法解析現有的 JSON 檔案: {json_file_path}。請檢查檔案內容。將視為空檔案。")
            # 為了續跑機制不被損壞的檔案阻礙，如果解析失敗，我們返回空字典，下次從頭嘗試處理所有圖片
            # 但這會導致之前成功的數據丟失，更好的做法是備份，但這使腳本複雜化。
            # 暫時採用返回空字典並記錄錯誤。
            return {}
        except FileNotFoundError: # Should not happen due to os.path.exists
             return {}
        except Exception as e:
            log_error(f"讀取現有 JSON 檔案時發生錯誤: {e}。將視為空檔案。")
            return {}
    return {}

def save_data(data, json_file_path):
    """安全地儲存 JSON 資料 (先寫入暫存，再重命名)"""
    temp_file_path = json_file_path + ".tmp"
    try:
        with open(temp_file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2) # indent=2 for readability
        os.replace(temp_file_path, json_file_path) # 原子操作替換
        # print(f"資料已成功儲存到 {json_file_path}") # Comment out for less verbose output
    except Exception as e:
        log_error(f"儲存 JSON 資料到 {json_file_path} 失敗: {e}")
        if os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception as remove_e:
                log_error(f"儲存失敗後移除暫存檔案 {temp_file_path} 失敗: {remove_e}")

def get_image_files_and_ids(folder_path):
    """獲取資料夾中所有 .webp 圖片的路徑和對應的 ID，並按 ID 排序"""
    image_paths_with_ids = []
    if not os.path.isdir(folder_path):
        log_error(f"圖片資料夾路徑不存在或不是一個資料夾: {folder_path}")
        return []

    try:
        for filename in os.listdir(folder_path):
            if filename.lower().endswith(".webp"):
                match = re.match(r"(\d+)\.webp$", filename, re.IGNORECASE)
                if match:
                    try:
                        image_id = int(match.group(1))
                        image_paths_with_ids.append({"id": image_id, "path": os.path.join(folder_path, filename)})
                    except ValueError: # Should not happen with \d+ match, but good practice
                         log_error(f"檔案 {filename} 提取的 ID 無法轉換為數字，已跳過。")
                else:
                    log_error(f"檔案 {filename} 不符合 '數字.webp' 格式，已跳過。")
    except Exception as e:
         log_error(f"遍歷圖片資料夾時發生錯誤: {e}")
         return []

    # 按 ID 排序
    image_paths_with_ids.sort(key=lambda x: x["id"])
    return image_paths_with_ids

def process_batch_with_gemini(batch_info, model):
    """
    使用 Gemini API 處理一批圖片 (單次 API 呼叫)。
    返回 AI 解析後的包含多個 ID 結果的字典，如果失敗則返回 None。
    同時返回成功上傳的圖片 part 列表，以便 finally 區塊清理。
    """
    # 在函數內部重新生成 batch_id_strs，這是該函數的局部變數
    batch_ids = [info['id'] for info in batch_info]
    batch_id_strs = [str(id) for id in batch_ids]
    print(f"\n--- 開始處理批次，包含 ID: {', '.join(batch_id_strs)} ---")

    # 組合發送給模型的內容列表，直接使用字串表示文字部分
    content = [
        SYSTEM_PROMPT_MULTI_IMAGE, # 主要Prompt (作為第一個文字部分)
        f"本批次處理的 ID 列表為: [{', '.join(batch_id_strs)}]. 請為每一個 ID 生成 JSON 描述，並合併到單一個 JSON 物件中。\n", # 額外文字指示
    ]

    uploaded_image_parts = []
    try:
        # 準備多個圖片和對應的文字部分
        images_added_to_content = 0
        for i, img_info in enumerate(batch_info):
            image_id_int = img_info["id"]
            image_id_str = str(image_id_int)
            image_path = img_info["path"]

            try:
                 # 上傳圖片並獲取 Part 對象
                 img_part = genai.upload_file(path=image_path)
                 uploaded_image_parts.append(img_part) # 儲存以便後續刪除
                 print(f"  圖片 {i+1} 上傳成功!")

                 # 添加圖片前的文字指示，明確這是哪個 ID 的圖片
                 # 直接使用字串作為文字部分
                 content.append(f"--- START IMAGE FOR ID: {image_id_str} ---\n請根據此圖片為 ID '{image_id_str}' 提供 JSON 描述。\n")
                 content.append(img_part) # 添加圖片本身
                 images_added_to_content += 1

            except Exception as e:
                # 如果某張圖片上傳失敗，記錄錯誤並跳過這張圖片，繼續處理批次中的其他圖片
                # 注意：這裡跳過的是將圖片添加到 content 列表，API 呼叫時就不會包含這張圖片。
                # 但 upload_file 可能已經成功，所以仍然會添加到 uploaded_image_parts 以便清理。
                log_error(f"批次 ID: {', '.join(batch_id_strs)}. 上傳或準備圖片 {Path(image_path).name} (ID {image_id_str}) 失敗: {e}. 此圖片將被跳過處理。")


        # 如果沒有任何圖片成功添加到 content 列表，則整個批次無法處理
        # content 中至少應該有 2 個文字 part (SYSTEM_PROMPT + 額外指示) + 至少一個圖片+文字對 (2個 part)
        # 總計至少 4 個 part 才能構成一個包含圖片的有效請求
        if images_added_to_content == 0:
             log_error(f"批次 ID: {', '.join(batch_id_strs)}. 沒有任何圖片成功添加到請求內容中，取消批次處理。")
             # 即使沒有成功添加到 content，uploaded_image_parts 可能還有需要清理的，由 finally 處理
             return None, uploaded_image_parts


        # 添加結束語句，再次提醒 JSON 格式要求
        # 直接使用字串作為文字部分
        content.append("\n--- END OF IMAGES ---\n請確保您的回應是一個單一的 JSON 物件，包含了所有成功處理的圖片的描述。")


        # 呼叫 Gemini API (單次呼叫處理所有內容)
        print(f"  正在向 Gemini 發送包含 {images_added_to_content} 張圖片的批次請求...")
        # 安全設定可以根據需求調整，這裡使用預設
        # generation_config 可以調整 temperature 等參數
        response = model.generate_content(
            content,
            generation_config=genai.types.GenerationConfig(temperature=0.7),
             safety_settings={ # 這裡可以覆寫預設安全設定，如果需要
                 # harmonizer.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: harmonizer.HarmBlockThreshold.BLOCK_NONE,
                 # harmonizer.HarmCategory.HARM_CATEGORY_HATE_SPEECH: harmonizer.HarmBlockThreshold.BLOCK_NONE,
                 # harmonizer.HarmCategory.HARM_CATEGORY_HARASSMENT: harmonizer.HarmBlockThreshold.BLOCK_NONE,
                 # harmonizer.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: harmonizer.HarmBlockThreshold.BLOCK_NONE,
            }
        )

        # 如果請求因為安全設置等原因被阻擋
        # 檢查 response._result 是否存在且有效
        if not hasattr(response, '_result') or not response._result or not response._result.candidates:
             block_reason = "未知原因"
             if hasattr(response, '_result') and response._result and response._result.prompt_feedback and response._result.prompt_feedback.block_reason:
                 block_reason = response._result.prompt_feedback.block_reason
             log_error(f"批次 ID: {', '.join(batch_id_strs)}. 批次請求被阻止或無有效回應。原因: {block_reason}. 回應原始內容: {response}")
             return None, uploaded_image_parts

        # 獲取 AI 的文字回應
        response_text = response.text

        # 清理 Gemini 可能回傳的 markdown JSON格式標籤
        cleaned_response_text = response_text.strip()
        if cleaned_response_text.startswith("```json"):
            cleaned_response_text = cleaned_response_text[len("```json"):]
        if cleaned_response_text.endswith("```"):
            cleaned_response_text = cleaned_response_text[:-len("```")]
        cleaned_response_text = cleaned_response_text.strip()

        # 嘗試解析 AI 回傳的 JSON (預期是一個包含多個 ID 鍵的字典)
        try:
            api_results = json.loads(cleaned_response_text)
        except json.JSONDecodeError as e:
            log_error(f"批次 ID: {', '.join(batch_id_strs)}. 無法解析 Gemini API 的 JSON 回應。錯誤: {e}. 回應原始: {response_text[:500] if 'response_text' in locals() else '無法獲取回應文字'}")
            return None, uploaded_image_parts # JSON 解析失敗，返回 None


        # 驗證返回的頂層結構是否符合預期：一個字典
        if not isinstance(api_results, dict):
            log_error(f"批次 ID: {', '.join(batch_id_strs)}. API 回應解析後不是一個頂層字典. 回應原始: {response_text[:500]}...")
            return None, uploaded_image_parts

        print(f"  批次請求成功，已收到 {len(api_results)} 個頂層鍵 (不保證是所有請求的圖片數量)。")
        # 返回解析後的字典和上傳的圖片 part 列表
        return api_results, uploaded_image_parts

    except genai.types.generation_types.StopCandidateException as e:
        log_error(f"批次 ID: {', '.join(batch_id_strs)}. Gemini API 批次請求因內容或其他原因被停止 (StopCandidateException): {e}")
        return None, uploaded_image_parts
    except Exception as e:
        error_message = str(e)
        # 嘗試獲取更詳細的錯誤信息，特別是來自 API 回應的
        if hasattr(e, 'response') and e.response is not None:
            if hasattr(e.response, 'text'):
                error_message += f" - API Response Text: {e.response.text[:500]}"
            elif hasattr(e.response, 'json'):
                 try:
                      error_message += f" - API Response JSON: {json.dumps(e.response.json())[:500]}"
                 except:
                      pass # Ignore json parsing error here
        log_error(f"批次 ID: {', '.join(batch_id_strs)}. 呼叫 Gemini API 時發生錯誤: {error_message}")
        return None, uploaded_image_parts

    finally:
        # 清理所有上傳的臨時檔案
        print(f"  正在刪除批次中所有臨時上傳檔案 ({len(uploaded_image_parts)} 個)...")
        for img_part in uploaded_image_parts:
             try:
                 # print(f"    Deleting file: {img_part.name}") # Optional: print which file is being deleted
                 img_part.delete()
             except Exception as del_e:
                 # 即使刪除失敗，也要記錄並繼續刪除其他的
                 log_error(f"批次 ID: {', '.join(batch_id_strs) if 'batch_id_strs' in locals() else 'Unknown Batch'}. 刪除臨時上傳檔案 ({getattr(img_part, 'name', 'N/A')}) 失敗: {del_e}")
        # print(f"  批次中所有臨時上傳檔案刪除完成。")


def main():
    """主執行函數"""
    # 1. 檢查 API 金鑰
    api_key = os.getenv(API_KEY_ENV_VAR)
    if not api_key:
        print(f"錯誤：請設定環境變數 {API_KEY_ENV_VAR} 並填入您的 Google Gemini API 金鑰。")
        print("設定方法範例：")
        print("  Windows (cmd): setx GOOGLE_API_KEY \"YOUR_API_KEY\" (可能需要重開終端)")
        print("  Linux/macOS (bash/zsh): export GOOGLE_API_KEY=\"YOUR_API_KEY\" (加入到 .bashrc/.zshrc 使其永久生效)")
        return

    # 2. 配置 Gemini API
    try:
        genai.configure(api_key=api_key)
        # 測試連線和模型可用性 (可選，但有助於早期發現問題)
        model = genai.GenerativeModel(MODEL_NAME)
        # model.generate_content("Ping", generation_config=genai.types.GenerationConfig(max_output_tokens=1))
        print(f"已成功配置 Gemini API，使用模型: {MODEL_NAME}")
    except Exception as e:
        log_error(f"配置或驗證 Gemini API 失敗: {e}")
        print("請檢查您的 API 金鑰是否正確以及網路連線。")
        return

    # 3. 獲取所有圖片檔案並排序 (只需要讀取一次檔案系統)
    image_files = get_image_files_and_ids(IMAGE_FOLDER_PATH)

    if not image_files:
        print(f"在指定的資料夾 ({IMAGE_FOLDER_PATH}) 中沒有找到符合 '數字.webp' 格式的圖片檔案。")
        return

    total_found_images = len(image_files)
    print(f"\n總共找到 {total_found_images} 張圖片檔案。")

    # 主處理迴圈：只要還有未處理的圖片，就繼續處理下一個批次
    processed_count_overall = 0 # 總共成功處理的圖片數量
    while True:
        # 4. 載入現有資料並獲取已處理 ID (每次迴圈開始都重新載入，確保讀取到上次循環保存的最新狀態)
        all_data = load_existing_data(OUTPUT_JSON_FILE)
        processed_ids = set(all_data.keys()) # 已處理的 ID 集合 (字串形式)
        processed_count_overall = len(processed_ids)

        # 5. 找出需要處理的新檔案
        new_files_to_process = []
        for img_info in image_files:
            image_id_str = str(img_info["id"])
            # 只處理那些是 '數字.webp' 格式且 ID 不在已處理列表中的圖片
            if image_id_str not in processed_ids and f"{img_info['id']}.webp" in os.path.basename(img_info['path']).lower():
                 new_files_to_process.append(img_info)

        total_new_images_remaining = len(new_files_to_process)

        print(f"\n--- 運行狀態 ---")
        print(f"總共找到圖片檔案: {total_found_images} 張")
        print(f"已處理圖片數量: {processed_count_overall} 張")
        print(f"剩餘新的圖片數量: {total_new_images_remaining} 張")

        # 6. 如果沒有新的圖片需要處理，則退出迴圈
        if not new_files_to_process:
            print("\n所有新的圖片檔案均已處理完畢。")
            break # 退出 while 迴圈

        # 7. 組成本次要處理的批次
        batch_for_this_run = new_files_to_process[:MAX_IMAGES_PER_RUN]
        batch_ids_in_run = [str(info['id']) for info in batch_for_this_run] # 本次批次嘗試處理的 ID (字串形式)

        print(f"\n本次運行將嘗試處理一個包含 {len(batch_for_this_run)} 張新圖片的批次 (批次上限為 {MAX_IMAGES_PER_RUN})。")
        print(f"本次批次包含的 ID: {', '.join(batch_ids_in_run)}")

        # 8. 處理批次圖片
        # process_batch_with_gemini 返回結果字典和上傳的 parts 列表
        batch_results, uploaded_parts = process_batch_with_gemini(batch_for_this_run, model)


        # 9. 處理批次結果並保存
        successful_count_in_batch = 0
        processed_ids_in_batch_response = set() # 記錄 API 回應中包含了哪些有效結果的 ID

        if batch_results is not None:
            print("\n--- 正在處理批次結果 ---")
            # 遍歷 API 回應中的每一個結果 (以 ID 字串為鍵)
            for api_id_str, meme_details in batch_results.items():
                # 驗證這個 ID 是否是我們本次批次請求中預期嘗試處理的 ID 之一
                # 並且驗證單個結果的格式是否符合預期
                if api_id_str in batch_ids_in_run: # 確保是本次請求範圍內的 ID
                    if isinstance(meme_details, dict) and all(key in meme_details for key in ["文字", "角色", "描述", "使用案例"]):
                        all_data[api_id_str] = meme_details
                        successful_count_in_batch += 1
                        processed_ids_in_batch_response.add(api_id_str)
                        # print(f"  ID {api_id_str} 的結果已成功解析並暫存。") # Comment out for less verbose output
                    else:
                        log_error(f"批次處理成功但 API 回應中 ID {api_id_str} 的結果格式不符 (應為字典且包含關鍵鍵)，已忽略。結果內容類型: {type(meme_details)}. 結果內容: {json.dumps(meme_details)[:500]}")
                # else:
                     # print(f"  警告: API 回應中包含非本次批次請求的 ID ({api_id_str})，已忽略。") # 這種情況比較少見，可選擇記錄或忽略

            # 檢查是否有本次請求的圖片但結果在 API 回應中缺失 (指那些在 batch_ids_in_run 裡但不在 processed_ids_in_batch_response 裡的 ID)
            missing_ids_in_response = set(batch_ids_in_run) - processed_ids_in_batch_response
            for missing_id in missing_ids_in_response:
                 # 我們只記錄那些是本次批次請求的 ID，但 AI 回應中沒有成功解析結果的
                 log_error(f"批次處理成功但 API 回應 JSON 中缺失了本次請求的 ID {missing_id} 的有效結果。")


            # 在處理完批次中所有圖片的結果後，一次性保存
            if successful_count_in_batch > 0:
                 save_data(all_data, OUTPUT_JSON_FILE)
                 # processed_ids 在下一次迴圈開始時會重新從檔案載入，所以這裡不需要手動更新 processed_ids set
                 print(f"\n成功處理 {successful_count_in_batch} 張圖片的結果，資料已保存到 {OUTPUT_JSON_FILE}。")
            else:
                 # 如果 batch_results is not None 但 successful_count_in_batch 是 0，說明 API 回應是有效的 JSON 格式，
                 # 但其中沒有任何一個 ID 的結果符合我們的預期格式。
                 print("\n批次請求成功並收到回應，但沒有解析到任何有效的圖片結果。資料未保存。")

        else:
            # 批次請求完全失敗 (API 錯誤, JSON 解析錯誤等)
            print(f"\n批次處理失敗。批次中所有圖片將在下次運行時重新嘗試。")
            # process_batch_with_gemini 中已記錄錯誤

        # 10. 批次間延遲
        # 只有在本次成功處理了圖片 (即 processed_count_overall > 上次迴圈的 processed_count_overall)
        # 或者本次處理的批次數量少於總剩餘數量 (說明還有下一個批次)
        # 並且還有新的圖片需要處理時，才進行延遲
        # 判斷是否還有下一個批次：如果本次嘗試處理的數量等於 batch_for_this_run 的長度，且還有剩餘新的圖片
        has_more_batches = len(batch_for_this_run) == MAX_IMAGES_PER_RUN and total_new_images_remaining > MAX_IMAGES_PER_RUN

        if total_new_images_remaining > successful_count_in_batch : # 如果本次處理後還有新的圖片待處理
            print(f"\n完成一個批次處理。等待 {BATCH_REQUEST_DELAY_SECONDS} 秒後處理下一個批次...")
            time.sleep(BATCH_REQUEST_DELAY_SECONDS)
        else:
             # 如果本次處理後所有圖片都處理完了，或者剩下的不足一個批次且本次已處理完，則不需要延遲
             print("\n本次處理後已無新的圖片或已處理完所有圖片。")
             # 這裡不需要額外的 break，迴圈會在下一次檢查 total_new_images_remaining 時退出


    # 迴圈結束，打印最終總結
    print(f"\n=== 所有批次處理完成 ===")
    print(f"總共成功處理的圖片數量: {len(all_data)} 張。") # final check from the saved data
    print(f"錯誤記錄請查看檔案: {ERROR_LOG_FILE}")


if __name__ == "__main__":
    main()