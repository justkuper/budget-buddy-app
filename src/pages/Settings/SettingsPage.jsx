import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useGoogleLogin } from '@react-oauth/google'
import { useTheme } from '../../contexts/ThemeContext'
import { useAuth } from '../../contexts/AuthContext'
import { usePlaid } from '../../contexts/PlaidContext'
import { useNavigate, Link } from 'react-router-dom'
import TopBar from '../../components/Layout/TopBar'

function loadFbSdk(appId) {
  return new Promise((resolve) => {
    if (window.FB) { resolve(window.FB); return }
    window.fbAsyncInit = () => {
      window.FB.init({ appId, cookie: true, xfbml: false, version: 'v19.0' })
      resolve(window.FB)
    }
    const s = document.createElement('script')
    s.src = 'https://connect.facebook.net/en_US/sdk.js'
    s.async = true; s.defer = true
    document.body.appendChild(s)
  })
}

function SettingRow({ icon, label, children, danger }) {
  return (
    <div style={{
      display:'flex', alignItems:'center', justifyContent:'space-between',
      padding:'14px 0', borderBottom:'1px solid var(--border)',
    }}>
      <div style={{display:'flex', alignItems:'center', gap:12}}>
        <span style={{fontSize:'1.2rem', display:'flex', alignItems:'center'}}>{icon}</span>
        <span style={{fontWeight:500, fontSize:'0.95rem', color: danger ? 'var(--expense)' : 'var(--text-primary)'}}>{label}</span>
      </div>
      {children}
    </div>
  )
}

const API_BASE = import.meta.env.VITE_API_URL || ''

