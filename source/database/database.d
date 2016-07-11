module database.database;

public import std.database.front;

public import std.typecons;
public import std.datetime;

abstract class DataBase
{
	void connect(string url);
	void connect();

	Statement statement(string sql);

	Statement query(string sql);

}

abstract class Statement
{
	@property string sql();
	Statement query();

	bool hasRows();

	RowSet rows();
	ColumnSet columns();
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
