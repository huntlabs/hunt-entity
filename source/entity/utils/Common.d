
module entity.utils.Common;

import std.traits;

class Common {
    static T sampleCopy(T)(T t) {
        T copy = new T;
        foreach(memberName; __traits(derivedMembers, T)) {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
                mixin("copy."~memberName~" = "~"t."~memberName~";\n");
            }
        }
        return copy;
    }
}