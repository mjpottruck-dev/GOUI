import { NextResponse } from 'next/server';
import { fetchTeams } from '../../../../lib/cloudkit';

export async function GET(request: Request) {
  const clubId = request.headers.get('x-club-id') ?? 'demo-club';
  const data = await fetchTeams({ clubId });
  return NextResponse.json({ scope: clubId, data });
}
