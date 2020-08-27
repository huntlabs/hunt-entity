module hunt.entity.EntityMetaInfo;

import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging;

import std.conv;
import std.string;
import std.traits;

/**
 * 
 */
struct EntityMetaInfo {
    string autoIncrementKey;
    
    string[string] fieldColumnMaps;
}

/**
 * 
 */
EntityMetaInfo extractEntityInfo(T)() {
    EntityMetaInfo metaInfo;

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMemeber = __traits(getMember, T, memberName);
        // alias memberType = typeof(currentMemeber);

        static if (__traits(getProtection, currentMemeber) == "public") {

            // The autoIncrementKey
            static if (hasUDA!(currentMemeber, AutoIncrement) || hasUDA!(currentMemeber, Auto)) {
                    metaInfo.autoIncrementKey = memberName;
            }  

            // The field and column mapping
            static if (hasUDA!(currentMemeber, Column)) {
                metaInfo.fieldColumnMaps[memberName] = getUDAs!(currentMemeber, Column)[0].name;
            }     
        }
    }}  

    return metaInfo;  
}