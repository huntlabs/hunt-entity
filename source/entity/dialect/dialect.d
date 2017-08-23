module entity.dialect.dialect;

import entity;

interface Dialect
{
    string closeQuote(); 
    string  openQuote();
    Variant fromSqlValue(FieldInfo info);
    string toSqlValueImpl(DlangDataType type,Variant value);
    string toSqlValue(T)(T val)
    {
        Variant value = val;
        DlangDataType type = getDlangDataType!T(val);
        return toSqlValueImpl(type, value);
    }

}
