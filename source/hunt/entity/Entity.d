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
 
module hunt.entity.Entity;

import hunt.entity;
import std.string;
import std.traits;

mixin template MakeModel()
{
    import hunt.serialization.Common;
    import hunt.validation;
    import hunt.logging.ConsoleLogger;
    import std.format;
    import hunt.entity.EntityMetaInfo;

    // pragma(msg, makeGetFunction!(typeof(this)));

    // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-08-28T16:59:53+08:00
    // 
    // enum EntityMetaInfo metaInfo = extractEntityInfo!(typeof(this));

    static EntityMetaInfo metaInfo() {
        enum m = extractEntityInfo!(typeof(this));
        return m;
    }

    mixin MakeLazyData;

    mixin MakeLazyLoadList!(typeof(this));
    mixin MakeLazyLoadSingle!(typeof(this));
    mixin(makeGetFunction!(typeof(this)));
    mixin MakeValid;
    /*  
     *   NOTE: annotation following code forbid auto create tables function when the EntityFactory construct for the reason when 
     *   the Entity model import other Entity model cause the dlang bug like "object.Error@src/rt/minfo.d(371): Cyclic dependency between 
     *   module SqlStruct.User and SqlStruct.Blog".
     *   if you want use the auto create tables function, you can open the following code and put all Entity model into one d file or 
     *   use EntityManagerFactory.createTables!(User,Blog) after EntityManagerFactory construct.
     */
    // shared static this() {
    //     addCreateTableHandle(getEntityTableName!(typeof(this)), &onCreateTableHandler!(typeof(this)));
    // }
}

mixin template MakeLazyData() {
    import hunt.logging.ConsoleLogger;

    @Ignore
    private LazyData[string] _lazyDatas;

    @Ignore
    private EntityManager _manager;

    void setManager(EntityManager manager) {_manager = manager;}
    EntityManager getManager() {return _manager;}

    void addLazyData(string key, LazyData data) {
        if (data is null) {
            warningf("No data for %s", key);
        } else {
            _lazyDatas[key] = data;
        }
    }

    LazyData[string] getAllLazyData() {
        return _lazyDatas;
    }

    LazyData getLazyData(string key ) {
        version(HUNT_ENTITY_DEBUG) {
            tracef("key: %s, lazyDatas size: %d", key, _lazyDatas.length);
        }

        auto itemPtr = key in _lazyDatas;
        
        if(itemPtr is null) {
            warningf("No data found for [%s]", key);
            return null;
        } else {
            return *itemPtr;
        }
    }    
}

mixin template MakeLazyLoadList(T) {

    private R[] lazyLoadList(R)(LazyData data , bool manyToMany = false , string mapped = "") {
        import hunt.logging;
        // logDebug("lazyLoadList ETMANAGER : ",_manager);
        auto builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!(R, T);
       
        // logDebug("****LoadList( %s , %s , %s )".format(R.stringof,data.key,data.value));

        if(manyToMany)
        {
            // logDebug("lazyLoadList for :",mapped);
            auto r = criteriaQuery.manyToManyFrom(null, this,mapped);

            auto p = builder.lazyManyToManyEqual(r.get(data.key), data.value, false);
        
            auto query = _manager.createQuery(criteriaQuery.select(r).where(p));
            auto ret = query.getResultList();
            foreach(v;ret) {
                v.setManager(_manager);
            }
            return ret;
        }
        else
        {
            auto r = criteriaQuery.from(null, this);

            auto p = builder.lazyEqual(r.get(data.key), data.value, false);
        
            auto query = _manager.createQuery(criteriaQuery.select(r).where(p));
            auto ret = query.getResultList();
            foreach(v;ret) {
                v.setManager(_manager);
            }
            return ret;
        }
        
    }    
}


mixin template MakeLazyLoadSingle(T) {

    import hunt.logging.ConsoleLogger;

    private R lazyLoadSingle(R)(LazyData data) {
        if(data is null) {
            warning("The parameter is null");
            return R.init;
        }
        auto builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!(R, T);
        auto r = criteriaQuery.from(null, this);
        auto p = builder.lazyEqual(r.get(data.key), data.value, false);
        TypedQuery!(R, T) query = _manager.createQuery(criteriaQuery.select(r).where(p));
        Object singleResult = query.getSingleResult();

        if(singleResult is null) {
            warningf("The result (%s) is null", R.stringof);
            return R.init;
        }

        R ret = cast(R)(singleResult);
        if(ret is null) {
            warningf("Type missmatched, expect: %s, actural: %s", typeid(R), typeid(singleResult));
        }
        ret.setManager(_manager);
        return ret;
    }    
}

string makeGetFunction(T)() {
    string str;
    string allGetMethods;

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMemeber = __traits(getMember, T, memberName);
        alias memType = typeof(currentMemeber);

        static if (__traits(getProtection, currentMemeber) == "public") {

            static if (hasUDA!(currentMemeber, OneToOne)) {
                enum bool lazyLoading = true;
                enum FetchType fetchType = getUDAs!(currentMemeber, OneToOne)[0].fetch;
            } else static if (hasUDA!(currentMemeber, OneToMany)) {
                enum bool lazyLoading = true;
                enum FetchType fetchType = getUDAs!(currentMemeber, OneToMany)[0].fetch;
            } else static if (hasUDA!(currentMemeber, ManyToOne)) {
                enum bool lazyLoading = true;
                enum FetchType fetchType = getUDAs!(currentMemeber, ManyToOne)[0].fetch;
            } else static if (hasUDA!(currentMemeber, ManyToMany)) {
                enum bool lazyLoading = true;
                enum FetchType fetchType = getUDAs!(currentMemeber, ManyToMany)[0].fetch;
            } else {
                enum bool lazyLoading = false;
            }

            static if (lazyLoading) {
                static if(fetchType == FetchType.EAGER && !hasUDA!(currentMemeber, JoinColumn)) {
                    allGetMethods ~= `
                        if(` ~ memberName ~ ` is null) {
                            info("loading data for [` ~ memberName ~ `] in [` ~ T.stringof ~ `]");
                            get` ~ capitalize(memberName) ~ `();
                        }
                    `;
                }

                str ~= `
                public `~memType.stringof ~ " get" ~ capitalize(memberName) ~ `() {`;
                
                static if (isArray!memType) {
                    string mappedBy;
                static if(hasUDA!(currentMemeber, ManyToMany)) {
                    str ~= "\n bool manyToMany = true ;";
                    
                    mappedBy = "\"" ~ getUDAs!(currentMemeber, ManyToMany)[0].mappedBy ~ "\"";
                } else {
                    str ~= "\n bool manyToMany = false ;";
                }

                str ~= "\n" ~ memberName ~ ` = lazyLoadList!(` ~ memType.stringof.replace("[]","") ~ 
                            `)(getLazyData("`~memberName~`"), manyToMany, `~mappedBy~`);`;
                } else {
                    str ~= "\n" ~ memberName~` = lazyLoadSingle!(`~memType.stringof~`)(getLazyData("`~memberName~`"));`;
                }

                str ~= `
                    return `~memberName~`;
                }`;
            }
        }
    }}

    // Try to load the other members which is not loaed in current mapping.
    
    str ~= "\n";
    str ~= `
    void loadLazyMembers() {
        version(HUNT_ENTITY_DEBUG) {
            infof("Try to load data for the other object members in %s", typeid(` ~ T.stringof ~ `));
        }
        ` ~ allGetMethods ~ `
    }
    `;

    return str;
}  

