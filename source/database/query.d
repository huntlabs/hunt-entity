module database.query;

import std.traits;
import database.database;
import database.querybuilder;

struct Table
{
	string name;
}

enum Primarykey = 1;
enum NotInDB = 2;

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
	{}

	Iterator Select(string sql)
	{}

	static void Insert(string table = "")(ref T v)
	{}

	static void Update(string table = "")(ref T v, string where = null)
	{}

	static void Delete(string table = "")(ref T v, string where = null)
	{}

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
string getSetValueFun(T)()
{
	enum tname  = TtableName!T;
	enum hasTable = hasUDA!(T,Table);
	string keyW = "\nstatic string keyWhile(ref T tv){\n\tstring str;\n";
	bool hasKey = false;
	string str = "\nstatic bool setTValue(ref T tv, CellValue value) { \n";
	str ~= "\tswitch(value.name()){\n";
	foreach(memberName; __traits(derivedMembers,T))
	{
		static if (TisSupport!(typeof(__traits(getMember,T, memberName))) && TisPublic!(__traits(getMember,T, memberName)) && !hasUDA!(__traits(getMember,T, memberName),NotInDB))
		{
			str ~= TcreaterCase!(typeof(__traits(getMember,T, memberName)).stringof,memberName,typeof(__traits(getMember,T, memberName)),tname,hasTable);
		}
		static if(hasUDA!(__traits(getMember,T, memberName),Primarykey))
		{
			if(hasKey)
				keyW ~= "\tstr ~= \"and\"; \n";
			keyW = keyW ~ "\tstr = str ~ \"" ~ memberName ~ " = \" ~ toSqlString(tv." ~ memberName ~ ");\n";
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
		if(v = T.nan)
				str = "0.0";
		else
			str = to!string(v);
		return str;
	}
	else static if(is(T == Date) || is(T == DateTime))
	{
		return "'" ~ v.toISOExtString() ~ "'";
	}
	else static if(is(T == Time))
	{
		return "'" ~ v.toString() ~ "'";
	}
	else static if(is(T== char))
	{
		char[1] tv;
		tv[0] = v;
		return "'" ~ tv.idup ~ "'";
	}
	else
	{
		return "'" ~ cast(string)v ~ "'";
	}
}

template TcreaterCase(string type,string memberName, T,string tname = "", bool hasTable = false)
{
	enum str = "\tcase \"" ~ memberName ~ "\" : \n";
	enum va = "\t\t{\n\t\t\t" ~ "Nullable!" ~ type ~ " v = value.get" ~ TtypeName!(T) ~ "();"
		~ "\n\t\t\tif(!v.isNull()) tv." ~ memberName ~ " = v.get!" ~ type ~ "();" ~ "\n\t\t} \n\t\treturn true;\n";
	static if(hasTable)
	{

		enum TcreaterCase = str ~ "\tcase \"" ~ tname ~ "." ~memberName ~ "\" : \n " ~ va;
	}
	else
	{
		enum TcreaterCase = str ~ va;
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