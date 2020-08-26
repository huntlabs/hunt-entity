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
 
module hunt.entity.EntityFieldOneToMany;

import hunt.logging;
import hunt.entity;
import hunt.Exceptions;
import std.variant;


class EntityFieldOneToMany(T : Object, F : Object) : EntityFieldObject!(T,F) {


    private OneToMany _mode;
    private string _primaryKey;
    // private string _joinColumn;
    private string _findString;
    private T[][string] _decodeCache;
    



    this(EntityManager manager, string fieldName, string primaryKey, string tableName, OneToMany mode, F owner) {
        super(manager, fieldName, "", tableName, null, owner);
        init(primaryKey, mode, owner);
    }

    private void init(string primaryKey,  OneToMany mode, F owner) {
        _mode = mode;       
        _enableJoin = _mode.fetch == FetchType.EAGER;    
        _primaryKey = primaryKey;
        _joinColumn = _entityInfo.getFields[_mode.mappedBy].getJoinColumn();
        initJoinData();
        initFindStr();
    }

    private void initJoinData() {
        _joinSqlData = new JoinSqlBuild(); 
        _joinSqlData.tableName = _entityInfo.getTableName();
        _joinSqlData.joinWhere = getTableName() ~ "." ~ _primaryKey ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _joinColumn;
        _joinSqlData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinSqlData.columnNames ~= value.getSelectColumn();
        }
        // logDebug("one to many join sql : %s ".format(_joinSqlData));
    }

    override string getSelectColumn() {
        return "";
    }


    private void initFindStr() {
        _findString = "SELECT ";
        string[] el;
        foreach(k,v; _entityInfo.getFields()) {
            if (v.getSelectColumn() != "")
                el ~= " "~v.getSelectColumn();
        }
        foreach(k,v; el) {
            _findString ~= v;
            if (k != el.length -1)
                _findString ~= ",";
        }
        _findString ~= " FROM "~_entityInfo.getTableName()~" WHERE " ~ _entityInfo.getTableName() ~"."~_joinColumn~" = ";
    }

    string getPrimaryKey() {return _primaryKey;}
    OneToMany getMode() {return _mode;}

    override FetchType fetchType() {
        return _mode.fetch;
    }    


    T[] deSerialize(Row[] rows, int startIndex, bool isFromManyToOne) {
        version(HUNT_ENTITY_DEBUG) {
            tracef("FetchType: %s, isFromManyToOne: %s", _mode.fetch, isFromManyToOne);
        }

        if (_mode.fetch == FetchType.LAZY)
            return null;

        T[] ret;
        T singleRet;
        long count = -1;
        if (isFromManyToOne) {
            string joinValue = getJoinKeyValue(rows[startIndex]);
            if (joinValue == "")
                return ret;
            T[] rets = getValueByJoinKeyValue(joinValue);
            foreach(value; rets) {
                ret ~= Common.sampleCopy(value);
            }
        } else {
            warning("11111");
            foreach(value; rows) {
                singleRet = _entityInfo.deSerialize([value], count);
                if (singleRet !is null)
                    ret ~= Common.sampleCopy(singleRet);
            }
            warning("222222");
        }
        return ret;
    }

    private string getJoinKeyValue(Row row) {
        string name = EntityExpression.getColumnAsName(_primaryKey, getTableName());
        Variant v = row.getValue(name);
        if(!v.hasValue()) {
            version(HUNT_DEBUG) warningf("Can't find value for %s", name);
            return null;
        }
        
        string value = v.toString();
        version(HUNT_ENTITY_DEBUG) tracef("A column: %s = %s", name, value);
        return value;        
    }

    private T[] getValueByJoinKeyValue(string key) {
        if (key in _decodeCache)
            return _decodeCache[key];

        T[] ret;
        T singleRet;
        auto stmt = _manager.getSession().prepare(_findString~key);
		auto res = stmt.query();
        long count = -1;
        foreach(value; res) {
            singleRet = _entityInfo.deSerialize([value], count);
            if (singleRet)
                ret ~=  singleRet;
        }
        _decodeCache[key] = ret;
        return _decodeCache[key];
    }

    void setMode(OneToMany mode) {
        _mode = mode;
        _enableJoin = _mode.fetch == FetchType.EAGER;    
    }

    override LazyData getLazyData(Row row) {
        string name = EntityExpression.getColumnAsName(_primaryKey, getTableName());
        Variant v = row.getValue(name);
        if(!v.hasValue()) {
            version(HUNT_DEBUG) warningf("Can't find the value of the primary key: %s", name);
            return null;
        }
        
        string value = v.toString();
        version(HUNT_ENTITY_DEBUG) {
            infof("The referenced primary column: %s=%s, the current model: %s", 
                name, value, T.stringof);
        }

        LazyData ret = new LazyData(_mode.mappedBy, value);
        return ret;        
    }



}
