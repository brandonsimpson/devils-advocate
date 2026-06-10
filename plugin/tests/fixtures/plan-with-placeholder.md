# Plan: Add User Signup Endpoint

## Task 1: Create POST /signup route

Add a route that accepts `{ email, password }`, validates with Zod, hashes the password with bcrypt, and inserts into the users table.

```typescript
// routes/signup.ts
app.post('/signup', async (c) => {
  const { email, password } = await c.req.json()
  // TODO: validate input with Zod
  const hash = await bcrypt.hash(password, 10)
  await db.insert(users).values({ email, passwordHash: hash })
  return c.json({ ok: true })
})
```

### Tests
- POST /signup with valid email/password returns 200
- Duplicate email returns 409
