import { createContext, useContext, useEffect, useState } from 'react'

const AuthContext = createContext()

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [mfaPending, setMfaPending] = useState(false)

  useEffect(() => {
    const session = localStorage.getItem('bb-session')
    if (session) {
      try { setUser(JSON.parse(session)) } catch {}
    }
    setLoading(false)
  }, [])

  const persist = (u) => {
    setUser(u)
    localStorage.setItem('bb-session', JSON.stringify(u))
  }

  // --- Email/Password Sign In ---
  const signIn = async (email, password) => {
    if (email && password) {
      const existing = JSON.parse(localStorage.getItem('bb-session') || 'null')
      persist({
        userId: existing?.userId || email,
        email: existing?.email || email,
        name: existing?.name || email.split('@')[0],
        avatar: existing?.avatar || null,
        providers: existing?.providers || {},
      })
      return { mfaRequired: false }
    }
    throw new Error('Invalid credentials')
  }

  // --- Google Sign In (initial login) ---
  const signInWithGoogle = async (googleProfile) => {
    const existing = JSON.parse(localStorage.getItem('bb-session') || 'null')
    persist({
      userId: existing?.userId || googleProfile.sub,
      email: existing?.email || googleProfile.email,
      name: existing?.name || googleProfile.name,
      avatar: existing?.avatar || googleProfile.picture,
      providers: {
        ...(existing?.providers || {}),
        google: {
          sub: googleProfile.sub,
          email: googleProfile.email,
          name: googleProfile.name,
          picture: googleProfile.picture,
        },
      },
    })
  }

  // --- Facebook Sign In (initial login) ---
  const signInWithFacebook = async (fbProfile) => {
    const existing = JSON.parse(localStorage.getItem('bb-session') || 'null')
    persist({
      userId: existing?.userId || `fb-${fbProfile.id}`,
      email: existing?.email || fbProfile.email || '',
      name: existing?.name || fbProfile.name,
      avatar: existing?.avatar || fbProfile.picture || null,
      providers: {
        ...(existing?.providers || {}),
        facebook: {
          id: fbProfile.id,
          email: fbProfile.email || '',
          name: fbProfile.name,
          picture: fbProfile.picture || null,
        },
      },
    })
  }

  // --- Link Google to existing account ---
  const linkGoogle = async (googleProfile) => {
    const updated = {
      ...user,
      providers: {
        ...(user?.providers || {}),
        google: {
          sub: googleProfile.sub,
          email: googleProfile.email,
          name: googleProfile.name,
          picture: googleProfile.picture,
        },
      },
    }
    persist(updated)
  }

  // --- Link Facebook to existing account ---
  const linkFacebook = async (fbProfile) => {
    const updated = {
      ...user,
      providers: {
        ...(user?.providers || {}),
        facebook: {
          id: fbProfile.id,
          email: fbProfile.email || '',
          name: fbProfile.name,
          picture: fbProfile.picture || null,
        },
      },
    }
    persist(updated)
  }

  // --- Unlink a provider ---
  const unlinkProvider = (provider) => {
    const providers = { ...(user?.providers || {}) }
    delete providers[provider]
    persist({ ...user, providers })
  }

  // --- Update profile (name, email, avatar) ---
  const updateProfile = (updates) => {
    persist({ ...user, ...updates })
  }

  // --- 2FA ---
  const confirmMFA = async (code) => {
    if (code.length === 6) {
      const current = user || JSON.parse(localStorage.getItem('bb-session') || '{}')
      persist(current)
      setMfaPending(false)
      return true
    }
    throw new Error('Invalid code')
  }

  // --- Sign Up ---
  const signUp = async (email, password) => {
    return { nextStep: 'DONE' }
  }

  // --- Sign Out ---
  const signOut = () => {
    setUser(null)
    setMfaPending(false)
    localStorage.removeItem('bb-session')
  }

  return (
    <AuthContext.Provider value={{
      user, loading, mfaPending,
      signIn, signInWithGoogle, signInWithFacebook,
      linkGoogle, linkFacebook, unlinkProvider,
      updateProfile,
      confirmMFA, signUp, signOut,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
