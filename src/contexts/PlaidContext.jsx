import { createContext, useContext, useEffect, useReducer, useCallback } from 'react'
import { useAuth, apiFetch } from './AuthContext'

// ─── Notes on security ────────────────────────────────────────────────────────
// Plaid access tokens are NEVER sent to or stored in the browser.
// The backend (secure-finance-backend) stores them encrypted in DynamoDB.
// All Plaid calls go through our authenticated backend routes.

const PlaidContext = createContext()

// ─── Reducer ──────────────────────────────────────────────────────────────────
function reducer(state, action) {
  switch (action.type) {
    case 'ADD_ITEM':
      return {
        ...state,
        items: [
          ...state.items.filter(i => i.itemId !== action.payload.itemId),
          action.payload,
        ],
      }
    case 'UPDATE_ACCOUNTS':
      return {
        ...state,
        items: state.items.map(item =>
          item.itemId === action.itemId
            ? { ...item, accounts: action.accounts, lastRefreshed: new Date().toISOString() }
            : item
        ),
      }
    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.itemId !== action.itemId) }
    case 'SET_TRANSACTIONS':
      return { ...state, plaidTransactions: action.transactions }
    case 'SET_LOADING':
      return { ...state, loading: action.value }
    case 'SET_ERROR':
      return { ...state, error: action.message }
    default:
      return state
  }
}

function loadState() {
  try {
    const raw = localStorage.getItem('bb-plaid')
    if (raw) return JSON.parse(raw)
  } catch {}
  return { items: [], plaidTransactions: [], loading: false, error: null }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
export function PlaidProvider({ children }) {
  const { user } = useAuth()
  const [state, dispatch] = useReducer(reducer, null, loadState)

  // Persist non-ephemeral state
  useEffect(() => {
    const { loading, error, ...persisted } = state
    localStorage.setItem('bb-plaid', JSON.stringify(persisted))
  }, [state])

  // ── Get a Plaid Link token ────────────────────────────────────────────────
  const getLinkToken = useCallback(async () => {
    dispatch({ type: 'SET_LOADING', value: true })
    try {
      const data = await apiFetch('plaid/link-token', { method: 'POST' })
      return data.linkToken
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user])

  // ── Called by Plaid Link onSuccess ────────────────────────────────────────
  // Exchanges public_token → backend stores encrypted access_token in DynamoDB.
  // Response: { itemId, accounts, institutionName }
  const onPlaidSuccess = useCallback(async (public_token, metadata) => {
    dispatch({ type: 'SET_LOADING', value: true })
    dispatch({ type: 'SET_ERROR', message: null })
    try {
      const data = await apiFetch('plaid/exchange', {
        method: 'POST',
        body: JSON.stringify({ publicToken: public_token }),
      })
      dispatch({
        type: 'ADD_ITEM',
        payload: {
          itemId: data.itemId,
          institutionName: data.institutionName || metadata?.institution?.name || 'Bank',
          accounts: data.accounts,
          lastRefreshed: new Date().toISOString(),
        },
      })
      // Pull latest transactions immediately
      await _syncAll()
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user])

  // ── Refresh accounts for a specific item ─────────────────────────────────
  const refreshAccounts = useCallback(async (itemId) => {
    try {
      const accounts = await apiFetch('plaid/accounts', { method: 'GET' })
      // Filter to accounts belonging to this item
      const itemAccounts = accounts.filter(a => a.itemId === itemId)
      dispatch({ type: 'UPDATE_ACCOUNTS', itemId, accounts: itemAccounts })
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    }
  }, [])

  // ── Sync transactions from Plaid into DynamoDB, then fetch from DynamoDB ──
  const syncTransactions = useCallback(async () => {
    try {
      await apiFetch('plaid/transactions/sync', { method: 'POST' })
      const { transactions } = await apiFetch('plaid/transactions?limit=200', { method: 'GET' })
      dispatch({ type: 'SET_TRANSACTIONS', transactions })
      return transactions
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
      return []
    }
  }, [])

  // Internal: sync all items (called after linking a new account)
  const _syncAll = async () => {
    try {
      await apiFetch('plaid/transactions/sync', { method: 'POST' })
      const { transactions } = await apiFetch('plaid/transactions?limit=200', { method: 'GET' })
      dispatch({ type: 'SET_TRANSACTIONS', transactions })
    } catch { /* non-critical */ }
  }

  // ── Unlink a bank account ─────────────────────────────────────────────────
  const removeItem = useCallback(async (itemId) => {
    try {
      await apiFetch(`plaid/items/${itemId}`, { method: 'DELETE' })
    } catch { /* proceed even if backend call fails */ }
    dispatch({ type: 'REMOVE_ITEM', itemId })
  }, [])

  // ── Derived values ────────────────────────────────────────────────────────
  const totalBankBalance = state.items.reduce((sum, item) =>
    sum + (item.accounts || []).reduce((s, a) => s + (a.balances?.current || 0), 0), 0)

  const allAccounts = state.items.flatMap(item =>
    (item.accounts || []).map(a => ({
      ...a,
      institutionName: item.institutionName,
      itemId: item.itemId,
    }))
  )

  return (
    <PlaidContext.Provider value={{
      items: state.items,
      allAccounts,
      plaidTransactions: state.plaidTransactions,
      totalBankBalance,
      loading: state.loading,
      error: state.error,
      getLinkToken,
      onPlaidSuccess,
      refreshAccounts,
      syncTransactions,
      removeItem,
    }}>
      {children}
    </PlaidContext.Provider>
  )
}

export const usePlaid = () => useContext(PlaidContext)
