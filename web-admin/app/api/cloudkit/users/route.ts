import { NextResponse } from 'next/server';
import { fetchUsers } from '../../../../lib/cloudkit';

export async function GET(request: Request) {
  const clubId = request.headers.get('x-club-id') ?? 'demo-club';
  const data = await fetchUsers({ clubId });
  return NextResponse.json({ scope: clubId, data });
}
