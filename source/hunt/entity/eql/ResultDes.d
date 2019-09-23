/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.entity.eql.ResultDes;

import hunt.entity.eql.Common;
import hunt.entity;
// import hunt.entity.DefaultEntityManagerFactory;

import hunt.logging;

import hunt.util.ConverterUtils;
import hunt.util.Traits;

import std.array;
import std.conv;
import std.traits;



class ResultDes(T : Object) {
    
    private string _tableName;
    private string _tableNameInLower; // for PostgreSQL, the column's name will be converted to lowercase.
    private string _tablePrefix;
    private string _clsName;
    private EntityManager _em;

    private EntityFieldInfo[string] _fields;

    this(EntityManager em)
    {
        _em = em;
        if(em !is null)
            _tablePrefix = em.getPrefix();
        initEntityData();
    }

    public void setFields(EntityFieldInfo[string] fields)
    {
        _fields = fields;
    }

    // pragma(msg, "T = "~T.stringof);
    // pragma(msg,makeDeSerialize!(T));
    // pragma(msg,makeInitEntityData!(T));


    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T)());
    mixin(makeDeSerialize!(T)());

    string getTableName()
    {
        return _tableName;
    }

    string formatSelectItem(string col)
    {
        return _tableName ~ "__as__" ~ col;
    }

    public R deSerialize(R)(string value) {
        version(HUNT_SQL_DEBUG_MORE) tracef("type=%s, value=%s", R.stringof, value);
        if (value.length == 0) {
            return R.init;
        }
        if (value.length == 1 && cast(byte)(value[0]) == 0) {
            return R.init;
        }

        R r = R.init;
        static if (is(R==bool)) {
            if( value[0] == 1 || value[0] == 't')
                r = true;
            else 
                r = false;
        }
        else {
            r = to!R(value);
        }

        return r;
    }
}


string makeInitEntityData(T)() {
    string str = `
    private void initEntityData() {
        import std.string;
        _clsName = "`~T.stringof~`";`;
    static if (hasUDA!(T,Table)) {
        str ~= `
        _tableName = _tablePrefix ~ "` ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~`";`;
    }
    else {
        str ~= `
        _tableName = _tablePrefix ~ "` ~ T.stringof ~ `";`;
    }
    str ~= `
        _tableNameInLower = _tableName.toLower();
        }
    `;
    return str;
}

string makeDeSerialize(T)() {
    string str = `
    public T deSerialize(Row[] rows, ref long count, int startIndex = 0) {

        version(HUNT_ENTITY_DEBUG) {
            tracef("Target: %s, Rows: %s, count: %s, startIndex: %d, tableName: %s ", 
                T.stringof, rows, count, startIndex, _tableName);
        }

        import std.variant;

        T _data = new T();
        Row row = rows[startIndex];
        string columnAsName;
        version(HUNT_ENTITY_DEBUG) logDebugf("rows[%d]: %s", startIndex, row);

        string value;
        Variant columnValue;
        `;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {

                // get the column's name
                static if(hasUDA!(__traits(getMember, T ,memberName), Column)) {
                    string columnName = "\"" ~ getUDAs!(__traits(getMember, T ,memberName), Column)[0].name ~"\"";
                } else {
                    string columnName = "\"" ~ memberName ~"\"";
                }

                // get the column's value
                str ~=`
                    // ======================== `~memberName~` =============================
                    value = null;  // clear last value
                    columnAsName = EntityExpression.getColumnAsName(`~ columnName ~`, _tableNameInLower);

                    version(HUNT_ENTITY_DEBUG_MORE) {
                        warningf("columnAsName: %s, columnName: %s", columnAsName, `~ columnName ~`);
                    }

                    columnValue = row.getValue(columnAsName);
                    if (columnValue.hasValue()) {
                        value = columnValue.toString();
                        version(HUNT_ENTITY_DEBUG) {
                            if(value.length > 128) {
                                tracef("member: %s, column: %s, type: %s, value: %s", "` 
                                    ~ memberName ~ `", ` ~ columnName ~ `, "` 
                                    ~ memType.stringof ~ `", value[0..128]);
                            } else {
                                tracef("member: %s, column: %s, type: %s, value: %s", "` 
                                    ~ memberName ~ `", ` ~ columnName ~ `, "` 
                                    ~ memType.stringof ~ `", value.empty() ? "(empty)" : value);
                            }
                        }              
                    } else {
                        version(HUNT_ENTITY_DEBUG) {
                                warningf("member: %s, column: %s, type: %s, value: null", "` 
                                    ~ memberName ~ `", ` ~ columnName ~ `, "` 
                                    ~ memType.stringof ~ `");
                        }
                    }
                    `;

                // populate the field member
                static if (isBasicType!memType || isSomeString!memType) {
                    str ~=`
                        if(!value.empty()) {
                            _data.` ~ memberName ~ ` = deSerialize!(` ~ memType.stringof ~ `)(value);
                        }
                    `;
                }
                else static if(!isArray!memType && hasUDA!(__traits(getMember, T ,memberName), JoinColumn))
                {
                    str ~= `
                        auto ` ~ memberName~ ` = new ResultDes!(` ~ memType.stringof ~ `)(_em);
                        _data.` ~ memberName~ ` = ` ~ memberName ~ `.deSerialize(rows,count,startIndex);
                    `;
                } else static if(is(memType : U[], U) && isByteType!U) { // bytes array

                    str ~=`
                        if(value.length >= 2) {
                            // FIXME: Needing refactor or cleanup -@zhangxueping at 2019/6/18 10:27:11 AM
                            // to handle the other format for mysql etc.

                            if(value[0..2] != "\\x") { 
                                version(HUNT_DEBUG) warningf("unrecognized data format: %(%02X %)", value[0..2]);
                            } else { // postgresql format
                                value = value[2 .. $];
                                _data.` ~ memberName ~ ` = ConverterUtils.toBytes!(`~ U.stringof ~`)(value);
                            }
                        }
                    `;
                        
                } else {
                    str ~= `warning("do nothing for ` ~ memberName ~ `, type=` ~ memType.stringof ~ `");`;
                }
            }
        }
    }
    str ~= `
        return (_data);
    }`;
    return str;
}
