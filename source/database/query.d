module database.query;

import std.traits;
import database.database;

struct Table
{
	string name;
}

enum Primarykey = 1;
enum NotInDB = 2;

class Query(T)
{
	this()
	{
		_tableName = tableName!T;
	}

private:
	string _tableName;
}

string getSetValueFun(T)()
{
	enum tname  = tableName!T;
	enum hasTable = hasUDA!(T,Table);
	string str = "";
	foreach(memberName; __traits(derivedMembers,typeof(aa)))
	{
		static if (isSupport!(typeof(__traits(getMember,  AAA, memberName))) && isPublic!(__traits(getMember,  AAA, memberName)) && !hasUDA!(T,NotInDB))
		{
			str ~= createrCase!(typeof(__traits(getMember,  AAA, memberName)).stringof,memberName,typeof(__traits(getMember,  AAA, memberName)),tname,hasTable);
		}
	}

	return str;
}

template createrCase(string type,string memberName, T,string tname = "", bool hasTable = false)
{
	enum str = "case \"" ~ memberName ~ "\" : \n {" ~ "Nullable!" ~ type ~ " v = value.get" ~ typeName!(T) ~ "();"
		~ "if(!v.isNull()) tv." ~ memberName ~ " = v.get!" ~ type ~ "();" ~ "} \n break;\n";
	static if(hasTable)
	{

		enum createrCase = str ~ "case \"" ~ tname ~ "." ~memberName ~ "\" : \n {" ~ "Nullable!" ~ type ~ " v = value.get" ~ typeName!(T) ~ "();"
			~ "if(!v.isNull()) tv." ~ memberName ~ " = v.get!" ~ type ~ "();" ~ "} \n break;\n";
	}
	else
	{
		enum createrCase = str;
	}
}

template createrCaseHasTable(string type,string memberName,string tname, T)
{
	enum createrCase = "case \"" ~ tname ~ "." ~memberName ~ "\" : \n {" ~ "Nullable!" ~ type ~ " v = value.get" ~ typeName!(T) ~ "();"
		~ "if(!v.isNull()) tv." ~ memberName ~ " = v.get!" ~ type ~ "();" ~ "} \n break;";
}

template tableName(T)
{
	static if(hasUDA!(T,Table))
	{
		enum tableName = getUDAs!(T, Table)[0].name;
	}
	else
	{
		enum tableName = "";
	}

}

template typeName(T)
{
	static if(T == int)
		enum typeName = "Int";
	else static if(T == char)
		enum typeName = "Char";
	else static if(T == short)
		enum typeName = "Short";
	else static if(T == long)
		enum typeName = "Long";
	else static if(T == float)
		enum typeName = "Float";
	else static if(T == double)
		enum typeName = "Double";
	else static if(T == Time)
		enum typeName = "Time";
	else static if(T == Date)
		enum typeName = "Date";
	else static if(T == DateTime)
		enum typeName = "DateTime";
	else static if(T == string)
		enum typeName = "String";
	else static if(T == ubyte[])
		enum typeName = "Raw";
	else
		enum typeName = "";		
}

template isSupport(T)
{
	enum isSupport = is(T == Date) || is(T == DateTime) || is(T == string) || is(T == ubyte[]) || is(T == char) || 
		is(T == int) || is(T == short) || is(T == float) || is(T == double) || is(T == long)  || is(T == Time);
}

template toType(T)
{
	enum type  = "value.as!(" ~ T.stringof ~ ")()";//T.stringof;
	static if(isArray!(T))
	{
		enum toType = type ~ ".dup";
	}
	else
	{
		enum toType = type;
	}
}

template isPublic(alias T)
{
	enum protection =  __traits(getProtection,T);
	enum isPublic = (protection == "public");
}