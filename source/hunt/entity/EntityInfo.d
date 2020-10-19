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
 
module hunt.entity.EntityInfo;

import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.EntityDeserializer;
import hunt.entity.EntityMetaInfo;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;
import hunt.entity.EntityInfoMaker;

import hunt.logging.ConsoleLogger;

import std.conv;
import std.string;
import std.traits;
import std.variant;

class EntityInfo(T : Object, F : Object = T) {
    
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

    // private string[string] _fieldColumnMaps;

    //auto mixin function
    // public T deSerialize(Row row) {}
    // public void setIncreaseKey(ref T entity, int value) {}
    // public R getPrimaryValue() {}
    // public void setPrimaryValue(ref T entity, int value) {}

    // pragma(msg, "T = "~T.stringof~ " F = "~F.stringof);
    // pragma(msg,makeImport!(T)());
    // pragma(msg,makeInitEntityData!(T,F)());
    // pragma(msg,makeDeserializer!(T,F));
    // pragma(msg,makeSetIncreaseKey!(T));
    // pragma(msg,makeGetPrimaryValue!(T));
    // pragma(msg,makeSetPrimaryValue!(T)());


    mixin(makeImport!(T)());
    mixin(makeInitEntityData!(T,F)());

    mixin(makeDeserializer!(T,F)());
    mixin(makeSetIncreaseKey!(T)());
    mixin(makeGetPrimaryValue!(T)());
    mixin(makeSetPrimaryValue!(T)());

    this(EntityManager manager = null, T t = null, F owner = null)
    {
        version(HUNT_ENTITY_DEBUG) { 
            warningf("T: %s, F: %s", T.stringof, F.stringof);
        }

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
            if(_data !is null)
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
    }

    private string toColumnName(string fieldName) {
        return _metaInfo.columnName(fieldName);
    }

    public EntityFieldInfo getPrimaryField() {
        if (_primaryKey.length > 0) 
            return _fields[_primaryKey];
        return null;
    }

    public Variant[string] getInsertString() {
        Variant[string] str;

        foreach(string fieldName, EntityFieldInfo info; _fields) {
            string columnName = info.getColumnName();
            Variant currentValue = info.getColumnFieldData();
            
            TypeInfo typeInfo = info.typeInfo();
            if(typeInfo is null) {
                typeInfo = currentValue.type;
            }

            version(HUNT_DB_DEBUG_MORE) {
                tracef("fieldName: %s, columnName: %s, type: %s, value: %s", 
                    fieldName, columnName, typeInfo, currentValue.toString());
            }
            
            // Skip the autoIncrementKey
            if (columnName == _autoIncrementKey) 
                continue;
            
            // version(HUNT_DB_DEBUG) trace(currentValue.type);

            // skip Object member
            if(typeid(typeInfo) == typeid(TypeInfo_Class) || 
                typeid(typeInfo) == typeid(TypeInfo_Struct) ) {
                version(HUNT_DB_DEBUG) warningf("Object member skipped: %s", fieldName);
                continue;
            }

            if (columnName.empty()) {
                version(HUNT_DEBUG) warningf("The name of column for the field [%s] is empty.", fieldName);
                continue;
            }

            if(!_manager.getDbOption().isPgsql()) {
                columnName = info.getFullColumn();
            }

            if(columnName in str) {
                version(HUNT_DEBUG) {
                    warningf("skip a existed column [%s] with value [%s].", columnName, currentValue.toString());
                }
            } else {
                str[columnName] = currentValue;
            }
        }
        return str;
    }

    EntityFieldInfo opDispatch(string name)() 
    {
        version(HUNT_ENTITY_DEBUG) {
            infof("getting field info for: %s", name);
        }

        EntityFieldInfo fieldInfo = _fields.get(name,null);
        if (fieldInfo is null) {
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        } else {
            version(HUNT_ENTITY_DEBUG_MORE) {
                tracef("The field info is a: %s", typeid(fieldInfo));
            }
        }
        return fieldInfo;
    }

    public string getFactoryName() { return _factoryName; }
    public string getEntityClassName() { return _entityClassName; }
    public string getTableName() { return _tableName; }
    public string getAutoIncrementKey() { return _autoIncrementKey; }
    public EntityFieldInfo[string] getFields() { return _fields; }
    public string getPrimaryKeyString() { return _primaryKey; }
    public EntityFieldInfo getSingleField(string name) { return _fields.get(name,null); }

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
            static if (!isFunction!(memType) && (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || 
                    hasUDA!(__traits(getMember, T ,memberName), Auto))) {
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
