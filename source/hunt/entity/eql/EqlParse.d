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

import hunt.entity.eql.EqlInfo;
import hunt.entity;
import hunt.entity.EntityMetaInfo;
import hunt.sql;

import hunt.logging;
import hunt.collection;
import hunt.math;
import hunt.Number;
import hunt.String;
import hunt.Integer;
import hunt.Long;
import hunt.Double;
import hunt.Float;
import hunt.Short;
import hunt.Byte;
import hunt.Boolean;
import hunt.database;
import hunt.Nullable;

import std.algorithm.sorting;
import std.format;
import std.regex;
import std.string;

void eql_throw(string type, string message)
{
    throw new Exception("[EQL PARSE EXCEPTION. " ~ type ~ "] " ~ message);
}

class EqlParse
{
    alias EntityField = EntityFieldInfo[string];
    private string _eql;
    private string _parsedEql;
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor; //Table and alias
    private SchemaStatVisitor _schemaVistor;
    private List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    private EntityField[string] _tableFields; //Class name and field name
    private EqlObject[string] _eqlObj;
    public string[string] _objType;
    private Object[string] _joinConds;

    private Object[int] _params;
    private Object[string] _parameters;

    private EntityMetaInfo _entityInfo;
    private FormatOption _formatOption;
    private string _nativeSql;

    this(string eql, ref EntityMetaInfo entityInfo, string dbtype = "mysql")
    {
        _entityInfo = entityInfo;
        _parsedEql = _eql = eql;
        _dbtype = dbtype;
        _aliasVistor = new ExportTableAliasVisitor();
        _schemaVistor = SQLUtils.createSchemaStatVisitor(_dbtype);

        _formatOption = new FormatOption(true, true);
        _formatOption.config(VisitorFeature.OutputQuotedIdentifier, true);
    }

    FormatOption formatOption() {
        return _formatOption;
    }

    void formatOption(FormatOption value) {
        _formatOption = value;
    }

    string getEql()
    {
        return _eql;
    }

    string getDBType()
    {
        return _dbtype;
    }

    void setParsedEql(string parsedEql)
    {
        _parsedEql = parsedEql;
    }

    string getParsedEql()
    {
        return _parsedEql;
    }

    public void parse()
    {
        try
        {
            // version(HUNT_DEBUG)logInfo("-----> :",_parsedEql);
            _stmtList = SQLUtils.parseStatements(_parsedEql, _dbtype);

            foreach (stmt; _stmtList)
            {
                stmt.accept(_aliasVistor);
                stmt.accept(_schemaVistor);
            }

            if (_stmtList.size == 0)
                eql_throw("Statement", " statement error : " ~ _parsedEql);

            init();
        }
        catch (Exception e)
        {
            throw e;
        }

    }

