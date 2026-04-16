## Thread-safe `Table` using malebolgia's fair `TicketRWLock` (reader-writer spinlock
## from `ticketlocks`). Read operations take the read lock; mutating operations take
## the write lock.
##
## `RwTable` is a plain `object` (not `ref`). Pass **`var RwTable`** to every operation
## so the inner `Table` is not copied. For sharing between threads, store the
## `RwTable` in a location every thread can reach (e.g. module var, heap block, channel).
##
## Lookups return plain copies, not `lent`/`var` into storage. The `pairs` iterator
## holds the read lock for the **entire** `for` loop (all `yield` points). Use
## `withReadTable` / `withWriteTable` when you need a `Table` snapshot or full
## `Table` API under a lock.

#[
source: araq on forum
ADAP HIS
- table > orderedtable
]#


import std/tables
import malebolgia/ticketlocks
#import std/[random,os]


export withReadLock, withWriteLock, acquireRead, releaseRead, acquireWrite, releaseWrite
export initTicketRWLock, TicketRWLock

type
  RwTable*[K, V] = object
    table: OrderedTable[K, V]
    rw: TicketRWLock

proc initRwTable*[K, V](initialSize = defaultInitialSize): RwTable[K, V] =
  ## Creates an empty table protected by a new reader-writer lock.
  RwTable[K, V](table: initOrderedTable[K, V](initialSize), rw: initTicketRWLock())

proc initRwTable*[K, V](t: var RwTable[K, V], initialSize = defaultInitialSize) =
  ## Fills `t` with an empty table and a fresh lock.
  t.table = initOrderedTable[K, V](initialSize)
  t.rw = initTicketRWLock()

proc toRwTable*[K, V](pairs: openArray[(K, V)]): RwTable[K, V] =
  ## Builds an `RwTable` from `pairs`.
  result = initRwTable[K, V]()
  withWriteLock(result.rw):
    result.table = toOrderedTable(pairs)

template withReadTable*[K, V](m: var RwTable[K, V]; tabName: untyped; body: untyped) =
  ## Snapshot of the inner `Table` while holding the read lock (a copy of `Table`).
  withReadLock(m.rw):
    let `tabName` = m.table
    body

template withWriteTable*[K, V](m: var RwTable[K, V]; tabName: untyped; body: untyped) =
  ## Mutable access via a temporary `Table` while holding the write lock; writes the
  ## table back in `finally`.
  withWriteLock(m.rw):
    var `tabName` = m.table
    try:
      body
    finally:
      m.table = `tabName`

# --- Read lock ---

proc len*[K, V](t: var RwTable[K, V]): int {.inline.} =
  withReadLock(t.rw):
    result = t.table.len

proc `[]`*[K, V](t: var RwTable[K, V], key: K): V {.inline.} =
  ## Value copy of `t[key]`.
  withReadLock(t.rw):
    result = t.table[key]

proc getOrDefault*[K, V](t: var RwTable[K, V], key: K): V {.inline.} =
  withReadLock(t.rw):
    result = getOrDefault(t.table, key)

proc getOrDefault*[K, V](t: var RwTable[K, V], key: K, default: V): V {.inline.} =
  withReadLock(t.rw):
    result = getOrDefault(t.table, key, default)

proc hasKey*[K, V](t: var RwTable[K, V], key: K): bool {.inline.} =
  withReadLock(t.rw):
    result = hasKey(t.table, key)

proc contains*[K, V](t: var RwTable[K, V], key: K): bool {.inline.} =
  withReadLock(t.rw):
    result = contains(t.table, key)

proc `$`*[K, V](t: var RwTable[K, V]): string =
  withReadLock(t.rw):
    result = $t.table

proc `==`*[K, V](a, b: var RwTable[K, V]): bool =
  ## Compares inner tables. Uses address ordering for the two locks when `a` and `b`
  ## are distinct objects.
  if addr(a) == addr(b):
    return true
  if cast[uint](addr(a)) < cast[uint](addr(b)):
    withReadLock(a.rw):
      withReadLock(b.rw):
        result = a.table == b.table
  else:
    withReadLock(b.rw):
      withReadLock(a.rw):
        result = a.table == b.table

iterator pairs*[K, V](t: var RwTable[K, V]): (K, V) =
  ## Yields `(key, value)` like `tables.pairs`. The read lock is held from before the
  ## first element until the loop ends (including `break`).
  acquireRead(t.rw)
  try:
    for k, v in pairs(t.table):
      yield (k, v)
  finally:
    releaseRead(t.rw)

# --- Write lock ---

proc `[]=`*[K, V](t: var RwTable[K, V], key: sink K, val: sink V) {.inline.} =
  withWriteLock(t.rw):
    t.table[key] = val

proc hasKeyOrPut*[K, V](t: var RwTable[K, V], key: K, val: V): bool {.inline.} =
  withWriteLock(t.rw):
    result = hasKeyOrPut(t.table, key, val)

proc add*[K, V](t: var RwTable[K, V], key: sink K, val: sink V) {.inline.} =
  withWriteLock(t.rw):
    add(t.table, key, val)

proc del*[K, V](t: var RwTable[K, V], key: K) {.inline.} =
  withWriteLock(t.rw):
    del(t.table, key)

proc pop*[K, V](t: var RwTable[K, V], key: K, val: var V): bool {.inline.} =
  ## On success, copies the removed value into `val` (your variable, not a table borrow).
  withWriteLock(t.rw):
    result = pop(t.table, key, val)

proc take*[K, V](t: var RwTable[K, V], key: K, val: var V): bool {.inline.} =
  withWriteLock(t.rw):
    result = take(t.table, key, val)

proc clear*[K, V](t: var RwTable[K, V]) {.inline.} =
  withWriteLock(t.rw):
    clear(t.table)


#==============================================================


when isMainModule:

  type
    JobLog = object
      id: int
      jobdesc: string


  var jlogta = initRwTable[int, JobLog]()

  # --- 2. Object-instantie maken en opslaan ---
  var j1 = JobLog(id: 1, jobdesc: "homework")
  jlogta[1] = j1
  echo j1
  # --- 3. Object overschrijven met nieuwe instantie ---
  var j1Updated = JobLog(id: 1, jobdesc: "more work")
  jlogta[1] = j1Updated
  echo j1
  # --- 4. Object verwijderen ---
  jlogta.del(1)

