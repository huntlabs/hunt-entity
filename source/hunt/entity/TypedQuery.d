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

module hunt.entity.TypedQuery;

import hunt.entity;
import hunt.Long;
import hunt.logging.ConsoleLogger;

import std.variant;

// version(WITH_HUNT_TRACE)
// {
//     // import hunt.trace.Constrants;
//     // import hunt.trace.Plugin;
//     import hunt.trace.Span;
// }

class TypedQuery(T, F = T) if(is(T : Object) && is(F : Object)) {

    private string _sqlSting;
    private CriteriaQuery!(T, F) _query;
    private EntityManager _manager;

    // version (WITH_HUNT_TRACE)
    // {
    //     private Span _span;
    //     private string[string] _tags;
    // }

    this(CriteriaQuery!(T, F) query, EntityManager manager) {
        _query = query;
        _manager = manager;
    }

    // version (WITH_HUNT_TRACE)
    // {
    //     private void beginTrace(string name)
    //     {
    //         _tags.clear();
    //         _span = traceSpanBefore(name);
    //     }

    //     private void endTrace(string error = null)
    //     {
    //         if (_span !is null)
    //         {
    //             traceSpanAfter(_span, _tags, error);
    //         }
    //     }
    // }

    R getResultAs(R)() {
        string sql = _query.toString();
        Statement stmt = _manager.getSession().prepare(sql);
        RowSet rowSet = stmt.query();
        version (HUNT_ENTITY_DEBUG) {
            infof("The result columns: %s", rowSet.columnsNames());
        }

        if (rowSet.size() == 0) {
            warning("The result is empty");
            return R.init;
        }

        // First row and first column

        Row firstRow = rowSet.firstRow();
        if (firstRow.size() == 0) {
            warning("The column in the row is empty.");
            return R.init;
        }

        Variant singleValue = firstRow.getValue(0);
        if (singleValue.hasValue())
            return singleValue.get!R();
        else
            return R.init;
    }

    Object getSingleResult() {
        Object[] ret = _getResultList();
        if (ret.length == 0)
            return null;
        return ret[0];
    }

    T[] getResultList() {
        Object[] ret = _getResultList();
        if (ret.length == 0) {
            return null;
        }
        return cast(T[]) ret;
    }

    TypedQuery!(T, F) setMaxResults(int maxResult) {
        _query.getQueryBuilder().limit(maxResult);
        return this;
    }

    TypedQuery!(T, F) setFirstResult(int startPosition) {
        _query.getQueryBuilder().offset(startPosition);
        return this;
    }

    private Object[] _getResultList() {
        string sql = _query.toString();
        // version (WITH_HUNT_TRACE)
        // {
        //     beginTrace("TypeQuery _getResultList");
        //     scope (exit)
        //     {
        //         _tags["sql"] = sql;
        //         endTrace();
        //     }
        // }
        Statement stmt = _manager.getSession().prepare(sql);
        RowSet res = stmt.query();
        version (HUNT_ENTITY_DEBUG) {
            infof("The result columns: %s", res.columnsNames());
        }

        Row[] rows;
        foreach (value; res) {
            rows ~= value;
        }

        long count = -1;
        Object[] ret;
        Root!(T, F) r = _query.getRoot();
        foreach (size_t k, Row v; rows) {
            T t = r.deSerialize(rows, count, cast(int) k);
            if (t is null) {
                warningf("t is null, count=%d", count);
                if (count != -1) {
                    ret ~= new Long(count);
                } else {
                    throw new EntityException("getResultList has an null data");
                }
            }
            ret ~= t;
        }
        return ret;
    }

}
