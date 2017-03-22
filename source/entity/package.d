
module entity;

public import ddbc;

public import entity.annotations;
public import entity.manager;
public import entity.metadata;
public import entity.type;
public import entity.dialect;

version( USE_SQLITE )
{
    public import entity.dialects.sqlitedialect;
}
version( USE_PGSQL )
{
    public import entity.dialects.pgsqldialect;
}
version( USE_MYSQL )
{
    public import entity.dialects.mysqldialect;
}
