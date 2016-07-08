import std.stdio;

import std.traits;
import std.datetime;
import std.typecons;

import database.database;
import database.dbdrive.mysql;
import database.dbdrive.impl;
import database.query;

@Table("name")
class AAA
{
@Primarykey int a;
	@Primarykey int b;
	string c;
	double d;

	Object obj;

	DateTime dt;
	@NotInDB
	ubyte[] aa;
}

struct Time
{
	int tm;
};

void main()
{
	writeln("Edit source/app.d to start your project.");

	static if(hasUDA!(AAA,Table))
	{
		writeln("name is  = ",getUDAs!(AAA, Table)[0].name);
	}
	writeln("over!!!");

	enum str = getSetValueFun!(AAA)();
	writeln(str);
	/*
	DataBase dt = new MyDataBase("mysql://127.0.0.1/test");
	dt.connect();
	dt.query("drop table if exists tuple");
	dt.query("create table tuple (a int, b int, c int)");
	string sql = "insert into tuple values(";

	foreach(i; 0..100)
	{
		import std.conv;
		string ts  = sql ~ to!string(i) ~ "," ~ to!string(i+1) ~ "," ~ to!string(i+2) ~ ")";
		dt.query(ts);
	}

	auto st = dt.query("select * from tuple");
	assert(st.hasRows());

	auto rows = st.rows();
	int i = 0;
	while(!rows.empty())
	{
		scope(exit){ ++i;rows.popFront();}
		auto row = rows.front();
		writeln("-----------new row : ", i, "----------");
		int w = row.width();
		foreach(t; 0..w)
		{
			//Nullable!
			auto value = row[t];
			writeln("type == ", value.type());
			Nullable!int v = value.getInt();
			if(v.isNull())
				writeln("is null");
			else
				writeln("v = ", v);
		}
	}*/
}
