import std.stdio;

import std.traits;
import std.datetime;
import std.typecons;


//import std.database.front;
import ddbc;
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

@Entity
@Table("f_image_info")
struct FImageInfo
{
	@Primarykey(1)
	string hash;

	@Field("w",2)
	int widght;

	@Field("h",3)
	int hight;

	@Field("ext",4)
	string ext;
} 

void main()
{
	string conUrl = "mysql://10.1.11.31:3306/file_images?user=dev,password=111111";
	writeln("con url is  : ", conUrl);
	DateBase conn = createConnection(conUrl);
	scope(exit) conn.close();

	auto query =  conn.getQuery!FImageInfo();
	auto iter = query.Select("select * from f_image_info LIMIT 10");
	foreach(int i,FImageInfo info; iter){
		writeln("index : ", i, "   hash is : ", info.hash, " w = ", info.widght, "  h = ", info.hight, "  ext = ", info.ext);
	}

	FImageInfo tmp;
	tmp.hash = "tmp112asdawsrwaerewrewr222";
	tmp.widght = 1000;
	tmp.hight = 2005;
	tmp.ext = ".tmp";
	query.Insert(tmp);
	writeln("new select !!!!");
	iter = query.Select("select * from f_image_info where hash = 'tmp112asdawsrwaerewrewr222';");
	foreach(int i,FImageInfo info; iter){
		writeln("index : ", i, "   hash is : ", info.hash, " w = ", info.widght, "  h = ", info.hight, "  ext = ", info.ext);
	}
	query.Delete(tmp);
}
