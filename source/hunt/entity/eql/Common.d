module hunt.entity.eql.Common;

import std.traits;

string makeImport(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                // pragma(msg, "memberName: " ~ memberName ~ "   type: " ~ memType.stringof);

                static if(is(memType U : U[])) {
                    // pragma(msg, "element type: " ~ U.stringof);
                    
                    alias S = U;
                } else static if(is(memType V : V[K], K)) {
                    enum s = importModuleFor!K() ;
                    static if(s.length>0) {
                        str ~= s;
                    }
                    alias S = V;
                } else {
                    alias S = memType;
                }

                enum s = importModuleFor!S() ;
                // pragma(msg, s);
                static if(s.length>0) {
                    str ~= s;
                }
                
            }
        }
    }
    return str;
}

string importModuleFor(T)() {
    string str;
    static if(is(T == class) || is(T == interface) || is(T == struct) || is(T == enum)) {
        // pragma(msg, "importing module for " ~ T.stringof);
        str ~= `
        import `~moduleName!T~`;`;   
    }
    return str;
}