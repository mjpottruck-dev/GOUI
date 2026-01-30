import { NextResponse } from 'next/server';
import { buildCsv } from '../../../../lib/cloudkit';

export async function POST() {
  const csv = buildCsv([
    { accountName: 'Austin Strikers FC', plan: 'Pro Annual', seats: 120 }
  ]);

  return new NextResponse(csv, {
    status: 200,
    headers: {
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename="crm-export.csv"'
    }
  });
}
