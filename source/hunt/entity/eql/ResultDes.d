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

import hunt.entity;
// import hunt.entity.DefaultEntityManagerFactory;

import hunt.logging;
import std.conv;


class ResultDes(T : Object) {
    
    // pragma(msg,makeDeSerialize!(T));

    mixin(makeDeSerialize!(T)());
}

string makeDeSerialize(T)() {
    string str = `
    public T deSerialize(Row[] rows, ref long count, int startIndex = 0, bool isFromManyToOne = false) {
        //    logDebug("deSerialize rows : %s , count : %s , index  : %s ".format(rows,count,startIndex));

        T _data = new T();
        RowData data = rows[startIndex].getAllRowData("");
        //logDebug("rows[0] : ",data);
        if (data is null)
            return null;
        `;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                static if (isBasicType!memType || isSomeString!memType) {
        str ~=`
            if (data.getData(`~memberName.stringof~`)){
                _data.`~memberName ~ ` = data.getData(`~ memberName.stringof ~`).value.to!`~memType.stringof ~ `;
        }`;
                }
            }
        }
    }
    str ~= `
        return (_data);
    }`;
    return str;
}
