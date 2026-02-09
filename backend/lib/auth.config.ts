import type { NextAuthConfig } from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import Google from 'next-auth/providers/google'
import { compare } from 'bcryptjs'
import { prisma } from './prisma'
import { z } from 'zod'

const loginSchema = z.object({
  identifier: z.string().min(1),
  password: z.string().min(6),
})

export default {
  providers: [
    // Google OAuth Provider
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          prompt: 'consent',
          access_type: 'offline',
          response_type: 'code',
        },
      },
    }),

    // Credentials Provider (Phone/Email + Password)
    Credentials({
      name: 'credentials',
      credentials: {
        identifier: { label: 'Phone or Email', type: 'text' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        try {
          // Validate input
          const { identifier, password } = loginSchema.parse(credentials)

          // Find user by phone or email
          const user = await prisma.user.findFirst({
            where: {
              OR: [
                { phoneNumber: identifier },
                { email: identifier },
              ],
            },
            include: {
              subscription: true,
            },
          })

          if (!user) {
            return null
          }

          // Check account status
          if (user.accountStatus === 'LOCKED') {
            if (user.lockedUntil && user.lockedUntil > new Date()) {
              throw new Error('Account is locked. Please try again later.')
            }
            // Unlock account if lock period has passed
            await prisma.user.update({
              where: { id: user.id },
              data: {
                accountStatus: 'ACTIVE',
                failedLoginAttempts: 0,
                lockedUntil: null,
              },
            })
          }

          if (user.accountStatus === 'PENDING_VERIFICATION') {
            throw new Error('Account is pending verification.')
          }

          if (user.accountStatus === 'REJECTED') {
            throw new Error('Account has been rejected.')
          }

          // Verify password
          const isPasswordValid = await compare(password, user.passwordHash)

          if (!isPasswordValid) {
            // Increment failed login attempts
            const failedAttempts = user.failedLoginAttempts + 1
            const shouldLock = failedAttempts >= 5

            await prisma.user.update({
              where: { id: user.id },
              data: {
                failedLoginAttempts: failedAttempts,
                ...(shouldLock && {
                  accountStatus: 'LOCKED',
                  lockedUntil: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
                }),
              },
            })

            if (shouldLock) {
              throw new Error('Account locked due to too many failed login attempts.')
            }

            return null
          }

          // Reset failed login attempts on successful login
          await prisma.user.update({
            where: { id: user.id },
            data: {
              failedLoginAttempts: 0,
            },
          })

          // Return user object for JWT
          return {
            id: user.id,
            email: user.email,
            name: user.fullName || `${user.firstName} ${user.lastName}`,
            role: user.role,
            language: user.language,
            theme: user.theme,
            subscriptionTier: user.subscription?.tier || 'FREEMIUM',
          }
        } catch (error) {
          console.error('Auth error:', error)
          return null
        }
      },
    }),
  ],

  pages: {
    signIn: '/auth/login',
    error: '/auth/error',
  },

  callbacks: {
    async signIn({ user, account, profile }) {
      // Handle Google OAuth sign-in
      if (account?.provider === 'google' && profile?.email) {
        try {
          // Check if user exists
          let existingUser = await prisma.user.findUnique({
            where: { email: profile.email },
          })

          if (!existingUser) {
            // Create new user from Google profile
            existingUser = await prisma.user.create({
              data: {
                email: profile.email,
                fullName: profile.name || '',
                firstName: profile.given_name || '',
                lastName: profile.family_name || '',
                phoneNumber: `+855${Date.now()}`, // Temporary phone number
                passwordHash: '', // No password for OAuth users
                role: 'PATIENT',
                language: 'ENGLISH',
                accountStatus: 'ACTIVE',
                subscription: {
                  create: {
                    tier: 'FREEMIUM',
                    storageQuota: 5368709120, // 5GB
                    storageUsed: 0,
                  },
                },
              },
            })
          }

          // Update user object with database info
          user.id = existingUser.id
          user.role = existingUser.role
          user.language = existingUser.language
          user.theme = existingUser.theme

          return true
        } catch (error) {
          console.error('Google sign-in error:', error)
          return false
        }
      }

      return true
    },

    async jwt({ token, user, trigger, session }) {
      // Initial sign in
      if (user) {
        token.id = user.id
        token.role = user.role
        token.language = user.language
        token.theme = user.theme
        token.subscriptionTier = user.subscriptionTier
      }

      // Update token on session update
      if (trigger === 'update' && session) {
        token.language = session.language || token.language
        token.theme = session.theme || token.theme
      }

      return token
    },

    async session({ session, token }) {
      if (token && session.user) {
        session.user.id = token.id as string
        session.user.role = token.role as string
        session.user.language = token.language as string
        session.user.theme = token.theme as string
        session.user.subscriptionTier = token.subscriptionTier as string
      }
      return session
    },
  },

  session: {
    strategy: 'jwt',
    maxAge: 7 * 24 * 60 * 60, // 7 days
  },

  jwt: {
    maxAge: 15 * 60, // 15 minutes
  },

  trustHost: true,
} satisfies NextAuthConfig
