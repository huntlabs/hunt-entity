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
 
module hunt.entity.EntityFieldInfo;

import hunt.entity;
import std.format;
import std.variant;

class EntityFieldInfo : EntityExpression
{
    protected string _joinColumn;
    protected string _inverseJoinColumn;
    protected string _joinTable;
    protected string _joinPrimaryKey;
    protected ForeignKeyData _foreignKeyData;
    protected JoinSqlBuild _joinSqlData;
    // protected ColumnFieldData _columnFieldData;
    protected Variant _columnFieldData;
    protected bool _isMainMapped;
    protected bool _enableJoin = true;
    protected TypeInfo _typeInfo;

    private string _fieldName;
    private bool _nullable = true;
    private bool _primary;
    private bool _auto;

    this(string fieldName, string columnName, string tableName) {
        super(columnName, tableName);
        _fieldName = fieldName;
    }

    TypeInfo typeInfo() {
        return _typeInfo;
    }

    void setNullable(bool b) {_nullable = b;}
    bool getNullable() {return _nullable;}

    void setPrimary(bool b) {_primary = b;}
    bool getPrimary() {return _primary;}

    void setAuto(bool b) {_auto = b;}
    bool getAuto() {return _auto;}

    bool isMainMapped() {return _isMainMapped;}

    deprecated("Using getFieldName instead.")
    string getFileldName() {return _fieldName;}
    string getFieldName() {return _fieldName;}
    string getJoinColumn() {return _joinColumn;}
    string getInverseJoinColumn() {return _inverseJoinColumn;}
    string getJoinTable() {return _joinTable;}
    string getJoinPrimaryKey() {return _joinPrimaryKey;}
    ForeignKeyData getForeignKeyData() {return _foreignKeyData;}

    JoinSqlBuild getJoinSqlData() {return _joinSqlData;}

    bool isEnableJoin() {return _enableJoin;}
    void setEnableJoin(bool en) { _enableJoin = en;}

    Variant getColumnFieldData() {return _columnFieldData;}

    override string toString() {
        return format("isPrimary: %s, TableName:%s, FileldName: %s, ColumnName: %s, JoinTable: %s, JoinColumn: %s, ", 
            _primary, getTableName(), _fieldName, getColumnName(), _joinTable, _joinColumn);
    }

}
