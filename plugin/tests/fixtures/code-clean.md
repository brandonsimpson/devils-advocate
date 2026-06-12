# Code Change: Add health check endpoint

Task: add `GET /health` returning `{ ok: true, version: string }`. No auth required — used by load balancers and uptime monitors. Nothing else is in scope. Runtime is Node 20; the deploy environment sets `APP_VERSION` (see `deploy.yml`), local dev falls back to `'dev'`.

Diff applied to `src/routes/health.ts` (new file):

```typescript
import { Hono } from 'hono'

const VERSION = process.env.APP_VERSION ?? 'dev'

export function healthRoutes(app: Hono) {
  app.get('/health', (c) => c.json({ ok: true, version: VERSION }))
}
```

Diff applied to `src/routes/health.test.ts` (new file):

```typescript
import { describe, it, expect } from 'vitest'
import { Hono } from 'hono'
import { healthRoutes } from './health'

describe('GET /health', () => {
  it('returns ok and a version string', async () => {
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

Diff applied to `src/app.ts` (health registered before the existing auth middleware):

```typescript
 import { Hono } from 'hono'
+import { healthRoutes } from './routes/health'
 import { authMiddleware } from './middleware/auth'

 export const app = new Hono()
+healthRoutes(app)
 app.use('*', authMiddleware())
```

Project conventions (from CLAUDE.md): routes live in `src/routes/<name>.ts` and export `<name>Routes(app)`; tests are colocated as `<name>.test.ts` using vitest. This change follows both. `hono` and `vitest` are existing project dependencies.

Test output from `npm test`:

```
PASS src/routes/health.test.ts (1 test)
PASS src/routes/orders.test.ts (2 tests)
PASS src/routes/auth.test.ts (4 tests)
Tests: 7 passed, 7 total
```

`tsc --noEmit`: clean, no errors.
