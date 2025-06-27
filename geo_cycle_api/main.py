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

        sightseeing_text = "観光名所（支店名まで明記）も途中に含めて、" if req.include_sightseeing else ""
        prompt = f"""
あなたは宇都宮の観光に詳しいサイクリングツアーガイドです。
出発地「{start_point}」から出発して、{sightseeing_text}2〜3か所を巡って出発地点に戻るルートを考えてください。
餃子の種類は「{req.gyoza_type}」、コースの所要時間は{req.course_type}（車で{('1-2時間' if req.course_type=='半日コース' else '2-3時間')}相当）です。

以下の形式で3つの異なるJSONオブジェクトを配列として出力してください：

```json
[
  {{
    "name": "餃子の〇〇",
    "description": "〇〇を巡る絶景とグルメのコース。初心者にもおすすめです。",
    "stops": [
      "宇都宮駅",
      "餃子の〇〇 本店",
      "大谷資料館",
      "餃子の△△ 駅東支店",
      "宇都宮駅"
    ]
  }},
  ...
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
            photos = []
            for stop in stops:
                place = gmaps.places(query=stop + " 宇都宮")
                if not place.get("results"):
                    raise Exception(f"場所が見つかりませんでした: {stop}")
                loc = place["results"][0]["geometry"]["location"]
                coords.append(f"{loc['lat']},{loc['lng']}")
                photo_ref = place["results"][0].get("photos", [{}])[0].get("photo_reference")
                if photo_ref:
                    photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={os.getenv('MAPS_API_KEY')}"
                    photos.append(photo_url)
                else:
                    photos.append(None)

            origin = coords[0]
            destination = coords[-1]
            waypoints = coords[1:-1]
            directions = gmaps.directions(origin, destination, waypoints=waypoints, mode="driving")
            if not directions:
                raise Exception("ルートが見つかりません")
            legs = directions[0]['legs']
            total_distance = sum(leg['distance']['value'] for leg in legs) / 1000
            total_duration = sum(leg['duration']['value'] for leg in legs) / 60
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

            first_place = gmaps.places(query=stops[1] + " 宇都宮")
            first_stop_place = first_place["results"][0]["geometry"]["location"]
            photo_ref = first_place["results"][0].get("photos", [{}])[0].get("photo_reference")
            photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={os.getenv('MAPS_API_KEY')}" if photo_ref else None

            result_list.append({
                "gyotza_shop": {
                    "name": shop_info["name"],
                    "lat": first_stop_place["lat"],
                    "lng": first_stop_place["lng"],
                    "photo_url": photo_url
                },
                "route_summary": {
                    "distance_km": round(total_distance, 2),
                    "duration_min": round(total_duration),
                    "elevation_gain_m": round(elevation_gain, 1) if elevation_gain >= 0 else "未取得",
                    "calories_kcal": round(calorie, 1)
                },
                "course_description": shop_info.get("description", "宇都宮をぐるりと楽しめるおすすめコースです"),
                "stops": shop_info.get("stops", [])
            })

        return result_list

    except Exception as e:
        print("エラー発生:", e)
        traceback.print_exc()
        return JSONResponse(status_code=500, content={"error": str(e)})
