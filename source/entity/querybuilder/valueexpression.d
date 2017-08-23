module entity.querybuilder.valueexpression;

import entity;

class QueryBuilderValueExpression : Expression
{
	string key;
	string value;
	this(string key , string value)
	{
		this.key = key;
		this.value = value;
	}
	override string toString()
	{
		return  key ~ " = " ~ value ;
		//return _dialect.openQuote ~ key ~ _dialect.closeQuote ~ " = " ~ value ;
	}
}
