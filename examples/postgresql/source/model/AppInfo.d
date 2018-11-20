module model.AppInfo;

import hunt.entity;
import model.UserInfo;

@Table("appinfo")
class AppInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;

    
    @(JoinTable("userapp"),JoinColumn("appid"),InverseJoinColumn("uid"))
    @ManyToMany("apps")
    UserInfo[] uinfos;
}
