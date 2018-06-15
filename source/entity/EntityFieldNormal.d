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

    
    private CriteriaBuilder _builder;

    public this(CriteriaBuilder builder, string fileldName, string columnName, string tableName, Variant fieldValue, DlangDataType dfieldType) {
        super(fileldName, columnName, fieldValue, tableName, EntityFieldType.NORMAL);
        _dfieldType = dfieldType;
        if (builder) {
            _builder = builder;
            _insertValue = _builder.getDialect().toSqlValueImpl(_dfieldType, fieldValue); 
        }
    }
    public void assertType(T)() {
        if (_dfieldType.getName() == "string" && getDlangTypeStr!T != "string") {
            throw new EntityException("EntityFieldInfo %s type need been string not %s".format(getFileldName(), typeid(T)));
        }
        if (_dfieldType.getName() != "string" && getDlangTypeStr!T == "string") {
            throw new EntityException("EntityFieldInfo %s type need been number not string".format(getFileldName()));
        }
    }

    public void deSerialize(R)(string value, ref R r) {
        if (value.length == 1 && cast(byte)(value[0]) == 0) {
            return;
        }
        static if (is(R==bool)) {
            r = cast(byte)(value[0]) == 1;
        }
        else {
            r = to!R(value);
        }
    }

    

}
