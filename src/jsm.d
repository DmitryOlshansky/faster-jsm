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
            if (args.length < 4) {
                stderr.writefln("xpected:\n\tfaster-jsm encode from.csv to.dat");
                return 1;
            }
            string from = args[2];
            string to = args[3];
            auto rawCsv = (cast(char[])readFile(from))
                .csvReader!string()
                .map!(r => r.array)
                .array();
            auto encoder = rangeEncoder!(string[])(iota(rawCsv[0].length).map!(i =>
                enumEncoder(iota(rawCsv.length).map!(j => rawCsv[j][i]).array())
            ));
            auto output = File(to, "w").lockingTextWriter();
            int cnt;
            auto store = appender!(uint[])();
            foreach(row; rawCsv) {
                store.clear();
                encoder.encodeTo!(string[])(row, (x) { store.put(x); });
                output.formattedWrite("%(%s %)\n", store.data);
            }
            writeln(cnt);
            break;
        default:
            stderr.writefln("Unrecognized sub-command: '%s'", args[1]);
            usage();
            return 1;
    }
    return 0;
}

