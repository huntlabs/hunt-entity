module entity.defined;

import entity;

//TableName
string Table(string name){return name;}

//Attribute
enum {
	Auto = 1001,
	AutoIncrement,
	PrimaryKey,
	NotNull,
}
//Relation
enum {
	None = 2001,
	Embedded,
	OneToOne,
	OneToMany,
	ManyToOne,
	ManyToMany,
}

enum MysqlField {
	//MysqlFieldAffinity Numeric Types
	BIT,
	TINYINT,
	BOOL,
	SMALLINT,
	MEDIUMINT,
	INT,
	INTEGER,
	BIGINT,
	SERIAL,
	DECIMAL,
	DEC,
	FLOAT,
	DOUBLE,
	//MysqlFieldAffinity Date/Time Types
	DATE,
	DATETIME,
	TIMESTAMP,
	TIME,
	YEAR,
	//MysqlFieldAffinity String Types
	BINARY,
	VARBINARY,
	TINYBLOB,
	TINYTEXT,
	BLOB,
	TEXT,
	MEDIUMBLOB,
	MEDIUMTEXT,
	LONGBLOB,
	LONGTEXT,
	ENUM,
	SET
}
enum PgsqlField {
	//PgsqlFieldAffinity Numeric Types
	SMALLINT,
	INTEGER,
	BIGINT,
	DECIMAL,
	NUMERIC,
	REAL,
	DOUBLE,
	SMALLSERIAL,
	SERIAL,
	BIGSERIAL,
	//PgsqlFieldAffinity Monetary Type
	MONEY,
	//PgsqlFieldAffinity Character Types
	CHARACTER,
	TEXT,
	//PgsqlFieldAffinity Binary Data Type
	BYTEA,
	//PgsqlFieldAffinity Date/Time Types
	TIMESTAMP,
	DATE,
	TIME,
	INTERVAL,
	//PgsqlFieldAffinity Boolean Type
	BOOLEAN,
	//PgsqlFieldAffinity Enumerated Type
	ENUM,
	//PgsqlFieldAffinity Geometric Types
	POINT,
	LINE,
	LSEG,
	BOX,
	PATH,
	POLYGON,
	CIRCLE,
	//PgsqlFieldAffinity Network Address Types
	CIDR,
	INET,
	MACADDR,
	//PgsqlFieldAffinity Bit String Type
	BIT,
	//PgsqlFieldAffinity Text Search Types
	TSVECTOR,
	TSQUERY,
	//PgsqlFieldAffinity UUID Type
	UUID,
	//PgsqlFieldAffinity XML Type
	XML,
	//PgsqlFieldAffinity JSON Type
	JSON,
	//PgsqlFieldAffinity Arrays Type
	ARRAYS,
	//OTHER
}

enum SqliteField {
	//SqliteFieldAffinity INTEGER Types
	INT,
	INTEGER,
	TINYINT,
	SMALLINT,
	MEDIUMINT,
	BIGINT,
	UNSIGNEDBIGINT,
	INT2,
	INT8,
	//SqliteFieldAffinity Text Types
	CHARACTER,
	VARCHAR,
	NCHAR,
	NVARCHAR,
	TEXT,
	CLOB,
	//SqliteFieldAffinity Blob Type
	BLOB,
	//SqliteFieldAffinity REAL Type
	REAL,
	DOUBLE,
	FLOAT,
	//SqliteFieldAffinity Numeric Types
	NUMERIC,
	DECIMAL,
	BOOLEAN,
	DATE,
	DATETIME,
}

enum MysqlFieldAffinity {
	Numeric,
	DateTime,
	String,
	JSON,
}
enum PgsqlFieldAffinity {
	Numeric,
	Monetary,
	Character,
	BinaryData,
	DateTime,
	Boolean,
	Enumerated,
	Geometric,
	NetworkAddress ,
	BitString,
	TextSearch,
	UUID,
	XML,
	JSON,
	Arrays,
	Composite,
	Range,
	ObjectIdentifier,
	pg_lsn,
	Pseudos
}
enum SqliteFieldAffinity {
	TEXT,
	NUMERIC,
	INTEGER,
	REAL,
	BLOB,
}


