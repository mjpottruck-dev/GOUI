import type { NextAuthConfig } from 'next-auth';
import Apple from 'next-auth/providers/apple';

export const authConfig: NextAuthConfig = {
  providers: [
    Apple({
      clientId: process.env.APPLE_CLIENT_ID ?? '',
      clientSecret: process.env.APPLE_CLIENT_SECRET ?? '',
      authorization: {
        params: {
          scope: 'name email'
        }
      }
    })
  ],
  session: {
    strategy: 'jwt'
  },
  callbacks: {
    async jwt({ token, profile }) {
      if (profile?.sub) {
        token.clubId = profile.sub;
      }
      return token;
    },
    async session({ session, token }) {
      session.user = {
        ...session.user,
        clubId: token.clubId as string | undefined
      };
      return session;
    }
  }
};
