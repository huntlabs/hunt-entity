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

    public this(string fileldName, string columnName, Variant fieldValue, string tableName)
    {
        super(columnName, tableName);
        _fileldName = fileldName;
        _fieldValue = fieldValue;
        
    }

    // need override those functions
    // public R deSerialize(R)(string data){};
    // public void assertType(T)() {}

    public Variant getFieldValue() {return _fieldValue;}
    public string getFileldName() {return _fileldName;}
    public string getJoinColumn() {return _joinColumn;}
}
