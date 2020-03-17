module encoders;

import std.range.primitives;

struct Encoder(T) {
    uint size;
    void delegate(T, ref uint, scope void delegate(uint)) encoder;

    void encode(T value, ref uint offset, scope void delegate(uint) sink)
    {
        encoder(value, offset, sink);
    }
}



Encoder!string enumEncoder(Range)(Range allValues)
if (isRandomAccessRange!Range) {
    import std.algorithm.sorting : sort;
    import std.algorithm.iteration : map, uniq;
    import std.range : iota, zip;
    import std.array : array, assocArray;
    auto unique = sort(allValues).uniq().array();
    uint[string] values = unique.zip(iota(cast(uint)unique.length)).assocArray();
    return Encoder!string(cast(uint)values.length,
        (string value, ref uint offset, scope void delegate(uint) sink) {
            sink(offset + values[value]);
            offset += values.length;
        }
    );
}

Encoder!Row rangeEncoder(Row, Encoders)(Encoders encoders) 
if (isForwardRange!Row && isForwardRange!Encoders) {
    import std.range : zip;
    import std.algorithm : map, sum;
    auto size = encoders.map!(enc => enc.size).sum;
    return Encoder!Row(cast(uint)size,
        (Row values, ref uint offset, scope void delegate(uint) sink) {
            foreach(value, enc;  zip(values, encoders)) {
                enc.encode(value, offset, sink);
            }
        }
    );
}


auto encodeTo(T)(Encoder!T encoder, T data, scope void delegate(uint) sink) {
    uint offset = 0;
    encoder.encode(data, offset, sink);
}

auto encodeToArray(T)(Encoder!T encoder, T data) {
    import std.array : appender;
    auto array = appender!(uint[]);
    encoder.encodeTo!T(data, (x) {
        array ~= x; 
    });
    return array.data;
}
