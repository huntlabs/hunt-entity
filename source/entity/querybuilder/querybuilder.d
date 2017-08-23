module entity.querybuilder.querybuilder;

import entity;

Dialect _dialect;
class QueryBuilder
{
	DatabaseConfig _config;
	Database _db;
	Method _method;
	string _tableName;
	string _tableNameAlias;
	string[] _selectKeys = ["*"];
	string _having;
	string _groupby;
	string _orderByKey;
	string _order;
	int _offset;
	int _limit;
	string _mutliWhereStr;
	QueryBuilderWhereExpression[] _whereKeys;
	QueryBuilderWhereExpression[] _whereKeysParameters;
	QueryBuilderValueExpression[string] _values;
	QueryBuilderValueExpression[] _valuesParameters;
	QueryBuilderJoinExpression[] _joins;
	this(DatabaseConfig config,Database db,Dialect dialect)
	{
		_db = db;
		_config = config;
		_dialect = dialect;
	}
	override string toString()
	{
		if(!_tableName.length)
			throw new EntityException("query build table name not exists");
		string str;
		switch(_method){
			case Method.Select:
				str ~= Method.Select;
				if(!_selectKeys.length)
					str ~= " * ";
				else {
					foreach(v;_selectKeys){
						str ~= v ~ ",";
					}
					str = str[0.. $-1];
				}
				str ~= " FROM " ~ _tableName ~ " " ~ _tableNameAlias ~ " ";
				if(_joins.length) foreach(join;_joins){str ~= join.toString;}
				if(_whereKeys.length){
					str ~= " WHERE ";
					int i = 0;
					foreach(v;_whereKeys){
						i++;
						str ~= v.toString;
						if(i<_whereKeys.length) str ~= " AND ";
					}
				}else if (_mutliWhereStr.length){
					str ~= " WHERE " ~ _mutliWhereStr;
				}else {
				}
				if(_groupby.length) str ~= " GROUP BY " ~ _groupby;
				if(_having.length) str ~= " HAVING " ~ _having;
				if(_orderByKey.length && _order.length) str ~= " ORDER BY " ~ _orderByKey ~ " " ~ _order;
				if(_limit) str ~= " LIMIT " ~ _limit.to!string;
				if(_offset) str ~= " OFFSET " ~ _offset.to!string;
				break;
			case Method.Update:
				str ~= Method.Update ~ " " ~ _tableName;
				if(_values.length){
					str ~= " SET ";
					int i = 0;
					foreach(k,v;_values){
						i++;
						str ~= v.toString;
						if(i<_values.length) str ~= " , ";
					}
				}else{
					throw new EntityException("query builder update method have not set values");
				}
				if(_whereKeys.length){
					str ~= " WHERE ";
					int i = 0;
					foreach(v;_whereKeys){
						i++;
						str ~= v.toString;
						if(i<_whereKeys.length) str ~= " AND ";
					}
				}else if (_mutliWhereStr.length){
					str ~= " WHERE " ~ _mutliWhereStr;
				}else {
				}
				if(_orderByKey.length && _order.length) str ~= " ORDER BY " ~ _orderByKey ~ " " ~ _order;
				if(_limit) str ~= " LIMIT " ~ _limit.to!string;
				break;
			case Method.Delete:
				str ~= Method.Delete ~ " " ~ _tableName;
				if(_whereKeys.length){
					str ~= " WHERE ";
					int i = 0;
					foreach(v;_whereKeys){
						i++;
						str ~= v.toString;
						if(i<_whereKeys.length) str ~= " AND ";
					}
				}else if (_mutliWhereStr.length){
					str ~= " WHERE " ~ _mutliWhereStr;
				}else {
				}
				if(_orderByKey.length && _order.length) str ~= " ORDER BY " ~ _orderByKey ~ " " ~ _order;
				if(_limit) str ~= " LIMIT " ~ _limit.to!string;
				break;
			case Method.Insert:
				str ~= Method.Insert ~ " " ~ _tableName ~ "(";
				if(!_values.length) throw new EntityException("query build insert have not values");
				string keys;
				string values;
				foreach(k,v;_values){
					keys ~= k~",";
					values ~= v.value~",";
					//values ~= "\""~v.value~"\",";
				}
				str ~= keys[0.. $-1] ~ ") VALUES("~ values[0..$-1]  ~")";
				break;
			default:
				throw new EntityException("query build method not found");
		}
		return str;
	}
	QueryBuilder from(string tableName,string tableNameAlias = null)
	{
		_tableName = tableName;
		_tableNameAlias = tableNameAlias.length ? tableNameAlias : tableName;
		return this;
	}
	QueryBuilder select(string...)(string args)
	{
		_selectKeys = null;
		foreach(arg;args)_selectKeys ~= arg;
		_method = Method.Select;
		return this;
	}
	QueryBuilder insert(string tableName)
	{
		_tableName = tableName;
		_method = Method.Insert;
		return this;
	}
	QueryBuilder update(string tableName)
	{
		_tableName = tableName;
		_method = Method.Update;
		return this;
	}
	//alias delete = remove;
	QueryBuilder remove(string tableName)
	{
		_tableName = tableName;
		_method = Method.Delete;
		return this;
	}
	QueryBuilder where(string expression)
	{
		if(!expression.length)return this;
		auto arr = split(strip(expression)," ");
		if(arr.length != 3)return this;
		auto expr = new QueryBuilderWhereExpression(arr[0],arr[1],arr[2]);
		_whereKeys ~= expr;
		if(arr[2] == "?")_whereKeysParameters ~= expr;
		return this;
	}
	QueryBuilder having(string expression)
	{
		_having = expression;
		return this;
	}
	QueryBuilder where(QueryBuilderMultiWhereExpression expr)
	{
		_mutliWhereStr = expr.toString;
		return this;
	}
    QueryBuilder where(T)(string key,CompareType type,T val)
    {
        _whereKeys ~= new QueryBuilderWhereExpression(key,type,_dialect.toSqlValue!T(val));
        return this;
    }
	QueryBuilderMultiWhereExpression expr()
	{
		return new QueryBuilderMultiWhereExpression();
	}
	QueryBuilder join(JoinMethod joinMethod,string table,string tablealias,string joinWhere)
	{
		_joins ~= new QueryBuilderJoinExpression(joinMethod,table,tablealias,joinWhere);
		return this;
	}
	QueryBuilder join(JoinMethod joinMethod,string table,string joinWhere)
	{
		return join(joinMethod,table,table,joinWhere);
	}
	QueryBuilder innerJoin(string table,string tablealias,string joinWhere)
	{
		return join(JoinMethod.InnerJoin,table,tablealias,joinWhere);
	}
	QueryBuilder innerJoin(string table,string joinWhere)
	{
		return innerJoin(table,table,joinWhere);
	}
	QueryBuilder leftJoin(string table,string tableAlias,string joinWhere)
	{
		return join(JoinMethod.LeftJoin,table,tableAlias,joinWhere);
	}
	QueryBuilder leftJoin(string table,string joinWhere)
	{
		return leftJoin(table,table,joinWhere);
	}
	QueryBuilder rightJoin(string table,string tableAlias,string joinWhere)
	{
		return join(JoinMethod.RightJoin,table,tableAlias,joinWhere);
	}
	QueryBuilder rightJoin(string table,string joinWhere)
	{
		return rightJoin(table,table,joinWhere);
	}
	QueryBuilder fullJoin(string table,string tableAlias,string joinWhere)
	{
		return join(JoinMethod.FullJoin,table,tableAlias,joinWhere);
	}
	QueryBuilder fullJoin(string table,string joinWhere)
	{
		return fullJoin(table,table,joinWhere);
	}
	QueryBuilder crossJoin(string table,string tableAlias)
	{
		return join(JoinMethod.CrossJoin,table,tableAlias,null);
	}
	QueryBuilder crossJoin(string table)
	{
		return crossJoin(table,table);
	}
	QueryBuilder groupBy(string expression)
	{
		_groupby = expression;
		return this;
	}
	alias orderBy = addOrderBy;
	QueryBuilder addOrderBy(string key,string order)
	{
		_orderByKey = key;
		_order = order;
		return this;
	}
	alias offset = setFirstResult;
	QueryBuilder setFirstResult(int offset)
	{
		_offset = offset;
		return this;
	}
	alias limit = setMaxResults;
	QueryBuilder setMaxResults(int limit)
	{
		_limit = limit;
		return this;
	}
	QueryBuilder values(string[string] arr)
	{
		foreach(key,value;arr){
			auto expr = new QueryBuilderValueExpression(key,value);
			_values[key] = expr;
			if(value == "?")_valuesParameters ~= expr;
		}
		return this;
	}
	alias set = setValue;
	QueryBuilder setValue(string key,string value)
	{
		auto expr = new QueryBuilderValueExpression(key,value);
		_values[key] = expr;
		if(value == "?")_valuesParameters ~= expr;
		return this;
	}
	QueryBuilder setParameter(int index,string value )
	{
		if(_whereKeysParameters.length){
			if(index > _whereKeysParameters.length - 1)throw new EntityException("query builder setParameter range valite");
			_whereKeysParameters[index].value = value;
		}else{
			if(index > _valuesParameters.length - 1)throw new EntityException("query builder setParameter range valite");
			_valuesParameters[index].value = value;
		}
		return this;
	}
}
