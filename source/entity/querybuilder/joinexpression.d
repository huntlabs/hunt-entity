module entity.querybuilder.joinexpression;

import entity;

class QueryBuilderJoinExpression : Expression
{
	JoinMethod _join;
	string _table;
	string _tableAlias;
	string _on;
	this(JoinMethod join,string table,string tableAlias,string on)
	{
		_join = join;
		_table = table;
		_tableAlias = tableAlias;
		_on = on;
	}
	override string toString()
	{
		string str = " " ~ _join ~ " " ~ _table ~ " " ~ _tableAlias ~ " ";
		if(_join != JoinMethod.CrossJoin) str ~= " ON " ~ _on ~ " ";
		return str;
	}
}
