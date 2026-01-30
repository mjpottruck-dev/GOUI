export type ClubScope = {
  clubId: string;
};

export async function fetchTeams(scope: ClubScope) {
  return {
    clubId: scope.clubId,
    records: []
  };
}

export async function fetchSeasons(scope: ClubScope) {
  return {
    clubId: scope.clubId,
    records: []
  };
}

export async function fetchGames(scope: ClubScope) {
  return {
    clubId: scope.clubId,
    records: []
  };
}

export async function fetchUsers(scope: ClubScope) {
  return {
    clubId: scope.clubId,
    records: []
  };
}

export function buildCsv(rows: Array<Record<string, string | number>>) {
  if (rows.length === 0) {
    return '';
  }
  const headers = Object.keys(rows[0]);
  const headerLine = headers.join(',');
  const bodyLines = rows.map((row) =>
    headers.map((header) => JSON.stringify(row[header] ?? '')).join(',')
  );
  return [headerLine, ...bodyLines].join('\n');
}
