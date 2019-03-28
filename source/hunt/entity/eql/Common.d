module hunt.entity.eql.Common;

import std.traits;

string makeImport(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                static if (isArray!memType && !isSomeString!memType) {
    // str ~= `
    // import `~moduleName!(ForeachType!memType)~`;`;
                }
                else static if (!isBuiltinType!memType){
    str ~= `
    import `~moduleName!memType~`;`;          
                }
                
            }
        }
    }
    return str;
}