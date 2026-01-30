import { clubSummary, teams, seasons, games, users } from '../../lib/mock-data';

export default function DashboardPage() {
  return (
    <div>
      <h1>Club Admin Dashboard</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Welcome back. Here is the latest snapshot for {clubSummary.clubName}.
      </p>

      <section className="section">
        <div className="card-grid">
          <div className="card">
            <h3>Active Games</h3>
            <p style={{ fontSize: 32, fontWeight: 700 }}>{clubSummary.activeGames}</p>
            <p style={{ color: 'var(--muted)' }}>Live + scheduled this week</p>
          </div>
          <div className="card">
            <h3>Subscription</h3>
            <p style={{ fontSize: 20, fontWeight: 600 }}>{clubSummary.subscriptionTier}</p>
            <span className="badge">{clubSummary.billingStatus}</span>
          </div>
          <div className="card">
            <h3>Coaches</h3>
            <p style={{ fontSize: 32, fontWeight: 700 }}>{clubSummary.coaches}</p>
            <p style={{ color: 'var(--muted)' }}>Across all teams</p>
          </div>
          <div className="card">
            <h3>Admins</h3>
            <p style={{ fontSize: 32, fontWeight: 700 }}>{clubSummary.admins}</p>
            <p style={{ color: 'var(--muted)' }}>Club-level access</p>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="card">
          <h3>Quick Actions</h3>
          <p style={{ color: 'var(--muted)', marginTop: 6 }}>
            Export data or invite additional admins.
          </p>
          <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
            <a className="button" href="/api/export/club">
              Export Club CSV
            </a>
            <button className="button secondary" type="button">
              Invite Admin
            </button>
            <button className="button secondary" type="button">
              Manage Coaches
            </button>
          </div>
        </div>
      </section>

      <section className="section">
        <h2>Recent Teams</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Team</th>
              <th>Season</th>
              <th>Head Coach</th>
            </tr>
          </thead>
          <tbody>
            {teams.map((team) => (
              <tr key={team.id}>
                <td>{team.name}</td>
                <td>{team.season}</td>
                <td>{team.coach}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="section">
        <h2>Active Seasons</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Season</th>
              <th>Teams</th>
              <th>Games</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {seasons.map((season) => (
              <tr key={season.id}>
                <td>{season.name}</td>
                <td>{season.teams}</td>
                <td>{season.games}</td>
                <td>{season.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="section">
        <h2>Games Snapshot</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Matchup</th>
              <th>Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {games.map((game) => (
              <tr key={game.id}>
                <td>{game.matchup}</td>
                <td>{game.date}</td>
                <td>{game.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="section">
        <h2>Admins & Coaches</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Email</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id}>
                <td>{user.name}</td>
                <td>{user.role}</td>
                <td>{user.email}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}
