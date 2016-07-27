module entity.database;

public import std.database.front;

public import std.typecons;
public import std.datetime;

abstract class DataBase
{
	void connect(string url);
	void connect();

	Statement statement(string sql);

	Statement query(string sql);

	static DataBase create(string url)
	{
		import std.database.uri;
		auto ul = toURI(url);
		switch(ul.protocol)
		{
		version(USE_MYSQL)
		{
			case "mysql" :
				{
					import entity.driver.mysql;
					return new MyDataBase(url);
				}
		}
		version(USE_PGSQL)
		{
			case "postgres" :
			{
				import entity.driver.pgsql;
				return new PGDataBase(url);
			}
		}
		version(USE_SQLITE)
		{
			case "path" :
			{
				import entity.driver.sqlite;
				return  new LiteDataBase(url);
			}
		}
		default:
			throw new Exception("protocol is not support!");
		}
	}
}

abstract class Statement
{
	@property string sql();
	Statement query();

	bool hasRows();

	RowSet rows();
	ColumnSet columns();

	void results();
}


abstract class RowSet
{
	int width();

	ColumnSet columns();

	bool empty();

	Row front();

	void popFront();
}

abstract class Row
{
	int width();

	CellValue opDispatch(string s)();

	CellValue opIndex(size_t idx);
}


abstract class ColumnSet
{
	int width();

	bool empty();
	
	Column front();
	
	void popFront();
}

abstract class Column
{
	size_t idx();
	string name();
}

abstract class CellValue
{
	size_t rowIdx();
	size_t columnIdx();
	string name();
	bool isNull();

	ubyte[] rawData();
	int dbType();

	ValueType type();

	Variant value();

	int asInt();
	final Nullable!int getInt()
	{
		try{
			return Nullable!int(asInt());
		}catch{
			return Nullable!int();
		}
	}
	
	char asChar();
	final Nullable!char getChar()
	{
		try{
			return Nullable!char(asChar());
		}catch{
			return Nullable!char();
		}
	}

	short asShort();
	short getShort()
	{
		try{
			return Nullable!short(asShort());
		}catch{
			return Nullable!short();
		}
	}

	long asLong();
	final Nullable!long getLong()
	{
		try{
			return Nullable!long(asLong());
		}catch{
			return Nullable!long();
		}
	}

	float asFloat();
	final Nullable!float getFloat()
	{
		try{
			return Nullable!float(asFloat());
		}catch{
			return Nullable!float();
		}
	}

	double asDouble();
	final Nullable!double getDouble()
	{
		try{
			return Nullable!double(asDouble());
		}catch{
			return Nullable!double();
		}
	}
	
	string asString();
	final Nullable!string getString()
	{
		try{
			return Nullable!string(asString());
		}catch{
			return Nullable!string();
		}
	}

	Date asDate();
	final Nullable!Date getDate()
	{
		try{
			return Nullable!Date(asDate());
		}catch{
			return Nullable!Date();
		}
	}

	DateTime asDateTime();
	final Nullable!DateTime getDateTime()
	{
		try{
			return Nullable!DateTime(asDateTime());
		}catch{
			return Nullable!DateTime();
		}
	}

	Time asTime();
	final Nullable!Time getTime()
	{
		try{
			return Nullable!Time(asTime());
		}catch{
			return Nullable!Time();
		}
	}

	ubyte[] asRaw();
	final Nullable!(ubyte[]) getRaw()
	{
		try{
			return Nullable!(ubyte[])(asRaw());
		}catch{
			return Nullable!(ubyte[])();
		}
	}

}

version(unittest)
{
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
}

unittest
{
	DataBase dt = DataBase.create("mysql://127.0.0.1/test");
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

}