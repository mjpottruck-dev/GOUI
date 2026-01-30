import Link from 'next/link';

export function Header() {
  return (
    <header>
      <div>
        <strong>GoStats Admin</strong>
      </div>
      <nav>
        <ul>
          <li>
            <Link href="/dashboard">Dashboard</Link>
          </li>
          <li>
            <Link href="/teams">Teams</Link>
          </li>
          <li>
            <Link href="/seasons">Seasons</Link>
          </li>
          <li>
            <Link href="/games">Games</Link>
          </li>
          <li>
            <Link href="/users">Users</Link>
          </li>
          <li>
            <Link href="/request-quote">Request Quote</Link>
          </li>
        </ul>
      </nav>
      <div>
        <button type="button" className="button secondary">
          Sign in with Apple
        </button>
      </div>
    </header>
  );
}
