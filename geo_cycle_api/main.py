from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import vertexai
from vertexai.generative_models import GenerativeModel
import json, os, requests, googlemaps, polyline, re, traceback

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RouteRequest(BaseModel):
    course_type: str
    gyoza_type: str
    include_sightseeing: bool
    start_point: str

vertexai.init(project="geosycle", location="asia-northeast1")
model = GenerativeModel("gemini-1.5-flash")
gmaps = googlemaps.Client(key=os.getenv("MAPS_API_KEY"))

@app.post("/generate")
async def generate_route(req: RouteRequest):
    print("=== /generate 呼び出し ===")
    print(f"入力: {req}")

    try:
        start_point = req.start_point or "宇都宮駅"
        start_geocode = gmaps.geocode(start_point)
        if not start_geocode:
            raise Exception("スタート地点のジオコードが見つかりません")
        start_lat = start_geocode[0]["geometry"]["location"]["lat"]
        start_lng = start_geocode[0]["geometry"]["location"]["lng"]
        start_location = f"{start_lat},{start_lng}"
        print(f"スタート地点の座標: {start_location}")

        u_location = gmaps.geocode("宇都宮駅")[0]["geometry"]["location"]
        directions_to_u = gmaps.directions(start_point, f"{u_location['lat']},{u_location['lng']}", mode="driving")
        if not directions_to_u:
            raise Exception("宇都宮までのルートが見つかりませんでした")
        distance_km = directions_to_u[0]['legs'][0]['distance']['value'] / 1000
        if distance_km > 100:
            return JSONResponse(status_code=200, content={"error": "宇都宮から遠すぎるためコースを生成できません"})

        sightseeing_text = "観光名所（支店名まで明記）も途中に含めて、" if req.include_sightseeing else "餃子店だけで"
        course_time_text = "1-2時間" if req.course_type == "半日コース" else "2-3時間"

        prompt = f"""
あなたは宇都宮の観光に詳しいサイクリングツアーガイドです。
出発地「{start_point}」から出発して、{sightseeing_text}2〜3か所を巡って出発地点に戻るルートを考えてください。
餃子の種類は「{req.gyoza_type}」、コースの所要時間は{req.course_type}（車で{course_time_text}相当）です。

以下の形式で3つの異なるJSONオブジェクトを配列として出力してください：

```
[
  {{
    "course_title": "餃子満喫ライド",
    "course_description": "ボリューム満点！ジューシーな餃子をめぐる充実コース！ 宇都宮餃子の名店を巡りながら、サイクリングで健康的に！初心者でも安心な平坦ルートで、途中には観光名所も立ち寄れます。餃子好きにはたまらない、満足度120％のルートです！",
    "course_detail": "宇都宮餃子を楽しみながら、サイクリング初心者でも無理なく走れるルートです。〇×餃子〇〇テント××餃子という、宇都宮でも人気の餃子店をめぐります。適度な運動で餃子を堪能しながら、心も体も満足できる半日コースです！",
    "stops": ["宇都宮駅", "餃子の〇〇 本店", "大谷資料館", "餃子の△△ 駅東支店", "宇都宮駅"],
    "spot_details": [
      {{"name": "餃子の〇〇 本店", "description": "野菜たっぷりのヘルシーな餃子が特徴！", "menu": "焼き餃子", "price": 400, "calorie": 180}},
      {{"name": "大谷資料館", "description": "地下の神殿みたいな空間で、大谷石の歴史を体感できるロマンあふれる資料館！", "menu": "", "price": 800, "calorie": 0}},
      {{"name": "餃子の△△ 駅東支店", "description": "モチモチ皮のジューシー水餃子が名物", "menu": "水餃子", "price": 420, "calorie": 160}}
    ]
  }}
]
"""

        response = model.generate_content(prompt)
        print("Gemini応答:", response.text)
        match = re.search(r"```(?:json)?\s*(\[.*\])\s*```", response.text, re.DOTALL)
        if not match:
            return JSONResponse(status_code=500, content={"error": "JSONコードブロックが見つかりません"})
        route_list = json.loads(match.group(1))

        result_list = []
        for shop_info in route_list:
            stops = shop_info.get("stops", [])
            coords = []
            decoded_coords = []
            photos = []
            for stop in stops:
                place = gmaps.places(query=stop + " 宇都宮")
                if not place.get("results"):
                    raise Exception(f"場所が見つかりませんでした: {stop}")
                loc = place["results"][0]["geometry"]["location"]
                coords.append(f"{loc['lat']},{loc['lng']}")
                decoded_coords.append([loc['lat'], loc['lng']])
                photo_ref = place["results"][0].get("photos", [{}])[0].get("photo_reference")
                photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={os.getenv('MAPS_API_KEY')}" if photo_ref else None
                photos.append(photo_url)

            origin = coords[0]
            destination = coords[-1]
            waypoints = coords[1:-1]
            directions = gmaps.directions(origin, destination, waypoints=waypoints, mode="driving")
            if not directions:
                raise Exception("ルートが見つかりません")
            legs = directions[0]['legs']
            total_distance = sum(leg['distance']['value'] for leg in legs) / 1000
            total_duration = sum(leg['duration']['value'] for leg in legs) / 25
            poly = directions[0]['overview_polyline']['points']
            decoded = polyline.decode(poly)

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
            except:
                elevation_gain = -1

            mets = 8.0
            weight = 60
            calorie = mets * weight * (total_duration / 60)

            spot_details = shop_info.get("spot_details", [])
            gyoza_total_calories = sum(int(s.get("calorie") or 0) for s in spot_details)

            for i, spot in enumerate(spot_details):
                stop_name = stops[i + 1] if i + 1 < len(stops) else ""
                place = gmaps.places(query=stop_name + " 宇都宮")
                photo_ref = place.get("results", [{}])[0].get("photos", [{}])[0].get("photo_reference")
                if photo_ref:
                    spot["photo_url"] = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={os.getenv('MAPS_API_KEY')}"

            photo_url = shop_info.get("photo_url") or (photos[0] if photos else None)

            result_list.append({
                "course_title": shop_info.get("course_title", "おすすめ餃子ライド"),
                "route_summary": {
                    "distance_km": round(total_distance, 2),
                    "duration_min": round(total_duration),
                    "elevation_gain_m": round(elevation_gain, 1) if elevation_gain >= 0 else "未取得",
                    "calories_kcal": round(calorie, 1),
                    "gyoza_calories": gyoza_total_calories
                },
                "course_description": shop_info.get("course_description", "宇都宮をぐるりと楽しめるおすすめコースです！"),
                "course_detail": shop_info.get("course_detail", ""),
                "stops": shop_info.get("stops", []),
                "route_polyline": decoded,
                "stop_coords": decoded_coords,
                "spot_details": spot_details
            })

        return result_list

    except Exception as e:
        print("エラー発生:", e)
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": str(e)})
