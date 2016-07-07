module database.dbdrive.impl;

import std.algorithm.mutation;

import database.database;

import std.database.front;


class DataBaseImpl(DB) : DataBase
{
	alias Connection = DB.Connection;
	alias Cell = DB.Connection;
	alias TStatement = BasicStatement!(DB.Driver,DB.Policy);

	this()
	{
		_db = DB.create();
	}
	
	this(string url)
	{
		_db = DB.create(url);
	}
	
	override void connect(string url) 
	{
		_con = _db.connection(url);
	}

	
	override void connect() 
	{
		_con = _db.connection();
	}

	override Statement statement(string sql)
	{
		return new StatementImpl!(DB)(_con.statement(sql));
	}
	
	override Statement query(string sql)
	{
		return new StatementImpl!(DB)(_con.query(sql));
	}


private:
	DB _db = void;
	Connection _con = void;
}


class StatementImpl(DB) : Statement
{
	alias TStatement = BasicStatement!(DB.Driver,DB.Policy);
	alias TRowSet = TStatement.RowSet;
	alias TColumnSet = TStatement.ColumnSet;

	this(TStatement stem)
	{
		_statement = move(stem);
	}

	override @property string sql()
	{
		return _statement.sql();
	}

	override Statement query()
	{
		_statement.query();
		return this;
	}
	
	override bool hasRows()
	{
		return _statement.hasRows();
	}

	override RowSet rows()
	{
		return new RowSetImpl!(DB)(_statement.rows());
	}

	override ColumnSet columns()
	{
		return new ColumnSetImpl!(DB)(_statement.columns());
	}

private:
	TStatement _statement = void;
}


class RowSetImpl(DB) : RowSet
{
	alias TRowSet = BasicRowSet!(DB.Driver,DB.Policy);
	alias TColumnSet = TRowSet.ColumnSet;
	alias TResult = TRowSet.Result;
	alias TRow = TRowSet.Row;

	this(TRowSet rset)
	{
		_rset = move(rset);
	}


	override int width()
	{
		return cast(int)_rset.width();
	}
	
	override ColumnSet columns()
	{
		return new ColumnSetImpl!(DB)(_rset.columns());
	}
	
	override bool empty()
	{
		return _rset.empty();
	}
	
	override Row front()
	{
		return new RowImpl!(DB)(_rset.front());
	}
	
	override void popFront()
	{
		_rset.popFront();
	}

private:
	TRowSet _rset = void;
}

class RowImpl(DB) : Row
{
	alias TRow = BasicRow!(DB.Driver,DB.Policy);
	alias TCell = TRow.Cell;
	alias TValue = TRow.Value;
	alias TColumn = TRow.Column;

	this(TRow row)
	{
		_row = move(row);
	}

	override int width()
	{
		return _row.width();
	}

	override CellValue opDispatch(string s)()
	{
		return new CellValueImpl!(DB)(_row.opDispatch!(s)());
	}
	
	override CellValue opIndex(size_t idx)
	{
		return new CellValueImpl!(DB)(_row[idx]);
	}

private:
	TRow _row = void;
}


class ColumnSetImpl(DB) : ColumnSet
{
	alias TColumnSet = BasicColumnSet!(DB.Driver,DB.Policy);
	alias TResult = TColumnSet.Result;
	alias TColumn = TColumnSet.Column;
	alias TRange = TColumnSet.Range;

	this(TColumnSet set)
	{
		_cset = move(set);
		_range = _cset[];
	}

	override int width()
	{
		return _cset.width();
	}
	
	override bool empty()
	{
		return _range.empty();
	}
	
	override Column front()
	{
		return new ColumnImpl!(DB)(_range.front());
	}
	
	override void popFront()
	{
		return _range.popFront();
	}

private:
	TColumnSet _cset = void;
	TRange _range = void;
}

class ColumnImpl(DB) : Column
{
	alias TColumn = BasicColumn!(DB.Driver,DB.Policy);

	this(TColumn col)
	{
		_column = move(col);
	}

	override size_t idx()
	{
		return _column.idx();
	}

	override string name()
	{
		return _column.name();
	}

private:
	TColumn _column = void;
}

class CellValueImpl(DB) : CellValue
{
	alias TValue = BasicValue!(DB.Driver,DB.Policy);
	alias TCell = TValue.Cell;
	this(TValue value)
	{
		_value = move(value);
		_cell = _value.cell();
	}

	override size_t rowIdx()
	{
		return _cell.rowIdx();
	}

	override size_t columnIdx()
	{
		return _cell.columnIdx();
	}

	override string name()
	{
		return _value.name();
	}

	override bool isNull()
	{
		return _value.isNull();
	}
	
	override ubyte[] rawData()
	{
		return _value.rawData();
	}

	override int dbType()
	{
		return cast(int)_value.dbType();
	}
	
	override ValueType type()
	{
		return _value.type();
	}

	override Variant value()
	{
		return _value.value();
	}
	
	override int asInt()
	{
		return _value.as!int();
	}
	
	override char asChar()
	{
		return _value.as!char();
	}
	
	override short asShort()
	{
		return _value.as!short();
	}
	
	override long asLong()
	{
		return _value.as!long();
	}
	
	override float asFloat()
	{
		return _value.as!float();
	}
	
	override double asDouble()
	{
		return _value.as!double();
	}
	
	override string asString()
	{
		return _value.as!string();
	}
	
	override Date asDate()
	{
		return _value.as!Date();
	}
	
	override DateTime asDateTime()
	{
		return _value.as!DateTime();
	}
	
	override Time asTime()
	{
		return _value.as!Time();
	}
	
	override ubyte[] asRaw()
	{
		return _value.as!(ubyte[])();
	}

private:
	TValue _value = void;
	TCell _cell = void;
}
