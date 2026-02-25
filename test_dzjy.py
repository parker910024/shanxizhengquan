import urllib.request
import json
import ssl

ssl._create_default_https_context = ssl._create_unverified_context
url = "http://112.213.108.32:12025/api/Indexnew/sgandps"
req = urllib.request.Request(url, headers={'Token': 'fccfd25b8d37c105a1e91caf59ebfdde9d7e09d9'})
try:
    with urllib.request.urlopen(req) as response:
        content = response.read().decode()
        print("Raw response:", content[:200])
        data = json.loads(content)
        print("Parsed data keys:", data.get("data", {}).keys())
except Exception as e:
    print("Error:", e)
