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
 
module entity.Entity;

import entity;
import std.string;

class Entity
{
    public LazyData[string] _lazyDatas;
    private EntityManager _manager;
    public void setManager(EntityManager manager) {_manager = manager;}
    public EntityManager getManager() {return _manager;}
    public void addLazyData(string key, LazyData data) {
        if (data) {
            _lazyDatas[key] = data;
        }
    }
    public LazyData getLazyData(string key) {
        return _lazyDatas[key];
    }

    // auto insert code
    // public BookDetail getDetail()
    // public static Book[] lazyLoadList(EntityManager manager, LazyData data)
    // public static Book lazyLoadSingle(EntityManager manager, LazyData data)
}

mixin template EnableLazyLoad()
{
    mixin(makeEnableLazyLoad!(typeof(this)));
    pragma(msg, makeEnableLazyLoad!(typeof(this)));
}

string makeEnableLazyLoad(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
            static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                str ~= makeGetFunction(memberName, memType.stringof, isArray!memType);
            }
        }
    }
    str ~= makeLazyLoad(T.stringof, true);
    str ~= makeLazyLoad(T.stringof, false);
    return str;
}  

string makeGetFunction(string name, string ObjectType, bool isArray) {
    string str = "\n\t";
    str ~= "public "~ObjectType~" get"~capitalize(name)~"() {\n\t\t";
    str ~= "if ("~name~" is null)\n\t\t\t";
    if (isArray)
        str ~= name~" = "~ObjectType~".lazyLoadList(getManager(), getLazyData(\""~name~"\"));\n\t\t";
    else 
        str ~= name~" = "~ObjectType~".lazyLoadSingle(getManager(), getLazyData(\""~name~"\"));\n\t\t";

    str ~= "return "~name~";\n\t}";
    return str;
}

string makeLazyLoad(string ObjectType, bool isArray) {
    string str = "\n\t";
    string retStr = isArray ? ObjectType~"[]" : ObjectType;
    string functionName = isArray ? "lazyLoadList" : "lazyLoadSingle";
    str ~= "public static "~retStr~" "~functionName~"(EntityManager manager, LazyData data) {\n\t\t";
    str ~= "CriteriaBuilder builder = manager.getCriteriaBuilder();\n\t\t";
    str ~= "CriteriaQuery!"~ObjectType~" criteriaQuery = builder.createQuery!("~ObjectType~");\n\t\t";
    str ~= "Root!"~ObjectType~" r = criteriaQuery.from();\n\t\t";
    str ~= "Predicate p = builder.equal(r.get(data.key), data.value, false);\n\t\t";
    str ~= "TypedQuery!"~ObjectType~" query = manager.createQuery(criteriaQuery.select(r).where(p));\n\t\t";
    if (isArray) {
        str ~= retStr~" ret = query.getResultList();\n\t\t";
        str ~= "foreach(v;ret) {\n\t\t\t";
        str ~= "v.setManager(manager);\n\t\t";
        str ~= "}\n\t\t";
        str ~= "return ret;\n\t}";
    }   
    else {
        str ~= retStr~" ret = cast("~retStr~")(query.getSingleResult());\n\t\t"; 
        str ~= "ret.setManager(manager);\n\t\t";
        str ~= "return ret;\n\t}";
    }
    return str;
}


