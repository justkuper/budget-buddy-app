import { useState, useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import { usePlaid } from '../../contexts/PlaidContext'
import TopBar from '../../components/Layout/TopBar'
import PlaidLinkButton from '../../components/Plaid/PlaidLinkButton'

// Popular Plaid-supported institutions
const SUPPORTED_BANKS = [
  { name: 'Chase',                id: 'ins_56',   logo: '🏦', color: '#117ACA' },
  { name: 'Bank of America',      id: 'ins_127782',logo: '🏦', color: '#E31837' },
  { name: 'Wells Fargo',          id: 'ins_127989',logo: '🏦', color: '#D71E28' },
  { name: 'Citibank',             id: 'ins_7',    logo: '🏦', color: '#003B70' },
  { name: 'Capital One',          id: 'ins_128026',logo: '💳', color: '#004977' },
  { name: 'US Bank',              id: 'ins_100003',logo: '🏦', color: '#00274C' },
  { name: 'PNC Bank',             id: 'ins_13',   logo: '🏦', color: '#F58025' },
  { name: 'TD Bank',              id: 'ins_128187',logo: '🏦', color: '#34B233' },
  { name: 'Truist',               id: 'ins_128187',logo: '🏦', color: '#5B2C8D' },
  { name: 'American Express',     id: 'ins_10',   logo: '💳', color: '#016FD0' },
  { name: 'Discover',             id: 'ins_128501',logo: '💳', color: '#F76F20' },
  { name: 'Ally Bank',            id: 'ins_132251',logo: '🏦', color: '#7F35B2' },
  { name: 'Charles Schwab',       id: 'ins_4',    logo: '📈', color: '#00A0DF' },
  { name: 'Fidelity',             id: 'ins_12437',logo: '📈', color: '#006400' },
  { name: 'Vanguard',             id: 'ins_128940',logo: '📈', color: '#8B0000' },
  { name: 'Robinhood',            id: 'ins_131615',logo: '📈', color: '#00C805' },
  { name: 'SoFi',                 id: 'ins_132240',logo: '🏦', color: '#7B2D8B' },
  { name: 'Chime',                id: 'ins_132251',logo: '🏦', color: '#1EC677' },
  { name: 'Marcus by Goldman',    id: 'ins_116729',logo: '💎', color: '#5D9B9B' },
  { name: 'Navy Federal CU',      id: 'ins_135479',logo: '🏦', color: '#003087' },
  { name: 'USAA',                 id: 'ins_130026',logo: '🏦', color: '#003087' },
  { name: 'Regions Bank',         id: 'ins_129976',logo: '🏦', color: '#006747' },
  { name: 'Fifth Third Bank',     id: 'ins_5',    logo: '🏦', color: '#1A3A6B' },
  { name: 'KeyBank',              id: 'ins_6',    logo: '🏦', color: '#CC0000' },
  { name: 'Huntington Bank',      id: 'ins_9',    logo: '🏦', color: '#00B140' },
  { name: 'Citizens Bank',        id: 'ins_128498',logo: '🏦', color: '#009900' },
  { name: 'Synchrony Bank',       id: 'ins_132246',logo: '💳', color: '#00509E' },
  { name: 'Comenity Bank',        id: 'ins_133354',logo: '💳', color: '#E8792A' },
  { name: 'Barclays',             id: 'ins_128500',logo: '💳', color: '#00AEEF' },
  { name: 'PayPal',               id: 'ins_100401',logo: '💰', color: '#003087' },
]

function formatCurrency(n, code = 'USD') {
  if (n == null) return '—'
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: code }).format(n)
}

function accountTypeIcon(type, subtype) {
  if (type === 'depository') {
    if (subtype === 'checking') return '🏦'
    if (subtype === 'savings') return '💎'
    return '🏦'
  }
  if (type === 'credit') return '💳'
  if (type === 'investment') return '📈'
  if (type === 'loan') return '🏠'
  return '💰'
}

function AccountCard({ account }) {
  const { t } = useTranslation()
  const isCredit = account.type === 'credit'
  const balance = isCredit ? account.balances.current : (account.balances.available ?? account.balances.current)
  const currency = account.balances.iso_currency_code || 'USD'

  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '1px solid var(--border)',
      borderRadius: 16,
      padding: '16px',
      marginBottom: 10,
    }}>
      <div style={{display: 'flex', alignItems: 'center', gap: 12}}>
        <div style={{
          width: 46, height: 46, borderRadius: 14,
          background: isCredit ? '#FF6B6B25' : '#6C63FF20',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '1.4rem', flexShrink: 0,
        }}>
          {accountTypeIcon(account.type, account.subtype)}
        </div>
        <div style={{flex: 1, minWidth: 0}}>
          <p style={{fontWeight: 700, fontSize: '0.95rem', marginBottom: 2}}>
            {account.name}
            {account.mask && <span style={{color: 'var(--text-muted)', fontWeight: 400}}> ••{account.mask}</span>}
          </p>
          <p style={{fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'capitalize'}}>
            {account.institution?.name} · {account.subtype || account.type}
          </p>
        </div>
        <div style={{textAlign: 'right', flexShrink: 0}}>
          <p style={{
            fontWeight: 800, fontSize: '1.05rem',
            color: isCredit ? 'var(--expense)' : 'var(--income)',
          }}>
            {formatCurrency(balance, currency)}
          </p>
          <p style={{fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: 1}}>
            {isCredit ? t('balance') : t('available')}
          </p>
        </div>
      </div>
    </div>
  )
}

