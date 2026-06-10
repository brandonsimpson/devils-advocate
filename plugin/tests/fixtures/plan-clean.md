# Plan: Add Health Check Endpoint

## Overview

Add a `GET /health` endpoint that returns `{ ok: true, version: string }`. No auth required. Used by load balancers and uptime monitors.

## Prerequisites

- Verify `tsconfig.json` has `"resolveJsonModule": true` before Task 1 (`grep resolveJsonModule tsconfig.json`).

## Task 1: Implement the route

```typescript
// routes/health.ts
import { Hono } from 'hono'
import { version } from '../package.json'

export function healthRoutes(app: Hono) {
  app.get('/health', (c) => {
    return c.json({ ok: true, version: version ?? 'unknown' })
  })
}
```

### Tests

```typescript
// routes/health.test.ts
import { describe, it, expect } from 'vitest'
import { Hono } from 'hono'
import { healthRoutes } from './health'

describe('GET /health', () => {
  it('returns 200 with ok:true and version string', async () => {
    const app = new Hono()
    healthRoutes(app)
    const res = await app.request('/health')
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.ok).toBe(true)
    expect(typeof body.version).toBe('string')
  })
})
```

## Task 2: Register before auth middleware

```typescript
// app.ts — must come before authMiddleware()
import { healthRoutes } from './routes/health'
healthRoutes(app)  // registered before auth
app.use('*', authMiddleware())
```

### Tests

```typescript
// routes/health.test.ts (add to existing describe block)
import { Hono } from 'hono'
import { healthRoutes } from './health'

it('responds 200 without Authorization header', async () => {
  const app = new Hono()
  // Register health before a mock auth middleware that rejects all requests
  healthRoutes(app)
  app.use('*', async (c, next) => { return c.json({ error: 'unauthorized' }, 401) })
  const healthRes = await app.request('/health')
  expect(healthRes.status).toBe(200)
  const blockedRes = await app.request('/other')
  expect(blockedRes.status).toBe(401)
})
```

## Verification

```bash
vitest run routes/health.test.ts  # new tests
vitest run                         # full suite — Task 2 modifies app.ts, check for regressions
```

Both must pass before merging.

## Rollback

Delete `routes/health.ts`, remove the `healthRoutes(app)` import and call from `app.ts`. No migration needed.
