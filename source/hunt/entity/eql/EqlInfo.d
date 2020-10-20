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
                    auto joinCond = new JoinCond!(` ~ memType.stringof ~ `)(_manager,_entityClassName,` ~ 
                        memberName.stringof~ `, ` ~ columnName ~ `,` ~ referencedColumnName ~ `, _tableName);
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

// string makeInitEntityData(T,F)() {
//     string str = `
//     private void initEntityData() {
//         _entityClassName = "`~T.stringof~`";`;
//     static if (hasUDA!(T,Table)) {
//         str ~= `
//         _tableName = _tablePrefix ~ "` ~ getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name ~`";`;
//     }
//     else {
//         str ~= `
//         _tableName = _tablePrefix ~ "` ~ T.stringof ~ `";`;
//     }

//     static if (hasUDA!(T, Factory))
//     {
//         str ~= `
//         _factoryName = `~ getUDAs!(getSymbolsByUDA!(T,Factory)[0], Factory)[0].name~`;`;
//     }

//     static foreach (string memberName; FieldNameTuple!T) {{
//         alias currentMember = __traits(getMember, T, memberName);
        
//         static if (__traits(getProtection, currentMember) != "public") {
//             enum isEntityMember = false;
//         } else static if(hasUDA!(currentMember, Transient)) {
//             enum isEntityMember = false;
//         } else {
//             enum isEntityMember = true;
//         }
        
//         static if (isEntityMember) {
//             alias memType = typeof(__traits(getMember, T ,memberName));
            
//                 //columnName nullable
//                 string nullable;
//                 string columnName;
//                 string referencedColumnName;
//                 static if (hasUDA!(__traits(getMember, T ,memberName), Column)) {
//                     columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), Column)[0].name~"\"";
//                     nullable = getUDAs!(__traits(getMember, T ,memberName), Column)[0].nullable.to!string;
//                 }
//                 else static if (hasUDA!(__traits(getMember, T ,memberName), JoinColumn)) {
//                     columnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].name~"\"";
//                     referencedColumnName = "\""~getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].referencedColumnName~"\"";
//                     nullable = getUDAs!(__traits(getMember, T ,memberName), JoinColumn)[0].nullable.to!string;
//                     static if(is(memType == class))
//                     {
//                         str ~= `
//                         {
//                             auto joinCond = new JoinCond!(`~memType.stringof~`)(_manager,_entityClassName,`~memberName.stringof~`, `~columnName~`,`~referencedColumnName~`, _tableName);
//                             _joinConds[_entityClassName ~ "." ~ `~memberName.stringof~`] = joinCond;
//                         }
//                         `;
//                     }
//                 }
//                 else {
//                     columnName = "\""~__traits(getMember, T ,memberName).stringof~"\"";
//                 }
           
//                 string value = "_data."~memberName;
//                 string fieldName = "_fields["~memberName.stringof~"]";
//                 static if (is(F == memType)) {
//         str ~= `
//         `~fieldName~` = new EntityFieldOwner(`~memberName.stringof~`, `~columnName~`, _tableName);`;
//                 }
//                 else static if (hasUDA!(__traits(getMember, T ,memberName), OneToOne)) {
//                     string owner = (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";

//         str ~= `
//         `~ fieldName ~ ` = new EntityFieldOneToOne!(` ~ memType.stringof ~ ", T)(_manager, " ~ memberName.stringof ~
//                     `, _primaryKey, ` ~ columnName ~ ", _tableName, " ~ value ~ ", " ~ 
//                     (getUDAs!(__traits(getMember, T ,memberName), OneToOne)[0]).stringof ~ 
//                     `, ` ~ owner ~ `);`;
//                 }
//                 else static if (hasUDA!(__traits(getMember, T ,memberName), OneToMany)) {
//         //             static if (is(T==F)) {
//         // str ~= `
//         // `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, F)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//         //                                 ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _owner);`;
//         //             }
//         //             else {
//         // str ~= `
//         // `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, T)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//         //                                 ~(getUDAs!(__traits(getMember, T ,memberName), OneToMany)[0]).stringof~`, _data);`;
//         //             }
//                 }
//                 else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToOne)) {
//         str ~= `
//         `~fieldName~` = new EntityFieldManyToOne!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, `~columnName~`, _tableName, `~value~`, `
//                                     ~(getUDAs!(__traits(getMember, T ,memberName), ManyToOne)[0]).stringof~`);`;
//                 }
//                 else static if (hasUDA!(__traits(getMember, T ,memberName), ManyToMany)) {
//                     //TODO                                                                 
//                 }
//                 else {
//         str ~= `
//         `~fieldName~` = new EntityFieldNormal!(`~memType.stringof~`)(_manager,`~memberName.stringof~`, `~columnName~`, _tableName, `~value~`);`;
//             }

