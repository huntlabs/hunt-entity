module Model.AppInfo;

import hunt.entity;
import Model.UserInfo;

@Table("appinfo")
class AppInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;

    
    @(JoinTable("userapp"),JoinColumn("appid"),InverseJoinColumn("uid"))
    @ManyToMany("apps")
    UserInfo[] uinfos;
}
