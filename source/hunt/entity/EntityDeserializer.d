module hunt.entity.EntityDeserializer;


import hunt.entity.eql.Common;

import hunt.entity;
import hunt.entity.EntityMetaInfo;
import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.dialect;

import hunt.logging.ConsoleLogger;

import std.conv;
import std.string;
import std.traits;
import std.variant;


string makeDeserializer(T)() {
    string str;

    str ~= "\n" ~ indent(4) ~ "/// T=" ~ T.stringof;
    str ~= `
    T deSerialize(P, bool canInit = true)(Row[] rows, ref long count, int startIndex = 0,` ~ 
            ` P owner = null,  bool isFromManyToOne = false) {
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
        string columnName;
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
        
    // static if(is(T == P)) {
    //     str ~= indent(8) ~ "T actualOwner = _data;\n";
    // } else {
    //     str ~= indent(8) ~ "T actualOwner = null;\n";
    // }

    str ~= indent(8) ~ "T actualOwner = _data;\n";

    static foreach (string memberName; FieldNameTuple!T) {{
        alias currentMember = __traits(getMember, T, memberName);
        alias memType = typeof(currentMember);
        
        static if (__traits(getProtection, currentMember) != "public") {
            enum isEntityMember = false;
        } else static if(hasUDA!(currentMember, Transient)) {
            enum isEntityMember = false;
        } else {
            enum isEntityMember = true;
        }

        static if (isEntityMember) {
            string mappedBy;
            static if(hasUDA!(currentMember, ManyToMany)) {
                mappedBy = "\""~getUDAs!(currentMember, ManyToMany)[0].mappedBy~"\"";
            }

            str ~= "\n\n";
            str ~= indent(8) ~ "// Handle membmer: " ~ memberName ~ ", type: " ~ memType.stringof ~ "\n";

            // string or basic type
            static if (isBasicType!memType || isSomeString!memType) {
                str ~= indent(8) ~ `isMemberDeserialized = false;
                auto `~memberName~` = cast(EntityFieldNormal!`~memType.stringof~`)(this.`~memberName~`);
                columnAsName = `~memberName~`.getColumnAsName();
                columnName = `~memberName~`.getColumnName();
                columnValue = row.getValue(columnAsName);
                
                if(!columnValue.hasValue()) {
                    version(HUNT_DEBUG) {
                    warningf("No value found for column [%s]. Try [%s] now.", columnAsName, columnName);
                    }
                    columnValue = row.getValue(columnName);
                }

                if(!columnValue.hasValue()) {
                    warningf("No value found for column: %s, asName: %s", columnName, columnAsName);
                } else {
                    version(HUNT_ENTITY_DEBUG) {
                        tracef("A column: %s = %s; The AsName: %s", columnName, columnValue, columnAsName);
                    }

                    if(columnValue.type == typeid(null)) {
                        version(HUNT_DEBUG) {
                            warningf("The value of column [%s] is null. So use its default.", "` 
                                ~ memberName ~ `");
                        }
                    } else {
                        string cvalue = columnValue.toString();
                        version(HUNT_ENTITY_DEBUG_MORE) { 
                            tracef("field: name=%s, type=%s; column: name=%s, type=%s; value: %s", "` 
                                        ~ memberName ~ `", "` ~ memType.stringof 
                                        ~ `", columnAsName, columnValue.type,` 
                                        ~ ` cvalue.empty() ? "(empty)" : cvalue);
                        }
                        _data.` ~ memberName ~ ` = ` ~ memberName ~ `.deSerialize!(` 
                                ~ memType.stringof ~ `)(cvalue, isMemberDeserialized);
                                
                        if(isMemberDeserialized) isObjectDeserialized = true;
                    }
                }`;
                
            } else { // Object
                str ~= indent(8) ~ "isDeserializationNeed = true;\n";

                str ~=`
                    static if(is(P == ` ~ memType.stringof ~ `)) {                    
                        if(owner is null) {
                            version(HUNT_ENTITY_DEBUG) {
                                warningf("The owner [%s] of [%s] is null.", P.stringof, T.stringof);
                            }
                        } else {
                            version(HUNT_ENTITY_DEBUG) {
                                warningf("set [` ~ memberName ~ 
                                    `] to the owner {Type: %s, isNull: false}", P.stringof);
                            }
                            isDeserializationNeed = false;
                            _data.` ~ memberName ~ ` = owner;
                        }
                    } else {
                        // version(HUNT_ENTITY_DEBUG) {
                        //     warningf("Type mismatched: P=%s, memType=` ~ memType.stringof ~ `", P.stringof);
                        // } 
                    }` ~ "\n\n";

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
                    static if ( memType.stringof.replace("[]","") == P.stringof) {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToManyOwner!(`~memType.stringof.replace("[]","")~`,P,`~mappedBy~`))(fieldInfo));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize!(T)(rows, startIndex, isFromManyToOne);`;
                    } else {
                        str ~=`
                            auto `~memberName~` = (cast(EntityFieldManyToMany!(`~memType.stringof.replace("[]","")~`,T,`~mappedBy~`))(fieldInfo));
                            _data.addLazyData("`~memberName~`",`~memberName~`.getLazyData(rows[startIndex]));
                            _data.`~memberName~` = `~memberName~`.deSerialize!(T)(rows, startIndex, isFromManyToOne);`;
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

        scope(exit) {
            _data.onInitialized();
        }

        if(isObjectDeserialized) {
            _data.loadLazyMembers();
            return _data;
        } else {
            static if(canInit) {
                return _data;
            } else {
                return T.init;
            }
        }
    }`;

    return str;
}
