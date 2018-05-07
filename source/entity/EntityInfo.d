/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
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
    // public T deSerialize(Row row) {}
    // public void setIncreaseKey(ref T entity, int value) {}
    // public R getPrimaryValue() {}
    
    pragma(msg,makeImport!(T)());
    pragma(msg,makeInitEntityData!(T));
    pragma(msg,makeDeSerialize!(T));
    pragma(msg,makeSetIncreaseKey!(T));
    pragma(msg,makeGetPrimaryValue!(T));

    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T)());
    mixin(makeDeSerialize!(T)());
    mixin(makeSetIncreaseKey!(T)());
    mixin(makeGetPrimaryValue!(T)());

    this(Dialect dialect, T t = null)
    {
        _dialect = dialect;
        if (t is null)
            _data = new T();
        else 
            _data = t;
        initEntityData(_data);
    }

    public EntityFieldInfo getPrimaryField()
    {
        if (_primaryKey.length > 0) 
            return _fields[_primaryKey];
        return null;
    }

    public string[string] getInsertString()
    {
        string[string] str;
        foreach(info; _fields)
        {
            if (info.getFileldName() != _autoIncrementKey)
            {
                if (cast(EntityFieldNormal)(info))
                {
                    str[info.getColumnName()] = _dialect.toSqlValueImpl((cast(EntityFieldNormal)info).getFieldType(), info.getFieldValue());
                }
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
    public EntityFieldInfo[string] getFields() {return _fields;}
    public string getPrimaryKeyString() {return _primaryKey;}
    public EntityFieldInfo getSingleField(string name) {return _fields.get(name,null);}
}

string makeImport(T)()
{
    return "\n\timport "~moduleName!T~";";
}

string makeGetPrimaryValue(T)()
{
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

string makeSetIncreaseKey(T)()
{
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

string makeDeSerialize(T)() 
{
    string endTag = ";\n\t\t";
    string str = "\t";
    str ~= "public T deSerialize(Row row, ref long count) {\n\t\t";
    str ~= "T ret"~endTag;
    str ~= "RowData data = row.getAllRowData(_tableName)"~endTag;
    str ~= "if (data is null) return ret"~endTag;

    str ~= "if (data.getAllData().length == 1 && data.getData(\"count\")) {\n\t\t\t";
    str ~= "count = data.getData(\"count\").value.to!long;\n\t\t\t";
    str ~= "return ret"~endTag;
    str ~= "}\n\t\t";

    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
            continue;
        }
        else static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
            static if (isBasicType!memType || isSomeString!memType) {
                str ~= "if (data.getData(\""~memberName~"\")) {\n\t\t\t";
                str ~= "if (ret is null) ret = new T();\n\t\t\t";
                str ~= "(cast(EntityFieldNormal)(this."~memberName~")).deSerialize(_dialect, data.getData(\""~memberName~"\").value, ret."~memberName~");\n\t\t";
                str ~= "}\n\t\t";
            }
            else {
                str ~= "(cast(EntityFieldManyToOne!"~memType.stringof~")(this."~memberName~")).deSerialize(_dialect, row, ret."~memberName~");\n\t\t";
            }

        }
    }

    str ~= "return ret;\n\t";
    str ~= "}\n";

    return str;
}

string makeInitEntityData(T)()
{
    string endTag = ";\n\t\t";
    string str = "\t";

    str ~= "private void initEntityData(T t) {\n\t\t";
    str ~= "_entityClassName = \"" ~ T.stringof ~"\""~ endTag;

    static if (hasUDA!(T,Table))
    {
        str ~= "_tableName = \"" ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~"\""~ endTag;
    }
    else
    {
        str ~= "_tableName = \"" ~ T.stringof ~"\""~ endTag;
    }

    str ~= "if (t is null) {\n\t\t\t";
    str ~= "t = new T();\n\t\t";
    str ~= "}\n\t\t";

    foreach(memberName; __traits(derivedMembers, T))
    {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {

            //primary key
            static if (hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
                str ~= "_primaryKey = "~memberName.stringof~endTag;
            }

            //autoincrease key
            static if (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto)) {
                str ~= "_autoIncrementKey = "~memberName.stringof~endTag;
            }

            //columnName
            string columnName;
            static if (hasUDA!(__traits(getMember, T ,memberName), Column)) {
                columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), JoinColumn)) {
                columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].name~"\"";
            }
            else {
                columnName = "\""~__traits(getMember, T ,memberName).stringof~"\"";
            }

            //value 
            string value = "t."~memberName;

            
            static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                // str ~= "_fields["~memberName.stringof~"] = new EntityFieldOneToOne("~memberName.stringof~", "~columnName~", Variant("~value~"), "~(getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof~")" ~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
                // str ~= "_fields["~memberName.stringof~"] = new EntityFieldOneToMany("~memberName.stringof~", "~columnName~", Variant("~value~"), "~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~")" ~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)) {
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldManyToOne!("~memType.stringof~")("~memberName.stringof~", "~columnName~", _tableName, "~value~", "~(getUDAs!(__traits(getMember, T ,memberName), ManyToOne)[0]).stringof~")"~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
                // str ~= "_fields["~memberName.stringof~"] = new EntityFieldManyToMany("~memberName.stringof~", 
                //                                                                 "~columnName~", Variant("~value~"), 
                //                                                                 "~(getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~")"
                //                                                                  ~ endTag;
            }
            else {
                string fieldType =  "new "~getDlangDataTypeStr!memType~"()";
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldNormal("~memberName.stringof~", "~columnName~", _tableName, Variant("~value~"), "~fieldType~")" ~ endTag;
            }



        }
    }

    str ~= "if (_fields.length == 0)\n\t\t";
    str ~= "\tthrow new EntityException(\"Entity class member cannot be empty : " ~ T.stringof~ "\");\n\t";
    str ~= "}\n";

    return str;
}
