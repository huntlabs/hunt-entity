module hunt.entity.EntityInfoMaker;

import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.EntityDeserializer;
import hunt.entity.EntityMetaInfo;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging;

import std.conv;
import std.string;
import std.traits;
import std.variant;


string makeInitEntityData(T,F)() {
    import std.conv;

    string str = `
    private void initEntityData() {
    `;

    static if (hasUDA!(T, Factory)) {
        str ~= `
        _factoryName = `~ getUDAs!(getSymbolsByUDA!(T,Factory)[0], Factory)[0].name~`;`;
    }

    //
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
            //columnName nullable
            string nullable;
            string columnName;
            string mappedBy;
            static if(hasUDA!(currentMember, ManyToMany))
            {
                mappedBy = "\""~getUDAs!(currentMember, ManyToMany)[0].mappedBy~"\"";
            }

            static if (hasUDA!(currentMember, Column)) {
                columnName = "\""~getUDAs!(currentMember, Column)[0].name~"\"";
                nullable = getUDAs!(currentMember, Column)[0].nullable.to!string;
            } else static if (hasUDA!(currentMember, JoinColumn)) {
                columnName = "\""~getUDAs!(currentMember, JoinColumn)[0].name~"\"";
                nullable = getUDAs!(currentMember, JoinColumn)[0].nullable.to!string;
            } 
            else {
                columnName = "\""~currentMember.stringof~"\"";
            }
            //value 
            string value = "_data."~memberName;
            
            // Use the field/member name as the key
            string fieldName = "_fields["~memberName.stringof~"]";
            static if (is(F == memType) ) {
                str ~= `
            `~fieldName~` = new EntityFieldOwner(`~memberName.stringof~`, toColumnName(`~columnName~`), _tableName);`;
                    
            }
            else static if( memType.stringof.replace("[]","") == F.stringof && hasUDA!(currentMember, ManyToMany))
            {
                string owner = (getUDAs!(currentMember, ManyToMany)[0]).mappedBy == "" ? "_data" : "_owner";

                static if (hasUDA!(currentMember, JoinTable))
                        {
                str ~= `
                `~fieldName~` = new EntityFieldManyToManyOwner!(`
                                ~ memType.stringof.replace("[]","")
                                ~ `,F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                ~ (getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,true,`
                                ~ (getUDAs!(currentMember, JoinTable)[0]).stringof~`,`
                                ~ (getUDAs!(currentMember, JoinColumn)[0]).stringof~`,`
                                ~ (getUDAs!(currentMember, InverseJoinColumn)[0]).stringof~ `);`;
                        }
                        else
                        {
                str ~= `
                `~fieldName~` = new EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`, F,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                                ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,false);`;
                        }
            }
            else static if (hasUDA!(currentMember, OneToOne)) {
                static if(is(memType == T)) {
                    enum string owner = (getUDAs!(currentMember, OneToOne)[0]).mappedBy == "" ? "_owner" : "_data";
                } else {
                    enum string owner = "_data";
                }
    str ~= `
    `~fieldName~` = new EntityFieldOneToOne!(`~memType.stringof~`, T)(_manager, `~memberName.stringof ~ 
                `, _primaryKey, toColumnName(`~columnName~`), _tableName, `~value~`, `
                                ~ (getUDAs!(currentMember, OneToOne)[0]).stringof ~ `, `~owner ~ `);`;
            }
            else static if (hasUDA!(currentMember, OneToMany)) {
                static if (is(T==F)) {
    str ~= `
    `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, F)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                    ~(getUDAs!(currentMember, OneToMany)[0]).stringof~`, _owner);`;
                }
                else {
    str ~= `
    `~fieldName~` = new EntityFieldOneToMany!(`~memType.stringof.replace("[]","")~`, T)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                    ~(getUDAs!(currentMember, OneToMany)[0]).stringof~`, _data);`;
                }
            }
            else static if (hasUDA!(currentMember, ManyToOne)) {
    str ~= `
    `~fieldName~` = new EntityFieldManyToOne!(`~memType.stringof~`)(_manager, `~memberName.stringof~`, toColumnName(`~columnName~`), _tableName, `~value~`, `
                                ~(getUDAs!(currentMember, ManyToOne)[0]).stringof~`);`;
            }
            else static if (hasUDA!(currentMember, ManyToMany)) {
                //TODO
                string owner = (getUDAs!(currentMember, ManyToMany)[0]).mappedBy == "" ? "_owner" : "_data";

                static if (hasUDA!(currentMember, JoinTable))
                {
        str ~= `
        `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                        ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,true,`
                                        ~(getUDAs!(currentMember, JoinTable)[0]).stringof~`,`
                                        ~(getUDAs!(currentMember, JoinColumn)[0]).stringof~`,`
                                        ~(getUDAs!(currentMember, InverseJoinColumn)[0]).stringof~ `);`;
                }
                else
                {
        str ~= `
        `~fieldName~` = new EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`, T,`~mappedBy~`)(_manager, `~memberName.stringof~`, _primaryKey, _tableName, `
                                        ~(getUDAs!(currentMember, ManyToMany)[0]).stringof~`, `~owner~`,false);`;
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
            static if (hasUDA!(currentMember, PrimaryKey) || hasUDA!(currentMember, Id)) {
    str ~= `
    _primaryKey = `~memberName.stringof~`;
    `~fieldName~`.setPrimary(true);`;
            }
            //autoincrease key
            static if (hasUDA!(currentMember, AutoIncrement) || hasUDA!(currentMember, Auto)) {
    str ~= `
    _autoIncrementKey = `~memberName.stringof~`;
    `~fieldName~`.setAuto(true);
    `~fieldName~`.setNullable(false);`;
            }
        }
    }}

    str ~=`
        if (_fields.length == 0) {
            throw new EntityException("Entity class member cannot be empty : `~ T.stringof~`");
        }
    }`;
    return str;
}
