module entity.query;

import std.traits;
import std.experimental.logger;

import entity.database;
import entity.querybuilder;

struct Table
{
	string name;
}


struct Primarykey 
{
	string name;
}

struct Field 
{
	string name;
}

class Query(T) if(is(T == class) || is(T == struct))
{
	alias Iterator = QueryIterator!(T);

	this(DataBase db)
	{
		_tableName = TtableName!T;
		_db = db;
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
		Statement rusel = _db.query(sql);
		if(rusel.hasRows)
			return new Iterator(rusel.rows());
		else
			return null;
	}

	void Insert(string table = "")(ref T v)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");

		InsertBuilder build = new InsertBuilder();//scoped!(InsertBuilder)();//
		string[string] value;
		mixin(buildKeyValue!T());
		//import std.stdio;
		//writeln(value);
		build.into(etable);
		build.insert(value.keys);
		build.values(value.values);
		_db.query(build.build());
		build.destroy;
	}

	void Update(string table = "")(ref T v)
	{
		string where = keyWhile(v);
		if(where.length == 0)
		{
			throw new Exception("do not has Primarykey;");
		}
		Update!(table)(v,where);
	}

	void Update(string table = "")(ref T v, string where)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");
		
		UpdateBuilder build = new UpdateBuilder();
		string[string] value;
		mixin(buildKeyValue!T());
		build.update(etable).set(value);
		if(where.length > 0)
			build.where(where);
	//	string sql = "SET SQL_SAFE_UPDATES = 0;";
	//	sql ~= build.build();
	//	_db.query(sql);
		_db.query(build.build());
		build.destroy;
	}

	void Update(string table = "")(ref T v, WhereBuilder where)
	{
		Update!(table)(v,where.build());
	}

	void Delete(string table = "")(ref T v)
	{
		string where = keyWhile(v);
		if(where.length == 0)
		{
			throw new Exception(" do not has Primarykey;");
		}
		Delete!(table)(v,where);
	}

	void Delete(string table = "")(ref T v, string where)
	{
		string etable;
		static if(table.length > 0)
			etable = table;
		else
			etable = _tableName;
		if(etable.length == 0)
			throw new Exception("the table must not be empty;");
		
		DeleteBuilder build = new DeleteBuilder();

		build.from(etable);
		if(where.length > 0)
			build.where(where);
		_db.query(build.build());
		build.destroy;
	}
	
	void Delete(string table = "")(ref T v, WhereBuilder where)
	{
		Delete!(table)(v,where.build());
	}

protected:
	mixin(getSetValueFun!T());
private:
	string _tableName;
	DataBase _db;
}

class QueryIterator(T) if(is(T == class) || is(T == struct))
{
	alias TQuery = Query!(T);

	@property bool empty()
	{
		if(_set is null) return true;
		else return _set.empty();
	}

	@property T front()
	in{
		assert(!empty());
	}
	body{
		static if(is(T == class))
		{
			T tvalue = new T();
		}
		else
		{
			T tvalue;
		}
		auto row = _set.front();
		int width = row.width();
		foreach(i; 0..width)
		{
			TQuery.setTValue(tvalue,row[i]);
		}
		return tvalue;
	}

	void popFront()
	{
		if(_set)
			_set.popFront();
	}

	int opApply(int delegate(T) operations)
	{
		int result = 0;

		while(!empty)
		{
			result = operations(front());
			popFront();
		}

		return result;
	}
	
	int opApply(int delegate(int, T) operations)
	{
		int result = 0;
		int num = 0;
		while(!empty)
		{
			result = operations(num,front());
			popFront();
			++ num;
		}
		return result;
	}

private:
	this(RowSet set)
	{
		_set = set;
	}

	RowSet _set;
}



package:

string buildKeyValue(T)()
{
	string sql;
	foreach(memberName; __traits(derivedMembers,T))
	{
		static if (TisSupport!(typeof(__traits(getMember,T, memberName))) && TisPublic!(__traits(getMember,T, memberName)) && 
			(hasUDA!(__traits(getMember,T, memberName),Primarykey) || hasUDA!(__traits(getMember,T, memberName),Field) ))
		{
			sql ~= "\tvalue[\"" ~ columnName!(__traits(getMember,T, memberName),memberName) ~ "\"] = toSqlString(v." ~ memberName ~ ");\n";
		}
	}
	return sql;
}

