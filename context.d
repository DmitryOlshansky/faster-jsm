module context;


struct Context(Intent, Extent, Property) {
    size_t attributes;      // number of binary attributes (after encoding)
    Intent[] rows;          // array of respective Property object
    Property[] properties;  // minimum of objects in a hypothesis extent
    size_t minSupport;      // minimum number of objects a hypotheses must include to be generated

    @property size_t objects() const { return rows.length; }

    static struct ClosedSet {
        Extent extent;
        Intent intent;
    }

    auto emptyExtent() { return Extent.newEmpty(objects); }

    auto fullIntent() { return Intent.newFull(attributes); }

    ClosedSet closeConcept(Extent A, uint y) {
        Extent C = emptyExtent();
        Intent D = fullIntent();
        foreach(i; A) {
            auto R = self.rows[i];
            if(R[y]) {
                C.add(i);
                D &= R;
            }
        }
        return ClosedSet(C, D);
    }

    Property mergeProperties(ref Extent A) {
        import std.algorithm.iteration;
        return reduce!((acc, p) => acc &= p)(properties);
    }

    void output(alias sink)(ref Extent A, ref Intent B) {
        auto props = ctx.mergeProperties(A);
        if(!props.empty())
            sink(B, props);
    }
}


auto context(Extent, Intent)(Intent[] rows, Properties[] properties, size_t minSupport) {
    return Context!(Extent, Intent)(rows.length, rows, properties, minSupport);
}

