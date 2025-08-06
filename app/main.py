from fastapi import FastAPI

app = FastAPI()

@app.get("/ping", status_code=200)
async def ping():
    return {"msg": "pong", "status": "ok"}