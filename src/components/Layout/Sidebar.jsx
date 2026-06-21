import { NavLink, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../contexts/AuthContext'
import { useTheme } from '../../contexts/ThemeContext'
import './Sidebar.css'

const navItems = [
  { to: '/',             icon: '🏠', key: 'dashboard' },
  { to: '/transactions', icon: '💸', key: 'transactions' },
  { to: '/budget',       icon: '🎯', key: 'budget' },
  { to: '/bills',        icon: '📋', key: 'bills' },
  { to: '/reports',      icon: '📊', key: 'reports' },
  { to: '/linked-accounts', icon: '🏦', key: 'linkedAccounts' },
]

export default function Sidebar({ mobileView, onToggleMobileView }) {
  const { t, i18n } = useTranslation()
  const { isDark, toggleTheme } = useTheme()
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = () => { signOut(); navigate('/auth/login') }

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <span className="sidebar-logo-icon">💰</span>
        <span className="sidebar-logo-text">Budget Buddy</span>
      </div>

      {/* Nav */}
      <nav className="sidebar-nav">
        {navItems.map(item => (
          <NavLink
            key={item.key}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) => `sidebar-item ${isActive ? 'active' : ''}`}
          >
            <span className="sidebar-item-icon">{item.icon}</span>
            <span className="sidebar-item-label">{t(item.key)}</span>
          </NavLink>
        ))}
      </nav>

      {/* Spacer */}
      <div style={{ flex: 1 }} />

      {/* Controls */}
      <div className="sidebar-controls">
        {/* Mobile view toggle */}
        <button
          className={`sidebar-control-btn ${mobileView ? 'active' : ''}`}
          onClick={onToggleMobileView}
          title={mobileView ? 'Switch to desktop view' : 'Switch to mobile view'}
        >
          <span>📱</span>
          <span>{mobileView ? 'Desktop view' : 'Mobile view'}</span>
        </button>

        {/* Language */}
        <button
          className="sidebar-control-btn"
          onClick={() => i18n.changeLanguage(i18n.language === 'en' ? 'es' : 'en')}
        >
          <span>{i18n.language === 'en' ? '🇺🇸' : '🇪🇸'}</span>
          <span>{i18n.language === 'en' ? 'English' : 'Español'}</span>
        </button>

        {/* Theme */}
        <button className="sidebar-control-btn" onClick={toggleTheme}>
          <span>{isDark ? '☀️' : '🌙'}</span>
          <span>{isDark ? 'Light mode' : 'Dark mode'}</span>
        </button>
      </div>

      {/* User profile */}
      <NavLink to="/settings" className="sidebar-user">
        {user?.avatar
          ? <img src={user.avatar} alt="" className="sidebar-avatar" />
          : <div className="sidebar-avatar sidebar-avatar-fallback">
              {(user?.name || 'U')[0]}
            </div>
        }
        <div className="sidebar-user-info">
          <p className="sidebar-user-name">{user?.name || 'User'}</p>
          <p className="sidebar-user-email">{user?.email}</p>
        </div>
        <button
          className="sidebar-signout"
          onClick={e => { e.preventDefault(); handleSignOut() }}
          title="Sign out"
        >
          ↩
        </button>
      </NavLink>
    </aside>
  )
}
