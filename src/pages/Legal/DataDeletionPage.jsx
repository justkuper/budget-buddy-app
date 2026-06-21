import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'

export default function DataDeletionPage() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const [showConfirm, setShowConfirm] = useState(false)
  const [step, setStep] = useState('idle') // 'idle' | 'confirming' | 'done'

  const handleDelete = () => {
    // Clear all app data from localStorage
    const keys = [
      'bb-data',
      'bb-data-version',
      'bb-session',
      'bb-plaid',
      'bb-mobile-view',
    ]
    keys.forEach(k => localStorage.removeItem(k))

    // Sign out
    signOut()
    setStep('done')
    setShowConfirm(false)
  }

  if (step === 'done') {
    return (
      <div style={pageStyle}>
        <div style={cardStyle}>
          <div style={{ fontSize: '3rem', marginBottom: 16, textAlign: 'center' }}>✅</div>
          <h2 style={{ ...headingStyle, textAlign: 'center' }}>Data deleted</h2>
          <p style={{ ...bodyStyle, textAlign: 'center', marginBottom: 32 }}>
            All your Budget Buddy data has been removed from this device. Your account session has been cleared.
          </p>
          <button style={btnPrimary} onClick={() => navigate('/auth/login')}>
            Back to login
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={pageStyle}>
      <div style={cardStyle}>
        <span style={{ fontSize: '2rem' }}>💰</span>
        <h1 style={{ ...headingStyle, marginTop: 8 }}>User Data Deletion</h1>
        <p style={{ color: '#9CA3AF', fontSize: '0.82rem', marginBottom: 28 }}>Budget Buddy</p>

        {user && (
          <div style={{
            background: '#F4F5FF', border: '1px solid #E8E9FF',
            borderRadius: 14, padding: '14px 16px', marginBottom: 24,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            {user.avatar
              ? <img src={user.avatar} alt="" style={{ width: 40, height: 40, borderRadius: '50%' }} />
              : <div style={{
                  width: 40, height: 40, borderRadius: '50%',
                  background: 'linear-gradient(135deg, #6C63FF, #8B85FF)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'white', fontWeight: 700, fontSize: '1rem',
                }}>
                  {(user.name || 'U')[0]}
                </div>
            }
            <div>
              <p style={{ fontWeight: 700, fontSize: '0.95rem', margin: 0 }}>{user.name}</p>
              <p style={{ color: '#6B7280', fontSize: '0.82rem', margin: 0 }}>{user.email}</p>
            </div>
          </div>
        )}

        <p style={{ ...bodyStyle, marginBottom: 16 }}>
          Deleting your data will permanently remove the following from this device:
        </p>

        <ul style={{ paddingLeft: 20, marginBottom: 28, color: '#374151', fontSize: '0.93rem', lineHeight: 2 }}>
          <li>All transactions, budgets, and bills</li>
          <li>Your account session and profile</li>
          <li>Linked bank account connections</li>
          <li>App preferences and settings</li>
        </ul>

        <div style={{
          background: '#FFF8F0', border: '1px solid #FFE0B2',
          borderRadius: 12, padding: '12px 14px', marginBottom: 28,
        }}>
          <p style={{ color: '#92400E', fontSize: '0.85rem', margin: 0 }}>
            ⚠️ This action cannot be undone. Data stored at third-party providers (Google, Facebook, Plaid) must be deleted through those services separately.
          </p>
        </div>

        <button style={btnDanger} onClick={() => setShowConfirm(true)}>
          Delete my data
        </button>

        <button style={btnGhost} onClick={() => navigate(-1)}>
          Cancel
        </button>
      </div>

      {/* Confirmation modal */}
      {showConfirm && (
        <div
          style={{
            position: 'fixed', inset: 0,
            background: 'rgba(0,0,0,0.5)',
            backdropFilter: 'blur(4px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 999, padding: 24,
          }}
          onClick={() => setShowConfirm(false)}
        >
          <div
            style={{
              background: 'white', borderRadius: 24, padding: 28,
              maxWidth: 400, width: '100%',
              boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{ fontSize: '2.5rem', textAlign: 'center', marginBottom: 16 }}>🗑️</div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, textAlign: 'center', marginBottom: 10, color: '#1A1A2E' }}>
              Are you sure?
            </h3>
            <p style={{ color: '#6B7280', fontSize: '0.9rem', textAlign: 'center', marginBottom: 24, lineHeight: 1.6 }}>
              This will permanently delete all your data and sign you out. There is no way to undo this.
            </p>
            <div style={{ display: 'flex', gap: 10 }}>
              <button
                style={{ ...btnGhost, flex: 1, border: '1.5px solid #E5E7EB', borderRadius: 14, padding: '12px 0' }}
                onClick={() => setShowConfirm(false)}
              >
                Cancel
              </button>
              <button
                style={{ ...btnDanger, flex: 1, margin: 0 }}
                onClick={handleDelete}
              >
                Yes, delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const pageStyle = {
  minHeight: '100vh',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '40px 20px',
  background: '#F4F5FF',
}

const cardStyle = {
  background: 'white',
  borderRadius: 28,
  padding: '32px 28px',
  width: '100%',
  maxWidth: 480,
  boxShadow: '0 4px 24px rgba(108,99,255,0.1)',
  border: '1px solid #E8E9FF',
}

const headingStyle = {
  fontSize: '1.5rem',
  fontWeight: 800,
  color: '#1A1A2E',
  margin: '0 0 4px',
}

const bodyStyle = {
  color: '#374151',
  fontSize: '0.93rem',
  lineHeight: 1.7,
  margin: 0,
}

const btnPrimary = {
  width: '100%', padding: '14px', borderRadius: 14, border: 'none',
  background: 'linear-gradient(135deg, #6C63FF, #8B85FF)',
  color: 'white', fontWeight: 700, fontSize: '1rem', cursor: 'pointer',
  marginBottom: 10,
}

const btnDanger = {
  width: '100%', padding: '14px', borderRadius: 14,
  border: '1.5px solid #FFD0D0',
  background: '#FFF0F0', color: '#D94F4F',
  fontWeight: 700, fontSize: '1rem', cursor: 'pointer',
  marginBottom: 10,
}

const btnGhost = {
  width: '100%', padding: '12px', borderRadius: 14, border: 'none',
  background: 'transparent', color: '#6B7280',
  fontWeight: 600, fontSize: '0.95rem', cursor: 'pointer',
}
