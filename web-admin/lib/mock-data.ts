export const clubSummary = {
  clubName: 'Austin Strikers FC',
  subscriptionTier: 'Pro Annual',
  billingStatus: 'Active',
  activeGames: 12,
  coaches: 18,
  admins: 4
};

export const teams = [
  { id: 'team_001', name: 'U12 Girls', season: 'Spring 2025', coach: 'Lena Torres' },
  { id: 'team_002', name: 'U14 Boys', season: 'Spring 2025', coach: 'Marcus Lee' },
  { id: 'team_003', name: 'U16 Girls', season: 'Winter 2024', coach: 'Camille Ortiz' }
];

export const seasons = [
  { id: 'season_001', name: 'Spring 2025', teams: 8, games: 42, status: 'Active' },
  { id: 'season_002', name: 'Winter 2024', teams: 6, games: 30, status: 'Archived' }
];

export const games = [
  { id: 'game_001', matchup: 'U12 Girls vs Wolves', date: '2025-03-12', status: 'Live' },
  { id: 'game_002', matchup: 'U14 Boys vs Hawks', date: '2025-03-16', status: 'Scheduled' },
  { id: 'game_003', matchup: 'U16 Girls vs Panthers', date: '2025-03-18', status: 'Final' }
];

export const users = [
  { id: 'user_001', name: 'Lena Torres', role: 'Coach', email: 'lena@gostats.club' },
  { id: 'user_002', name: 'Ben Coleman', role: 'Admin', email: 'ben@gostats.club' },
  { id: 'user_003', name: 'Camille Ortiz', role: 'Coach', email: 'camille@gostats.club' }
];
