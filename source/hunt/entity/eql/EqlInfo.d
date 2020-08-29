module hunt.entity.eql.EqlInfo;

import hunt.entity.eql.Common;
import hunt.entity.dialect;
import hunt.logging;

import std.array;
import std.format;
import std.traits;


class EqlObject
{
    private string _className;
    private string _tableName;
    private string _name;
    private Object[] _selectItem;

    this(string name , string clsName = null)
    {
        _name = name;
        _className = clsName;
    }

    public string className() { return _className ;}
    public void setClassName(string name)
    {
        _className = name;
    }

    public string tableName() { return _tableName; }
    public void setTableName(string tbName)
    {
        _tableName = tbName;
    }

    public void putSelectItem( Object o)
    {
        _selectItem ~= o;
    }

    public Object[] getSelectItems()
    {
        return _selectItem;
    }

    override string toString()
    {
        return "( ObjName : %s , ClsName : %s , TableName : %s )".format(_name,_className,_tableName);
    }
}


import hunt.entity;
import hunt.entity.DefaultEntityManagerFactory;

import hunt.logging;
import std.conv;


class EqlInfo(T : Object, F : Object = T) {
    
    private EntityFieldInfo[string] _fields;
    private string _factoryName = defaultEntityManagerFactoryName();
    private string _tableName;
    private string _tableNameInLower; // for PostgreSQL, the column's name will be converted to lowercase.
    private string _entityClassName;
    private string _autoIncrementKey;
    private string _primaryKey;
    private EntityManager _manager;
    private Dialect _dialect;
    private T _data;
    private F _owner;
    private string _tablePrefix;

    private Object[string] _joinConds;


    // pragma(msg, "T = "~T.stringof~ " F = "~F.stringof);
    // pragma(msg,makeImport!(T)());
    // pragma(msg,makeInitEntityData!(T,F));
    // pragma(msg,makeDeSerialize!(T,F));
    // pragma(msg,makeSetIncreaseKey!(T));
    // pragma(msg,makeGetPrimaryValue!(T));
    // pragma(msg,makeSetPrimaryValue!(T)());

    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T,F)());
    mixin(makeDeSerialize!(T,F)());
    mixin(makeSetIncreaseKey!(T)());
    mixin(makeGetPrimaryValue!(T)());
    mixin(makeSetPrimaryValue!(T)());

    this(EntityManager manager = null, T t = null, F owner = null)
    {
        if (t is null) {
            _data = new T();
        }
        else {
            _data = t;
        }
        static if (is(T == F)){
            _owner = _data;
        }
        else{
            _owner = owner;
        }
        _manager = manager;
        if (_manager) {
            _data.setManager(_manager);
            _tablePrefix = _manager.getPrefix();
        }
        initEntityData();
    }

    public EntityFieldInfo getPrimaryField() {
        if (_primaryKey.length > 0) 
            return _fields[_primaryKey];
        return null;
    }


    public EntityFieldInfo opDispatch(string name)() 
    {
        EntityFieldInfo info = _fields.get(name,null);
        if (info is null)
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        return info;
    }

    public string getFactoryName() { return _factoryName; };
    public string getEntityClassName() { return _entityClassName; }
    public string getTableName() { return _tableName; }
    public string getAutoIncrementKey() { return _autoIncrementKey; }
    public EntityFieldInfo[string] getFields() { return _fields; }
    public string getPrimaryKeyString() { return _primaryKey; }
    public EntityFieldInfo getSingleField(string name) { return _fields.get(name,null); }
    public string getJoinCond(string member) { 
        auto cond =  _joinConds.get(member,null);
        return cond !is null ? cond.toString() : null;
    }
    public Object[string] getJoinConds() { 
        return _joinConds;
    }

    private string getCountAsName() {
        if(_manager.getDbOption().isPgsql()) {
            return EntityExpression.getCountAsName(_tableNameInLower);
        } else {
            return EntityExpression.getCountAsName(_tableName);
        }
    }
}


string makeSetPrimaryValue(T)() {
    string R;
    string name;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType) && hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
                R = typeof(__traits(getMember, T ,memberName)).stringof;
                name = memberName;
            }
        }
    }
    return `
    public void setPrimaryValue(string value) {
        _data.`~name~` = value.to!`~R~`;
    }`;
}


