module entity.domain.Member;

import entity;

import std.stdio;



class Member(T)
{
    string         _tableName;

    this(EntityManager em)
    {
        _tableName = em.getPrefix() ~ getUDAs!(getSymbolsByUDA!(T, Table)[0], Table)[0].name;
    }

    mixin(MakeMember!T);

    private string  getMember(string name)()
    {   
        static if(hasUDA!(__traits(getMember , T , name) ,Column))
        {
            return _tableName ~ "." ~ getUDAs!(__traits(getMember , T , name) ,Column)[0].name;
        }
        else static if(hasUDA!(__traits(getMember , T , name) ,JoinColumn))
        {
            return _tableName ~ "." ~ getUDAs!(__traits(getMember , T , JoinColumn) ,Column)[0].name;
        }
        else 
        {
            return _tableName ~ "." ~ name;
        }
    }
  
}

private:
string MakeMember(T)()
{
    string str;
    foreach (m; FieldNameTuple!T)
    {
        if (__traits(getProtection, __traits(getMember, T, m)) == "public")
        {
            str ~= "@property string " ~ m ~ "(){";
            str ~= "return getMember!\""~m~"\"; }";
        }
    }
    return str;
}