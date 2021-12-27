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
 
module hunt.entity.EntityFieldNormal;

import hunt.entity;

import hunt.logging;

import std.conv;
import std.math;
import std.variant;

class EntityFieldNormal(T) : EntityFieldInfo {

    public this(EntityManager manager ,string fieldName, string columnName, string tableName, T value) {
        super(fieldName, columnName, tableName);

        _columnFieldData = Variant(value);
        _typeInfo = typeid(T);

        // _columnFieldData = new ColumnFieldData();
        // _columnFieldData.valueType = typeof(value).stringof;
        // _columnFieldData.value = new hunt.Nullable.Nullable!(T)(value);
        // static if (isSomeString!T) {
        //     if( manager !is null)
        //         _columnFieldData.value = /*manager.getDatabase().escapeLiteral*/(value);
        //     else
        //         _columnFieldData.value = value;
        // }
        // else static if (is(T == double)) {
        //     if (isNaN(value))
        //         _columnFieldData.value = "0";
        //     else 
        //         _columnFieldData.value = "%s".format(value);
        // }
        // else static if (is(T == bool)) {
        //     if(manager.getDbOption().isPgsql())
        //     {
        //         _columnFieldData.value = value ? "'1'":"'0'";
        //     }
        //     else
        //     {
        //         _columnFieldData.value = value ? "1" : "0";
        //     }
        // }
        // else {
        //     _columnFieldData.value = "%s".format(value);
        // }
    }

    override bool isAggregateType() {
        return false;
    }

    R deSerialize(R)(string value, ref bool flag) {
        if (value.length == 0) {
            return R.init;
        }
        if (value.length == 1 && cast(byte)(value[0]) == 0) {
            return R.init;
        }

        R r;
        static if (is(R==bool)) {
            if( value[0] == 1 || value[0] == 't')
                r = true;
            else 
                r = false;
            flag = true;
        } else {
            try {
                r = to!R(value);
                flag = true;
            } catch(Exception ex) {
                warning(ex.msg);
                version(HUNT_DEBUG) {
                    warning(ex);
                }
            }
        }

        return r;
    }

}
