import std.stdio;

import std.traits;
import std.datetime;
import std.typecons;

import database.database;
import database.dbdrive.mysql;
import database.dbdrive.impl;
import database.query;

import database.querybuilder;
import std.database.front;

@table("tuple")
struct AAA
{
	@primarykey()
	int a;

	@primarykey()
	int b;

	@column()
	int c;
}

void main()
{
	enum str = getSetValueFun!(AAA)();
	writeln(str);

	enum ley = buildKeyValue!(AAA)();
	writeln(ley);


	DataBase dt = new MyDataBase("mysql://127.0.0.1/test");
	dt.connect();
	dt.query("drop table if exists tuple");
	dt.query("create table tuple (a int, b int, c int)");
	string sql = "insert into tuple values(";
	writeln("\ninsert\n\n\n");
	Query!AAA quer = new Query!AAA(dt);
	foreach(i; 0..100)
	{
		AAA a = AAA();
		a.a = i;
		a.b = i + 1;
		a.c = i + 2;
		quer.Insert(a);
	//	import std.conv;
	//	string ts  = sql ~ to!string(i) ~ "," ~ to!string(i+1) ~ "," ~ to!string(i+2) ~ ")";
	//	dt.query(ts);
	}
	writeln("select");
	auto iter = quer.Select();
	writeln("tuple data: \n a \t b \t c");
	AAA a;
	if(!iter.empty)
	{
		a = iter.front();
		iter.popFront();
		writeln(a.a,"\t",a.b,"\t",a.c);
	}
	while(!iter.empty)
	{
		auto ta = iter.front();
		iter.popFront();
		writeln(ta.a,"\t",ta.b,"\t",ta.c);
	}
	a.c = 1002;

	dt.query("SET SQL_SAFE_UPDATES = 0");
	quer.Update(a);
	a.a = 20;
	a.b = 21;
	quer.Delete(a);

	/*
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
