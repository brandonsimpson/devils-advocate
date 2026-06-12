# Plan: Add Health Check Endpoint

## Overview

Add a `GET /health` endpoint that returns `{ ok: true, version: string }`. No auth required. Used by load balancers and uptime monitors. Runtime is Node 20 (see Dockerfile).

## Prerequisites

- `hono` and `vitest` are already project dependencies (`package.json`).
- The deploy environment sets `APP_VERSION` (see `deploy.yml` env block); local dev falls back to `'dev'`.

## Task 1: Implement the route

```typescript
// routes/health.ts
import { Hono } from 'hono'

const VERSION = process.env.APP_VERSION ?? 'dev'

export function healthRoutes(app: Hono) {
  app.get('/health', (c) => {
    return c.json({ ok: true, version: VERSION })
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
// app.ts — health must be registered BEFORE authMiddleware()
import { Hono } from 'hono'
import { healthRoutes } from './routes/health'
import { authMiddleware } from './middleware/auth'

export const app = new Hono()
healthRoutes(app)                  // registered before auth
app.use('*', authMiddleware())
// ... existing protected routes
```

### Tests

```typescript
// routes/health.integration.test.ts — new file; tests the REAL app composition,
// not a fresh Hono instance, so a registration-order mistake in app.ts fails here
import { describe, it, expect } from 'vitest'
import { app } from '../app'

describe('GET /health (integration)', () => {
  it('responds 200 without an Authorization header on the real app', async () => {
    const res = await app.request('/health')
    expect(res.status).toBe(200)
  })

  it('still blocks unauthenticated requests to protected routes', async () => {
    const res = await app.request('/orders')
    expect(res.status).toBe(401)
  })
})
```

## Verification

```bash
vitest run routes/health.test.ts routes/health.integration.test.ts  # new tests
vitest run                       # full suite — Task 2 modifies app.ts, check for regressions
npm run dev & sleep 2 && curl -fsS http://localhost:3000/health     # E2E smoke: real boot, real HTTP
```

All three must pass before merging.

## Rollback

Delete `routes/health.ts` and `routes/health.integration.test.ts`, remove the `healthRoutes(app)` import and call from `app.ts`. No migration needed.
