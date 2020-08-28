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

module hunt.entity.eql.EqlQuery;

import hunt.entity;

import hunt.entity.EntityMetaInfo;
import hunt.entity.eql.EqlParse;
import hunt.entity.eql.ResultDes;
import hunt.entity.eql.EqlInfo;
import hunt.entity.eql.EqlCache;

import hunt.sql;
import hunt.logging.ConsoleLogger;
import hunt.collection;
import hunt.Long;

// version(WITH_HUNT_TRACE)
// {
//     import hunt.trace.Constrants;
//     import hunt.trace.Plugin;
//     import hunt.trace.Span;
// }

import std.algorithm;
import std.conv;
import std.format;
import std.traits;
import std.string;
import std.variant;



class EqlQuery(T...)
{
    alias executeUpdate = exec;
    alias ResultObj = T[0];

    private EntityManager _manager;
    private ResultDes!(ResultObj) _resultDes;

    private EqlParse _eqlParser;
    private string _eql;
    private string _countEql;
    private Pageable _pageable;
    private string[] _isExtracted;
    private long _offset = -1;
    private long _limit = -1;
    private int _lastInsertId = -1;
    private int _affectRows = 0;
    private EntityMetaInfo _entityInfo;
    // private enum EntityMetaInfo _entityInfo = extractEntityInfo!ResultObj();

    version (WITH_HUNT_TRACE)
    {
        private Span _span;
        private string[string] _tags;
    }

    this(string eql, EntityManager em)
    {
        _manager = em;
        _resultDes = new ResultDes!(ResultObj)(em);
        _eql = eql;
        _entityInfo = ResultObj.metaInfo; // extractEntityInfo!ResultObj();
        parseEql();
    }

    this(string query_eql, Pageable page, EntityManager em)
    {
        _manager = em;
        _resultDes = new ResultDes!(ResultObj)(em);
        _eql = query_eql;
        _pageable = page;
        parseEql();
    }

    version (WITH_HUNT_TRACE)
    {
        private void beginTrace(string name)
        {
            _tags.clear();
            _span = traceSpanBefore(name);
        }

        private void endTrace(string error = null)
        {
            if (_span !is null)
            {
                _tags["eql"] = _eql;
                traceSpanAfter(_span, _tags, error);
            }
        }
    }

    private void parseEql()
    {
        version (WITH_HUNT_TRACE)
        {
            beginTrace("EQL PARSE");
            scope (exit)
                endTrace();
        }
        DatabaseOption opt = _manager.getDbOption();
        if (opt.isMysql())
        {
            _eqlParser = new EqlParse(_eql, _entityInfo, DBType.MYSQL.name);
        }
        else if (opt.isPgsql())
        {
            _eqlParser = new EqlParse(_eql, _entityInfo, DBType.POSTGRESQL.name);
        }
        // else if (opt.isSqlite())
        // {
        //     _eqlParser = new EqlParse(_eql, DBType.SQLITE.name);
        // }
        else
        {
            throw new Exception("not support dbtype : %s".format(opt.schemeName()));
        }
        version(HUNT_SQL_DEBUG) {
            tracef("Raw sql: %s", _eql);
        }

        auto parsedEql = eqlCache.get(_eql);
        if (parsedEql is null)
        {
            foreach (ObjType; T)
            {
                extractInfo!ObjType();
            }
            _eqlParser.parse();

            eqlCache.put(_eql, _eqlParser.getParsedEql());
        }
        else
        {
            // version(HUNT_SQL_DEBUG_MORE) trace("EQL Cache Hit");
            _eqlParser.setParsedEql(parsedEql);
        }

        // _countEql = PagerUtils.count(_eqlParser.getNativeSql, _eqlParser.getDBType());
    }

    private void extractInfo(ObjType)()
    {
        if (_isExtracted.canFind(ObjType.stringof))
            return;
        _isExtracted ~= ObjType.stringof;

        static if (isAggregateType!(ObjType) && hasUDA!(ObjType, Table))
        {
            {
                auto entInfo = new EqlInfo!(ObjType)(_manager);

                _eqlParser.putFields(entInfo.getEntityClassName(), entInfo.getFields);
                _eqlParser.putClsTbName(entInfo.getEntityClassName(), entInfo.getTableName());

                _eqlParser.putJoinCond(entInfo.getJoinConds());
                if (ObjType.stringof == ResultObj.stringof)
                {
                    _resultDes.setFields(entInfo.getFields);
                }
            }
        }
        else
        {
            // throw new Exception(" not support type : " ~ ObjType.stringof);
        }

        foreach (memberName; __traits(derivedMembers, ObjType))
        {
            static if (__traits(getProtection, __traits(getMember, ObjType, memberName)) == "public")
            {
                alias memType = typeof(__traits(getMember, ObjType, memberName));
                static if (is(memType == class))
                {
                    {
                        auto sub_en = new EqlInfo!(memType)(_manager);
                        _eqlParser.putFields(sub_en.getEntityClassName(), sub_en.getFields);
                        _eqlParser.putClsTbName(sub_en.getEntityClassName(), sub_en.getTableName());
                        _eqlParser._objType[ObjType.stringof ~ "." ~ memberName] = sub_en.getEntityClassName();

                        extractInfo!memType();
                    }
                }
                else if (isArray!memType)
                {
                }
            }
        }
    }

