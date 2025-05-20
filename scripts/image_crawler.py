import os, time, json, re, requests
from urllib.parse import urljoin, urlparse
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

BASE_URL = "https://mygo.0m0.uk/"
DOWNLOAD_DIR = "downloaded_images"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

#─── 1) ChromeOptions + Performance Log ────────────────────────────────
opts = Options()
opts.add_argument("--headless")
opts.set_capability("goog:loggingPrefs", {"performance": "ALL"})
service = Service()  # 可選填 chromedriver 路徑

driver = webdriver.Chrome(service=service, options=opts)
driver.get(BASE_URL)

#─── 2) 禁用快取 ───────────────────────────────────────────────────
driver.execute_cdp_cmd("Network.enable", {})
driver.execute_cdp_cmd("Network.setCacheDisabled", {"cacheDisabled": True})

#─── 3) 開始滾動並顯示進度 ───────────────────────────────────────
time.sleep(2)
scroll_step = 400
pause_per_step = 0.8
start_time = time.time()

y = 0
page_height = driver.execute_script("return document.body.scrollHeight")
step_count = 0

print("開始滾動...")

while y < page_height:
    driver.execute_script(f"window.scrollTo(0, {y});")
    time.sleep(pause_per_step)
    y += scroll_step
    step_count += 1
    new_height = driver.execute_script("return document.body.scrollHeight")

    elapsed = time.time() - start_time
    if step_count > 5:
        speed = y / elapsed
        remaining = (new_height - y) / speed if speed > 0 else 0
        print(f"目前高度: {y}px / {new_height}px | 已花: {elapsed:.1f}s | 預估剩餘: {remaining:.1f}s")
    
    # 如果高度有變就繼續更新
    if new_height > page_height:
        page_height = new_height

# 最後等一下確保最後一批圖載入
print("滾動完成，等待最後資料載入...")
time.sleep(10)

#─── 4) 解析 .webp 圖片 URL ──────────────────────────────────────
logs = driver.get_log("performance")
driver.quit()

pattern = re.compile(r"https?://[^\"']+\.webp")
urls = set()
for entry in logs:
    msg = json.loads(entry["message"])["message"]
    if msg.get("method") == "Network.responseReceived":
        req = msg["params"]["response"]
        u = req.get("url", "")
        if pattern.match(u):
            urls.add(u)

print(f"共找到 {len(urls)} 張 .webp 圖片。開始下載…")

#─── 5) 下載圖片並顯示進度 ───────────────────────────────────────
from concurrent.futures import ThreadPoolExecutor, as_completed
def download(i_url):
    i, url = i_url
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        ext = os.path.splitext(urlparse(url).path)[1] or ".webp"
        fn = f"{i:04d}{ext}"
        with open(os.path.join(DOWNLOAD_DIR, fn), "wb") as f:
            f.write(r.content)
        return True, fn
    except Exception as e:
        return False, url

start_dl_time = time.time()
with ThreadPoolExecutor(max_workers=16) as ex:
    futures = { ex.submit(download, iu): iu for iu in enumerate(sorted(urls), 1) }
    for i, fut in enumerate(as_completed(futures), 1):
        ok, info = fut.result()
        print(f"[{i:>4}/{len(futures)}] [{'OK' if ok else 'ERR'}] {info}")

print(f"下載完成，共耗時 {time.time() - start_time:.1f} 秒。")
