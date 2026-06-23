import { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useAuth } from './contexts/AuthContext'
import BottomNav from './components/Layout/BottomNav'
import Sidebar from './components/Layout/Sidebar'
import PlaidSyncBridge from './components/PlaidSyncBridge'

import LoginPage from './pages/Auth/LoginPage'
import SignupPage from './pages/Auth/SignupPage'
import TwoFactorPage from './pages/Auth/TwoFactorPage'
import DashboardPage from './pages/Dashboard/DashboardPage'
import TransactionsPage from './pages/Transactions/TransactionsPage'
import BudgetPage from './pages/Budget/BudgetPage'
import BillsPage from './pages/Bills/BillsPage'
import ReportsPage from './pages/Reports/ReportsPage'
import SettingsPage from './pages/Settings/SettingsPage'
import LinkedAccountsPage from './pages/LinkedAccounts/LinkedAccountsPage'
import TermsPage from './pages/Legal/TermsPage'
import PrivacyPage from './pages/Legal/PrivacyPage'
import DataDeletionPage from './pages/Legal/DataDeletionPage'

function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(() => window.innerWidth >= 768)
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 768px)')
    const handler = e => setIsDesktop(e.matches)
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [])
  return isDesktop
}

function PrivateRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <div className="spinner" />
  return user ? children : <Navigate to="/auth/login" replace />
}

const AppRoutes = () => (
  <Routes>
    <Route path="/auth/login"     element={<LoginPage />} />
    <Route path="/auth/signup"    element={<SignupPage />} />
    <Route path="/auth/2fa"       element={<TwoFactorPage />} />
    <Route path="/auth/2fa-setup" element={<TwoFactorPage isSetup />} />

    <Route path="/"                element={<PrivateRoute><DashboardPage /></PrivateRoute>} />
    <Route path="/transactions"    element={<PrivateRoute><TransactionsPage /></PrivateRoute>} />
    <Route path="/budget"          element={<PrivateRoute><BudgetPage /></PrivateRoute>} />
    <Route path="/bills"           element={<PrivateRoute><BillsPage /></PrivateRoute>} />
    <Route path="/reports"         element={<PrivateRoute><ReportsPage /></PrivateRoute>} />
    <Route path="/linked-accounts" element={<PrivateRoute><LinkedAccountsPage /></PrivateRoute>} />
    <Route path="/settings"        element={<PrivateRoute><SettingsPage /></PrivateRoute>} />

    <Route path="/terms"         element={<TermsPage />} />
    <Route path="/privacy"       element={<PrivacyPage />} />
    <Route path="/data-deletion" element={<DataDeletionPage />} />

    <Route path="*" element={<Navigate to="/" replace />} />
  </Routes>
)

function AppLayout() {
  const location = useLocation()
  const isAuth = location.pathname.startsWith('/auth')
  const isDesktop = useIsDesktop()
  const [mobileView, setMobileView] = useState(
    () => localStorage.getItem('bb-mobile-view') === 'true'
  )

  const toggleMobileView = () => {
    setMobileView(v => {
      localStorage.setItem('bb-mobile-view', String(!v))
      return !v
    })
  }

  if (isAuth) return <AppRoutes />

  if (!isDesktop) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
        <AppRoutes />
        <BottomNav />
      </div>
    )
  }

  return (
    <>
      <Sidebar mobileView={mobileView} onToggleMobileView={toggleMobileView} />
      <div className={`desktop-main${mobileView ? ' mobile-view' : ''}`}>
        <AppRoutes />
      </div>
    </>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      {/* Keeps Plaid transactions in sync with DataContext across the whole app */}
      <PlaidSyncBridge />
      <AppLayout />
    </BrowserRouter>
  )
}