string makeGetPrimaryValue(T)() {
    string R;
    string name;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType) && hasUDA!(__traits(getMember, T ,memberName), PrimaryKey)) {
                R = typeof(__traits(getMember, T ,memberName)).stringof;
                name = memberName;
            }
        }
    }
    return `
    public `~R~` getPrimaryValue() {
        return _data.`~name~`;
    }`;
}

string makeSetIncreaseKey(T)() {
    string name;
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType) && (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto))) {
                name = memberName;
            }
        }
    }
    if (name == "")
        return `
    public void setIncreaseKey(ref T entity, int value) {
    }`;
    else
        return `
    public void setIncreaseKey(ref T entity, int value) {
        entity.`~name~` = value;
    }`;
}


string makeInitEntityData(T,F)() {
    string str = `
    private void initEntityData() {
        _entityClassName = "`~T.stringof~`";`;
    static if (hasUDA!(T,Table)) {
        str ~= `
        _tableName = _tablePrefix ~ "` ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~`";`;
    }
    else {
        str ~= `
        _tableName = _tablePrefix ~ "` ~ T.stringof ~ `";`;
    }

    static if (hasUDA!(T, Factory))
    {
        str ~= `
        _factoryName = `~ getUDAs!(getSymbolsByUDA!(T,Factory)[0], Factory)[0].name~`;`;
    }

    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                //columnName nullable
                string nullable;
                string columnName;
                string referencedColumnName;
                static if (hasUDA!(__traits(getMember, T ,memberName), Column)) {
                    columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
                    nullable = getUDAs!(__traits(getMember, T ,memberName), Column)[0].nullable.to!string;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), JoinColumn)) {
                    columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].name~"\"";
                    referencedColumnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].referencedColumnName~"\"";
                    nullable = getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].nullable.to!string;
                    static if(is(memType == class))
                    {
                        str ~= `
                        {
                            auto joinCond = new JoinCond!(`~memType.stringof~`)(_manager,_entityClassName,`~memberName.stringof~`, `~columnName~`,`~referencedColumnName~`, _tableName);
                            _joinConds[_entityClassName ~ "." ~ `~memberName.stringof~`] = joinCond;
                        }
                        `;
                    }
                }
                else {
                    columnName = "\""~__traits(getMember, T ,memberName).stringof~"\"";
                }
           
                string value = "_data."~memberName;
                string fieldName = "_fields["~memberName.stringof~"]";
                static if (is(F == memType)) {
        str ~= `
        `~fieldName~` = new EntityFieldOwner(`~memberName.stringof~`, `~columnName~`, _tableName);`;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                    string owner = (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";

        str ~= `
        `~ fieldName ~ ` = new EntityFieldOneToOne!(` ~ memType.stringof ~ ", T)(_manager, " ~ memberName.stringof ~
                    `, _primaryKey, ` ~ columnName ~ ", _tableName, " ~ value ~ ", " ~ 
                    (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof ~ 
                    `, ` ~ owner ~ `);`;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
        //             static if (is(T==F)) {
        // str ~= `
        // `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, F)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
        //                                 ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _owner);`;
        //             }
        //             else {
        // str ~= `
        // `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, T)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
        //                                 ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _data);`;
        //             }
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)) {
        str ~= `
        `~fieldName~` = new EntityFieldManyToOne!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, `~columnName~`, _tableName, `~value~`, `
                                    ~(getUDAs!(__traits(getMember, T ,memberName), ManyToOne)[0]).stringof~`);`;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
                    //TODO                                                                 
                }
                else {
        str ~= `
        `~fieldName~` = new EntityFieldNormal!(`~memType.stringof~`)(_manager,`~memberName.stringof~`, `~columnName~`, _tableName, `~value~`);`;
            }

                //nullable
                if (nullable != "" && nullable != "true")
        str ~= `
        `~fieldName~`.setNullable(`~nullable~`);`;
                //primary key
                static if (hasUDA!(__traits(getMember, T ,memberName), PrimaryKey) || hasUDA!(__traits(getMember, T ,memberName), Id)) {
        str ~= `
        _primaryKey = `~memberName.stringof~`;
        `~fieldName~`.setPrimary(true);`;
                }
                //autoincrease key
                static if (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto)) {
        str ~= `
        _autoIncrementKey = `~memberName.stringof~`;
        `~fieldName~`.setAuto(true);
        `~fieldName~`.setNullable(false);`;
                }
            }
        }    
    }
    str ~=`
        if (_fields.length == 0) {
            throw new EntityException("Entity class member cannot be empty : `~ T.stringof~`");
        }
    }`;
    return str;
}


