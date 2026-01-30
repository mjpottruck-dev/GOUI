import { teams } from '../../lib/mock-data';

export default function TeamsPage() {
  return (
    <div>
      <h1>Teams</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        View all teams scoped to the current club.
      </p>
      <table className="table">
        <thead>
          <tr>
            <th>Team</th>
            <th>Season</th>
            <th>Coach</th>
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
    </div>
  );
}
