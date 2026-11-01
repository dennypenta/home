# Pointerless go

how many pointers you use and why you would ever care

----

---
transition: swipeLeft
---

# How may pointers are there allocated?

```go
type obj struct {
    val string
}

var s := make([]*obj, 10)
```

----

---
transition: swipeLeft
---

# How it looks natively

```c
#include <stdlib.h>
#include <string.h>

typedef struct {
    char *val;
} obj;

int main(void) {
    // 1 allocation: array of 10 pointers
    obj **s = calloc(10, sizeof(obj *));

    for (int i = 0; i < 10; i++) {
        // 1 allocation per object
        s[i] = malloc(sizeof(obj));

        // 1 allocation per string
        s[i]->val = malloc(6);
    }

    // Free all allocated memory
    for (int i = 0; i < 10; i++) {
        free(s[i]->val);
        free(s[i]);
    }
    free(s);

    return 0;
}
```

----

---
transition: swipeLeft
---

# What's a deal?

Fragmentation

a free bucket
[---- ----]

a used bucket
[==== ==--]
----

---
transition: swipeLeft
---

# What's a deal?

Cache locality

```go
type obj struct {
    another *another
    val string
}

i := obj.another
```

----

---
transition: swipeLeft
---

# Let's make it worse

```go
type another struct {
    entityID string
}

type obj struct {
    another *another
    val string
}

var s := make([]*obj, 10)
```

----

---
transition: swipeLeft
---

# Step 1

Stop using `[]*`

```go
type another struct {
    entityID string
}

type obj struct {
    another *another
    val string
}

var s := make([]obj, 10)
```

----

---
transition: swipeLeft
---

# Step 2

Stop using nested pointers

- better cache localiity
- less space required

```go
type another struct {
    entityID string
}

type obj struct {
    another another
    val string
}

var s := make([]obj, 10)
```
----

---
transition: swipeLeft
---

# What is a string?

String is `[]byte`, but more expensive for no reason

```go
// this creates a copy
b := []byte("string")
s := string(b)

// this retains a reference
b := []byte("string")
s := b
```
----

---
transition: swipeLeft
---

# Step 3

Skip designated slices pointers

```go
type another struct {
    entityID []byte
}

type obj struct {
    another another
    val []byte
}

type slice struct {
    buf []byte
    objs []obj
}

s := slice{
    buf: make([]byte, 42),
    objs: make([]obj, 10),
}

entity := "FP_SG"
val := "text"

prev := len(s.buf)
// memcpy
s.obj.buf = append(s.obj.buf, []byte(entity))
entitySlice := s.obj.buf[prev:len(s.obj.buf)]

prev := len(s.buf)
// memcpy
s.obj.buf = append(s.obj.buf, []byte(val))
valSlice := s.obj.buf[prev:len(s.obj.buf)]
s.objs = append(s.objs, obj{
    another: another{
        entityID: entitySlicey,
    },
    val: valSlice,
})
```
----

---
transition: swipeLeft
---

# Sneaky unsafe cast

Strings are just bytes slice

```go
type obj struct {
    val string
}

type slice struct {
    buf []byte
    objs []obj
}

s := slice{
    buf: make([]byte, 42),
    objs: make([]obj, 10),
}

val := "text"

prev := len(s.buf)
// memcpy
s.obj.buf = append(s.obj.buf, []byte(val))
valSlice := s.obj.buf[prev:len(s.obj.buf)]

s.objs = append(s.objs, obj{
    val: unsafe.String(&b.buf[prev], len(valSlice)),
})
```
----

---
transition: swipeLeft
---

# Get back to native again

```c
// 2 allocations
Slice s = {
    .buf = malloc(1024),
    .objs = malloc(10 * sizeof(Obj)),
};

const char *val = "text";
size_t prev = 0;

memcpy(s.buf + prev, val, strlen(val) + 1);

s.objs[0] = (Obj){
    .val = s.buf + prev,
};
```
----

---
transition: swipeLeft
---

# Custom shop arena

```go
func GetSlice() *slice {
	return slicePool.Get().(*slice)
}

func (s *slice) Release() {
	s.buf = s.buf[:0]
	s.objs = s.[:0]
	if cap(s.buf) <= maxPoolBuf {
		slicePool.Put(b)
	}
}
```
----

---
transition: swipeLeft
---

# Questions?

- [github](https://github.com/dennypenta)
- [slides](https://github.com/dennypenta/home/blob/main/talks/pointerlessgo.md)
----

---