//                 //nullable
//                 if (nullable != "" && nullable != "true")
//         str ~= `
//         `~fieldName~`.setNullable(`~nullable~`);`;
//                 //primary key
//                 static if (hasUDA!(__traits(getMember, T ,memberName), PrimaryKey) || hasUDA!(__traits(getMember, T ,memberName), Id)) {
//         str ~= `
//         _primaryKey = `~memberName.stringof~`;
//         `~fieldName~`.setPrimary(true);`;
//                 }
//                 //autoincrease key
//                 static if (hasUDA!(__traits(getMember, T ,memberName), AutoIncrement) || hasUDA!(__traits(getMember, T ,memberName), Auto)) {
//         str ~= `
//         _autoIncrementKey = `~memberName.stringof~`;
//         `~fieldName~`.setAuto(true);
//         `~fieldName~`.setNullable(false);`;
//                 }
//         }    
//     }}

//     str ~=`
//         if (_fields.length == 0) {
//             throw new EntityException("Entity class member cannot be empty : `~ T.stringof~`");
//         }
//     }`;
//     return str;
// }



// string makeInitEntityData(T,F)() {
//     import std.conv;

//     string str = `
//     private void initEntityData() {
//     `;

//     static if (hasUDA!(T, Factory)) {
//         str ~= `
//         _factoryName = `~ getUDAs!(getSymbolsByUDA!(T,Factory)[0], Factory)[0].name~`;`;
//     }

//     //
//     static foreach (string memberName; FieldNameTuple!T) {{
//         alias currentMember = __traits(getMember, T, memberName);

//         static if (__traits(getProtection, currentMember) != "public") {
//             enum isEntityMember = false;
//         } else static if(hasUDA!(currentMember, Transient)) {
//             enum isEntityMember = false;
//         } else {
//             enum isEntityMember = true;
//         }

//         static if (isEntityMember) {
//             alias memType = typeof(currentMember);
//             //columnName nullable
//             string nullable;
//             string columnName;
//             string mappedBy;
//             static if(hasUDA!(currentMember, ManyToMany))
//             {
//                 mappedBy = "\""~getUDAs!(currentMember, ManyToMany)[0].mappedBy~"\"";
//             }

//             static if (hasUDA!(currentMember, Column)) {
//                 columnName = "\""~getUDAs!(currentMember, Column)[0].name~"\"";
//                 nullable = getUDAs!(currentMember, Column)[0].nullable.to!string;
//             } else static if (hasUDA!(currentMember, JoinColumn)) {
//                 columnName = "\""~getUDAs!(currentMember, JoinColumn)[0].name~"\"";
//                 nullable = getUDAs!(currentMember, JoinColumn)[0].nullable.to!string;
//             } 
//             else {
//                 columnName = "\""~currentMember.stringof~"\"";
//             }
//             //value 
//             string value = "_data."~memberName;
            
//             // Use the field/member name as the key
//             string fieldName = "_fields["~memberName.stringof~"]";
//             static if (is(F == memType) ) {
//                 str ~= `
//             `~fieldName~` = new EntityFieldOwner(`~memberName.stringof~`, toColumnName(`~columnName~`), _tableName);`;
                    
//             }
//             else static if( memType.stringof.replace("[]","") == F.stringof && hasUDA!(currentMember, ManyToMany))
//             {
//                 string owner = (getUDAs!(currentMember, ManyToMany)[0]).mappedBy == "" ? "_data" : "_owner";

