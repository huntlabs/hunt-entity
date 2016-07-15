# entity
Database for dlang

# example
```
import std.stdio;

import entity;

@table("users")
struct User
{
	@primarykey()
	int id;

	@column("floatcol")
	float fcol;

	@column("doublecol")
	double dcol;

	@column("datecol")
	Date date;

	@column("datetimecol")
	DateTime dt;

	@column("timecol")
	Time time;

	@column()
	string stringcol;

	@column()
	ubyte[] ubytecol;
}

void main()
{
	enum str = getSetValueFun!(User)();
	writeln(str);

	enum ley = buildKeyValue!(User)();
	writeln(ley);

	//DataBase dt = DataBase.create("mysql://127.0.0.1/test");
	DataBase dt = DataBase.create("postgres://127.0.0.1/test?username=postgres&password=");
	dt.connect();

	Query!User quer = new Query!User(dt);

	User tmp;
	tmp.id = 3;
	tmp.fcol = 3.5;
	tmp.dcol = 526.58;
	tmp.date = Date(2016,07,12);
	tmp.dt = DateTime(2016,12,15,15,30,20);
	tmp.time = Time(12,10,23,256);
	tmp.stringcol = "hello world33";
	tmp.ubytecol = cast(ubyte[])"hellllo33".dup;

	//quer.Insert(tmp);

	auto iter = quer.Select();
	if(iter !is null)
		while(!iter.empty)
		{
			Test tp = iter.front();
			iter.popFront();
			writeln("float is  : ", tp.fcol);
			writeln("the string is : ", tp.stringcol);
			writeln("the ubyte is : ", cast(string)tp.ubytecol);
		}
}
```
	"libs" : ["mysqlclient","pq","pgtypes","sqlite3"],
	"versions" : ["USE_MYSQL", "USE_PGSQL", "USE_SQLITE"],
