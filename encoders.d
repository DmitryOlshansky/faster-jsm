module encoders;

alias Encoder(T) = (T, ref size_t, scope void delegate(uint));

Encoder!string enumEncoder(Range)(Range allValues)
if (isRandomAccessRange!Range) {
    string[uint] values;
    import std.algorithm.sorting, std.algorithm.iteration, std.range, std.array;
    values = sort(allValues).uniq().enumerate().assocArray();
    return (string value, ref size_t offset=0, scope void delegate(uint) sink) {
        sink(offset + values[value]);
        offset += values.length;
    };
}

Encoder!Row rangeEncoder(Row, Encoders)(Encoders encoders) 
if (isForwardRange!Row && isForwardRange!Encoders) {
    return (Row values, ref size_t offset=0, scope void delegate(uint) sink) {
        foreach(value, enc;  zip(values, encoders)) {
            enc(value, offset, sink);
        }
    };
}


auto encodeTo(T)(Encoder!T encoder, T data, scope void delegate(uint) sink) {
    size_t offset = 0;
    encoder(data, offset, sink);
}

auto encodeToArray(T)(Encoder!T encoder, T data)
{
    uint[] array = [];
    encoder.encodeTo(data, x -> array ~= x);
    return array;
}