string makeDeSerialize(T,F)() {
    string str;

    str ~= "\n" ~ indent(4) ~ "/// T=" ~ T.stringof ~ ", F=" ~ F.stringof;
    str ~= `
    T deSerialize(Row[] rows, ref long count, int startIndex = 0, F owner = null,  bool isFromManyToOne = false) {
        version(HUNT_ENTITY_DEBUG_MORE) {
            infof("Target: %s, Rows: %d, count: %s, startIndex: %d, tableName: %s ", 
                T.stringof, rows.length, count, startIndex, _tableName);
        }

        import std.variant;

        T _data = new T();
        bool isObjectDeserialized = false;
        bool isMemberDeserialized = false;
        bool isDeserializationNeed = true;
        // T actualOwner = null;

        _data.setManager(_manager);
        Row row = rows[startIndex];
        string columnAsName;
        version(HUNT_ENTITY_DEBUG_MORE) logDebugf("rows[%d]: %s", startIndex, row);
        if (row is null || row.size() == 0)
            return null;

        columnAsName = getCountAsName();
        Variant columnValue = row.getValue(columnAsName);
        if (columnValue.hasValue()) {
            version(HUNT_ENTITY_DEBUG) tracef("count: %s", columnValue.toString());
            count = columnValue.coerce!(long);
            return null;
        }
        `;
        
    // static if(is(T == F)) {
    //     str ~= indent(8) ~ "T actualOwner = _data;\n";
    // } else {
    //     str ~= indent(8) ~ "T actualOwner = null;\n";
    // }

    str ~= indent(8) ~ "T actualOwner = _data;\n";

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMember = __traits(getMember, T, memberName);
        alias memType = typeof(currentMember);

        static if (__traits(getProtection, currentMember) == "public") {
            string mappedBy;
            static if(hasUDA!(currentMember, ManyToMany)) {
                mappedBy = "\""~getUDAs!(currentMember, ManyToMany)[0].mappedBy~"\"";
            }

            str ~= "\n";
            str ~= indent(8) ~ "// Handle membmer: " ~ memberName ~ ", type: " ~ memType.stringof ~ "\n";

            // string or basic type
            static if (isBasicType!memType || isSomeString!memType) {
                str ~=`
                isMemberDeserialized = false;
                auto `~memberName~` = cast(EntityFieldNormal!`~memType.stringof~`)(this.`~memberName~`);
                columnAsName = `~memberName~`.getColumnAsName();
                columnValue = row.getValue(columnAsName);
                version(HUNT_ENTITY_DEBUG_MORE) {
                    tracef("A column: %s = %s; The AsName: %s", `~memberName~`.getColumnName(), 
                        columnValue, columnAsName);
                }

                if(columnValue.type == typeid(null)) {
                    version(HUNT_DEBUG) {
                        warningf("The value of column [%s] is null. So use its default.", "` 
                            ~ memberName ~ `");
                    }
                } else if (columnValue.hasValue()) {
                    string cvalue = columnValue.toString();
                    version(HUNT_ENTITY_DEBUG_MORE) { 
                        tracef("field: name=%s, type=%s; column: name=%s, type=%s; value: %s", "` 
                                    ~ memberName ~ `", "` ~ memType.stringof ~ `", columnAsName, columnValue.type,` 
                                    ~ ` cvalue.empty() ? "(empty)" : cvalue);
                    }
                    _data.`~memberName~` = `~memberName~`.deSerialize!(` ~ 
                        memType.stringof ~ `)(cvalue, isMemberDeserialized);
                    if(isMemberDeserialized) isObjectDeserialized = true;
                }`;
                
            } else { // Object
                str ~= indent(8) ~ "isDeserializationNeed = true;\n";

                static if(is(F == memType)) {
                    str ~=`
                    if(owner is null) {
                        version(HUNT_ENTITY_DEBUG) {
                            warning("The owner [` ~ F.stringof ~ `] of [` ~ T.stringof ~ `] is null.");
                        }
                    } else {
                        version(HUNT_ENTITY_DEBUG) {
                            warningf("set [` ~ memberName ~ 
                                `] to the owner {Type: %s, isNull: false}", "` ~ F.stringof ~ `");
                        }
                        isDeserializationNeed = false;
                        _data.` ~ memberName ~ ` = owner;
                    }` ~ "\n\n";
                } 

                str ~= indent(8) ~ "if(isDeserializationNeed) {\n";
                str ~= indent(12) ~ "version(HUNT_ENTITY_DEBUG) info(\"Deserializing member: " 
                    ~ memberName ~ " \");\n";
                str ~= indent(12) ~ "EntityFieldInfo fieldInfo = this.opDispatch!(\"" ~ memberName ~ "\")();\n";

                static if (isArray!memType && hasUDA!(currentMember, OneToMany)) {
                    str ~=`
                    auto fieldObject = (cast(EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`,T))(fieldInfo));
                    if(fieldObject is null) {
                        warningf("The field is not a EntityFieldManyToOne. It's a %s", typeid(fieldInfo));
                    } else {
                        _data.addLazyData("`~memberName~`", fieldObject.getLazyData(rows[startIndex]));
                        _data.`~memberName~` = fieldObject.deSerialize(rows, startIndex, isFromManyToOne, actualOwner);
                        isMemberDeserialized = true;
                    }`;

                } else static if (hasUDA!(currentMember, ManyToOne)) {
                    str ~=`
                    auto fieldObject = (cast(EntityFieldManyToOne!(`~memType.stringof~`))(fieldInfo));
                    if(fieldObject is null) {
                        warningf("The field is not a EntityFieldManyToOne. It's a %s", typeid(fieldInfo));
                    } else {
                        _data.addLazyData("`~memberName~`", fieldObject.getLazyData(rows[startIndex]));
                        _data.`~memberName~` = fieldObject.deSerialize(rows[startIndex]);
                        isMemberDeserialized = true;
                    }`;

                } else static if (hasUDA!(currentMember, OneToOne)) {
                    str ~= `
                    auto fieldObject = (cast(EntityFieldOneToOne!(`~memType.stringof~`, T))(fieldInfo));
                    if(fieldObject is null) {
                        warningf("The field is not a EntityFieldOneToOne. It's a %s", typeid(fieldInfo));
                    } else {
                        _data.addLazyData("`~memberName~`", fieldObject.getLazyData(rows[startIndex]));
                        _data.`~memberName~` = fieldObject.deSerialize(rows[startIndex], actualOwner);
                        isMemberDeserialized = true;
                    }`;
                } else static if (isArray!memType && hasUDA!(currentMember, ManyToMany)) {
                    static if ( memType.stringof.replace("[]","") == F.stringof) {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`,F,`~mappedBy~`))(fieldInfo));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;
                    } else {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`))(fieldInfo));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;
                    }
    
                }
                
                str ~= "\n" ~ indent(12) ~  "if(isMemberDeserialized) isObjectDeserialized = true;";
                str ~= `
                version(HUNT_ENTITY_DEBUG) {
                    warningf("member: `~memberName~`, isDeserialized: %s, result: %s null", ` ~ 
                        `isMemberDeserialized, _data.` ~ memberName ~ ` is null ? "is" : "is not");
                }`;

                str ~= "\n" ~ indent(8) ~ "}\n";
            }
        }
    }}



    // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-08-25T15:22:46+08:00
    // More tests needed
    str ~= `
        version(HUNT_ENTITY_DEBUG) {
            infof("Object: ` ~ T.stringof ~`, isDeserialized: %s",  isObjectDeserialized);
        }

        if(isObjectDeserialized) {
            _data.loadLazyMembers();
            // return Common.sampleCopy(_data);
            return _data;
        } else {
            return T.init;
        }
    }`;

    return str;
}


class JoinCond(T : Object)
{
    private string _joinCond;
    private EqlInfo!T _eqlInfo;
    this(EntityManager manager, string leftTable,string fieldName, string joinCol, string referencedColumnName ,string tableName)
    {
        _eqlInfo = new EqlInfo!T(manager);
        if(referencedColumnName.length == 0)
            _joinCond = tableName ~ "." ~ joinCol ~ " = " ~ _eqlInfo.getTableName() ~ "." ~ _eqlInfo.getPrimaryKeyString();
        else
            _joinCond = tableName ~ "." ~ joinCol ~ " = " ~ _eqlInfo.getTableName() ~ "." ~ referencedColumnName;
    }

    override string toString()
    {
        return _joinCond;
    }
}