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
import std.conv;



class EntityInfo(T : Object, F : Object = T) {
    
    private EntityFieldInfo[string] _fields;
    private string _tableName;
    private string _entityClassName;
    private string _autoIncrementKey;
    private string _primaryKey;
    private CriteriaBuilder _builder;
    private Dialect _dialect;
    private T _data;
    private F _owner;


    //auto mixin function
    // private void initEntityData(T t){}
    // public T deSerialize(Row row) {}
    // public void setIncreaseKey(ref T entity, int value) {}
    // public R getPrimaryValue() {}
    // public void setPrimaryValue(ref T entity, int value) {}


    // pragma(msg, "T = "~T.stringof~ " F = "~F.stringof);
    // pragma(msg,makeImport!(T)());
    // pragma(msg,makeInitEntityData!(T,F));
    // pragma(msg,makeDeSerialize!(T,F));
    // pragma(msg,makeSetIncreaseKey!(T));
    // pragma(msg,makeGetPrimaryValue!(T));
    // pragma(msg,makeSetPrimaryValue(string value));


    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T,F)());
    mixin(makeDeSerialize!(T,F)());
    mixin(makeSetIncreaseKey!(T)());
    mixin(makeGetPrimaryValue!(T)());
    mixin(makeSetPrimaryValue!(T)());
    

    this(CriteriaBuilder builder, T t = null, F owner = null) {
        _builder = builder;
        if (t is null)
            _data = new T();
        else 
            _data = t;
        static if (is(T == F)) {
            _owner = _data;
        }
        else {
            _owner = owner;
        }
        initEntityData();
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
                if (cast(EntityFieldNormal)(info)) {
                    str[info.getFullColumn()] = _builder.getDialect().toSqlValueImpl((cast(EntityFieldNormal)info).getFieldType(), info.getFieldValue());
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






string makeSetPrimaryValue(T)() {
    string str = "\t";
    string R;
    string name;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function) && hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
            R = typeof(__traits(getMember, T ,memberName)).stringof;
            name = memberName;
        }
    }
    str ~= "public void setPrimaryValue(string value) {\n\t\t";
    str ~= "_data."~name~" = value.to!"~R~";\n\t";
    str ~= "}\n";
    return str;
}



string makeImport(T)() {
    return "\n\timport "~moduleName!T~";";
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


string makeInitEntityData(T,F)() {
    string endTag = ";\n\t\t";
    string str = "\t";
    str ~= "private void initEntityData() {\n\t\t";
    str ~= "_entityClassName = \"" ~ T.stringof ~"\""~ endTag;
    static if (hasUDA!(T,Table)) {
        str ~= "_tableName = \"" ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~"\""~ endTag;
    }
    else {
        str ~= "_tableName = \"" ~ T.stringof ~"\""~ endTag;
    }
    foreach(memberName; __traits(derivedMembers, T)) {
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
            string value = "_data."~memberName;
            static if (is(F == memType)) {
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldOwner("~memberName.stringof~", "~columnName~", Variant(_owner), _tableName)"~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                string owner = (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldOneToOne!("~memType.stringof~", F)(_builder, "~memberName.stringof~", _primaryKey, "~columnName~", _tableName, "
                                ~(getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof~", "~owner~")"~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldOneToMany!("~memType.stringof.replace("[]","")~", F)(_builder, "~memberName.stringof~", _primaryKey, _tableName, "
                                ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~", _owner)"~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)) {
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldManyToOne!("~memType.stringof~")(_builder, "~memberName.stringof~", "~columnName~", _tableName, "~value~", "
                                ~(getUDAs!(__traits(getMember, T ,memberName), ManyToOne)[0]).stringof~")"~ endTag;
            }
            else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
                // str ~= "_fields["~memberName.stringof~"] = new EntityFieldManyToMany("~memberName.stringof~", 
                //                                                                 "~columnName~", Variant("~value~"), 
                //                                                                 "~(getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~")"
                //                                                                  ~ endTag;
            }
            else {
                string fieldType =  "new "~getDlangDataTypeStr!memType~"()";
                str ~= "_fields["~memberName.stringof~"] = new EntityFieldNormal(_builder, "~memberName.stringof~", "~columnName~", _tableName, Variant("~value~"), "~fieldType~")" ~ endTag;
            }

        }
    }
    str ~= "if (_fields.length == 0)\n\t\t";
    str ~= "\tthrow new EntityException(\"Entity class member cannot be empty : " ~ T.stringof~ "\");\n\t";
    str ~= "}\n";
    return str;
}

string makeDeSerialize(T,F)() {
    string str = "\t";
    str ~= "public T deSerialize(Row[] rows, ref long count, int startIndex = 0, bool isFromManyToOne = false) {"~skip();
    str ~= "RowData data = rows[startIndex].getAllRowData(_tableName);"~skip();
    str ~= "if (data is null)"~skip(3);
    str ~= "return null;"~skip();
    str ~= "if (data.getAllData().length == 1 && data.getData(\"countfor\"~_tableName~\"_\")) {"~skip(3);
    str ~= "count = data.getData(\"countfor\"~_tableName~\"_\").value.to!long;"~skip(3);
    str ~= "return null;"~skip();
    str ~= "}"~skip();
    foreach(memberName; __traits(derivedMembers, T)) {
        alias memType = typeof(__traits(getMember, T ,memberName));
        static if (!is(FunctionTypeOf!(__traits(getMember, T ,memberName)) == function)) {
            static if (isBasicType!memType || isSomeString!memType) {
                str ~= "if (data.getData(\""~memberName~"\")) {"~skip(3);
                str ~= "_data."~memberName~" = (cast(EntityFieldNormal)(this."~memberName~")).deSerialize!("~memType.stringof~")(data.getData(\""~memberName~"\").value);"~skip();
                str ~= "}"~skip();
            }
            else {
                static if(is(F == memType)) {
                    str ~= "_data."~memberName~" = _owner;"~skip();
                }
                else static if (isArray!memType && hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
                    string singleType = memType.stringof.replace("[]","");
                    str ~= "_data."~memberName~" = (cast(EntityFieldOneToMany!("~singleType~","~T.stringof~"))(this."~memberName~")).deSerialize(rows, startIndex, isFromManyToOne);"~skip();
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)){
                    str ~= "auto "~memberName~" = cast(EntityFieldManyToOne!("~memType.stringof~"))(this."~memberName~");"~skip();
                    str ~= "if (data.getData("~memberName~".getColumnName())) {"~skip(3);
                    str ~= "_data."~memberName~" = "~memberName~".deSerialize(rows[startIndex]);"~skip();
                    str ~= "}"~skip();
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                    str ~= "_data."~memberName~" = (cast(EntityFieldOneToOne!("~memType.stringof~", F))(this."~memberName~")).deSerialize(rows[startIndex]);"~skip();
                }
            }
        }
    // str ~= "log(\""~T.stringof~"._data."~memberName~" = \", _data."~memberName~");\n";
    }
    str ~= "return Common.sampleCopy(_data);\n\t";
    str ~= "}\n";
    return str;
}





string skip(int interval = 2) {
    string ret = "\n";
    for(int i = 0; i < interval; i ++) {
        ret ~= "\t";
    }
    return ret;
}