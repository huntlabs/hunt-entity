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
 
module hunt.entity.criteria.CriteriaQuery;

import hunt.entity;
import hunt.logging;

class CriteriaQuery (T : Object, F : Object = T) : CriteriaBase!(T,F)
{
    this(CriteriaBuilder criteriaBuilder)
    {
        super(criteriaBuilder);
    }

    public CriteriaQuery!(T,F) select(Root!(T,F) root)
    {
        string[] selectColumn = root.getAllSelectColumn();
        // version(HUNT_ENTITY_DEBUG) warning(selectColumn);

        foreach(value; root.getJoins()) {
            version(HUNT_ENTITY_DEBUG) logDebug("####join sql : %s".format(value));
            if (value.joinType == JoinType.INNER) {
                _sqlBuidler.innerJoin(value.tableName, value.joinWhere);
                foreach(v; value.columnNames) {
                    if (v != "")
                        selectColumn ~= v;
                }
            }
            else if (value.joinType == JoinType.LEFT) {
                _sqlBuidler.leftJoin(value.tableName, value.joinWhere);
                foreach(v; value.columnNames) {
                    if (v != "")
                        selectColumn ~= v;
                }
            }
            else {
                _sqlBuidler.rightJoin(value.tableName, value.joinWhere);
                foreach(v; value.columnNames) {
                    if (v != "")
                        selectColumn ~= v;
                }
            } 
        }
        _sqlBuidler.select(selectColumn);
        return this;
    }

    public CriteriaQuery!(T,F) select(EntityExpression info) {
        _sqlBuidler.select([info.getSelectColumn()]);
        return this;
    }
    //Comparison
    public CriteriaQuery!(T,F) where(R)(Comparison!R cond) {
        return cast(CriteriaQuery!(T,F))super.where(cond);
    }
    //P = Predicate
    public CriteriaQuery!(T,F) where(P...)(P predicates) {
        return cast(CriteriaQuery!(T,F))super.where(predicates);
    }
    //O = Order
    public CriteriaQuery!(T,F) orderBy(O...)(O orders) {
        foreach(v; orders) {
            _sqlBuidler.orderBy(v.getColumn() ~ " " ~ v.getOrderType());
        }
        return this;
    }
    //E = EntityFieldInfo
    public CriteriaQuery!(T,F) groupBy(E...)(E entityFieldInfos) {
        foreach(v; entityFieldInfos) {
            _sqlBuidler.groupBy(v.getFullColumn());
        }
        return this;
    }
    //P = Predicate
    public CriteriaQuery!(T,F) having(P...)(P predicates) { 
        string s;
        foreach(k, v; predicates) {
            s ~= v.toString();
            if (k != predicates.length-1) 
                s ~= " AND ";
        }
        _sqlBuidler.having(s);
        return this;
    }
    //E = EntityFieldInfo
    public CriteriaQuery!(T,F) multiselect(E...)(E entityExpressions) {
        string[] columns;
        foreach(v; entityExpressions) {
            columns ~= v.getSelectColumn();
        }
        _sqlBuidler.select(columns);
        return this;
    }

    public CriteriaQuery!(T,F) distinct(bool distinct) {
        _sqlBuidler.setDistinct(distinct);
        return this;
    }
    
    public QueryBuilder getQueryBuilder()
    {
        return _sqlBuidler;
    }
}
