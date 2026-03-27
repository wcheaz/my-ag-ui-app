import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
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
}