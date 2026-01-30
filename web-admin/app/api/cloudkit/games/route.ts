import { NextResponse } from 'next/server';
import { fetchGames } from '../../../../lib/cloudkit';

export async function GET(request: Request) {
  const clubId = request.headers.get('x-club-id') ?? 'demo-club';
  const data = await fetchGames({ clubId });
  return NextResponse.json({ scope: clubId, data });
}
