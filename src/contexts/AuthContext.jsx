import { createContext, useContext, useEffect, useState } from 'react'

// ─── API base URL ──────────────────────────────────────────────────────────────
// Dev: Vite proxies /api → http://localhost:3001 (see vite.config.js)
// Production (Netlify): /api/* is rewritten to the serverless function
const BASE = import.meta.env.VITE_API_URL || '/api'
// ─── Token storage ─────────────────────────────────────────────────────────────
function getTokens() {
  try { return JSON.parse(localStorage.getItem('bb-tokens') || 'null') } catch { return null }
}
function saveTokens(tokens) {
  if (tokens) localStorage.setItem('bb-tokens', JSON.stringify(tokens))
  else localStorage.removeItem('bb-tokens')
}
function subFromIdToken(idToken) {
  try {
    const payload = JSON.parse(atob(idToken.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')))
    return payload.sub
  } catch { return null }
}

// ─── Authenticated fetch helper ────────────────────────────────────────────────
// Exported so PlaidContext and other contexts can reuse it
export async function apiFetch(path, options = {}) {
  const tokens = getTokens()
  const headers = { 'Content-Type': 'application/json', ...options.headers }
  if (tokens?.accessToken) headers['Authorization'] = `Bearer ${tokens.accessToken}`
  const res = await fetch(`${BASE}/${path}`, { ...options, headers })
  const data = await res.json()
  if (!res.ok) throw Object.assign(new Error(data.error || `HTTP ${res.status}`), { status: res.status })
  return data
}

// ─── Context ───────────────────────────────────────────────────────────────────
const AuthContext = createContext()

export function AuthProvider({ children }) {
  const [user, setUser]             = useState(null)
  const [loading, setLoading]       = useState(true)
  const [mfaPending, setMfaPending] = useState(false)

  // Stored during login when Cognito issues a TOTP challenge
  const [_mfaSession, _setMfaSession] = useState(null)
  const [_mfaEmail,   _setMfaEmail]   = useState(null)

  // ── Restore session on mount ─────────────────────────────────────────────
  useEffect(() => {
    const tokens  = getTokens()
    const session = localStorage.getItem('bb-session')
    if (tokens?.accessToken && session) {
      try { setUser(JSON.parse(session)) } catch {}
    }
    setLoading(false)
  }, [])

  // ── Sign Up ──────────────────────────────────────────────────────────────
  // Cognito sends a verification email; UI must then call confirmEmail()
  const signUp = async (email, password) => {
    await apiFetch('auth/register', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
    return { nextStep: 'CONFIRM_EMAIL' }
  }

  // ── Confirm email after signup ────────────────────────────────────────────
  const confirmEmail = async (email, code) => {
    await apiFetch('auth/confirm', {
      method: 'POST',
      body: JSON.stringify({ email, code }),
    })
  }

  // ── Sign In ──────────────────────────────────────────────────────────────
  // Returns:
  //   { mfaRequired: false }  — tokens stored, user logged in
  //   { mfaRequired: true }   — TOTP code required (navigate to /auth/2fa)
  const signIn = async (email, password) => {
    const result = await apiFetch('auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })

    if (result.accessToken) {
      // Login complete — no MFA challenge
      _storeSession(email, result)
      return { mfaRequired: false }
    }

    if (result.challenge === 'SOFTWARE_TOKEN_MFA') {
      // User has TOTP enabled — need code to complete login
      _setMfaSession(result.session)
      _setMfaEmail(email)
      setMfaPending(true)
      return { mfaRequired: true }
    }

    if (result.challenge === 'MFA_SETUP') {
      // Cognito wants MFA set up (pool policy) — store session for setup page
      _setMfaSession(result.session)
      _setMfaEmail(email)
      return { mfaRequired: false }
    }

    return { mfaRequired: false }
  }

  // ── Complete TOTP login challenge ────────────────────────────────────────
  const confirmMFA = async (totpCode) => {
    const result = await apiFetch('auth/login/mfa', {
      method: 'POST',
      body: JSON.stringify({ email: _mfaEmail, totpCode, session: _mfaSession }),
    })
    _storeSession(_mfaEmail, result)
    setMfaPending(false)
    _setMfaSession(null)
    _setMfaEmail(null)
    return true
  }

  // ── Google OAuth ──────────────────────────────────────────────────────────
  // To route through Cognito, set up Google as a federated IdP in your User Pool.
  // For now this stores the Google profile locally (no backend verification).
  const signInWithGoogle = async (googleProfile) => {
    const u = {
      userId:   googleProfile.sub,
      email:    googleProfile.email,
      name:     googleProfile.name,
      avatar:   googleProfile.picture,
      provider: 'google',
    }
    setUser(u)
    localStorage.setItem('bb-session', JSON.stringify(u))
  }

  // ── Facebook OAuth ────────────────────────────────────────────────────────
  const signInWithFacebook = async () => {
    const u = { userId: 'fb-demo', email: '', name: 'Facebook User', avatar: null, provider: 'facebook' }
    setUser(u)
    localStorage.setItem('bb-session', JSON.stringify(u))
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  const signOut = async () => {
    try { await apiFetch('auth/logout', { method: 'POST' }) } catch {}
    setUser(null)
    setMfaPending(false)
    _setMfaSession(null)
    _setMfaEmail(null)
    saveTokens(null)
    localStorage.removeItem('bb-session')
  }

  // ── Token refresh ─────────────────────────────────────────────────────────
  const refreshSession = async () => {
    const tokens = getTokens()
    if (!tokens?.refreshToken) return false
    try {
      const result = await apiFetch('auth/refresh', {
        method: 'POST',
        body: JSON.stringify({ refreshToken: tokens.refreshToken }),
      })
      saveTokens(result)
      return true
    } catch {
      await signOut()
      return false
    }
  }

  // ── Forgot / Reset password ───────────────────────────────────────────────
  const forgotPassword = (email) =>
    apiFetch('auth/forgot-password', { method: 'POST', body: JSON.stringify({ email }) })

  const resetPassword = (email, code, newPassword) =>
    apiFetch('auth/reset-password', {
      method: 'POST',
      body: JSON.stringify({ email, code, newPassword }),
    })

  // ── Expose access token for MFA setup calls ───────────────────────────────
  const getAccessToken = () => getTokens()?.accessToken || null

  // ── Internal helper ───────────────────────────────────────────────────────
  function _storeSession(email, tokens) {
    saveTokens(tokens)
    const userId = subFromIdToken(tokens.idToken) || email
    const u = { userId, email, name: email.split('@')[0] }
    setUser(u)
    localStorage.setItem('bb-session', JSON.stringify(u))
  }

  return (
    <AuthContext.Provider value={{
      user, loading, mfaPending,
      signIn, signUp, confirmEmail, confirmMFA,
      signInWithGoogle, signInWithFacebook,
      signOut, refreshSession,
      forgotPassword, resetPassword,
      getAccessToken,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
