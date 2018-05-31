
module entity.utils.Common;

import std.traits;
import entity.Entity;
import entity.Constant;


class Common {
    static T sampleCopy(T)(T t) {
        T copy = new T;
        foreach(memberName; __traits(derivedMembers, T)) {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                mixin("copy."~memberName~" = "~"t."~memberName~";\n");
            }
        }
        if (cast(Entity)t) {
            foreach(key, value; t._lazyDatas) {
                copy._lazyDatas[key] = new LazyData(value);
            }
            copy.setManager(t.getManager());
        }
        return copy;
    }
}