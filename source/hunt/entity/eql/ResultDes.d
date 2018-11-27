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

}

string makeImport(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                static if (isArray!memType && !isSomeString!memType) {
    str ~= `
    import `~moduleName!(ForeachType!memType)~`;`;
                }
                else static if (!isBuiltinType!memType){
    str ~= `
    import `~moduleName!memType~`;`;          
                }
                
            }
        }
    }
    return str;
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
                static if (isBasicType!memType || isSomeString!memType) {
                    static if(hasUDA!(__traits(getMember, T ,memberName), Column))
                    {
                        string columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
                        str ~=`
                            if ((data !is null ) && data.getData((`~columnName~`))){
                                _data.`~memberName ~ ` = data.getData((`~ columnName ~`)).value.to!`~memType.stringof ~ `;
                        }
                        `;
                    }
                    else {
                                str ~=`
                            if ((data !is null ) && data.getData((`~memberName.stringof~`))){
                                _data.`~memberName ~ ` = data.getData((`~ memberName.stringof ~`)).value.to!`~memType.stringof ~ `;
                        }
                        `;
                    }
                }
                else static if(!isArray!memType && hasUDA!(__traits(getMember, T ,memberName), JoinColumn))
                {
                    str ~= `
                        auto `~memberName~ ` = new ResultDes!(`~memType.stringof~`)(_em);
                        _data.`~memberName~ ` = `~memberName~`.deSerialize(rows,count,startIndex);
                    `;
                }
            }
        }
    }
    str ~= `
        return (_data);
    }`;
    return str;
}