//                 static if (hasUDA!(currentMember, JoinTable))
//                         {
//                 str ~= `
//                 `~fieldName~` = new EntityFieldManyToManyOwner!(`
//                                 ~ memType.stringof.replace("[]","")
//                                 ~ `,F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                 ~ (getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,true,`
//                                 ~ (getUDAs!(currentMember, JoinTable)[0]).stringof~`,`
//                                 ~ (getUDAs!(currentMember, JoinColumn)[0]).stringof~`,`
//                                 ~ (getUDAs!(currentMember, InverseJoinColumn)[0]).stringof~ `);`;
//                         }
//                         else
//                         {
//                 str ~= `
//                 `~fieldName~` = new EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`, F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                                 ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,false);`;
//                         }
//             }
//             else static if (hasUDA!(currentMember, OneToOne)) {
//                 static if(is(memType == T)) {
//                     enum string owner = (getUDAs!(currentMember, OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";
//                 } else {
//                     enum string owner = "_data";
//                 }
//     str ~= `
//     `~fieldName~` = new EntityFieldOneToOne!(`~memType.stringof~`, T)(_manager, `~memberName.stringof ~ 
//                 `, _primaryKey, toColumnName(`~columnName~`), _tableName, `~value~`, `
//                                 ~ (getUDAs!(currentMember, OneToOne)[0]).stringof ~ `, `~owner ~ `);`;
//             }
//             else static if (hasUDA!(currentMember, OneToMany)) {
//                 static if (is(T==F)) {
//     str ~= `
//     `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, F)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                     ~(getUDAs!(currentMember, OneToMany)[0]).stringof~`, _owner);`;
//                 }
//                 else {
//     str ~= `
//     `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, T)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                     ~(getUDAs!(currentMember, OneToMany)[0]).stringof~`, _data);`;
//                 }
//             }
//             else static if (hasUDA!(currentMember, ManyToOne)) {
//     str ~= `
//     `~fieldName~` = new EntityFieldManyToOne!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, toColumnName(`~columnName~`), _tableName, `~value~`, `
//                                 ~(getUDAs!(currentMember, ManyToOne)[0]).stringof~`);`;
//             }
//             else static if (hasUDA!(currentMember, ManyToMany)) {
//                 //TODO
//                 string owner = (getUDAs!(currentMember, ManyToMany)[0]).mappedBy == "" ? "_owner" : "_data";

//                 static if (hasUDA!(currentMember, JoinTable))
//                 {
//         str ~= `
//         `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                         ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,true,`
//                                         ~(getUDAs!(currentMember, JoinTable)[0]).stringof~`,`
//                                         ~(getUDAs!(currentMember, JoinColumn)[0]).stringof~`,`
//                                         ~(getUDAs!(currentMember, InverseJoinColumn)[0]).stringof~ `);`;
//                 }
//                 else
//                 {
//         str ~= `
//         `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`, T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
//                                         ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,false);`;
//                 }
//             }
//             else {
//                 // string fieldType =  "new "~getDlangDataTypeStr!memType~"()";
//     str ~= `
//     `~fieldName~` = new EntityFieldNormal!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, `~columnName~`, _tableName, `~value~`);`;
//             }

//             //nullable
//             if (nullable != "" && nullable != "true")
//     str ~= `
//     `~fieldName~`.setNullable(`~nullable~`);`;
//             //primary key
//             static if (hasUDA!(currentMember, PrimaryKey) || hasUDA!(currentMember, Id)) {
//     str ~= `
//     _primaryKey = `~memberName.stringof~`;
//     `~fieldName~`.setPrimary(true);`;
//             }
//             //autoincrease key
//             static if (hasUDA!(currentMember, AutoIncrement) || hasUDA!(currentMember, Auto)) {
//     str ~= `
//     _autoIncrementKey = `~memberName.stringof~`;
//     `~fieldName~`.setAuto(true);
//     `~fieldName~`.setNullable(false);`;
//             }
//         }
//     }}

//     str ~=`
//         if (_fields.length == 0) {
//             throw new EntityException("Entity class member cannot be empty : `~ T.stringof~`");
//         }
//     }`;
//     return str;
// }


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