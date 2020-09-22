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

    string tablePrfix;
    string tableName;
    string simpleName;

    // fully qualified name
    string fullName;

    string primaryKey;
    string autoIncrementKey;

    private EntityField[] _fields;

    EntityField[] fields() {
        return _fields;
    }

    EntityField field(string name) {
        foreach(ref EntityField f; _fields) {
            if(name == f.name) {
                return f;
            }
        }
        warningf("Can't find the field for %s", name);
        return EntityField.init;
    }

    string columnName(string name) {
        EntityField f = field(name);
        string r = f.columnName;
        if(r.empty)
            return name;
        else
            return r;
    }

    string fullColumnName(string name) {
        string column = columnName(name);
        return tablePrfix ~ tableName ~ "." ~ column;
    }
}

struct EntityField {
    string name;

    // fully qualified name
    string fullName;

    string columnName;

    bool isPrimary = false;

    bool isAutoIncrement = false;

    bool isAvaliable = true; 
}

/**
 * 
 */
EntityMetaInfo extractEntityInfo(T)() {
    EntityMetaInfo metaInfo;

    metaInfo.fullName = fullyQualifiedName!T;
    metaInfo.simpleName = T.stringof;

    static if (hasUDA!(T, Table)) {
        enum tableUda = getUDAs!(T, Table)[0];
        metaInfo.tableName = tableUda.name;
        metaInfo.tablePrfix = tableUda.prefix;
    } else {
        metaInfo.tableName = T.stringof;
    }

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMember = __traits(getMember, T, memberName);
        alias memberType = typeof(currentMember);

        static if (__traits(getProtection, currentMember) == "public") {

            // The field and column mapping
            EntityField currentField;
            currentField.name = memberName;
            currentField.fullName = fullyQualifiedName!memberType;

            // Column
            static if (hasUDA!(currentMember, Column)) {
                enum columnName = getUDAs!(currentMember, Column)[0].name;
                currentField.columnName = columnName;
            } else {
                currentField.columnName = memberName;
            }

            // The autoIncrementKey
            static if (hasUDA!(currentMember, AutoIncrement) || hasUDA!(currentMember, Auto)) {
                currentField.isAutoIncrement = true;
                metaInfo.autoIncrementKey = memberName;
            }

            // PrimaryKey
            static if (hasUDA!(currentMember, PrimaryKey)) {
                currentField.isPrimary = true;
                metaInfo.primaryKey = memberName;
            }

            // Transient
            static if (hasUDA!(currentMember, Transient)) {
                currentField.isAvaliable = false;
            }

            metaInfo._fields ~= currentField;
        }
    }}  

    return metaInfo;  
}