function TwoFARow({ navigate, user }) {
  const [twoFaEnabled, setTwoFaEnabled] = useState(
    () => localStorage.getItem('bb-2fa-enabled') !== 'false'
  )
  const [confirming, setConfirming] = useState(false) // showing disable-confirm modal
  const [code, setCode]             = useState('')
  const [token, setToken]           = useState(null)
  const [sending, setSending]       = useState(false)
  const [error, setError]           = useState('')

  const handleToggle = async () => {
    if (!twoFaEnabled) {
      // Turning ON → go to full setup flow
      navigate('/auth/2fa-setup')
    } else {
      // Turning OFF → send a code first to confirm
      setError('')
      setSending(true)
      try {
        const res = await fetch(`${API_BASE}/api/send-2fa-code`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ method: 'email', contact: user?.email }),
        })
        const data = await res.json()
        if (!res.ok) throw new Error(data.error || 'Failed to send code')
        setToken(data.token)
        setConfirming(true)
      } catch (e) {
        setError(e.message)
      } finally {
        setSending(false)
      }
    }
  }

  const handleDisableConfirm = async () => {
    setError('')
    try {
      const res = await fetch(`${API_BASE}/api/verify-2fa-code`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, code }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || 'Incorrect code')
      localStorage.setItem('bb-2fa-enabled', 'false')
      setTwoFaEnabled(false)
      setConfirming(false)
      setCode('')
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <>
      <SettingRow icon="🔐" label="Two-Factor Auth">
        <div style={{display:'flex', alignItems:'center', gap:10}}>
          <span style={{fontSize:'0.82rem', color:'var(--text-muted)'}}>
            {twoFaEnabled ? 'On' : 'Off'}
          </span>
          <div
            onClick={!sending ? handleToggle : undefined}
            style={{
              width:44, height:24, borderRadius:12, cursor:'pointer',
              background: twoFaEnabled ? 'var(--primary)' : 'var(--border)',
              position:'relative', transition:'background 0.2s',
            }}
          >
            <div style={{
              position:'absolute', top:3, left: twoFaEnabled ? 23 : 3,
              width:18, height:18, borderRadius:'50%', background:'white',
              transition:'left 0.2s', boxShadow:'0 1px 3px rgba(0,0,0,0.2)',
            }} />
          </div>
        </div>
      </SettingRow>

      {confirming && (
        <div className="overlay" onClick={() => { setConfirming(false); setCode(''); setError('') }}>
          <div className="sheet" onClick={e => e.stopPropagation()} style={{padding:24}}>
            <div className="sheet-handle" />
            <h3 style={{fontWeight:700, marginBottom:8}}>Disable Two-Factor Auth</h3>
            <p style={{fontSize:'0.88rem', color:'var(--text-muted)', marginBottom:16}}>
              Enter the 6-digit code sent to <strong>{user?.email}</strong> to confirm.
            </p>
            {error && <div className="auth-error" style={{marginBottom:12}}>⚠️ {error}</div>}
            <input
              type="text"
              inputMode="numeric"
              maxLength={6}
              value={code}
              onChange={e => setCode(e.target.value.replace(/\D/g, ''))}
              placeholder="000000"
              style={{
                width:'100%', padding:'12px 16px', borderRadius:10, marginBottom:16,
                border:'1.5px solid var(--border)', background:'var(--bg-input)',
                color:'var(--text-primary)', fontSize:'1.2rem', letterSpacing:8, textAlign:'center',
              }}
              autoFocus
            />
            <div style={{display:'flex', gap:10}}>
              <button className="btn btn-secondary" style={{flex:1}} onClick={() => { setConfirming(false); setCode(''); setError('') }}>
                Cancel
              </button>
              <button className="btn btn-primary" style={{flex:2, background:'var(--expense)'}} onClick={handleDisableConfirm} disabled={code.length < 6}>
                Disable 2FA
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

export default function SettingsPage() {
  const { t, i18n } = useTranslation()
  const { isDark, toggleTheme } = useTheme()
  const { user, signOut, updateProfile, linkGoogle, linkFacebook, unlinkProvider } = useAuth()
  const { items, allAccounts } = usePlaid()
  const navigate = useNavigate()

  const [editingProfile, setEditingProfile] = useState(false)
  const [editName,  setEditName]  = useState(user?.name  || '')
  const [editEmail, setEditEmail] = useState(user?.email || '')
  const [editAvatar,setEditAvatar]= useState(user?.avatar|| '')

  const [notifEnabled, setNotifEnabled] = useState(
    () => localStorage.getItem('bb-notif-enabled') !== 'false'
  )
  const handleNotifToggle = () => {
    setNotifEnabled(v => {
      localStorage.setItem('bb-notif-enabled', String(!v))
      return !v
    })
  }

  const CURRENCIES = [
    { code: 'USD', symbol: '$', label: 'USD $' },
    { code: 'EUR', symbol: '€', label: 'EUR €' },
    { code: 'GBP', symbol: '£', label: 'GBP £' },
    { code: 'CAD', symbol: '$', label: 'CAD $' },
    { code: 'MXN', symbol: '$', label: 'MXN $' },
  ]
  const [currency, setCurrency] = useState(
    () => localStorage.getItem('bb-currency') || 'USD'
  )
  const handleCurrencyChange = (code) => {
    setCurrency(code)
    localStorage.setItem('bb-currency', code)
  }

  const handleSignOut = () => {
    signOut()
    navigate('/auth/login')
  }

  const handleSaveProfile = () => {
    updateProfile({ name: editName, email: editEmail, avatar: editAvatar || null })
    setEditingProfile(false)
  }

  const googleConnected   = !!user?.providers?.google
  const facebookConnected = !!user?.providers?.facebook
  const [socialError, setSocialError] = useState('')
  const [socialLoading, setSocialLoading] = useState('')

  // Connect Google inline
  const connectGoogle = useGoogleLogin({
    ux_mode: 'popup',
    onSuccess: async (tokenResponse) => {
      setSocialLoading('google')
      setSocialError('')
      try {
        const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${tokenResponse.access_token}` },
        })
        const profile = await res.json()
        await linkGoogle(profile)
      } catch (e) {
        setSocialError('Failed to connect Google: ' + e.message)
      } finally {
        setSocialLoading('')
      }
    },
    onError: () => setSocialError('Google connection was cancelled.'),
  })

  // Connect Facebook inline
  const handleConnectFacebook = async () => {
    setSocialLoading('facebook')
    setSocialError('')
    try {
      const FB_APP_ID = import.meta.env.VITE_FACEBOOK_APP_ID
      const FB = await loadFbSdk(FB_APP_ID)
      const authResponse = await new Promise((resolve, reject) => {
        FB.login(
          (res) => res.authResponse ? resolve(res.authResponse) : reject(new Error('Cancelled')),
          { scope: 'public_profile,email' }
        )
      })
      const profileData = await new Promise((resolve, reject) => {
        FB.api('/me', { fields: 'id,name,email,picture.type(large)', access_token: authResponse.accessToken },
          (data) => data && !data.error ? resolve(data) : reject(new Error('Failed to fetch profile'))
        )
      })
      await linkFacebook({
        id: profileData.id,
        name: profileData.name,
        email: profileData.email || '',
        picture: profileData.picture?.data?.url || null,
      })
    } catch (e) {
      setSocialError('Failed to connect Facebook: ' + e.message)
    } finally {
      setSocialLoading('')
    }
  }

  return (
    <div style={{flex:1}}>
      <TopBar title={t('settings')} showBack onBack={() => navigate(-1)} />
      <div className="page">

        {/* Profile Card */}
        <div className="card" style={{marginTop:20}}>
          <div style={{display:'flex', alignItems:'center', gap:16, marginBottom: editingProfile ? 16 : 0}}>
            <div style={{position:'relative'}}>
              {user?.avatar
                ? <img src={user.avatar} alt="" style={{width:60, height:60, borderRadius:'50%', objectFit:'cover'}} />
                : <div style={{
                    width:60, height:60, borderRadius:'50%',
                    background:'linear-gradient(135deg, var(--primary), var(--primary-light))',
                    display:'flex', alignItems:'center', justifyContent:'center',
                    fontSize:'1.5rem', color:'white', fontWeight:800,
                  }}>
                    {(user?.name || 'U')[0]}
                  </div>
              }
            </div>
            <div style={{flex:1}}>
              <p style={{fontWeight:700, fontSize:'1.05rem'}}>{user?.name || 'User'}</p>
              <p style={{color:'var(--text-muted)', fontSize:'0.85rem'}}>{user?.email}</p>
            </div>
            <button
              onClick={() => { setEditName(user?.name||''); setEditEmail(user?.email||''); setEditAvatar(user?.avatar||''); setEditingProfile(true) }}
              style={{background:'none', border:'1.5px solid var(--border)', borderRadius:8, padding:'5px 12px', cursor:'pointer', fontSize:'0.82rem', fontWeight:600, color:'var(--text-primary)'}}
            >
              Edit
            </button>
          </div>

          {editingProfile && (
            <div style={{borderTop:'1px solid var(--border)', paddingTop:16, display:'flex', flexDirection:'column', gap:12}}>
              <div>
                <label style={{fontSize:'0.8rem', fontWeight:600, color:'var(--text-muted)', display:'block', marginBottom:4}}>Name</label>
                <input value={editName} onChange={e => setEditName(e.target.value)}
                  style={{width:'100%', padding:'10px 12px', borderRadius:8, border:'1.5px solid var(--border)', background:'var(--bg-input)', color:'var(--text-primary)', fontSize:'0.95rem'}} />
              </div>
              <div>
                <label style={{fontSize:'0.8rem', fontWeight:600, color:'var(--text-muted)', display:'block', marginBottom:4}}>Email</label>
                <input type="email" value={editEmail} onChange={e => setEditEmail(e.target.value)}
                  style={{width:'100%', padding:'10px 12px', borderRadius:8, border:'1.5px solid var(--border)', background:'var(--bg-input)', color:'var(--text-primary)', fontSize:'0.95rem'}} />
              </div>
              <div>
                <label style={{fontSize:'0.8rem', fontWeight:600, color:'var(--text-muted)', display:'block', marginBottom:4}}>Profile Photo URL (optional)</label>
                <input value={editAvatar} onChange={e => setEditAvatar(e.target.value)} placeholder="https://..."
                  style={{width:'100%', padding:'10px 12px', borderRadius:8, border:'1.5px solid var(--border)', background:'var(--bg-input)', color:'var(--text-primary)', fontSize:'0.95rem'}} />
              </div>
              <div style={{display:'flex', gap:10}}>
                <button className="btn btn-secondary" style={{flex:1}} onClick={() => setEditingProfile(false)}>Cancel</button>
                <button className="btn btn-primary" style={{flex:2}} onClick={handleSaveProfile}>Save</button>
              </div>
            </div>
          )}
        </div>

        {/* Settings */}
        <div className="card" style={{marginTop:16}}>
          <SettingRow icon="🌙" label={t('darkMode')}>
            <label className="switch">
              <input type="checkbox" checked={isDark} onChange={toggleTheme} />
              <span className="switch-slider" />
            </label>
          </SettingRow>

          <SettingRow icon="🌐" label={t('language')}>
            <div style={{display:'flex', gap:6}}>
              <button
                onClick={() => i18n.changeLanguage('en')}
                style={{
                  padding:'5px 12px', borderRadius:8, border:'1.5px solid var(--border)',
                  background: i18n.language === 'en' ? 'var(--primary)' : 'var(--bg-input)',
                  color: i18n.language === 'en' ? 'white' : 'var(--text-primary)',
                  fontWeight:600, cursor:'pointer', fontSize:'0.85rem',
                }}
              >🇺🇸 EN</button>
              <button
                onClick={() => i18n.changeLanguage('es')}
                style={{
                  padding:'5px 12px', borderRadius:8, border:'1.5px solid var(--border)',
                  background: i18n.language === 'es' ? 'var(--primary)' : 'var(--bg-input)',
                  color: i18n.language === 'es' ? 'white' : 'var(--text-primary)',
                  fontWeight:600, cursor:'pointer', fontSize:'0.85rem',
                }}
              >🇪🇸 ES</button>
            </div>
          </SettingRow>

          <TwoFARow navigate={navigate} user={user} />

          <SettingRow icon="💵" label={t('currency')}>
            <select
              value={currency}
              onChange={e => handleCurrencyChange(e.target.value)}
              style={{
                padding:'6px 10px', borderRadius:8, border:'1.5px solid var(--border)',
                background:'var(--bg-input)', color:'var(--text-primary)',
                fontWeight:600, fontSize:'0.85rem', cursor:'pointer',
              }}
            >
              {CURRENCIES.map(c => (
                <option key={c.code} value={c.code}>{c.label}</option>
              ))}
            </select>
          </SettingRow>
        </div>

        {/* Social Accounts */}
        <div className="card" style={{marginTop:16}}>
          <p style={{fontWeight:700, fontSize:'0.8rem', color:'var(--text-muted)', textTransform:'uppercase', letterSpacing:1, paddingBottom:8, borderBottom:'1px solid var(--border)'}}>
            Social Accounts
          </p>

          {socialError && (
            <p style={{fontSize:'0.82rem', color:'var(--expense)', margin:'8px 0'}}>⚠️ {socialError}</p>
          )}

          <SettingRow icon={null} label="Facebook">
            <div style={{display:'flex', alignItems:'center', gap:8}}>
              <span style={{
                fontSize:'0.78rem', fontWeight:700, padding:'3px 8px', borderRadius:20,
                background: facebookConnected ? '#d1fae5' : '#fee2e2',
                color: facebookConnected ? '#065f46' : '#991b1b',
              }}>
                {facebookConnected ? '● Connected' : '● Not connected'}
              </span>
              <button
                onClick={facebookConnected ? () => unlinkProvider('facebook') : handleConnectFacebook}
                disabled={socialLoading === 'facebook'}
                style={{
                  fontSize:'0.78rem', fontWeight:600, padding:'3px 10px', borderRadius:8,
                  border:'1.5px solid var(--border)', background:'var(--bg-input)',
                  color:'var(--text-primary)', cursor:'pointer', opacity: socialLoading === 'facebook' ? 0.6 : 1,
                }}
              >
                {socialLoading === 'facebook' ? '…' : facebookConnected ? 'Disconnect' : 'Connect'}
              </button>
            </div>
          </SettingRow>

          <SettingRow icon={null} label="Google">
            <div style={{display:'flex', alignItems:'center', gap:8}}>
              <span style={{
                fontSize:'0.78rem', fontWeight:700, padding:'3px 8px', borderRadius:20,
                background: googleConnected ? '#d1fae5' : '#fee2e2',
                color: googleConnected ? '#065f46' : '#991b1b',
              }}>
                {googleConnected ? '● Connected' : '● Not connected'}
              </span>
              <button
                onClick={googleConnected ? () => unlinkProvider('google') : () => connectGoogle()}
                disabled={socialLoading === 'google'}
                style={{
                  fontSize:'0.78rem', fontWeight:600, padding:'3px 10px', borderRadius:8,
                  border:'1.5px solid var(--border)', background:'var(--bg-input)',
                  color:'var(--text-primary)', cursor:'pointer', opacity: socialLoading === 'google' ? 0.6 : 1,
                }}
              >
                {socialLoading === 'google' ? '…' : googleConnected ? 'Disconnect' : 'Connect'}
              </button>
            </div>
          </SettingRow>
        </div>

        {/* Bank Accounts */}
        <div className="card" style={{marginTop:16}}>
          <SettingRow icon="🏦" label={t('linkedAccounts')}>
            <Link
              to="/linked-accounts"
              style={{
                display:'inline-flex', alignItems:'center', gap:6,
                padding:'6px 14px', borderRadius:8, background:'var(--primary)',
                color:'white', fontWeight:600, fontSize:'0.85rem', textDecoration:'none',
              }}
            >
              {allAccounts.length > 0 ? `${allAccounts.length} connected` : 'Connect'} →
            </Link>
          </SettingRow>
        </div>

        <div className="card" style={{marginTop:16}}>
          <SettingRow icon="🔔" label={t('notifications')}>
            <label className="switch">
              <input type="checkbox" checked={notifEnabled} onChange={handleNotifToggle} />
              <span className="switch-slider" />
            </label>
          </SettingRow>
        </div>

        <div className="card" style={{marginTop:16}}>
          <SettingRow icon="🚪" label={t('signOut')} danger>
            <button
              className="btn btn-danger"
              style={{padding:'7px 16px', fontSize:'0.85rem'}}
              onClick={handleSignOut}
            >
              {t('signOut')}
            </button>
          </SettingRow>
        </div>

        <p style={{textAlign:'center', color:'var(--text-muted)', fontSize:'0.78rem', marginTop:32}}>
          Budget Buddy v1.0.0<br />
          Made with ❤️ for smarter spending
        </p>
      </div>
    </div>
  )
}
