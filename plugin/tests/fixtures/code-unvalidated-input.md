# Code Change: Add order search endpoint

Task: let support staff search orders by customer name.

Diff applied to `src/routes/orders.ts`:

```typescript
export async function searchOrders(req: Request, res: Response) {
  const { customer } = req.query;
  const rows = await db.raw(
    "SELECT * FROM orders WHERE customer_name LIKE '%" + customer + "%' ORDER BY created_at DESC"
  );
  return res.json(rows);
}
```

Diff applied to `src/routes/orders.test.ts`:

```typescript
it('finds orders by customer name', async () => {
  const res = await request(app).get('/orders/search?customer=Smith');
  expect(res.status).toBe(200);
  expect(res.body.length).toBeGreaterThan(0);
});
```

Test output from `npm test`:

```
PASS src/routes/orders.test.ts (3 tests)
Tests: 3 passed, 3 total
```

Project conventions (from CLAUDE.md): all routes live in `src/routes/<name>.ts`; the rest of the codebase uses knex query builder methods (`db('orders').where(...)`) for database access.