function InstitutionGroup({ item, onRemove, onRefresh, onSync }) {
  const { t } = useTranslation()
  const [syncing, setSyncing] = useState(false)
  const [newCount, setNewCount] = useState(null)

  const handleSync = async () => {
    setSyncing(true)
    try {
      const added = await onSync(item.item_id)
      setNewCount(added.length)
      setTimeout(() => setNewCount(null), 4000)
    } finally {
      setSyncing(false)
    }
  }

  return (
    <div style={{marginBottom: 24}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12}}>
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: 'linear-gradient(135deg, var(--primary), var(--primary-light))',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '1.1rem', color: 'white', fontWeight: 800, flexShrink: 0,
        }}>
          {item.institution?.name?.[0] || '🏦'}
        </div>
        <div style={{flex: 1}}>
          <p style={{fontWeight: 700, fontSize: '0.95rem'}}>{item.institution?.name || 'Bank'}</p>
          {item.lastRefreshed && (
            <p style={{fontSize: '0.72rem', color: 'var(--text-muted)'}}>
              {t('lastUpdated')}: {new Date(item.lastRefreshed).toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit'})}
            </p>
          )}
        </div>
        <div style={{display: 'flex', gap: 6}}>
          <button
            onClick={handleSync}
            disabled={syncing}
            style={{
              padding: '6px 10px', borderRadius: 8, border: '1.5px solid var(--border)',
              background: 'var(--bg-input)', cursor: 'pointer', fontSize: '0.8rem', fontWeight: 600,
              color: 'var(--primary)',
            }}
          >
            {syncing ? '⟳' : newCount !== null ? `+${newCount} new` : t('sync')}
          </button>
          <button
            onClick={() => onRemove(item.item_id)}
            style={{
              padding: '6px 10px', borderRadius: 8, border: '1.5px solid var(--border)',
              background: 'var(--bg-input)', cursor: 'pointer', fontSize: '0.8rem',
              color: 'var(--expense)',
            }}
          >
            {t('unlink')}
          </button>
        </div>
      </div>

      {item.accounts.map(account => (
        <AccountCard key={account.account_id} account={{...account, institution: item.institution}} />
      ))}
    </div>
  )
}

