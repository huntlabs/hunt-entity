module hunt.entity.eql.EqlInfo;

import hunt.entity.EntityDeserializer;
import hunt.entity.eql.Common;
import hunt.entity.dialect;
import hunt.logging;

import hunt.entity.EntityInfoMaker;

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

    string className() { return _className ;}

    void setClassName(string name)
    {
        _className = name;
    }

    string tableName() { return _tableName; }
    void setTableName(string tbName)
    {
        _tableName = tbName;
    }

    void putSelectItem( Object o)
    {
        _selectItem ~= o;
    }

    Object[] getSelectItems()
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

import hunt.logging.ConsoleLogger;

import std.conv;
import std.string;
import std.traits;
import std.variant;

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

    private EntityMetaInfo _metaInfo;

    private Object[string] _joinConds;


    // pragma(msg, "T = "~T.stringof~ " F = "~F.stringof);
    // pragma(msg,makeImport!(T)());
    // pragma(msg,makeInitEntityData!(T,F));
    // pragma(msg,makeDeserializer!(T,F));
    // pragma(msg,makeSetIncreaseKey!(T));
    // pragma(msg,makeGetPrimaryValue!(T));
    // pragma(msg,makeSetPrimaryValue!(T)());

    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T,F)());
    mixin(makeJoinConds!(T,F)());
    mixin(makeDeserializer!(T,F)());
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
        initializeEntityInfo();

    }

    
    private void initializeEntityInfo() {
        // _metaInfo = extractEntityInfo!(T)();
        _metaInfo = T.metaInfo; // extractEntityInfo!(T)();

        _entityClassName = _metaInfo.simpleName;
        _tableName = _tablePrefix ~ _metaInfo.tableName;
        _tableNameInLower = _tableName.toLower();

        initEntityData();
        initJoinConds();
    }

    EntityFieldInfo getPrimaryField() {
        if (_primaryKey.length > 0) 
            return _fields[_primaryKey];
        return null;
    }


    EntityFieldInfo opDispatch(string name)() 
    {
        EntityFieldInfo info = _fields.get(name,null);
        if (info is null)
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        return info;
    }

    string getFactoryName() { return _factoryName; };
    string getEntityClassName() { return _entityClassName; }
    string getTableName() { return _tableName; }
    string getAutoIncrementKey() { return _autoIncrementKey; }
    EntityFieldInfo[string] getFields() { return _fields; }
    string getPrimaryKeyString() { return _primaryKey; }
    EntityFieldInfo getSingleField(string name) { return _fields.get(name,null); }
    string getJoinCond(string member) { 
        auto cond =  _joinConds.get(member,null);
        return cond !is null ? cond.toString() : null;
    }
    Object[string] getJoinConds() { 
        return _joinConds;
    }


    private string toColumnName(string fieldName) {
        return _metaInfo.columnName(fieldName);
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

private string makeJoinConds(T, F)() {
    string str = `
    private void initJoinConds() {`;    

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMember = __traits(getMember, T, memberName);

        static if (__traits(getProtection, currentMember) != "public") {
            enum isEntityMember = false;
        } else static if(hasUDA!(currentMember, Transient)) {
            enum isEntityMember = false;
        } else {
            enum isEntityMember = true;
        }

        static if (isEntityMember) {
            alias memType = typeof(currentMember);
            string columnName;
            string referencedColumnName;

            static if (hasUDA!(currentMember, JoinColumn) && is(memType == class)) {
                columnName = "\""~getUDAs!(currentMember, JoinColumn)[0].name~"\"";
                referencedColumnName = "\""~getUDAs!(currentMember, JoinColumn)[0].referencedColumnName~"\"";
                
                str ~= `
                {
                    EntityMetaInfo memberMetaInfo = ` ~ memType.stringof ~ `.metaInfo;
                    string rightTableName = _tablePrefix ~ memberMetaInfo.tableName;
                    auto joinCond = new JoinCond(_tableName, ` ~ 
                        memberName.stringof~ `, ` ~ columnName ~ `,` ~ referencedColumnName ~ 
                        `, rightTableName, memberMetaInfo.primaryKey);
                    _joinConds[_entityClassName ~ "." ~ ` ~ memberName.stringof ~ `] = joinCond;
                }
                `;                
            } 
        }
    }}

    str ~=`
    }`;
    return str;
}


/**
 * 
 */
class JoinCond
{
    private string _joinCond;

    this(string leftTable, string fieldName, string joinCol, string referencedColumnName,
        string rightTable, string rightTablePrimaryKey)
    {
        version(HUNT_ENTITY_DEBUG) {
            warningf("leftTable: %s, fieldName: %s, joinCol: %s, referencedColumn: %s, rightTable: %s", 
                leftTable, fieldName, joinCol, referencedColumnName, rightTable);
        }

        if(referencedColumnName.empty())
            _joinCond = leftTable ~ "." ~ joinCol ~ " = " ~ rightTable ~ "." ~ rightTablePrimaryKey;
        else
            _joinCond = leftTable ~ "." ~ joinCol ~ " = " ~ rightTable ~ "." ~ referencedColumnName;
    }

    override string toString()
    {
        return _joinCond;
    }
}