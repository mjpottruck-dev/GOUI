import Link from 'next/link';

export default function HomePage() {
  return (
    <div>
      <h1>GoStats Club Admin</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Lightweight web admin dashboard for clubs.
      </p>
      <div style={{ marginTop: 16 }}>
        <Link className="button" href="/dashboard">
          Go to Dashboard
        </Link>
      </div>
    </div>
  );
}
