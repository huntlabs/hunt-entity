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
import std.traits;


mixin template MakeEntity()
{
    mixin(makeLazyData);
    mixin(makeLazyLoadList!(typeof(this)));
    mixin(makeLazyLoadSingle!(typeof(this)));
    mixin(makeGetFunction!(typeof(this)));
    // shared static this() {
    //     addCreateTableHandle(getEntityTableName!(typeof(this)), &onCreateTableHandler!(typeof(this)));
    // }
}


string makeLazyData() {
    return `
    private LazyData[string] _lazyDatas;
    private EntityManager _manager;
    public void setManager(EntityManager manager) {_manager = manager;}
    public EntityManager getManager() {return _manager;}
    public void addLazyData(string key, LazyData data) {
        if (data) {
            _lazyDatas[key] = data;
        }
    }
    public LazyData[string] getAllLazyData() {
        return _lazyDatas;
    }
    public LazyData getLazyData(string key) {
        return _lazyDatas[key];
    }`;
}
string makeLazyLoadList(T)() {
    return `
    private R[] lazyLoadList(R)(LazyData data) {
        auto builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!(R,`~T.stringof~`);
        auto r = criteriaQuery.from(null, this).autoJoin();
        auto p = builder.equal(r.get(data.key), data.value, false);
        auto query = _manager.createQuery(criteriaQuery.select(r).where(p));
        auto ret = query.getResultList();
        foreach(v;ret) {
            v.setManager(_manager);
        }
        return ret;
    }`;
}
string makeLazyLoadSingle(T)() {
    return `
    private R lazyLoadSingle(R)(LazyData data) {
        auto builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!(R,`~T.stringof~`);
        auto r = criteriaQuery.from(null, this).autoJoin();
        auto p = builder.equal(r.get(data.key), data.value, false);
        auto query = _manager.createQuery(criteriaQuery.select(r).where(p));
        R ret = cast(R)(query.getSingleResult());
        ret.setManager(_manager);
        return ret;
    }`;
}
string makeGetFunction(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne) || hasUDA!(__traits(getMember, T ,memberName), OneToMany) ||
                            hasUDA!(__traits(getMember, T ,memberName), ManyToOne) || hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
    str ~= `
    public `~memType.stringof~` get`~capitalize(memberName)~`() {`;
                    static if (isArray!memType) {
        str ~= `
        if (`~memberName~`.length == 0)
            `~memberName~` = lazyLoadList!(`~memType.stringof.replace("[]","")~`)(getLazyData("`~memberName~`"));`;
                    }
                    else {
        str ~= `
        if (`~memberName~` is null)
            `~memberName~` = lazyLoadSingle!(`~memType.stringof~`)(getLazyData("`~memberName~`"));`;
                    }
        str ~= `
        return `~memberName~`;
    }`;
                }
            }
        }
    }
    return str;
}  

