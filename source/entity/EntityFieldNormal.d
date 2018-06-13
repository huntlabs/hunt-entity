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

class EntityFieldNormal : EntityFieldInfo {

    private DlangDataType _fieldType;
    private CriteriaBuilder _builder;

    public this(CriteriaBuilder builder, string fileldName, string columnName, string tableName, Variant fieldValue, DlangDataType fieldType) {
        super(fileldName, columnName, fieldValue, tableName, EntityFieldType.NORMAL);
        _fieldType = fieldType;
        _builder = builder;
        _insertValue = _builder.getDialect().toSqlValueImpl(fieldType, fieldValue); 
    }
    public void assertType(T)() {
        if (_fieldType.getName() == "string" && getDlangTypeStr!T != "string") {
            throw new EntityException("EntityFieldInfo %s type need been string not %s".format(getFileldName(), typeid(T)));
        }
        if (_fieldType.getName() != "string" && getDlangTypeStr!T == "string") {
            throw new EntityException("EntityFieldInfo %s type need been number not string".format(getFileldName()));
        }
    }

    public R deSerialize(R)(string value) {
        // return *(_builder.getDialect().fromSqlValue(_fieldType, Variant(value))).peek!R;
        static if (is(R==bool)) {
            if (value == "0")
                return false;
            else if(value == "1")
                return true;
        }
        return to!R(value);
    }

}