function BankPicker({ onBankSelect }) {
  const [search, setSearch] = useState('')
  const [isOpen, setIsOpen] = useState(false)

  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim()
    if (!q) return SUPPORTED_BANKS
    return SUPPORTED_BANKS.filter(b => b.name.toLowerCase().includes(q))
  }, [search])

  return (
    <div style={{width: '100%', marginBottom: 16}}>
      {/* Search input */}
      <div
        style={{
          display: 'flex', alignItems: 'center', gap: 10,
          background: 'var(--bg-input)', border: '1.5px solid var(--border)',
          borderRadius: isOpen ? '12px 12px 0 0' : 12,
          padding: '12px 14px', cursor: 'text',
          transition: 'border-color 0.2s',
        }}
        onClick={() => setIsOpen(true)}
      >
        <span style={{fontSize: '1.1rem'}}>🔍</span>
        <input
          value={search}
          onChange={e => { setSearch(e.target.value); setIsOpen(true) }}
          onFocus={() => setIsOpen(true)}
          placeholder="Search your bank or credit union…"
          style={{
            flex: 1, background: 'transparent', border: 'none', outline: 'none',
            fontSize: '0.92rem', color: 'var(--text-primary)',
          }}
        />
        {search && (
          <button
            onClick={e => { e.stopPropagation(); setSearch(''); setIsOpen(true) }}
            style={{background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', fontSize: '1rem', padding: 0}}
          >
            ✕
          </button>
        )}
        <span
          style={{color: 'var(--text-muted)', fontSize: '0.8rem', cursor: 'pointer', flexShrink: 0}}
          onClick={e => { e.stopPropagation(); setIsOpen(o => !o) }}
        >
          {isOpen ? '▲' : '▼'}
        </span>
      </div>

      {/* Dropdown list */}
      {isOpen && (
        <div style={{
          border: '1.5px solid var(--border)', borderTop: 'none',
          borderRadius: '0 0 12px 12px',
          background: 'var(--bg-card)',
          maxHeight: 280, overflowY: 'auto',
          boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
        }}>
          {filtered.length === 0 ? (
            <div style={{padding: '20px 16px', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.88rem'}}>
              No match — you can still connect via Plaid Link below
            </div>
          ) : (
            filtered.map(bank => (
              <button
                key={bank.id + bank.name}
                onClick={() => { onBankSelect(bank); setIsOpen(false); setSearch('') }}
                style={{
                  width: '100%', display: 'flex', alignItems: 'center', gap: 12,
                  padding: '11px 16px', background: 'transparent',
                  border: 'none', borderBottom: '1px solid var(--border)',
                  cursor: 'pointer', textAlign: 'left',
                  transition: 'background 0.15s',
                }}
                onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-input)'}
                onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
              >
                <div style={{
                  width: 34, height: 34, borderRadius: 9, flexShrink: 0,
                  background: bank.color + '22',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '1.1rem',
                }}>
                  {bank.logo}
                </div>
                <span style={{fontWeight: 600, fontSize: '0.9rem', color: 'var(--text-primary)'}}>
                  {bank.name}
                </span>
                <span style={{marginLeft: 'auto', color: 'var(--primary)', fontSize: '0.8rem', fontWeight: 600}}>
                  Connect →
                </span>
              </button>
            ))
          )}
          <div style={{padding: '10px 16px', fontSize: '0.75rem', color: 'var(--text-muted)', textAlign: 'center'}}>
            12,000+ institutions supported · Secured by Plaid
          </div>
        </div>
      )}
    </div>
  )
}

export default function LinkedAccountsPage() {
  const { t } = useTranslation()
  const { items, totalBankBalance, loading, error, removeItem, refreshAccounts, syncTransactions } = usePlaid()
  const [triggerOpen, setTriggerOpen] = useState(0)

  // When a bank is chosen from the picker, open Plaid Link
  const handleBankSelect = (_bank) => {
    setTriggerOpen(n => n + 1)
  }

  return (
    <div style={{flex: 1}}>
      <TopBar title={t('linkedAccounts')} />
      <div className="page">

        {/* Total balance */}
        {items.length > 0 && (
          <div className="card-gradient" style={{marginTop: 16, marginBottom: 24}}>
            <p style={{color: 'rgba(255,255,255,0.75)', fontSize: '0.85rem', marginBottom: 6}}>
              {t('totalBankBalance')}
            </p>
            <h1 style={{color: 'white', fontSize: '2.2rem', fontWeight: 900, marginBottom: 4}}>
              {new Intl.NumberFormat('en-US', {style: 'currency', currency: 'USD'}).format(totalBankBalance)}
            </h1>
            <p style={{color: 'rgba(255,255,255,0.65)', fontSize: '0.82rem'}}>
              {items.reduce((s, i) => s + i.accounts.length, 0)} {t('accountsLinked')} · {items.length} {t('banks')}
            </p>
          </div>
        )}

        {/* Error */}
        {error && (
          <div style={{
            background: '#FFF0F0', border: '1px solid #FFD0D0', color: 'var(--expense)',
            borderRadius: 12, padding: '12px 16px', marginBottom: 16, fontSize: '0.88rem',
          }}>
            ⚠️ {error}
          </div>
        )}

        {/* Empty state with bank picker */}
        {items.length === 0 && (
          <div style={{paddingTop: 24}}>
            <div style={{textAlign: 'center', marginBottom: 24}}>
              <div style={{fontSize: '2.8rem', marginBottom: 10}}>🏦</div>
              <h3 style={{marginBottom: 8, color: 'var(--text-primary)'}}>{t('noAccountsLinked')}</h3>
              <p style={{color: 'var(--text-muted)', fontSize: '0.9rem', maxWidth: 300, margin: '0 auto'}}>
                {t('linkAccountDesc')}
              </p>
            </div>

            {/* Bank search dropdown */}
            <BankPicker onBankSelect={handleBankSelect} />

            <PlaidLinkButton
              key={triggerOpen}
              onSuccess={() => {}}
              autoOpen={triggerOpen > 0}
            >
              🏦 {t('linkBankAccount')}
            </PlaidLinkButton>
          </div>
        )}

        {/* Institution groups */}
        {items.map(item => (
          <InstitutionGroup
            key={item.item_id}
            item={item}
            onRemove={removeItem}
            onRefresh={refreshAccounts}
            onSync={syncTransactions}
          />
        ))}

        {/* Add another bank */}
        {items.length > 0 && (
          <div style={{marginTop: 8}}>
            <PlaidLinkButton
              onSuccess={() => {}}
              style={{background: 'var(--bg-input)', color: 'var(--primary)', boxShadow: 'none', border: '1.5px dashed var(--primary)'}}
            >
              + {t('addAnotherBank')}
            </PlaidLinkButton>
          </div>
        )}

        {/* Security note */}
        <div style={{
          marginTop: 24, padding: '14px 16px',
          background: 'var(--bg-input)', borderRadius: 14,
          border: '1px solid var(--border)',
        }}>
          <p style={{fontSize: '0.78rem', color: 'var(--text-muted)', lineHeight: 1.6}}>
            🔒 <strong style={{color: 'var(--text-secondary)'}}>Bank-level security.</strong>{' '}
            {t('plaidSecurityNote')}
          </p>
        </div>
      </div>
    </div>
  )
}
