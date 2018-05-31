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

    public static R[] lazyLoadList(R,F)(EntityManager manager, LazyData data, F owner) {
		auto builder = manager.getCriteriaBuilder();
		auto criteriaQuery = builder.createQuery!(R,F);
		auto r = criteriaQuery.from(null, owner).autoJoin();
		auto p = builder.equal(r.get(data.key), data.value, false);
		auto query = manager.createQuery(criteriaQuery.select(r).where(p));
		auto ret = query.getResultList();
		foreach(v;ret) {
			v.setManager(manager);
		}
        return ret;
	}
	public static R lazyLoadSingle(R,F)(EntityManager manager, LazyData data, F owner) {
		auto builder = manager.getCriteriaBuilder();
		auto criteriaQuery = builder.createQuery!(R,F);
		auto r = criteriaQuery.from(null, owner).autoJoin();
		auto p = builder.equal(r.get(data.key), data.value, false);
		auto query = manager.createQuery(criteriaQuery.select(r).where(p));
		R ret = cast(R)(query.getSingleResult());
		ret.setManager(manager);
        return ret;
	}
}



mixin template GetFunction()
{
    mixin(makeEnableLazyLoad!(typeof(this)));
    pragma(msg, makeEnableLazyLoad!(typeof(this)));
}

string makeEnableLazyLoad(T)() {
    string str;
    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!isFunction!(memType)) {
            static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne) || hasUDA!(__traits(getMember, T ,memberName), OneToMany) ||
                        hasUDA!(__traits(getMember, T ,memberName), ManyToOne) || hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
                str ~= "\n\tpublic "~memType.stringof~" get"~capitalize(memberName)~"() {\n\t\t";
                static if (isArray!memType) {
                    str ~= "if ("~memberName~".length == 0)\n\t\t\t";
                    str ~= memberName~" = lazyLoadList!("~memType.stringof.replace("[]","")~","~T.stringof~")(getManager(), getLazyData(\""~memberName~"\"), this);\n\t\t";
                }
                else {
                    str ~= "if ("~memberName~" is null)\n\t\t\t";
                    str ~= memberName~" = lazyLoadSingle!("~memType.stringof~","~T.stringof~")(getManager(), getLazyData(\""~memberName~"\"), this);\n\t\t";
                }
                str ~= "return "~memberName~";\n\t}";
            }
        }
    }
    return str;
}  
