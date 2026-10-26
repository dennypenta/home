## Data types

Creating a new type never use a slice of pointers:

BAD:
```go
value := make([]*Event, len(events))
```

GOOD:
```go
value := make([]Event, len(events))
```

Avoid using pointers to a slice, instead return a new slice as a result:

BAD:
```go
func appendEvents(dst *[]Event) {
    ...
}
```

GOOD:
```go
func appendEvents(dst []Event) []Event {
    ...
}
```

## Style

Prefer struct-literal assertions over per-field assertions:

BAD:
```go
assert.Equal(t, "sk_mc1", product.Sku)
assert.Equal(t, "TB_AE", product.GlobalEntityID)
assert.Equal(t, "v1", product.VendorID)
```

GOOD:
```go
assert.Equal(t, Product{Sku: "sk_mc1", GlobalEntityID: "TB_AE", VendorID: "v1"}, product)
```

Comments: 1-2 lines max. Explain why, not what — well-named identifiers already say what. If a comment needs 3+ lines to justify itself, that's a signal the code needs a clearer name or a smaller function instead.

Use `require.NoError` for errors that should abort the test, `assert.Equal` for non-fatal checks.