    /**
    idx: It starts from 1. 
    */
    public EqlQuery setParameter(R = string)(int idx, R param)
    {
        if (_eqlParser !is null)
        {
            _eqlParser.setParameter!R(idx, param);
        }
        return this;
    }

    public EqlQuery setParameter(R = string)(string idx, R param)
    {
        if (_eqlParser !is null)
        {
            _eqlParser.setParameter!R(idx, param);
        }
        return this;
    }

    public EqlQuery setMaxResults(long maxResult)
    {
        if (_pageable)
        {
            throw new Exception("This method is not supported!");
        }
        _limit = maxResult;
        return this;
    }

    public EqlQuery setFirstResult(long startPosition)
    {
        if (_pageable)
        {
            throw new Exception("This method is not supported!");
        }
        _offset = startPosition;
        return this;
    }

    public string getExecSql()
    {
        auto sql = strip(_eqlParser.getNativeSql());
        if (endsWith(sql, ";"))
            sql = sql[0 .. $ - 1];
        if (_pageable)
        {
            sql ~= " limit " ~ to!string(_pageable.getPageSize());
            auto offset = _pageable.getOffset();
            if (offset > 0)
                sql ~= " offset " ~ to!string(offset);
        }
        else if (_limit != -1)
        {
            sql ~= " limit " ~ to!string(_limit);
            if (_offset != -1)
                sql ~= " offset " ~ to!string(_offset);
        }
        return sql;
    }

    int exec()
    {
        auto sql = getExecSql();
        version (WITH_HUNT_TRACE)
        {
            beginTrace("EqlQuery exec");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }
        
        Statement stmt = _manager.getSession().prepare(sql);
        string autoIncrementKey = _entityInfo.autoIncrementKey;
        int r = stmt.execute(autoIncrementKey);

        _lastInsertId = stmt.lastInsertId();
        _affectRows = stmt.affectedRows();

        //TODO update 时 返回的row line count 为 0
        return r;
    }

    public int lastInsertId()
    {
        return _lastInsertId;
    }

    public int affectedRows()
    {
        return _affectRows;
    }

    public ResultObj getSingleResult()
    {
        Object[] ret = _getResultList();
        if (ret.length == 0)
            return null;
        return cast(ResultObj)(ret[0]);
    }

    public ResultObj[] getResultList()
    {
        Object[] ret = _getResultList();
        if (ret.length == 0)
        {
            return null;
        }
        return cast(ResultObj[]) ret;
    }

    public Page!ResultObj getPageResult()
    {
        if (_pageable)
            _countEql = PagerUtils.count(_eqlParser.getNativeSql, _eqlParser.getDBType());
        else
        {
            throw new Exception("please use 'createPageQuery'");
        }

        auto res = getResultList();
        return new Page!ResultObj(res, _pageable, count(_countEql));
    }

    private Object[] _getResultList()
    {
        auto sql = getExecSql();
        version (WITH_HUNT_TRACE)
        {
            beginTrace("EqlQuery _getResultList");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }

        Object[] ret;
        long count = -1;
        Statement stmt = _manager.getSession().prepare(sql);
        RowSet res = stmt.query();
        if(res is null) {
            warning("The result of query is empty");
            return null;
        }

        Row[] rows;
        foreach (value; res)
        {
            rows ~= value;
        }

        foreach (k, v; rows)
        {
            try
            {
                ResultObj t = _resultDes.deSerialize(rows, count, cast(int) k);
                if (t is null)
                {
                    if (count != -1)
                    {
                        ret ~= new Long(count);
                    }
                    else
                    {
                        throw new EntityException("empty row data");
                    }
                }
                ret ~= t;
            }
            catch (Exception e)
            {
                version(HUNT_SQL_DEBUG) warning(e);
                else version(HUNT_DEBUG) warning(e.msg);
                throw new EntityException(e.msg);
            }

        }
        return ret;
    }

    public RowSet getNativeResult()
    {
        auto sql = getExecSql();
        version (WITH_HUNT_TRACE)
        {
            beginTrace("EqlQuery getNativeResult");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }

        auto stmt = _manager.getSession().prepare(sql);
        return stmt.query();
    }

    private long count(string sql)
    {
        version (WITH_HUNT_TRACE)
        {
            beginTrace("EqlQuery count");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }
        long total = 0;
        auto stmt = _manager.getSession().prepare(sql);
        RowSet res = stmt.query();
        foreach (Row row; res)
        {
            Variant v = row.getValue(0);
            total = to!int(v.toString());
        }
        return total;
    }
}
