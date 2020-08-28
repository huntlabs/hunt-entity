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
import hunt.entity.EntityMetaInfo;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging;

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

        // _metaInfo = extractEntityInfo!(T)();
        _metaInfo = T.metaInfo; // extractEntityInfo!(T)();
        initEntityData();
    }

    private string toColumnName(string fieldName) {
        return _metaInfo.toClumnName(fieldName);
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
        EntityFieldInfo info = _fields.get(name,null);
        if (info is null)
            throw new EntityException("Cannot find entityfieldinfo by name : " ~ name);
        return info;
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


string makeInitEntityData(T,F)() {
    import std.conv;

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

    str ~= `
        _tableNameInLower = _tableName.toLower();
    `;

    static if (hasUDA!(T, Factory))
    {
        str ~= `
        _factoryName = `~ getUDAs!(getSymbolsByUDA!(T,Factory)[0], Factory)[0].name~`;`;
    }

    //
    foreach(memberName; __traits(derivedMembers, T)) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            alias memType = typeof(__traits(getMember, T ,memberName));
            static if (!isFunction!(memType)) {
                //columnName nullable
                string nullable;
                string columnName;
                string mappedBy;
                static if(hasUDA!(__traits(getMember, T ,memberName), ManyToMany))
                {
                    mappedBy = "\""~getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0].mappedBy~"\"";
                }

                static if (hasUDA!(__traits(getMember, T ,memberName), Column)) {
                    columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
                    nullable = getUDAs!(__traits(getMember, T ,memberName), Column)[0].nullable.to!string;
                } else static if (hasUDA!(__traits(getMember, T ,memberName), JoinColumn)) {
                    columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].name~"\"";
                    nullable = getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].nullable.to!string;
                } 
                else {
                    columnName = "\""~__traits(getMember, T ,memberName).stringof~"\"";
                }
                //value 
                string value = "_data."~memberName;
                
                // Use the field/member name as the key
                string fieldName = "_fields["~memberName.stringof~"]";
                static if (is(F == memType) ) {
                    str ~= `
                `~fieldName~` = new EntityFieldOwner(`~memberName.stringof~`, toColumnName(`~columnName~`), _tableName);`;
                        
                }
                else static if( memType.stringof.replace("[]","") == F.stringof && hasUDA!(__traits(getMember, T ,memberName), ManyToMany))
                {
                    string owner = (getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).mappedBy == "" ? "_data" : "_owner";

                    static if (hasUDA!(__traits(getMember, T ,memberName), JoinTable))
                            {
                    str ~= `
                    `~fieldName~` = new EntityFieldManyToManyOwner!(`
                                    ~ memType.stringof.replace("[]","")
                                    ~ `,F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                    ~ (getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~`, `~owner~`,true,`
                                    ~ (getUDAs!(__traits(getMember, T ,memberName), JoinTable)[0]).stringof~`,`
                                    ~ (getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0]).stringof~`,`
                                    ~ (getUDAs!(__traits(getMember, T ,memberName), InverseJoinColumn)[0]).stringof~ `);`;
                            }
                            else
                            {
                    str ~= `
                    `~fieldName~` = new EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`, F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                                    ~(getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~`, `~owner~`,false);`;
                            }
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
                    static if(is(memType == T)) {
                        enum string owner = (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";
                    } else {
                        enum string owner = "_data";
                    }
        str ~= `
        `~fieldName~` = new EntityFieldOneToOne!(`~memType.stringof~`, T)(_manager, `~memberName.stringof ~ 
                    `, _primaryKey, toColumnName(`~columnName~`), _tableName, `~value~`, `
                                    ~ (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof ~ `, `~owner ~ `);`;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
                    static if (is(T==F)) {
        str ~= `
        `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, F)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                        ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _owner);`;
                    }
                    else {
        str ~= `
        `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, T)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                        ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _data);`;
                    }
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)) {
        str ~= `
        `~fieldName~` = new EntityFieldManyToOne!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, toColumnName(`~columnName~`), _tableName, `~value~`, `
                                    ~(getUDAs!(__traits(getMember, T ,memberName), ManyToOne)[0]).stringof~`);`;
                }
                else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
                    //TODO
                    string owner = (getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).mappedBy == "" ? "_owner" : "_data";

                    static if (hasUDA!(__traits(getMember, T ,memberName), JoinTable))
                    {
            str ~= `
            `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                            ~(getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~`, `~owner~`,true,`
                                            ~(getUDAs!(__traits(getMember, T ,memberName), JoinTable)[0]).stringof~`,`
                                            ~(getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0]).stringof~`,`
                                            ~(getUDAs!(__traits(getMember, T ,memberName), InverseJoinColumn)[0]).stringof~ `);`;
                    }
                    else
                    {
            str ~= `
            `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`, T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                            ~(getUDAs!(__traits(getMember, T ,memberName), ManyToMany)[0]).stringof~`, `~owner~`,false);`;
                    }
                }
                else {
                    // string fieldType =  "new "~getDlangDataTypeStr!memType~"()";
        str ~= `
        `~fieldName~` = new EntityFieldNormal!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, `~columnName~`, _tableName, `~value~`);`;
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

    str ~= indent(4) ~ "/// T=" ~ T.stringof ~ ", F=" ~ F.stringof;
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
                }

                version(HUNT_ENTITY_DEBUG) {
                    warningf("member: `~memberName~`, isDeserialized: %s", isMemberDeserialized);
                }
                `;
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

                str ~= indent(8) ~ "if(isDeserializationNeed) {";

                static if (isArray!memType && hasUDA!(currentMember, OneToMany)) {
                    str ~=`
                    auto `~memberName~` = (cast(EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`,T))(this.`~memberName~`));
                    _data.addLazyData("`~memberName~`", `~memberName~`.getLazyData(rows[startIndex]));
                    _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;

                } else static if (hasUDA!(currentMember, ManyToOne)){
                    str ~=`
                    auto `~memberName~` = (cast(EntityFieldManyToOne!(`~memType.stringof~`))(this.`~memberName~`));
                    _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                    _data.`~memberName~` = `~memberName~`.deSerialize(rows[startIndex]);`;

                } else static if (hasUDA!(currentMember, OneToOne)) {
                    str ~= "\n" ~ indent(12) ~ `auto `~memberName~` = (cast(EntityFieldOneToOne!(`~memType.stringof~`,T))(this.`~memberName~`));`;
                    str ~= "\n" ~ indent(12) ~ `_data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));`;
                    str ~= "\n" ~ indent(12) ~ `_data.`~memberName~` = ` ~ memberName ~ `.deSerialize(rows[startIndex], actualOwner);`;

                } else static if (isArray!memType && hasUDA!(currentMember, ManyToMany)) {
                    static if ( memType.stringof.replace("[]","") == F.stringof) {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`,F,`~mappedBy~`))(this.`~memberName~`));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;
                    } else {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`))(this.`~memberName~`));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize(rows, startIndex, isFromManyToOne);`;
                    }
    
                }

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
