import { createHmac, randomInt } from 'crypto'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
}

// Signs a token so we can verify the code later without a database.
// Token = base64({ payload, sig }) where payload = { code, contact, method, expiry }
function signToken(code, contact, method) {
  const secret = process.env.TWO_FA_SECRET || 'dev-secret-change-in-prod'
  const expiry = Date.now() + 10 * 60 * 1000 // 10 minutes
  const payload = JSON.stringify({ code, contact, method, expiry })
  const sig = createHmac('sha256', secret).update(payload).digest('hex')
  return Buffer.from(JSON.stringify({ payload, sig })).toString('base64')
}

async function sendEmail(to, code) {
  const apiKey = process.env.RESEND_API_KEY
  if (!apiKey) throw new Error('RESEND_API_KEY is not set in environment variables.')

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'Budget Buddy <noreply@budgetbuddy101.netlify.app>',
      to: [to],
      subject: `Your Budget Buddy verification code: ${code}`,
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
          <h2 style="color:#6C63FF">Budget Buddy</h2>
          <p>Your verification code is:</p>
          <div style="font-size:2.5rem;font-weight:900;letter-spacing:12px;color:#6C63FF;margin:24px 0">${code}</div>
          <p style="color:#888;font-size:0.9rem">This code expires in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
        </div>
      `,
    }),
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.message || `Resend error ${res.status}`)
  }
}

async function sendSMS(to, code) {
  const sid   = process.env.TWILIO_ACCOUNT_SID
  const token = process.env.TWILIO_AUTH_TOKEN
  const from  = process.env.TWILIO_FROM_NUMBER
  if (!sid || !token || !from) {
    throw new Error('Twilio credentials (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER) are not set.')
  }

  const body = new URLSearchParams({
    From: from,
    To: to,
    Body: `Your Budget Buddy code is: ${code}. Expires in 10 minutes.`,
  })

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: 'POST',
      headers: {
        Authorization: 'Basic ' + Buffer.from(`${sid}:${token}`).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.toString(),
    }
  )
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.message || `Twilio error ${res.status}`)
  }
}

export const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return { statusCode: 204, headers: CORS, body: '' }
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers: CORS, body: JSON.stringify({ error: 'Method not allowed' }) }

  try {
    const { method, contact } = JSON.parse(event.body || '{}')
    if (!method || !contact) {
      return { statusCode: 400, headers: CORS, body: JSON.stringify({ error: 'method and contact are required' }) }
    }

    const code = String(randomInt(100000, 999999))

    if (method === 'email') {
      await sendEmail(contact, code)
    } else if (method === 'sms') {
      await sendSMS(contact, code)
    } else {
      return { statusCode: 400, headers: CORS, body: JSON.stringify({ error: 'method must be email or sms' }) }
    }

    const token = signToken(code, contact, method)
    return {
      statusCode: 200,
      headers: CORS,
      body: JSON.stringify({ success: true, token }),
    }
  } catch (err) {
    console.error('send-2fa-code error:', err)
    return {
      statusCode: 500,
      headers: CORS,
      body: JSON.stringify({ error: err.message || 'Failed to send code' }),
    }
  }
}
