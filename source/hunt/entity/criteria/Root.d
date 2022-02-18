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

interface IRoot {

}

class Root(T : Object, F: Object = T) : IRoot {
    private EntityInfo!(T, F) _entityInfo;
    private CriteriaBuilder _builder;
    JoinSqlBuild[] _joins;
    private bool _enableJoin = false;

    this(CriteriaBuilder builder, T t = null, F owner = null) {
        _builder = builder;
        _entityInfo = new EntityInfo!(T, F)(_builder.getManager(), t, owner);
    }

    string getEntityClassName() {
        return _entityInfo.getEntityClassName();
    }

    string getTableName() {
        return _entityInfo.getTableName();
    }

    EntityInfo!(T, F) opDispatch(string name)() {
        if (getEntityClassName() != name)
            throw new EntityException("Cannot find entityinfo by name : " ~ name);
        return _entityInfo;
    }

    EntityFieldInfo get(string field) {
        return _entityInfo.getSingleField(field);
    }

    T deSerialize(Row[] rows, ref long count, int startIndex, F owner) {
        return _entityInfo.deSerialize(rows, count, startIndex, owner);
    }

    EntityFieldInfo getPrimaryField() {
        return _entityInfo.getPrimaryField();
    }

    EntityInfo!(T, F) getEntityInfo() {
        return _entityInfo;
    }

    JoinSqlBuild[] getJoins() {
        return _joins;
    }

    Join!(T, P) join(P)(EntityFieldInfo info, JoinType joinType = JoinType.INNER) {

        Join!(T, P) ret = new Join!(T, P)(_builder, info, this, joinType);
        JoinSqlBuild data = new JoinSqlBuild();
        data.tableName = ret.getTableName();
        data.joinWhere = ret.getJoinOnString();
        data.joinType = joinType;
        // data.columnNames = [ret.getPrimaryField().getSelectColumn()];
        data.columnNames = ret.getAllSelectColumn();
        _joins ~= data;

        return ret;
    }

    string[] getAllSelectColumn() {
        import std.algorithm;

        string[] ret;
        foreach (EntityFieldInfo value; _entityInfo.getFields()) {
            string name = value.getSelectColumn();
            version (HUNT_ENTITY_DEBUG_MORE) {
                infof("FileldName: %s, JoinPrimaryKey: %s, joinColumn: %s, selectColumn: %s",
                        value.getFieldName(), value.getJoinPrimaryKey(),
                        value.getJoinColumn(), name);
            }

            if (ret.canFind(name)) {
                version (HUNT_ENTITY_DEBUG)
                    warningf("duplicated column: %s", name);
                continue;
            }
            
            if (name != "") {
                ret ~= name;
            }
        }
        return ret;
    }

    Root!(T, F) autoJoin() {
        // logDebug("#### join Fields : ",_entityInfo.getFields());
        foreach (EntityFieldInfo value; _entityInfo.getFields()) {
            JoinSqlBuild build = value.getJoinSqlData();
            if(build is null) {
                version(HUNT_ENTITY_DEBUG) {
                    infof("No join for the field [%s] in %s.", value.getFieldName(), T.stringof);
                }
                continue;
            }

            if (_enableJoin || value.isEnableJoin()) {
                version(HUNT_ENTITY_DEBUG) {
                    trace("join sql : ", build.toString());
                }
                _joins ~= build;
            }
        }
        return this;
    }

    void setEnableJoin(bool flg) {
        _enableJoin = flg;
    }

}
