import { NextResponse } from 'next/server';
import { fetchSeasons } from '../../../../lib/cloudkit';

export async function GET(request: Request) {
  const clubId = request.headers.get('x-club-id') ?? 'demo-club';
  const data = await fetchSeasons({ clubId });
  return NextResponse.json({ scope: clubId, data });
}