    private void init()
    {
        _nativeSql = "";
        Map!(string, SQLTableSource) aliasMap = _aliasVistor.getAliasMap();
        foreach (string objName, SQLTableSource v; aliasMap)
        {
            string clsName;
            auto expr = (cast(SQLExprTableSource) v).getExpr();
            if (cast(SQLIdentifierExpr) expr !is null)
            {
                clsName = (cast(SQLIdentifierExpr) expr).getName();
            }
            else if (cast(SQLPropertyExpr) expr !is null)
            {

                // clsName = (cast(SQLPropertyExpr)expr);
                clsName = _objType.get(convertExprAlias(cast(SQLPropertyExpr) expr), null);
            }
            auto obj = new EqlObject(objName, clsName);
            _eqlObj[objName] = obj;
        }

        version (HUNT_ENTITY_DEBUG) trace(_clsNameToTbName);

        foreach (string objName, EqlObject obj; _eqlObj)
        {
            string className = obj.className();
            assert(!className.empty());

            string tableName = _clsNameToTbName.get(className, null);
            if (tableName.empty()) {
                eql_throw(className, "table is not found");
            }
            obj.setTableName(tableName);
        }

        // logDebug("aliasMap : %s".format(aliasMap));

        // logDebug("cls name : %s".format(_clsNameToTbName));

        // logDebug("EQL OBJS : %s".format(_eqlObj));

        // logDebug("EQL Conds : %s".format(_joinConds));

        // logDebug("EQL objType : %s".format(_objType));

        if (cast(SQLSelectStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_select_parse");
            doSelectParse();
        }
        else if (cast(SQLUpdateStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_update_parse");
            doUpdateParse();
        }
        else if (cast(SQLDeleteStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_delete_parse");
            doDeleteParse();
        }
        else if (cast(SQLInsertStatement)(_stmtList.get(0)) !is null)
        {
            version (HUNT_ENTITY_DEBUG_MORE)
                logDebug("EQL do_insert_parse");
            doInsertParse();
        }
        else
        {
            eql_throw("Statement",
                    " unknown sql statement : " ~ typeid(cast(Object)(_stmtList.get(0))).toString);
        }

        // logDebug("init eql : %s".format(_parsedEql));
    }

    private void doSelectParse()
    {
        auto queryBlock = (cast(SQLSelectStatement)(_stmtList.get(0))).getSelect().getQueryBlock();
        auto select_copy = queryBlock.clone();
        select_copy.getSelectList().clear();
        /// select item
        foreach (selectItem; queryBlock.getSelectList())
        {
            auto expr = selectItem.getExpr();
            
            Object oo = cast(Object)expr;
            // version(HUNT_DEBUG) infof("Expr: %s, item: %s", typeid(oo).name, SQLUtils.toSQLString(selectItem));
            version(HUNT_ENTITY_DEBUG) infof("Expr: %s", typeid(oo).name);

            if (cast(SQLIdentifierExpr) expr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLIdentifierExpr) expr).getName(), null);
                if (eqlObj !is null)
                {
                    auto clsName = eqlObj.className();
                    EntityFieldInfo[string] fields = _tableFields.get(clsName, null);

                    if (fields !is null)
                    {
                        foreach (string clsFiled, EntityFieldInfo entFiled; fields)
                        {
                            if (!(clsName ~ "." ~ clsFiled in _objType)) /// ordinary member
                            {
                                string columnAlias = selectItem.getAlias();

                                version(HUNT_ENTITY_DEBUG) {
                                    tracef("columnAlias: %s, SelectColumn: %s, fullColumn: %s", 
                                        columnAlias, entFiled.getSelectColumn(), entFiled.getFullColumn());
                                }

                                // SQLIdentifierExpr identifierExpr = new SQLIdentifierExpr(entFiled.getFullColumn());                                    

                                SQLIdentifierExpr identifierExpr = new SQLIdentifierExpr(columnAlias.empty()
                                        ? entFiled.getSelectColumn()
                                        : entFiled.getFullColumn());

                                select_copy.addSelectItem(identifierExpr, columnAlias);
                                // logDebug("sql replace : (%s ,%s) ".format(clsName ~ "." ~ clsFiled,clsName ~ "." ~ entFiled.getSelectColumn()));
                            }
                        }
                    }
                }
            }
            else if (cast(SQLPropertyExpr) expr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) expr).getOwnernName(), null);
                auto clsFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (clsFiled, entFiled; fields)
                        {
                            if (clsFiled == clsFieldName)
                            {
                                select_copy.addSelectItem(new SQLIdentifierExpr(selectItem.getAlias() is null
                                        ? entFiled.getSelectColumn()
                                        : entFiled.getFullColumn()), selectItem.getAlias());
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
                else
                {
                    eql_throw("Statement",
                    " undefined sql object  '%s' in '%s': ".format((cast(SQLPropertyExpr) expr).getOwnernName(),SQLUtils.toSQLString(expr)));
                }
            }
            else if (cast(SQLAggregateExpr) expr !is null)
            {
                SQLAggregateExpr aggreExpr = cast(SQLAggregateExpr) expr;
                List!SQLExpr newArgs = new ArrayList!SQLExpr();
                foreach (subExpr; aggreExpr.getArguments())
                {
                    // version(HUNT_ENTITY_DEBUG_MORE) {
                    //     tracef("arg expr : %s, arg string : %s",
                    //         typeid(cast(Object)subExpr).name, SQLUtils.toSQLString(subExpr));
                    // }

                    if (cast(SQLIdentifierExpr) subExpr !is null)
                    {
                        newArgs.add(subExpr);
                    }
                    else if (cast(SQLPropertyExpr) subExpr !is null)
                    {
                        SQLPropertyExpr pExpr = cast(SQLPropertyExpr) subExpr;
                        auto eqlObj = _eqlObj.get(pExpr.getOwnernName(), null);
                        auto clsFieldName = (cast(SQLPropertyExpr) subExpr).getName();
                        if (eqlObj !is null)
                        {
                            auto fields = _tableFields.get(eqlObj.className(), null);
                            if (fields !is null)
                            {
                                foreach (clsFiled, entFiled; fields)
                                {
                                    if (clsFiled == clsFieldName)
                                    {
                                        newArgs.add(new SQLPropertyExpr(eqlObj.tableName(),
                                                entFiled.getColumnName()));
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        newArgs.add(subExpr);
                    }
                }
                aggreExpr.getArguments().clear();
                aggreExpr.getArguments().addAll(newArgs);
                select_copy.addSelectItem(aggreExpr,selectItem.getAlias());
            }
            else
            {
                version(HUNT_ENTITY_DEBUG_MORE) {
                    auto o = cast(Object)expr;
                    warningf("Expr: %s, item: %s", typeid(o).name, SQLUtils.toSQLString(selectItem));
                }
                select_copy.addSelectItem(selectItem);
            }
        }

        ///from
        auto fromExpr = select_copy.getFrom();

        SQLExprTableSource  tableSource = cast(SQLExprTableSource)queryBlock.getFrom();
        SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)tableSource.getExpr(); 
        string tableAlias = tableSource.getAlias();
        string className = identifierExpr.getName();
        
        string[string] aliasModelMap;
        if(!tableAlias.empty()) {
            aliasModelMap[tableAlias] = className;
        }

        version (HUNT_ENTITY_DEBUG) trace(aliasModelMap);
        parseFromTable(fromExpr);
               

        ///where 
        auto whereCond = select_copy.getWhere();
        if (whereCond !is null)
        {
            // version (HUNT_ENTITY_DEBUG) {
            //     infof("Parsing the WHERE clause. The type is %s", typeid(cast(Object)whereCond));
            // }

            updateOwner(whereCond, _clsNameToTbName, aliasModelMap);
            
            string where = SQLUtils.toSQLString(whereCond);
            version (HUNT_ENTITY_DEBUG) warning(where);
            where = convertAttrExpr(where);
            version (HUNT_ENTITY_DEBUG) trace(where);
            select_copy.setWhere(SQLUtils.toSQLExpr(where));
        }

        ///order by
        auto orderBy = select_copy.getOrderBy();
        if (orderBy !is null)
        {
            version (HUNT_ENTITY_DEBUG) infof("Parsing the orderBy clause.");
            foreach (item; orderBy.getItems)
            {
                auto exprStr = SQLUtils.toSQLString(item.getExpr(), _dbtype);
                // version (HUNT_ENTITY_DEBUG_MORE)
                //     logDebug("order item : %s".format(exprStr));
                item.replace(item.getExpr(), SQLUtils.toSQLExpr(convertAttrExpr(exprStr), _dbtype));
            }
        }
        // else
        // {
        //     version (HUNT_ENTITY_DEBUG_MORE)
        //         logDebug("order by item is null");
        // }

        /// group by 
        auto groupBy = select_copy.getGroupBy();
        if (groupBy !is null)
        {
            version (HUNT_ENTITY_DEBUG) infof("Parsing the groupBy clause.");
            groupBy.getItems().clear();
            foreach (item; queryBlock.getGroupBy().getItems())
            {
                // logDebug("group item : %s".format(SQLUtils.toSQLString(item)));
                groupBy.addItem(SQLUtils.toSQLExpr(convertAttrExpr(SQLUtils.toSQLString(item))));
            }
            auto having = groupBy.getHaving();
            if (having !is null)
            {
                groupBy.setHaving(SQLUtils.toSQLExpr(
                        convertAttrExpr(SQLUtils.toSQLString(having))));
            }
            select_copy.setGroupBy(groupBy);
        }

        version(HUNT_ENTITY_DEBUG) info("The parsing done. Now, converting to native SQL...");
        _parsedEql = SQLUtils.toSQLString(select_copy, _dbtype);
        version(HUNT_ENTITY_DEBUG) warning(_parsedEql);

    }

    private void doUpdateParse()
    {
        SQLUpdateStatement updateBlock = cast(SQLUpdateStatement)(_stmtList.get(0));
        /// update item
        foreach (SQLUpdateSetItem updateItem; updateBlock.getItems())
        {
            version(HUNT_ENTITY_DEBUG_MORE)
            {
                tracef("clone select : ( %s , %s ) ", SQLUtils.toSQLString(updateItem.getColumn()),
                        SQLUtils.toSQLString(updateItem.getValue));
            }
            auto expr = updateItem.getColumn();
            if (cast(SQLIdentifierExpr) expr !is null)
            {

            }
            if (cast(SQLPropertyExpr) expr !is null)
            {
                EqlObject eqlObj = _eqlObj.get((cast(SQLPropertyExpr) expr).getOwnernName(), null);
                string clsFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    EntityField fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (string clsFiled, EntityFieldInfo entFiled; fields)
                        {
                            version(HUNT_ENTITY_DEBUG_MORE)
                            {
                                tracef("sql replace %s with %s, table: %s ", clsFiled,
                                        entFiled.getColumnName(), eqlObj.tableName());
                            }

                            if (clsFiled == clsFieldName)
                            {
                                if (_dbtype == DBType.POSTGRESQL.name)
                                { // PostgreSQL
                                    // https://www.postgresql.org/docs/9.1/sql-update.html
                                    updateItem.setColumn(new SQLIdentifierExpr(
                                            entFiled.getColumnName()));
                                    // updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(),
                                    //         entFiled.getColumnName()));
                                }
                                else
                                {
                                    updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(),
                                            entFiled.getColumnName()));
                                }
                                break;
                            }
                        }
                    }
                }
                else
                {
                    eql_throw("Statement",
                    " undefined sql object  '%s' in '%s': ".format((cast(SQLPropertyExpr) expr).getOwnernName(),SQLUtils.toSQLString(expr)));
                }
            }

