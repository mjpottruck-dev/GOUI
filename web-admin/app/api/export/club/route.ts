import { NextResponse } from 'next/server';
import { buildCsv } from '../../../../lib/cloudkit';

export async function GET() {
  const csv = buildCsv([
    { recordType: 'Team', name: 'U12 Girls', coach: 'Lena Torres' },
    { recordType: 'Team', name: 'U14 Boys', coach: 'Marcus Lee' }
  ]);

  return new NextResponse(csv, {
    status: 200,
    headers: {
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename="club-export.csv"'
    }
  });
}
