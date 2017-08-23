module entity.dialect.mysqldialect;

import entity;

class MysqlDialect : Dialect
{
	string closeQuote() { return "\""; }
	string openQuote()  { return "\""; }
    Variant fromSqlValue(FieldInfo info)
	{
		if(typeid(info.fieldType) == typeid(dBoolType)){
			if(*info.fieldValue.peek!string == "1")
				return Variant(true);
			else
				return Variant(false);
		}else if(typeid(info.fieldType) == typeid(dFloatType))
			return Variant(to!float(*info.fieldValue.peek!string));
		else if(typeid(info.fieldType) == typeid(dDoubleType))
			return Variant(to!double(*info.fieldValue.peek!string));
		else if(typeid(info.fieldType) == typeid(dIntType))
			return Variant(to!int(*info.fieldValue.peek!string));
		else 
			return info.fieldValue;	
	}
    string toSqlValueImpl(DlangDataType type,Variant value)
	{
		if(typeid(type) == typeid(dBoolType))
				return value.get!(bool) ? "1" : "0";
		else if(typeid(type) == typeid(dCrealType) ||
			typeid(type) == typeid(dCdoubleType) ||
			typeid(type) == typeid(dCfloatType) ||  
			typeid(type) == typeid(dIrealType) || 
			typeid(type) == typeid(dIdoubleType) || 
			typeid(type) == typeid(dIfloatType) || 
			typeid(type) == typeid(dRealType) || 
			typeid(type) == typeid(dDoubleType) || 
			typeid(type) == typeid(dFloatType) || 
			typeid(type) == typeid(dUlongType) || 
			typeid(type) == typeid(dLongType) || 
			typeid(type) == typeid(dUintType) || 
			typeid(type) == typeid(dIntType) || 
			typeid(type) == typeid(dShortType) || 
			typeid(type) == typeid(dUshortType)) 
				return value.toString;
		else
			//typeid(type) ==typeid(dDharType)  
			//typeid(type) ==typeid(dWcharType) 
			//typeid(type) ==typeid(dCharType)  
			//typeid(type) ==typeid(dByteType)  
			//typeid(type) ==typeid(dUbyteType) 
			//default || 
			return openQuote ~ value.toString ~ closeQuote;
	}
}

string[] MYSQL_RESERVED_WORDS = 
[
	"ACCESSIBLE", "ADD", "ALL",
	"ALTER", "ANALYZE", "AND",
	"AS", "ASC", "ASENSITIVE",
	"BEFORE", "BETWEEN", "BIGINT",
	"BINARY", "BLOB", "BOTH",
	"BY", "CALL", "CASCADE",
	"CASE", "CHANGE", "CHAR",
	"CHARACTER", "CHECK", "COLLATE",
	"COLUMN", "CONDITION", "CONSTRAINT",
	"CONTINUE", "CONVERT", "CREATE",
	"CROSS", "CURRENT_DATE", "CURRENT_TIME",
	"CURRENT_TIMESTAMP", "CURRENT_USER", "CURSOR",
	"DATABASE", "DATABASES", "DAY_HOUR",
	"DAY_MICROSECOND", "DAY_MINUTE", "DAY_SECOND",
	"DEC", "DECIMAL", "DECLARE",
	"DEFAULT", "DELAYED", "DELETE",
	"DESC", "DESCRIBE", "DETERMINISTIC",
	"DISTINCT", "DISTINCTROW", "DIV",
	"DOUBLE", "DROP", "DUAL",
	"EACH", "ELSE", "ELSEIF",
	"ENCLOSED", "ESCAPED", "EXISTS",
	"EXIT", "EXPLAIN", "FALSE",
	"FETCH", "FLOAT", "FLOAT4",
	"FLOAT8", "FOR", "FORCE",
	"FOREIGN", "FROM", "FULLTEXT",
	"GET", "GRANT", "GROUP",
	"HAVING", "HIGH_PRIORITY", "HOUR_MICROSECOND",
	"HOUR_MINUTE", "HOUR_SECOND", "IF",
	"IGNORE", "IN", "INDEX",
	"INFILE", "INNER", "INOUT",
	"INSENSITIVE", "INSERT", "INT",
	"INT1", "INT2", "INT3",
	"INT4", "INT8", "INTEGER",
	"INTERVAL", "INTO", "IO_AFTER_GTIDS",
	"IO_BEFORE_GTIDS", "IS", "ITERATE",
	"JOIN", "KEY", "KEYS",
	"KILL", "LEADING", "LEAVE",
	"LEFT", "LIKE", "LIMIT",
	"LINEAR", "LINES", "LOAD",
	"LOCALTIME", "LOCALTIMESTAMP", "LOCK",
	"LONG", "LONGBLOB", "LONGTEXT",
	"LOOP", "LOW_PRIORITY", "MASTER_BIND",
	"MASTER_SSL_VERIFY_SERVER_CERT", "MATCH", "MAXVALUE",
	"MEDIUMBLOB", "MEDIUMINT", "MEDIUMTEXT",
	"MIDDLEINT", "MINUTE_MICROSECOND", "MINUTE_SECOND",
	"MOD", "MODIFIES", "NATURAL",
	"NOT", "NO_WRITE_TO_BINLOG", "NULL",
	"NUMERIC", "ON", "OPTIMIZE",
	"OPTION", "OPTIONALLY", "OR",
	"ORDER", "OUT", "OUTER",
	"OUTFILE", "PARTITION", "PRECISION",
	"PRIMARY", "PROCEDURE", "PURGE",
	"RANGE", "READ", "READS",
	"READ_WRITE", "REAL", "REFERENCES",
	"REGEXP", "RELEASE", "RENAME",
	"REPEAT", "REPLACE", "REQUIRE",
	"RESIGNAL", "RESTRICT", "RETURN",
	"REVOKE", "RIGHT", "RLIKE",
	"SCHEMA", "SCHEMAS", "SECOND_MICROSECOND",
	"SELECT", "SENSITIVE", "SEPARATOR",
	"SET", "SHOW", "SIGNAL",
	"SMALLINT", "SPATIAL", "SPECIFIC",
	"SQL", "SQLEXCEPTION", "SQLSTATE",
	"SQLWARNING", "SQL_BIG_RESULT", "SQL_CALC_FOUND_ROWS",
	"SQL_SMALL_RESULT", "SSL", "STARTING",
	"STRAIGHT_JOIN", "TABLE", "TERMINATED",
	"THEN", "TINYBLOB", "TINYINT",
	"TINYTEXT", "TO", "TRAILING",
	"TRIGGER", "TRUE", "UNDO",
	"UNION", "UNIQUE", "UNLOCK",
	"UNSIGNED", "UPDATE", "USAGE",
	"USE", "USING", "UTC_DATE",
	"UTC_TIME", "UTC_TIMESTAMP", "VALUES",
	"VARBINARY", "VARCHAR", "VARCHARACTER",
	"VARYING", "WHEN", "WHERE",
	"WHILE", "WITH", "WRITE",
	"XOR", "YEAR_MONTH", "ZEROFILL",
	"GET", "IO_AFTER_GTIDS", "IO_BEFORE_GTIDS",
	"MASTER_BIND", "ONE_SHOT", "PARTITION",
	"SQL_AFTER_GTIDS", "SQL_BEFORE_GTIDS",
];