class EntityFieldType{}

class String : EntityFieldType {

}

class Text : EntityFieldType {

}

class Integer : EntityFieldType {

}

class Real : EntityFieldType {

}

class Blob : EntityFieldType {

}

class Numeric : EntityFieldType {

}

class Monetary : EntityFieldType {

}

class Character : EntityFieldType {

}

class BinaryData : EntityFieldType {

}

class DataTime : EntityFieldType {

}

class Boolean : EntityFieldType {

}

class Enumerated : EntityFieldType {

}

class Geometric : EntityFieldType {

}

class NetworkAddress : EntityFieldType {

}

class BitString : EntityFieldType {

}

class TextSearch : EntityFieldType {

}

class UUID : EntityFieldType {

}

class XML : EntityFieldType {

}

class JSON : EntityFieldType {

}

class Array : EntityFieldType {

}

class Composite : EntityFieldType {

}

class Range : EntityFieldType {

}

class ObjectIdentifier : EntityFieldType {

}

class Pglsn : EntityFieldType {

}

class Pseudeo : EntityFieldType {

}


class DlangDataType {
	string getName(){return "void";}
}

class dBoolType : DlangDataType {
	override string getName(){return "bool";}
}
class dByteType : DlangDataType {
	override string getName(){return "byte";}
}
class dUbyteType : DlangDataType {
	override string getName(){return "ubyte";}
}
class dShortType : DlangDataType {
	override string getName(){return "short";}
}
class dUshortType : DlangDataType {
	override string getName(){return "ushort";}
}
class dIntType : DlangDataType {
	override string getName(){return "int";}
}
class dUintType : DlangDataType {
	override string getName(){return "uint";}
}
class dLongType : DlangDataType {
	override string getName(){return "long";}
}
class dUlongType : DlangDataType {
	override string getName(){return "ulong";}
}
class dFloatType : DlangDataType {
	override string getName(){return "float";}
}
class dDoubleType : DlangDataType {
	override string getName(){return "double";}
}
class dRealType : DlangDataType {
	override string getName(){return "real";}
}
class dIfloatType : DlangDataType {
	override string getName(){return "ifloat";}
}
class dIdoubleType : DlangDataType {
	override string getName(){return "idouble";}
}
class dIrealType : DlangDataType {
	override string getName(){return "ireal";}
}
class dCfloatType : DlangDataType {
	override string getName(){return "cfloat";}
}
class dCdoubleType : DlangDataType {
	override string getName(){return "cdouble";}
}
class dCrealType : DlangDataType {
	override string getName(){return "creal";}
}
class dCharType : DlangDataType {
	override string getName(){return "char";}
}
class dWcharType : DlangDataType {
	override string getName(){return "wchar";}
}
class dDcharType : DlangDataType {
	override string getName(){return "dchar";}
}
class dEnumType : DlangDataType {
	override string getName(){return "enum";}
}
class dStructType : DlangDataType {
	override string getName(){return "struct";}
}
class dUnionType : DlangDataType {
	override string getName(){return "union";}
}
class dClassType : DlangDataType {
	override string getName(){return "class";}
}
class dStringType : DlangDataType {
	override string getName(){return "string";}
}
class dJsonType : DlangDataType {
	override string getName(){return "json";}
}
class dDateType : DlangDataType {
	override string getName(){return "date";}
}
class dTimeType : DlangDataType {
	override string getName(){return "time";}
}


