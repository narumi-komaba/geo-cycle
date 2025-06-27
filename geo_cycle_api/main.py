from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import vertexai
from vertexai.generative_models import GenerativeModel
import json, os, requests, googlemaps, polyline, re, traceback

app = FastAPI()

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# リクエストボディ
class RouteRequest(BaseModel):
    distance: int
    elevation: int
    time: int
    gyotza_type: str

# 初期化
vertexai.init(project="geosycle", location="asia-northeast1")
model = GenerativeModel("gemini-1.5-flash")
gmaps = googlemaps.Client(key=os.getenv("MAPS_API_KEY"))

@app.post("/generate")
async def generate_route(req: RouteRequest):
    print("=== /generate 呼び出し ===")
    print(f"入力: {req}")

    # ① Geminiで餃子店候補を取得
    prompt = f"""
あなたは宇都宮のサイクリングツアーガイドです。以下の条件に合った餃子店を1件おすすめしてください。
できるだけ正式な店舗名を出力してください。

- 距離：約{req.distance}km
- 獲得標高：約{req.elevation}m
- 所要時間：約{req.time}分
- 餃子タイプ：{req.gyotza_type}

出力形式は以下のJSONで：
{{
  "name": "餃子の〇〇",
  "comment": "肉汁たっぷりで行列ができる人気店"
}}
"""
    try:
        response = model.generate_content(prompt)
        print("Gemini応答:", response.text)
        match = re.search(r"```(?:json)?\s*(\{.*\})\s*```", response.text, re.DOTALL)
        if not match:
            print("JSONコードブロックが見つかりません")
            return JSONResponse(status_code=500, content={"error": "JSONコードブロックが見つかりません"})
        shop_info = json.loads(match.group(1))
        print("抽出されたshop_info:", shop_info)
    except Exception as e:
        print("Gemini解析エラー:", e)
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": "Gemini応答の解析に失敗", "detail": str(e)})

    # ② 店名から緯度経度を検索（Places API）
    try:
        query = f"{shop_info['name']} 宇都宮"
        places = gmaps.places(query=query)
        if not places.get("results"):
            raise Exception(f"場所が見つかりませんでした: {query}")
        location = places["results"][0]["geometry"]["location"]
        destination_latlng = f"{location['lat']},{location['lng']}"
        print(f"検索成功: {destination_latlng}")
    except Exception as e:
        print("Google Places検索失敗:", e)
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": "店舗検索に失敗", "detail": str(e)})

    # ③ Maps Routes APIでルート取得
    origin = "宇都宮駅"
    try:
        directions = gmaps.directions(origin, destination_latlng, mode="driving")
        if not directions:
            raise Exception("ルートが見つかりませんでした")
        print("Maps directions取得成功")
        route = directions[0]['legs'][0]
        poly = directions[0]['overview_polyline']['points']
        decoded = polyline.decode(poly)
    except Exception as e:
        print("Google Maps ルート取得失敗:", e)
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": "Google Maps ルート取得失敗", "detail": str(e)})

    # ④ Elevation APIで標高差計算
    try:
        points = decoded[::max(1, len(decoded)//20)]
        loc_str = "|".join(f"{lat},{lng}" for lat, lng in points)
        elev_url = "https://maps.googleapis.com/maps/api/elevation/json"
        elev_res = requests.get(elev_url, params={"locations": loc_str, "key": os.getenv("MAPS_API_KEY")})
        elev_data = elev_res.json().get("results", [])
        elevation_gain = sum(
            max(0, elev_data[i+1]["elevation"] - elev_data[i]["elevation"])
            for i in range(len(elev_data)-1)
        )
        print(f"標高差計算成功: {elevation_gain} m")
    except Exception as e:
        print("標高差計算失敗:", e)
        traceback.print_exc()
        elevation_gain = -1

    # ⑤ カロリー計算（METS法）
    distance_km = route["distance"]["value"] / 1000
    duration_h = route["duration"]["value"] / 3600
    mets = 8.0
    weight = 60
    calorie = mets * weight * duration_h

    return {
        "gyotza_shop": {
            "name": shop_info["name"],
            "comment": shop_info["comment"],
            "lat": location['lat'],
            "lng": location['lng']
        },
        "route_summary": {
            "distance_km": round(distance_km, 2),
            "duration_min": round(duration_h * 60),
            "elevation_gain_m": round(elevation_gain, 1) if elevation_gain >= 0 else "未取得",
            "calories_kcal": round(calorie, 1)
        }
    }
