module entity.criteriabuilder.criteriabuilder;

import entity;

public Dialect _dialect;

class CriteriaBuilder
{
	DatabaseConfig _config;
	Database _db;

    string _name;
	bool _countFlag = false;
    EntityInfo[string] _models;
    EntityInfo[TypeInfo_Class] _classMap;

    EntityManager _entitymanager;

    SqlBuilder sqlbuilder;

	string _tableName;
    
	this(DatabaseConfig config,Database db,Dialect dialect,EntityManager entitymanager,string name,
        EntityInfo[string] models,
        EntityInfo[TypeInfo_Class] classMap)
	{
		_db = db;
		_config = config;
		_dialect = dialect;
        _name = name;
        _models = models;
        _classMap = classMap;
        _entitymanager = entitymanager;
        sqlbuilder = _entitymanager.createSqlBuilder;
        _tableName = _models[name].tableName;
        sqlbuilder.select("*").from(_tableName);
	}

    CriteriaBuilder createCriteriaQuery()
    {
        sqlbuilder.select("*").from(_tableName);
        return this;
    }
    CriteriaBuilder createCriteriaCount()
    {
		_countFlag = true;
        sqlbuilder.from(_tableName).count();
        return this;
    }
    CriteriaBuilder createCriteriaDelete()
    {
        sqlbuilder.remove(_tableName);
        return this;
    }
    CriteriaBuilder createCriteriaUpdate()
    {
        sqlbuilder.update(_tableName);
        return this;
    }
    CriteriaBuilder createCriteriaInsert()
    {
        sqlbuilder.insert(_tableName);
        return this;
    }

    CriteriaBuilder where(CriteriaBuilderMultiWhereExpression expr)
	{
		sqlbuilder.where(expr.toString);
		return this;
	}

    CriteriaBuilder where(CriteriaBuilderWhereExpression expr)
    {
        sqlbuilder.where(expr.toString);
        return this;
    }
    CriteriaBuilder having(FieldInfo info)
    {
        //sqlbuilder.having();
        return this;
    }
    CriteriaBuilder asc(FieldInfo info)
    {
        sqlbuilder.orderBy(info.fieldName ,"ASC");
        return this;
    }
    CriteriaBuilder desc(FieldInfo info)
    {
        sqlbuilder.orderBy(info.fieldName ,"DESC");
        return this;
    }
    CriteriaBuilder offset(int offset)
    {
        sqlbuilder.offset(offset);
        return this;
    }
    CriteriaBuilder limit(int limit)
    {
        sqlbuilder.limit(limit);
        return this;
    }
    CriteriaBuilder set(T)(FieldInfo info,T val)
    {
		sqlbuilder.set(info.fieldName,_dialect.toSqlValue(val));
        return this;
    }
    
    CriteriaBuilder leftJoin(T)(FieldInfo infoa,FieldInfo infob)
    {
        string joinTable = _models[T.stringof].tableName;
		sqlbuilder.leftJoin(joinTable,_tableName ~"."~infoa.fieldName 
                      ~ " = " ~ joinTable~"."~infob.fieldName);
        return this;
    }
    CriteriaBuilder rightJoin(T)(FieldInfo infoa,FieldInfo infob)
    {
        string joinTable = _models[T.stringof].tableName;
		sqlbuilder.rightJoin(joinTable,_tableName ~"."~infoa.fieldName 
                      ~ " = " ~ joinTable~"."~infob.fieldName);
        return this;
    }
    CriteriaBuilder innerJoin(T)(FieldInfo infoa,FieldInfo infob)
    {
        string joinTable = _models[T.stringof].tableName;
		sqlbuilder.innerJoin(joinTable,_tableName ~"."~infoa.fieldName 
                      ~ " = " ~ joinTable~"."~infob.fieldName);
        return this;
    }
    
    CriteriaBuilderWhereExpression eq(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,"=",_dialect.toSqlValue(val));
    }
    CriteriaBuilderWhereExpression ne(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,"!=",_dialect.toSqlValue(val));
    }
    CriteriaBuilderWhereExpression gt(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,">",_dialect.toSqlValue(val));
    }
    CriteriaBuilderWhereExpression lt(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,"<",_dialect.toSqlValue(val));
    }
    CriteriaBuilderWhereExpression ge(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,">=",_dialect.toSqlValue(val));
    }
    CriteriaBuilderWhereExpression le(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,"<=",_dialect.toSqlValue(val));
    }
	CriteriaBuilderMultiWhereExpression expr()()
	{
        return new CriteriaBuilderMultiWhereExpression();
	}

    override string toString()
    {
        return sqlbuilder.build().toString();
    }

    int execute()
    {
        auto stmt = _db.prepare(this.toString()); 
		if(_countFlag){
			_countFlag = false;
			return stmt.count();
		}else{
			return stmt.execute();
		}
	
    }

	auto getResultList()
    {
        return null; 
    }


    EntityInfo opDispatch(string name)() 
    {
        return _models.get(name,null);
    }
    EntityInfo opIndex(string name) 
    {
        return _models.get(name,null);
    }
} 

class CriteriaBuilderExpression
{

}

class CriteriaBuilderWhereExpression : CriteriaBuilderExpression
{
    string key;
    string op;
    string value;

    this(string key,string op,string value)
    {
        this.key = key;
        this.op = op;
        this.value = value;
    }

    override string toString()
    {
        return key ~" " ~ op ~ " " ~ value;
    }
}

class CriteriaBuilderMultiWhereExpression : CriteriaBuilderExpression
{
	Relation _relation;
	CriteriaBuilderMultiWhereExpression[] childs;
	CriteriaBuilderWhereExpression expr;
	override string toString()
	{
		if(childs.length){
			auto len = childs.length;
			int i = 0;
			string str;
			foreach(child;childs)
			{
				str ~= child.toString;
                if( i < len-1 )str ~=  (_relation == Relation.And ? " AND " : " OR ");
				i++;
			}
			return "(" ~ str ~ ")";
		}else{
			return "(" ~ expr.toString ~ ")";
		}
	}
    CriteriaBuilderMultiWhereExpression eq(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,"=",_dialect.toSqlValue(val));
        return this;
    }
    CriteriaBuilderMultiWhereExpression ne(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,"!=",_dialect.toSqlValue(val));
        return this;
    }
    CriteriaBuilderMultiWhereExpression gt(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,">",_dialect.toSqlValue(val));
        return this;
    }
    CriteriaBuilderMultiWhereExpression lt(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,"<",_dialect.toSqlValue(val));
        return this;
    }
    CriteriaBuilderMultiWhereExpression ge(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,">=",_dialect.toSqlValue(val));
        return this;
    }
    CriteriaBuilderMultiwhereExpression le(T)(FieldInfo info,T val)
    {
		expr = new CriteriaBuilderWhereExpression(info.fieldName,"<=",_dialect.toSqlValue(val));
        return this;
    }
	CriteriaBuilderMultiWhereExpression andX(T...)(T args)
	{
		_relation = Relation.And; 
		foreach(v;args)
		{
			childs ~= v;
		}
		return this;
	}
	CriteriaBuilderMultiWhereExpression orX(T...)(T args)
	{
		_relation = Relation.Or; 
		foreach(v;args)
		{
			childs ~= v;
		}
		return this;
	}
}
