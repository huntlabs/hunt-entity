module entity.EntityInfo;

import entity;



class EntityInfo(T) {
    
    private EntityFieldInfo[string] _fields;
    private string _tableName;
    private string _entityClassName;
    private string _autoIncrementKey;
    private string _primaryKey;
    private Dialect _dialect;
    private T _data;


    //auto mixin function
    // private void initEntityData(T t){}
    // public T deSerialize(Row row, ref int count) {}
    // public void setIncreaseKey(ref T entity, int value) {}
    // public R getPrimaryValue() {}
    
    pragma(msg,makeInitEntityData!(T));
    pragma(msg,makeDeSerialize!(T));
    pragma(msg,makeSetIncreaseKey!(T));
    pragma(msg,makeGetPrimaryValue!(T));

    mixin(makeInitEntityData!(T)());
    mixin(makeDeSerialize!(T)());
    mixin(makeSetIncreaseKey!(T)());
    mixin(makeGetPrimaryValue!(T)());


   




    this(Dialect dialect, T t = null) {
        _dialect = dialect;
        if (t is null)
            _data = new T();
        else 
            _data = t;
        initEntityData(_data);
    }

    public EntityFieldInfo getPrimaryField() {
        if (_primaryKey.length > 0) 
            return _fields[_primaryKey];
        return null;
    }

    public string[string] getInsertString() {
        string[string] str;
        foreach(info; _fields) {
            if (info.getFileldName() != _autoIncrementKey) {
                str[info.getColumnName()] = _dialect.toSqlValueImpl(info.getFieldType(), info.getFieldValue());
            }
        }
        return str;
    }

    public EntityFieldInfo opDispatch(string name)() 
    {
        EntityFieldInfo info = _fields.get(name,null);
        if (info is null)
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        return info;
    }

    public string getEntityClassName() {return _entityClassName;}
    public string getTableName() {return _tableName;}
    public string getAutoIncrementKey() {return _autoIncrementKey;}
    public EntityFieldInfo[string] getFields() {return _fields;};
    public string getPrimaryKeyString() {return _primaryKey;}
    public EntityFieldInfo getSingleField(string name) {return _fields.get(name,null);}
}


string makeGetPrimaryValue(T)() {
    string str = "\t";
    string R;
    string name;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function) && hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
            R = typeof(__traits(getMember, T ,memberName)).stringof;
            name = memberName;
        }
    }
    str ~= "public "~R~" getPrimaryValue() {\n\t\t";
    str ~= "return _data."~name~";\n\t";
    str ~= "}\n";
    return str;
}




string makeSetIncreaseKey(T)() {
    string endTag = ";\n\t\t";
    string str = "\t";
    str ~= "public void setIncreaseKey(ref T entity, int value) {\n\t\t";
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function) && (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto))) {
            str ~= "entity."~memberName~" = value;\n\t";
        }
    }
    str ~= "}\n";
    return str;
}



string makeDeSerialize(T)() {
    string endTag = ";\n\t\t";
    string str = "\t";
    str ~= "public T deSerialize(Row row, ref long count) {\n\t\t";
    str ~= "T ret"~endTag;
    str ~= "if (row.getSize() == 1 && (indexOf(row.toString(), \"COUNT(\") != -1)) {\n\t\t\t";
    str ~= "count = row[0].to!long;\n\t\t\t";
    str ~= "return ret"~endTag;
    str ~= "}\n\t\t";

    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
            str ~= "if (row.exsit(\""~memberName~"\")) {\n\t\t\t";
            str ~= "if (ret is null) ret = new T();\n\t\t\t";
            str ~= "ret."~memberName~" = "~"*(_dialect.fromSqlValue(this."~memberName~".getFieldType(), Variant(row[\""~memberName~"\"]))).peek!"~memType.stringof~endTag;
            str ~= "}\n\t\t";
        }
    }
    str ~= "return ret;\n\t";
    str ~= "}\n";
    return str;
}

string makeInitEntityData(T)() {
    string endTag = ";\n\t\t";
    string str = "\t";
    str ~= "private void initEntityData(T t) {\n\t\t";
    str ~= "_entityClassName = \"" ~ T.stringof ~"\""~ endTag;
    static if (hasUDA!(T,Table)) {
        str ~= "_tableName = \"" ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~"\""~ endTag;
    }
    else {
        str ~= "_tableName = \"" ~ T.stringof ~"\""~ endTag;
    }
    str ~= "if (t is null) {\n\t\t\t";
    str ~= "t = new T();\n\t\t";
    str ~= "}\n\t\t";
    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
            string fieldType =  "new "~getDlangDataTypeStr!memType~"()";
            string mark = "0"; 
            string columnName = "\""~__traits(getMember, T ,memberName).stringof~"\"";
            string value = "t."~memberName;

            static if (hasUDA!(__traits(getMember, T ,memberName), Column)) {
                columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
            }

            static if (hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
                if (mark == "0") 
                    mark = "PrimaryKey";
                else
                    mark ~= "|PrimaryKey";
                str ~= "_primaryKey = "~memberName.stringof~endTag;
            }
            static if (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto)) {
                if (mark == "0") 
                    mark = "AutoIncrement";
                else 
                    mark ~= "|AutoIncrement";
                str ~= "_autoIncrementKey = "~memberName.stringof~endTag;
            }
            //TODO add more entity @ tag

            str ~= "_fields["~memberName.stringof~"] = new EntityFieldInfo("~memberName.stringof~", "~columnName~", "~fieldType~", Variant("~value~"), "~mark~")" ~ endTag;
        }
    }
    str ~= "if (_fields.length == 0)\n\t\t";
    str ~= "\tthrow new EntityException(\"Entity class member cannot be empty : " ~ T.stringof~ "\")" ~ endTag;
    str ~= "}\n";
    return str;
}