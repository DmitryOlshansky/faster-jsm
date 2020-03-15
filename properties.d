module properties;

import std.range.primitives;

// encoded as 1-hot "bitvector" and representated as plain integer
struct SmallEnumProperty(uint size) {
    static assert (size <= 64, "SmallEnumProperty doesn't support sizes larger then 64");
    static if(size < 8)
        alias Value = ubyte;
    else static if(size < 16)
        alias Value = ushort;
    else static if(size < 32
        alias Value = uint;
    else
        alias Value = ulong;
    Value value;

    this(uint property) {
        assert(property < size);
        value = cast(Value)1<<property;
    }

    static auto tau() {
        return size == 64 ? EnumProperty(~0) : EnumProperty((cast(Value)1<<size) - 1);
    }

    auto opBinary(string op:"&")(SmallEnumProperty other) {
        return EnumProperty(value & other.value);
    }

    bool empty() const { return value == 0; }
    
    bool isTau() const { this == tau; }
}
