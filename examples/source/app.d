import std.stdio;

import std.traits;
import std.datetime;
import std.typecons;


//import std.database.front;
import entity;

/*
//pgsql
CREATE TABLE test2
(
  id integer NOT NULL,
  floatcol double precision,
  doublecol real,
  datecol date,
  datetimecol timestamp without time zone,
  timecol time without time zone,
  stringcol text,
  ubytecol text,
  CONSTRAINT kry PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE test2
  OWNER TO postgres;
*/

/*

*/

@TABLE("test2")
struct Test
{
	@PRIMARYKEY()
	int id;

	@COLUMN("floatcol")
	float fcol;

	@COLUMN("doublecol")
	double dcol;

	@COLUMN("datecol")
	Date date;

	@COLUMN("datetimecol")
	DateTime dt;

	@COLUMN("timecol")
	Time time;

	@COLUMN()
	string stringcol;

	@COLUMN()
	ubyte[] ubytecol;
} 

void main()
{

	//DataBase dt = DataBase.create("mysql://127.0.0.1/test");
	DataBase dt = DataBase.create("postgres://127.0.0.1/test?username=postgres&password=");
	dt.connect();

	Query!Test quer = new Query!Test(dt);

	Test tmp;
	tmp.id = 3;
	tmp.fcol = 3.5;
	tmp.dcol = 526.58;
	tmp.date = Date(2016,07,12);
	tmp.dt = DateTime(2016,12,15,15,30,20);
	tmp.time = Time(12,10,23,256);
	tmp.stringcol = "hello world33";
	tmp.ubytecol = cast(ubyte[])"hellllo33".dup;

	quer.Insert(tmp);

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

	tmp.stringcol = "hello hello";
	quer.Update(tmp);

	/*
	iter = quer.Select();
	
	while(!iter.empty)
	{
		Test tp = iter.front();
		iter.popFront();
		writeln("the string is : ", tp.stringcol);
	}*/

	//quer.Delete(tmp);
}
