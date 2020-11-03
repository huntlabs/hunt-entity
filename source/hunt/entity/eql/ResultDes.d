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
import hunt.entity.EntityDeserializer;


import hunt.logging.ConsoleLogger;

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
    private EntityManager _manager;

    private EntityFieldInfo[string] _fields;

    this(EntityManager em)
    {
        _manager = em;
        if(em !is null)
            _tablePrefix = em.getPrefix();
        initEntityData();
    }

    public void setFields(EntityFieldInfo[string] fields)
    {
        _fields = fields;
        // tracef("T: %s, fields: %s", T.stringof, _fields);
    }


    // pragma(msg, "T = "~T.stringof);
    // pragma(msg, makeDeserializer!(T));
    // pragma(msg,makeInitEntityData!(T));


    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T)());
    mixin(makeDeserializer!(T)());

    EntityFieldInfo opDispatch(string name)() 
    {
        EntityFieldInfo info = _fields.get(name,null);
        if (info is null) {
            version(HUNT_DEBUG) tracef("T: %s, fields: %s", T.stringof, _fields);
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        }
        return info;
    }    

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

    private string getCountAsName() {
        if(_manager.getDbOption().isPgsql()) {
            return EntityExpression.getCountAsName(_tableNameInLower);
        } else {
            return EntityExpression.getCountAsName(_tableName);
        }
    }    

    public R deSerialize(R)(string value) {
        version(HUNT_ENTITY_DEBUG) {
            tracef("type=%s, value=%s", R.stringof, value);
        }

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

