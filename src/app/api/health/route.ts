import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // Check if we should simulate a failure
    const { searchParams } = new URL(request.url);
    const fail = searchParams.get('fail');
    
    if (fail === 'true') {
      return NextResponse.json(
        { status: 'unhealthy', error: 'Explicit failure requested' },
        { status: 503 }
      );
    }
    
    // Return healthy status
    return NextResponse.json({ status: 'healthy' });
  } catch (error) {
    // Return error status if something goes wrong
    return NextResponse.json(
      { status: 'unhealthy', error: 'Internal server error' },
      { status: 500 }
    );
  }
}