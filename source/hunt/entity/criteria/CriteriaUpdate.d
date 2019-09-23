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
 
module hunt.entity.criteria.CriteriaUpdate;

import hunt.entity;
import hunt.logging;
import std.variant;

class CriteriaUpdate(T : Object, F : Object = T) : CriteriaBase!(T,F)
{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!(T,F) from(T t = null, F owner = null) {
        super.from(t, owner);
        _sqlBuidler.update(_root.getTableName());
        return _root;
    }
    //Comparison
    public CriteriaUpdate!(T,F) where(R)(Comparison!R cond) {
        return cast(CriteriaUpdate!(T,F))super.where(cond);
    }
    //P = Predicate
    public CriteriaUpdate!(T,F) where(P...)(P predicates) {
        return cast(CriteriaUpdate!(T,F))super.where(predicates);
    }
    public CriteriaUpdate!(T,F) set(P)(EntityFieldInfo field, P p) {
        _criteriaBuilder.assertType!(P)(field);
        // logDebug("set value : %s".format(_criteriaBuilder.getDialect().toSqlValue(p)));
        if(!_criteriaBuilder.getDatabase().getOption().isPgsql())
            _sqlBuidler.set(field.getFullColumn(), p);
        else
            _sqlBuidler.set(field.getColumnName(), p);
        return this;
    }

    public CriteriaUpdate!(T,F) set(EntityFieldInfo field) {
        Variant value = field.getColumnFieldData();

        version(HUNT_ENTITY_DEBUG_MORE) {
            tracef("EntityFieldInfo: (%s ), ColumnFieldData: (%s, %s)", field.toString(), value, 
                field.getColumnFieldData().valueType);
        }

        // FIXME: Needing refactor or cleanup -@zxp at Sat, 21 Sep 2019 03:02:07 GMT
        // skip field which type is non-db
        TypeInfo valueTypeInfo = typeid(value.type);
        if(valueTypeInfo == typeid(TypeInfo_Class) || valueTypeInfo == typeid(TypeInfo_Interface)) {
            version(HUNT_DEBUG) warningf("Skipped Object field, field: %s", field.getFieldName());
        } else {
            _sqlBuidler.set(field.getFieldName(), 
                field.getColumnName(), field.getTableName(), value);

            // if(_criteriaBuilder.getDatabase().getOption().isPgsql())
            // {  
            //     _sqlBuidler.set(field.getColumnName(), value);
            // }
            // else
            // {
            //     _sqlBuidler.set(field.getFullColumn(), value);
            // }

        }
        return this;
    }    
}
