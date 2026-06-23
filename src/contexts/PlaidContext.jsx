import { createContext, useContext, useEffect, useReducer, useCallback } from 'react'
import { useAuth } from './AuthContext'

const PlaidContext = createContext()

const API_BASE = import.meta.env.VITE_API_URL || ''

async function api(method, path, body, token) {
  const opts = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  }
  if (body) opts.body = JSON.stringify(body)
  const res = await fetch(`${API_BASE}${path}`, opts)
  const text = await res.text()
  let data
  try { data = JSON.parse(text) } catch { throw new Error(text || `Error ${res.status}`) }
  if (!res.ok) throw new Error(data.error || `Error ${res.status}`)
  return data
}

function reducer(state, action) {
  switch (action.type) {
    case 'SET_ITEMS':
      return { ...state, items: action.items }

    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.itemId !== action.itemId) }

    case 'SET_TRANSACTIONS': {
      const incoming = action.transactions
      const incomingIds = new Set(incoming.map(t => t.id))
      const kept = state.plaidTransactions.filter(t => !incomingIds.has(t.id))
      return { ...state, plaidTransactions: [...incoming, ...kept], removedPlaidIds: [] }
    }

    case 'REMOVE_TRANSACTIONS': {
      const ids = new Set(action.ids)
      return {
        ...state,
        plaidTransactions: state.plaidTransactions.filter(t => !ids.has(t.id)),
        removedPlaidIds: action.ids,
      }
    }

    case 'SET_LOADING': return { ...state, loading: action.value }
    case 'SET_ERROR':   return { ...state, error: action.message }
    default: return state
  }
}

function loadState() {
  const defaults = {
    items: [], plaidTransactions: [], removedPlaidIds: [],
    loading: false, error: null,
  }
  try {
    const raw = localStorage.getItem('bb-plaid')
    if (raw) {
      const parsed = JSON.parse(raw)
      return { ...defaults, ...parsed, removedPlaidIds: [], loading: false, error: null }
    }
  } catch {}
  return defaults
}

export function PlaidProvider({ children }) {
  const { user, getToken } = useAuth()
  const [state, dispatch] = useReducer(reducer, null, loadState)

  // Persist items + transactions (not volatile state)
  useEffect(() => {
    const { loading, error, removedPlaidIds, ...persisted } = state
    localStorage.setItem('bb-plaid', JSON.stringify(persisted))
  }, [state])

  // Load items from backend whenever user logs in
  useEffect(() => {
    const token = getToken?.()
    if (token) loadItems(token)
  }, [user?.accessToken])

  const loadItems = async (token) => {
    try {
      const items = await api('GET', '/plaid/items', null, token)
      dispatch({ type: 'SET_ITEMS', items })
    } catch { /* user may not have any items yet */ }
  }

  // Create a Plaid Link token
  const getLinkToken = useCallback(async () => {
    const token = getToken()
    if (!token) throw new Error('Please sign out and sign back in to connect your bank.')
    dispatch({ type: 'SET_LOADING', value: true })
    try {
      const data = await api('POST', '/plaid/link-token', {}, token)
      return data.linkToken
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user?.accessToken])

  // Called by Plaid Link onSuccess
  const onPlaidSuccess = useCallback(async (publicToken, _metadata) => {
    const token = getToken()
    if (!token) throw new Error('Not authenticated')
    dispatch({ type: 'SET_LOADING', value: true })
    dispatch({ type: 'SET_ERROR', message: null })
    try {
      // Exchange token — backend stores access_token encrypted in DynamoDB
      await api('POST', '/plaid/exchange', { publicToken }, token)

      // Sync transactions into DynamoDB
      await api('POST', '/plaid/transactions/sync', {}, token)

      // Reload items and transactions
      await _reloadAll(token)
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user?.accessToken])

  const _reloadAll = async (token) => {
    const [items, txData] = await Promise.all([
      api('GET', '/plaid/items', null, token),
      api('GET', '/plaid/transactions', null, token),
    ])
    dispatch({ type: 'SET_ITEMS', items })
    dispatch({ type: 'SET_TRANSACTIONS', transactions: _mapTransactions(txData.transactions || []) })
  }

  const _mapTransactions = (txs) => txs.map(tx => ({
    id:          tx.transactionId || tx.id,
    plaid_id:    tx.transactionId || tx.id,
    description: tx.name || tx.description || 'Unknown',
    amount:      Math.abs(tx.amount),
    type:        tx.amount > 0 ? 'expense' : 'income',
    category:    tx.category || 'other',
    date:        tx.date ? new Date(tx.date).toISOString() : new Date().toISOString(),
    pending:     tx.pending || false,
    logo_url:    tx.logoUrl || tx.logo_url || null,
  }))

  // Sync transactions for all items
  const syncTransactions = useCallback(async () => {
    const token = getToken()
    if (!token) return []
    try {
      await api('POST', '/plaid/transactions/sync', {}, token)
      const txData = await api('GET', '/plaid/transactions', null, token)
      const mapped = _mapTransactions(txData.transactions || [])
      dispatch({ type: 'SET_TRANSACTIONS', transactions: mapped })
      return mapped
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
      return []
    }
  }, [user?.accessToken])

  // Refresh account balances
  const refreshAccounts = useCallback(async () => {
    const token = getToken()
    if (!token) return
    try {
      const items = await api('GET', '/plaid/items', null, token)
      dispatch({ type: 'SET_ITEMS', items })
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    }
  }, [user?.accessToken])

  // Unlink a bank
  const removeItem = useCallback(async (itemId) => {
    const token = getToken()
    try {
      if (token) await api('DELETE', `/plaid/items/${itemId}`, null, token)
    } catch { /* optimistic — remove locally regardless */ }
    dispatch({ type: 'REMOVE_ITEM', itemId })
  }, [user?.accessToken])

  // Derived values
  const allAccounts = state.items.flatMap(item =>
    (item.accounts || []).map(a => ({
      ...a,
      institution: { name: item.institutionName },
      item_id: item.itemId,
    }))
  )

  const totalBankBalance = allAccounts.reduce((sum, a) => sum + (a.balances?.current || 0), 0)

  return (
    <PlaidContext.Provider value={{
      items:            state.items,
      allAccounts,
      plaidTransactions: state.plaidTransactions,
      removedPlaidIds:  state.removedPlaidIds,
      totalBankBalance,
      loading:          state.loading,
      error:            state.error,
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
