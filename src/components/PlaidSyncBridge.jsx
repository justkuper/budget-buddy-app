import { useEffect, useRef } from 'react'
import { usePlaid } from '../contexts/PlaidContext'
import { useData } from '../contexts/DataContext'

/**
 * Invisible component that keeps DataContext in sync with PlaidContext.
 * - When plaidTransactions changes → upsert into DataContext
 * - When removedPlaidIds changes  → remove from DataContext
 *
 * Render once inside App (inside both DataProvider and PlaidProvider).
 */
export default function PlaidSyncBridge() {
  const { plaidTransactions = [], removedPlaidIds = [] } = usePlaid()
  const { importTransactions, removeTransactions } = useData()

  // Track what we've already synced to avoid redundant dispatches
  const lastTxCount   = useRef(0)
  const lastRemovedIds = useRef([])

  useEffect(() => {
    if (plaidTransactions.length > 0 && plaidTransactions.length !== lastTxCount.current) {
      importTransactions(plaidTransactions)
      lastTxCount.current = plaidTransactions.length
    }
  }, [plaidTransactions, importTransactions])

  useEffect(() => {
    if (
      removedPlaidIds.length > 0 &&
      removedPlaidIds !== lastRemovedIds.current
    ) {
      removeTransactions(removedPlaidIds)
      lastRemovedIds.current = removedPlaidIds
    }
  }, [removedPlaidIds, removeTransactions])

  return null
}
