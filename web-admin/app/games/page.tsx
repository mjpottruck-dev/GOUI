import { games } from '../../lib/mock-data';

export default function GamesPage() {
  return (
    <div>
      <h1>Games</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Active and upcoming games across the club.
      </p>
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
    </div>
  );
}
