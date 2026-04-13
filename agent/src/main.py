from src.agent import ProcurementState, StateDeps, agent
import logfire
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.gzip import GZipMiddleware

logfire.configure()
logfire.instrument_pydantic_ai()

app = agent.to_ag_ui(deps=StateDeps(state=ProcurementState()))

# Configure CORS for SSE streaming
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure GZip middleware (helps with streaming performance)
app.add_middleware(GZipMiddleware, minimum_size=1000)


async def health_check(request: Request):
    """Health check endpoint that returns HTTP 200 if the application is running."""
    return JSONResponse(
        status_code=200,
        content={"status": "healthy", "message": "Application is running"},
    )


# Add the health check route to the app's router
app.router.add_route("/api/health", health_check, methods=["GET"])


if __name__ == "__main__":
    # run the app
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=3000, reload=True)
