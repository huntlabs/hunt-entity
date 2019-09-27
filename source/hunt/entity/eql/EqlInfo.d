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
        `~fieldName~` = new EntityFieldOneToOne!(`~memType.stringof~`, T)(_manager, `~memberName.stringof~`, _primaryKey, `~columnName~`, _tableName, `~value~`, `
                                    ~(getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof~`, `~owner~`);`;
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
    string str = `
    public T deSerialize(Row[] rows, ref long count, int startIndex = 0, bool isFromManyToOne = false) {
        version(HUNT_ENTITY_DEBUG) {
            tracef("Target: %s, Rows: %s, count: %s, startIndex: %d, tableName: %s ", 
                T.stringof, rows, count, startIndex, _tableName);
        }

        import std.variant;

        T _data = new T();

        Row row = rows[startIndex];
        string columnAsName;
        string columnName;
        version(HUNT_ENTITY_DEBUG) logDebugf("rows[%d]: %s", startIndex, row);
        if (row is null || row.size() == 0)
            return null;

        Variant columnValue = row.getValue("countfor" ~ _tableName ~ "_");
        if (columnValue.hasValue()) {
            count = columnValue.get!(long);
            return null;
        }
        `;
        
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                static if (isBasicType!memType || isSomeString!memType) {
        str ~=`
        auto `~memberName~` = cast(EntityFieldNormal!`~memType.stringof~`)(this.`~memberName~`);
        columnAsName = `~memberName~`.getColumnAsName();
        columnName = `~memberName~`.getColumnName();

        columnValue = row.getValue(columnName);
        if (!columnValue.hasValue()) // try use columnAsName to get the value
            columnValue = row.getValue(columnAsName);

        version(HUNT_ENTITY_DEBUG) {
            tracef("A column: %s = %s, As Name: %s", columnName, 
                columnValue, columnAsName);
        }
        if (columnValue.hasValue()) {
            `~memberName~`.deSerialize!(`~memType.stringof~`)(columnValue.toString(), _data.`~memberName~`);
        }
        `;
                }
                else {
                    static if(is(F == memType)) {
        str ~=`
        _data.`~memberName~` = _owner;`;
                    }
                    else static if (isArray!memType && hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
        str ~=`
        auto `~memberName~` = (cast(EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`,T))(this.`~memberName~`));
        _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
        _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;
                    }
                    else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)){
        str ~=`
        auto `~memberName~` = (cast(EntityFieldManyToOne!(`~memType.stringof~`))(this.`~memberName~`));
        _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
        _data.`~memberName~` = `~memberName~`.deSerialize(rows[startIndex]);`;
                    }
                    else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
        str ~=`
        auto `~memberName~` = (cast(EntityFieldOneToOne!(`~memType.stringof~`,T))(this.`~memberName~`));
        _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
        _data.`~memberName~` = `~memberName~`.deSerialize(rows[startIndex]);`;
                    }
                }
            }
        }
    }
    str ~= `
        return Common.sampleCopy(_data);
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