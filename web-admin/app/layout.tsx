import './globals.css';
import type { ReactNode } from 'react';
import { Header } from '../components/header';

export const metadata = {
  title: 'GoStats Club Admin',
  description: 'GoStats web admin dashboard for club leadership.'
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Header />
        <main>{children}</main>
        <footer>GoStats Admin Dashboard · Sprint 8</footer>
      </body>
    </html>
  );
}
