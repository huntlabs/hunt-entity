
module hunt.entity.utils.Common;

import std.traits;
import hunt.entity.Entity;
import hunt.entity.Constant;


class Common {
    static T sampleCopy(T)(T t) {
        T copy = new T();
        foreach(memberName; __traits(derivedMembers, T)) {
            static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public")  {
                alias memType = typeof(__traits(getMember, T ,memberName));
                static if (!isFunction!(memType)) {
                    mixin("copy."~memberName~" = "~"t."~memberName~";\n");
                }
            }
        }
        foreach(key, value; t.getAllLazyData()) {
            copy.addLazyData(key, new LazyData(value));
        }
        copy.setManager(t.getManager());
        return copy;
    }

    static bool inArray(T)(T[] ts, T t) {
        foreach(v; ts) {
            if(v == t)
                return true;
        }
        return false;
    }

    static string quoteStr(string s) {
        if (s == "length")
            return s;
        return "\""~s~"\"";
    }

}