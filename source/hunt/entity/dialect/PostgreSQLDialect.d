module hunt.entity.dialect.PostgreSQLDialect;

import hunt.entity.dialect.Dialect;
import hunt.database.query.Common;
import hunt.Exceptions;

import std.conv;
import std.format;
import std.variant;


class PostgreSQLDialect : Dialect
{
	// Database _db;
	// this(Database db)
	// {
	// 	_db = db;
	// }
	this() {

	}

	Variant fromSqlValue(DlangDataType type,Variant value)
	{
		if(typeid(type) == typeid(dBoolType)){
			if(*value.peek!string == "true")
				return Variant(true);
			else
				return Variant(false);
		}else if(typeid(type) == typeid(dFloatType))
			return Variant(safeConvert!(string,float)(*value.peek!string));
		else if(typeid(type) == typeid(dDoubleType))
			return Variant(safeConvert!(string,double)(*value.peek!string));
		else if(typeid(type) == typeid(dIntType))
			return Variant(safeConvert!(string,int)(*value.peek!string));
		else if(typeid(type) == typeid(dLongType))
			return Variant(safeConvert!(string,long)(*value.peek!string));
		else
			return value;
	}
	string toSqlValueImpl(DlangDataType type,Variant value)
	{
		if(typeid(type) == typeid(dBoolType))
			return value.get!(bool) ? "TRUE" : "FALSE";
		else if(typeid(type) == typeid(dFloatType))
			return safeConvert!(float,string)(*value.peek!float);
		else if(typeid(type) == typeid(dDoubleType))
			return safeConvert!(double,string)(*value.peek!double);
		else if(typeid(type) == typeid(dIntType))
			return value.toString;
		else {
			implementationMissing(false);
			return value.toString();
			// return _db.escapeLiteral(value.toString);
		}
	}
	string getColumnDefinition(ColumnDefinitionInfo info) {
		if (!(info.dType in DTypeToPropertyType))
			throw new Exception("unsupport type %d of %s".format(info.dType,info.name));
		SqlSingleTypeInfo sqlInfo = DTypeToSqlInfo[DTypeToPropertyType[info.dType]];

		string nullable = info.isNullable ? "" : " NOT NULL";
		string primaryKey = info.isId ? " PRIMARY KEY" : "";
		string autoIncrease;
		if (info.isAuto) {
			if (sqlInfo.sqlType == SqlType.SMALLINT || sqlInfo.sqlType == SqlType.TINYINT)
                autoIncrease = "SERIAL PRIMARY KEY";
            if (sqlInfo.sqlType == SqlType.INTEGER)
                autoIncrease = "SERIAL PRIMARY KEY";
			else 
            	autoIncrease = "BIGSERIAL PRIMARY KEY";
			return autoIncrease;
		}
		int len = info.len == 0 ? sqlInfo.len : info.len;
		string modifiers = nullable ~ primaryKey ~ autoIncrease;
		string lenmodifiers = "("~to!string(len > 0 ? len : 255)~")"~modifiers;
		switch (sqlInfo.sqlType) {
			case SqlType.BIGINT:
                return "BIGINT" ~ modifiers;
            case SqlType.BIT:
            case SqlType.BOOLEAN:
                return "BOOLEAN" ~ modifiers;
            case SqlType.INTEGER:
                return "INT" ~ modifiers;
            case SqlType.NUMERIC:
                return "INT" ~ modifiers;
            case SqlType.SMALLINT:
                return "SMALLINT" ~ modifiers;
            case SqlType.TINYINT:
                return "SMALLINT" ~ modifiers;
            case SqlType.FLOAT:
                return "FLOAT(24)" ~ modifiers;
            case SqlType.DOUBLE:
                return "FLOAT(53)" ~ modifiers;
            case SqlType.DECIMAL:
                return "REAL" ~ modifiers;
            case SqlType.DATE:
                return "DATE" ~ modifiers;
            case SqlType.DATETIME:
                return "TIMESTAMP" ~ modifiers;
            case SqlType.TIME:
                return "TIME" ~ modifiers;
            case SqlType.CHAR:
            case SqlType.CLOB:
            case SqlType.LONGNVARCHAR:
            case SqlType.LONGVARBINARY:
            case SqlType.LONGVARCHAR:
            case SqlType.NCHAR:
            case SqlType.NCLOB:
            case SqlType.VARBINARY:
            case SqlType.VARCHAR:
            case SqlType.NVARCHAR:
                return "TEXT" ~ modifiers;
            case SqlType.BLOB:
                return "BYTEA";
            default:
                return "TEXT";
		}
	}
}

string[] PGSQL_RESERVED_WORDS = [
"ABORT",
	"ACTION",
	"ADD",
	"AFTER",
	"ALL",
	"ALTER",
	"ANALYZE",
	"AND",
	"AS",
	"ASC",
	"ATTACH",
	"AUTOINCREMENT",
	"BEFORE",
	"BEGIN",
	"BETWEEN",
	"BY",
	"CASCADE",
	"CASE",
	"CAST",
	"CHECK",
	"COLLATE",
	"COLUMN",
	"COMMIT",
	"CONFLICT",
	"CONSTRAINT",
	"CREATE",
	"CROSS",
	"CURRENT_DATE",
	"CURRENT_TIME",
	"CURRENT_TIMESTAMP",
	"DATABASE",
	"DEFAULT",
	"DEFERRABLE",
	"DEFERRED",
	"DELETE",
	"DESC",
	"DETACH",
	"DISTINCT",
	"DROP",
	"EACH",
	"ELSE",
	"END",
	"ESCAPE",
	"EXCEPT",
	"EXCLUSIVE",
	"EXISTS",
	"EXPLAIN",
	"FAIL",
	"FOR",
	"FOREIGN",
	"FROM",
	"FULL",
	"GLOB",
	"GROUP",
	"HAVING",
	"IF",
	"IGNORE",
	"IMMEDIATE",
	"IN",
	"INDEX",
	"INDEXED",
	"INITIALLY",
	"INNER",
	"INSERT",
	"INSTEAD",
	"INTERSECT",
	"INTO",
	"IS",
	"ISNULL",
	"JOIN",
	"KEY",
	"LEFT",
	"LIKE",
	"LIMIT",
	"MATCH",
	"NATURAL",
	"NO",
	"NOT",
	"NOTNULL",
	"NULL",
	"OF",
	"OFFSET",
	"ON",
	"OR",
	"ORDER",
	"OUTER",
	"PLAN",
	"PRAGMA",
	"PRIMARY",
	"QUERY",
	"RAISE",
	"REFERENCES",
	"REGEXP",
	"REINDEX",
	"RELEASE",
	"RENAME",
	"REPLACE",
	"RESTRICT",
	"RIGHT",
	"ROLLBACK",
	"ROW",
	"SAVEPOINT",
	"SELECT",
	"SET",
	"TABLE",
	"TEMP",
	"TEMPORARY",
	"THEN",
	"TO",
	"TRANSACTION",
	"TRIGGER",
	"UNION",
	"UNIQUE",
	"UPDATE",
	"USER",
	"USING",
	"VACUUM",
	"VALUES",
	"VIEW",
	"VIRTUAL",
	"WHEN",
	"WHERE",
	];
