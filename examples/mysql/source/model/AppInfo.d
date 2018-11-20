module model.AppInfo;

import hunt.entity;
import model.UserInfo;

@Table("AppInfo")
class AppInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;

    
    @(JoinTable("UserApp"),JoinColumn("appid"),InverseJoinColumn("uid"))
    @ManyToMany("apps")
    UserInfo[] uinfos;
}
