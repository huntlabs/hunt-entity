module database.muitlquery;

import std.typetuple;
import std.typecons;

import database.database;
import database.query;

class MuitlQuery(T,V) if(is(T == class) || is(T == struct) || is(V == class) || is(V == struct))
{
	alias Iterator = MuitlQueryIterator!(T,V);
	alias TQuery = Query!(T);
	alias VQuery = Query!(V);

	this(DataBase db)
	{
		_db = db;
		_tq = new TQuery(db);
		_vq = new VQuery(db);
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
		_tq.Insert!table(v);
	}
	
	void Update(string table = "")(ref T v)
	{
		_tq.Update!table(v);
	}
	
	void Update(string table = "")(ref T v, string where)
	{
		_tq.Update!table(v,where);
	}
	
	void Update(string table = "")(ref T v, WhereBuilder where)
	{
		_tq.Update!table(v,where);
	}
	
	void Delete(string table = "")(ref T v)
	{
		_tq.Delete!table(v);
	}
	
	void Delete(string table = "")(ref T v, string where)
	{
		_tq.Delete!table(v,where);
	}
	
	void Delete(string table = "")(ref T v, WhereBuilder where)
	{
		_tq.Delete!table(v,where);
	}

	void Insert(string table = "")(ref V v)
	{
		_vq.Insert!table(v);
	}
	
	void Update(string table = "")(ref V v)
	{
		_vq.Update!table(v);
	}

	void Update(string table = "")(ref V v, string where)
	{
		_vq.Update!table(v,where);
	}
	
	void Update(string table = "")(ref V v, WhereBuilder where)
	{
		_vq.Update!table(v,where);
	}
	
	void Delete(string table = "")(ref V v)
	{
		_vq.Delete!table(v);
	}
	
	void Delete(string table = "")(ref V v, string where)
	{
		_vq.Delete!table(v,where);
	}
	
	void Delete(string table = "")(ref T v, WhereBuilder where)
	{
		_vq.Delete!table(v,where);
	}

private:
	TQuery _tq;
	VQuery _vq;
	DataBase _db;
}


class MuitlQueryIterator(T,V) if(is(T == class) || is(T == struct) || is(V == class) || is(V == struct))
{
	alias TQuery = Query!(T);
	alias VQuery = Query!(V);
	alias TVuple = Tuple!(T,V);

	@property bool empty()
	{
		if(_set is null) return true;
		else return _set.empty();
	}
	
	@property TVuple front()
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

		static if(is(V == class))
		{
			V vvalue = new V();
		}
		else
		{
			V vvalue;
		}

		auto row = _set.front();
		int width = row.width();
		foreach(i; 0..width)
		{
			auto vt = row[i];
			if(!TQuery.setTValue(tvalue,vt))
				VQuery.setTValue(vvalue,vt);
		}
		TVuple rvalue;
		rvalue[0] = tvalue;
		rvalue[1] = vvalue;
		return rvalue;
	}
	
	void popFront()
	{
		if(_set)
			_set.popFront();
	}

	int opApply(int delegate(T, V) operations)
	{
		int result = 0;
		int num = 0;
		while(!empty)
		{
			TVuple value = front();
			result = operations(value[0],value[1]);
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
