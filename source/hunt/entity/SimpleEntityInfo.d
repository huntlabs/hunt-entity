module hunt.entity.SimpleEntityInfo;

import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging;

import std.conv;
import std.string;
import std.traits;

interface IEntityInfo {
    string autoIncrementKey();
}

/**
 * 
 */
class SimpleEntityInfo(T) : IEntityInfo {

    static foreach (string memberName; FieldNameTuple!T) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            // alias memType = typeof(__traits(getMember, T ,memberName));

            static if (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || 
                hasUDA!(__traits(getMember, T ,memberName), Auto)) {
                    enum string _autoIncrementKey = memberName;
            }       
        }
    }

    string autoIncrementKey() {
        return _autoIncrementKey;
    }

    this() {
      
    }
}
