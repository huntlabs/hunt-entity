


module entity.EntityCreateTable;

import entity.EntityInfo;
import entity.Constant;

import database;
import std.digest.md;



 class EntityCreateTable(T) {
    private EntityInfo!T _entityInfo;
    this() {
        _entityInfo = new EntityInfo!T();
    }

    public string createTable(Dialect dialect, string tablePrefix, ref string[] alertRows) {
        alertRows ~= getAddForeignKey(tablePrefix);
        return getCreateTable(dialect, tablePrefix);
    }

    private string getCreateTable(Dialect dialect, string tablePrefix) {
        string str;
        str ~= "CREATE TABLE "~tablePrefix~_entityInfo.getTableName()~" (";
        bool first = true;
        foreach(field ; _entityInfo.getFields()) {
            if (field.getColumnName() != "" && field.getDlangType()) {
                ColumnDefinitionInfo info;
                info.isId = field.getPrimary();
                info.name = field.getColumnName();
                info.isAuto = field.getAuto();
                info.isNullable = field.getNullable();
                info.dType = field.getDlangType().getName();
                if (first)
                    first = false;
                else 
                    str ~= ", ";
                str ~= info.name ~ " " ~ dialect.getColumnDefinition(info);
            }
        }
        str ~= ")";
        return str;
    }

    private string[] getAddForeignKey(string tablePrefix) {
        string[] str;
        foreach(v; _entityInfo.getFields()) {
            ForeignKeyData data = v.getForeignKeyData();
            if (data) {
                ubyte[16] hash = md5Of(tablePrefix~data.tableName~data.columnName);
                string mds = toHexString(hash);
                string tmp = "ALTER TABLE "~tablePrefix~_entityInfo.getTableName()~" ADD CONSTRAINT FRK"~mds~" FOREIGN KEY ("~data.columnName~") REFERENCES "~tablePrefix~data.tableName~" ("~data.primaryKey~")";
                str ~= tmp;
            }
        }
        return str;
    }


}







