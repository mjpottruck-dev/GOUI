import { seasons } from '../../lib/mock-data';

export default function SeasonsPage() {
  return (
    <div>
      <h1>Seasons</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Track historical and active seasons for the club.
      </p>
      <table className="table">
        <thead>
          <tr>
            <th>Name</th>
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
    </div>
  );
}
