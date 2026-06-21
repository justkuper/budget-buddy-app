import { createHmac } from 'crypto'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
}

function verifyToken(token, submittedCode) {
  const secret = process.env.TWO_FA_SECRET || 'dev-secret-change-in-prod'
  try {
    const { payload, sig } = JSON.parse(Buffer.from(token, 'base64').toString())
    const expectedSig = createHmac('sha256', secret).update(payload).digest('hex')
    if (sig !== expectedSig) return { valid: false, reason: 'Invalid token' }
    const { code, expiry } = JSON.parse(payload)
    if (Date.now() > expiry) return { valid: false, reason: 'Code has expired. Please request a new one.' }
    if (code !== submittedCode) return { valid: false, reason: 'Incorrect code. Please try again.' }
    return { valid: true }
  } catch {
    return { valid: false, reason: 'Invalid token' }
  }
}

export const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return { statusCode: 204, headers: CORS, body: '' }
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers: CORS, body: JSON.stringify({ error: 'Method not allowed' }) }

  try {
    const { token, code } = JSON.parse(event.body || '{}')
    if (!token || !code) {
      return { statusCode: 400, headers: CORS, body: JSON.stringify({ error: 'token and code are required' }) }
    }

    const result = verifyToken(token, code)
    return {
      statusCode: result.valid ? 200 : 400,
      headers: CORS,
      body: JSON.stringify(result.valid ? { success: true } : { error: result.reason }),
    }
  } catch (err) {
    return {
      statusCode: 500,
      headers: CORS,
      body: JSON.stringify({ error: 'Verification failed' }),
    }
  }
}
