import { useState, useRef } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../contexts/AuthContext'
import './Auth.css'

export default function SignupPage() {
  const { t } = useTranslation()
  const { signUp, confirmEmail, signIn } = useAuth()
  const navigate = useNavigate()

  // 'form' → show signup fields
  // 'confirm' → show email verification code input
  const [step, setStep] = useState('form')

  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')

  // 6-digit confirmation code
  const [code, setCode] = useState(['', '', '', '', '', ''])
  const inputs = useRef([])

  // ── Step 1: Register ──────────────────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await signUp(email, password)
      setStep('confirm')
      setTimeout(() => inputs.current[0]?.focus(), 50)
    } catch (err) {
      setError(err.message || t('error'))
    } finally {
      setLoading(false)
    }
  }

  // ── Step 2: Confirm email ─────────────────────────────────────────────────
  const handleConfirm = async () => {
    const full = code.join('')
    if (full.length < 6) return
    setLoading(true)
    setError('')
    try {
      await confirmEmail(email, full)
      // Auto sign-in then go to MFA setup
      const result = await signIn(email, password)
      navigate(result?.mfaRequired ? '/auth/2fa' : '/auth/2fa-setup')
    } catch (err) {
      setError(err.message || 'Incorrect code — try again.')
      setCode(['', '', '', '', '', ''])
      inputs.current[0]?.focus()
    } finally {
      setLoading(false)
    }
  }

  // ── Code input helpers ────────────────────────────────────────────────────
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

  return (
    <div className="auth-page">
      <div className="auth-header">
        <div className="auth-logo">💰</div>
        <h1 className="auth-app-name">Budget Buddy</h1>
      </div>

      <div className="auth-card">

        {/* ── Registration form ── */}
        {step === 'form' && (
          <>
            <h2 className="auth-title">{t('createAccount')}</h2>

            {error && <div className="auth-error">⚠️ {error}</div>}

            <form onSubmit={handleSubmit} className="auth-form">
              <div className="form-group">
                <label className="form-label">{t('email')}</label>
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="hello@example.com"
                  required
                  autoComplete="email"
                />
              </div>
              <div className="form-group">
                <label className="form-label">{t('password')}</label>
                <input
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="Min 8 chars, 1 uppercase, 1 number, 1 symbol"
                  required
                  minLength={8}
                  autoComplete="new-password"
                />
              </div>
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? t('loading') : t('createAccount')}
              </button>
            </form>

            <p className="auth-switch">
              {t('alreadyHaveAccount')}{' '}
              <Link to="/auth/login" style={{ color: 'var(--primary)', fontWeight: 600 }}>
                {t('signIn')}
              </Link>
            </p>
          </>
        )}

        {/* ── Email confirmation ── */}
        {step === 'confirm' && (
          <>
            <button
              onClick={() => setStep('form')}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--primary)', fontSize: '0.9rem', fontWeight: 600, padding: '0 0 16px', display: 'block' }}
            >
              ← Back
            </button>

            <h2 className="auth-title">Check your email</h2>
            <p className="auth-desc">
              We sent a 6-digit verification code to <strong>{email}</strong>. Enter it below to confirm your account.
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
              onClick={handleConfirm}
              disabled={loading || code.join('').length < 6}
              style={{ marginTop: 24 }}
            >
              {loading ? 'Verifying…' : 'Confirm email'}
            </button>

            <p style={{ marginTop: 16, fontSize: '0.85rem', color: 'var(--text-muted)', textAlign: 'center' }}>
              Didn't receive it? Check your spam folder or{' '}
              <button
                className="btn btn-ghost"
                style={{ display: 'inline', padding: 0, fontSize: 'inherit', color: 'var(--primary)' }}
                onClick={() => setStep('form')}
              >
                try a different email
              </button>.
            </p>
          </>
        )}

      </div>
    </div>
  )
}
