module jsm;

import simd_set;
import sorted_array_set;
import properties;
import encoders;
import context;
import cbo;

import std.algorithm;
import std.csv;
import std.file : readFile = read;
import std.format;
import std.getopt;
import std.range;
import std.stdio;


int main(string[] args) {
    void usage() {
        stderr.writefln("Usage:\n\tfaster-jsm [encode|split|tau|generate|predict|verify] <sub-command-options>");
    }
    if (args.length < 2) {
        usage();
        return 1;
    }
    switch(args[1]) {
        case "encode":
            int property;
            auto result = getopt(args,
                "p|property", &property
            );
            if (args.length < 4) {
                stderr.writefln("xpected:\n\tfaster-jsm encode from.csv to.dat");
                return 1;
            }
            string from = args[2];
            string to = args[3];
            stderr.writeln("Using atribute #", property, " as target property");
            auto rawCsv = (cast(char[])readFile(from))
                .csvReader!string()
                .map!(r => r.array)
                .array();
            auto encoders = iota(rawCsv[0].length)
                .map!(i =>
                    enumEncoder(iota(rawCsv.length).map!(j => rawCsv[j][i]).array())
                ).array;
            auto propValues = iota(rawCsv.length).map!(j => rawCsv[j][property]).array().sort.uniq.array;
            auto attrsEncoder = rangeEncoder!(string[])(encoders[0..property] ~ encoders[property+1..$]);
            auto output = File(to, "w").lockingTextWriter();
            output.formattedWrite("# attributes: %d properties: B(%s)\n", attrsEncoder.size, propValues.join(","));
            auto buffer = appender!(uint[])();
            foreach(row; rawCsv) {
                buffer.clear();
                auto attrs = row[0..property] ~ row[property+1..$];
                attrsEncoder.encodeTo!(string[])(attrs, (x) {
                    buffer.put(x); 
                });
                output.formattedWrite("%(%s %) | %s\n", buffer.data, row[property]);
            }
            break;
        default:
            stderr.writefln("Unrecognized sub-command: '%s'", args[1]);
            usage();
            return 1;
    }
    return 0;
}

