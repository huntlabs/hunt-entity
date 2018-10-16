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
 
module hunt.entity.eql.EqlParse;

import hunt.entity;
import hunt.sql;
import hunt.logging;
import hunt.container;
import hunt.math;
import std.algorithm.sorting;
import hunt.entity.eql.EqlInfo;
import std.regex;

class EqlParse
{
    alias EntityField = EntityFieldInfo[string];
    private string _eql;
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor; //表 与 别名
    private SchemaStatVisitor   _schemaVistor;
    private List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    private EntityField[string] _tableFields;   //类名 与 表字段
    private EqlObject[string] _eqlObj;
    public  string[string] _objType;
    public  string[string] _joinConds;

    private Object[int] _params;

    this(string eql, string dbtype = "mysql")
    {
        _eql = eql;
        _dbtype = dbtype;
        _aliasVistor = new ExportTableAliasVisitor();
        _schemaVistor = SQLUtils.createSchemaStatVisitor(_dbtype);
    }

    void parse()
    {
        _stmtList = SQLUtils.parseStatements(_eql, _dbtype);

        foreach(stmt ; _stmtList)
        {
            stmt.accept(_aliasVistor);
            stmt.accept(_schemaVistor);
        }

        init();
    }

    void init()
    {
        auto aliasMap = _aliasVistor.getAliasMap();
        foreach(objName , v ; aliasMap)
        {
            string clsName;
            auto expr = (cast(SQLExprTableSource)v).getExpr();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                clsName = (cast(SQLIdentifierExpr)expr).getName();
            }
            else if(cast(SQLPropertyExpr)expr !is null)
            {
                clsName = (cast(SQLPropertyExpr)expr).getName();
                clsName = _objType.get(clsName,clsName);
            }
            auto obj = new EqlObject(objName , clsName);
            _eqlObj[objName] = obj;
        }

        foreach(objName , obj ; _eqlObj)
        {
            if(obj.className() != null)
            {
                obj.setTableName(_clsNameToTbName.get(obj.className(),null));
            }
        }

        // logDebug("aliasMap : %s".format(aliasMap));

        // logDebug("cls name : %s".format(_clsNameToTbName));

        // logDebug("EQL OBJS : %s".format(_eqlObj));

        // logDebug("EQL Conds : %s".format(_joinConds));

        /// select item
        if(cast(SQLSelectStatement)(_stmtList.get(0)) !is null)
        {
            logDebug("EQL do_select_parse");
            do_select_parse();
        }
        else if(cast(SQLUpdateStatement)(_stmtList.get(0)) !is null)
        {
            logDebug("EQL do_update_parse");
            do_update_parse();
        }
        else if(cast(SQLDeleteStatement)(_stmtList.get(0)) !is null)
        {
            logDebug("EQL do_delete_parse");
            do_delete_parse();
        }


