/**
 * Local development API server
 * Runs the Lambda functions locally so /api/* calls work in dev
 *
 * Usage: node local-api-server.js
 * Then run: npm run dev  (in a separate terminal)
 *
 * Requires a .env file with your keys set.
 */

import { createServer } from 'http'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const PORT = 4000

// Load .env
try {
  const env = readFileSync(resolve(__dirname, '.env'), 'utf-8')
  env.split('\n').forEach(line => {
    const [k, ...v] = line.split('=')
    if (k && !k.startsWith('#')) process.env[k.trim()] = v.join('=').trim()
  })
} catch {}

// Map route name → function file
const routes = {
  'create-link-token':    './functions/create-link-token.js',
  'exchange-public-token':'./functions/exchange-public-token.js',
  'get-accounts':         './functions/get-accounts.js',
  'sync-transactions':    './functions/sync-transactions.js',
  'send-2fa-code':        './functions/send-2fa-code.js',
  'verify-2fa-code':      './functions/verify-2fa-code.js',
}

const server = createServer(async (req, res) => {
  const name = req.url.replace(/^\/api\//, '').split('?')[0]
  const file = routes[name]

  if (!file) {
    res.writeHead(404, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ error: `Unknown route: ${req.url}` }))
    return
  }

  let body = ''
  req.on('data', chunk => body += chunk)
  req.on('end', async () => {
    try {
      const mod = await import(`${file}?t=${Date.now()}`)
      const event = { httpMethod: req.method, body, headers: req.headers }
      const result = await mod.handler(event)
      res.writeHead(result.statusCode, result.headers || { 'Content-Type': 'application/json' })
      res.end(result.body)
    } catch (e) {
      console.error(e)
      res.writeHead(500, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ error: e.message }))
    }
  })
})

server.listen(PORT, () => console.log(`Local API server running at http://localhost:${PORT}`))
