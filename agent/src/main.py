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


# Configure SSE response headers for streaming
@app.middleware("http")
async def add_sse_headers(request, call_next):
    response = await call_next(request)
    # Apply SSE headers to all AG-UI endpoints, not just root path
    if request.method == "POST" and request.url.path.startswith("/"):
        # Ensure this is an AG-UI request (has appropriate content-type or user-agent)
        content_type = request.headers.get("content-type", "")
        user_agent = request.headers.get("user-agent", "")

        is_ag_ui_request = (
            "application/json" in content_type
            or "copilotkit" in user_agent.lower()
            or "ag-ui" in user_agent.lower()
        )

        if is_ag_ui_request:
            # Add SSE-specific headers for streaming responses
            response.headers["Content-Type"] = "text/event-stream"
            response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
            response.headers["Connection"] = "keep-alive"
            response.headers["X-Accel-Buffering"] = "no"
            response.headers["X-Content-Type-Options"] = "nosniff"
            # Ensure no buffering for streaming responses
            response.headers["Transfer-Encoding"] = "chunked"
            # Also ensure the response is a streaming response
            if hasattr(response, "body_iterator") or hasattr(response, "stream"):
                # Force the response to be streamed
                response.headers["X-Streaming-Status"] = "active"
    return response


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
