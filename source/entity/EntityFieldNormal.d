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
 
module entity.EntityFieldNormal;

import entity;
import std.math;


class EntityFieldNormal(T) : EntityFieldInfo {

    public this(string fileldName, string columnName, string tableName, T value) {
        super(fileldName, columnName, tableName);

        _columnFieldData = new ColumnFieldData();
        _columnFieldData.valueType = typeof(value).stringof;
        
        static if (isSomeString!T) {
            _columnFieldData.value = "'"~value~"'";
        }
        else static if (is(T == double)) {
            if (isNaN(value))
                _columnFieldData.value = "0";
            else 
                _columnFieldData.value = "%s".format(value);
        }
        else static if (is(T == bool)) {
            _columnFieldData.value = value ? "1" : "0";
        }
        else {
            _columnFieldData.value = "%s".format(value);
        }
    }

    public void deSerialize(R)(string value, ref R r) {
        if (value.length == 0) {
            return;
        }
        if (value.length == 1 && cast(byte)(value[0]) == 0) {
            return;
        }
        static if (is(R==bool)) {
            r = cast(byte)(value[0]) == 1;
        }
        else {
            r = to!R(value);
        }
    }

}
