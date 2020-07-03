module hunt.entity.domain.Member;

import hunt.entity;

import std.stdio;
import std.traits;


class Member(T)
{
    string         _tableName;

    this(string prefix)
    {
        static if (hasUDA!(T,Table))
            _tableName = prefix ~ getUDAs!(getSymbolsByUDA!(T, Table)[0], Table)[0].name;
        else
            _tableName = prefix ~ T.stringof;
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
            return _tableName ~ "." ~ getUDAs!(__traits(getMember , T , name) ,JoinColumn)[0].name;
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
            str ~= "@property string " ~ m ~ "() {";
            str ~= "return getMember!\""~m~"\"; }";
        }
    }
    return str;
}