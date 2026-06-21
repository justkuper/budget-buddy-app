import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../contexts/AuthContext'
import './Auth.css'

const API_BASE = import.meta.env.VITE_API_URL || ''

async function sendCode(method, contact) {
  const res = await fetch(`${API_BASE}/api/send-2fa-code`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ method, contact }),
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || 'Failed to send code')
  return data.token
}

async function verifyCode(token, code) {
  const res = await fetch(`${API_BASE}/api/verify-2fa-code`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, code }),
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || 'Incorrect code')
  return true
}

export default function TwoFactorPage({ isSetup = false }) {
  const { t } = useTranslation()
  const { confirmMFA, signOut, user } = useAuth()
  const navigate = useNavigate()

  // Steps: 'choose' → 'contact' → 'code' → 'success'
  const [step, setStep]         = useState(isSetup ? 'choose' : 'code')
  const [method, setMethod]     = useState('email')   // 'email' | 'sms'
  const [contact, setContact]   = useState(user?.email || '')
  const [sending, setSending]   = useState(false)
  const [verifyToken, setVerifyToken] = useState(null) // HMAC token returned from server
  const [code, setCode]         = useState(['', '', '', '', '', ''])
  const [error, setError]       = useState('')
  const [loading, setLoading]   = useState(false)
  const inputs = useRef([])

  useEffect(() => {
    if (step === 'code') inputs.current[0]?.focus()
  }, [step])

  // ── Step 1: choose method ──────────────────────────────────────────────────
  const handleChooseMethod = (m) => {
    setMethod(m)
    setContact(m === 'email' ? (user?.email || '') : '')
    setStep('contact')
  }

  // ── Step 2: send the code ──────────────────────────────────────────────────
  const handleSendCode = async (e) => {
    e.preventDefault()
    if (!contact.trim()) return
    setError('')
    setSending(true)
    try {
      const token = await sendCode(method, contact)
      setVerifyToken(token)
      setStep('code')
    } catch (err) {
      setError(err.message || 'Failed to send code. Try again.')
    } finally {
      setSending(false)
    }
  }

  // ── Step 3: verify the code ────────────────────────────────────────────────
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

  const handleVerify = async () => {
    const full = code.join('')
    if (full.length < 6) return
    setLoading(true)
    setError('')
    try {
      if (verifyToken) {
        // Real server-side verification
        await verifyCode(verifyToken, full)
      } else {
        // Fallback: confirmMFA for login 2FA flow (token already set up on server)
        await confirmMFA(full)
      }
      if (isSetup) setStep('success')
      else navigate('/')
    } catch (err) {
      setError(err.message || 'Incorrect code. Please try again.')
      setCode(['', '', '', '', '', ''])
      inputs.current[0]?.focus()
    } finally {
      setLoading(false)
    }
  }

  const maskedContact = method === 'email'
    ? contact.replace(/(.{2}).+(@.+)/, '$1•••$2')
    : contact.replace(/(\d{3})\d+(\d{2})/, '$1•••••$2')

  // ── Renders ────────────────────────────────────────────────────────────────
  return (
    <div className="auth-page">
      <div className="auth-header">
        <div className="auth-logo">{step === 'success' ? '✅' : '🔐'}</div>
        <h1 className="auth-app-name">Budget Buddy</h1>
      </div>

      <div className="auth-card">

        {/* ── Choose method ── */}
        {step === 'choose' && (
          <>
            <h2 className="auth-title">Secure your account</h2>
            <p className="auth-desc">
              Two-factor authentication adds an extra layer of security. Choose how you'd like to receive your verification code.
            </p>

            <div style={{display:'flex', flexDirection:'column', gap:12, marginBottom:24}}>
              <button
                className="twofa-method-btn"
                onClick={() => handleChooseMethod('email')}
              >
                <span style={{fontSize:'1.6rem'}}>📧</span>
                <div style={{textAlign:'left'}}>
                  <p style={{fontWeight:700, marginBottom:2}}>Email</p>
                  <p style={{fontSize:'0.82rem', color:'var(--text-muted)'}}>We'll send a code to your email address</p>
                </div>
                <span style={{marginLeft:'auto', color:'var(--text-muted)'}}>›</span>
              </button>

              <button
                className="twofa-method-btn"
                onClick={() => handleChooseMethod('sms')}
              >
                <span style={{fontSize:'1.6rem'}}>📱</span>
                <div style={{textAlign:'left'}}>
                  <p style={{fontWeight:700, marginBottom:2}}>Text Message (SMS)</p>
                  <p style={{fontSize:'0.82rem', color:'var(--text-muted)'}}>We'll send a code to your phone number</p>
                </div>
                <span style={{marginLeft:'auto', color:'var(--text-muted)'}}>›</span>
              </button>
            </div>

            <button
              className="btn btn-ghost"
              style={{width:'100%'}}
              onClick={() => navigate('/')}
            >
              Skip for now
            </button>
          </>
        )}

        {/* ── Enter contact ── */}
        {step === 'contact' && (
          <>
            <button
              onClick={() => setStep('choose')}
              style={{background:'none', border:'none', cursor:'pointer', color:'var(--primary)', fontSize:'0.9rem', fontWeight:600, padding:'0 0 16px', display:'block'}}
            >
              ← Back
            </button>

            <h2 className="auth-title">
              {method === 'email' ? 'Enter your email' : 'Enter your phone number'}
            </h2>
            <p className="auth-desc">
              {method === 'email'
                ? "We'll send a 6-digit verification code to this address."
                : "We'll text a 6-digit verification code to this number. Standard rates may apply."}
            </p>

            {error && <div className="auth-error">⚠️ {error}</div>}

            <form onSubmit={handleSendCode} className="auth-form">
              <div className="form-group">
                <label className="form-label">
                  {method === 'email' ? 'Email address' : 'Phone number'}
                </label>
                <input
                  type={method === 'email' ? 'email' : 'tel'}
                  value={contact}
                  onChange={e => setContact(e.target.value)}
                  placeholder={method === 'email' ? 'hello@example.com' : '+1 (555) 000-0000'}
                  required
                  autoFocus
                />
              </div>
              <button type="submit" className="btn btn-primary" disabled={sending || !contact.trim()}>
                {sending ? 'Sending code…' : 'Send code'}
              </button>
            </form>
          </>
        )}

        {/* ── Enter code ── */}
        {step === 'code' && (
          <>
            {isSetup && (
              <button
                onClick={() => setStep('contact')}
                style={{background:'none', border:'none', cursor:'pointer', color:'var(--primary)', fontSize:'0.9rem', fontWeight:600, padding:'0 0 16px', display:'block'}}
              >
                ← Back
              </button>
            )}

            <h2 className="auth-title">Enter verification code</h2>
            <p className="auth-desc">
              {isSetup
                ? <>A 6-digit code was sent to <strong>{maskedContact}</strong>. Enter it below to confirm.</>
                : <>Enter the 6-digit code sent to your verified {method === 'email' ? 'email' : 'phone'}.</>
              }
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
              style={{marginTop:24}}
            >
              {loading ? 'Verifying…' : 'Verify'}
            </button>

            <button
              className="btn btn-ghost"
              style={{marginTop:12, width:'100%', fontSize:'0.88rem'}}
              onClick={async () => {
              setError('')
              setSending(true)
              try {
                const token = await sendCode(method, contact)
                setVerifyToken(token)
                setCode(['', '', '', '', '', ''])
                inputs.current[0]?.focus()
              } catch (err) {
                setError(err.message || 'Failed to resend code.')
              } finally {
                setSending(false)
              }
            }}
            >
              Didn't receive a code? Resend
            </button>

            {!isSetup && (
              <button
                className="btn btn-ghost"
                style={{marginTop:4, width:'100%', fontSize:'0.85rem', color:'var(--text-muted)'}}
                onClick={() => { signOut(); navigate('/auth/login') }}
              >
                Sign in with a different account
              </button>
            )}
          </>
        )}

        {/* ── Success ── */}
        {step === 'success' && (
          <>
            <div style={{textAlign:'center', padding:'8px 0 24px'}}>
              <div style={{fontSize:'3rem', marginBottom:16}}>🎉</div>
              <h2 className="auth-title" style={{textAlign:'center'}}>2FA Enabled!</h2>
              <p className="auth-desc" style={{textAlign:'center'}}>
                Your account is now protected. You'll be asked for a code each time you sign in.
              </p>
              <div style={{
                background:'var(--bg-input)', borderRadius:14, padding:'14px 16px',
                marginBottom:24, textAlign:'left', border:'1px solid var(--border)'
              }}>
                <p style={{fontSize:'0.82rem', color:'var(--text-muted)', marginBottom:4}}>Verification sent to</p>
                <p style={{fontWeight:700}}>{maskedContact}</p>
              </div>
            </div>
            <button className="btn btn-primary" onClick={() => navigate('/')}>
              Go to dashboard
            </button>
          </>
        )}

      </div>
    </div>
  )
}
