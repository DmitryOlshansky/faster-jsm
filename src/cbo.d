module cbo;


void cbo(alias sink, Context)(ref Context ctx) {
    void cbo_step(Extent A, Intent B, uint y) {
        ctx.output!sink(A, B);
        foreach(j;  y..ctx.attributes) {
            if (!B [j]) {
                auto pair = ctx.closeConcept(A, j);
                auto C = pair[0];
                auto D = pair[1];
                // test if D is obtained in a canonical way
                if (C.length >= ctx.min_support && D.equalUpTo(B, j))
                    cbo_step(C, D, j + 1);
            }
        }
    }
    auto A = ctx.fullExtent();
    auto B = ctx.fullIntent();
    foreach(ref row; ctx.rows) {
        B &= row;
    }
    cbo_step(ctx, A, B, 0);
}

