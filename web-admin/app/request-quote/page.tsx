export default function RequestQuotePage() {
  return (
    <div>
      <h1>Request a Quote</h1>
      <p style={{ color: 'var(--muted)', marginTop: 8 }}>
        Share your club details and our sales team will respond with enterprise pricing.
      </p>
      <section className="section">
        <div className="card">
          <form className="form" action="/api/contact" method="post">
            <label>
              Club Name
              <input name="clubName" placeholder="Austin Strikers FC" />
            </label>
            <label>
              Contact Email
              <input name="email" type="email" placeholder="you@club.org" />
            </label>
            <label>
              Number of Teams
              <input name="teams" type="number" min="1" placeholder="12" />
            </label>
            <label>
              Notes
              <textarea name="notes" rows={4} placeholder="Tell us about your league." />
            </label>
            <div style={{ display: 'flex', gap: 12 }}>
              <button className="button" type="submit">
                Submit Request
              </button>
              <button className="button secondary" type="button">
                Schedule Demo
              </button>
            </div>
          </form>
        </div>
      </section>

      <section className="section">
        <div className="card">
          <h3>CRM Export Stub</h3>
          <p style={{ color: 'var(--muted)', marginTop: 6 }}>
            Generate a CSV payload for CRM ingestion.
          </p>
          <form action="/api/crm/export" method="post">
            <button className="button" type="submit">
              Export CRM CSV
            </button>
          </form>
        </div>
      </section>
    </div>
  );
}
