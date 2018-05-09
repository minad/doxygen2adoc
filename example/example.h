typedef struct {
    ENTRY* entry;
    size_t count, size;
} HASH;

/**
 * Compute hash index
 */
static inline HashIndex INDEX(KEYTYPE k) {
    return (HashIndex){ HASHFN(k) };
}

/**
 * Destroy hash table and free allocated memory
 */
static inline void DESTROY(HASH* h) {
    INVARIANT;
    FREE(h, h->entry);
    h->entry = 0;
    h->size = h->count = 0;
}

static inline void CAT(HASH, _auto_destroy)(HASH* h) {
    DESTROY(h);
}

/**
 * Get next entry in the hash table
 *
 * @param h Hash table
 * @param e Current entry
 * @return Next entry
 */
static inline ENTRY* NEXT(const HASH* h, ENTRY* e) {
    INVARIANT;
    for (; e < h->entry + h->size; ++e) {
        bool x = EXISTS(e);
        if (x)
            return e;
    }
    return 0;
}

/**
 * Get next free insertion position in the hash table
 *
 * @param h Hash table
 * @param i Hash index
 * @return Pointer to free entry
 */
static inline ENTRY* INSERTPOS(HASH* h, HashIndex i) {
    INVARIANT;
    assert(h && h->entry);
    for (size_t n = 0; ; ++n) {
        size_t a = (i._i + n) & (h->size - 1);
        ENTRY* e = h->entry + a;
        bool x = EXISTS(e);
        if (!x)
            return e;
    }
}

/**
 * Grow hash table by factor of two
 */
static void GROW(HASH* h) {
    INVARIANT;
    HASH l = *h;
    l.size = h->size ? 2 * h->size : (1UL << INITSHIFT);
    size_t n = sizeof (ENTRY) * l.size;
    l.entry = (ENTRY*)CALLOC(h, n);
    HASH_FOREACH(PREFIX, e, h)
        memcpy(INSERTPOS(&l, INDEX(KEY(e))), e, sizeof (ENTRY));
    DESTROY(h);
    *h = l;
}

/**
 * Insert into hash table
 *
 * @param h Hash table
 * @param i Hash index
 * @return Pointer to inserted entry
 */
static inline ENTRY* INSERT(HASH* h, HashIndex i) {
    INVARIANT;
    if (UNLIKELY(FULL))
        GROW(h);
    ++h->count;
    return INSERTPOS(h, i);
}

/**
 * Find position of entry or insertion position
 *
 * @param h Hash table
 * @param k Key
 * @param i Hash index of key
 * @param r Returns pointer to entry or next insertion position
 * @return true if key was found
 */
static inline bool FINDPOS(const HASH* h, KEYTYPE k, HashIndex i, ENTRY** r) {
    INVARIANT;
    if (UNLIKELY(!h->entry)) {
        *r = 0;
        return false;
    }
    for (size_t n = 0; ; ++n) {
        size_t a = (i._i + n) & (h->size - 1);
        ENTRY* e = h->entry + a;
        bool x = EXISTS(e);
        if (!x) {
            *r = e;
            return false;
        }
        KEYTYPE l = KEY(e);
        bool q = KEYEQ(l, k);
        if (q) {
            *r = e;
            return true;
        }
    }
}

/**
 * Find entry by key
 *
 * @param h Hash table
 * @param k Key
 * @return Entry or 0 if not found
 */
static inline ENTRY* FIND(const HASH* h, KEYTYPE k) {
    ENTRY* e;
    return FINDPOS(h, k, INDEX(k), &e) ? e : 0;
}

/**
 * Create new entry or find if it already exists
 *
 * @param h Hash table
 * @param k Key
 * @param r Pointer to entry
 * @return true if the entry was newly created
 */
static inline bool CREATE(HASH* h, KEYTYPE k, ENTRY** r) {
    INVARIANT;
    HashIndex i = INDEX(k);
    ENTRY* e;
    if (FINDPOS(h, k, i, &e)) {
        *r = e;
        return false;
    }
    if (LIKELY(e && !FULL))
        ++h->count;
    else
        e = INSERT(h, i);
    *r = e;
    return true;
}
