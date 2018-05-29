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
 
module entity.EntityFieldOneToMany;

import entity;
class EntityFieldOneToMany(T : Object, F : Object) : EntityFieldObject!(T,F) {


    private OneToMany _mode;
    private string _primaryKey;
    private string _joinColumn;
    private string _findString;
    private T[][string] _decodeCache;



    this(CriteriaBuilder builder, string fileldName, string primaryKey, string tableName, OneToMany mode, F owner) {
        super(builder, fileldName, "", tableName, null, owner, EntityFieldType.ONE_TO_MANY);
        init(primaryKey, mode, owner);
    }

    private void init(string primaryKey,  OneToMany mode, F owner) {
        _mode = mode;       
        _primaryKey = primaryKey;
        _joinColumn = _entityInfo.getFields[_mode.mappedBy].getJoinColumn();
        initJoinData();
        initFindStr();
    }

    private void initJoinData() {
        _joinData = new JoinSqlBuild(); 
        _joinData.tableName = _entityInfo.getTableName();
        _joinData.joinWhere = getTableName() ~ "." ~ _primaryKey ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _joinColumn;
        _joinData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinData.columnNames ~= value.getSelectColumn();
        }
    }

    override public JoinSqlBuild getJoinData() {
        if (_mode.fetch == FetchType.LAZY)
            return null;
        return _joinData;
    }

    override public string getSelectColumn() {
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

    public string getPrimaryKey() {return _primaryKey;}
    public OneToMany getMode() {return _mode;}



    public T[] deSerialize(Row[] rows, int startIndex, bool isFromManyToOne) {
        T[] ret;
        if (_mode.fetch == FetchType.LAZY)
            return ret;
        T singleRet;
        long count = -1;
        if (!isFromManyToOne) {
            foreach(value; rows) {
                singleRet = _entityInfo.deSerialize([value], count);
                if (singleRet)
                    ret ~= Common.sampleCopy(singleRet);
            }
        }
        else {
            string joinValue = getJoinKeyValue(rows[startIndex]);
            if (joinValue == "")
                return ret;
            T[] rets = getValueByJoinKeyValue(joinValue);
            foreach(value; rets) {
                ret ~= Common.sampleCopy(value);
            }
        }
        return ret;
    }

    private string getJoinKeyValue(Row row) {
        RowData data = row.getAllRowData(getTableName());
        if (data is null)
            return "";
        RowDataS rd = data.getData(_primaryKey);
        if (rd is null)
            return "";
        return rd.value;
    }

    private T[] getValueByJoinKeyValue(string key) {
        if (key in _decodeCache)
            return _decodeCache[key];

        T[] ret;
        T singleRet;
        auto stmt = _builder.getManager().getSession().prepare(_findString~key);
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
}
