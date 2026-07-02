# NoSQL Design Reference

Use this reference when the user asks for MongoDB/document design or when SQL vs NoSQL is the core decision.

## Design From Access Patterns

Document schemas optimize for known reads and writes. Before designing collections, identify:

- Which documents are read together.
- Which fields update together.
- Expected child cardinality.
- Whether child records are shared across parents.
- Maximum document growth over time.

If access patterns are unknown, say so and prefer a relational design or a conservative document model.

## Embed vs Reference

| Factor | Embed | Reference |
|--------|-------|-----------|
| Read pattern | Read together | Read separately |
| Cardinality | One-to-few, bounded | One-to-many, unbounded |
| Update frequency | Parent/child update together | Child updates independently |
| Ownership | Child belongs to one parent | Child shared or independently queried |
| Size risk | Safely below document limit | Could grow without bound |

Embedded order snapshot:

```json
{
  "_id": "order_123",
  "customer": {
    "id": "cust_456",
    "name": "Jane Smith",
    "email": "jane@example.com"
  },
  "items": [
    { "product_id": "prod_789", "quantity": 2, "price": 29.99 }
  ],
  "total": 109.97
}
```

Referenced order:

```json
{
  "_id": "order_123",
  "customer_id": "cust_456",
  "item_ids": ["item_1", "item_2"],
  "total": 109.97
}
```

Use snapshots for historical facts like order customer name or item price at purchase time. Use references for mutable shared entities like current customer profile or product catalog.

## Indexes

Add indexes for actual query shapes:

```javascript
db.users.createIndex({ email: 1 }, { unique: true });
db.orders.createIndex({ customer_id: 1, created_at: -1 });
db.articles.createIndex({ title: "text", content: "text" });
db.stores.createIndex({ location: "2dsphere" });
```

Name the query each index supports and call out write amplification for heavily updated collections.

## Review Findings

Treat these as likely issues:

- Unbounded arrays inside a document.
- Duplicated mutable data without an owner or sync story.
- References that require many round trips for the primary read path.
- Missing unique indexes for identifiers like email or slug.
- No retention/archive plan for append-only event collections.
- Document shape that mixes unrelated access patterns because it mirrors a UI screen.
