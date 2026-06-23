import { createContext, useContext, useEffect, useState } from 'react'

const AuthContext = createContext()

const API_BASE = import.meta.env.VITE_API_URL || ''

async function authPost(path, body) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || `Error ${res.status}`)
  return data
}

function decodeJwt(token) {
  try {
    const payload = token.split('.')[1]
    return JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')))
  } catch {
    return {}
  }
}

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

  // Returns the stored JWT for use in API calls
  const getToken = () => user?.accessToken || null

  // ── Email / Password ────────────────────────────────────────────────────────
  const signIn = async (email, password) => {
    const data = await authPost('/auth/login', { email, password })

    if (data.challenge) {
      // Cognito TOTP MFA required
      sessionStorage.setItem('bb-mfa-session', data.session)
      sessionStorage.setItem('bb-mfa-email', email)
      return { mfaRequired: true, session: data.session }
    }

    const payload = decodeJwt(data.idToken || data.accessToken)
    persist({
      userId:       payload.sub || email,
      email:        payload.email || email,
      name:         payload.name || email.split('@')[0],
      avatar:       null,
      accessToken:  data.accessToken,
      refreshToken: data.refreshToken,
      providers:    user?.providers || {},
    })
    return { mfaRequired: false }
  }

  // ── Google ──────────────────────────────────────────────────────────────────
  // token = Google access_token (from useGoogleLogin) or id_token (from GoogleLogin)
  const signInWithGoogle = async (token, profile) => {
    const data = await authPost('/auth/social', { provider: 'google', token })
    persist({
      userId:       data.userId || profile?.sub || profile?.id,
      email:        profile?.email || '',
      name:         profile?.name  || '',
      avatar:       profile?.picture || null,
      accessToken:  data.accessToken,
      refreshToken: data.refreshToken,
      providers: {
        ...(user?.providers || {}),
        google: { email: profile?.email, name: profile?.name, picture: profile?.picture },
      },
    })
  }

  // ── Facebook ────────────────────────────────────────────────────────────────
  const signInWithFacebook = async (accessToken, profile) => {
    const data = await authPost('/auth/social', { provider: 'facebook', token: accessToken })
    persist({
      userId:       data.userId || `fb-${profile?.id}`,
      email:        profile?.email || '',
      name:         profile?.name  || '',
      avatar:       profile?.picture || null,
      accessToken:  data.accessToken,
      refreshToken: data.refreshToken,
      providers: {
        ...(user?.providers || {}),
        facebook: { id: profile?.id, email: profile?.email, picture: profile?.picture },
      },
    })
  }

  // ── Link social to existing account ────────────────────────────────────────
  const linkGoogle = async (googleProfile) => {
    persist({
      ...user,
      providers: {
        ...(user?.providers || {}),
        google: { sub: googleProfile.sub, email: googleProfile.email, name: googleProfile.name, picture: googleProfile.picture },
      },
    })
  }

  const linkFacebook = async (fbProfile) => {
    persist({
      ...user,
      providers: {
        ...(user?.providers || {}),
        facebook: { id: fbProfile.id, email: fbProfile.email || '', name: fbProfile.name, picture: fbProfile.picture || null },
      },
    })
  }

  const unlinkProvider = (provider) => {
    const providers = { ...(user?.providers || {}) }
    delete providers[provider]
    persist({ ...user, providers })
  }

  const updateProfile = (updates) => persist({ ...user, ...updates })

  // ── MFA (TOTP confirm) ──────────────────────────────────────────────────────
  const confirmMFA = async (code) => {
    const email   = sessionStorage.getItem('bb-mfa-email')
    const session = sessionStorage.getItem('bb-mfa-session')
    if (session && email) {
      // Cognito TOTP
      const data = await authPost('/auth/login/mfa', { email, totpCode: code, session })
      const payload = decodeJwt(data.idToken || data.accessToken)
      persist({
        userId:       payload.sub || user?.userId,
        email:        payload.email || user?.email,
        name:         user?.name || payload.email?.split('@')[0] || '',
        avatar:       user?.avatar || null,
        accessToken:  data.accessToken,
        refreshToken: data.refreshToken,
        providers:    user?.providers || {},
      })
      sessionStorage.removeItem('bb-mfa-session')
      sessionStorage.removeItem('bb-mfa-email')
      setMfaPending(false)
      return true
    }
    // Fallback: email OTP (legacy)
    if (code.length === 6) {
      const current = user || JSON.parse(localStorage.getItem('bb-session') || '{}')
      persist(current)
      setMfaPending(false)
      return true
    }
    throw new Error('Invalid code')
  }

  const signUp = async (email, password) => {
    await authPost('/auth/register', { email, password })
    return { nextStep: 'CONFIRM_EMAIL' }
  }

  const signOut = async () => {
    if (user?.accessToken) {
      try {
        await fetch(`${API_BASE}/auth/logout`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.accessToken}` },
        })
      } catch { /* ignore — clear local session regardless */ }
    }
    setUser(null)
    setMfaPending(false)
    localStorage.removeItem('bb-session')
  }

  return (
    <AuthContext.Provider value={{
      user, loading, mfaPending,
      getToken,
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
