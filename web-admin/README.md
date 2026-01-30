# GoStats Web Admin Dashboard (Sprint 8)

## Repo structure
```
web-admin/
├── app/
│   ├── api/
│   │   ├── auth/[...nextauth]/route.ts   # Sign in with Apple auth wiring
│   │   ├── cloudkit/*/route.ts           # CloudKit record stubs (teams, seasons, games, users)
│   │   ├── contact/route.ts              # Contact form handler
│   │   ├── crm/export/route.ts           # CRM CSV export stub
│   │   └── export/club/route.ts          # Club CSV export
│   ├── dashboard/page.tsx                # Club snapshot + actions
│   ├── games/page.tsx                    # Games list
│   ├── request-quote/page.tsx            # Sales contact form
│   ├── seasons/page.tsx                  # Seasons list
│   ├── teams/page.tsx                    # Teams list
│   ├── users/page.tsx                    # Admin/coach list
│   ├── globals.css                       # Shared styles
│   └── layout.tsx                        # Global layout + nav
├── components/
│   └── header.tsx                        # Global navigation
├── lib/
│   ├── auth.ts                           # NextAuth config
│   ├── cloudkit.ts                       # CloudKit and CSV helpers
│   └── mock-data.ts                      # Placeholder data for UI
├── types/next-auth.d.ts                  # Session typing
├── next.config.js
├── package.json
└── tsconfig.json
```

## Deployment instructions
1. Install dependencies:
   ```bash
   cd web-admin
   npm install
   ```
2. Configure environment variables (see `.env.example`):
   ```bash
   APPLE_CLIENT_ID=...
   APPLE_CLIENT_SECRET=...
   NEXTAUTH_URL=https://admin.gostats.app
   NEXTAUTH_SECRET=...
   ```
3. Run the app locally:
   ```bash
   npm run dev
   ```
4. Build + deploy:
   ```bash
   npm run build
   npm run start
   ```

## Auth wiring
- NextAuth is configured with the Apple provider in `lib/auth.ts` and the handler in `app/api/auth/[...nextauth]/route.ts`.
- Apple user identity is mapped into the JWT/session as `clubId` to support club-scoped access.
- Sign-in UI is represented by the header button; replace with a NextAuth sign-in flow in production.

## API layer scaffolding
- CloudKit collection stubs:
  - `/api/cloudkit/teams`
  - `/api/cloudkit/seasons`
  - `/api/cloudkit/games`
  - `/api/cloudkit/users`
- CSV export endpoints:
  - `/api/export/club` for club-wide data
  - `/api/crm/export` for CRM ingestion
- Contact form endpoint:
  - `/api/contact`

## Test flow
1. Club admin logs in with Sign in with Apple.
2. Admin lands on the Dashboard and sees teams, seasons, games, users, and subscription status.
3. Admin clicks **Export Club CSV** to download club-wide data.
