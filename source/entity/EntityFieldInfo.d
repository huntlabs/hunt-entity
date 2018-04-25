


module entity.EntityFieldInfo;

import std.variant;
import entity;

class EntityFieldInfo {
    
    private int _mark;
    private string _columnName;
    private string _fileldName;
    private DlangDataType _fieldType;
    private Variant _fieldValue;
    private string _columeSpecifier;


    public this(string columnName) {
        _columnName = columnName;
    }

    public this(string fileldName,string columnName, DlangDataType fieldType, Variant fieldValue,int mark = 0) {
        _fileldName = fileldName;
        _columnName = columnName;
        _fieldType = fieldType;
        _mark = mark;
        _fieldValue = fieldValue;
    }
    
    public void assertType(T)() {
        if (_fieldType.getName() == "string" && getDlangTypeStr!T != "string") {
            throw new EntityException("EntityFieldInfo %s type need been string not %s".format(_fileldName, typeid(T)));
        }
        if (_fieldType.getName() != "string" && getDlangTypeStr!T == "string") {
            throw new EntityException("EntityFieldInfo %s type need been number not string".format(_fileldName));
        }
    }

    public Variant getFieldValue() {return _fieldValue;}
    public string getFileldName() {return _fileldName;}
    public DlangDataType getFieldType() {return _fieldType;}
    public string getColumnName() {return _columnName;}

    public EntityFieldInfo setColumeSpecifier(string s) {
        _columeSpecifier = s;
        return this;
    }
    public string getFullColumeString() {
        if (_columeSpecifier != "")  {
            if (_columeSpecifier != "COUNT")
                return _columeSpecifier ~ "(" ~ _columnName ~ ") as "~_columnName;
            return _columeSpecifier ~ "(" ~ _columnName ~ ")";
        }
        return _columnName;
    }


    public int addmark(int mark) {
        return _mark |= mark;
    }
    public int removemark(int mark) {
        return _mark & (~mark);
    }
    public int checkmark(int mark) {
        return _mark & mark;
    }

}
