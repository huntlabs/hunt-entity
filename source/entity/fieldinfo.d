module entity.fieldinfo;

import entity;

class FieldInfo
{
    string fieldName;
    string columnName;
    DlangDataType fieldType;
    Variant fieldValue;
    int[] fieldAttrs;
    Dialect dialect;

    alias void function(Object,FieldInfo,Dialect) WriteFunc;
    alias string function(Object,FieldInfo,Dialect) ReadFunc;

    WriteFunc writeFunc;
    ReadFunc readFunc;

    this(string fieldName,string columnName,DlangDataType fieldType,
         int[] fieldAttrs,Dialect dialect, WriteFunc write,ReadFunc read)
    {
        this.fieldName = fieldName;
        this.columnName = columnName;
        this.fieldType = fieldType;
        this.fieldAttrs = fieldAttrs;
        this.dialect = dialect;

        this.writeFunc = write;
        this.readFunc = read;
    }

    void write(Object obj)
    {
        this.writeFunc(obj,this,dialect);
    }

    string read(Object obj)
    {
        return this.readFunc(obj,this,dialect);
    }
}
