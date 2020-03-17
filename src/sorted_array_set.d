module sorted_array_set;

import std.array;
import std.algorithm.searching;

/**
    Integer set implemented as sorted array.
*/
struct SortedArraySet {
    uint[] array;
    size_t size;

    this(size_t maxSize) {
        size = maxSize;
    }

    static newEmpty(size_t maxSize) {
        return typeof(this)(maxSize);
    }

    static newFull(size_t maxSize) {
        import std.range;
        auto set = typeof(this)(maxSize);
        set.array = iota(cast(uint)maxSize).array();
        return set;
    }

    ref add(uint[] values...) {
        assert(values.maxElement < size);
        foreach(v; values) {
            if (array.empty()) 
            array ~= v;
            else if (array.back < v) array ~= v;
            else if (array.back == v) {} // nop
            else {
                assert(0); //TODO: add support as needed, cbo and friends do not need this case
            }
        }
        return this;
    }

    ref invert() {
        assert(0); //TODO: add support as needed
    }

    const(uint)[] opIndex() {
        return array;
    }

    bool opIndex(size_t item) {
        import std.range;
        return array.assumeSorted.contains(item);
    }

    size_t length() { return array.length; }

    void toString(scope void delegate(const(char)[]) sink) {
        import std.format;
        formattedWrite(sink, "%(%s %)", array[]);
    }
}


unittest {
    import std.range, std.algorithm;
    alias Set = SortedArraySet;
    auto e = Set.newFull(10);
    assert(e[].equal(iota(10)));
    auto e2 = Set.newEmpty(30);
    assert(e2[].empty);
    assert(e2[].equal(cast(uint[])[]));
    e2.add(iota(10u).array);
    e2.add(10);
    assert(e2[].equal(iota(11)));
    e2.add(20);
    assert(e2[20]);
    assert(!e2[11]);
}
