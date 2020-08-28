module hunt.entity.EntityMetaInfo;

import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging.ConsoleLogger;

import std.conv;
import std.string;
import std.traits;

/**
 * 
 */
struct EntityMetaInfo {
    string autoIncrementKey;

    string[string] fieldColumnMaps;

    // TODO: Tasks pending completion -@zhangxueping at 2020-08-28T09:35:46+08:00
    // 
    string tableName;
    string modelName;
    // TypeInfo typeInfo;

    // fully qualified name
    string qualifiedName;

    string toClumnName(string fieldName) {
        auto itemPtr = fieldName in fieldColumnMaps;
        if(itemPtr is null) {
            version(HUNT_ENTITY_DEBUG) warningf("No mapped column name found for field: %s", fieldName);
            return fieldName;
        }

        return *itemPtr;
    }    

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