            auto valueExpr = updateItem.getValue();
            if (cast(SQLPropertyExpr) valueExpr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) valueExpr).getOwnernName(), null);
                auto clsFieldName = (cast(SQLPropertyExpr) valueExpr).getName();
                if (eqlObj !is null)
                {
                    EntityField fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (string clsFiled, EntityFieldInfo entFiled; fields)
                        {
                            if (clsFiled == clsFieldName)
                            {
                                updateItem.setValue(new SQLPropertyExpr(eqlObj.tableName(),
                                        entFiled.getColumnName()));
                                break;
                            }
                            // tracef("sql replace : (%s ,%s) ", clsFiled, entFiled.getColumnName());
                        }
                    }
                }
            }
        }

        ///from
        auto fromExpr = updateBlock.getTableSource();
        // logDebug("update From : %s".format(SQLUtils.toSQLString(fromExpr)));
        parseFromTable(fromExpr);

        ///where 
        SQLExpr whereCond = updateBlock.getWhere();
        if (whereCond !is null)
        {
            string where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            updateBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _parsedEql = SQLUtils.toSQLString(updateBlock, _dbtype, _formatOption);

        version (HUNT_ENTITY_DEBUG_MORE)
            trace(_parsedEql);
    }

    private void doDeleteParse()
    {
        auto delBlock = cast(SQLDeleteStatement)(_stmtList.get(0));

        ///from
        auto fromExpr = delBlock.getTableSource();
        // logDebug("delete From : %s".format(SQLUtils.toSQLString(fromExpr)));

        parseFromTable(fromExpr);

        ///where 
        auto whereCond = delBlock.getWhere();
        if (whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            delBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _parsedEql = SQLUtils.toSQLString(delBlock, _dbtype, _formatOption);
    }

    private void doInsertParse()
    {
        SQLInsertStatement insertBlock = cast(SQLInsertStatement)(_stmtList.get(0));

        List!SQLExpr newColumns = new ArrayList!SQLExpr();

        /// insert item
        foreach (expr; insertBlock.getColumns())
        {
            version(HUNT_ENTITY_DEBUG_MORE)
                trace("insert item :", SQLUtils.toSQLString(expr));
            if (cast(SQLIdentifierExpr) expr !is null)
            {
                newColumns.add(expr);
            }
            if (cast(SQLPropertyExpr) expr !is null)
            {
                SQLPropertyExpr pExpr = cast(SQLPropertyExpr) expr;
                auto eqlObj = _eqlObj.get(pExpr.getOwnernName(), null);
                auto clsFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (clsFiled, entFiled; fields)
                        {
                            if (clsFiled == clsFieldName)
                            {
                                newColumns.add(new SQLIdentifierExpr(entFiled.getColumnName()));
                                break;
                            }
                        }
                    }
                }
                else
                {
                    eql_throw("Statement",
                    " undefined sql object  '%s' in '%s': ".format(pExpr.getOwnernName(),SQLUtils.toSQLString(pExpr)));
                }
            }
            insertBlock.getColumns().clear();
            insertBlock.getColumns().addAll(newColumns);

            // auto valueExpr = updateItem.getValue();
            // if (cast(SQLPropertyExpr) valueExpr !is null)
            // {
            //     auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) valueExpr).getOwnernName(), null);
            //     auto clsFieldName = (cast(SQLPropertyExpr) valueExpr).getName();
            //     if (eqlObj !is null)
            //     {
            //         auto fields = _tableFields.get(eqlObj.className(), null);
            //         if (fields !is null)
            //         {
            //             foreach (clsFiled, entFiled; fields)
            //             {
            //                 if (clsFiled == clsFieldName)
            //                 {
            //                     updateItem.setValue(new SQLPropertyExpr(eqlObj.tableName(),
            //                             entFiled.getColumnName()));
            //                     break;
            //                 }
            //                 // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
            //             }
            //         }
            //     }
            // }
        }

        ///from
        SQLExprTableSource fromExpr = insertBlock.getTableSource();
        // version (HUNT_DEBUG)
        //     logDebug("Insert into: %s".format(SQLUtils.toSQLString(fromExpr)));
        parseFromTable(fromExpr);

        _parsedEql = SQLUtils.toSQLString(insertBlock, _dbtype, _formatOption);

        if(_dbtype == DBType.POSTGRESQL) {
            string autoIncrementKey = _entityInfo.autoIncrementKey;
            _parsedEql = _parsedEql.stripRight(";");
            _parsedEql ~= " RETURNING " ~ autoIncrementKey ~ ";";
        }
    }

    /// a.id  --- > Class.id , a is instance of Class
    private string convertExprAlias(SQLPropertyExpr expr)
    {
        string originStr = SQLUtils.toSQLString(expr);
        auto objName = expr.getOwnernName();
        auto subPropertyName = expr.getName();
        auto aliasMap = _aliasVistor.getAliasMap();
        string clsName;
        foreach (obj, v; aliasMap)
        {
            if (obj == objName)
            {
                auto exprTab = (cast(SQLExprTableSource) v).getExpr();
                if (cast(SQLIdentifierExpr) exprTab !is null)
                {
                    expr.setOwner(exprTab);
                }
                else if (cast(SQLPropertyExpr) exprTab !is null)
                {
                    expr.setOwner(SQLUtils.toSQLExpr(
                            convertExprAlias(cast(SQLPropertyExpr) exprTab)));
                }
            }
        }
        // logDebug("get last type : ( %s , %s )".format(originStr,SQLUtils.toSQLString(expr)));
        return SQLUtils.toSQLString(expr);
    }

    /// a.id --> Table.col
    private string convertAttrExpr(string attrExpr)
    {
        string res = attrExpr;
        auto conds = matchAll(attrExpr, regex("([^\\(\\s]+)\\.([^\\s]+)"));
        bool[string] handerFlag;
        foreach (cond; conds)
        {
            string newCond = cond.captures[0];
            if (newCond in handerFlag)
                continue;
            else
                handerFlag[newCond] = true;
            auto eqlObj = _eqlObj.get(cond.captures[1], null);
            if (eqlObj !is null)
            {
                newCond = newCond.replace(cond.captures[1] ~ ".", eqlObj.tableName() ~ ".");
                auto fields = _tableFields.get(eqlObj.className(), null);
                if (fields !is null)
                {
                    foreach (clsFiled, entFiled; fields)
                    {
                        if (clsFiled == cond.captures[2])
                            newCond = newCond.replace("." ~ cond.captures[2],
                                    "." ~ entFiled.getColumnName());

                    }
                }
            }
            res = res.replace(cond.captures[0], newCond);
        }
        return res;
    }

    /// remove alias & a.xx -- > Table
    private void parseFromTable(SQLTableSource fromExpr)
    {
        version (HUNT_ENTITY_DEBUG) infof("Parsing the FROM clause. The type is: %s", typeid(cast(Object)fromExpr));
        if (fromExpr is null)
        {
            eql_throw("Table", "no found table");
        }
        // logDebug(" From table : %s".format(SQLUtils.toSQLString(fromExpr)));
        if (cast(SQLJoinTableSource) fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource) fromExpr;
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());

            auto defaultJoinCond = joinExpr.getCondition();
            if (defaultJoinCond is null)
            {
                // logDebug("join table no default condition");
            }
            else
            {
                auto convertAttrStr = convertAttrExpr(SQLUtils.toSQLString(defaultJoinCond));
                // logDebug(" join Cond : %s , convert : %s ".format(SQLUtils.toSQLString(defaultJoinCond),convertAttrStr));
                joinExpr.setCondition(SQLUtils.toSQLExpr(convertAttrStr));
            }

            if (cast(SQLJoinTableSource)(joinExpr.getLeft()) !is null)
            {
                auto subExpr = cast(SQLJoinTableSource)(joinExpr.getLeft());
                parseFromTable(subExpr);
            }
            else if (cast(SQLExprTableSource)(joinExpr.getLeft()) !is null)
            {
                auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());

                if (cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
                {
                    auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(leftExpr.getExpr()));
                    auto clsName = _objType.get(convertStr, null);
                    if (clsName !is null)
                    {
                        auto tableName = _clsNameToTbName.get(clsName, null);
                        if (tableName !is null)
                        {
                            leftExpr.setExpr(tableName);
                        }
                    }
                    auto joinCond = _joinConds.get(convertStr, null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                    if (joinCond !is null)
                    {
                        joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                    }
                }
                else if (cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
                {
                    auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                leftExpr.setAlias("");
            }

            if (rightExpr is null)
                return;
            if (cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(rightExpr.getExpr()));
                auto clsName = _objType.get(convertStr, null);
                if (clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(convertStr, null);
                // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if (joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                }
            }
            else if (cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName, null);
                if (tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
            }

            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if (expr is null)
                return;
            if (cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(expr.getExpr()));
                auto clsName = _objType.get(convertStr, null);
                if (clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }

            }
            else if (cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName, null);
                if (tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }
    }

    public void setParameter(R)(int idx, R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _params[idx] = new Integer(param);
        }
        else static if (is(R == char))
        {
            _params[idx] = new String(cast(string)[param]);
        }
        else static if (is(R == string))
        {
            _params[idx] = new String(param);
        }
        else static if (is(R == byte[]) || is(R == ubyte[]))
        {
            _params[idx] = new Bytes(cast(byte[]) param);
        }
        else static if (is(R == bool))
        {
            _params[idx] = new Boolean(param);
        }
        else static if (is(R == double))
        {
            _params[idx] = new Double(param);
        }
        else static if (is(R == float))
        {
            _params[idx] = new Float(param);
        }
        else static if (is(R == short) || is(R == ushort))
        {
            _params[idx] = new Short(param);
        }
        else static if (is(R == long) || is(R == ulong))
        {
            _params[idx] = new Long(param);
        }
        else static if (is(R == byte) || is(R == ubyte))
        {
            _params[idx] = new Byte(param);
        }
        else static if (is(R == class))
        {
            _params[idx] = param;
        }
        else
        {
            eql_throw("setParameter", "IllegalArgument not support : " ~ R.stringof);
        }
    }

    public void setParameter(R)(string key, R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _parameters[key] = new Integer(param);
        }
        else static if (is(R == char))
        {
            _parameters[key] = new String(cast(string)[param]);
        }
        else static if (is(R == string))
        {
            _parameters[key] = new String(param);
        }
        else static if (is(R == byte[]) || is(R == ubyte[]))
        {
            _parameters[key] = new Bytes(cast(byte[]) param);
        }
        // else static if (is(R == string) || is(R == char) || is(R == byte[]))
        // {
        //     _parameters[key] = new String(param);
        // }
        else static if (is(R == bool))
        {
            _parameters[key] = new Boolean(param);
        }
        else static if (is(R == double))
        {
            _parameters[key] = new Double(param);
        }
        else static if (is(R == float))
        {
            _parameters[key] = new Float(param);
        }
        else static if (is(R == short) || is(R == ushort))
        {
            _parameters[key] = new Short(param);
        }
        else static if (is(R == long) || is(R == ulong))
        {
            _parameters[key] = new Long(param);
        }
        else static if (is(R == byte) || is(R == ubyte))
        {
            _parameters[key] = new Byte(param);
        }
        else static if (is(R == class))
        {
            _parameters[key] = param;
        }
        else
        {
            eql_throw("setParameter", "IllegalArgument not support : " ~ R.stringof);
        }
    }

    public void putClsTbName(string clsName, string tableName)
    {
        _clsNameToTbName[clsName] = tableName;
    }

    public void putFields(string table, EntityField ef)
    {
        _tableFields[table] = ef;
    }

    public void putJoinCond(Object[string] conds)
    {
        foreach (k, v; conds)
        {
            _joinConds[k] = v;
        }
    }

    public string getTableName(string clsName)
    {
        return _clsNameToTbName.get(clsName, null);
    }

    public string getNativeSql()
    {
        if(!_nativeSql.empty())
            return _nativeSql;

        string sql = _parsedEql;

        version (HUNT_ENTITY_DEBUG_MORE)
            logDebug("EQL params : ", _parameters);

        foreach (k, v; _parameters)
        {
            auto re = regex(r":" ~ k ~ r"([^\w]*)", "g");
            if (cast(String) v !is null || (cast(Nullable!string) v !is null))
            {
                version (HUNT_ENTITY_DEBUG_MORE)
                    logInfo("-----: ", v.toString);
                if (_dbtype == DBType.POSTGRESQL.name)
                    sql = sql.replaceAll(re, quoteSqlString(v.toString(), "'") ~ "$1");
                else
                    sql = sql.replaceAll(re, quoteSqlString(v.toString()) ~ "$1");
            }
            else
            {
                sql = sql.replaceAll(re, v.toString() ~ "$1");
            }
        }

        if (_params.length > 0)
        {
            auto keys = _params.keys;
            sort!("a < b")(keys);
            List!Object params = new ArrayList!Object();
            foreach (e; keys)
            {
                params.add(_params[e]);
            }
            // sql = SQLUtils.format(sql, _dbtype, params, _formatOption);
            sql = SQLUtils.format(sql, _dbtype, params);
        } else {
            // sql = SQLUtils.format(sql, _dbtype, _formatOption);
            sql = SQLUtils.format(sql, _dbtype);
        }

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-10-09T14:41:55+08:00
        // why?
        // if (_dbtype == DBType.POSTGRESQL.name && _params.length == 0) {
        //     sql = SQLUtils.format(sql, _dbtype, _formatOption);
        //     warning(sql);
        // }

        version(HUNT_ENTITY_DEBUG) infof("result sql : %s", sql);
        _nativeSql = sql;
        return sql;
    }

    static void updateOwner(SQLExpr sqlExpr, string[string] modelTableMap, string[string] aliasModelMap) {
    // static void updateOwner(SQLSelectStatement statement, string[string] mappedNames) {
    //     SQLSelectQueryBlock queryBlock = selStmt.getSelect().getQueryBlock();

    //     // where
    //     SQLExpr sqlExpr = queryBlock.getWhere();
    //     infof("Where: %s", typeid(cast(Object)sqlExpr));
        version (HUNT_ENTITY_DEBUG) {
            infof("Parsing the WHERE clause. The type is %s", typeid(cast(Object)sqlExpr));
        }


        SQLInSubQueryExpr subQueryExpr = cast(SQLInSubQueryExpr)sqlExpr;

        if(subQueryExpr !is null) {

            // in express
            SQLPropertyExpr expr =  cast(SQLPropertyExpr)subQueryExpr.getExpr();
            string ownerName = expr.getOwnernName();
            auto itemPtr = ownerName in aliasModelMap;
            if(itemPtr !is null) {
                ownerName = *itemPtr;
                ownerName = modelTableMap.get(ownerName, ownerName);
                expr.setOwner(ownerName);
            }

            // version (HUNT_ENTITY_DEBUG) warningf("ownerName: %s", ownerName);


            // alias
            SQLSelect subSelect = subQueryExpr.getSubQuery();
            SQLSelectQueryBlock selectQuery = cast(SQLSelectQueryBlock)subSelect.getQuery();
            SQLExprTableSource  subFromExpr = cast(SQLExprTableSource)selectQuery.getFrom();

            string tableAlias = subFromExpr.getAlias();
            SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)subFromExpr.getExpr();
            string className = identifierExpr.getName();
            version (HUNT_ENTITY_DEBUG) tracef("tableAlias: %s, className: %s", tableAlias, className);

            itemPtr = className in modelTableMap;
            if(itemPtr is null) {
                warningf("No mapped model name found for class: %s", className);
            } else {
                identifierExpr.setName(*itemPtr);
            }
            subFromExpr.setAlias("");

            // 
        } else {
            warning("unhandled");
        }

    }
}
