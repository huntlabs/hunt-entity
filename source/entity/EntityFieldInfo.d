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
 
module entity.EntityFieldInfo;

import entity;

class EntityFieldInfo : EntityExpression
{
    private string _fileldName;
    private Variant _fieldValue;
    protected string _joinColumn;
    protected string _joinTable;
    protected string _joinPrimaryKey;
    protected ForeignKeyData _foreignKeyData;
    
    protected JoinSqlBuild _joinSqlData;
    private EntityFieldType _fieldType;
    protected bool _enableJoin = true;
    protected string _stringValue;
    protected DlangDataType _dfieldType;

    private bool _nullable = true;
    private bool _primary;
    private bool _auto;
    


    public this(string fileldName, string columnName, Variant fieldValue, string tableName, EntityFieldType fieldType = EntityFieldType.DEFAULT) {
        super(columnName, tableName);
        _fileldName = fileldName;
        _fieldValue = fieldValue;
        _fieldType = fieldType;
    }



    public void setNullable(bool b) {_nullable = b;}
    public bool getNullable() {return _nullable;}
    public void setPrimary(bool b) {_primary = b;}
    public bool getPrimary() {return _primary;}
    public void setAuto(bool b) {_auto = b;}
    public bool getAuto() {return _auto;}




    public Variant getFieldValue() {return _fieldValue;}

    public string getFileldName() {return _fileldName;}


    public string getJoinColumn() {return _joinColumn;}
    public string getJoinTable() {return _joinTable;}
    public string getJoinPrimaryKey() {return _joinPrimaryKey;}

    public ForeignKeyData getForeignKeyData() {return _foreignKeyData;}

    public JoinSqlBuild getJoinSqlData() {return _joinSqlData;}
    public EntityFieldType getFileldType() {return _fieldType;}
    public bool isEnableJoin() {return _enableJoin;}
    public string getStringValue() {return _stringValue;}
    public DlangDataType getDlangType() {return _dfieldType;}

 
}
