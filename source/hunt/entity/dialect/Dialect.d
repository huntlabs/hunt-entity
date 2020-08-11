module hunt.entity.dialect.Dialect;

// import hunt.database;
import hunt.database.query.Common;

import std.conv;
import std.variant;

interface Dialect {
	Variant fromSqlValue(DlangDataType fieldType, Variant fieldValue);
	string toSqlValueImpl(DlangDataType type, Variant value);
	
	string toSqlValue(T)(T val) {
		Variant value = val;
		DlangDataType type = getDlangDataType!T;
		return toSqlValueImpl(type, value);
	}

	string getColumnDefinition(ColumnDefinitionInfo info);
}

public T safeConvert(F, T)(F value) {
	try {
		return to!T(value);
	} catch {
		return T.init;
	}
}

auto fromSQLType(uint type) {
	return typeid(string);
}

struct SqlSingleTypeInfo {
	SqlType sqlType;
	int len;
	bool unsigned;
}

struct ColumnDefinitionInfo {
	int len = 0;
	bool isId;
	string name;
	bool isAuto;
	bool isNullable;
	string dType;
}

// dfmt off
enum SqlSingleTypeInfo[PropertyMemberType] DTypeToSqlInfo = [
	PropertyMemberType.BOOL_TYPE : SqlSingleTypeInfo(SqlType.BOOLEAN, 2, false),
	PropertyMemberType.SHORT_TYPE : SqlSingleTypeInfo(SqlType.SMALLINT, 4, false),
	PropertyMemberType.USHORT_TYPE : SqlSingleTypeInfo(SqlType.SMALLINT, 4, true),
	PropertyMemberType.INT_TYPE : SqlSingleTypeInfo(SqlType.INTEGER, 9, false),
	PropertyMemberType.UINT_TYPE : SqlSingleTypeInfo(SqlType.INTEGER, 9, true),
	PropertyMemberType.LONG_TYPE : SqlSingleTypeInfo(SqlType.BIGINT, 20, false),
	PropertyMemberType.ULONG_TYPE : SqlSingleTypeInfo(SqlType.BIGINT, 20, true),
	PropertyMemberType.BYTE_TYPE : SqlSingleTypeInfo(SqlType.TINYINT, 2, false),
	PropertyMemberType.UBYTE_TYPE : SqlSingleTypeInfo(SqlType.TINYINT, 2, true),
	PropertyMemberType.FLOAT_TYPE : SqlSingleTypeInfo(SqlType.FLOAT, 7, false),
	PropertyMemberType.DOUBLE_TYPE : SqlSingleTypeInfo(SqlType.DOUBLE, 14, false),
	PropertyMemberType.STRING_TYPE : SqlSingleTypeInfo(SqlType.VARCHAR, 0, false),
];
// dfmt on
