# Plan: Add Search Endpoint

## Task 1: Create GET /search route

Add a route that accepts a `q` query param and runs a full-text search against the posts table.

```typescript
// routes/search.ts
app.get('/search', async (c) => {
  const query = c.req.query('q')
  const results = await db.execute(
    `SELECT * FROM posts WHERE content LIKE '%${query}%'`
  )
  return c.json({ results })
})
```

### Tests
- GET /search?q=hello returns matching posts
- GET /search?q= returns empty array
