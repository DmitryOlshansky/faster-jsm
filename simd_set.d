module simd_set;

import core.simd;
import std.algorithm.searching;

/**
    SIMD-optimized bit set for non-negative integers.

    An instance of SimdBitSet follows reference semantics,
    as internal storage array is not copied on assignments.
*/
struct SimdBitSet {
    enum SIMD_BITS = 128;
    ubyte16[] blocks;
    size_t size;

    this(size_t maxSize) {
        blocks = new ubyte16[(maxSize + SIMD_BITS-1) / SIMD_BITS];
        size = maxSize;
    }

    ref add(uint[] values...) {
        assert(values.maxElement < size);
        foreach(v; values) {
            this[v] = true;
        }
        return this;
    }

    ref invert() {
        foreach(ref v; blocks) {
            v = ~v;
        }
        return this;
    }

    struct Range {
        SimdBitSet set;
        size_t index;

        this(SimdBitSet set) {
            this.set = set;
            index = 0;
            next();
        }

        void next() {
            auto len = set.size;
            while(index < len && !set[index]) {
                index++;
            }
        }

        @property bool empty() const { return index == set.size; }

        void popFront() {
            index++;
            next();
        }

        @property uint front() const {
            return cast(uint)index;
        }
    }

    Range opIndex() {
        return Range(this);
    }

    bool opIndex(size_t idx) {
        size_t offset = idx % SIMD_BITS;
        ubyte16 mask;
        mask[offset / 8] |= 1<<(offset % 8);
        return (blocks[idx / SIMD_BITS] & mask) == mask;
    }

    ref opIndexAssign(bool value, size_t idx) {
        size_t offset = idx % SIMD_BITS;
        ubyte16 mask;
        mask[offset / 8] = 1<<(offset % 8);
        if (value)
            blocks[idx / SIMD_BITS] |= mask;
        else
            blocks[idx / SIMD_BITS] &= ~mask;
        return this;
    }

    ref opOpAssign(string op)(ref SimdBitSet other) 
    if (op == "&" || op == "|")
    {
        assert(size == other.size);
        mixin("blocks[] "~op~"= other.blocks[];");
        return this;
    }

    bool equalUpTo(ref SimdBitSet other, size_t top) {
        size_t offset = top % SIMD_BITS;
        ubyte16 mask;
        auto bytes = offset / 8;
        foreach (i; 0..bytes)
            mask[i] = 0xFF;
        if (offset % 8 != 0) mask[offset / 8] = (1<<(offset % 8))-1;
        debug(SimdBitSet) {
            import std.stdio;
            writefln("equalUpTo %s vs %s", this, other);
            writefln("%(%2x %)", mask);
            writefln("%(%2x %)", blocks[0]);
            writefln("%(%2x %)", other.blocks[0]);
        }
        if (top < SIMD_BITS) // fast path for small sets
            return (blocks[0] & mask) == (other.blocks[0] & mask);
        else {
            auto n = top / SIMD_BITS;
            if (blocks[0..n] != other.blocks[0..n]) return false;
            return offset == 0 || (blocks[n] & mask) == (other.blocks[n] & mask);
        }
    }

    void toString(scope void delegate(const(char)[]) sink) {
        import std.format;
        formattedWrite(sink, "%(%s %)", this[]);
    }
}

unittest {
    auto set = SimdBitSet(250);
    set.add(1, 2, 4, 5, 7);
    assert(!set[0]);
    assert(set[1]);
    assert(set[7]);
    assert(!set[8]);
    set.add(249);
    assert(set[249]);
    set.add([3, 129]);
    assert(set[3]);
    assert(set[129]);
}

unittest {
    alias Set = SimdBitSet;
    import std.range, std.algorithm, std.conv, std.stdio;
    auto set1 = Set(33).invert();
    assert(set1[].equal(iota(33)));
    auto set2 = Set(33);
    set2.add(9);
    set2.add(32);
    assert(set2[].equal([9, 32]));
    assert(set2.to!string == "9 32");
    assert(set2[9]);
    assert(set2[32]);
    set1 &= set2;
    assert(set2[].equal([9, 32]));
    assert(set1[9]);
    assert(set1[32]);
    foreach(i; 0..33)
        assert(!set1[i] || i == 9 || i == 32);
    auto set3 = Set(4).add(1, 3);
    assert(set3[].equal([1, 3]));
    assert(!set3[0]);
    assert(set3[1]);
    assert(!set3[2]);
    assert(set3[3]);
    auto set4 = Set(64).add(31);
    assert(set4[31]);
    assert(!set4[32]);
    auto set5 = Set(127).add(32);
    auto set6 = Set(127).invert();
    set6 &= set5;
    assert(set6[].equal([32]));
    assert(set5[].equal([32]));
    set5[32] = false;
    assert(set5[].equal(cast(uint[])[]));
}

unittest {
    alias Set = SimdBitSet;
    auto set1 = Set(128).add(1, 2, 9, 127);
    auto set2 = Set(128).add(1, 2, 9);
    assert(set1.equalUpTo(set2, 9));
    assert(set1.equalUpTo(set2, 127));
    assert(!set1.equalUpTo(set2, 128));

    set1 = Set(36).add(1, 33, 35);
    set2 = Set(36).add(1, 33, 34);
    assert(set1.equalUpTo(set2, 34));
    assert(set2.equalUpTo(set1, 34));
    assert(!set1.equalUpTo(set2, 35));

    set1 = Set(256).add(1, 2, 129, 133);
    set2 = Set(256).add(1, 2, 129, 134);
    foreach(i; 0..134) {
        assert(set1.equalUpTo(set2, i));
        assert(set2.equalUpTo(set1, i));
    }
    assert(!set1.equalUpTo(set2, 134));
    assert(!set2.equalUpTo(set1, 134));
}

unittest {
    import std.algorithm;
    assert(reduce!max([1]) == 1);
}