string getSetValueFun(T)()
{
	enum tname  = TtableName!T;
	enum hasTable = hasUDA!(T,Table);
	string keyW = "\nstatic string keyWhile(ref T tv){\n\tstring str;\n";
	bool hasKey = false;
	string str = "\nstatic bool setTValue(ref T tv, CellValue value) { \n";
	str ~= "\t trace(\"value.name() is \", value.name(), \"  type is : \", value.type());";
	str ~= "\tswitch(value.name()){\n";
	foreach(memberName; __traits(derivedMembers,T))
	{
		//生成case 赋值函数
		static if (TisSupport!(typeof(__traits(getMember,T, memberName))) && TisPublic!(__traits(getMember,T, memberName)) && 
			(hasUDA!(__traits(getMember,T, memberName),Primarykey) || hasUDA!(__traits(getMember,T, memberName),Field) ))
		{
			static if(hasUDA!(__traits(getMember,T, memberName),Primarykey))
			{
				enum list = getUDAs!(__traits(getMember,T, memberName), Primarykey);
			}
			else
			{
				enum list = getUDAs!(__traits(getMember,T, memberName), Field);
			}
			string tstr ;//= "\tcase \"" ~ memberName ~ "\" : \n";
			string va = "\t\t{\n\t\t\t" ~ "Nullable!(" ~ typeof(__traits(getMember,T, memberName)).stringof ~ ") v = value.get" ~ TtypeName!(typeof(__traits(getMember,T, memberName))) ~ "();"
				~ "\n\t\t\tif(!v.isNull()) tv." ~ memberName ~ " = v.get();" ~ "\n\t\t} \n\t\treturn true;\n";
				foreach(col; list)
				{
					string stname = tColumnName(col.name,memberName);
					tstr ~= "\tcase \"" ~ stname ~ "\" : \n";
					static if(hasTable)
						tstr ~= "\tcase \"" ~ tname ~ "." ~ stname ~ "\" : \n ";
				}
			str ~= tstr;
			str ~= va;
		}
		// 生成主键的where函数
		static if(hasUDA!(__traits(getMember,T, memberName),Primarykey))
		{
			string name = columnName!(__traits(getMember,T, memberName),memberName);
			if(hasKey)
				keyW ~= "\tstr ~= \" and \"; \n";
			keyW = keyW ~ "\tstr = str ~ \"" ~ name ~ " = '\" ~ toSqlString(tv." ~ memberName ~ ") ~ \"'\" ;\n";
			hasKey = true;
		}
	}
	str ~= "\tdefault : \n\t\treturn false;\n\t}\n}\n";
	keyW ~= "\treturn str;\n}\n";
	str ~= keyW;

	return str;
}

string toSqlString(T)(T v) if(TisSupport!T)
{
	import std.conv;
	static if(is(T == int) || is(T == short)  || is(T == long)){
		return  to!string(v) ;
	}
	else static if(is(T == float) || is(T == double))
	{
		string str;
		if(v == T.nan)
				str = "0.0";
		else
			str = to!string(v);
		return str;
	}
	else static if(is(T == Date) || is(T == DateTime))
	{
		return v.toISOExtString() ;
	}
	else static if(is(T == Time))
	{
		return  v.toString() ;
	}
	else static if(is(T== char))
	{
		char[1] tv;
		tv[0] = v;
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
	static if(is(T == int))
		enum TtypeName = "Int";
	else static if(is(T == char))
		enum TtypeName = "Char";
	else static if(is(T == short))
		enum TtypeName = "Short";
	else static if(is(T == long))
		enum TtypeName = "Long";
	else static if(is(T == float))
		enum TtypeName = "Float";
	else static if(is(T == double))
		enum TtypeName = "Double";
	else static if(is(T == Time))
		enum TtypeName = "Time";
	else static if(is(T == Date))
		enum TtypeName = "Date";
	else static if(is(T == DateTime))
		enum TtypeName = "DateTime";
	else static if(is(T == string))
		enum TtypeName = "String";
	else static if(is(T == ubyte[]))
		enum TtypeName = "Raw";
	else
		enum TtypeName = "";		
}

template TisSupport(T)
{
	enum TisSupport = is(T == Date) || is(T == DateTime) || is(T == string) || is(T == ubyte[]) || is(T == char) || 
		is(T == int) || is(T == short) || is(T == float) || is(T == double) || is(T == long)  || is(T == Time);
}

template TtoType(T)
{
	enum type  = "value.as!(" ~ T.stringof ~ ")()";//T.stringof;
	static if(isArray!(T))
	{
		enum TtoType = type ~ ".dup";
	}
	else
	{
		enum TtoType = type;
	}
}

template TisPublic(alias T)
{
	enum protection =  __traits(getProtection,T);
	enum TisPublic = (protection == "public");
}


version(unittest)
{
	@Table("name")
	class AAA
	{
		@Primarykey int a;
		@Primarykey int b;
		string c;
		double d;
		
		Object obj;
		
		DateTime dt;
		ubyte[] aa;
	}
}

unittest
{
	static if(hasUDA!(AAA,table))
	{
		writeln("name is  = ",getUDAs!(AAA, table)[0].name);
	}
	writeln("over!!!");
	
	enum str = getSetValueFun!(AAA)();
	writeln(str);
	
	enum ley = buildKeyValue!(AAA)();
	writeln(ley);
}