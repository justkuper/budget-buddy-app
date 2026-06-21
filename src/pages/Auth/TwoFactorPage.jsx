import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth, apiFetch } from '../../contexts/AuthContext'
import './Auth.css'

/**
 * TwoFactorPage
 *
 * isSetup=false  (route /auth/2fa)
 *   User just logged in and Cognito issued a SOFTWARE_TOKEN_MFA challenge.
 *   They enter their 6-digit TOTP code from Google Authenticator / Authy.
 *
 * isSetup=true   (route /auth/2fa-setup)
 *   User is enabling TOTP for the first time.
 *   Step 1: Backend issues a QR code URI → show QR image + secret.
 *   Step 2: User scans with authenticator app and enters the first code.
 *   Step 3: Backend verifies and enables MFA.
 */
export default function TwoFactorPage({ isSetup = false }) {
  const { confirmMFA, signOut, user, getAccessToken } = useAuth()
  const navigate = useNavigate()

  // ── Shared state ────────────────────────────────────────────────────────
  const [code,    setCode]    = useState(['', '', '', '', '', ''])
  const [error,   setError]   = useState('')
  const [loading, setLoading] = useState(false)
  const inputs = useRef([])

  // ── Setup-mode state ─────────────────────────────────────────────────────
  const [step,       setStep]       = useState(isSetup ? 'loading' : 'code')
  const [secretCode, setSecretCode] = useState('')
  const [qrUri,      setQrUri]      = useState('')
  const [mfaSession, setMfaSession] = useState(null)

  // ── Fetch TOTP secret on mount (setup mode only) ─────────────────────────
  useEffect(() => {
    if (!isSetup) {
      inputs.current[0]?.focus()
      return
    }
    const token = getAccessToken()
    if (!token) {
      // Google/Facebook users have no backend JWT — TOTP not applicable
      if (user?.provider) { navigate('/'); return }
      navigate('/auth/login'); return
    }

    apiFetch('auth/mfa/setup', { method: 'POST' })
      .then(({ secretCode: sc, qrUri: uri, session: sess }) => {
        setSecretCode(sc)
        setQrUri(uri)
        setMfaSession(sess)
        setStep('scan')
      })
      .catch((err) => {
        setError(err.message)
        setStep('scan') // show error in scan step
      })
  }, [isSetup])

  useEffect(() => {
    if (step === 'code') inputs.current[0]?.focus()
  }, [step])

  // ── Code input handlers ──────────────────────────────────────────────────
  const handleChange = (i, val) => {
    if (!/^\d*$/.test(val)) return
    const next = [...code]
    next[i] = val.slice(-1)
    setCode(next)
    if (val && i < 5) inputs.current[i + 1]?.focus()
  }

  const handleKeyDown = (i, e) => {
    if (e.key === 'Backspace' && !code[i] && i > 0) inputs.current[i - 1]?.focus()
  }

  const handlePaste = (e) => {
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
    if (pasted.length === 6) {
      setCode(pasted.split(''))
      inputs.current[5]?.focus()
    }
  }

  // ── Verify handler (both modes) ──────────────────────────────────────────
  const handleVerify = async () => {
    const full = code.join('')
    if (full.length < 6) return
    setLoading(true)
    setError('')
    try {
      if (isSetup) {
        // Enable MFA: POST /api/auth/mfa/verify
        await apiFetch('auth/mfa/verify', {
          method: 'POST',
          body: JSON.stringify({ totpCode: full, session: mfaSession }),
        })
        setStep('success')
      } else {
        // Complete login: AuthContext calls POST /api/auth/login/mfa
        await confirmMFA(full)
        navigate('/')
      }
    } catch (err) {
      setError(err.message || 'Incorrect code — try again.')
      setCode(['', '', '', '', '', ''])
      inputs.current[0]?.focus()
    } finally {
      setLoading(false)
    }
  }

  const qrImageUrl = qrUri
    ? `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(qrUri)}`
    : null

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div className="auth-page">
      <div className="auth-header">
        <div className="auth-logo">{step === 'success' ? '✅' : '🔐'}</div>
        <h1 className="auth-app-name">Budget Buddy</h1>
      </div>

      <div className="auth-card">

        {/* ── Loading QR ── */}
        {step === 'loading' && (
          <div style={{ textAlign: 'center', padding: '32px 0', color: 'var(--text-muted)' }}>
            Setting up authenticator…
          </div>
        )}

        {/* ── Scan QR (setup mode) ── */}
        {step === 'scan' && (
          <>
            <h2 className="auth-title">Set up Authenticator</h2>
            <p className="auth-desc">
              Scan this QR code with <strong>Google Authenticator</strong>, <strong>Authy</strong>,
              or any TOTP app. Then enter the 6-digit code it generates.
            </p>

            {error && <div className="auth-error">⚠️ {error}</div>}

            {qrImageUrl && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, margin: '20px 0' }}>
                <img
                  src={qrImageUrl}
                  alt="TOTP QR code"
                  style={{ width: 200, height: 200, borderRadius: 12, border: '1px solid var(--border)' }}
                />
                <div style={{
                  background: 'var(--bg-input)', borderRadius: 10, padding: '10px 14px',
                  fontSize: '0.78rem', color: 'var(--text-muted)', wordBreak: 'break-all',
                  maxWidth: '100%', textAlign: 'center',
                }}>
                  <p style={{ marginBottom: 4, fontWeight: 600 }}>Manual entry key:</p>
                  <code style={{ letterSpacing: 2 }}>{secretCode}</code>
                </div>
              </div>
            )}

            <button
              className="btn btn-primary"
              style={{ marginTop: 8 }}
              onClick={() => { setCode(['', '', '', '', '', '']); setStep('code') }}
            >
              I've scanned it — Next →
            </button>

            <button
              className="btn btn-ghost"
              style={{ marginTop: 8, width: '100%', fontSize: '0.85rem' }}
              onClick={() => navigate('/')}
            >
              Skip for now
            </button>
          </>
        )}

        {/* ── Enter TOTP code (both modes) ── */}
        {step === 'code' && (
          <>
            {isSetup && (
              <button
                onClick={() => setStep('scan')}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--primary)', fontSize: '0.9rem', fontWeight: 600, padding: '0 0 16px', display: 'block' }}
              >
                ← Back
              </button>
            )}

            <h2 className="auth-title">
              {isSetup ? 'Enter the code' : 'Two-factor authentication'}
            </h2>
            <p className="auth-desc">
              {isSetup
                ? 'Enter the 6-digit code shown in your authenticator app to confirm setup.'
                : 'Enter the 6-digit code from your authenticator app.'}
            </p>

            {error && <div className="auth-error">⚠️ {error}</div>}

            <div className="otp-wrapper" onPaste={handlePaste}>
              {code.map((digit, i) => (
                <input
                  key={i}
                  ref={el => inputs.current[i] = el}
                  className="otp-input"
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={e => handleChange(i, e.target.value)}
                  onKeyDown={e => handleKeyDown(i, e)}
                />
              ))}
            </div>

            <button
              className="btn btn-primary"
              onClick={handleVerify}
              disabled={loading || code.join('').length < 6}
              style={{ marginTop: 24 }}
            >
              {loading ? 'Verifying…' : 'Verify'}
            </button>

            {!isSetup && (
              <button
                className="btn btn-ghost"
                style={{ marginTop: 8, width: '100%', fontSize: '0.85rem', color: 'var(--text-muted)' }}
                onClick={() => { signOut(); navigate('/auth/login') }}
              >
                Sign in with a different account
              </button>
            )}
          </>
        )}

        {/* ── Success (setup mode) ── */}
        {step === 'success' && (
          <div style={{ textAlign: 'center', padding: '8px 0 24px' }}>
            <div style={{ fontSize: '3rem', marginBottom: 16 }}>🎉</div>
            <h2 className="auth-title" style={{ textAlign: 'center' }}>2FA Enabled!</h2>
            <p className="auth-desc" style={{ textAlign: 'center' }}>
              Your account is now protected. You'll need your authenticator app each time you sign in.
            </p>
            <button className="btn btn-primary" onClick={() => navigate('/')}>
              Go to dashboard
            </button>
          </div>
        )}

      </div>
    </div>
  )
}
