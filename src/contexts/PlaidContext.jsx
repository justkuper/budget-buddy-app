import { createContext, useContext, useEffect, useReducer, useCallback } from 'react'
import { useAuth } from './AuthContext'

const PlaidContext = createContext()

const API_BASE = import.meta.env.VITE_API_URL || ''

const API = async (path, body) => {
  const res = await fetch(`${API_BASE}/api/${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.error || `API error ${res.status}`)
  return data
}

function reducer(state, action) {
  switch (action.type) {
    case 'ADD_ITEM':
      return {
        ...state,
        items: [
          ...state.items.filter(i => i.item_id !== action.payload.item_id),
          action.payload,
        ],
      }
    case 'UPDATE_ACCOUNTS':
      return {
        ...state,
        items: state.items.map(item =>
          item.item_id === action.item_id
            ? { ...item, accounts: action.accounts, lastRefreshed: new Date().toISOString() }
            : item
        ),
      }
    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.item_id !== action.item_id) }

    case 'SYNC_TRANSACTIONS': {
      // Upsert added+modified into plaidTransactions; remove deleted ones
      const { added, modified, removed, item_id, next_cursor } = action
      const removedIds = new Set(removed)
      const upserted = [...added, ...modified]
      const upsertedIds = new Set(upserted.map(t => t.id))

      const existing = state.plaidTransactions.filter(
        t => !removedIds.has(t.id) && !upsertedIds.has(t.id)
      )
      return {
        ...state,
        plaidTransactions: [...upserted, ...existing],
        removedPlaidIds: removed,   // surface to bridge for DataContext cleanup
        cursors: { ...state.cursors, [item_id]: next_cursor },
      }
    }

    case 'SET_LOADING':
      return { ...state, loading: action.value }
    case 'SET_ERROR':
      return { ...state, error: action.message }
    default:
      return state
  }
}

function loadState() {
  const defaults = { items: [], plaidTransactions: [], removedPlaidIds: [], cursors: {}, loading: false, error: null }
  try {
    const raw = localStorage.getItem('bb-plaid')
    if (raw) return { ...defaults, ...JSON.parse(raw), removedPlaidIds: [], loading: false, error: null }
  } catch {}
  return defaults
}

export function PlaidProvider({ children }) {
  const { user } = useAuth()
  const [state, dispatch] = useReducer(reducer, null, loadState)

  useEffect(() => {
    const { loading, error, removedPlaidIds, ...persisted } = state
    localStorage.setItem('bb-plaid', JSON.stringify(persisted))
  }, [state])

  const getLinkToken = useCallback(async () => {
    dispatch({ type: 'SET_LOADING', value: true })
    try {
      const data = await API('create-link-token', { userId: user?.userId || 'demo-user' })
      return data.link_token
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user])

  const onPlaidSuccess = useCallback(async (public_token, metadata) => {
    dispatch({ type: 'SET_LOADING', value: true })
    dispatch({ type: 'SET_ERROR', message: null })
    try {
      const data = await API('exchange-public-token', {
        public_token,
        institution: metadata.institution,
        userId: user?.userId || 'demo-user',
      })
      dispatch({
        type: 'ADD_ITEM',
        payload: {
          item_id: data.item_id,
          access_token: data.access_token,
          institution: data.institution,
          accounts: data.accounts,
          lastRefreshed: new Date().toISOString(),
        },
      })
      await _syncTransactions(data.item_id, data.access_token, null)
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    } finally {
      dispatch({ type: 'SET_LOADING', value: false })
    }
  }, [user])

  const _syncTransactions = async (item_id, access_token, cursor) => {
    try {
      const data = await API('sync-transactions', { access_token, cursor })
      dispatch({
        type: 'SYNC_TRANSACTIONS',
        item_id,
        added:       data.added,
        modified:    data.modified || [],
        removed:     data.removed  || [],
        next_cursor: data.next_cursor,
      })
      return data.added
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
      return []
    }
  }

  const refreshAccounts = useCallback(async (item_id) => {
    const item = state.items.find(i => i.item_id === item_id)
    if (!item) return
    try {
      const data = await API('get-accounts', { access_token: item.access_token })
      dispatch({ type: 'UPDATE_ACCOUNTS', item_id, accounts: data.accounts })
    } catch (e) {
      dispatch({ type: 'SET_ERROR', message: e.message })
    }
  }, [state.items])

  const syncTransactions = useCallback(async (item_id) => {
    const item = state.items.find(i => i.item_id === item_id)
    if (!item) return []
    const cursor = state.cursors[item_id] || null
    return _syncTransactions(item_id, item.access_token, cursor)
  }, [state.items, state.cursors])

  const removeItem = useCallback((item_id) => {
    dispatch({ type: 'REMOVE_ITEM', item_id })
  }, [])

  const totalBankBalance = state.items.reduce((sum, item) =>
    sum + item.accounts.reduce((s, a) => s + (a.balances.current || 0), 0), 0)

  const allAccounts = state.items.flatMap(item =>
    item.accounts.map(a => ({ ...a, institution: item.institution, item_id: item.item_id }))
  )

  return (
    <PlaidContext.Provider value={{
      items: state.items,
      allAccounts,
      plaidTransactions: state.plaidTransactions,
      removedPlaidIds: state.removedPlaidIds,
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
