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

// version(WITH_HUNT_TRACE)
// {
//     // import hunt.trace.Constrants;
//     // import hunt.trace.Plugin;
//     import hunt.trace.Span;
// }

class TypedQuery(T : Object, F : Object = T)
{

    private string _sqlSting;
    private CriteriaQuery!(T, F) _query;
    private EntityManager _manager;

    // version (WITH_HUNT_TRACE)
    // {
    //     private Span _span;
    //     private string[string] _tags;
    // }

    this(CriteriaQuery!(T, F) query, EntityManager manager)
    {
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

    public Object getSingleResult()
    {
        Object[] ret = _getResultList();
        if (ret.length == 0)
            return null;
        return ret[0];
    }

    public T[] getResultList()
    {
        Object[] ret = _getResultList();
        if (ret.length == 0)
        {
            return null;
        }
        return cast(T[]) ret;
    }

    public TypedQuery!(T, F) setMaxResults(int maxResult)
    {
        _query.getQueryBuilder().limit(maxResult);
        return this;
    }

    public TypedQuery!(T, F) setFirstResult(int startPosition)
    {
        _query.getQueryBuilder().offset(startPosition);
        return this;
    }

    private Object[] _getResultList()
    {
        auto sql = _query.toString();
        // version (WITH_HUNT_TRACE)
        // {
        //     beginTrace("TypeQuery _getResultList");
        //     scope (exit)
        //     {
        //         _tags["sql"] = sql;
        //         endTrace();
        //     }
        // }
        Object[] ret;
        long count = -1;
        Statement stmt = _manager.getSession().prepare(sql);
        RowSet res = stmt.query();
        version(HUNT_ENTITY_DEBUG) {
            infof("columns: %s", res.columnsNames());
        }

        Row[] rows;
        foreach (value; res)
        {
            rows ~= value;
        }
        foreach (k, v; rows)
        {
            Object t = _query.getRoot().deSerialize(rows, count, cast(int) k);
            if (t is null)
            {
                if (count != -1)
                {
                    ret ~= new Long(count);
                }
                else
                {
                    throw new EntityException("getResultList has an null data");
                }
            }
            ret ~= t;
        }
        return ret;
    }

}
