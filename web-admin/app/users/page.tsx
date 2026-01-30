import { users } from '../../lib/mock-data';

export default function UsersPage() {
  return (
    <div>
      <h1>Users</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Admins and coaches who can access the club account.
      </p>
      <div style={{ display: 'flex', gap: 12, marginTop: 12 }}>
        <button className="button" type="button">
          Invite Admin
        </button>
        <button className="button secondary" type="button">
          Invite Coach
        </button>
      </div>
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
    </div>
  );
}
