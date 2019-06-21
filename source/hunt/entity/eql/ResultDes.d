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
        }
    `;
    return str;
}

string makeDeSerialize(T)() {
    string str = `
    public T deSerialize(Row[] rows, ref long count, int startIndex = 0) {
        //    logDebug("deSerialize rows : %s , count : %s , index  : %s , table : %s ".format(rows,count,startIndex,_tableName));

        T _data = new T();
        RowData data = rows[startIndex].getAllRowData(_tableName);
        string value;
        // logDebug("rows[0] : ",data);
        
        // if (data.getAllData().length == 1 && data.getData("countfor"~_tableName~"_")) {
        //     count = data.getData("countfor"~_tableName~"_").value.to!long;
        //     return null;
        // }
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
                    value = null;  // clear last value
                    if (data !is null) {
                        auto columnData = data.getData(`~ columnName ~`);
                        if(columnData !is null) {
                            value = columnData.value;
                            version(HUNT_SQL_DEBUG_MORE) {
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
                            version(HUNT_SQL_DEBUG_MORE) {
                                    tracef("member: %s, column: %s, type: %s, value: null", "` 
                                        ~ memberName ~ `", ` ~ columnName ~ `, "` 
                                        ~ memType.stringof ~ `");
                            }
                        }
                    }`;

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
                } else static if(is(memType : U[], U) && is(isByteType!U)) { // bytes array

                    str ~=`
                        if(value.length > 2) {
                            // FIXME: Needing refactor or cleanup -@zhangxueping at 2019/6/18 10:27:11 AM
                            // to handle the other format for mysql etc.

                            if(value[0..2] != "\\x") { // postgresql format
                                version(HUNT_DEBUG) warning("unrecognized data format");
                            } else {
                                value = value[2 .. $];
                                _data.` ~ memberName ~ ` = ConverterUtils.toBytes!(`~ U.stringof ~`)(value);
                            }
                        }
                    `;
                        
                    } else {
                        version(HUNT_DEBUG) {
                            str ~= `warning("do nothing for ` ~ memberName ~ `, type=` ~ memType.stringof ~ `");`;
                        }
                }
            }
        }
    }
    str ~= `
        return (_data);
    }`;
    return str;
}
