from src.agent import ProcurementState, StateDeps, agent
import logfire

logfire.configure()
logfire.instrument_pydantic_ai()

app = agent.to_ag_ui(deps=StateDeps(state=ProcurementState()))

if __name__ == "__main__":
    # run the app
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
