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
        if(!_criteriaBuilder.getDbOption().isPgsql())
            _sqlBuidler.set(field.getFullColumn(), p);
        else
            _sqlBuidler.set(field.getColumnName(), p);
        return this;
    }

    public CriteriaUpdate!(T,F) set(EntityFieldInfo field) {
        string fieldName = field.getFieldName();
        Variant value = field.getColumnFieldData();

        version(HUNT_ENTITY_DEBUG_MORE) {
            tracef("EntityFieldInfo: (%s ), ColumnFieldData: (%s, %s)", field.toString(), value, 
                field.getColumnFieldData().type);
        }

        version(HUNT_ENTITY_DEBUG) {
            TypeInfo valueTypeInfo = typeid(value.type);
            tracef("field: %s, isAggregateType: %s, Type: %s", fieldName, field.isAggregateType(), valueTypeInfo);
        }

        if(field.isAggregateType()) {
            version(HUNT_DEBUG) warningf("An aggregate field ignored: %s", fieldName);
        } else {
            _sqlBuidler.set(fieldName, field.getColumnName(), field.getTableName(), value);

            // if(_criteriaBuilder.getDbOption().isPgsql())
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
