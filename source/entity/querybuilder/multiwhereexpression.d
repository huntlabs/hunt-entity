module entity.querybuilder.multiwhereexpression;

import entity;

class QueryBuilderMultiWhereExpression : Expression
{
	Relation _relation;
	QueryBuilderMultiWhereExpression[] childs;
	QueryBuilderWhereExpression expr;
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
	QueryBuilderMultiWhereExpression eq(string key,string value)
	{
		if(value == null)
			expr = new QueryBuilderWhereExpression(key,"is",null);
		else 
			expr = new QueryBuilderWhereExpression(key,"=",value);
		return this;
	}
	QueryBuilderMultiWhereExpression ne(string key,string value)
	{
		if(value == null)
			expr = new QueryBuilderWhereExpression(key,"is not",null);
		else 
			expr =  new QueryBuilderWhereExpression(key,"!=",value);
		return this;
	}
	QueryBuilderMultiWhereExpression gt(string key,string value)
	{
		expr =  new QueryBuilderWhereExpression(key,">",value);
		return this;
	}
	QueryBuilderMultiWhereExpression lt(string key,string value)
	{
		expr = new QueryBuilderWhereExpression(key,"<",value);
		return this;
	}
	QueryBuilderMultiWhereExpression ge(string key,string value)
	{
		expr = new QueryBuilderWhereExpression(key,">=",value);
		return this;
	}
	QueryBuilderMultiWhereExpression le(string key,string value)
	{
		expr = new QueryBuilderWhereExpression(key,"<=",value);
		return this;
	}
	QueryBuilderMultiWhereExpression andX(T...)(T args)
	{
		_relation = Relation.And; 
		foreach(v;args)
		{
			childs ~= v;
		}
		return this;
	}
	QueryBuilderMultiWhereExpression orX(T...)(T args)
	{
		_relation = Relation.Or; 
		foreach(v;args)
		{
			childs ~= v;
		}
		return this;
	}
}
