module entity.query;

public import std.variant;
import std.traits;
import std.conv;
import std.array;
import std.experimental.logger;

import ddbc.core;
import entity.querybuilder;

enum Entity;

struct Table
{
	string name;
}


struct Primarykey 
{
	this(string n, int i = -1, bool a = false){
		name = n;
		index = i;
		autoIncr = a;
	}

	this(int i, bool a = false){
		index = i;
		autoIncr = a;
	}

	this(bool a){
		autoIncr = a;
	}

	string name;
	int index = -1;
	bool autoIncr = false;
}

struct Field 
{
	this(string n, int i = -1){
		name = n;
		index = i;
	}
	
	this(int i){
		index = i;
	}
	string name;
	int index = -1;
}

struct Query(T) if(isEntity!T)
{
	alias Iterator = QueryIterator!(T);

	this(Statement statement)
	{
		_tableName = TtableName!T;
		_statement = statement;
	}

	~this(){
		close();
		trace("Query ~ this()");
	}

	@property tableName(){return _tableName;}
	@property tableName(string table){_tableName = table;}

	Iterator Select(string table = "")()
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");
		string sql = "Select * from " ~ etable;
		return Select(sql);
	}

	Iterator Select(string sql)
	{
		ResultSet rusel = _statement.executeQuery(sql);
		return Iterator(rusel);
	}

	pragma(inline,true)
	int executeUpdate(string sql){
		return _statement.executeUpdate(sql);
	}

	int Insert(string table = "")(ref T v)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");

		scope InsertBuilder build = new InsertBuilder();//scoped!(InsertBuilder)();//
		string[string] value;
		mixin(buildKeyValue!T());
		//import std.stdio;
		//writeln(value);
		build.into(etable);
		build.insert(value.keys);
		build.values(value.values);
		return executeUpdate(build.build());
	}

	int Update(string table = "")(ref T v)
	{
		string where = keyWhile(v);
		if(where.length == 0)
		{
			throw new Exception("do not has Primarykey;");
		}
		return Update!(table)(v,where);
	}

	int Update(string table = "")(ref T v, string where)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");
		
		scope UpdateBuilder build = new UpdateBuilder();
		string[string] value;
		mixin(buildKeyValue!T());
		build.update(etable).set(value);
		if(where.length > 0)
			build.where(where);
	//	string sql = "SET SQL_SAFE_UPDATES = 0;";
	//	sql ~= build.build();
	//	_db.query(sql);
		return _statement.executeUpdate(build.build());
	}

	int Update(string table = "")(ref T v, WhereBuilder where)
	{
		return Update!(table)(v,where.build());
	}

	int Delete(string table = "")(ref T v)
	{
		string where = keyWhile(v);
		if(where.length == 0)
		{
			throw new Exception(" do not has Primarykey;");
		}
		return Delete!(table)(v,where);
	}

	int Delete(string table = "")(string where)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");
		scope DeleteBuilder build = new DeleteBuilder();
		build.from(etable);
		if(where.length > 0)
			build.where(where);
		return executeUpdate(build.build());
	}

	int Delete(string table = "")(ref T v, string where)
	{
		Appender!string str = appender!string;
		str.put("1 = 1");
		if(where.length > 0) {
			str.put(" and ");
			str.put(where);
		}
		where = keyWhile(v);
		if(where.length > 0){
			str.put(" and ");
			str.put(where);
		}
		return Delete!table(str.data);
	}
	
	int Delete(string table = "")(ref T v, WhereBuilder where)
	{
		return Delete!(table)(v,where.build());
	}

	void close(){
		if(_close){
			_set.close();
			_statement.close();
			_close = true;
		}
	}

protected:
	enum str = getSetValueFun!T();
	pragma(msg,str);
	mixin(getSetValueFun!T());
private:
	@disable this();
	string _tableName;
	Statement _statement;
	ResultSet _set;
	bool _close = false;
}

struct QueryIterator(T) if(isEntity!T)
{
	alias TQuery = Query!(T);

	~this(){
		clear();
	}

	bool next(){
		if(_set)
			return _set.next();
		return false;
	}

	T value(){
		static if(is(T == class))
			T tvalue = new T();
		else
			T tvalue;
		if(_set)
			TQuery.setTValue(tvalue,_set);
		return tvalue;
	}

	int opApply(scope int delegate(int,T) operations)
	{
		int result = 0;
		int num = 0;
		while(next())
		{
			result = operations(num,value());
			++ num;
		}
		return result;
	}
	
	int opApply(scope int delegate(T) operations)
	{
		int result = 0;
		while(next())
		{
			result = operations(value());
		}
		return result;
	}

	void clear()
	{
		_set = null;
	}

private:
	this(ResultSet set)
	{
		_set = set;
	}

	ResultSet _set;
}



package:

template isEntity(T)
{
	enum bool isEntity = (is(T == class) || is(T == struct)) && hasUDA!(T,Entity);
}

