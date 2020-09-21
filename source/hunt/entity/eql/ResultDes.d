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
import std.string;
import std.traits;


string getTableName(T)() if(is(T == class) || is(T == struct) ) {
    static if (hasUDA!(T,Table)) {
        return getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name;
    } else {
        return T.stringof;
    }
}


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
    // pragma(msg,makeDeserializer!(T));
    // pragma(msg,makeInitEntityData!(T));


    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T)());
    mixin(makeDeserializer!(T)());

    string getTableName()
    {
        return _tableName;
    }

    string formatSelectItem(string col)
    {
        return _tableName ~ "__as__" ~ col;
    }

    private string getColumnAsName(string name) {
        return EntityExpression.getColumnAsName(name, _tableName);
    }

    private string getColumnAsName(string name, string tableName) {
        return EntityExpression.getColumnAsName(name, tableName);
    }    

    public R deSerialize(R)(string value) {
        version(HUNT_ENTITY_DEBUG_MORE) tracef("type=%s, value=%s", R.stringof, value);
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
    // static if (hasUDA!(T,Table)) {
    //     str ~= `
    //     _tableName = _tablePrefix ~ "` ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~`";`;
    // }
    // else {
    //     str ~= `
    //     _tableName = _tablePrefix ~ "` ~ T.stringof ~ `";`;
    // }

    str ~= `
    _tableName = _tablePrefix ~ "` ~ getTableName!(T) ~ `";`;
    

    str ~= `
        _tableNameInLower = _tableName.toLower();
        }
    `;
    return str;
}

string makeDeserializer(T)() {
    string str = `
    public T deSerialize(Row[] rows, ref long count, int startIndex = 0) {

        version(HUNT_ENTITY_DEBUG) {
            tracef("Target: %s, Rows: %d, count: %s, startIndex: %d, tableName: %s ", 
                T.stringof, rows.length, count, startIndex, _tableName);
        }

        import std.variant;

        T _data = new T();
        Row row = rows[startIndex];
        string columnAsName;
        version(HUNT_ENTITY_DEBUG) logDebugf("rows[%d]: %s", startIndex, row);

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

                str ~=`
                    // ======================== `~memberName~` =============================
                    `;

                static if(!isArray!memType && hasUDA!(__traits(getMember, T ,memberName), JoinColumn))
                {
                    str ~= `
                        auto ` ~ memberName~ ` = new ResultDes!(` ~ memType.stringof ~ `)(_em);
                        _data.` ~ memberName~ ` = ` ~ memberName ~ `.deSerialize(rows,count,startIndex);
                    `;
                } else {

                    str ~=`
                        columnAsName = getColumnAsName(`~ columnName ~`);`;

                    // get the column's value
                    str ~=`
                        version(HUNT_ENTITY_DEBUG_MORE) {
                            tracef("columnAsName: %s, columnName: %s", columnAsName, `~ columnName ~`);
                        }

                        columnValue = row.getValue(`~ columnName ~`);
                        if (!columnValue.hasValue()) { // try use columnAsName to get the value
                            version(HUNT_ENTITY_DEBUG_MORE) {
                                warningf("No value for %s found. Try %s again.", `~ columnName ~`, columnAsName);
                            }
                            columnValue = row.getValue(columnAsName);
                        }
                        version(HUNT_ENTITY_DEBUG) {
                            if (columnValue.hasValue()) {
                                version(HUNT_ENTITY_DEBUG_MORE) {
                                    string value = columnValue.toString();
                                    if(value.length > 128) {
                                        tracef("field: %s, column: %s, type: %s, value: %s", "` 
                                            ~ memberName ~ `", ` ~ columnName ~ `, "` 
                                            ~ memType.stringof ~ `", value[0..128]);
                                    } else {
                                        tracef("field: name=%s, type=%s; column: name=%s / %s, type=%s; value: %s", "` 
                                            ~ memberName ~ `", "` ~ memType.stringof ~ `", ` 
                                            ~ columnName ~ `, columnAsName, columnValue.type,` 
                                            ~ ` value.empty() ? "(empty)" : value);
                                    }
                                }
                            } else {
                                warningf("field: name=%s, type=%s;, column: %s / %s, value: (null)", "` 
                                    ~ memberName ~ `", "` ~ memType.stringof ~ `", ` ~ columnName 
                                    ~ `, columnAsName);
                            }
                        }
                        `;

                    // populate the field member
                    // 1) The types are same.
                    str ~=`
                        if(columnValue.type == typeid(null)) {
                            version(HUNT_DEBUG) {
                                warningf("The value of column [%s] is null. So use its default value.", "` 
                                    ~ memberName ~ `");
                            }
                        } else if(columnValue.hasValue()) {
                            if(typeid(` ~ memType.stringof ~ `) == columnValue.type) {
                                _data.` ~ memberName ~ ` = columnValue.get!(` ~ memType.stringof ~ `);
                            } else {
                    `;

                    // 2) convert to string type
                    static if (isSomeString!memType) {
                        str ~=`
                            _data.` ~ memberName ~ ` = columnValue.toString();
                        `;
                    } else static if (isNumeric!memType || is(memType == bool)) {
                    // 3) convert to number type
                        str ~=`
                            version(HUNT_ENTITY_DEBUG) 
                                infof("Try to convert to a number from %s", columnValue.type.toString());

                            try { _data.` ~ memberName ~ ` = columnValue.toString().to!(` ~ memType.stringof ~ `); }
                            catch(Exception) { 
                                warningf("Can't convert to a number or bool from %s, member: ` ~ memberName ~ 
                                `, value: %s", columnValue.type.toString(), columnValue.toString());
                            }
                        `;
                    } else {
                    // 4) unmatched type
                        str ~= `warningf("unmatched type for field ` ~ memberName ~ `: fieldType=` ~ memType.stringof ~ 
                            `, columnType = %s", columnValue.type.toString());`;
                    }

                    str ~=`} }`;
                }
            }
        }
    }
    str ~= `
        return (_data);
    }`;
    return str;
}
