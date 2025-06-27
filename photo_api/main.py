# main.py
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
import os
import requests

app = FastAPI()

# CORS 設定（すべてのオリジンを許可する場合）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter Webローカル開発用。公開時はドメイン指定を推奨
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GOOGLE_MAPS_API_KEY = os.getenv("MAPS_API_KEY")

@app.get("/place-photo")
async def get_place_photo(ref: str, maxwidth: int = 400):
    if not ref:
        raise HTTPException(status_code=400, detail="photo_reference is required")

    photo_url = (
        "https://maps.googleapis.com/maps/api/place/photo"
        f"?maxwidth={maxwidth}&photoreference={ref}&key={GOOGLE_MAPS_API_KEY}"
    )

    try:
        res = requests.get(photo_url, allow_redirects=True)
        if res.status_code != 200:
            raise HTTPException(status_code=502, detail="Photo fetch failed")

        content_type = res.headers.get("Content-Type", "image/jpeg")
        return Response(content=res.content, media_type=content_type)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
