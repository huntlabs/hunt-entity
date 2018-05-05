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
 
module entity.EntityFieldNormal;

import entity;

class EntityFieldNormal : EntityFieldInfo
{
    private DlangDataType _fieldType;

    public this(string fileldName, string columnName, string tableName, Variant fieldValue, DlangDataType fieldType)
    {
        super(fileldName, columnName, fieldValue, tableName);
        _fieldType = fieldType;
    }

    public void assertType(T)()
    {
        if (_fieldType.getName() == "string" && getDlangTypeStr!T != "string") {
            throw new EntityException("EntityFieldInfo %s type need been string not %s".format(getFileldName(), typeid(T)));
        }
        if (_fieldType.getName() != "string" && getDlangTypeStr!T == "string") {
            throw new EntityException("EntityFieldInfo %s type need been number not string".format(getFileldName()));
        }
    }

    public DlangDataType getFieldType() {return _fieldType;}

    public void deSerialize(R)(Dialect dialect, string value, ref R ret) {
        ret = *(dialect.fromSqlValue(_fieldType, Variant(value))).peek!R;
    }
}
