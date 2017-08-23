module entity.criteriabuilder.criteriabuilder;

import entity;

public Dialect _dialect;

class CriteriaBuilder
{
	DatabaseConfig _config;
	Database _db;

    string _name;
    EntityInfo[string] _models;
    EntityInfo[TypeInfo_Class] _classMap;

    EntityManager _entitymanager;

    QueryBuilder querybuilder;
    
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
        querybuilder = new QueryBuilder(_config,_db,_dialect);
        querybuilder.from(_models[name].tableName);
	}

    CriteriaBuilder createCriteriaQuery()
    {
        querybuilder._method = Method.Select;
        return this;
    }
    CriteriaBuilder createCriteriaDelete()
    {
        querybuilder._method = Method.Delete;
        return this;
    }
    CriteriaBuilder createCriteriaUpdate()
    {
        querybuilder._method = Method.Update;
        return this;
    }
    CriteriaBuilder createCriteriaInsert()
    {
        querybuilder._method = Method.Insert;
        return this;
    }

    CriteriaBuilder where(CriteriaBuilderMultiWhereExpression expr)
	{
		querybuilder._mutliWhereStr = expr.toString;
		return this;
	}

    CriteriaBuilder where(CriteriaBuilderWhereExpression expr)
    {
        querybuilder.where(expr.toString);
        return this;
    }
    CriteriaBuilder having(FieldInfo info)
    {
        //querybuilder.having();
        return this;
    }
    CriteriaBuilder asc(FieldInfo info)
    {
        querybuilder.groupBy(info.fieldName ~ " ASC ");
        return this;
    }
    CriteriaBuilder desc(FieldInfo info)
    {
        querybuilder.groupBy(info.fieldName ~ " DESC ");
        return this;
    }
    CriteriaBuilder offset(int offset)
    {
        querybuilder.setFirstResult(offset);
        return this;
    }
    CriteriaBuilder limit(int limit)
    {
        querybuilder.setMaxResults(limit);
        return this;
    }
    CriteriaBuilder set(T)(FieldInfo info,T val)
    {
		querybuilder.setValue(info.fieldName,_dialect.toSqlValue(val));
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
    CriteriaBuilderhereExpression le(T)(FieldInfo info,T val)
    {
		return new CriteriaBuilderWhereExpression(info.fieldName,"<=",_dialect.toSqlValue(val));
    }
	CriteriaBuilderMultiWhereExpression expr()()
	{
        return new CriteriaBuilderMultiWhereExpression();
	}

    override string toString()
    {
        return querybuilder.toString();
    }

    int execute()
    {
        return _db.execute(querybuilder.toString()); 
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
