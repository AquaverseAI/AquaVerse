from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class ReasonResponse(BaseModel):
    pond_id: str
    payload: dict
    narration: str
    hallucination_check_passed: bool
    regeneration_attempts: int
    latency_ms: float

@app.post("/v1/reason/m3")
async def mock_m3(req: dict):
    return ReasonResponse(
        pond_id=req.get("pond_id", "0000"),
        payload=req,
        narration="Mocked M3 narration: You should feed 5kg of feed.",
        hallucination_check_passed=True,
        regeneration_attempts=0,
        latency_ms=150.0
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
