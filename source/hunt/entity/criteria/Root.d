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
 
module hunt.entity.criteria.Root;

import hunt.entity;
import hunt.logging;
import std.traits;

class Root(T : Object, F : Object = T)
{
    private EntityInfo!(T,F) _entityInfo;
    private CriteriaBuilder _builder;
    JoinSqlBuild[] _joins;
    private bool _enableJoin = false;

    public this(CriteriaBuilder builder, T t = null, F owner = null) {
        _builder = builder;
        _entityInfo = new EntityInfo!(T,F)(_builder.getManager(), t, owner);
    }

    public string getEntityClassName() {
        return _entityInfo.getEntityClassName();
    }
    public string getTableName() {
        return _entityInfo.getTableName();
    }
    public EntityInfo!(T,F) opDispatch(string name)() {
        if (getEntityClassName() != name)
            throw new EntityException("Cannot find entityinfo by name : " ~ name);	
        return _entityInfo;
    }
    public EntityFieldInfo get(string field) {
        return _entityInfo.getSingleField(field);
    }
    public T deSerialize(Row[] rows, ref long count, int startIndex) {
        return _entityInfo.deSerialize(rows, count, startIndex);
    }
    public EntityFieldInfo getPrimaryField() {
        return _entityInfo.getPrimaryField();
    }

    public EntityInfo!(T,F) getEntityInfo() {return _entityInfo;}

    public JoinSqlBuild[] getJoins() {return _joins;}

    public Join!(T,P) join(P)(EntityFieldInfo info, JoinType joinType = JoinType.INNER) {

        Join!(T,P) ret = new Join!(T,P)(_builder, info, this, joinType);
        JoinSqlBuild data = new JoinSqlBuild();
        data.tableName = ret.getTableName();
        data.joinWhere = ret.getJoinOnString();
        data.joinType = joinType;
        // data.columnNames = [ret.getPrimaryField().getSelectColumn()];
        data.columnNames = ret.getAllSelectColumn();
        _joins ~= data;

        return ret;
    }
    
    public string[] getAllSelectColumn() {
        string[] ret;
        foreach(value; _entityInfo.getFields()) {
            if (value.getSelectColumn() != "") {
                ret ~= value.getSelectColumn();
            }
        }
        return ret;
    }

    public Root!(T, F) autoJoin() {
        // logDebug("#### join Fields : ",_entityInfo.getFields());
        foreach(value; _entityInfo.getFields()) {
            if (value.getJoinSqlData() && (_enableJoin || value.isEnableJoin()))
                // logDebug("** join sql : ",value.getJoinSqlData());
                _joins ~= value.getJoinSqlData(); 
        }
        return this;
    }

    public void setEnableJoin(bool flg)
    {
        _enableJoin = flg;
    }

}
