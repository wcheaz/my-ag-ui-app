import {
  CopilotRuntime,
  ExperimentalEmptyAdapter,
  copilotRuntimeNextJSAppRouterEndpoint,
} from "@copilotkit/runtime";
import { HttpAgent } from "@ag-ui/client";
import { NextRequest, NextResponse } from "next/server";

// 1. You can use any service adapter here for multi-agent support. We use
//    the empty adapter since we're only using one agent.
const serviceAdapter = new ExperimentalEmptyAdapter();

// 2. Create the CopilotRuntime instance and utilize the PydanticAI AG-UI
//    integration to setup the connection.
const runtime = new CopilotRuntime({
  agents: {
    // Our FastAPI endpoint URL
    my_agent: new HttpAgent({ url: process.env.AGENT_URL || "http://localhost:8000/" }),
  },
});

// 3. Health endpoint for Kubernetes probes
export const GET = async (req: NextRequest) => {
  const { searchParams } = new URL(req.url);
  const shouldFail = searchParams.get('fail') === 'true';
  
  if (shouldFail) {
    return NextResponse.json(
      { status: "unhealthy", timestamp: new Date().toISOString(), error: "Test failure scenario" },
      { status: 500 }
    );
  }
  
  return NextResponse.json(
    { status: "healthy", timestamp: new Date().toISOString() },
    { status: 200 }
  );
};

// 4. Build a Next.js API route that handles the CopilotKit runtime requests.
export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  return handleRequest(req);
};
