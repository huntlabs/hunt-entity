module entity.querybuilder.whereexpression;

import entity;

class QueryBuilderWhereExpression : Expression
{
	string key;
	string op;
	string value;
	this(string key , string op, string value)
	{
		this.key = key;
		this.op = op;
		this.value = value;
	}
	string formatKey(string str)
	{
        return str;
	}
	string formatValue(string str)
	{
		if(str == null)return "null";
		return str;
	}
	override string toString()
	{
		return formatKey(key) ~ " " ~ op ~ " "~ formatValue(value);
	}
}