string buildKeyValue(T)()
{
	string sql;
	foreach(memberName; __traits(derivedMembers,T))
	{
		static if (TisPublic!(__traits(getMember,T, memberName)) && 
			(hasUDA!(__traits(getMember,T, memberName),Primarykey) || hasUDA!(__traits(getMember,T, memberName),Field) ))
		{
			static if(hasUDA!(__traits(getMember,T, memberName),Primarykey)) {
				enum Primarykey key = getUDAs!(__traits(getMember,T, memberName), Primarykey)[0];
				static if(!key.autoIncr)
					sql ~= "\tvalue[\"" ~ columnName!(__traits(getMember,T, memberName),memberName) ~ "\"] = toSqlString(v." ~ memberName ~ ");\n";
			} else {
				sql ~= "\tvalue[\"" ~ columnName!(__traits(getMember,T, memberName),memberName) ~ "\"] = toSqlString(v." ~ memberName ~ ");\n";
			}
		}
	}
	return sql;
}

string getSetValueFun(T)()
{
	enum tname  = TtableName!T;
	enum hasTable = hasUDA!(T,Table);
	string keyW = "\nstatic string keyWhile(ref T tv){\n\tstring str = string.init;\n";
	bool hasKey = false;
	string str = "\nstatic void setTValue(ref T tv, ResultSet result) { \n";
	foreach(memberName; __traits(derivedMembers,T))
	{
		//生成case 赋值函数
		static if (TisPublic!(__traits(getMember,T, memberName)) && 
			(hasUDA!(__traits(getMember,T, memberName),Primarykey) || hasUDA!(__traits(getMember,T, memberName),Field) ))
		{
			static if(hasUDA!(__traits(getMember,T, memberName),Primarykey))
			{
				enum Primarykey key = getUDAs!(__traits(getMember,T, memberName), Primarykey)[0];
				str ~= "\tsetValue(tv." ~ memberName ~ ", result , \""  ~ columnName!(__traits(getMember,T, memberName),memberName) ~ "\", " ~ to!string(key.index) ~ ");\n";
				// 生成主键的where函数
				string name = columnName!(__traits(getMember,T, memberName),memberName);
				if(hasKey)
					keyW ~= "\tstr ~= \" and \"; \n";
				keyW = keyW ~ "\tstr = str ~ \"" ~ name ~ " = '\" ~ toSqlString(tv." ~ memberName ~ ") ~ \"'\" ;\n";
				hasKey = true;
			}
			else
			{
				enum Field key = getUDAs!(__traits(getMember,T, memberName), Field)[0];
				str ~= "\tsetValue(tv." ~ memberName ~ ", result , \""  ~ columnName!(__traits(getMember,T, memberName),memberName) ~ "\", " ~ to!string(key.index) ~ ");\n";
			}
		}
	}
	str ~= "}\n";
	keyW ~= "\treturn str;\n}\n";
	str ~= keyW;

	return str;
}

string toSqlString(T)(T v)
{
	import std.datetime;

	static if(is(T == float) || is(T == double))
	{
		string str;
		if(v == T.nan)
			str = "0.0";
		else
			str = std.conv.to!string(v);
		return str;
	} else static if(isIntegral!T){
		return  std.conv.to!string(v) ;
	}
	else static if(is(T == Date) || is(T == DateTime))
	{
		return v.toISOExtString() ;
	}
	else static if(is(T== char) || is(T== byte) || is(T== ubyte))
	{
		char[1] tv;
		tv[0] = cast(char)v;
		return tv.idup;
	}
	else
	{
		return  cast(string)v;
	}
}

template columnName(alias T,string mname)
{
	static if(hasUDA!(T,Primarykey))
	{
		enum columnName = tColumnName(getUDAs!(T, Primarykey)[0].name,mname);
	}
	else
	{
		enum columnName = tColumnName(getUDAs!(T, Field)[0].name,mname);
	} 
}

template TtableName(T)
{
	static if(hasUDA!(T,Table))
	{
		enum TtableName = getUDAs!(T, Table)[0].name;
	}
	else
	{
		enum TtableName = "";
	}

}

string tColumnName(string column, string name)
{
	if(column.length == 0)
		return name;
	else
		return column;
}

template TtypeName(T)
{
	static if(is(T == bool))
		enum TtypeName = "Boolean";
	else static if(is(T == int))
		enum TtypeName = "Int";
	else static if(is(T == uint))
		enum TtypeName = "UInt";
	else static if(is(T == ubyte))
		enum TtypeName = "Ubyte";
	else static if(is(T == byte))
		enum TtypeName = "Byte";
	else static if(is(T == ushort))
		enum TtypeName = "Ushort";
	else static if(is(T == ulong))
		enum TtypeName = "Ulong";
	else static if(is(T == short))
		enum TtypeName = "Short";
	else static if(is(T == long))
		enum TtypeName = "Long";
	else static if(is(T == float))
		enum TtypeName = "Float";
	else static if(is(T == double))
		enum TtypeName = "Double";
	else static if(is(T == string))
		enum TtypeName = "String";
	else static if(is(T == ubyte[]))
		enum TtypeName = "Ubytes";
	else
		enum TtypeName = "Variant";		
}

template TisPublic(alias T)
{
	enum protection =  __traits(getProtection,T);
	enum TisPublic = (protection == "public");
}

void setValue(T)(ref T v, ResultSet result,string name, int index){
	if(index < 0){
		index = result.findColumn(name);
	}
	mixin("v = result.get" ~ TtypeName!T ~ "(index);");
}