DlangDataType getDlangDataType(T)(T val)
{
	static if(is(T == int))
		 return new dIntType();
	else static if(is(T == bool))
		 return new dBoolType();
	else static if(is(T == byte))
		 return new dByteType();
	else static if(is(T == ubyte))
		 return new dUbyteType();
	else static if(is(T == short))
		 return new dShortType();
	else static if(is(T == ushort))
		 return new dUshortType();
	else static if(is(T == uint))
		 return new dUintType();
	else static if(is(T == long))
		 return new dLongType();
	else static if(is(T == float))
		 return new dFloatType();
	else static if(is(T == double))
		 return new dDoubleType();
	else static if(is(T == real))
		 return new dRealType();
	else static if(is(T == ifloat))
		 return new dIfloatType();
	else static if(is(T == idouble))
		 return new dIdoubleType();
	else static if(is(T == ireal))
		 return new dIrealType();
	else static if(is(T == cfloat))
		 return new dCfloatType();
	else static if(is(T == cdouble))
		 return new dCdoubleType();
	else static if(is(T == creal))
		 return new dCrealType();
	else static if(is(T == char))
		 return new dCharType();
	else static if(is(T == wchar))
		 return new dWcharType();
	else static if(is(T == dchar))
		 return new dCharType();
	else static if(is(T == enum))
		 return new dEnumType();
	else static if(is(T == JSONValue))
		 return new dJsonType();
	else static if(is(T == SysTime))
		 return new dTimeType();
	else static if(is(T == DateTime))
		 return new dDateType();
	else 
		 return new dStringType();
}
string getDlangDataTypeStr(T)()
{
	static if(is(T == int))
		return "dIntType";
	else static if(is(T == bool))
		return "dBoolType";
	else static if(is(T == byte))
		return "dByteType";
	else static if(is(T == ubyte))
		return "dUbyteType";
	else static if(is(T == short))
		return "dShortType";
	else static if(is(T == ushort))
		return "dUshortType";
	else static if(is(T == uint))
		return "dUintType";
	else static if(is(T == long))
		return "dLongType";
	else static if(is(T == float))
		return "dFloatType";
	else static if(is(T == double))
		return "dDoubleType";
	else static if(is(T == real))
		return "dRealType";
	else static if(is(T == ifloat))
		return "dIfloatType";
	else static if(is(T == idouble))
		return "dIdoubleType";
	else static if(is(T == ireal))
		return "dIrealType";
	else static if(is(T == cfloat))
		return "dCfloatType";
	else static if(is(T == cdouble))
		return "dCdoubleType";
	else static if(is(T == creal))
		return "dCrealType";
	else static if(is(T == char))
		return "dCharType";
	else static if(is(T == wchar))
		return "dWcharType";
	else static if(is(T == dchar))
		return "dCharType";
	else static if(is(T == enum))
		return "dEnumType";
	else static if(is(T == JSONValue))
		return "dJsonType";
	else static if(is(T == SysTime))
		return "dTimeType";
	else static if(is(T == DateTime))
		return "dDateType";
	else 
		return "dStringType";
}
string getDlangTypeStr(T)()
{
	static if(is(T == int))
		return "int";
	else static if(is(T == bool))
		return "bool";
	else static if(is(T == byte))
		return "byte";
	else static if(is(T == ubyte))
		return "ubyte";
	else static if(is(T == short))
		return "short";
	else static if(is(T == ushort))
		return "ushort";
	else static if(is(T == uint))
		return "uint";
	else static if(is(T == long))
		return "long";
	else static if(is(T == float))
		return "float";
	else static if(is(T == double))
		return "double";
	else static if(is(T == real))
		return "real";
	else static if(is(T == ifloat))
		return "ifloat";
	else static if(is(T == idouble))
		return "idouble";
	else static if(is(T == ireal))
		return "ireal";
	else static if(is(T == cfloat))
		return "cfloat";
	else static if(is(T == cdouble))
		return "cdouble";
	else static if(is(T == creal))
		return "creal";
	else static if(is(T == char))
		return "char";
	else static if(is(T == wchar))
		return "wchar";
	else static if(is(T == dchar))
		return "dchar";
	else static if(is(T == JSONValue))
		return "JSONValue";
	else 
		return "string";
}