        // logDebug("init eql : %s".format(_eql));
    }

    


    void do_select_parse()
    {
        auto queryBlock = (cast(SQLSelectStatement)(_stmtList.get(0))).getSelect().getQueryBlock();
        auto select_copy = queryBlock.clone();
        select_copy.getSelectList().clear();
        foreach(selectItem; queryBlock.getSelectList()) {
            // logDebug("clone selcet : ( %s , %s ) ".format(SQLUtils.toSQLString(selectItem.getExpr()),selectItem.computeAlias()));
            auto expr = selectItem.getExpr();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLIdentifierExpr)expr).getName(),null);
                if(eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(),null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(!(clsFiled in _objType))
                                select_copy.addSelectItem(new SQLIdentifierExpr(entFiled.getSelectColumn()));
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
            }
            if(cast(SQLPropertyExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLPropertyExpr)expr).getOwnernName(),null);
                auto clsFieldName = (cast(SQLPropertyExpr)expr).getName();
                if(eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(),null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(clsFiled == clsFieldName)
                            {
                                select_copy.addSelectItem(new SQLIdentifierExpr(entFiled.getSelectColumn()));
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
            }
        }

        ///from
        auto fromExpr = select_copy.getFrom();
        if(cast(SQLJoinTableSource)fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource)fromExpr;
            auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());
            if(cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(leftExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    leftExpr.setExpr(tableName);
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            if(cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(rightExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
                 auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            leftExpr.setAlias("");
            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if(cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(expr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }
                
            }
            else if(cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }

        ///where 
        auto whereCond = select_copy.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            select_copy.setWhere(SQLUtils.toSQLExpr(where));
        }

        ///order by
        auto orderBy = select_copy.getOrderBy();
        if(orderBy !is null)
        {
            foreach(item ; orderBy.getItems)
            {
                auto exprStr = SQLUtils.toSQLString(item.getExpr());
                // logDebug("order item : %s".format(exprStr));
                item.replace(item.getExpr(),SQLUtils.toSQLExpr(convertAttrExpr(exprStr)));
            }
        }

        _eql = SQLUtils.toSQLString(select_copy);

    }

    void do_update_parse()
    {
        auto updateBlock = cast(SQLUpdateStatement)(_stmtList.get(0));

        foreach(updateItem; updateBlock.getItems()) {
            // logDebug("clone selcet : ( %s , %s ) ".format(SQLUtils.toSQLString(selectItem.getExpr()),selectItem.computeAlias()));
            auto expr = updateItem.getColumn();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                
            }
            if(cast(SQLPropertyExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLPropertyExpr)expr).getOwnernName(),null);
                auto clsFieldName = (cast(SQLPropertyExpr)expr).getName();
                if(eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(),null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(clsFiled == clsFieldName)
                            {
                                updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(),entFiled.getColumnName()));
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
            }
        }

        ///from
        auto fromExpr = updateBlock.getTableSource();
            // logDebug("update From : %s".format(SQLUtils.toSQLString(fromExpr)));

        if(cast(SQLJoinTableSource)fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource)fromExpr;
            auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());
            if(cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(leftExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    leftExpr.setExpr(tableName);
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            if(cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(rightExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
                 auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            leftExpr.setAlias("");
            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if(cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(expr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }
                
            }
            else if(cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }

        ///where 
        auto whereCond = updateBlock.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            updateBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _eql = SQLUtils.toSQLString(updateBlock);
    }

    void do_delete_parse()
    {
        auto delBlock = cast(SQLDeleteStatement)(_stmtList.get(0));

        
        ///from
        auto fromExpr = delBlock.getTableSource();
            // logDebug("delete From : %s".format(SQLUtils.toSQLString(fromExpr)));

        if(cast(SQLJoinTableSource)fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource)fromExpr;
            auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());
            if(cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(leftExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    leftExpr.setExpr(tableName);
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            if(cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(rightExpr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }
            else if(cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
                 auto joinCond = _joinConds.get(clsName,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond));
                }
            }

            leftExpr.setAlias("");
            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if(cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto clsName = _objType.get((cast(SQLPropertyExpr)(expr.getExpr())).getName(),null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }
                
            }
            else if(cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }

        ///where 
        auto whereCond = delBlock.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            delBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _eql = SQLUtils.toSQLString(delBlock);
    }

    /// a.id --> Table.col
    string convertAttrExpr(string attrExpr)
    {
        string res = attrExpr;
        auto conds = matchAll(attrExpr, regex("([^\\s]+)\\.([^\\s]+)"));
        foreach(cond ; conds)
        {
            string newCond = cond.captures[0];
            auto eqlObj = _eqlObj.get(cond.captures[1],null);
            if(eqlObj !is null)
            {
                newCond = newCond.replace(cond.captures[1],eqlObj.tableName());
                auto fields = _tableFields.get(eqlObj.className(),null);
                if(fields !is null)
                {
                    foreach(clsFiled , entFiled ; fields)
                    {
                        if(clsFiled == cond.captures[2])
                            newCond = newCond.replace(cond.captures[2],entFiled.getColumnName());
                       
                    }
                }
            }
            res = res.replace(cond.captures[0],newCond);
        }
        return res;
    }
    
    void setParameter(R)(int idx , R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _params[idx] = new Integer(param);
        }
        else static if(is( R == string ) || is ( R == char ) || is( R == byte[] ))
        {
            _params[idx] = new String(param);
        }
        else static if(is( R == bool))
        {
            _params[idx] = new Boolean(param);
        }
        else static if(is( R == double))
        {
            _params[idx] = new Double(param);
        }
        else static if(is( R == float))
        {
            _params[idx] = new Float(param);
        }
        else static if(is( R == short) || is( R == ushort))
        {
            _params[idx] = new Short(param);
        }
        else static if(is( R == long) || is( R == ulong))
        {
            _params[idx] = new Long(param);
        }
        else static if(is(R == byte) || is(R == ubyte))
        {
            _params[idx] = new Byte(param);
        }
    }

    void putClsTbName(string clsName, string tableName)
    {
        _clsNameToTbName[clsName] = tableName;
    }

    void putFields(string table, EntityField ef)
    {
        _tableFields[table] = ef;
    }


    string getTableName(string clsName)
    {
        return _clsNameToTbName.get(clsName,null);
    }

    string getNativeSql()
    {
        string sql = _eql;
     
        auto keys = _params.keys;
		sort!("a < b")(keys);
        List!Object params = new ArrayList!Object();
		foreach(e;keys)
        {
            params.add(_params[e]);
        }
        sql = SQLUtils.format(sql, DBType.ORACLE.name,params);

        // logDebug("native sql : %s".format(sql));
        return sql;
    }
}